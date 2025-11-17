<#
.SYNOPSIS
    Modular date/time to Unix timestamp converter for PowerShell 5+

.DESCRIPTION
    This module provides functions to convert between DateTime objects and Unix timestamps.
    Supports seconds, milliseconds, and microsecond precision with timezone handling.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
#>

#region Module Variables

# Unix epoch start date: January 1, 1970, 00:00:00 UTC
$script:UnixEpoch = [DateTime]::new(1970, 1, 1, 0, 0, 0, 0, [DateTimeKind]::Utc)

#endregion

#region Public Functions

<#
.SYNOPSIS
    Converts a DateTime object to Unix timestamp.

.DESCRIPTION
    Converts a DateTime to Unix timestamp (seconds since January 1, 1970 UTC).
    Supports seconds, milliseconds, and microsecond precision.

.PARAMETER DateTime
    The DateTime object to convert. If not specified, uses current time.

.PARAMETER Precision
    The precision of the timestamp: Seconds, Milliseconds, or Microseconds. Default is Seconds.

.PARAMETER AsInteger
    Switch. Returns the timestamp as an integer instead of a decimal.

.EXAMPLE
    # Current time as Unix timestamp
    $timestamp = ConvertTo-UnixTime

.EXAMPLE
    # Specific date to Unix timestamp
    $date = Get-Date "2024-01-15 10:30:00"
    $timestamp = ConvertTo-UnixTime -DateTime $date

.EXAMPLE
    # Get millisecond precision
    $timestamp = ConvertTo-UnixTime -Precision Milliseconds

.EXAMPLE
    # Get as integer
    $timestamp = ConvertTo-UnixTime -AsInteger
