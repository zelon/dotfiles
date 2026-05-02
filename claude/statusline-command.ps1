#!/usr/bin/env pwsh

# Read JSON from stdin
$inputJson = [Console]::In.ReadToEnd()

# for debugging
#$inputJson | Set-Content -Path D:/tmp/claude_input.json

$data = $inputJson | ConvertFrom-Json

# Helper: safely get nested property by dot-notation key
function Get-JsonValue {
    param($obj, [string]$key)
    $val = $obj
    foreach ($p in $key -split '\.') {
        if ($null -eq $val) { return '' }
        $val = $val.$p
    }
    return "$val"
}

# ANSI Color Codes
$ESC     = [char]27
$CYAN    = "$ESC[36m"
$GREEN   = "$ESC[32m"
$YELLOW  = "$ESC[33m"
$RED     = "$ESC[31m"
$BLUE    = "$ESC[34m"
$RESET   = "$ESC[0m"

# Parse fields
$cwd                     = Get-JsonValue $data "cwd"
$currentModel           = Get-JsonValue $data "model.id"
$contextUsedPercent      = [int](Get-JsonValue $data "context_window.used_percentage")
$contextRemainingPercent = [int](Get-JsonValue $data "context_window.remaining_percentage")

# Current git branch
$currentBranch = "UNKNOWN"
git rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    $currentBranch = (git branch --show-current 2>$null)
}

# 5-hour rate limit
$fivePercent    = [int](Get-JsonValue $data "rate_limits.five_hour.used_percentage")
$fiveResetStamp = [long](Get-JsonValue $data "rate_limits.five_hour.resets_at")
$fiveResets     = [System.DateTimeOffset]::FromUnixTimeSeconds($fiveResetStamp).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss zzz")

# Weekly rate limit
$weekPercent    = [int](Get-JsonValue $data "rate_limits.seven_day.used_percentage")
$weekResetStamp = [long](Get-JsonValue $data "rate_limits.seven_day.resets_at")
$weekResets     = [System.DateTimeOffset]::FromUnixTimeSeconds($weekResetStamp).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss zzz")

# Progress bar builder
function New-Bar([int]$percent) {
    $filled = [Math]::Floor($percent / 10)
    $empty  = 10 - $filled
    return ('#' * $filled) + ('-' * $empty)
}

$currentBar = New-Bar $fivePercent
$weekBar    = New-Bar $weekPercent

# Select colors
$contextColor = ""
if ($contextUsedPercent -ge 80) { $contextColor = $YELLOW }
if ($contextUsedPercent -ge 90) { $contextColor = $RED    }

$currentColor = ""
if ($fivePercent -ge 70) { $currentColor = $YELLOW }
if ($fivePercent -ge 90) { $currentColor = $RED    }

$weekColor = ""
if ($weekPercent -ge 70) { $weekColor = $YELLOW }
if ($weekPercent -ge 90) { $weekColor = $RED    }

# Output (matches bash version layout)
Write-Output "- ${cwd} | branch: ${currentBranch} | model: ${currentModel} |${contextColor} context_window_used: ${contextUsedPercent}% ${RESET}"
Write-Output "-${currentColor} current: ${currentBar} ${fivePercent}%, reset: ${fiveResets} ${RESET}"
Write-Output "-${weekColor}    week: ${weekBar} ${weekPercent}%, reset: ${weekResets} ${RESET}"
