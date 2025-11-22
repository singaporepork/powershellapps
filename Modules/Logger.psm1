<#
.SYNOPSIS
    Modular PowerShell script for logging with multiple output targets and log levels.

.DESCRIPTION
    This module provides comprehensive logging functionality including multiple log levels,
    various output targets (console, file, both), log rotation, and customizable formatting.
    Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+
#>

#Requires -Version 5.0

# ============================================================================
# Module Variables
# ============================================================================

# Log levels with numeric values for comparison
$script:LogLevels = @{
    'DEBUG'    = 0
    'INFO'     = 1
    'WARNING'  = 2
    'ERROR'    = 3
    'CRITICAL' = 4
    'NONE'     = 5
}

# Default logger configuration
$script:LoggerConfig = @{
    LogLevel        = 'INFO'
    LogPath         = $null
    LogToConsole    = $true
    LogToFile       = $false
    DateFormat      = 'yyyy-MM-dd HH:mm:ss'
    MessageFormat   = '[{0}] [{1}] {2}'
    IncludeCaller   = $false
    MaxFileSizeMB   = 10
    MaxLogFiles     = 5
    UseColors       = $true
    Initialized     = $false
}

# Color mapping for console output
$script:LogColors = @{
    'DEBUG'    = 'Gray'
    'INFO'     = 'White'
    'WARNING'  = 'Yellow'
    'ERROR'    = 'Red'
    'CRITICAL' = 'Magenta'
}

# ============================================================================
# Initialization Functions
# ============================================================================

function Initialize-Logger {
    <#
    .SYNOPSIS
        Initializes the logger with specified configuration.

    .DESCRIPTION
        Sets up the logging system with the specified options. Must be called before
        using other logging functions if you want to log to a file.

    .PARAMETER LogPath
        Path to the log file. Required if LogToFile is true.

    .PARAMETER LogLevel
        Minimum log level to record. Options: DEBUG, INFO, WARNING, ERROR, CRITICAL.

    .PARAMETER LogToConsole
        Enable console output. Default: $true.

    .PARAMETER LogToFile
        Enable file output. Default: $false.

    .PARAMETER DateFormat
        Format for timestamps. Default: 'yyyy-MM-dd HH:mm:ss'.

    .PARAMETER MessageFormat
        Format string for log messages. Placeholders: {0}=timestamp, {1}=level, {2}=message.

    .PARAMETER IncludeCaller
        Include calling function name in log messages. Default: $false.

    .PARAMETER MaxFileSizeMB
        Maximum log file size in MB before rotation. Default: 10.

    .PARAMETER MaxLogFiles
        Maximum number of rotated log files to keep. Default: 5.

    .PARAMETER UseColors
        Use colors for console output. Default: $true.

    .PARAMETER Append
        Append to existing log file instead of overwriting. Default: $true.

    .EXAMPLE
        Initialize-Logger -LogPath "C:\Logs\app.log" -LogLevel INFO -LogToFile $true

    .EXAMPLE
        Initialize-Logger -LogLevel DEBUG -LogToConsole $true -UseColors $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL', 'NONE')]
        [string]$LogLevel = 'INFO',

        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole = $true,

        [Parameter(Mandatory = $false)]
        [bool]$LogToFile = $false,

        [Parameter(Mandatory = $false)]
        [string]$DateFormat = 'yyyy-MM-dd HH:mm:ss',

        [Parameter(Mandatory = $false)]
        [string]$MessageFormat = '[{0}] [{1}] {2}',

        [Parameter(Mandatory = $false)]
        [bool]$IncludeCaller = $false,

        [Parameter(Mandatory = $false)]
        [int]$MaxFileSizeMB = 10,

        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 5,

        [Parameter(Mandatory = $false)]
        [bool]$UseColors = $true,

        [Parameter(Mandatory = $false)]
        [bool]$Append = $true
    )

    # Validate file logging requirements
    if ($LogToFile -and [string]::IsNullOrWhiteSpace($LogPath)) {
        throw "LogPath is required when LogToFile is enabled"
    }

    # Update configuration
    $script:LoggerConfig.LogLevel = $LogLevel
    $script:LoggerConfig.LogToConsole = $LogToConsole
    $script:LoggerConfig.LogToFile = $LogToFile
    $script:LoggerConfig.DateFormat = $DateFormat
    $script:LoggerConfig.MessageFormat = $MessageFormat
    $script:LoggerConfig.IncludeCaller = $IncludeCaller
    $script:LoggerConfig.MaxFileSizeMB = $MaxFileSizeMB
    $script:LoggerConfig.MaxLogFiles = $MaxLogFiles
    $script:LoggerConfig.UseColors = $UseColors

    if ($LogPath) {
        $script:LoggerConfig.LogPath = $LogPath

        # Create directory if it doesn't exist
        $logDir = Split-Path -Path $LogPath -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # Create or clear the log file
        if (-not $Append -or -not (Test-Path $LogPath)) {
            New-Item -ItemType File -Path $LogPath -Force | Out-Null
        }
    }

    $script:LoggerConfig.Initialized = $true

    Write-Verbose "Logger initialized with level: $LogLevel"
}

