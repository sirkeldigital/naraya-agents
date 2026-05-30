# NARAYA Agents - Windows / PowerShell installer
# Installs NARAYA agents + skills to Claude Code, OpenCode, and/or Factory Droid.
#
# Usage:
#   irm https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.ps1 | iex
#
# Non-interactive:
#   $env:NARAYA_PLATFORM='claude-code'; irm <url> | iex      # platform: claude-code|opencode|droid|all
#   $env:NARAYA_COMPONENTS='agents,skills'; irm <url> | iex  # what to install: agents,skills,all (default: all)
#   $env:NARAYA_BRANCH='main'                                # repo branch (default: main)

param(
    [string]$Platform = $env:NARAYA_PLATFORM,
    [string]$Components = $env:NARAYA_COMPONENTS,
    [string]$RepoUrl = "https://github.com/sirkeldigital/naraya-agents",
    [string]$Branch = $(if ($env:NARAYA_BRANCH) { $env:NARAYA_BRANCH } else { "main" })
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[NARAYA] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[OK]     $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN]   $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[ERROR]  $msg" -ForegroundColor Red }

# === Interactive platform selection ===
if (-not $Platform) {
    Write-Host ""
    Write-Host "NARAYA Agents Installer" -ForegroundColor Magenta
    Write-Host "========================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Detected installed AI CLIs:"
    $detected = @()
    if (Get-Command claude -ErrorAction SilentlyContinue) { Write-Host "  - Claude Code"; $detected += "claude-code" }
    if (Get-Command opencode -ErrorAction SilentlyContinue) { Write-Host "  - OpenCode"; $detected += "opencode" }
    if (Get-Command droid -ErrorAction SilentlyContinue) { Write-Host "  - Factory Droid"; $detected += "droid" }
    if ($detected.Count -eq 0) { Write-Host "  (none detected)" }
    Write-Host ""
    Write-Host "Which platform to install for?"
    Write-Host "  [1] Claude Code   -> ~/.claude/"
    Write-Host "  [2] OpenCode      -> ~/.config/opencode/"
    Write-Host "  [3] Factory Droid -> ~/.factory/"
    Write-Host "  [4] All"
    Write-Host ""
    $choice = Read-Host "Choice (1-4)"
    switch ($choice) {
        "1" { $Platform = "claude-code" }
        "2" { $Platform = "opencode" }
        "3" { $Platform = "droid" }
        "4" { $Platform = "all" }
        default { Write-Err "Invalid choice"; exit 1 }
    }
}

# === Components ===
if (-not $Components) { $Components = "all" }
$installAgents = $Components -match "agents|all"
$installSkills = $Components -match "skills|all"
if (-not ($installAgents -or $installSkills)) {
    Write-Err "Invalid NARAYA_COMPONENTS value: $Components (use agents,skills,all)"
    exit 1
}

# === Target dirs per platform ===
# Each platform has agent dir + skill dir
$agentTargets = @{
    "claude-code" = "$env:USERPROFILE\.claude\agents"
    "opencode"    = "$env:USERPROFILE\.config\opencode\agents"
    "droid"       = "$env:USERPROFILE\.factory\droids"
}
$skillTargets = @{
    "claude-code" = "$env:USERPROFILE\.claude\skills"
    "opencode"    = "$env:USERPROFILE\.config\opencode\skills"
    "droid"       = "$env:USERPROFILE\.factory\skills"
}

$platformsToInstall = if ($Platform -eq "all") { @("claude-code", "opencode", "droid") } else { @($Platform) }

foreach ($p in $platformsToInstall) {
    if (-not $agentTargets.ContainsKey($p)) {
        Write-Err "Unknown platform: $p (valid: claude-code, opencode, droid, all)"
        exit 1
    }
}

# === Download repo ===
$tmpDir = Join-Path $env:TEMP "naraya-agents-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$zipPath = Join-Path $tmpDir "repo.zip"
$zipUrl = "$RepoUrl/archive/refs/heads/$Branch.zip"

Write-Info "Downloading from $zipUrl"
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Err "Failed to download: $_"
    Write-Err "Verify the repo URL is correct and the branch exists."
    exit 1
}

Write-Info "Extracting..."
Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force
$extractedRoot = Get-ChildItem $tmpDir -Directory | Where-Object { $_.Name -like "naraya-agents-*" } | Select-Object -First 1
if (-not $extractedRoot) {
    Write-Err "Could not find extracted repo root in $tmpDir"
    exit 1
}

