<#
.SYNOPSIS
    Modular PowerShell script for creating and managing local Windows users.

.DESCRIPTION
    This module provides comprehensive functions for creating, modifying, and managing
    local user accounts on Windows machines. Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+, Administrator privileges
#>

#Requires -Version 5.0
#Requires -RunAsAdministrator

# ============================================================================
# User Creation Functions
# ============================================================================

function New-LocalUserAccount {
    <#
    .SYNOPSIS
        Creates a new local user account.

    .DESCRIPTION
        Creates a new local user account with the specified properties.

    .PARAMETER Username
        The username for the new account.

    .PARAMETER Password
        The password as a SecureString.

    .PARAMETER FullName
        The full name of the user.

    .PARAMETER Description
        Description for the user account.

    .PARAMETER PasswordNeverExpires
        Set password to never expire.

    .PARAMETER UserCannotChangePassword
        Prevent user from changing password.

    .PARAMETER AccountDisabled
        Create account in disabled state.

    .PARAMETER PasswordChangeRequired
        Require password change at next logon.

    .PARAMETER Groups
        Array of group names to add the user to.

    .EXAMPLE
        $password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
        New-LocalUserAccount -Username "jdoe" -Password $password -FullName "John Doe"

    .EXAMPLE
        New-LocalUserAccount -Username "svcaccount" -Password $password -Description "Service Account" -PasswordNeverExpires
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9_\-\.]+$')]
        [ValidateLength(1, 20)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [string]$FullName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$PasswordNeverExpires,

        [Parameter(Mandatory = $false)]
        [switch]$UserCannotChangePassword,

        [Parameter(Mandatory = $false)]
        [switch]$AccountDisabled,

        [Parameter(Mandatory = $false)]
        [switch]$PasswordChangeRequired,

        [Parameter(Mandatory = $false)]
        [string[]]$Groups
    )

    try {
        # Check if user already exists
        if (Test-LocalUserExists -Username $Username) {
            throw "User '$Username' already exists"
        }

        if ($PSCmdlet.ShouldProcess($Username, "Create local user account")) {
            # Build parameters for New-LocalUser
            $userParams = @{
                Name                     = $Username
                Password                 = $Password
                PasswordNeverExpires     = $PasswordNeverExpires
                UserMayNotChangePassword = $UserCannotChangePassword
                AccountNeverExpires      = $true
                Disabled                 = $AccountDisabled
            }

            if ($FullName) {
                $userParams['FullName'] = $FullName
            }

            if ($Description) {
                $userParams['Description'] = $Description
            }

            # Create the user
            $newUser = New-LocalUser @userParams

            # Set password change required if specified
            if ($PasswordChangeRequired) {
                $newUser | Set-LocalUser -PasswordNeverExpires $false
                # Force password change using net user command
                net user $Username /logonpasswordchg:yes 2>&1 | Out-Null
            }

            # Add to groups if specified
            if ($Groups) {
                foreach ($group in $Groups) {
                    try {
                        Add-LocalGroupMember -Group $group -Member $Username -ErrorAction Stop
                        Write-Verbose "Added '$Username' to group '$group'"
                    }
                    catch {
                        Write-Warning "Failed to add user to group '$group': $_"
                    }
                }
            }

            Write-Verbose "Successfully created user '$Username'"

            # Return user info
            return Get-LocalUserInfo -Username $Username
        }
    }
    catch {
        throw "Failed to create user '$Username': $_"
    }
}

