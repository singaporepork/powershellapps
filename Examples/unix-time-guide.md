# Unix Time Converter Guide

## Overview

The UnixTimeConverter module provides comprehensive tools for working with Unix timestamps in PowerShell. Unix time (also known as POSIX time or epoch time) represents the number of seconds that have elapsed since January 1, 1970, 00:00:00 UTC.

## What is Unix Time?

Unix time is a system for describing a point in time. It is the number of seconds that have elapsed since the Unix epoch:
- **Epoch Start**: January 1, 1970, 00:00:00 UTC
- **Common Formats**: Seconds, milliseconds, microseconds

## Why Use Unix Time?

1. **Universal**: Platform and timezone independent
2. **Simple**: Just a number, easy to store and compare
3. **Efficient**: Easy to perform time arithmetic
4. **Standardized**: Widely used in APIs, databases, and systems

## Module Functions

### Core Conversion Functions

#### ConvertTo-UnixTime
Convert DateTime objects to Unix timestamps.

```powershell
# Current time
$now = ConvertTo-UnixTime

# Specific date
$timestamp = ConvertTo-UnixTime -DateTime (Get-Date "2024-01-15 10:30:00")

# With precision
$timestampMs = ConvertTo-UnixTime -Precision Milliseconds -AsInteger
```

#### ConvertFrom-UnixTime
Convert Unix timestamps to DateTime objects.

```powershell
# To UTC
$dateUTC = ConvertFrom-UnixTime -Timestamp 1705315800

# To local time
$dateLocal = ConvertFrom-UnixTime -Timestamp 1705315800 -ToLocalTime

# From milliseconds
$date = ConvertFrom-UnixTime -Timestamp 1705315800000 -Precision Milliseconds
```

#### Get-UnixTime
Get the current Unix timestamp.

```powershell
# Current time in seconds
$now = Get-UnixTime

# Current time in milliseconds
$nowMs = Get-UnixTime -Precision Milliseconds -AsInteger
```

### String and Formatting Functions

#### ConvertTo-UnixTimeFromString
Parse date strings and convert to Unix timestamps.

```powershell
# Auto-parse
$timestamp = ConvertTo-UnixTimeFromString -DateString "2024-01-15 10:30:00"

# With specific format
$timestamp = ConvertTo-UnixTimeFromString -DateString "01/15/2024" -Format "MM/dd/yyyy"

# Via pipeline
"2024-12-25" | ConvertTo-UnixTimeFromString
```

#### Format-UnixTimestamp
Format Unix timestamps as readable strings.

```powershell
# Default format
$formatted = Format-UnixTimestamp -Timestamp 1705315800
# Output: 2024-01-15 10:30:00

# Custom format
$formatted = Format-UnixTimestamp -Timestamp 1705315800 -Format "MM/dd/yyyy hh:mm tt"
# Output: 01/15/2024 10:30 AM

# To local time
$formatted = Format-UnixTimestamp -Timestamp 1705315800 -ToLocalTime
```

### Utility Functions

#### Test-UnixTimestamp
Validate if a number is a reasonable Unix timestamp.

```powershell
if (Test-UnixTimestamp -Timestamp 1705315800) {
    Write-Host "Valid timestamp"
}

# Test milliseconds
Test-UnixTimestamp -Timestamp 1705315800000 -Precision Milliseconds
```

#### Get-TimeDifference
Calculate time differences between dates.

```powershell
$start = Get-Date "2024-01-01"
$end = Get-Date "2024-01-15"

$seconds = Get-TimeDifference -StartDate $start -EndDate $end -Unit Seconds
$hours = Get-TimeDifference -StartDate $start -EndDate $end -Unit Hours
$days = Get-TimeDifference -StartDate $start -EndDate $end -Unit Days
```

#### Add-UnixTime
Perform time arithmetic on Unix timestamps.

```powershell
# Add 2 hours
$newTime = Add-UnixTime -Timestamp 1705315800 -Hours 2

# Subtract 30 days
$oldTime = Add-UnixTime -Timestamp 1705315800 -Days -30

# Combine multiple units
$time = Add-UnixTime -Timestamp 1705315800 -Days 1 -Hours 2 -Minutes 30
```

#### Get-UnixDayBoundary
Get the start or end of day for a timestamp.

```powershell
# Start of day (00:00:00)
$start = Get-UnixDayBoundary -Timestamp 1705315800 -StartOfDay

# End of day (23:59:59)
$end = Get-UnixDayBoundary -Timestamp 1705315800 -EndOfDay
```

#### ConvertTo-UnixTimeBatch
Convert multiple dates at once.