#>
function ConvertTo-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [DateTime]$DateTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$AsInteger
    )

    process {
        try {
            # Convert to UTC if not already
            if ($DateTime.Kind -eq [DateTimeKind]::Local) {
                $DateTime = $DateTime.ToUniversalTime()
            }
            elseif ($DateTime.Kind -eq [DateTimeKind]::Unspecified) {
                # Assume local time and convert to UTC
                $DateTime = [DateTime]::SpecifyKind($DateTime, [DateTimeKind]::Local).ToUniversalTime()
            }

            # Calculate time difference from Unix epoch
            $timeSpan = $DateTime - $script:UnixEpoch

            # Return based on precision
            switch ($Precision) {
                'Seconds' {
                    $timestamp = $timeSpan.TotalSeconds
                }
                'Milliseconds' {
                    $timestamp = $timeSpan.TotalMilliseconds
                }
                'Microseconds' {
                    $timestamp = $timeSpan.TotalMilliseconds * 1000
                }
            }

            # Return as integer if requested
            if ($AsInteger) {
                return [long]$timestamp
            }
            else {
                return $timestamp
            }
        }
        catch {
            Write-Error "Failed to convert DateTime to Unix timestamp: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Converts a Unix timestamp to DateTime object.

.DESCRIPTION
    Converts a Unix timestamp (seconds since January 1, 1970 UTC) to a DateTime object.
    Supports seconds, milliseconds, and microsecond precision.

.PARAMETER Timestamp
    The Unix timestamp to convert.

.PARAMETER Precision
    The precision of the input timestamp: Seconds, Milliseconds, or Microseconds. Default is Seconds.

.PARAMETER ToLocalTime
    Switch. Converts the result to local timezone instead of UTC.

.EXAMPLE
    # Convert Unix timestamp to DateTime
    $date = ConvertFrom-UnixTime -Timestamp 1705315800

.EXAMPLE
    # Convert milliseconds timestamp
    $date = ConvertFrom-UnixTime -Timestamp 1705315800000 -Precision Milliseconds

.EXAMPLE
    # Convert to local time
    $date = ConvertFrom-UnixTime -Timestamp 1705315800 -ToLocalTime

.EXAMPLE
    # Pipeline support
    1705315800 | ConvertFrom-UnixTime -ToLocalTime
#>
function ConvertFrom-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [double]$Timestamp,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$ToLocalTime
    )

    process {
        try {
            # Convert based on precision
            switch ($Precision) {
                'Seconds' {
                    $seconds = $Timestamp
                }
                'Milliseconds' {
                    $seconds = $Timestamp / 1000
                }
                'Microseconds' {
                    $seconds = $Timestamp / 1000000
                }
            }

            # Add seconds to Unix epoch
            $dateTime = $script:UnixEpoch.AddSeconds($seconds)

            # Convert to local time if requested
            if ($ToLocalTime) {
                $dateTime = $dateTime.ToLocalTime()
            }

            return $dateTime
        }
        catch {
            Write-Error "Failed to convert Unix timestamp to DateTime: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Gets the current Unix timestamp.

.DESCRIPTION
    Returns the current time as a Unix timestamp.

.PARAMETER Precision
    The precision of the timestamp: Seconds, Milliseconds, or Microseconds. Default is Seconds.

.PARAMETER AsInteger
    Switch. Returns the timestamp as an integer.

.EXAMPLE
    $now = Get-UnixTime

.EXAMPLE
    $nowMs = Get-UnixTime -Precision Milliseconds -AsInteger
#>
function Get-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$AsInteger
    )

    return ConvertTo-UnixTime -DateTime (Get-Date) -Precision $Precision -AsInteger:$AsInteger
}

<#
.SYNOPSIS
    Converts a date string to Unix timestamp.

.DESCRIPTION
    Parses a date string and converts it to Unix timestamp.
    Supports various date formats and timezones.

.PARAMETER DateString
    The date string to parse and convert.

.PARAMETER Format
    Optional. The format of the date string (e.g., "yyyy-MM-dd HH:mm:ss").

.PARAMETER Precision
    The precision of the output timestamp. Default is Seconds.

.PARAMETER AsInteger
    Switch. Returns the timestamp as an integer.

.EXAMPLE
    $timestamp = ConvertTo-UnixTimeFromString -DateString "2024-01-15 10:30:00"

.EXAMPLE
    $timestamp = ConvertTo-UnixTimeFromString -DateString "01/15/2024" -Format "MM/dd/yyyy"

.EXAMPLE
    "2024-01-15 10:30:00" | ConvertTo-UnixTimeFromString -Precision Milliseconds
#>
function ConvertTo-UnixTimeFromString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$DateString,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$AsInteger
    )

    process {
        try {
            # Parse the date string
            if ($Format) {
                $dateTime = [DateTime]::ParseExact($DateString, $Format, $null)
            }
            else {
                $dateTime = [DateTime]::Parse($DateString)
            }

            # Convert to Unix timestamp
            return ConvertTo-UnixTime -DateTime $dateTime -Precision $Precision -AsInteger:$AsInteger
        }
        catch {
            Write-Error "Failed to parse date string '$DateString': $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Calculates the time difference between two dates in various units.

.DESCRIPTION
    Returns the time difference between two dates in seconds, minutes, hours, or days.

.PARAMETER StartDate
    The start date/time.

.PARAMETER EndDate
    The end date/time. If not specified, uses current time.

.PARAMETER Unit
    The unit for the result: Seconds, Minutes, Hours, or Days. Default is Seconds.

.EXAMPLE
    $diff = Get-TimeDifference -StartDate (Get-Date).AddHours(-2)
    # Returns difference in seconds

.EXAMPLE
    $start = Get-Date "2024-01-01"
    $end = Get-Date "2024-01-15"
    $days = Get-TimeDifference -StartDate $start -EndDate $end -Unit Days
#>
function Get-TimeDifference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [DateTime]$StartDate,

        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [string]$Unit = 'Seconds'
    )

    try {
        $timeSpan = $EndDate - $StartDate

        switch ($Unit) {
            'Seconds' { return $timeSpan.TotalSeconds }
            'Minutes' { return $timeSpan.TotalMinutes }
            'Hours' { return $timeSpan.TotalHours }
            'Days' { return $timeSpan.TotalDays }
        }
    }
    catch {
        Write-Error "Failed to calculate time difference: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Tests if a value is a valid Unix timestamp.

.DESCRIPTION
    Validates if a number is a reasonable Unix timestamp.

.PARAMETER Timestamp
    The value to test.

.PARAMETER Precision
    The expected precision of the timestamp. Default is Seconds.

.EXAMPLE
    if (Test-UnixTimestamp -Timestamp 1705315800) {
        Write-Host "Valid timestamp"
    }

.EXAMPLE
    Test-UnixTimestamp -Timestamp 1705315800000 -Precision Milliseconds
#>
function Test-UnixTimestamp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$Timestamp,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds'
    )

    process {
        try {
            # Convert to seconds for validation
            switch ($Precision) {
                'Seconds' { $seconds = $Timestamp }
                'Milliseconds' { $seconds = $Timestamp / 1000 }
                'Microseconds' { $seconds = $Timestamp / 1000000 }
            }

            # Reasonable range: 1970-01-01 to 2100-01-01
            $minTimestamp = 0
            $maxTimestamp = 4102444800 # 2100-01-01

            return ($seconds -ge $minTimestamp -and $seconds -le $maxTimestamp)
        }
        catch {
            return $false
        }
    }
}