function New-LocalUserBatch {
    <#
    .SYNOPSIS
        Creates multiple local user accounts from an array or CSV.

    .DESCRIPTION
        Batch creates local user accounts with specified properties.

    .PARAMETER Users
        Array of user objects with properties: Username, Password, FullName, Description, Groups.

    .PARAMETER CsvPath
        Path to CSV file with user data.

    .PARAMETER DefaultPassword
        Default password for all users (if not specified individually).

    .PARAMETER DefaultGroups
        Default groups for all users.

    .PARAMETER PasswordChangeRequired
        Require password change for all users.

    .EXAMPLE
        $users = @(
            @{ Username = "user1"; FullName = "User One" },
            @{ Username = "user2"; FullName = "User Two" }
        )
        New-LocalUserBatch -Users $users -DefaultPassword $password

    .EXAMPLE
        New-LocalUserBatch -CsvPath "C:\users.csv" -DefaultGroups "Users"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Array')]
        [array]$Users,

        [Parameter(Mandatory = $true, ParameterSetName = 'CSV')]
        [string]$CsvPath,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$DefaultPassword,

        [Parameter(Mandatory = $false)]
        [string[]]$DefaultGroups,

        [Parameter(Mandatory = $false)]
        [switch]$PasswordChangeRequired
    )

    try {
        # Load users from CSV if specified
        if ($CsvPath) {
            if (-not (Test-Path $CsvPath)) {
                throw "CSV file not found: $CsvPath"
            }
            $Users = Import-Csv -Path $CsvPath
        }

        $results = @()

        foreach ($user in $Users) {
            $username = if ($user.Username) { $user.Username } else { $user.Name }

            if (-not $username) {
                Write-Warning "Skipping user with no username"
                continue
            }

            try {
                # Determine password
                $password = $DefaultPassword
                if ($user.Password) {
                    if ($user.Password -is [System.Security.SecureString]) {
                        $password = $user.Password
                    }
                    else {
                        $password = ConvertTo-SecureString $user.Password -AsPlainText -Force
                    }
                }

                if (-not $password) {
                    Write-Warning "Skipping user '$username': No password specified"
                    continue
                }

                # Build parameters
                $params = @{
                    Username = $username
                    Password = $password
                }

                if ($user.FullName) { $params['FullName'] = $user.FullName }
                if ($user.Description) { $params['Description'] = $user.Description }

                # Groups
                $groups = $DefaultGroups
                if ($user.Groups) {
                    $groups = if ($user.Groups -is [array]) { $user.Groups } else { $user.Groups -split ',' | ForEach-Object { $_.Trim() } }
                }
                if ($groups) { $params['Groups'] = $groups }

                if ($PasswordChangeRequired) {
                    $params['PasswordChangeRequired'] = $true
                }

                # Create user
                $result = New-LocalUserAccount @params

                $results += [PSCustomObject]@{
                    Username = $username
                    Status   = 'Created'
                    Message  = 'Success'
                }

                Write-Verbose "Created user: $username"
            }
            catch {
                $results += [PSCustomObject]@{
                    Username = $username
                    Status   = 'Failed'
                    Message  = $_.Exception.Message
                }

                Write-Warning "Failed to create user '$username': $_"
            }
        }

        return $results
    }
    catch {
        throw "Batch user creation failed: $_"
    }
}

# ============================================================================
# User Information Functions
# ============================================================================

function Test-LocalUserExists {
    <#
    .SYNOPSIS
        Tests if a local user account exists.

    .DESCRIPTION
        Checks whether a local user account with the specified name exists.

    .PARAMETER Username
        The username to check.

    .EXAMPLE
        if (Test-LocalUserExists -Username "jdoe") {
            Write-Host "User exists"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username
    )

    process {
        try {
            $user = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
            return ($null -ne $user)
        }
        catch {
            return $false
        }
    }
}

function Get-LocalUserInfo {
    <#
    .SYNOPSIS
        Gets detailed information about a local user.

    .DESCRIPTION
        Retrieves comprehensive information about a local user account.

    .PARAMETER Username
        The username to get information for.

    .PARAMETER IncludeGroups
        Include group memberships in the output.

    .EXAMPLE
        Get-LocalUserInfo -Username "jdoe" -IncludeGroups
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeGroups
    )

    process {
        try {
            $user = Get-LocalUser -Name $Username -ErrorAction Stop

            $info = [PSCustomObject]@{
                Username              = $user.Name
                FullName              = $user.FullName
                Description           = $user.Description
                Enabled               = $user.Enabled
                SID                   = $user.SID.Value
                LastLogon             = $user.LastLogon
                PasswordLastSet       = $user.PasswordLastSet
                PasswordExpires       = $user.PasswordExpires
                PasswordChangeableDate = $user.PasswordChangeableDate
                PasswordRequired      = $user.PasswordRequired
                UserMayChangePassword = $user.UserMayChangePassword
                AccountExpires        = $user.AccountExpires
                PrincipalSource       = $user.PrincipalSource
            }

            if ($IncludeGroups) {
                $groups = Get-LocalGroup | Where-Object {
                    (Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -like "*\$Username" -or $_.Name -eq $Username })
                } | Select-Object -ExpandProperty Name

                $info | Add-Member -NotePropertyName 'Groups' -NotePropertyValue $groups
            }

            return $info
        }
        catch {
            throw "Failed to get user info for '$Username': $_"
        }
    }
}

