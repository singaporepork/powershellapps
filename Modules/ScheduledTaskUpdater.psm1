<#
.SYNOPSIS
    Modular PowerShell script for updating Windows Scheduled Tasks.

.DESCRIPTION
    This module provides functions to get, update, enable, disable, and manage
    Windows Scheduled Tasks. Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: Windows PowerShell 5.0+, ScheduledTasks module (built-in on Windows)
#>

#Requires -Version 5.0

# ============================================================================
# Helper Functions
# ============================================================================

function Test-ScheduledTaskExists {
    <#
    .SYNOPSIS
        Tests if a scheduled task exists.

    .DESCRIPTION
        Checks whether a scheduled task with the specified name exists in the given path.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .EXAMPLE
        Test-ScheduledTaskExists -TaskName "MyTask"

    .EXAMPLE
        Test-ScheduledTaskExists -TaskName "MyTask" -TaskPath "\Microsoft\Windows\"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\"
    )

    try {
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        return ($null -ne $task)
    }
    catch {
        return $false
    }
}

function Get-ScheduledTaskInfo {
    <#
    .SYNOPSIS
        Gets detailed information about a scheduled task.

    .DESCRIPTION
        Retrieves comprehensive information about a scheduled task including
        triggers, actions, principal, and settings.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER IncludeRunHistory
        Include the last run time and result.

    .EXAMPLE
        Get-ScheduledTaskInfo -TaskName "MyTask"

    .EXAMPLE
        Get-ScheduledTaskInfo -TaskName "MyTask" -IncludeRunHistory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRunHistory
    )

    process {
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop

            $info = [PSCustomObject]@{
                TaskName        = $task.TaskName
                TaskPath        = $task.TaskPath
                State           = $task.State
                Description     = $task.Description
                Author          = $task.Author
                Date            = $task.Date
                URI             = $task.URI
                Triggers        = @()
                Actions         = @()
                Principal       = $null
                Settings        = $null
            }

            # Process triggers
            foreach ($trigger in $task.Triggers) {
                $triggerInfo = [PSCustomObject]@{
                    Type           = $trigger.CimClass.CimClassName -replace 'MSFT_Task', '' -replace 'Trigger', ''
                    Enabled        = $trigger.Enabled
                    StartBoundary  = $trigger.StartBoundary
                    EndBoundary    = $trigger.EndBoundary
                    Repetition     = $null
                }

                if ($trigger.Repetition) {
                    $triggerInfo.Repetition = [PSCustomObject]@{
                        Interval         = $trigger.Repetition.Interval
                        Duration         = $trigger.Repetition.Duration
                        StopAtDurationEnd = $trigger.Repetition.StopAtDurationEnd
                    }
                }

                $info.Triggers += $triggerInfo
            }

            # Process actions
            foreach ($action in $task.Actions) {
                $actionInfo = [PSCustomObject]@{
                    Type             = $action.CimClass.CimClassName -replace 'MSFT_Task', ''
                    Execute          = $action.Execute
                    Arguments        = $action.Arguments
                    WorkingDirectory = $action.WorkingDirectory
                }
                $info.Actions += $actionInfo
            }

            # Process principal
            $info.Principal = [PSCustomObject]@{
                UserId           = $task.Principal.UserId
                LogonType        = $task.Principal.LogonType
                RunLevel         = $task.Principal.RunLevel
                GroupId          = $task.Principal.GroupId
            }

            # Process settings
            $info.Settings = [PSCustomObject]@{
                Enabled                    = $task.Settings.Enabled
                Hidden                     = $task.Settings.Hidden
                AllowDemandStart           = $task.Settings.AllowDemandStart
                AllowHardTerminate         = $task.Settings.AllowHardTerminate
                DisallowStartIfOnBatteries = $task.Settings.DisallowStartIfOnBatteries
                StopIfGoingOnBatteries     = $task.Settings.StopIfGoingOnBatteries
                RunOnlyIfIdle              = $task.Settings.RunOnlyIfIdle
                RunOnlyIfNetworkAvailable  = $task.Settings.RunOnlyIfNetworkAvailable
                StartWhenAvailable         = $task.Settings.StartWhenAvailable
                WakeToRun                  = $task.Settings.WakeToRun
                ExecutionTimeLimit         = $task.Settings.ExecutionTimeLimit
                DeleteExpiredTaskAfter     = $task.Settings.DeleteExpiredTaskAfter
                Priority                   = $task.Settings.Priority
                RestartCount               = $task.Settings.RestartCount
                RestartInterval            = $task.Settings.RestartInterval
                MultipleInstances          = $task.Settings.MultipleInstances
            }

            # Include run history if requested
            if ($IncludeRunHistory) {
                $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
                if ($taskInfo) {
                    $info | Add-Member -NotePropertyName 'LastRunTime' -NotePropertyValue $taskInfo.LastRunTime
                    $info | Add-Member -NotePropertyName 'LastTaskResult' -NotePropertyValue $taskInfo.LastTaskResult
                    $info | Add-Member -NotePropertyName 'NextRunTime' -NotePropertyValue $taskInfo.NextRunTime
                    $info | Add-Member -NotePropertyName 'NumberOfMissedRuns' -NotePropertyValue $taskInfo.NumberOfMissedRuns
                }
            }

            return $info
        }
        catch {
            throw "Failed to get scheduled task '$TaskName': $_"
        }
    }
}