function Get-LoggerConfig {
    <#
    .SYNOPSIS
        Gets the current logger configuration.

    .DESCRIPTION
        Returns a copy of the current logger configuration settings.

    .EXAMPLE
        $config = Get-LoggerConfig
        Write-Host "Current log level: $($config.LogLevel)"
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:LoggerConfig.Clone()
}

function Set-LogLevel {
    <#
    .SYNOPSIS
        Sets the current log level.

    .DESCRIPTION
        Changes the minimum log level for messages to be recorded.

    .PARAMETER Level
        The new log level: DEBUG, INFO, WARNING, ERROR, CRITICAL, NONE.

    .EXAMPLE
        Set-LogLevel -Level DEBUG
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL', 'NONE')]
        [string]$Level
    )

    $script:LoggerConfig.LogLevel = $Level
    Write-Verbose "Log level set to: $Level"
}

# ============================================================================
# Core Logging Function
# ============================================================================

function Write-LogMessage {
    <#
    .SYNOPSIS
        Writes a message to the log.

    .DESCRIPTION
        Core logging function that writes messages to configured outputs (console/file).

    .PARAMETER Message
        The message to log.

    .PARAMETER Level
        The log level: DEBUG, INFO, WARNING, ERROR, CRITICAL.

    .PARAMETER Exception
        Optional exception object to include in the log.

    .PARAMETER NoNewline
        Don't add newline at the end of console output.

    .EXAMPLE
        Write-LogMessage -Message "Application started" -Level INFO

    .EXAMPLE
        Write-LogMessage -Message "Failed to connect" -Level ERROR -Exception $_.Exception
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')]
        [string]$Level = 'INFO',

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )

    process {
        # Check if message level meets minimum threshold
        $messageLevelValue = $script:LogLevels[$Level]
        $configLevelValue = $script:LogLevels[$script:LoggerConfig.LogLevel]

        if ($messageLevelValue -lt $configLevelValue) {
            return
        }

        # Build timestamp
        $timestamp = Get-Date -Format $script:LoggerConfig.DateFormat

        # Build message
        $logMessage = $Message

        # Include caller information if enabled
        if ($script:LoggerConfig.IncludeCaller) {
            $caller = (Get-PSCallStack)[1]
            if ($caller.FunctionName -and $caller.FunctionName -ne '<ScriptBlock>') {
                $logMessage = "[$($caller.FunctionName)] $logMessage"
            }
        }

        # Include exception details if provided
        if ($Exception) {
            $logMessage += "`n  Exception: $($Exception.GetType().Name): $($Exception.Message)"
            if ($Exception.InnerException) {
                $logMessage += "`n  Inner Exception: $($Exception.InnerException.Message)"
            }
        }

        # Format the complete message
        $formattedMessage = $script:LoggerConfig.MessageFormat -f $timestamp, $Level.PadRight(8), $logMessage

        # Write to console
        if ($script:LoggerConfig.LogToConsole) {
            $writeParams = @{
                Object = $formattedMessage
            }

            if ($script:LoggerConfig.UseColors -and $script:LogColors.ContainsKey($Level)) {
                $writeParams['ForegroundColor'] = $script:LogColors[$Level]
            }

            if ($NoNewline) {
                $writeParams['NoNewline'] = $true
            }

            Write-Host @writeParams
        }

        # Write to file
        if ($script:LoggerConfig.LogToFile -and $script:LoggerConfig.LogPath) {
            try {
                # Check for log rotation
                Test-LogRotation

                # Write to file (thread-safe with mutex)
                $mutexName = "Global\PowerShellLogger_" + ($script:LoggerConfig.LogPath -replace '[\\/:*?"<>|]', '_')
                $mutex = New-Object System.Threading.Mutex($false, $mutexName)

                try {
                    $mutex.WaitOne() | Out-Null
                    Add-Content -Path $script:LoggerConfig.LogPath -Value $formattedMessage -Encoding UTF8
                }
                finally {
                    $mutex.ReleaseMutex()
                    $mutex.Dispose()
                }
            }
            catch {
                # Fallback to Write-Warning if file logging fails
                Write-Warning "Failed to write to log file: $_"
            }
        }
    }
}

