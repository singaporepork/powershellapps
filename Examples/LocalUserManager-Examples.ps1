<#
.SYNOPSIS
    Example usage of the LocalUserManager module.

.DESCRIPTION
    This script demonstrates various user management functions provided by
    the LocalUserManager module. REQUIRES ADMINISTRATOR PRIVILEGES.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
    - Administrator privileges
    - Windows operating system
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\LocalUserManager.psm1" -Force

Write-Host "LocalUserManager Module Examples" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

Write-Host "NOTE: These examples require Administrator privileges." -ForegroundColor Yellow
Write-Host "Some examples show code patterns without execution.`n" -ForegroundColor Yellow

# ============================================================================
# Example 1: Check if user exists
# ============================================================================

Write-Host "Example 1: Check if user exists" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Check if a user exists
if (Test-LocalUserExists -Username "Administrator") {
    Write-Host "Administrator account exists"
}

# Check for a custom user
`$exists = Test-LocalUserExists -Username "jdoe"
Write-Host "User 'jdoe' exists: `$exists"
"@

# Actual example (safe)
$adminExists = Test-LocalUserExists -Username "Administrator"
Write-Host "`nAdministrator exists: $adminExists"

Write-Host ""

# ============================================================================
# Example 2: Get all local users
# ============================================================================

Write-Host "Example 2: List all local users" -ForegroundColor Yellow
Write-Host "--------------------------------"

# Get non-system users
$users = Get-AllLocalUsers
Write-Host "Regular users:"
$users | Format-Table -AutoSize

Write-Host ""

# ============================================================================
# Example 3: Create a new user
# ============================================================================

Write-Host "Example 3: Create a new user" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Create a simple user
`$password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
New-LocalUserAccount -Username "jdoe" -Password `$password -FullName "John Doe"

# Create user with more options
New-LocalUserAccount -Username "svcbackup" ``
    -Password `$password ``
    -FullName "Backup Service Account" ``
    -Description "Account for backup operations" ``
    -PasswordNeverExpires ``
    -Groups "Backup Operators"

# Create user who must change password
New-LocalUserAccount -Username "newemployee" ``
    -Password `$password ``
    -FullName "New Employee" ``
    -PasswordChangeRequired ``
    -Groups "Users", "Remote Desktop Users"

# Create disabled account
New-LocalUserAccount -Username "tempuser" ``
    -Password `$password ``
    -AccountDisabled ``
    -Description "Temporary account - not yet activated"
"@

Write-Host ""

# ============================================================================
# Example 4: Get user information
# ============================================================================

Write-Host "Example 4: Get user information" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Get detailed user info
`$userInfo = Get-LocalUserInfo -Username "jdoe"
Write-Host "Full Name: `$(`$userInfo.FullName)"
Write-Host "Enabled: `$(`$userInfo.Enabled)"
Write-Host "Last Logon: `$(`$userInfo.LastLogon)"

# Include group memberships
`$userInfo = Get-LocalUserInfo -Username "jdoe" -IncludeGroups
Write-Host "Groups: `$(`$userInfo.Groups -join ', ')"
"@

Write-Host ""

# ============================================================================
# Example 5: Modify user properties
# ============================================================================

Write-Host "Example 5: Modify user properties" -ForegroundColor Yellow
Write-Host "----------------------------------"

Write-Host @"
# Update user's full name and description
Set-LocalUserProperties -Username "jdoe" ``
    -FullName "John M. Doe" ``
    -Description "IT Department - Senior Admin"

# Set account to expire
Set-LocalUserProperties -Username "contractor" ``
    -AccountExpires (Get-Date).AddMonths(3)

# Set password to never expire (for service accounts)
Set-LocalUserProperties -Username "svcaccount" ``
    -PasswordNeverExpires `$true ``
    -UserCannotChangePassword `$true
"@

Write-Host ""

# ============================================================================
# Example 6: Password management
# ============================================================================

Write-Host "Example 6: Password management" -ForegroundColor Yellow
Write-Host "-------------------------------"

Write-Host @"
# Set a new password
`$newPassword = ConvertTo-SecureString "NewP@ssw0rd!" -AsPlainText -Force
Set-LocalUserPassword -Username "jdoe" -Password `$newPassword

# Set password and require change at next logon
Set-LocalUserPassword -Username "jdoe" -Password `$newPassword -RequireChange

# Test if password is correct
`$testPassword = Read-Host -AsSecureString -Prompt "Enter password"
if (Test-LocalUserPassword -Username "jdoe" -Password `$testPassword) {
    Write-Host "Password is correct"
} else {
    Write-Host "Invalid password"
}
"@

