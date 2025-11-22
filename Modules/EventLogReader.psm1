<#
.SYNOPSIS
    Modular PowerShell script for reading and analyzing Windows Event Logs.

.DESCRIPTION
    This module provides comprehensive functions for reading, filtering, searching,
    and exporting Windows Event Logs. Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+
#>

#Requires -Version 5.0

# ============================================================================
# Event Log Reading Functions
# ============================================================================

function Get-EventLogEntries {
    <#
    .SYNOPSIS
        Retrieves event log entries with filtering options.

    .DESCRIPTION
        Gets events from Windows Event Logs with various filter criteria.

    .PARAMETER LogName
        Name of the event log (e.g., System, Application, Security).

    .PARAMETER Level
        Event level(s): Critical, Error, Warning, Information, Verbose.

    .PARAMETER StartTime
        Get events after this time.

    .PARAMETER EndTime
        Get events before this time.

    .PARAMETER EventId
        Filter by specific Event ID(s).

    .PARAMETER ProviderName
        Filter by event source/provider name.

    .PARAMETER MaxEvents
        Maximum number of events to return.

    .PARAMETER ComputerName
        Remote computer to query.

    .PARAMETER Credential
        Credentials for remote computer.

    .PARAMETER Message
        Filter events containing this text in message.

    .EXAMPLE
        Get-EventLogEntries -LogName System -Level Error -MaxEvents 50

    .EXAMPLE
        Get-EventLogEntries -LogName Application -StartTime (Get-Date).AddDays(-1) -ProviderName "MSSQLSERVER"

    .EXAMPLE
        Get-EventLogEntries -LogName Security -EventId 4624,4625 -MaxEvents 100
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [string[]]$Level,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime,

        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime,

        [Parameter(Mandatory = $false)]
        [int[]]$EventId,

        [Parameter(Mandatory = $false)]
        [string]$ProviderName,

        [Parameter(Mandatory = $false)]
        [int]$MaxEvents = 100,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$Message
    )

    try {
        # Build filter hashtable
        $filterHash = @{
            LogName = $LogName
        }

        # Map level names to numeric values
        $levelMap = @{
            'Critical'    = 1
            'Error'       = 2
            'Warning'     = 3
            'Information' = 4
            'Verbose'     = 5
        }

        if ($Level) {
            $filterHash['Level'] = $Level | ForEach-Object { $levelMap[$_] }
        }

        if ($StartTime) {
            $filterHash['StartTime'] = $StartTime
        }

        if ($EndTime) {
            $filterHash['EndTime'] = $EndTime
        }

        if ($EventId) {
            $filterHash['Id'] = $EventId
        }

        if ($ProviderName) {
            $filterHash['ProviderName'] = $ProviderName
        }

        # Build parameters
        $params = @{
            FilterHashtable = $filterHash
            MaxEvents       = $MaxEvents
            ErrorAction     = 'Stop'
        }

        if ($ComputerName) {
            $params['ComputerName'] = $ComputerName
        }

        if ($Credential) {
            $params['Credential'] = $Credential
        }

        # Get events
        $events = Get-WinEvent @params

        # Filter by message if specified
        if ($Message -and $events) {
            $events = $events | Where-Object { $_.Message -like "*$Message*" }
        }

        # Format output
        $events | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated   = $_.TimeCreated
                LogName       = $_.LogName
                ProviderName  = $_.ProviderName
                Id            = $_.Id
                LevelName     = $_.LevelDisplayName
                Level         = $_.Level
                Message       = $_.Message
                MachineName   = $_.MachineName
                UserId        = $_.UserId
                RecordId      = $_.RecordId
                TaskName      = $_.TaskDisplayName
                Keywords      = $_.KeywordsDisplayNames -join ', '
            }
        }
    }
    catch [System.Exception] {
        if ($_.Exception.Message -like "*No events were found*") {
            Write-Verbose "No events found matching the specified criteria"
            return @()
        }
        throw "Failed to get event log entries: $_"
    }
}

