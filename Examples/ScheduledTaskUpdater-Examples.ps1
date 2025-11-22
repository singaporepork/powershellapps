<#
.SYNOPSIS
    Example usage of the ScheduledTaskUpdater module.

.DESCRIPTION
    This script demonstrates various ways to use the ScheduledTaskUpdater module
    for managing Windows Scheduled Tasks.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
    - Administrator privileges (for most operations)
    - ScheduledTasks module (built-in on Windows)
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\ScheduledTaskUpdater.psm1" -Force

Write-Host "ScheduledTaskUpdater Module Examples" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# ============================================================================
# Example 1: Check if a task exists
# ============================================================================

Write-Host "Example 1: Check if a task exists" -ForegroundColor Yellow
Write-Host "---------------------------------"

$taskName = "GoogleUpdateTaskMachineCore"
$exists = Test-ScheduledTaskExists -TaskName $taskName
Write-Host "Task '$taskName' exists: $exists"

# Check with specific path
$exists = Test-ScheduledTaskExists -TaskName "SystemSoundsService" -TaskPath "\Microsoft\Windows\Multimedia\"
Write-Host "Task 'SystemSoundsService' in Multimedia path exists: $exists`n"

# ============================================================================
# Example 2: Get detailed task information
# ============================================================================

Write-Host "Example 2: Get detailed task information" -ForegroundColor Yellow
Write-Host "-----------------------------------------"

# Get a common Windows task for demonstration
$taskPath = "\Microsoft\Windows\Time Synchronization\"
$taskName = "SynchronizeTime"

if (Test-ScheduledTaskExists -TaskName $taskName -TaskPath $taskPath) {
    $info = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath $taskPath

    Write-Host "Task: $($info.TaskName)"
    Write-Host "Path: $($info.TaskPath)"
    Write-Host "State: $($info.State)"
    Write-Host "Description: $($info.Description)"

    if ($info.Triggers.Count -gt 0) {
        Write-Host "Triggers:"
        foreach ($trigger in $info.Triggers) {
            Write-Host "  - Type: $($trigger.Type), Enabled: $($trigger.Enabled)"
        }
    }

    if ($info.Actions.Count -gt 0) {
        Write-Host "Actions:"
        foreach ($action in $info.Actions) {
            Write-Host "  - Execute: $($action.Execute)"
            if ($action.Arguments) {
                Write-Host "    Arguments: $($action.Arguments)"
            }
        }
    }
}
else {
    Write-Host "Task not found - this is expected on some systems"
}

Write-Host ""

# ============================================================================
# Example 3: List tasks in a path
# ============================================================================

Write-Host "Example 3: List tasks in a path" -ForegroundColor Yellow
Write-Host "--------------------------------"

$tasks = Get-ScheduledTasksByPath -TaskPath "\Microsoft\Windows\Shell\" -ErrorAction SilentlyContinue
if ($tasks) {
    Write-Host "Tasks in Shell folder:"
    $tasks | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.TaskName) [$($_.State)]"
    }
}
else {
    Write-Host "No tasks found in Shell folder"
}

Write-Host ""

# ============================================================================
# Example 4: Update task trigger (Daily)
# ============================================================================

Write-Host "Example 4: Update task trigger (Daily)" -ForegroundColor Yellow
Write-Host "---------------------------------------"

Write-Host @"
# Update a task to run daily at 9:00 AM
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "09:00"

# Update to run every 2 days at 3:00 PM
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "15:00" -DaysInterval 2
"@

Write-Host ""

# ============================================================================
# Example 5: Update task trigger (Weekly)
# ============================================================================

Write-Host "Example 5: Update task trigger (Weekly)" -ForegroundColor Yellow
Write-Host "----------------------------------------"

Write-Host @"
# Run weekly on Monday and Friday at 8:00 AM
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Weekly ``
    -StartTime "08:00" ``
    -DaysOfWeek Monday, Friday