function Get-AllLocalUsers {
    <#
    .SYNOPSIS
        Gets all local user accounts.

    .DESCRIPTION
        Retrieves information about all local user accounts on the system.

    .PARAMETER IncludeDisabled
        Include disabled accounts.

    .PARAMETER IncludeSystem
        Include system accounts.

    .EXAMPLE
        Get-AllLocalUsers

    .EXAMPLE
        Get-AllLocalUsers -IncludeDisabled -IncludeSystem
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDisabled,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystem
    )

    try {
        $users = Get-LocalUser

        if (-not $IncludeDisabled) {
            $users = $users | Where-Object { $_.Enabled -eq $true }
        }

        if (-not $IncludeSystem) {
            $systemAccounts = @('Administrator', 'Guest', 'DefaultAccount', 'WDAGUtilityAccount')
            $users = $users | Where-Object { $_.Name -notin $systemAccounts }
        }

        return $users | Select-Object Name, FullName, Enabled, LastLogon, Description
    }
    catch {
        throw "Failed to get local users: $_"
    }
}

# ============================================================================
# User Modification Functions
# ============================================================================

function Set-LocalUserPassword {
    <#
    .SYNOPSIS
        Sets or resets a local user's password.

    .DESCRIPTION
        Changes the password for a local user account.

    .PARAMETER Username
        The username to change password for.

    .PARAMETER Password
        The new password as a SecureString.

    .PARAMETER RequireChange
        Require password change at next logon.

    .EXAMPLE
        $newPassword = ConvertTo-SecureString "NewP@ssw0rd" -AsPlainText -Force
        Set-LocalUserPassword -Username "jdoe" -Password $newPassword
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [switch]$RequireChange
    )

    try {
        if (-not (Test-LocalUserExists -Username $Username)) {
            throw "User '$Username' does not exist"
        }

        if ($PSCmdlet.ShouldProcess($Username, "Set password")) {
            Set-LocalUser -Name $Username -Password $Password

            if ($RequireChange) {
                net user $Username /logonpasswordchg:yes 2>&1 | Out-Null
            }

            Write-Verbose "Password updated for user '$Username'"
        }
    }
    catch {
        throw "Failed to set password for '$Username': $_"
    }
}

function Set-LocalUserProperties {
    <#
    .SYNOPSIS
        Updates properties of a local user account.

    .DESCRIPTION
        Modifies various properties of an existing local user account.

    .PARAMETER Username
        The username to modify.

    .PARAMETER FullName
        New full name for the user.

    .PARAMETER Description
        New description for the user.

    .PARAMETER PasswordNeverExpires
        Set whether password never expires.

    .PARAMETER UserCannotChangePassword
        Set whether user can change password.

    .PARAMETER AccountExpires
        Set account expiration date.

    .EXAMPLE
        Set-LocalUserProperties -Username "jdoe" -FullName "John M. Doe" -Description "IT Department"

    .EXAMPLE
        Set-LocalUserProperties -Username "temp" -AccountExpires (Get-Date).AddDays(30)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$FullName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [bool]$PasswordNeverExpires,

        [Parameter(Mandatory = $false)]
        [bool]$UserCannotChangePassword,

        [Parameter(Mandatory = $false)]
        [DateTime]$AccountExpires
    )

    try {
        if (-not (Test-LocalUserExists -Username $Username)) {
            throw "User '$Username' does not exist"
        }

        if ($PSCmdlet.ShouldProcess($Username, "Update properties")) {
            $params = @{ Name = $Username }

            if ($PSBoundParameters.ContainsKey('FullName')) {
                $params['FullName'] = $FullName
            }

            if ($PSBoundParameters.ContainsKey('Description')) {
                $params['Description'] = $Description
            }

            if ($PSBoundParameters.ContainsKey('PasswordNeverExpires')) {
                $params['PasswordNeverExpires'] = $PasswordNeverExpires
            }

            if ($PSBoundParameters.ContainsKey('UserCannotChangePassword')) {
                $params['UserMayNotChangePassword'] = $UserCannotChangePassword
            }

            if ($PSBoundParameters.ContainsKey('AccountExpires')) {
                $params['AccountExpires'] = $AccountExpires
            }

            Set-LocalUser @params

            Write-Verbose "Updated properties for user '$Username'"

            return Get-LocalUserInfo -Username $Username
        }
    }
    catch {
        throw "Failed to update properties for '$Username': $_"
    }
}

# ============================================================================
# User State Functions
# ============================================================================

