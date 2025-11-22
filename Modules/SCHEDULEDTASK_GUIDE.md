# ScheduledTaskUpdater Module Guide

A comprehensive PowerShell module for managing and updating Windows Scheduled Tasks.

## Requirements

- Windows PowerShell 5.0 or later
- Windows operating system
- Administrator privileges (for most operations)
- ScheduledTasks module (built-in on Windows)

## Installation

No additional installation required. The module uses the built-in Windows ScheduledTasks module.

```powershell
Import-Module ".\Modules\ScheduledTaskUpdater.psm1"
```

## Functions Reference

### Helper Functions

| Function | Description |
|----------|-------------|
| `Test-ScheduledTaskExists` | Check if a scheduled task exists |
| `Get-ScheduledTaskInfo` | Get detailed information about a task |
| `Get-ScheduledTasksByPath` | List all tasks in a folder path |

### Trigger Management

| Function | Description |
|----------|-------------|
| `Update-ScheduledTaskTrigger` | Replace task triggers |
| `Add-ScheduledTaskTrigger` | Add trigger without removing existing |

### Action Management

| Function | Description |
|----------|-------------|
| `Update-ScheduledTaskAction` | Update what the task executes |

### Principal Management

| Function | Description |
|----------|-------------|
| `Update-ScheduledTaskPrincipal` | Update security context (user/privileges) |

### Settings Management

| Function | Description |
|----------|-------------|
| `Update-ScheduledTaskSettings` | Update task behavior settings |
| `Update-ScheduledTaskDescription` | Update task description |

### State Management

| Function | Description |
|----------|-------------|
| `Enable-ScheduledTaskState` | Enable a task |
| `Disable-ScheduledTaskState` | Disable a task |
| `Start-ScheduledTaskNow` | Run task immediately |
| `Stop-ScheduledTaskNow` | Stop running task |

## Quick Start Examples

### Check if a Task Exists

```powershell
if (Test-ScheduledTaskExists -TaskName "MyTask") {
    Write-Host "Task exists"
}
```

### Get Task Information

```powershell
$info = Get-ScheduledTaskInfo -TaskName "MyTask"
Write-Host "State: $($info.State)"
Write-Host "Triggers: $($info.Triggers.Count)"
```

### Update to Daily Schedule

```powershell
Update-ScheduledTaskTrigger -TaskName "MyTask" `
    -TriggerType Daily `
    -StartTime "09:00"
```

### Update to Weekly Schedule

```powershell
Update-ScheduledTaskTrigger -TaskName "MyTask" `
    -TriggerType Weekly `
    -StartTime "08:00" `
    -DaysOfWeek Monday, Wednesday, Friday
```

### Update Task Action

```powershell
Update-ScheduledTaskAction -TaskName "MyTask" `
    -Execute "powershell.exe" `
    -Argument "-File C:\Scripts\MyScript.ps1"
```

### Run as SYSTEM with Elevated Privileges

```powershell
Update-ScheduledTaskPrincipal -TaskName "MyTask" `
    -UserId "SYSTEM" `
    -RunLevel Highest
```

### Configure Task Settings

```powershell
Update-ScheduledTaskSettings -TaskName "MyTask" `
    -StartWhenAvailable $true `
    -ExecutionTimeLimit "PT2H" `
    -RestartCount 3 `
    -RestartInterval "PT5M"
