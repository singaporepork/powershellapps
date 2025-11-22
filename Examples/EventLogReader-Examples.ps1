<#
.SYNOPSIS
    Example usage of the EventLogReader module.

.DESCRIPTION
    This script demonstrates various event log reading and analysis functions.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
    - Windows operating system
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\EventLogReader.psm1" -Force

Write-Host "EventLogReader Module Examples" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan

# ============================================================================
# Example 1: List available event logs
# ============================================================================

Write-Host "Example 1: List available event logs" -ForegroundColor Yellow
Write-Host "-------------------------------------"

$logs = Get-EventLogNames | Select-Object -First 10
$logs | Format-Table LogName, RecordCount, LastWriteTime -AutoSize

Write-Host ""

# ============================================================================
# Example 2: Get event log summary
# ============================================================================

Write-Host "Example 2: Get event log summary" -ForegroundColor Yellow
Write-Host "---------------------------------"

$summary = Get-EventLogSummary -LogName System -Hours 24
Write-Host "Log: $($summary.LogName)"
Write-Host "Period: $($summary.Period)"
Write-Host "Total Events: $($summary.TotalEvents)"
Write-Host "Critical: $($summary.Critical)"
Write-Host "Errors: $($summary.Error)"
Write-Host "Warnings: $($summary.Warning)"
Write-Host "Top Providers: $($summary.TopProviders -join ', ')"

Write-Host ""

# ============================================================================
# Example 3: Get recent errors
# ============================================================================

Write-Host "Example 3: Get recent errors from System log" -ForegroundColor Yellow
Write-Host "---------------------------------------------"