# Run every 2 weeks on Wednesday
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Weekly ``
    -StartTime "10:00" ``
    -WeeksInterval 2 ``
    -DaysOfWeek Wednesday
"@

Write-Host ""

# ============================================================================
# Example 6: Update task trigger (Special triggers)
# ============================================================================

Write-Host "Example 6: Special triggers" -ForegroundColor Yellow
Write-Host "----------------------------"

Write-Host @"
# Run at system startup
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType AtStartup

# Run at user logon
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType AtLogon

# Run once at a specific time
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Once ``
    -StartTime "2024-12-31 23:59"
"@

Write-Host ""

# ============================================================================
# Example 7: Add additional trigger
# ============================================================================

Write-Host "Example 7: Add additional trigger" -ForegroundColor Yellow
Write-Host "----------------------------------"

Write-Host @"
# Add a second trigger without removing the existing one
Add-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "14:00"
"@

Write-Host ""

# ============================================================================
# Example 8: Update task action
# ============================================================================

Write-Host "Example 8: Update task action" -ForegroundColor Yellow
Write-Host "------------------------------"

Write-Host @"
# Update to run a PowerShell script
Update-ScheduledTaskAction -TaskName "MyTask" ``
    -Execute "powershell.exe" ``
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\MyScript.ps1"

# Update to run an executable with working directory
Update-ScheduledTaskAction -TaskName "MyTask" ``
    -Execute "C:\Program Files\MyApp\app.exe" ``
    -Argument "--config settings.json" ``
    -WorkingDirectory "C:\Program Files\MyApp"
"@

Write-Host ""

# ============================================================================
# Example 9: Update task principal (security context)
# ============================================================================

Write-Host "Example 9: Update task principal" -ForegroundColor Yellow
Write-Host "---------------------------------"

Write-Host @"
# Run as SYSTEM with highest privileges
Update-ScheduledTaskPrincipal -TaskName "MyTask" ``
    -UserId "SYSTEM" ``
    -RunLevel Highest

# Run as a specific user
Update-ScheduledTaskPrincipal -TaskName "MyTask" ``
    -UserId "DOMAIN\ServiceAccount" ``
    -LogonType Password ``
    -RunLevel Limited

# Run interactively as current user
Update-ScheduledTaskPrincipal -TaskName "MyTask" ``
    -LogonType Interactive ``
    -RunLevel Limited
"@

Write-Host ""

# ============================================================================
# Example 10: Update task settings
# ============================================================================

Write-Host "Example 10: Update task settings" -ForegroundColor Yellow
Write-Host "---------------------------------"

Write-Host @"
# Allow task to run on battery
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -AllowStartIfOnBatteries `$true ``
    -DontStopIfGoingOnBatteries `$true

# Set execution time limit and restart on failure
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -ExecutionTimeLimit "PT2H" ``
    -RestartCount 3 ``
    -RestartInterval "PT10M"