```powershell
$dates = @(
    (Get-Date "2024-01-01"),
    (Get-Date "2024-06-15"),
    (Get-Date "2024-12-31")
)

$results = ConvertTo-UnixTimeBatch -Dates $dates
$results | Format-Table
```

## Common Scenarios

### Scenario 1: API Integration

Many REST APIs use Unix timestamps for date/time fields.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1
Import-Module .\Modules\RestApiAuth.psm1

# Prepare data with Unix timestamps
$data = @{
    event = "user_login"
    timestamp = Get-UnixTime
    user_id = 12345
}

# Post to API
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Bearer -Token $token
$response = Invoke-RestApiRequest -Session $session -Endpoint "/events" -Method POST -Body ($data | ConvertTo-Json)
```

### Scenario 2: Log File Processing

Convert Unix timestamps in log files to readable dates.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1

# Read log file with Unix timestamps
$logEntries = Get-Content "app.log" | ForEach-Object {
    if ($_ -match '^\[(\d+)\]\s+(.*)$') {
        $timestamp = [double]$matches[1]
        $message = $matches[2]

        [PSCustomObject]@{
            Timestamp = $timestamp
            Date = Format-UnixTimestamp -Timestamp $timestamp -ToLocalTime
            Message = $message
        }
    }
}

$logEntries | Format-Table -AutoSize
```

### Scenario 3: Database Queries

Query databases using Unix timestamp ranges.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1

# Get timestamp range for yesterday
$yesterday = (Get-Date).AddDays(-1)
$startOfDay = Get-UnixDayBoundary -Timestamp (ConvertTo-UnixTime -DateTime $yesterday) -StartOfDay
$endOfDay = Get-UnixDayBoundary -Timestamp (ConvertTo-UnixTime -DateTime $yesterday) -EndOfDay

# Use in SQL query
$query = "SELECT * FROM events WHERE timestamp BETWEEN $startOfDay AND $endOfDay"
```

### Scenario 4: File Metadata

Work with file timestamps as Unix time.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1

# Convert file timestamps
Get-ChildItem -Path "C:\Files" | Select-Object Name,
    @{Name='CreatedUnix';Expression={ConvertTo-UnixTime -DateTime $_.CreationTime -AsInteger}},
    @{Name='ModifiedUnix';Expression={ConvertTo-UnixTime -DateTime $_.LastWriteTime -AsInteger}},
    @{Name='Age(Days)';Expression={
        $diff = Get-TimeDifference -StartDate $_.LastWriteTime -Unit Days
        [Math]::Round($diff, 1)
    }}
```

### Scenario 5: Time-based Calculations

Calculate expiry times, retention periods, etc.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1

# Check if token is expired
$tokenTimestamp = 1705315800
$expiryPeriod = 3600 # 1 hour in seconds
$expiryTimestamp = Add-UnixTime -Timestamp $tokenTimestamp -Seconds $expiryPeriod

$currentTime = Get-UnixTime
if ($currentTime -gt $expiryTimestamp) {
    Write-Host "Token expired"
}
else {
    $remaining = $expiryTimestamp - $currentTime
    Write-Host "Token valid for $remaining more seconds"
}
```

### Scenario 6: Data Export

Export data with Unix timestamps for cross-platform compatibility.

```powershell
Import-Module .\Modules\UnixTimeConverter.psm1
Import-Module .\Modules\TextToJson.psm1

# Collect data with Unix timestamps
$systemEvents = @(
    @{
        event = "boot"
        timestamp = ConvertTo-UnixTime -DateTime (Get-Date).AddHours(-10)
        status = "success"
    },
    @{
        event = "update"
        timestamp = ConvertTo-UnixTime -DateTime (Get-Date).AddHours(-5)
        status = "success"
    },
    @{
        event = "backup"
        timestamp = Get-UnixTime
        status = "in_progress"
    }
)

# Export as JSON
$systemEvents | ConvertTo-Json | Out-File "events.json" -Encoding UTF8
```

## Precision Levels

### Seconds (Default)
- **Range**: 0 to ~4,294,967,295 (until year 2106)
- **Use Case**: Most applications, databases, APIs
- **Example**: 1705315800

### Milliseconds
- **Range**: Seconds × 1000
- **Use Case**: High-precision logging, performance monitoring
- **Example**: 1705315800000

### Microseconds
- **Range**: Seconds × 1,000,000
- **Use Case**: Ultra-high precision, scientific applications
- **Example**: 1705315800000000

## Timezone Handling

Unix timestamps are **always in UTC**. When converting:

```powershell
# From local time to Unix (automatic UTC conversion)
$localDate = Get-Date "2024-01-15 10:30:00" # Local time
$timestamp = ConvertTo-UnixTime -DateTime $localDate # Converted to UTC