Write-Host ""

# ============================================================================
# Example 7: Group management
# ============================================================================

Write-Host "Example 7: Group management" -ForegroundColor Yellow
Write-Host "----------------------------"

Write-Host @"
# Add user to a group
Add-LocalUserToGroup -Username "jdoe" -GroupName "Administrators"

# Add user to multiple groups
Add-LocalUserToGroup -Username "jdoe" -GroupName "Remote Desktop Users", "Backup Operators"

# Remove user from a group
Remove-LocalUserFromGroup -Username "jdoe" -GroupName "Administrators"

# Get all groups for a user
`$groups = Get-LocalUserGroups -Username "jdoe"
`$groups | Format-Table

# Get all members of a group
`$members = Get-LocalGroupMembers -GroupName "Administrators"
`$members | Format-Table
"@

# Actual example - show Administrators group members
Write-Host "`nAdministrators group members:"
try {
    $admins = Get-LocalGroupMembers -GroupName "Administrators"
    $admins | Format-Table -AutoSize
}
catch {
    Write-Host "Could not retrieve group members" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Example 8: Enable/Disable accounts
# ============================================================================

Write-Host "Example 8: Enable/Disable accounts" -ForegroundColor Yellow
Write-Host "------------------------------------"

Write-Host @"
# Disable a user account
Disable-LocalUserAccount -Username "jdoe"

# Enable a user account
Enable-LocalUserAccount -Username "jdoe"

# Disable multiple accounts
"user1", "user2", "user3" | Disable-LocalUserAccount
"@

Write-Host ""

# ============================================================================
# Example 9: Rename user
# ============================================================================

Write-Host "Example 9: Rename user account" -ForegroundColor Yellow
Write-Host "-------------------------------"

Write-Host @"
# Rename a user
Rename-LocalUserAccount -OldUsername "jdoe" -NewUsername "john.doe"

# Verify the rename
`$userInfo = Get-LocalUserInfo -Username "john.doe"
"@

Write-Host ""

# ============================================================================
# Example 10: Remove user account
# ============================================================================

Write-Host "Example 10: Remove user account" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Remove a user (will prompt for confirmation)
Remove-LocalUserAccount -Username "tempuser"

# Remove without confirmation
Remove-LocalUserAccount -Username "tempuser" -Force
"@

Write-Host ""

# ============================================================================
# Example 11: Batch user creation
# ============================================================================

Write-Host "Example 11: Batch user creation" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Create multiple users from array
`$password = ConvertTo-SecureString "Welcome123!" -AsPlainText -Force

`$users = @(
    @{ Username = "user1"; FullName = "User One"; Description = "Test User 1" },
    @{ Username = "user2"; FullName = "User Two"; Description = "Test User 2" },
    @{ Username = "user3"; FullName = "User Three"; Description = "Test User 3" }
)

`$results = New-LocalUserBatch -Users `$users ``
    -DefaultPassword `$password ``
    -DefaultGroups "Users" ``
    -PasswordChangeRequired

`$results | Format-Table

# Create from CSV file
# CSV format: Username,FullName,Description,Groups
# user1,User One,Description,Users
# user2,User Two,Description,"Users,Remote Desktop Users"

`$results = New-LocalUserBatch -CsvPath "C:\users.csv" ``
    -DefaultPassword `$password ``
    -PasswordChangeRequired

`$results | Format-Table
"@

Write-Host ""

# ============================================================================
# Example 12: List all groups
# ============================================================================

Write-Host "Example 12: List all local groups" -ForegroundColor Yellow
Write-Host "----------------------------------"

$groups = Get-AllLocalGroups
Write-Host "Local groups on this system:"
$groups | Format-Table -AutoSize

Write-Host ""

# ============================================================================
# Example 13: Complete workflow - New employee onboarding
# ============================================================================

Write-Host "Example 13: New employee onboarding workflow" -ForegroundColor Yellow
Write-Host "---------------------------------------------"

Write-Host @"
# Complete workflow for onboarding a new employee

Import-Module ".\Modules\LocalUserManager.psm1"

function New-EmployeeAccount {
    param(
        [string]`$FirstName,
        [string]`$LastName,
        [string]`$Department,
        [string[]]`$Groups = @("Users")
    )

    # Generate username (first initial + last name)
    `$username = (`$FirstName.Substring(0,1) + `$LastName).ToLower()

    # Generate temporary password
    `$tempPassword = "Welcome" + (Get-Random -Minimum 1000 -Maximum 9999) + "!"
    `$securePassword = ConvertTo-SecureString `$tempPassword -AsPlainText -Force

    # Create the user
    `$user = New-LocalUserAccount -Username `$username ``
        -Password `$securePassword ``
        -FullName "`$FirstName `$LastName" ``
        -Description "`$Department" ``
        -PasswordChangeRequired ``
        -Groups `$Groups

    # Return account info
    return [PSCustomObject]@{
        Username = `$username
        FullName = "`$FirstName `$LastName"
        TempPassword = `$tempPassword
        Groups = `$Groups -join ", "
        Status = "Created"
    }
}