# Configure for reliability
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -StartWhenAvailable `$true ``
    -WakeToRun `$true ``
    -RunOnlyIfNetworkAvailable `$true

# Set no time limit (run until complete)
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -ExecutionTimeLimit "PT0S"

# Set priority (0 = highest, 10 = lowest)
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -Priority 4

# Configure multiple instances behavior
Update-ScheduledTaskSettings -TaskName "MyTask" ``
    -MultipleInstances Queue
"@

Write-Host ""

# ============================================================================
# Example 11: Enable/Disable tasks
# ============================================================================

Write-Host "Example 11: Enable/Disable tasks" -ForegroundColor Yellow
Write-Host "---------------------------------"

Write-Host @"
# Disable a task
Disable-ScheduledTaskState -TaskName "MyTask"

# Enable a task
Enable-ScheduledTaskState -TaskName "MyTask"

# Disable multiple tasks via pipeline
"Task1", "Task2", "Task3" | Disable-ScheduledTaskState
"@

Write-Host ""

# ============================================================================
# Example 12: Start/Stop tasks
# ============================================================================

Write-Host "Example 12: Start/Stop tasks manually" -ForegroundColor Yellow
Write-Host "--------------------------------------"

Write-Host @"
# Start a task immediately (run now)
Start-ScheduledTaskNow -TaskName "MyTask"

# Stop a running task
Stop-ScheduledTaskNow -TaskName "MyTask"
"@

Write-Host ""

# ============================================================================
# Example 13: Update description
# ============================================================================

Write-Host "Example 13: Update task description" -ForegroundColor Yellow
Write-Host "------------------------------------"

Write-Host @"
# Update the description
Update-ScheduledTaskDescription -TaskName "MyTask" ``
    -Description "Daily backup task - runs at 9 AM and 5 PM"
"@

Write-Host ""

# ============================================================================
# Example 14: Complete task update workflow
# ============================================================================

Write-Host "Example 14: Complete task update workflow" -ForegroundColor Yellow
Write-Host "------------------------------------------"

Write-Host @"
# Full example: Update all aspects of a task
`$taskName = "MyBackupTask"

# First, verify the task exists
if (Test-ScheduledTaskExists -TaskName `$taskName) {
    # Update the trigger
    Update-ScheduledTaskTrigger -TaskName `$taskName ``
        -TriggerType Daily ``
        -StartTime "03:00" ``
        -RepetitionInterval "PT6H" ``
        -RepetitionDuration "P1D"

    # Update the action
    Update-ScheduledTaskAction -TaskName `$taskName ``
        -Execute "powershell.exe" ``
        -Argument "-File C:\Scripts\Backup.ps1 -Full"

    # Update settings
    Update-ScheduledTaskSettings -TaskName `$taskName ``
        -StartWhenAvailable `$true ``
        -ExecutionTimeLimit "PT4H" ``
        -RestartCount 2 ``
        -RestartInterval "PT15M"

    # Update principal to run as SYSTEM
    Update-ScheduledTaskPrincipal -TaskName `$taskName ``
        -UserId "SYSTEM" ``
        -RunLevel Highest

    # Update description
    Update-ScheduledTaskDescription -TaskName `$taskName ``
        -Description "Daily backup - runs at 3 AM, repeats every 6 hours"

    # Enable the task
    Enable-ScheduledTaskState -TaskName `$taskName

    # Get final task info
    `$taskInfo = Get-ScheduledTaskInfo -TaskName `$taskName
    Write-Host "Task updated successfully. State: `$(`$taskInfo.State)"
}
else {
    Write-Host "Task '`$taskName' not found"
}
"@

Write-Host ""

# ============================================================================
# Example 15: Using with task path
# ============================================================================

Write-Host "Example 15: Working with task paths" -ForegroundColor Yellow
Write-Host "------------------------------------"

Write-Host @"
# Tasks in custom folders
`$customPath = "\MyCompany\Scripts\"

# Check existence in custom path
Test-ScheduledTaskExists -TaskName "CleanupTask" -TaskPath `$customPath

# Get task info from custom path
Get-ScheduledTaskInfo -TaskName "CleanupTask" -TaskPath `$customPath

# Update task in custom path
Update-ScheduledTaskTrigger -TaskName "CleanupTask" -TaskPath `$customPath ``
    -TriggerType Weekly -StartTime "02:00" -DaysOfWeek Sunday

# List all tasks in a path
Get-ScheduledTasksByPath -TaskPath `$customPath

# List tasks recursively
Get-ScheduledTasksByPath -TaskPath "\" -Recurse | Where-Object { `$_.State -eq 'Ready' }
"@

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host @"

Note: Most task modification operations require Administrator privileges.
Run PowerShell as Administrator to use these functions on actual tasks.

For more information, use Get-Help on any function:
  Get-Help Update-ScheduledTaskTrigger -Full
  Get-Help Update-ScheduledTaskSettings -Examples
"@ -ForegroundColor Gray