# ============================================================================
# Trigger Update Functions
# ============================================================================

function Update-ScheduledTaskTrigger {
    <#
    .SYNOPSIS
        Updates the trigger(s) of a scheduled task.

    .DESCRIPTION
        Replaces the existing triggers of a scheduled task with new trigger(s).
        Supports various trigger types: Daily, Weekly, Once, AtStartup, AtLogon.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER TriggerType
        The type of trigger: Daily, Weekly, Once, AtStartup, AtLogon.

    .PARAMETER StartTime
        The time to start the task (for time-based triggers).

    .PARAMETER DaysInterval
        For Daily triggers, the interval in days.

    .PARAMETER WeeksInterval
        For Weekly triggers, the interval in weeks.

    .PARAMETER DaysOfWeek
        For Weekly triggers, the days of the week to run.

    .PARAMETER RepetitionInterval
        How often to repeat the task after it starts (e.g., "PT1H" for 1 hour).

    .PARAMETER RepetitionDuration
        How long to keep repeating (e.g., "P1D" for 1 day).

    .EXAMPLE
        Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "09:00"

    .EXAMPLE
        Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Weekly -StartTime "08:00" -DaysOfWeek Monday,Wednesday,Friday
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $true)]
        [ValidateSet('Daily', 'Weekly', 'Once', 'AtStartup', 'AtLogon')]
        [string]$TriggerType,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int]$DaysInterval = 1,

        [Parameter(Mandatory = $false)]
        [int]$WeeksInterval = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string[]]$DaysOfWeek = @('Monday'),

        [Parameter(Mandatory = $false)]
        [string]$RepetitionInterval,

        [Parameter(Mandatory = $false)]
        [string]$RepetitionDuration
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        # Create the trigger based on type
        $triggerParams = @{}

        switch ($TriggerType) {
            'Daily' {
                $triggerParams['Daily'] = $true
                $triggerParams['At'] = $StartTime
                $triggerParams['DaysInterval'] = $DaysInterval
            }
            'Weekly' {
                $triggerParams['Weekly'] = $true
                $triggerParams['At'] = $StartTime
                $triggerParams['WeeksInterval'] = $WeeksInterval
                $triggerParams['DaysOfWeek'] = $DaysOfWeek
            }
            'Once' {
                $triggerParams['Once'] = $true
                $triggerParams['At'] = $StartTime
            }
            'AtStartup' {
                $triggerParams['AtStartup'] = $true
            }
            'AtLogon' {
                $triggerParams['AtLogon'] = $true
            }
        }

        $trigger = New-ScheduledTaskTrigger @triggerParams

        # Add repetition if specified
        if ($RepetitionInterval) {
            $trigger.Repetition.Interval = $RepetitionInterval
            if ($RepetitionDuration) {
                $trigger.Repetition.Duration = $RepetitionDuration
            }
        }

        if ($PSCmdlet.ShouldProcess($TaskName, "Update trigger to $TriggerType")) {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            $task.Triggers = $trigger
            $task | Set-ScheduledTask

            Write-Verbose "Successfully updated trigger for task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to update trigger for task '$TaskName': $_"
    }
}