# Create new employee
`$newUser = New-EmployeeAccount ``
    -FirstName "Jane" ``
    -LastName "Smith" ``
    -Department "Marketing" ``
    -Groups "Users", "Marketing Team"

# Display info (for IT to provide to employee)
`$newUser | Format-List
"@

Write-Host ""

# ============================================================================
# Example 14: Security audit
# ============================================================================

Write-Host "Example 14: Security audit report" -ForegroundColor Yellow
Write-Host "----------------------------------"

Write-Host @"
# Generate security audit report

Import-Module ".\Modules\LocalUserManager.psm1"

# Get all users
`$allUsers = Get-AllLocalUsers -IncludeDisabled -IncludeSystem

# Find users with never-expiring passwords
`$neverExpire = Get-LocalUser | Where-Object { `$_.PasswordNeverExpires }

# Find disabled accounts
`$disabled = Get-LocalUser | Where-Object { -not `$_.Enabled }

# Find accounts that haven't logged in recently
`$inactiveDate = (Get-Date).AddDays(-90)
`$inactive = Get-LocalUser | Where-Object {
    `$_.LastLogon -and `$_.LastLogon -lt `$inactiveDate
}

# Find members of Administrators group
`$admins = Get-LocalGroupMembers -GroupName "Administrators"

# Generate report
`$report = [PSCustomObject]@{
    TotalUsers = `$allUsers.Count
    UsersWithNeverExpirePassword = `$neverExpire.Count
    DisabledAccounts = `$disabled.Count
    InactiveOver90Days = `$inactive.Count
    Administrators = `$admins.Count
}

`$report | Format-List
"@

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Security Notes:" -ForegroundColor Gray
Write-Host "- Always use strong passwords" -ForegroundColor Gray
Write-Host "- Require password change for new accounts" -ForegroundColor Gray
Write-Host "- Regularly audit group memberships" -ForegroundColor Gray
Write-Host "- Disable accounts instead of deleting (for audit trail)" -ForegroundColor Gray
Write-Host "- Use service accounts with non-expiring passwords carefully" -ForegroundColor Gray
