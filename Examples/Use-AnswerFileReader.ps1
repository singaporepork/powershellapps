<#
.SYNOPSIS
    Example script demonstrating how to use the AnswerFileReader module.

.DESCRIPTION
    Shows various ways to read and use values from answer files using the
    AnswerFileReader module.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\AnswerFileReader.psm1"
Import-Module $modulePath -Force

Write-Host "=== AnswerFileReader Module Examples ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Read entire INI file
Write-Host "Example 1: Reading entire INI file" -ForegroundColor Yellow
$iniPath = Join-Path $PSScriptRoot "sample-config.ini"
$iniConfig = Read-AnswerFile -FilePath $iniPath

Write-Host "Database ServerName: $($iniConfig.Database.ServerName)"
Write-Host "Application Name: $($iniConfig.Application.AppName)"
Write-Host ""

# Example 2: Read specific section from INI file
Write-Host "Example 2: Reading specific section from INI file" -ForegroundColor Yellow
$dbConfig = Read-AnswerFile -FilePath $iniPath -DefaultSection "Database"

Write-Host "Database Configuration:"
$dbConfig.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}
Write-Host ""

# Example 3: Get specific value from answer file
Write-Host "Example 3: Getting specific value" -ForegroundColor Yellow
$serverName = Get-AnswerFileValue -FilePath $iniPath -Key "Database.ServerName"
Write-Host "Server Name: $serverName"

$port = Get-AnswerFileValue -FilePath $iniPath -Key "Database.Port" -DefaultValue 1433
Write-Host "Port: $port"
Write-Host ""

# Example 4: Test if key exists
Write-Host "Example 4: Testing if key exists" -ForegroundColor Yellow
if (Test-AnswerFileKey -FilePath $iniPath -Key "Database.ServerName") {
    Write-Host "Database.ServerName exists!" -ForegroundColor Green
}

if (-not (Test-AnswerFileKey -FilePath $iniPath -Key "Database.NonExistent")) {
    Write-Host "Database.NonExistent does not exist" -ForegroundColor Gray
}
Write-Host ""

# Example 5: Read JSON file
Write-Host "Example 5: Reading JSON file" -ForegroundColor Yellow
$jsonPath = Join-Path $PSScriptRoot "sample-config.json"
$jsonConfig = Read-AnswerFile -FilePath $jsonPath

Write-Host "Application Version: $($jsonConfig.Application.Version)"
Write-Host "Network UseSSL: $($jsonConfig.Network.UseSSL)"
Write-Host ""

# Example 6: Read XML file
Write-Host "Example 6: Reading XML file" -ForegroundColor Yellow
$xmlPath = Join-Path $PSScriptRoot "sample-config.xml"
$xmlConfig = Read-AnswerFile -FilePath $xmlPath

Write-Host "Database Name: $($xmlConfig.Database.DatabaseName)"
Write-Host ""

# Example 7: Read simple key-value file
Write-Host "Example 7: Reading simple key-value file" -ForegroundColor Yellow
$txtPath = Join-Path $PSScriptRoot "sample-config.txt"
$txtConfig = Read-AnswerFile -FilePath $txtPath

Write-Host "Server Name: $($txtConfig.ServerName)"
Write-Host "Port: $($txtConfig.Port)"
Write-Host "Log Path: $($txtConfig.LogPath)"
Write-Host ""

# Example 8: Using in a real-world scenario
Write-Host "Example 8: Real-world usage - Database connection" -ForegroundColor Yellow

function Connect-ToDatabase {
    param([hashtable]$Config)

    Write-Host "Connecting to database..." -ForegroundColor Gray
    Write-Host "  Server: $($Config.ServerName):$($Config.Port)"
    Write-Host "  Database: $($Config.DatabaseName)"
    Write-Host "  User: $($Config.Username)"
    Write-Host "  Timeout: $($Config.Timeout) seconds"
    # In real scenario, you would create actual connection here
    Write-Host "Connection established! (simulated)" -ForegroundColor Green
}

# Read database config and use it
$dbSettings = Read-AnswerFile -FilePath $iniPath -DefaultSection "Database"
Connect-ToDatabase -Config $dbSettings

Write-Host ""
Write-Host "=== Examples Complete ===" -ForegroundColor Cyan