function Enable-LocalUserAccount {
    <#
    .SYNOPSIS
        Enables a local user account.

    .DESCRIPTION
        Enables a disabled local user account.

    .PARAMETER Username
        The username to enable.

    .EXAMPLE
        Enable-LocalUserAccount -Username "jdoe"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username
    )

    process {
        try {
            if (-not (Test-LocalUserExists -Username $Username)) {
                throw "User '$Username' does not exist"
            }

            if ($PSCmdlet.ShouldProcess($Username, "Enable account")) {
                Enable-LocalUser -Name $Username
                Write-Verbose "Enabled user account '$Username'"
            }
        }
        catch {
            throw "Failed to enable user '$Username': $_"
        }
    }
}

function Disable-LocalUserAccount {
    <#
    .SYNOPSIS
        Disables a local user account.

    .DESCRIPTION
        Disables a local user account without deleting it.

    .PARAMETER Username
        The username to disable.

    .EXAMPLE
        Disable-LocalUserAccount -Username "jdoe"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username
    )

    process {
        try {
            if (-not (Test-LocalUserExists -Username $Username)) {
                throw "User '$Username' does not exist"
            }

            if ($PSCmdlet.ShouldProcess($Username, "Disable account")) {
                Disable-LocalUser -Name $Username
                Write-Verbose "Disabled user account '$Username'"
            }
        }
        catch {
            throw "Failed to disable user '$Username': $_"
        }
    }
}

function Remove-LocalUserAccount {
    <#
    .SYNOPSIS
        Removes a local user account.

    .DESCRIPTION
        Permanently deletes a local user account.

    .PARAMETER Username
        The username to remove.

    .PARAMETER Force
        Skip confirmation prompt.

    .EXAMPLE
        Remove-LocalUserAccount -Username "jdoe"

    .EXAMPLE
        Remove-LocalUserAccount -Username "tempuser" -Force
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    process {
        try {
            if (-not (Test-LocalUserExists -Username $Username)) {
                throw "User '$Username' does not exist"
            }

            if ($Force) {
                $ConfirmPreference = 'None'
            }

            if ($PSCmdlet.ShouldProcess($Username, "Remove user account")) {
                Remove-LocalUser -Name $Username
                Write-Verbose "Removed user account '$Username'"
            }
        }
        catch {
            throw "Failed to remove user '$Username': $_"
        }
    }
}

# ============================================================================
# Group Management Functions
# ============================================================================

function Add-LocalUserToGroup {
    <#
    .SYNOPSIS
        Adds a local user to a group.

    .DESCRIPTION
        Adds an existing local user to one or more local groups.

    .PARAMETER Username
        The username to add to the group.

    .PARAMETER GroupName
        The name of the group(s) to add the user to.

    .EXAMPLE
        Add-LocalUserToGroup -Username "jdoe" -GroupName "Administrators"

    .EXAMPLE
        Add-LocalUserToGroup -Username "jdoe" -GroupName "Administrators", "Remote Desktop Users"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string[]]$GroupName
    )

    try {
        if (-not (Test-LocalUserExists -Username $Username)) {
            throw "User '$Username' does not exist"
        }

        foreach ($group in $GroupName) {
            try {
                # Verify group exists
                $grp = Get-LocalGroup -Name $group -ErrorAction Stop

                if ($PSCmdlet.ShouldProcess("$Username to $group", "Add user to group")) {
                    Add-LocalGroupMember -Group $group -Member $Username -ErrorAction Stop
                    Write-Verbose "Added '$Username' to group '$group'"
                }
            }
            catch [Microsoft.PowerShell.Commands.MemberExistsException] {
                Write-Verbose "User '$Username' is already a member of '$group'"
            }
            catch {
                Write-Warning "Failed to add '$Username' to group '$group': $_"
            }
        }
    }
    catch {
        throw "Failed to add user to groups: $_"
    }
}

function Remove-LocalUserFromGroup {
    <#
    .SYNOPSIS
        Removes a local user from a group.

    .DESCRIPTION
        Removes an existing local user from one or more local groups.

    .PARAMETER Username
        The username to remove from the group.

    .PARAMETER GroupName
        The name of the group(s) to remove the user from.

    .EXAMPLE
        Remove-LocalUserFromGroup -Username "jdoe" -GroupName "Administrators"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string[]]$GroupName
    )

    try {
        if (-not (Test-LocalUserExists -Username $Username)) {
            throw "User '$Username' does not exist"
        }

        foreach ($group in $GroupName) {
            try {
                if ($PSCmdlet.ShouldProcess("$Username from $group", "Remove user from group")) {
                    Remove-LocalGroupMember -Group $group -Member $Username -ErrorAction Stop
                    Write-Verbose "Removed '$Username' from group '$group'"
                }
            }
            catch {
                Write-Warning "Failed to remove '$Username' from group '$group': $_"
            }
        }
    }
    catch {
        throw "Failed to remove user from groups: $_"
    }
}

