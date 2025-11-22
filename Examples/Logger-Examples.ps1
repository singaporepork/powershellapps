<#
.SYNOPSIS
    Example usage of the Logger module.

.DESCRIPTION
    This script demonstrates various ways to use the Logger module
    for application logging in PowerShell.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\Logger.psm1" -Force

Write-Host "Logger Module Examples" -ForegroundColor Cyan
Write-Host "=====================`n" -ForegroundColor Cyan

# ============================================================================
# Example 1: Console-only logging (default)
# ============================================================================

Write-Host "Example 1: Console-only logging" -ForegroundColor Yellow
Write-Host "--------------------------------"

# Initialize for console output only
Initialize-Logger -LogLevel DEBUG -LogToConsole $true -UseColors $true

Write-LogDebug "This is a debug message"
Write-LogInfo "This is an info message"
Write-LogWarning "This is a warning message"
Write-LogError "This is an error message"
Write-LogCritical "This is a critical message"

Write-Host ""

# ============================================================================
# Example 2: File logging
# ============================================================================

Write-Host "Example 2: File logging" -ForegroundColor Yellow
Write-Host "-----------------------"

$logPath = "$PSScriptRoot\example.log"

# Initialize with file output
Initialize-Logger -LogPath $logPath `
                  -LogLevel INFO `
                  -LogToConsole $true `
                  -LogToFile $true `
                  -MaxFileSizeMB 5 `
                  -MaxLogFiles 3

Write-LogInfo "Application started"
Write-LogInfo "Log file created at: $logPath"

# Check file size
$size = Get-LogFileSize
if ($size) {
    Write-LogInfo "Current log size: $($size.SizeKB) KB"
}

Write-Host ""

# ============================================================================
# Example 3: Logging with caller information
# ============================================================================

Write-Host "Example 3: Caller information" -ForegroundColor Yellow
Write-Host "------------------------------"

# Reinitialize with caller info
Initialize-Logger -LogLevel DEBUG `
                  -LogToConsole $true `
                  -LogToFile $false `
                  -IncludeCaller $true

function Do-Something {
    Write-LogInfo "This message includes the caller function name"
}

function Process-Data {
    Write-LogDebug "Processing data..."
    Do-Something
}

Process-Data

Write-Host ""

# ============================================================================
# Example 4: Exception logging
# ============================================================================

Write-Host "Example 4: Exception logging" -ForegroundColor Yellow
Write-Host "-----------------------------"

Initialize-Logger -LogLevel DEBUG -LogToConsole $true -IncludeCaller $false

try {
    # Simulate an error
    throw [System.IO.FileNotFoundException]::new("Configuration file not found", "config.json")
}
catch {
    Write-LogError "Failed to load configuration" -Exception $_.Exception
}

try {
    # Simulate division by zero
    $result = 1 / 0
}
catch {
    Write-LogError "Calculation error" -Exception $_.Exception
}

Write-Host ""

# ============================================================================
# Example 5: Operation tracking
# ============================================================================

Write-Host "Example 5: Operation tracking" -ForegroundColor Yellow
Write-Host "------------------------------"

Initialize-Logger -LogLevel INFO -LogToConsole $true

# Simulate a database backup operation
Start-LogOperation "Database Backup"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-LogInfo "Connecting to database server..."
Start-Sleep -Milliseconds 100

Write-LogInfo "Creating backup..."
Start-Sleep -Milliseconds 200

Write-LogInfo "Compressing backup file..."
Start-Sleep -Milliseconds 150

$stopwatch.Stop()

Complete-LogOperation "Database Backup" -Success $true -Duration $stopwatch.Elapsed

Write-Host ""

# ============================================================================
# Example 6: Headers and separators
# ============================================================================

Write-Host "Example 6: Headers and separators" -ForegroundColor Yellow
Write-Host "----------------------------------"

Initialize-Logger -LogLevel INFO -LogToConsole $true

Write-LogHeader "System Initialization"

Write-LogInfo "Loading configuration..."
Write-LogInfo "Initializing services..."
Write-LogInfo "Starting web server..."

Write-LogSeparator

Write-LogInfo "System ready"

Write-Host ""

# ============================================================================
# Example 7: Logging objects
# ============================================================================

Write-Host "Example 7: Logging objects" -ForegroundColor Yellow
Write-Host "--------------------------"

Initialize-Logger -LogLevel DEBUG -LogToConsole $true

# Log a hashtable
$config = @{
    Server = "localhost"
    Port = 8080
    EnableSSL = $true
    Timeout = 30
}