# From Unix to local time
$timestamp = 1705315800
$localDate = ConvertFrom-UnixTime -Timestamp $timestamp -ToLocalTime
$utcDate = ConvertFrom-UnixTime -Timestamp $timestamp
```

## Best Practices

1. **Always Specify Precision**
   ```powershell
   # Good
   $timestamp = Get-UnixTime -Precision Seconds

   # Better for APIs that need it
   $timestampMs = Get-UnixTime -Precision Milliseconds
   ```

2. **Use ToLocalTime for Display**
   ```powershell
   # For user display, convert to local time
   $displayDate = ConvertFrom-UnixTime -Timestamp $ts -ToLocalTime
   ```

3. **Validate Before Converting**
   ```powershell
   if (Test-UnixTimestamp -Timestamp $value) {
       $date = ConvertFrom-UnixTime -Timestamp $value
   }
   ```

4. **Use AsInteger for Storage**
   ```powershell
   # When storing in databases or files
   $timestamp = Get-UnixTime -AsInteger
   ```

5. **Consistent Precision**
   ```powershell
   # Use the same precision throughout your application
   $created = Get-UnixTime -Precision Milliseconds
   $updated = Get-UnixTime -Precision Milliseconds
   ```

## Common Pitfalls

### Issue: Milliseconds vs Seconds
**Problem**: API returns timestamp that seems wrong.
**Solution**: Check if it's in milliseconds instead of seconds.

```powershell
# If timestamp is very large (13+ digits), it's likely milliseconds
if (Test-UnixTimestamp -Timestamp $value -Precision Milliseconds) {
    $date = ConvertFrom-UnixTime -Timestamp $value -Precision Milliseconds
}
```

### Issue: Timezone Confusion
**Problem**: Dates appear off by several hours.
**Solution**: Remember Unix time is UTC, use -ToLocalTime for display.

```powershell
# For storage/API: UTC
$timestamp = ConvertTo-UnixTime -DateTime $date

# For user display: Local
$displayDate = ConvertFrom-UnixTime -Timestamp $timestamp -ToLocalTime
```

### Issue: Date Arithmetic
**Problem**: Adding days doesn't work as expected.
**Solution**: Use Add-UnixTime function.

```powershell
# Wrong
$newTimestamp = $oldTimestamp + (86400 * 30) # Error prone

# Right
$newTimestamp = Add-UnixTime -Timestamp $oldTimestamp -Days 30
```

## Integration with Other Modules

### With RestApiAuth
```powershell
# Send events with timestamps
$event = @{
    type = "user_action"
    timestamp = Get-UnixTime -Precision Milliseconds
    user_id = 123
}

$json = $event | ConvertTo-Json
Invoke-RestApiRequest -Session $session -Endpoint "/events" -Method POST -Body $json
```

### With TextToJson
```powershell
# Convert data with dates to JSON
$data = @{
    report_date = Get-UnixTime
    events = @(
        @{ time = Get-UnixTime; type = "login" }
    )
}

$json = $data | ConvertTo-Json -Depth 10
```

### With PdfTextReader
```powershell
# Extract dates from PDF and convert to Unix time
$text = Read-PdfText -FilePath "report.pdf"
$dates = [regex]::Matches($text, '\d{4}-\d{2}-\d{2}')

$timestamps = $dates | ForEach-Object {
    ConvertTo-UnixTimeFromString -DateString $_.Value
}
```

## Performance Tips

1. **Batch Operations**: Use `ConvertTo-UnixTimeBatch` for multiple dates
2. **Avoid Repeated Conversions**: Cache converted values
3. **Use AsInteger**: When storing, use integers for better performance
4. **Pipeline Efficiently**: Use pipeline for large datasets

## Reference

### Important Unix Timestamps

```
0           = 1970-01-01 00:00:00 (Epoch)
1000000000  = 2001-09-09 01:46:40
2000000000  = 2033-05-18 03:33:20
2147483647  = 2038-01-19 03:14:07 (32-bit max)
```

### Format Strings

Common format patterns for Format-UnixTimestamp:

```powershell
"yyyy-MM-dd HH:mm:ss"          # 2024-01-15 10:30:00
"MM/dd/yyyy hh:mm:ss tt"       # 01/15/2024 10:30:00 AM
"dddd, MMMM dd, yyyy"          # Monday, January 15, 2024
"yyyy-MM-ddTHH:mm:ssZ"         # 2024-01-15T10:30:00Z (ISO 8601)
"yyyyMMdd_HHmmss"              # 20240115_103000
```

## Additional Resources

- Unix Time on Wikipedia: https://en.wikipedia.org/wiki/Unix_time
- Epoch Converter: https://www.epochconverter.com/
- PowerShell Get-Date documentation: `Get-Help Get-Date -Full`