function Add-ScheduledTaskTrigger {
    <#
    .SYNOPSIS
        Adds a new trigger to an existing scheduled task.

    .DESCRIPTION
        Adds a trigger to the existing triggers of a scheduled task without removing current triggers.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER TriggerType
        The type of trigger to add.

    .PARAMETER StartTime
        The time to start the task.

    .PARAMETER DaysInterval
        For Daily triggers, the interval in days.

    .PARAMETER DaysOfWeek
        For Weekly triggers, the days of the week.

    .EXAMPLE
        Add-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "14:00"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $true)]
        [ValidateSet('Daily', 'Weekly', 'Once', 'AtStartup', 'AtLogon')]
        [string]$TriggerType,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [int]$DaysInterval = 1,

        [Parameter(Mandatory = $false)]
        [string[]]$DaysOfWeek = @('Monday')
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath

        # Create new trigger
        $triggerParams = @{}
        switch ($TriggerType) {
            'Daily' {
                $triggerParams['Daily'] = $true
                $triggerParams['At'] = $StartTime
                $triggerParams['DaysInterval'] = $DaysInterval
            }
            'Weekly' {
                $triggerParams['Weekly'] = $true
                $triggerParams['At'] = $StartTime
                $triggerParams['DaysOfWeek'] = $DaysOfWeek
            }
            'Once' {
                $triggerParams['Once'] = $true
                $triggerParams['At'] = $StartTime
            }
            'AtStartup' {
                $triggerParams['AtStartup'] = $true
            }
            'AtLogon' {
                $triggerParams['AtLogon'] = $true
            }
        }

        $newTrigger = New-ScheduledTaskTrigger @triggerParams

        if ($PSCmdlet.ShouldProcess($TaskName, "Add $TriggerType trigger")) {
            # Get existing triggers and add the new one
            $existingTriggers = @($task.Triggers)
            $allTriggers = $existingTriggers + $newTrigger
            $task.Triggers = $allTriggers
            $task | Set-ScheduledTask

            Write-Verbose "Successfully added trigger to task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to add trigger to task '$TaskName': $_"
    }
}

# ============================================================================
# Action Update Functions
# ============================================================================

function Update-ScheduledTaskAction {
    <#
    .SYNOPSIS
        Updates the action(s) of a scheduled task.

    .DESCRIPTION
        Replaces the existing actions of a scheduled task with a new action.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER Execute
        The path to the program or script to execute.

    .PARAMETER Argument
        Arguments to pass to the program.

    .PARAMETER WorkingDirectory
        The working directory for the action.

    .EXAMPLE
        Update-ScheduledTaskAction -TaskName "MyTask" -Execute "powershell.exe" -Argument "-File C:\Scripts\MyScript.ps1"

    .EXAMPLE
        Update-ScheduledTaskAction -TaskName "MyTask" -Execute "C:\App\program.exe" -WorkingDirectory "C:\App"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $true)]
        [string]$Execute,

        [Parameter(Mandatory = $false)]
        [string]$Argument,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        $actionParams = @{
            Execute = $Execute
        }

        if ($Argument) {
            $actionParams['Argument'] = $Argument
        }

        if ($WorkingDirectory) {
            $actionParams['WorkingDirectory'] = $WorkingDirectory
        }

        $action = New-ScheduledTaskAction @actionParams

        if ($PSCmdlet.ShouldProcess($TaskName, "Update action to execute '$Execute'")) {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            $task.Actions = $action
            $task | Set-ScheduledTask

            Write-Verbose "Successfully updated action for task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to update action for task '$TaskName': $_"
    }
}