```

## Trigger Types

| Type | Description | Parameters |
|------|-------------|------------|
| `Daily` | Run daily | `-StartTime`, `-DaysInterval` |
| `Weekly` | Run weekly | `-StartTime`, `-WeeksInterval`, `-DaysOfWeek` |
| `Once` | Run once | `-StartTime` |
| `AtStartup` | Run at system startup | None |
| `AtLogon` | Run at user logon | None |

## Time Duration Format

Task scheduler uses ISO 8601 duration format:

| Format | Meaning |
|--------|---------|
| `PT0S` | No limit (0 seconds) |
| `PT30M` | 30 minutes |
| `PT1H` | 1 hour |
| `PT2H30M` | 2 hours 30 minutes |
| `P1D` | 1 day |
| `P1DT12H` | 1 day and 12 hours |

## LogonType Values

| Value | Description |
|-------|-------------|
| `Interactive` | Run only when user is logged in |
| `S4U` | Service for User (stored credentials) |
| `Password` | Password stored (requires input) |
| `ServiceAccount` | Run as service account |
| `Group` | Run as group |
| `InteractiveOrPassword` | Interactive or stored password |

## RunLevel Values

| Value | Description |
|-------|-------------|
| `Limited` | Run with standard user privileges |
| `Highest` | Run with highest available privileges |

## MultipleInstances Values

| Value | Description |
|-------|-------------|
| `Parallel` | Start new instance alongside running |
| `Queue` | Queue new instance |
| `IgnoreNew` | Do not start if already running |
| `StopExisting` | Stop running and start new |

## Task Paths

Tasks are organized in folders. Common paths include:

- `\` - Root folder
- `\Microsoft\Windows\` - Windows system tasks
- `\MyCompany\` - Custom folder for your tasks

```powershell
# Work with tasks in custom paths
Get-ScheduledTaskInfo -TaskName "MyTask" -TaskPath "\MyCompany\Scripts\"

# List all tasks in a path
Get-ScheduledTasksByPath -TaskPath "\MyCompany\" -Recurse
```

## Complete Workflow Example

```powershell
Import-Module ".\Modules\ScheduledTaskUpdater.psm1"

$taskName = "DailyBackup"

# Verify task exists
if (Test-ScheduledTaskExists -TaskName $taskName) {
    # Update trigger to run at 3 AM daily
    Update-ScheduledTaskTrigger -TaskName $taskName `
        -TriggerType Daily `
        -StartTime "03:00"

    # Update action
    Update-ScheduledTaskAction -TaskName $taskName `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -File C:\Scripts\Backup.ps1"

    # Configure settings
    Update-ScheduledTaskSettings -TaskName $taskName `
        -StartWhenAvailable $true `
        -WakeToRun $true `
        -ExecutionTimeLimit "PT4H" `
        -RestartCount 2 `
        -RestartInterval "PT10M"

    # Run as SYSTEM
    Update-ScheduledTaskPrincipal -TaskName $taskName `
        -UserId "SYSTEM" `
        -RunLevel Highest

    # Enable the task
    Enable-ScheduledTaskState -TaskName $taskName

    Write-Host "Task updated successfully"
}
```

## Error Handling

All functions throw descriptive errors on failure:

```powershell
try {
    Update-ScheduledTaskTrigger -TaskName "NonExistent" -TriggerType Daily
}
catch {
    Write-Host "Error: $_"
}
```

## WhatIf Support

All modification functions support `-WhatIf`:

```powershell
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -WhatIf
# Shows what would happen without making changes
```

## Pipeline Support

Several functions support pipeline input:

```powershell
# Disable multiple tasks
"Task1", "Task2", "Task3" | Disable-ScheduledTaskState

# Get info for multiple tasks
"Task1", "Task2" | ForEach-Object { Get-ScheduledTaskInfo -TaskName $_ }
```

## Troubleshooting

### "Access Denied" Error

Run PowerShell as Administrator. Most task modifications require elevated privileges.

### Task Not Found

- Verify the task name is correct (case-sensitive)
- Check the task path if not in root folder
- Use `Get-ScheduledTasksByPath` to list available tasks

### Invalid Duration Format

Use ISO 8601 format: `PT` prefix for time, `P` for periods
- `PT1H30M` = 1 hour 30 minutes
- `P1D` = 1 day

### Trigger Not Updating

Ensure you're specifying all required parameters for the trigger type:
- Daily: `StartTime`
- Weekly: `StartTime`, `DaysOfWeek`

## Security Considerations

- Store passwords securely when using `Password` LogonType
- Use service accounts for unattended tasks
- Apply principle of least privilege with `RunLevel`
- Audit task changes in production environments