function Get-EventLogSummary {
    <#
    .SYNOPSIS
        Gets a summary of events in a log.

    .DESCRIPTION
        Provides statistics about events in a specified event log.

    .PARAMETER LogName
        Name of the event log.

    .PARAMETER Hours
        Number of hours to analyze. Default: 24.

    .PARAMETER ComputerName
        Remote computer to query.

    .EXAMPLE
        Get-EventLogSummary -LogName System

    .EXAMPLE
        Get-EventLogSummary -LogName Application -Hours 48
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [int]$Hours = 24,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName
    )

    try {
        $startTime = (Get-Date).AddHours(-$Hours)

        $params = @{
            FilterHashtable = @{
                LogName   = $LogName
                StartTime = $startTime
            }
            ErrorAction = 'SilentlyContinue'
        }

        if ($ComputerName) {
            $params['ComputerName'] = $ComputerName
        }

        $events = Get-WinEvent @params

        if (-not $events) {
            return [PSCustomObject]@{
                LogName       = $LogName
                Period        = "$Hours hours"
                TotalEvents   = 0
                Critical      = 0
                Error         = 0
                Warning       = 0
                Information   = 0
                TopProviders  = @()
                TopEventIds   = @()
            }
        }

        # Count by level
        $levelCounts = $events | Group-Object Level | ForEach-Object {
            @{ $_.Name = $_.Count }
        }

        # Top providers
        $topProviders = $events | Group-Object ProviderName |
            Sort-Object Count -Descending |
            Select-Object -First 5 |
            ForEach-Object { "$($_.Name) ($($_.Count))" }

        # Top Event IDs
        $topEventIds = $events | Group-Object Id |
            Sort-Object Count -Descending |
            Select-Object -First 5 |
            ForEach-Object { "$($_.Name) ($($_.Count))" }

        [PSCustomObject]@{
            LogName       = $LogName
            Period        = "$Hours hours"
            TotalEvents   = $events.Count
            Critical      = ($events | Where-Object { $_.Level -eq 1 }).Count
            Error         = ($events | Where-Object { $_.Level -eq 2 }).Count
            Warning       = ($events | Where-Object { $_.Level -eq 3 }).Count
            Information   = ($events | Where-Object { $_.Level -eq 4 }).Count
            TopProviders  = $topProviders
            TopEventIds   = $topEventIds
        }
    }
    catch {
        throw "Failed to get event log summary: $_"
    }
}

function Get-CriticalEvents {
    <#
    .SYNOPSIS
        Gets critical and error events from common logs.

    .DESCRIPTION
        Retrieves critical and error level events from System, Application, and Security logs.

    .PARAMETER Hours
        Number of hours to search. Default: 24.

    .PARAMETER IncludeWarnings
        Include warning level events.

    .PARAMETER ComputerName
        Remote computer to query.

    .EXAMPLE
        Get-CriticalEvents -Hours 48

    .EXAMPLE
        Get-CriticalEvents -IncludeWarnings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Hours = 24,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeWarnings,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName
    )

    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        $logs = @('System', 'Application')
        $allEvents = @()

        $levels = @(1, 2)  # Critical and Error
        if ($IncludeWarnings) {
            $levels += 3  # Warning
        }

        foreach ($log in $logs) {
            $params = @{
                FilterHashtable = @{
                    LogName   = $log
                    Level     = $levels
                    StartTime = $startTime
                }
                ErrorAction = 'SilentlyContinue'
            }

            if ($ComputerName) {
                $params['ComputerName'] = $ComputerName
            }

            $events = Get-WinEvent @params

            if ($events) {
                $allEvents += $events | ForEach-Object {
                    [PSCustomObject]@{
                        TimeCreated  = $_.TimeCreated
                        LogName      = $_.LogName
                        Level        = $_.LevelDisplayName
                        Provider     = $_.ProviderName
                        EventId      = $_.Id
                        Message      = $_.Message
                    }
                }
            }
        }

        return $allEvents | Sort-Object TimeCreated -Descending
    }
    catch {
        throw "Failed to get critical events: $_"
    }
}

# ============================================================================
# Search Functions
# ============================================================================

function Search-EventLogMessage {
    <#
    .SYNOPSIS
        Searches for text in event log messages.

    .DESCRIPTION
        Searches event log messages for specific text or patterns.

    .PARAMETER LogName
        Name of the event log to search.

    .PARAMETER Pattern
        Text or regex pattern to search for.

    .PARAMETER UseRegex
        Treat pattern as regular expression.

    .PARAMETER StartTime
        Search events after this time.

    .PARAMETER MaxEvents
        Maximum events to search through.

    .PARAMETER ComputerName
        Remote computer to query.

    .EXAMPLE
        Search-EventLogMessage -LogName System -Pattern "disk"

    .EXAMPLE
        Search-EventLogMessage -LogName Application -Pattern "error.*database" -UseRegex
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [switch]$UseRegex,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date).AddDays(-7),

        [Parameter(Mandatory = $false)]
        [int]$MaxEvents = 1000,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName
    )

    try {
        $params = @{
            FilterHashtable = @{
                LogName   = $LogName
                StartTime = $StartTime
            }
            MaxEvents   = $MaxEvents
            ErrorAction = 'SilentlyContinue'
        }

        if ($ComputerName) {
            $params['ComputerName'] = $ComputerName
        }

        $events = Get-WinEvent @params

        if (-not $events) {
            return @()
        }

        # Search in messages
        if ($UseRegex) {
            $matchedEvents = $events | Where-Object { $_.Message -match $Pattern }
        }
        else {
            $matchedEvents = $events | Where-Object { $_.Message -like "*$Pattern*" }
        }

        $matchedEvents | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated  = $_.TimeCreated
                LogName      = $_.LogName
                Level        = $_.LevelDisplayName
                Provider     = $_.ProviderName
                EventId      = $_.Id
                Message      = $_.Message
            }
        }
    }
    catch {
        throw "Failed to search event log: $_"
    }
}

