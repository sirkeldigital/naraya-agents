# Build per-platform agent files from source/*.md
# Source format: YAML frontmatter (name, description) + body
# Outputs:
#   platforms/claude-code/agents/*.md  (Claude Code format)
#   platforms/opencode/agents/*.md     (OpenCode markdown agent format: description + mode + body)
#   platforms/droid/droids/*.md        (Factory Droid format)
$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$root = $PSScriptRoot
$sourceDir = Join-Path $root "source"
$claudeOut = Join-Path $root "platforms\claude-code\agents"
$opencodeOut = Join-Path $root "platforms\opencode\agents"
$droidOut = Join-Path $root "platforms\droid\droids"

foreach ($d in @($claudeOut, $opencodeOut, $droidOut)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

function Parse-Source($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if (-not $text.StartsWith("---")) {
        $first40 = $text.Substring(0, [Math]::Min(40, $text.Length))
        throw "No frontmatter in $path (starts with: '$first40')"
    }
    $end = $text.IndexOf("`n---", 3)
    if ($end -lt 0) { throw "Unterminated frontmatter in $path" }
    $fm = $text.Substring(3, $end - 3).Trim()
    $body = $text.Substring($end + 4).TrimStart()
    $meta = @{}
    foreach ($line in $fm -split "`r?`n") {
        if ($line -match "^(\w+):\s*(.*)$") {
            $meta[$matches[1]] = $matches[2].Trim()
        }
    }
    return @{ meta = $meta; body = $body }
}

function Yaml-Quote($s) {
    if ($s -match '^[a-zA-Z0-9 _.,()/&;:+*?%@!=\#-]+$' -and $s -notmatch '^[-?!&*|>]' -and $s.Length -lt 500) {
        # Safe unquoted
        return $s
    }
    return '"' + ($s -replace '"','\"') + '"'
}

function Write-NoBom($path, $content) {
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$sources = Get-ChildItem $sourceDir -Filter "*.md"
foreach ($f in $sources) {
    $parsed = Parse-Source $f.FullName
    $name = $parsed.meta['name']
    $desc = $parsed.meta['description']
    $body = $parsed.body

    # === Claude Code ===
    $claudeFm = @"
---
name: $name
description: $(Yaml-Quote $desc)
model: inherit
---

"@
    Write-NoBom (Join-Path $claudeOut "$name.md") ($claudeFm + $body)

    # === OpenCode markdown ===
    # mode: primary for naraya-worker; subagent for others
    $mode = if ($name -eq "naraya-worker") { "primary" } else { "all" }
    $opencodeFm = @"
---
description: $(Yaml-Quote $desc)
mode: $mode
---

"@
    Write-NoBom (Join-Path $opencodeOut "$name.md") ($opencodeFm + $body)

    # === Droid ===
    # tools left unset = all tools; users can lock down explorer to read-only later
    $droidFm = @"
---
name: $name
description: $(Yaml-Quote $desc)
model: inherit
---

"@
    Write-NoBom (Join-Path $droidOut "$name.md") ($droidFm + $body)
}

Write-Host "Built $($sources.Count) agents x 3 platforms = $($sources.Count * 3) files"
Write-Host ""
Write-Host "Claude Code:"; Get-ChildItem $claudeOut -Filter "*.md" | Select-Object Name
Write-Host ""
Write-Host "OpenCode:"; Get-ChildItem $opencodeOut -Filter "*.md" | Select-Object Name
Write-Host ""
Write-Host "Droid:"; Get-ChildItem $droidOut -Filter "*.md" | Select-Object Name
