# NARAYA Agents — Windows / PowerShell installer
# Usage:
#   irm https://raw.githubusercontent.com/<owner>/naraya-agents/main/install/install.ps1 | iex
#
# Or with platform arg:
#   $env:NARAYA_PLATFORM='claude-code'; irm <url> | iex
#
# Supported platforms: claude-code, opencode, droid, all

param(
    [string]$Platform = $env:NARAYA_PLATFORM,
    [string]$RepoUrl = "https://github.com/sirkeldigital/naraya-agents",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Info($msg) { Write-Host "[NARAYA] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[OK]     $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN]   $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[ERROR]  $msg" -ForegroundColor Red }

# Platform detection if not specified
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
    Write-Host "  [1] Claude Code  -> ~/.claude/agents/"
    Write-Host "  [2] OpenCode     -> ~/.config/opencode/agents/"
    Write-Host "  [3] Factory Droid-> ~/.factory/droids/"
    Write-Host "  [4] All detected platforms"
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

# Target dirs per platform
$targets = @{
    "claude-code" = "$env:USERPROFILE\.claude\agents"
    "opencode"    = "$env:USERPROFILE\.config\opencode\agents"
    "droid"       = "$env:USERPROFILE\.factory\droids"
}

$platformsToInstall = if ($Platform -eq "all") { @("claude-code", "opencode", "droid") } else { @($Platform) }

foreach ($p in $platformsToInstall) {
    if (-not $targets.ContainsKey($p)) {
        Write-Err "Unknown platform: $p (valid: claude-code, opencode, droid, all)"
        exit 1
    }
}

# Download repo as zip (no git dependency)
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

# Map platform -> source dir in repo
$sourceDirs = @{
    "claude-code" = Join-Path $extractedRoot.FullName "platforms\claude-code\agents"
    "opencode"    = Join-Path $extractedRoot.FullName "platforms\opencode\agents"
    "droid"       = Join-Path $extractedRoot.FullName "platforms\droid\droids"
}

# Install
foreach ($p in $platformsToInstall) {
    $src = $sourceDirs[$p]
    $dst = $targets[$p]

    if (-not (Test-Path $src)) {
        Write-Warn "Source not found for $p ($src) - skipping"
        continue
    }

    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Write-Info "Installing $p -> $dst"

    $count = 0
    $skipped = 0
    Get-ChildItem $src -Filter "*.md" -File | ForEach-Object {
        $dstFile = Join-Path $dst $_.Name
        $action = "installed"
        if (Test-Path $dstFile) {
            $existingHash = (Get-FileHash $dstFile -Algorithm SHA256).Hash
            $newHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            if ($existingHash -eq $newHash) {
                $skipped++
                return
            }
            $backup = "$dstFile.bak"
            Copy-Item $dstFile $backup -Force
            $action = "updated (backup: $($_.Name).bak)"
        }
        Copy-Item $_.FullName $dstFile -Force
        $count++
    }
    Write-OK "$p : $count files installed, $skipped unchanged"
}

# Cleanup
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-OK "Installation complete."
Write-Host ""
Write-Host "Next steps:"
foreach ($p in $platformsToInstall) {
    switch ($p) {
        "claude-code" { Write-Host "  Claude Code: restart, then run '/agents' to verify naraya-worker appears" }
        "opencode"    { Write-Host "  OpenCode:    restart, then '@naraya-worker' or check 'agent' list" }
        "droid"       { Write-Host "  Droid:       restart, then '/droids' to verify" }
    }
}
Write-Host ""