# ============================================================================
# Principal Update Functions
# ============================================================================

function Update-ScheduledTaskPrincipal {
    <#
    .SYNOPSIS
        Updates the principal (security context) of a scheduled task.

    .DESCRIPTION
        Updates who the task runs as and with what privileges.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER UserId
        The user account to run the task as.

    .PARAMETER LogonType
        The logon type: Interactive, S4U, Password, ServiceAccount, Group.

    .PARAMETER RunLevel
        The run level: Limited or Highest.

    .EXAMPLE
        Update-ScheduledTaskPrincipal -TaskName "MyTask" -UserId "SYSTEM" -RunLevel Highest

    .EXAMPLE
        Update-ScheduledTaskPrincipal -TaskName "MyTask" -UserId "Domain\User" -LogonType Password -RunLevel Limited
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $false)]
        [string]$UserId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Interactive', 'S4U', 'Password', 'ServiceAccount', 'Group', 'InteractiveOrPassword')]
        [string]$LogonType,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Limited', 'Highest')]
        [string]$RunLevel
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        $principalParams = @{}

        if ($UserId) {
            $principalParams['UserId'] = $UserId
        }

        if ($LogonType) {
            $principalParams['LogonType'] = $LogonType
        }

        if ($RunLevel) {
            $principalParams['RunLevel'] = $RunLevel
        }

        if ($principalParams.Count -eq 0) {
            throw "At least one parameter (UserId, LogonType, or RunLevel) must be specified"
        }

        $principal = New-ScheduledTaskPrincipal @principalParams

        if ($PSCmdlet.ShouldProcess($TaskName, "Update principal")) {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath

            # Update with new principal
            Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Principal $principal

            Write-Verbose "Successfully updated principal for task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to update principal for task '$TaskName': $_"
    }
}

# ============================================================================
# Settings Update Functions
# ============================================================================