# ============================================================================
# Convenience Logging Functions
# ============================================================================

function Write-LogDebug {
    <#
    .SYNOPSIS
        Writes a DEBUG level message to the log.

    .PARAMETER Message
        The message to log.

    .EXAMPLE
        Write-LogDebug "Variable value: $myVar"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message
    )

    process {
        Write-LogMessage -Message $Message -Level DEBUG
    }
}

function Write-LogInfo {
    <#
    .SYNOPSIS
        Writes an INFO level message to the log.

    .PARAMETER Message
        The message to log.

    .EXAMPLE
        Write-LogInfo "Application started successfully"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message
    )

    process {
        Write-LogMessage -Message $Message -Level INFO
    }
}

function Write-LogWarning {
    <#
    .SYNOPSIS
        Writes a WARNING level message to the log.

    .PARAMETER Message
        The message to log.

    .EXAMPLE
        Write-LogWarning "Configuration file not found, using defaults"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message
    )

    process {
        Write-LogMessage -Message $Message -Level WARNING
    }
}

function Write-LogError {
    <#
    .SYNOPSIS
        Writes an ERROR level message to the log.

    .PARAMETER Message
        The message to log.

    .PARAMETER Exception
        Optional exception object to include.

    .EXAMPLE
        Write-LogError "Failed to connect to database"

    .EXAMPLE
        try { ... } catch { Write-LogError "Operation failed" -Exception $_.Exception }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception
    )

    process {
        Write-LogMessage -Message $Message -Level ERROR -Exception $Exception
    }
}

function Write-LogCritical {
    <#
    .SYNOPSIS
        Writes a CRITICAL level message to the log.

    .PARAMETER Message
        The message to log.

    .PARAMETER Exception
        Optional exception object to include.

    .EXAMPLE
        Write-LogCritical "System failure - shutting down"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception
    )

    process {
        Write-LogMessage -Message $Message -Level CRITICAL -Exception $Exception
    }
}

# ============================================================================
# Log File Management Functions
# ============================================================================

function Test-LogRotation {
    <#
    .SYNOPSIS
        Checks if log rotation is needed and performs it if necessary.

    .DESCRIPTION
        Internal function that checks log file size and rotates if needed.
    #>
    [CmdletBinding()]
    param()

    if (-not $script:LoggerConfig.LogPath -or -not (Test-Path $script:LoggerConfig.LogPath)) {
        return
    }

    $logFile = Get-Item $script:LoggerConfig.LogPath
    $maxSizeBytes = $script:LoggerConfig.MaxFileSizeMB * 1MB

    if ($logFile.Length -ge $maxSizeBytes) {
        Invoke-LogRotation
    }
}

function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Performs log file rotation.

    .DESCRIPTION
        Rotates log files by renaming the current log and removing old files.

    .EXAMPLE
        Invoke-LogRotation
    #>
    [CmdletBinding()]
    param()

    if (-not $script:LoggerConfig.LogPath) {
        return
    }

    $logPath = $script:LoggerConfig.LogPath
    $logDir = Split-Path -Path $logPath -Parent
    $logName = [System.IO.Path]::GetFileNameWithoutExtension($logPath)
    $logExt = [System.IO.Path]::GetExtension($logPath)

    # Rotate existing files
    for ($i = $script:LoggerConfig.MaxLogFiles - 1; $i -ge 1; $i--) {
        $oldFile = Join-Path $logDir "$logName.$i$logExt"
        $newFile = Join-Path $logDir "$logName.$($i + 1)$logExt"

        if (Test-Path $oldFile) {
            if ($i -eq ($script:LoggerConfig.MaxLogFiles - 1)) {
                Remove-Item $oldFile -Force
            }
            else {
                Move-Item $oldFile $newFile -Force
            }
        }
    }

    # Rename current log file
    if (Test-Path $logPath) {
        $firstRotated = Join-Path $logDir "$logName.1$logExt"
        Move-Item $logPath $firstRotated -Force
    }

    # Create new empty log file
    New-Item -ItemType File -Path $logPath -Force | Out-Null

    Write-Verbose "Log file rotated"
}