$errors = Get-EventLogEntries -LogName System -Level Error -MaxEvents 5
if ($errors) {
    $errors | Format-Table TimeCreated, ProviderName, Id, @{L='Message';E={$_.Message.Substring(0, [Math]::Min(50, $_.Message.Length))}} -AutoSize
} else {
    Write-Host "No errors found in System log" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Example 4: Get critical events across logs
# ============================================================================

Write-Host "Example 4: Get critical events (last 24 hours)" -ForegroundColor Yellow
Write-Host "-----------------------------------------------"

$critical = Get-CriticalEvents -Hours 24 | Select-Object -First 5
if ($critical) {
    $critical | Format-Table TimeCreated, LogName, Level, Provider, EventId -AutoSize
} else {
    Write-Host "No critical events found" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Example 5: Filter by Event ID
# ============================================================================

Write-Host "Example 5: Filter by Event ID" -ForegroundColor Yellow
Write-Host "------------------------------"

Write-Host @"
# Get specific Event IDs
`$events = Get-EventLogEntries -LogName Security -EventId 4624,4625 -MaxEvents 20

# Common security Event IDs:
# 4624 - Successful logon
# 4625 - Failed logon
# 4634 - Logoff
# 4648 - Explicit credential logon
# 4672 - Special privileges assigned
"@

Write-Host ""

# ============================================================================
# Example 6: Filter by provider
# ============================================================================

Write-Host "Example 6: Filter by provider" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Get events from specific provider
`$events = Get-EventLogEntries -LogName Application ``
    -ProviderName "MSSQLSERVER" ``
    -MaxEvents 50

# Get events from Windows Update
`$events = Get-EventLogEntries -LogName System ``
    -ProviderName "Microsoft-Windows-WindowsUpdateClient" ``
    -MaxEvents 20
"@

Write-Host ""

# ============================================================================
# Example 7: Filter by date range
# ============================================================================

Write-Host "Example 7: Filter by date range" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Get events from last week
`$events = Get-EventLogEntries -LogName System ``
    -StartTime (Get-Date).AddDays(-7) ``
    -EndTime (Get-Date).AddDays(-1) ``
    -MaxEvents 100

# Get events from specific date
`$events = Get-EventLogEntries -LogName Application ``
    -StartTime "2024-01-15 00:00:00" ``
    -EndTime "2024-01-15 23:59:59"
"@

Write-Host ""

# ============================================================================
# Example 8: Search event messages
# ============================================================================

Write-Host "Example 8: Search event messages" -ForegroundColor Yellow
Write-Host "---------------------------------"

Write-Host @"
# Simple text search
`$events = Search-EventLogMessage -LogName System -Pattern "disk"

# Regex search
`$events = Search-EventLogMessage -LogName Application ``
    -Pattern "error.*connection" ``
    -UseRegex

# Search with date filter
`$events = Search-EventLogMessage -LogName System ``
    -Pattern "service" ``
    -StartTime (Get-Date).AddDays(-3)
"@

Write-Host ""

# ============================================================================
# Example 9: Export events
# ============================================================================

Write-Host "Example 9: Export events" -ForegroundColor Yellow
Write-Host "-------------------------"

Write-Host @"
# Export to CSV
`$events = Get-EventLogEntries -LogName System -Level Error -MaxEvents 100
Export-EventLogEntries -Events `$events -OutputPath "C:\Logs\errors.csv"

# Export to JSON
`$events | Export-EventLogEntries -OutputPath "C:\Logs\errors.json" -Format JSON

# Export to HTML report
`$events | Export-EventLogEntries -OutputPath "C:\Logs\errors.html" -Format HTML
"@

Write-Host ""

# ============================================================================
# Example 10: Get frequent events
# ============================================================================

Write-Host "Example 10: Get frequent events" -ForegroundColor Yellow
Write-Host "--------------------------------"

$frequent = Get-FrequentEvents -LogName System -Hours 24 -Top 5
if ($frequent) {
    $frequent | Format-Table EventId, Provider, Level, Count, LastOccur -AutoSize
} else {
    Write-Host "No frequent events found" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Example 11: Get event trends
# ============================================================================

Write-Host "Example 11: Get event trends" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Get daily trend
`$trend = Get-EventLogTrend -LogName System -Days 7 -GroupBy Day
`$trend | Format-Table

# Get hourly trend for errors
`$trend = Get-EventLogTrend -LogName Application ``
    -Days 1 ``
    -GroupBy Hour ``
    -Level Error
"@

Write-Host ""

# ============================================================================
# Example 12: Monitor event log
# ============================================================================

Write-Host "Example 12: Monitor event log (Watch mode)" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host @"
# Watch for new events (press Ctrl+C to stop)
Watch-EventLog -LogName System -Level Error,Warning -IntervalSeconds 5

# Watch specific provider
Watch-EventLog -LogName Application ``
    -ProviderName "MyApplication" ``
    -IntervalSeconds 2 ``
    -Duration 30
"@

Write-Host ""

# ============================================================================
# Example 13: Get providers for a log
# ============================================================================

Write-Host "Example 13: Get event log providers" -ForegroundColor Yellow
Write-Host "------------------------------------"

$providers = Get-EventLogProviders -LogName System | Select-Object -First 10
$providers | Format-Table ProviderName -AutoSize

Write-Host ""

# ============================================================================
# Example 14: Complete analysis workflow
# ============================================================================

Write-Host "Example 14: Complete analysis workflow" -ForegroundColor Yellow
Write-Host "---------------------------------------"

Write-Host @"
# Daily health check script

Import-Module ".\Modules\EventLogReader.psm1"

# Get summaries for main logs
`$logs = @('System', 'Application')
`$results = foreach (`$log in `$logs) {
    Get-EventLogSummary -LogName `$log -Hours 24
}

# Display summary
Write-Host "=== Daily Event Log Summary ===" -ForegroundColor Cyan
`$results | Format-Table LogName, TotalEvents, Critical, Error, Warning

# Get critical events
`$critical = Get-CriticalEvents -Hours 24
if (`$critical.Count -gt 0) {
    Write-Host "`nCritical/Error Events:" -ForegroundColor Red
    `$critical | Select-Object -First 10 | Format-Table TimeCreated, LogName, Level, Provider, EventId
}

# Export report
`$reportPath = "C:\Reports\DailyEventLog_`$(Get-Date -Format 'yyyyMMdd').html"
`$critical | Export-EventLogEntries -OutputPath `$reportPath -Format HTML
Write-Host "`nReport saved to: `$reportPath"
"@

Write-Host ""

# ============================================================================
# Example 15: Remote computer queries
# ============================================================================

Write-Host "Example 15: Remote computer queries" -ForegroundColor Yellow
Write-Host "------------------------------------"

Write-Host @"
# Query remote computer
`$events = Get-EventLogEntries -LogName System ``
    -Level Error ``
    -ComputerName "Server01" ``
    -MaxEvents 50

# With credentials
`$cred = Get-Credential
`$events = Get-EventLogEntries -LogName Application ``
    -ComputerName "Server01" ``
    -Credential `$cred ``
    -MaxEvents 100

# Get remote log summary
`$summary = Get-EventLogSummary -LogName System -ComputerName "Server01"
"@

Write-Host ""

# ============================================================================
# Example 16: Security audit
# ============================================================================

Write-Host "Example 16: Security audit" -ForegroundColor Yellow
Write-Host "---------------------------"

Write-Host @"
# Failed logon attempts
`$failed = Get-EventLogEntries -LogName Security ``
    -EventId 4625 ``
    -MaxEvents 100 ``
    -StartTime (Get-Date).AddDays(-7)

# Successful logons
`$success = Get-EventLogEntries -LogName Security ``
    -EventId 4624 ``
    -MaxEvents 100

# Account changes
`$changes = Get-EventLogEntries -LogName Security ``
    -EventId 4720,4722,4725,4726 ``
    -MaxEvents 50

# 4720 - User account created
# 4722 - User account enabled
# 4725 - User account disabled
# 4726 - User account deleted
"@

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Common Event Log Names:" -ForegroundColor Gray
Write-Host "  System         - OS and driver events" -ForegroundColor Gray
Write-Host "  Application    - Application events" -ForegroundColor Gray
Write-Host "  Security       - Security/audit events (requires Admin)" -ForegroundColor Gray
Write-Host "  Setup          - Windows setup events" -ForegroundColor Gray
Write-Host "  PowerShellCore - PowerShell events" -ForegroundColor Gray