function Update-ScheduledTaskSettings {
    <#
    .SYNOPSIS
        Updates the settings of a scheduled task.

    .DESCRIPTION
        Updates various settings that control task behavior.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER AllowStartIfOnBatteries
        Allow the task to start if on battery power.

    .PARAMETER DontStopIfGoingOnBatteries
        Don't stop the task if switching to batteries.

    .PARAMETER StartWhenAvailable
        Start the task as soon as possible if a scheduled start is missed.

    .PARAMETER RunOnlyIfNetworkAvailable
        Run only if a network connection is available.

    .PARAMETER WakeToRun
        Wake the computer to run the task.

    .PARAMETER ExecutionTimeLimit
        Maximum time the task can run (e.g., "PT1H" for 1 hour, "PT0S" for no limit).

    .PARAMETER RestartCount
        Number of times to restart if the task fails.

    .PARAMETER RestartInterval
        Time to wait before restarting (e.g., "PT5M" for 5 minutes).

    .PARAMETER MultipleInstances
        Behavior when multiple instances: Parallel, Queue, IgnoreNew, StopExisting.

    .PARAMETER Priority
        Task priority (0-10, where 0 is highest).

    .PARAMETER Hidden
        Hide the task in the Task Scheduler UI.

    .EXAMPLE
        Update-ScheduledTaskSettings -TaskName "MyTask" -StartWhenAvailable $true -WakeToRun $true

    .EXAMPLE
        Update-ScheduledTaskSettings -TaskName "MyTask" -ExecutionTimeLimit "PT2H" -RestartCount 3 -RestartInterval "PT10M"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $false)]
        [bool]$AllowStartIfOnBatteries,

        [Parameter(Mandatory = $false)]
        [bool]$DontStopIfGoingOnBatteries,

        [Parameter(Mandatory = $false)]
        [bool]$StartWhenAvailable,

        [Parameter(Mandatory = $false)]
        [bool]$RunOnlyIfNetworkAvailable,

        [Parameter(Mandatory = $false)]
        [bool]$WakeToRun,

        [Parameter(Mandatory = $false)]
        [string]$ExecutionTimeLimit,

        [Parameter(Mandatory = $false)]
        [int]$RestartCount,

        [Parameter(Mandatory = $false)]
        [string]$RestartInterval,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Parallel', 'Queue', 'IgnoreNew', 'StopExisting')]
        [string]$MultipleInstances,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$Priority,

        [Parameter(Mandatory = $false)]
        [bool]$Hidden
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        $settingsParams = @{}

        if ($PSBoundParameters.ContainsKey('AllowStartIfOnBatteries')) {
            $settingsParams['AllowStartIfOnBatteries'] = $AllowStartIfOnBatteries
            # If allowing on batteries, also set DontStopIfGoingOnBatteries unless explicitly set
            if (-not $PSBoundParameters.ContainsKey('DontStopIfGoingOnBatteries')) {
                $settingsParams['DontStopIfGoingOnBatteries'] = $AllowStartIfOnBatteries
            }
        }

        if ($PSBoundParameters.ContainsKey('DontStopIfGoingOnBatteries')) {
            $settingsParams['DontStopIfGoingOnBatteries'] = $DontStopIfGoingOnBatteries
        }

        if ($PSBoundParameters.ContainsKey('StartWhenAvailable')) {
            $settingsParams['StartWhenAvailable'] = $StartWhenAvailable
        }

        if ($PSBoundParameters.ContainsKey('RunOnlyIfNetworkAvailable')) {
            $settingsParams['RunOnlyIfNetworkAvailable'] = $RunOnlyIfNetworkAvailable
        }

        if ($PSBoundParameters.ContainsKey('WakeToRun')) {
            $settingsParams['WakeToRun'] = $WakeToRun
        }

        if ($ExecutionTimeLimit) {
            $settingsParams['ExecutionTimeLimit'] = $ExecutionTimeLimit
        }

        if ($PSBoundParameters.ContainsKey('RestartCount')) {
            $settingsParams['RestartCount'] = $RestartCount
        }

        if ($RestartInterval) {
            $settingsParams['RestartInterval'] = $RestartInterval
        }

        if ($MultipleInstances) {
            $settingsParams['MultipleInstances'] = $MultipleInstances
        }

        if ($PSBoundParameters.ContainsKey('Priority')) {
            $settingsParams['Priority'] = $Priority
        }

        if ($PSBoundParameters.ContainsKey('Hidden')) {
            $settingsParams['Hidden'] = $Hidden
        }

        if ($settingsParams.Count -eq 0) {
            throw "At least one setting parameter must be specified"
        }

        $settings = New-ScheduledTaskSettingsSet @settingsParams

        if ($PSCmdlet.ShouldProcess($TaskName, "Update settings")) {
            Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Settings $settings

            Write-Verbose "Successfully updated settings for task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to update settings for task '$TaskName': $_"
    }
}

# ============================================================================
# State Management Functions
# ============================================================================

function Enable-ScheduledTaskState {
    <#
    .SYNOPSIS
        Enables a scheduled task.

    .DESCRIPTION
        Enables a scheduled task that is currently disabled.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .EXAMPLE
        Enable-ScheduledTaskState -TaskName "MyTask"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\"
    )

    process {
        try {
            if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
                throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
            }

            if ($PSCmdlet.ShouldProcess($TaskName, "Enable")) {
                Enable-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
                Write-Verbose "Successfully enabled task '$TaskName'"
                return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            }
        }
        catch {
            throw "Failed to enable task '$TaskName': $_"
        }
    }
}

function Disable-ScheduledTaskState {
    <#
    .SYNOPSIS
        Disables a scheduled task.

    .DESCRIPTION
        Disables a scheduled task without deleting it.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .EXAMPLE
        Disable-ScheduledTaskState -TaskName "MyTask"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\"
    )

    process {
        try {
            if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
                throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
            }

            if ($PSCmdlet.ShouldProcess($TaskName, "Disable")) {
                Disable-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
                Write-Verbose "Successfully disabled task '$TaskName'"
                return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            }
        }
        catch {
            throw "Failed to disable task '$TaskName': $_"
        }
    }
}