Write-LogObject -InputObject $config -Name "Application Configuration"

Write-Host ""

# Log a custom object
$stats = [PSCustomObject]@{
    TotalRequests = 1523
    SuccessRate = "98.5%"
    AvgResponseMs = 45
}

Write-LogObject -InputObject $stats -Name "Server Statistics"

Write-Host ""

# ============================================================================
# Example 8: Changing log level at runtime
# ============================================================================

Write-Host "Example 8: Dynamic log level" -ForegroundColor Yellow
Write-Host "-----------------------------"

Initialize-Logger -LogLevel WARNING -LogToConsole $true

Write-LogDebug "This DEBUG won't show (level is WARNING)"
Write-LogInfo "This INFO won't show (level is WARNING)"
Write-LogWarning "This WARNING will show"

# Change to DEBUG
Set-LogLevel -Level DEBUG

Write-LogDebug "Now DEBUG shows after level change"
Write-LogInfo "INFO also shows now"

Write-Host ""

# ============================================================================
# Example 9: Reading log entries
# ============================================================================

Write-Host "Example 9: Reading log entries" -ForegroundColor Yellow
Write-Host "-------------------------------"

# Create a log file with entries
$logPath = "$PSScriptRoot\test-read.log"
Initialize-Logger -LogPath $logPath -LogLevel DEBUG -LogToFile $true -LogToConsole $false

Write-LogDebug "Debug entry 1"
Write-LogInfo "Info entry 1"
Write-LogWarning "Warning entry 1"
Write-LogError "Error entry 1"
Write-LogInfo "Info entry 2"
Write-LogError "Error entry 2"

# Re-enable console for output
Initialize-Logger -LogLevel INFO -LogToConsole $true -LogToFile $false

# Get last 3 entries
Write-Host "`nLast 3 entries:" -ForegroundColor Gray
Get-LogEntries -Last 3 | ForEach-Object { Write-Host "  $_" }

# Get only errors
Write-Host "`nError entries:" -ForegroundColor Gray
Get-LogEntries -Level ERROR | ForEach-Object { Write-Host "  $_" }

# Get as objects
Write-Host "`nEntries as objects:" -ForegroundColor Gray
Get-LogEntries -AsObject | Format-Table -AutoSize

# Cleanup
Remove-Item $logPath -Force -ErrorAction SilentlyContinue

Write-Host ""

# ============================================================================
# Example 10: Complete application example
# ============================================================================

Write-Host "Example 10: Complete application" -ForegroundColor Yellow
Write-Host "---------------------------------"

$appLogPath = "$PSScriptRoot\app.log"

# Initialize logger
Initialize-Logger -LogPath $appLogPath `
                  -LogLevel INFO `
                  -LogToConsole $true `
                  -LogToFile $true `
                  -IncludeCaller $false `
                  -MaxFileSizeMB 10

Write-LogHeader "Application Startup"

# Log configuration
$appConfig = @{
    Version = "1.0.0"
    Environment = "Development"
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
Write-LogObject -InputObject $appConfig -Name "Application Info"

Write-LogSeparator

# Simulate application workflow
Start-LogOperation "User Authentication"
Write-LogInfo "Validating credentials..."
Start-Sleep -Milliseconds 50
Write-LogInfo "Loading user profile..."
Complete-LogOperation "User Authentication" -Success $true

Start-LogOperation "Data Processing"
Write-LogInfo "Fetching records from database..."
Write-LogInfo "Processing 100 records..."
Write-LogWarning "Skipped 3 invalid records"
Complete-LogOperation "Data Processing" -Success $true

Start-LogOperation "Report Generation"
try {
    Write-LogInfo "Generating report..."
    # Simulate partial failure
    throw "PDF generation failed"
}
catch {
    Write-LogError "Report generation failed: $_"
    Complete-LogOperation "Report Generation" -Success $false
}

Write-LogSeparator -Character '='

# Show log file info
$logInfo = Get-LogFileSize
Write-LogInfo "Log file: $($logInfo.Path)"
Write-LogInfo "Log size: $($logInfo.SizeKB) KB ($($logInfo.PercentUsed)% of max)"

Write-LogHeader "Application Shutdown"

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Log file created at: $appLogPath" -ForegroundColor Gray
Write-Host "View with: Get-Content '$appLogPath'" -ForegroundColor Gray

# Cleanup example files
Write-Host "`nCleaning up example log files..." -ForegroundColor Gray
Remove-Item "$PSScriptRoot\example.log" -Force -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\app.log" -Force -ErrorAction SilentlyContinue