function Get-LocalUserGroups {
    <#
    .SYNOPSIS
        Gets the groups a user belongs to.

    .DESCRIPTION
        Returns all local groups that a user is a member of.

    .PARAMETER Username
        The username to check.

    .EXAMPLE
        Get-LocalUserGroups -Username "jdoe"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Username
    )

    process {
        try {
            if (-not (Test-LocalUserExists -Username $Username)) {
                throw "User '$Username' does not exist"
            }

            $groups = Get-LocalGroup | Where-Object {
                $members = Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue
                $members | Where-Object { $_.Name -like "*\$Username" -or $_.Name -eq $Username }
            }

            return $groups | Select-Object Name, Description
        }
        catch {
            throw "Failed to get groups for user '$Username': $_"
        }
    }
}

# ============================================================================
# Utility Functions
# ============================================================================

function Test-LocalUserPassword {
    <#
    .SYNOPSIS
        Tests if a password is correct for a local user.

    .DESCRIPTION
        Validates a password against a local user account.

    .PARAMETER Username
        The username to test.

    .PARAMETER Password
        The password to test as a SecureString.

    .EXAMPLE
        $password = Read-Host -AsSecureString
        Test-LocalUserPassword -Username "jdoe" -Password $password
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password
    )

    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement

        $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)

        # Convert SecureString to plain text for validation
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        try {
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            return $context.ValidateCredentials($Username, $plainPassword)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
    catch {
        throw "Failed to validate password: $_"
    }
}

function Rename-LocalUserAccount {
    <#
    .SYNOPSIS
        Renames a local user account.

    .DESCRIPTION
        Changes the username of an existing local user account.

    .PARAMETER OldUsername
        The current username.

    .PARAMETER NewUsername
        The new username.

    .EXAMPLE
        Rename-LocalUserAccount -OldUsername "jdoe" -NewUsername "john.doe"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OldUsername,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9_\-\.]+$')]
        [ValidateLength(1, 20)]
        [string]$NewUsername
    )

    try {
        if (-not (Test-LocalUserExists -Username $OldUsername)) {
            throw "User '$OldUsername' does not exist"
        }

        if (Test-LocalUserExists -Username $NewUsername) {
            throw "User '$NewUsername' already exists"
        }

        if ($PSCmdlet.ShouldProcess("$OldUsername to $NewUsername", "Rename user")) {
            Rename-LocalUser -Name $OldUsername -NewName $NewUsername
            Write-Verbose "Renamed user '$OldUsername' to '$NewUsername'"

            return Get-LocalUserInfo -Username $NewUsername
        }
    }
    catch {
        throw "Failed to rename user: $_"
    }
}

function Get-LocalGroupMembers {
    <#
    .SYNOPSIS
        Gets members of a local group.

    .DESCRIPTION
        Returns all members of a specified local group.

    .PARAMETER GroupName
        The name of the group.

    .EXAMPLE
        Get-LocalGroupMembers -GroupName "Administrators"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$GroupName
    )

    try {
        $members = Get-LocalGroupMember -Group $GroupName -ErrorAction Stop

        return $members | Select-Object Name, ObjectClass, PrincipalSource
    }
    catch {
        throw "Failed to get members of group '$GroupName': $_"
    }
}

function Get-AllLocalGroups {
    <#
    .SYNOPSIS
        Gets all local groups.

    .DESCRIPTION
        Returns all local groups on the system.

    .EXAMPLE
        Get-AllLocalGroups
    #>
    [CmdletBinding()]
    param()

    try {
        return Get-LocalGroup | Select-Object Name, Description, SID
    }
    catch {
        throw "Failed to get local groups: $_"
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # User creation
    'New-LocalUserAccount',
    'New-LocalUserBatch',

    # User information
    'Test-LocalUserExists',
    'Get-LocalUserInfo',
    'Get-AllLocalUsers',

    # User modification
    'Set-LocalUserPassword',
    'Set-LocalUserProperties',
    'Rename-LocalUserAccount',

    # User state
    'Enable-LocalUserAccount',
    'Disable-LocalUserAccount',
    'Remove-LocalUserAccount',

    # Group management
    'Add-LocalUserToGroup',
    'Remove-LocalUserFromGroup',
    'Get-LocalUserGroups',
    'Get-LocalGroupMembers',
    'Get-AllLocalGroups',

    # Utilities
    'Test-LocalUserPassword'
)