function Start-ScheduledTaskNow {
    <#
    .SYNOPSIS
        Starts a scheduled task immediately.

    .DESCRIPTION
        Runs a scheduled task immediately regardless of its schedule.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .EXAMPLE
        Start-ScheduledTaskNow -TaskName "MyTask"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\"
    )

    process {
        try {
            if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
                throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
            }

            if ($PSCmdlet.ShouldProcess($TaskName, "Start immediately")) {
                Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
                Write-Verbose "Successfully started task '$TaskName'"

                # Return task info with current state
                return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            }
        }
        catch {
            throw "Failed to start task '$TaskName': $_"
        }
    }
}

function Stop-ScheduledTaskNow {
    <#
    .SYNOPSIS
        Stops a running scheduled task.

    .DESCRIPTION
        Stops a scheduled task that is currently running.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .EXAMPLE
        Stop-ScheduledTaskNow -TaskName "MyTask"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\"
    )

    process {
        try {
            if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
                throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
            }

            if ($PSCmdlet.ShouldProcess($TaskName, "Stop")) {
                Stop-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
                Write-Verbose "Successfully stopped task '$TaskName'"
                return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            }
        }
        catch {
            throw "Failed to stop task '$TaskName': $_"
        }
    }
}

# ============================================================================
# Bulk Operations
# ============================================================================

function Get-ScheduledTasksByPath {
    <#
    .SYNOPSIS
        Gets all scheduled tasks in a specific path.

    .DESCRIPTION
        Retrieves all scheduled tasks from a specified task folder path.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER Recurse
        Include tasks from subfolders.

    .EXAMPLE
        Get-ScheduledTasksByPath -TaskPath "\Microsoft\Windows\"

    .EXAMPLE
        Get-ScheduledTasksByPath -TaskPath "\" -Recurse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    try {
        if ($Recurse) {
            $tasks = Get-ScheduledTask -TaskPath "$TaskPath*" -ErrorAction SilentlyContinue
        }
        else {
            $tasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue
        }

        return $tasks | Select-Object TaskName, TaskPath, State, Description
    }
    catch {
        throw "Failed to get scheduled tasks from path '$TaskPath': $_"
    }
}

function Update-ScheduledTaskDescription {
    <#
    .SYNOPSIS
        Updates the description of a scheduled task.

    .DESCRIPTION
        Changes the description text of an existing scheduled task.

    .PARAMETER TaskName
        The name of the scheduled task.

    .PARAMETER TaskPath
        The path to the task folder. Defaults to root ("\").

    .PARAMETER Description
        The new description for the task.

    .EXAMPLE
        Update-ScheduledTaskDescription -TaskName "MyTask" -Description "Updated task description"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = "\",

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    try {
        if (-not (Test-ScheduledTaskExists -TaskName $TaskName -TaskPath $TaskPath)) {
            throw "Scheduled task '$TaskName' not found in path '$TaskPath'"
        }

        if ($PSCmdlet.ShouldProcess($TaskName, "Update description")) {
            $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            $task.Description = $Description
            $task | Set-ScheduledTask

            Write-Verbose "Successfully updated description for task '$TaskName'"
            return Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
    }
    catch {
        throw "Failed to update description for task '$TaskName': $_"
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # Helper functions
    'Test-ScheduledTaskExists',
    'Get-ScheduledTaskInfo',

    # Trigger functions
    'Update-ScheduledTaskTrigger',
    'Add-ScheduledTaskTrigger',

    # Action functions
    'Update-ScheduledTaskAction',

    # Principal functions
    'Update-ScheduledTaskPrincipal',

    # Settings functions
    'Update-ScheduledTaskSettings',

    # State management
    'Enable-ScheduledTaskState',
    'Disable-ScheduledTaskState',
    'Start-ScheduledTaskNow',
    'Stop-ScheduledTaskNow',

    # Bulk operations
    'Get-ScheduledTasksByPath',
    'Update-ScheduledTaskDescription'
)