# Source dirs in extracted repo
$agentSources = @{
    "claude-code" = Join-Path $extractedRoot.FullName "platforms\claude-code\agents"
    "opencode"    = Join-Path $extractedRoot.FullName "platforms\opencode\agents"
    "droid"       = Join-Path $extractedRoot.FullName "platforms\droid\droids"
}
$skillsSource = Join-Path $extractedRoot.FullName "skills"

# === Install helper functions ===
function Install-FlatFiles($srcDir, $dstDir, $label) {
    if (-not (Test-Path $srcDir)) {
        Write-Warn "Source not found ($srcDir) - skipping $label"
        return
    }
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    $installed = 0; $unchanged = 0; $updated = 0
    Get-ChildItem $srcDir -Filter "*.md" -File | ForEach-Object {
        $dstFile = Join-Path $dstDir $_.Name
        if (Test-Path $dstFile) {
            $h1 = (Get-FileHash $dstFile -Algorithm SHA256).Hash
            $h2 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            if ($h1 -eq $h2) { $unchanged++; return }
            Copy-Item $dstFile "$dstFile.bak" -Force
            $updated++
        } else {
            $installed++
        }
        Copy-Item $_.FullName $dstFile -Force
    }
    Write-OK ("{0,-13} : {1} new, {2} updated, {3} unchanged" -f $label, $installed, $updated, $unchanged)
}

function Install-SkillFolders($srcRoot, $dstRoot, $label) {
    if (-not (Test-Path $srcRoot)) {
        Write-Warn "Skills source not found ($srcRoot) - skipping $label"
        return
    }
    New-Item -ItemType Directory -Force -Path $dstRoot | Out-Null
    $installed = 0; $unchanged = 0; $updated = 0
    Get-ChildItem $srcRoot -Directory | ForEach-Object {
        $skillName = $_.Name
        $dstSkill = Join-Path $dstRoot $skillName

        # Compare manifest hash (concat of all file hashes inside)
        $srcFiles = Get-ChildItem $_.FullName -Recurse -File | Sort-Object FullName
        $srcManifest = ($srcFiles | ForEach-Object { (Get-FileHash $_.FullName).Hash }) -join '|'

        if (Test-Path $dstSkill) {
            $dstFiles = Get-ChildItem $dstSkill -Recurse -File | Sort-Object FullName
            $dstManifest = ($dstFiles | ForEach-Object { (Get-FileHash $_.FullName).Hash }) -join '|'
            if ($srcManifest -eq $dstManifest) { $unchanged++; return }
            # Backup the SKILL.md only (assets rarely change)
            $existingMain = Join-Path $dstSkill "SKILL.md"
            if (Test-Path $existingMain) { Copy-Item $existingMain "$existingMain.bak" -Force }
            $updated++
        } else {
            $installed++
        }
        # Copy whole folder (overwriting)
        if (Test-Path $dstSkill) { Remove-Item $dstSkill -Recurse -Force }
        Copy-Item $_.FullName $dstSkill -Recurse -Force
    }
    Write-OK ("{0,-13} : {1} new, {2} updated, {3} unchanged" -f $label, $installed, $updated, $unchanged)
}

# === Install per platform ===
Write-Host ""
Write-Info "Installing components: $Components"
Write-Host ""

foreach ($p in $platformsToInstall) {
    Write-Host "=== $p ===" -ForegroundColor Magenta
    if ($installAgents) {
        Install-FlatFiles $agentSources[$p] $agentTargets[$p] "$p agents"
    }
    if ($installSkills) {
        Install-SkillFolders $skillsSource $skillTargets[$p] "$p skills"
    }
    Write-Host ""
}

# Cleanup
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-OK "Installation complete."
Write-Host ""
Write-Host "Next steps:"
foreach ($p in $platformsToInstall) {
    switch ($p) {
        "claude-code" {
            Write-Host "  Claude Code:"
            Write-Host "    1. Restart Claude Code"
            Write-Host "    2. Run /agents - verify naraya-worker is listed"
            Write-Host "    3. Try /handoff to test the manual handoff skill"
        }
        "opencode" {
            Write-Host "  OpenCode:"
            Write-Host "    1. Restart OpenCode"
            Write-Host "    2. @naraya-worker to invoke, or check the agent list"
        }
        "droid" {
            Write-Host "  Factory Droid:"
            Write-Host "    1. Restart Droid"
            Write-Host "    2. Run /droids - verify NARAYA droids appear"
        }
    }
}
Write-Host ""