<#
.SYNOPSIS
    Formats a Unix timestamp as a readable string.

.DESCRIPTION
    Converts a Unix timestamp to a formatted date/time string.

.PARAMETER Timestamp
    The Unix timestamp to format.

.PARAMETER Format
    The output format string. Default is "yyyy-MM-dd HH:mm:ss".

.PARAMETER Precision
    The precision of the input timestamp. Default is Seconds.

.PARAMETER ToLocalTime
    Switch. Converts to local timezone before formatting.

.EXAMPLE
    $formatted = Format-UnixTimestamp -Timestamp 1705315800
    # Output: 2024-01-15 10:30:00

.EXAMPLE
    Format-UnixTimestamp -Timestamp 1705315800 -Format "MM/dd/yyyy hh:mm tt" -ToLocalTime
#>
function Format-UnixTimestamp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$Timestamp,

        [Parameter(Mandatory = $false)]
        [string]$Format = "yyyy-MM-dd HH:mm:ss",

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$ToLocalTime
    )

    process {
        try {
            $dateTime = ConvertFrom-UnixTime -Timestamp $Timestamp -Precision $Precision -ToLocalTime:$ToLocalTime
            return $dateTime.ToString($Format)
        }
        catch {
            Write-Error "Failed to format Unix timestamp: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Converts a batch of dates to Unix timestamps.

.DESCRIPTION
    Processes multiple DateTime objects and converts them to Unix timestamps.
    Returns an array of custom objects with original and converted values.

.PARAMETER Dates
    Array of DateTime objects to convert.

.PARAMETER Precision
    The precision for timestamps. Default is Seconds.

.PARAMETER AsInteger
    Switch. Returns timestamps as integers.

.EXAMPLE
    $dates = @((Get-Date), (Get-Date).AddDays(-1), (Get-Date).AddDays(-7))
    $results = ConvertTo-UnixTimeBatch -Dates $dates

.EXAMPLE
    Get-ChildItem | Select-Object Name, LastWriteTime |
        ForEach-Object { ConvertTo-UnixTime -DateTime $_.LastWriteTime }
#>
function ConvertTo-UnixTimeBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DateTime[]]$Dates,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds',

        [Parameter(Mandatory = $false)]
        [switch]$AsInteger
    )

    begin {
        $results = @()
    }

    process {
        foreach ($date in $Dates) {
            $timestamp = ConvertTo-UnixTime -DateTime $date -Precision $Precision -AsInteger:$AsInteger

            $results += [PSCustomObject]@{
                OriginalDate = $date
                UnixTimestamp = $timestamp
                Precision = $Precision
                UTC = $date.ToUniversalTime()
            }
        }
    }

    end {
        return $results
    }
}

<#
.SYNOPSIS
    Adds or subtracts time from a Unix timestamp.

.DESCRIPTION
    Performs time arithmetic on Unix timestamps.

.PARAMETER Timestamp
    The Unix timestamp to modify.

