<#
.SYNOPSIS
    Example: Converting dates to Unix timestamps and vice versa

.DESCRIPTION
    Demonstrates how to use the UnixTimeConverter module for date/time conversions.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\UnixTimeConverter.psm1"
Import-Module $modulePath -Force

Write-Host "=== Unix Time Converter Examples ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Get current Unix timestamp
Write-Host "Example 1: Get current Unix timestamp" -ForegroundColor Yellow

$currentTimestamp = Get-UnixTime
Write-Host "Current Unix timestamp (seconds): $currentTimestamp" -ForegroundColor Green

$currentTimestampMs = Get-UnixTime -Precision Milliseconds -AsInteger
Write-Host "Current Unix timestamp (milliseconds): $currentTimestampMs" -ForegroundColor Green
Write-Host ""

# Example 2: Convert specific date to Unix timestamp
Write-Host "Example 2: Convert specific date to Unix timestamp" -ForegroundColor Yellow

$specificDate = Get-Date "2024-01-15 10:30:00"
Write-Host "Original date: $($specificDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

$timestamp = ConvertTo-UnixTime -DateTime $specificDate
Write-Host "Unix timestamp: $timestamp" -ForegroundColor Green

$timestampInt = ConvertTo-UnixTime -DateTime $specificDate -AsInteger
Write-Host "Unix timestamp (integer): $timestampInt" -ForegroundColor Green
Write-Host ""

# Example 3: Convert Unix timestamp back to DateTime
Write-Host "Example 3: Convert Unix timestamp to DateTime" -ForegroundColor Yellow

$unixTimestamp = 1705315800
Write-Host "Unix timestamp: $unixTimestamp" -ForegroundColor Gray

$dateUTC = ConvertFrom-UnixTime -Timestamp $unixTimestamp
Write-Host "Date (UTC): $($dateUTC.ToString('yyyy-MM-dd HH:mm:ss')) UTC" -ForegroundColor Green

$dateLocal = ConvertFrom-UnixTime -Timestamp $unixTimestamp -ToLocalTime
Write-Host "Date (Local): $($dateLocal.ToString('yyyy-MM-dd HH:mm:ss')) Local" -ForegroundColor Green
Write-Host ""

# Example 4: Convert date string to Unix timestamp
Write-Host "Example 4: Convert date string to Unix timestamp" -ForegroundColor Yellow

$dateString = "2024-12-25 00:00:00"
Write-Host "Date string: $dateString" -ForegroundColor Gray

$timestamp = ConvertTo-UnixTimeFromString -DateString $dateString
Write-Host "Unix timestamp: $timestamp" -ForegroundColor Green

# Different date format
$dateString2 = "01/15/2024"
$timestamp2 = ConvertTo-UnixTimeFromString -DateString $dateString2 -Format "MM/dd/yyyy"
Write-Host "Date '$dateString2' as Unix timestamp: $timestamp2" -ForegroundColor Green
Write-Host ""

# Example 5: Format Unix timestamp as readable string
Write-Host "Example 5: Format Unix timestamp as readable string" -ForegroundColor Yellow

$unixTimestamp = 1705315800
Write-Host "Unix timestamp: $unixTimestamp" -ForegroundColor Gray

$formatted = Format-UnixTimestamp -Timestamp $unixTimestamp
Write-Host "Formatted (default): $formatted" -ForegroundColor Green

$formatted2 = Format-UnixTimestamp -Timestamp $unixTimestamp -Format "MM/dd/yyyy hh:mm:ss tt"
Write-Host "Formatted (custom): $formatted2" -ForegroundColor Green

$formatted3 = Format-UnixTimestamp -Timestamp $unixTimestamp -Format "dddd, MMMM dd, yyyy" -ToLocalTime
Write-Host "Formatted (local): $formatted3" -ForegroundColor Green
Write-Host ""

# Example 6: Working with milliseconds
Write-Host "Example 6: Working with millisecond precision" -ForegroundColor Yellow

$date = Get-Date "2024-01-15 10:30:00.500"
Write-Host "Date: $($date.ToString('yyyy-MM-dd HH:mm:ss.fff'))" -ForegroundColor Gray

$timestampMs = ConvertTo-UnixTime -DateTime $date -Precision Milliseconds
Write-Host "Unix timestamp (ms): $timestampMs" -ForegroundColor Green

$convertedBack = ConvertFrom-UnixTime -Timestamp $timestampMs -Precision Milliseconds
Write-Host "Converted back: $($convertedBack.ToString('yyyy-MM-dd HH:mm:ss.fff'))" -ForegroundColor Green
Write-Host ""

# Example 7: Validate Unix timestamps
Write-Host "Example 7: Validate Unix timestamps" -ForegroundColor Yellow

$validTimestamp = 1705315800
$invalidTimestamp = 999999999999999

Write-Host "Testing $validTimestamp..." -ForegroundColor Gray
if (Test-UnixTimestamp -Timestamp $validTimestamp) {
    Write-Host "  Valid Unix timestamp" -ForegroundColor Green
}

Write-Host "Testing $invalidTimestamp..." -ForegroundColor Gray
if (-not (Test-UnixTimestamp -Timestamp $invalidTimestamp)) {
    Write-Host "  Invalid Unix timestamp" -ForegroundColor Red
}
Write-Host ""

# Example 8: Calculate time differences
Write-Host "Example 8: Calculate time differences" -ForegroundColor Yellow

$startDate = Get-Date "2024-01-01 00:00:00"
$endDate = Get-Date "2024-01-15 10:30:00"