function Clear-LogFile {
    <#
    .SYNOPSIS
        Clears the current log file.

    .DESCRIPTION
        Empties the current log file without deleting it.

    .PARAMETER Archive
        Archive the current log before clearing.

    .EXAMPLE
        Clear-LogFile

    .EXAMPLE
        Clear-LogFile -Archive
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Archive
    )

    if (-not $script:LoggerConfig.LogPath) {
        Write-Warning "No log file configured"
        return
    }

    if (-not (Test-Path $script:LoggerConfig.LogPath)) {
        Write-Warning "Log file does not exist"
        return
    }

    if ($PSCmdlet.ShouldProcess($script:LoggerConfig.LogPath, "Clear log file")) {
        if ($Archive) {
            Invoke-LogRotation
        }
        else {
            Clear-Content -Path $script:LoggerConfig.LogPath
        }

        Write-Verbose "Log file cleared"
    }
}

function Get-LogEntries {
    <#
    .SYNOPSIS
        Reads entries from the log file.

    .DESCRIPTION
        Retrieves log entries from the current log file with optional filtering.

    .PARAMETER Level
        Filter by log level.

    .PARAMETER Last
        Get last N entries.

    .PARAMETER Since
        Get entries since specified DateTime.

    .PARAMETER Pattern
        Filter entries matching regex pattern.

    .PARAMETER AsObject
        Return parsed log entry objects instead of raw text.

    .EXAMPLE
        Get-LogEntries -Last 50

    .EXAMPLE
        Get-LogEntries -Level ERROR -Since (Get-Date).AddHours(-1)

    .EXAMPLE
        Get-LogEntries -Pattern "database" -AsObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [int]$Last,

        [Parameter(Mandatory = $false)]
        [DateTime]$Since,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )

    if (-not $script:LoggerConfig.LogPath) {
        Write-Warning "No log file configured"
        return
    }

    if (-not (Test-Path $script:LoggerConfig.LogPath)) {
        Write-Warning "Log file does not exist"
        return
    }

    # Read all lines
    $entries = Get-Content -Path $script:LoggerConfig.LogPath

    # Filter by level
    if ($Level) {
        $entries = $entries | Where-Object { $_ -match "\[$Level\s*\]" }
    }

    # Filter by pattern
    if ($Pattern) {
        $entries = $entries | Where-Object { $_ -match $Pattern }
    }

    # Filter by time (requires parsing)
    if ($Since) {
        $filteredEntries = @()
        foreach ($entry in $entries) {
            if ($entry -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
                $entryTime = [DateTime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
                if ($entryTime -ge $Since) {
                    $filteredEntries += $entry
                }
            }
        }
        $entries = $filteredEntries
    }

    # Get last N entries
    if ($Last -and $Last -gt 0) {
        $entries = $entries | Select-Object -Last $Last
    }

    # Convert to objects if requested
    if ($AsObject) {
        $entries | ForEach-Object {
            if ($_ -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] \[(\w+)\s*\] (.*)$') {
                [PSCustomObject]@{
                    Timestamp = [DateTime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
                    Level     = $Matches[2].Trim()
                    Message   = $Matches[3]
                }
            }
        }
    }
    else {
        return $entries
    }
}

function Get-LogFilePath {
    <#
    .SYNOPSIS
        Gets the current log file path.

    .DESCRIPTION
        Returns the path to the currently configured log file.

    .EXAMPLE
        $path = Get-LogFilePath
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $script:LoggerConfig.LogPath
}

function Get-LogFileSize {
    <#
    .SYNOPSIS
        Gets the current log file size.

    .DESCRIPTION
        Returns information about the current log file size.

    .EXAMPLE
        $size = Get-LogFileSize
        Write-Host "Log file is $($size.SizeMB) MB"
    #>
    [CmdletBinding()]
    param()

    if (-not $script:LoggerConfig.LogPath -or -not (Test-Path $script:LoggerConfig.LogPath)) {
        return $null
    }

    $file = Get-Item $script:LoggerConfig.LogPath

    return [PSCustomObject]@{
        Path       = $file.FullName
        SizeBytes  = $file.Length
        SizeKB     = [Math]::Round($file.Length / 1KB, 2)
        SizeMB     = [Math]::Round($file.Length / 1MB, 2)
        MaxSizeMB  = $script:LoggerConfig.MaxFileSizeMB
        PercentUsed = [Math]::Round(($file.Length / ($script:LoggerConfig.MaxFileSizeMB * 1MB)) * 100, 1)
    }
}