.PARAMETER Seconds
    Number of seconds to add (positive) or subtract (negative).

.PARAMETER Minutes
    Number of minutes to add or subtract.

.PARAMETER Hours
    Number of hours to add or subtract.

.PARAMETER Days
    Number of days to add or subtract.

.PARAMETER Precision
    The precision of the timestamp. Default is Seconds.

.EXAMPLE
    # Add 2 hours to a timestamp
    $newTimestamp = Add-UnixTime -Timestamp 1705315800 -Hours 2

.EXAMPLE
    # Subtract 30 days
    $oldTimestamp = Add-UnixTime -Timestamp 1705315800 -Days -30

.EXAMPLE
    # Combine multiple units
    $newTimestamp = Add-UnixTime -Timestamp 1705315800 -Days 1 -Hours 2 -Minutes 30
#>
function Add-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$Timestamp,

        [Parameter(Mandatory = $false)]
        [double]$Seconds = 0,

        [Parameter(Mandatory = $false)]
        [double]$Minutes = 0,

        [Parameter(Mandatory = $false)]
        [double]$Hours = 0,

        [Parameter(Mandatory = $false)]
        [double]$Days = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds'
    )

    process {
        try {
            # Convert timestamp to DateTime
            $dateTime = ConvertFrom-UnixTime -Timestamp $Timestamp -Precision $Precision

            # Add time units
            $dateTime = $dateTime.AddDays($Days)
            $dateTime = $dateTime.AddHours($Hours)
            $dateTime = $dateTime.AddMinutes($Minutes)
            $dateTime = $dateTime.AddSeconds($Seconds)

            # Convert back to Unix timestamp
            return ConvertTo-UnixTime -DateTime $dateTime -Precision $Precision
        }
        catch {
            Write-Error "Failed to add time to Unix timestamp: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Gets the start or end of day for a Unix timestamp.

.DESCRIPTION
    Returns the Unix timestamp for the start (00:00:00) or end (23:59:59) of the day.

.PARAMETER Timestamp
    The Unix timestamp.

.PARAMETER StartOfDay
    Switch. Returns the start of day (00:00:00).

.PARAMETER EndOfDay
    Switch. Returns the end of day (23:59:59).

.PARAMETER Precision
    The precision for the output. Default is Seconds.

.EXAMPLE
    # Get start of day
    $startOfDay = Get-UnixDayBoundary -Timestamp 1705315800 -StartOfDay

.EXAMPLE
    # Get end of day
    $endOfDay = Get-UnixDayBoundary -Timestamp 1705315800 -EndOfDay
#>
function Get-UnixDayBoundary {
    [CmdletBinding(DefaultParameterSetName='Start')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$Timestamp,

        [Parameter(Mandatory = $false, ParameterSetName='Start')]
        [switch]$StartOfDay,

        [Parameter(Mandatory = $false, ParameterSetName='End')]
        [switch]$EndOfDay,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Seconds', 'Milliseconds', 'Microseconds')]
        [string]$Precision = 'Seconds'
    )

    process {
        try {
            $dateTime = ConvertFrom-UnixTime -Timestamp $Timestamp -Precision $Precision

            if ($EndOfDay) {
                $dateTime = $dateTime.Date.AddDays(1).AddSeconds(-1)
            }
            else {
                # Start of day (default)
                $dateTime = $dateTime.Date
            }

            return ConvertTo-UnixTime -DateTime $dateTime -Precision $Precision
        }
        catch {
            Write-Error "Failed to get day boundary: $_"
            return $null
        }
    }
}

#endregion

#region Private Functions

# No private functions needed for this module

#endregion

# Export public functions
Export-ModuleMember -Function ConvertTo-UnixTime, `
                              ConvertFrom-UnixTime, `
                              Get-UnixTime, `
                              ConvertTo-UnixTimeFromString, `
                              Get-TimeDifference, `
                              Test-UnixTimestamp, `
                              Format-UnixTimestamp, `
                              ConvertTo-UnixTimeBatch, `
                              Add-UnixTime, `
                              Get-UnixDayBoundary