Write-Host "Start: $($startDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "End: $($endDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

$diffSeconds = Get-TimeDifference -StartDate $startDate -EndDate $endDate -Unit Seconds
Write-Host "Difference: $diffSeconds seconds" -ForegroundColor Green

$diffHours = Get-TimeDifference -StartDate $startDate -EndDate $endDate -Unit Hours
Write-Host "Difference: $([Math]::Round($diffHours, 2)) hours" -ForegroundColor Green

$diffDays = Get-TimeDifference -StartDate $startDate -EndDate $endDate -Unit Days
Write-Host "Difference: $([Math]::Round($diffDays, 2)) days" -ForegroundColor Green
Write-Host ""

# Example 9: Add time to Unix timestamp
Write-Host "Example 9: Add/subtract time from Unix timestamp" -ForegroundColor Yellow

$originalTimestamp = 1705315800
Write-Host "Original timestamp: $originalTimestamp" -ForegroundColor Gray
Write-Host "Original date: $(Format-UnixTimestamp -Timestamp $originalTimestamp)" -ForegroundColor Gray

# Add 2 hours
$newTimestamp = Add-UnixTime -Timestamp $originalTimestamp -Hours 2
Write-Host "After adding 2 hours: $(Format-UnixTimestamp -Timestamp $newTimestamp)" -ForegroundColor Green

# Subtract 30 days
$oldTimestamp = Add-UnixTime -Timestamp $originalTimestamp -Days -30
Write-Host "After subtracting 30 days: $(Format-UnixTimestamp -Timestamp $oldTimestamp)" -ForegroundColor Green

# Combine multiple units
$complexTimestamp = Add-UnixTime -Timestamp $originalTimestamp -Days 1 -Hours 2 -Minutes 30 -Seconds 45
Write-Host "After adding 1d 2h 30m 45s: $(Format-UnixTimestamp -Timestamp $complexTimestamp)" -ForegroundColor Green
Write-Host ""

# Example 10: Get day boundaries
Write-Host "Example 10: Get start and end of day" -ForegroundColor Yellow

$timestamp = 1705315800
$originalDate = Format-UnixTimestamp -Timestamp $timestamp
Write-Host "Original: $originalDate" -ForegroundColor Gray

$startOfDay = Get-UnixDayBoundary -Timestamp $timestamp -StartOfDay
Write-Host "Start of day: $(Format-UnixTimestamp -Timestamp $startOfDay)" -ForegroundColor Green

$endOfDay = Get-UnixDayBoundary -Timestamp $timestamp -EndOfDay
Write-Host "End of day: $(Format-UnixTimestamp -Timestamp $endOfDay)" -ForegroundColor Green
Write-Host ""

# Example 11: Batch conversion
Write-Host "Example 11: Batch convert multiple dates" -ForegroundColor Yellow

$dates = @(
    (Get-Date "2024-01-01"),
    (Get-Date "2024-01-15"),
    (Get-Date "2024-02-01")
)

Write-Host "Converting $($dates.Count) dates..." -ForegroundColor Gray
$results = ConvertTo-UnixTimeBatch -Dates $dates

$results | Format-Table @{Label="Date"; Expression={$_.OriginalDate.ToString("yyyy-MM-dd")}},
                        @{Label="Unix Timestamp"; Expression={$_.UnixTimestamp}},
                        @{Label="UTC"; Expression={$_.UTC.ToString("yyyy-MM-dd HH:mm:ss")}} -AutoSize
Write-Host ""

# Example 12: Pipeline usage
Write-Host "Example 12: Pipeline usage" -ForegroundColor Yellow

Write-Host "Converting date strings via pipeline:" -ForegroundColor Gray
@("2024-01-01", "2024-06-15", "2024-12-31") | ForEach-Object {
    $timestamp = ConvertTo-UnixTimeFromString -DateString $_
    Write-Host "  $_ -> $timestamp" -ForegroundColor Green
}

Write-Host ""
Write-Host "Converting timestamps back via pipeline:" -ForegroundColor Gray
@(1704067200, 1718409600, 1735689600) | ForEach-Object {
    $date = ConvertFrom-UnixTime -Timestamp $_ | ForEach-Object { $_.ToString("yyyy-MM-dd") }
    Write-Host "  $_ -> $date" -ForegroundColor Green
}
Write-Host ""

# Example 13: Real-world usage - Log file processing
Write-Host "Example 13: Real-world example - Process log timestamps" -ForegroundColor Yellow
Write-Host ""

function Convert-LogTimestamps {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogEntry
    )

    try {
        # Extract Unix timestamp from log entry (assuming format: [timestamp] message)
        if ($LogEntry -match '^\[(\d+)\](.*)$') {
            $timestamp = [double]$matches[1]
            $message = $matches[2].Trim()

            # Convert to readable date
            $date = Format-UnixTimestamp -Timestamp $timestamp -ToLocalTime

            return [PSCustomObject]@{
                Timestamp = $timestamp
                Date = $date
                Message = $message
            }
        }
        return $null
    }
    catch {
        Write-Warning "Failed to parse log entry: $_"
        return $null
    }
}

# Sample log entries with Unix timestamps
$logEntries = @(
    "[1705315800] Application started",
    "[1705315860] Database connection established",
    "[1705315920] User login: admin",
    "[1705316000] Processing batch job"
)

Write-Host "Converting log timestamps:" -ForegroundColor Cyan
$logEntries | ForEach-Object {
    $parsed = Convert-LogTimestamps -LogEntry $_
    if ($parsed) {
        Write-Host "  [$($parsed.Date)] $($parsed.Message)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Examples Complete ===" -ForegroundColor Cyan