# ============================================================================
# Export Functions
# ============================================================================

function Export-EventLogEntries {
    <#
    .SYNOPSIS
        Exports event log entries to a file.

    .DESCRIPTION
        Exports events to CSV, JSON, or HTML format.

    .PARAMETER Events
        Events to export (from Get-EventLogEntries).

    .PARAMETER OutputPath
        Path for the output file.

    .PARAMETER Format
        Output format: CSV, JSON, or HTML.

    .PARAMETER Append
        Append to existing file (CSV only).

    .EXAMPLE
        $events = Get-EventLogEntries -LogName System -Level Error
        Export-EventLogEntries -Events $events -OutputPath "C:\logs\errors.csv"

    .EXAMPLE
        Get-EventLogEntries -LogName Application | Export-EventLogEntries -OutputPath "C:\logs\app.json" -Format JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Events,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CSV', 'JSON', 'HTML')]
        [string]$Format = 'CSV',

        [Parameter(Mandatory = $false)]
        [switch]$Append
    )

    begin {
        $allEvents = @()
    }

    process {
        $allEvents += $Events
    }

    end {
        try {
            # Create directory if needed
            $outputDir = Split-Path -Path $OutputPath -Parent
            if ($outputDir -and -not (Test-Path $outputDir)) {
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            }

            switch ($Format) {
                'CSV' {
                    if ($Append -and (Test-Path $OutputPath)) {
                        $allEvents | Export-Csv -Path $OutputPath -NoTypeInformation -Append
                    }
                    else {
                        $allEvents | Export-Csv -Path $OutputPath -NoTypeInformation
                    }
                }
                'JSON' {
                    $allEvents | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                'HTML' {
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Event Log Export</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .error { background-color: #ffcccc; }
        .warning { background-color: #ffffcc; }
        .critical { background-color: #ff9999; }
        h1 { color: #333; }
        .summary { margin-bottom: 20px; padding: 10px; background-color: #e7f3fe; border-left: 4px solid #2196F3; }
    </style>
</head>
<body>
    <h1>Event Log Export</h1>
    <div class="summary">
        <strong>Export Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
        <strong>Total Events:</strong> $($allEvents.Count)
    </div>
    <table>
        <tr>
            <th>Time</th>
            <th>Log</th>
            <th>Level</th>
            <th>Provider</th>
            <th>Event ID</th>
            <th>Message</th>
        </tr>
"@
                    foreach ($event in $allEvents) {
                        $rowClass = switch ($event.LevelName) {
                            'Error' { 'error' }
                            'Warning' { 'warning' }
                            'Critical' { 'critical' }
                            default { '' }
                        }
                        $msgPreview = if ($event.Message.Length -gt 200) {
                            $event.Message.Substring(0, 200) + "..."
                        } else {
                            $event.Message
                        }
                        $html += @"

        <tr class="$rowClass">
            <td>$($event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))</td>
            <td>$($event.LogName)</td>
            <td>$($event.LevelName)</td>
            <td>$($event.ProviderName)</td>
            <td>$($event.Id)</td>
            <td>$([System.Web.HttpUtility]::HtmlEncode($msgPreview))</td>
        </tr>
"@
                    }

                    $html += @"

    </table>
</body>
</html>
"@
                    Add-Type -AssemblyName System.Web
                    $html | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }

            Write-Verbose "Exported $($allEvents.Count) events to: $OutputPath"

            return [PSCustomObject]@{
                OutputPath  = $OutputPath
                Format      = $Format
                EventCount  = $allEvents.Count
            }
        }
        catch {
            throw "Failed to export events: $_"
        }
    }
}

# ============================================================================
# Log Information Functions
# ============================================================================

function Get-EventLogNames {
    <#
    .SYNOPSIS
        Gets available event log names.

    .DESCRIPTION
        Lists all event logs available on the system.

    .PARAMETER ComputerName
        Remote computer to query.

    .PARAMETER IncludeEmpty
        Include logs with no events.

    .EXAMPLE
        Get-EventLogNames

    .EXAMPLE
        Get-EventLogNames -ComputerName "Server01"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEmpty
    )

    try {
        $params = @{
            ListLog     = '*'
            ErrorAction = 'SilentlyContinue'
        }

        if ($ComputerName) {
            $params['ComputerName'] = $ComputerName
        }

        $logs = Get-WinEvent @params

        if (-not $IncludeEmpty) {
            $logs = $logs | Where-Object { $_.RecordCount -gt 0 }
        }

        $logs | Sort-Object LogName | ForEach-Object {
            [PSCustomObject]@{
                LogName       = $_.LogName
                RecordCount   = $_.RecordCount
                MaxSizeKB     = [Math]::Round($_.MaximumSizeInBytes / 1KB, 2)
                LastWriteTime = $_.LastWriteTime
                IsEnabled     = $_.IsEnabled
                LogMode       = $_.LogMode
            }
        }
    }
    catch {
        throw "Failed to get event log names: $_"
    }
}

function Get-EventLogProviders {
    <#
    .SYNOPSIS
        Gets event log providers/sources.

    .DESCRIPTION
        Lists providers that write to a specific event log.

    .PARAMETER LogName
        Name of the event log.

    .EXAMPLE
        Get-EventLogProviders -LogName System
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName
    )

    try {
        $providers = Get-WinEvent -ListProvider * -ErrorAction SilentlyContinue |
            Where-Object { $_.LogLinks.LogName -contains $LogName }

        $providers | Sort-Object Name | ForEach-Object {
            [PSCustomObject]@{
                ProviderName = $_.Name
                DisplayName  = $_.DisplayName
            }
        }
    }
    catch {
        throw "Failed to get event log providers: $_"
    }
}

# ============================================================================
# Monitoring Functions
# ============================================================================

function Watch-EventLog {
    <#
    .SYNOPSIS
        Monitors an event log for new entries.

    .DESCRIPTION
        Continuously monitors an event log and displays new events as they occur.

    .PARAMETER LogName
        Name of the event log to monitor.

    .PARAMETER Level
        Filter by event level(s).

    .PARAMETER ProviderName
        Filter by provider name.

    .PARAMETER IntervalSeconds
        Polling interval in seconds. Default: 5.

    .PARAMETER Duration
        Duration to monitor in minutes. Default: 60.

    .EXAMPLE
        Watch-EventLog -LogName System -Level Error,Warning

    .EXAMPLE
        Watch-EventLog -LogName Application -ProviderName "MSSQLSERVER" -IntervalSeconds 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [string[]]$Level,

        [Parameter(Mandatory = $false)]
        [string]$ProviderName,

        [Parameter(Mandatory = $false)]
        [int]$IntervalSeconds = 5,

        [Parameter(Mandatory = $false)]
        [int]$Duration = 60
    )

    try {
        $levelMap = @{
            'Critical'    = 1
            'Error'       = 2
            'Warning'     = 3
            'Information' = 4
            'Verbose'     = 5
        }

        $startTime = Get-Date
        $endTime = $startTime.AddMinutes($Duration)
        $lastCheckTime = $startTime

        Write-Host "Monitoring '$LogName' log for new events..." -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
        Write-Host ""

        while ((Get-Date) -lt $endTime) {
            $filterHash = @{
                LogName   = $LogName
                StartTime = $lastCheckTime
            }

            if ($Level) {
                $filterHash['Level'] = $Level | ForEach-Object { $levelMap[$_] }
            }

            if ($ProviderName) {
                $filterHash['ProviderName'] = $ProviderName
            }

            $events = Get-WinEvent -FilterHashtable $filterHash -ErrorAction SilentlyContinue

            if ($events) {
                foreach ($event in ($events | Sort-Object TimeCreated)) {
                    $color = switch ($event.Level) {
                        1 { 'Magenta' }  # Critical
                        2 { 'Red' }      # Error
                        3 { 'Yellow' }   # Warning
                        4 { 'White' }    # Information
                        default { 'Gray' }
                    }

                    Write-Host "[$($event.TimeCreated.ToString('HH:mm:ss'))] " -NoNewline
                    Write-Host "[$($event.LevelDisplayName)] " -ForegroundColor $color -NoNewline
                    Write-Host "$($event.ProviderName) (ID: $($event.Id))"

                    if ($event.Message) {
                        $msgPreview = if ($event.Message.Length -gt 100) {
                            $event.Message.Substring(0, 100) + "..."
                        } else {
                            $event.Message.Split("`n")[0]
                        }
                        Write-Host "  $msgPreview" -ForegroundColor Gray
                    }
                    Write-Host ""
                }
            }

            $lastCheckTime = Get-Date
            Start-Sleep -Seconds $IntervalSeconds
        }

        Write-Host "Monitoring complete" -ForegroundColor Cyan
    }
    catch {
        if ($_.Exception.Message -notlike "*No events were found*") {
            throw "Failed to monitor event log: $_"
        }
    }
}

# ============================================================================
# Analysis Functions
# ============================================================================

function Get-EventLogTrend {
    <#
    .SYNOPSIS
        Gets event count trends over time.

    .DESCRIPTION
        Analyzes event frequency by hour or day.

    .PARAMETER LogName
        Name of the event log.

    .PARAMETER Days
        Number of days to analyze. Default: 7.

    .PARAMETER GroupBy
        Group events by Hour or Day.

    .PARAMETER Level
        Filter by event level(s).

    .EXAMPLE
        Get-EventLogTrend -LogName System -Days 7 -GroupBy Day

    .EXAMPLE
        Get-EventLogTrend -LogName Application -GroupBy Hour -Level Error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [int]$Days = 7,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Hour', 'Day')]
        [string]$GroupBy = 'Day',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [string[]]$Level
    )

    try {
        $startTime = (Get-Date).AddDays(-$Days)

        $levelMap = @{
            'Critical'    = 1
            'Error'       = 2
            'Warning'     = 3
            'Information' = 4
            'Verbose'     = 5
        }

        $filterHash = @{
            LogName   = $LogName
            StartTime = $startTime
        }

        if ($Level) {
            $filterHash['Level'] = $Level | ForEach-Object { $levelMap[$_] }
        }

        $events = Get-WinEvent -FilterHashtable $filterHash -ErrorAction SilentlyContinue

        if (-not $events) {
            Write-Verbose "No events found"
            return @()
        }

        if ($GroupBy -eq 'Hour') {
            $grouped = $events | Group-Object { $_.TimeCreated.ToString('yyyy-MM-dd HH:00') }
        }
        else {
            $grouped = $events | Group-Object { $_.TimeCreated.ToString('yyyy-MM-dd') }
        }

        $grouped | Sort-Object Name | ForEach-Object {
            [PSCustomObject]@{
                Period = $_.Name
                Count  = $_.Count
            }
        }
    }
    catch {
        throw "Failed to get event log trend: $_"
    }
}

function Get-FrequentEvents {
    <#
    .SYNOPSIS
        Gets the most frequent events in a log.

    .DESCRIPTION
        Identifies events that occur most frequently.

    .PARAMETER LogName
        Name of the event log.

    .PARAMETER Hours
        Number of hours to analyze. Default: 24.

    .PARAMETER Top
        Number of top events to return. Default: 10.

    .EXAMPLE
        Get-FrequentEvents -LogName System -Top 20

    .EXAMPLE
        Get-FrequentEvents -LogName Application -Hours 48
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [int]$Hours = 24,

        [Parameter(Mandatory = $false)]
        [int]$Top = 10
    )

    try {
        $startTime = (Get-Date).AddHours(-$Hours)

        $events = Get-WinEvent -FilterHashtable @{
            LogName   = $LogName
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        if (-not $events) {
            return @()
        }

        $events | Group-Object Id, ProviderName |
            Sort-Object Count -Descending |
            Select-Object -First $Top |
            ForEach-Object {
                $sampleEvent = $_.Group[0]
                [PSCustomObject]@{
                    EventId     = $sampleEvent.Id
                    Provider    = $sampleEvent.ProviderName
                    Level       = $sampleEvent.LevelDisplayName
                    Count       = $_.Count
                    LastOccur   = ($_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                    Message     = if ($sampleEvent.Message.Length -gt 100) {
                        $sampleEvent.Message.Substring(0, 100) + "..."
                    } else {
                        $sampleEvent.Message.Split("`n")[0]
                    }
                }
            }
    }
    catch {
        throw "Failed to get frequent events: $_"
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # Event retrieval
    'Get-EventLogEntries',
    'Get-EventLogSummary',
    'Get-CriticalEvents',

    # Search
    'Search-EventLogMessage',

    # Export
    'Export-EventLogEntries',

    # Log information
    'Get-EventLogNames',
    'Get-EventLogProviders',

    # Monitoring
    'Watch-EventLog',

    # Analysis
    'Get-EventLogTrend',
    'Get-FrequentEvents'
)