# ============================================================================
# Utility Functions
# ============================================================================

function Write-LogSeparator {
    <#
    .SYNOPSIS
        Writes a separator line to the log.

    .DESCRIPTION
        Writes a visual separator for grouping log entries.

    .PARAMETER Character
        Character to use for separator. Default: '-'.

    .PARAMETER Length
        Length of separator. Default: 60.

    .EXAMPLE
        Write-LogSeparator

    .EXAMPLE
        Write-LogSeparator -Character "=" -Length 80
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [char]$Character = '-',

        [Parameter(Mandatory = $false)]
        [int]$Length = 60
    )

    $separator = [string]::new($Character, $Length)
    Write-LogInfo $separator
}

function Write-LogHeader {
    <#
    .SYNOPSIS
        Writes a header section to the log.

    .DESCRIPTION
        Writes a formatted header with the specified title.

    .PARAMETER Title
        The header title.

    .EXAMPLE
        Write-LogHeader "Application Startup"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Title
    )

    Write-LogSeparator -Character '=' -Length 60
    Write-LogInfo $Title.ToUpper()
    Write-LogSeparator -Character '=' -Length 60
}

function Start-LogOperation {
    <#
    .SYNOPSIS
        Logs the start of an operation.

    .DESCRIPTION
        Writes a standardized start message for an operation.

    .PARAMETER OperationName
        Name of the operation.

    .EXAMPLE
        Start-LogOperation "Database Backup"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OperationName
    )

    Write-LogInfo ">>> Starting: $OperationName"
}

function Complete-LogOperation {
    <#
    .SYNOPSIS
        Logs the completion of an operation.

    .DESCRIPTION
        Writes a standardized completion message for an operation.

    .PARAMETER OperationName
        Name of the operation.

    .PARAMETER Success
        Whether the operation succeeded.

    .PARAMETER Duration
        Optional duration of the operation.

    .EXAMPLE
        Complete-LogOperation "Database Backup" -Success $true

    .EXAMPLE
        Complete-LogOperation "Database Backup" -Success $true -Duration $stopwatch.Elapsed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OperationName,

        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,

        [Parameter(Mandatory = $false)]
        [TimeSpan]$Duration
    )

    $status = if ($Success) { "COMPLETED" } else { "FAILED" }
    $message = "<<< $status`: $OperationName"

    if ($Duration) {
        $message += " (Duration: $($Duration.ToString('hh\:mm\:ss\.fff')))"
    }

    if ($Success) {
        Write-LogInfo $message
    }
    else {
        Write-LogError $message
    }
}

function Write-LogObject {
    <#
    .SYNOPSIS
        Logs an object's properties.

    .DESCRIPTION
        Writes the properties of an object to the log in a formatted way.

    .PARAMETER InputObject
        The object to log.

    .PARAMETER Name
        Optional name for the object.

    .PARAMETER Level
        Log level to use. Default: INFO.

    .EXAMPLE
        Write-LogObject -InputObject $config -Name "Configuration"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')]
        [string]$Level = 'INFO'
    )

    process {
        if ($Name) {
            Write-LogMessage -Message "Object: $Name" -Level $Level
        }

        if ($InputObject -is [hashtable]) {
            foreach ($key in $InputObject.Keys) {
                Write-LogMessage -Message "  $key = $($InputObject[$key])" -Level $Level
            }
        }
        elseif ($InputObject -is [PSCustomObject] -or $InputObject.GetType().Name -ne 'String') {
            $InputObject.PSObject.Properties | ForEach-Object {
                Write-LogMessage -Message "  $($_.Name) = $($_.Value)" -Level $Level
            }
        }
        else {
            Write-LogMessage -Message "  $InputObject" -Level $Level
        }
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # Initialization
    'Initialize-Logger',
    'Get-LoggerConfig',
    'Set-LogLevel',

    # Core logging
    'Write-LogMessage',

    # Convenience functions
    'Write-LogDebug',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Write-LogCritical',

    # File management
    'Invoke-LogRotation',
    'Clear-LogFile',
    'Get-LogEntries',
    'Get-LogFilePath',
    'Get-LogFileSize',

    # Utilities
    'Write-LogSeparator',
    'Write-LogHeader',
    'Start-LogOperation',
    'Complete-LogOperation',
    'Write-LogObject'
)
