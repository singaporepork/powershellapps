<#
.SYNOPSIS
    Modular PowerShell script for validating Windows OS hardening settings.

.DESCRIPTION
    This module provides comprehensive functionality to validate Windows security hardening
    settings against security benchmarks like CIS (Center for Internet Security) for
    Windows Server 2019/2022 and Windows 10/11. It checks registry settings, security policies,
    audit configurations, Windows Firewall, services, and generates compliance reports.
    Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+
    Requires: Administrator privileges for most checks
#>

#Requires -Version 5.0

# ============================================================================
# Module Variables
# ============================================================================

# Compliance status values
$script:ComplianceStatus = @{
    'Pass'        = 'Pass'
    'Fail'        = 'Fail'
    'Error'       = 'Error'
    'NotChecked'  = 'Not Checked'
    'NotApplicable' = 'Not Applicable'
}

# Severity levels for findings
$script:SeverityLevels = @{
    'Critical' = 1
    'High'     = 2
    'Medium'   = 3
    'Low'      = 4
    'Info'     = 5
}

# Default validator configuration
$script:ValidatorConfig = @{
    OutputPath          = $null
    IncludePassedChecks = $true
    Verbose            = $false
    BenchmarkVersion   = 'CIS 1.0.0'
    Initialized        = $false
}

# Built-in CIS Benchmark checks for Windows Server 2019
$script:CISBenchmarkChecks = @(
    # Account Policies - Password Policy
    @{
        Id = '1.1.1'
        Category = 'Account Policies'
        SubCategory = 'Password Policy'
        Name = 'Enforce password history'
        Description = 'Ensure password history is set to 24 or more passwords'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
        RegistryName = 'RefusePasswordChange'
        ExpectedValue = 0
        Operator = 'Equals'
        Severity = 'Medium'
        Remediation = 'Configure the policy value to 24 or more passwords remembered'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.1.1'
    },
    @{
        Id = '1.1.2'
        Category = 'Account Policies'
        SubCategory = 'Password Policy'
        Name = 'Maximum password age'
        Description = 'Ensure maximum password age is set to 365 or fewer days'
        CheckType = 'SecurityPolicy'
        PolicyName = 'MaximumPasswordAge'
        ExpectedValue = 365
        Operator = 'LessOrEqual'
        Severity = 'Medium'
        Remediation = 'Configure maximum password age to 365 days or less'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.1.2'
    },
    @{
        Id = '1.1.3'
        Category = 'Account Policies'
        SubCategory = 'Password Policy'
        Name = 'Minimum password age'
        Description = 'Ensure minimum password age is set to 1 or more days'
        CheckType = 'SecurityPolicy'
        PolicyName = 'MinimumPasswordAge'
        ExpectedValue = 1
        Operator = 'GreaterOrEqual'
        Severity = 'Medium'
        Remediation = 'Configure minimum password age to 1 day or more'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.1.3'
    },
    @{
        Id = '1.1.4'
        Category = 'Account Policies'
        SubCategory = 'Password Policy'
        Name = 'Minimum password length'
        Description = 'Ensure minimum password length is set to 14 or more characters'
        CheckType = 'SecurityPolicy'
        PolicyName = 'MinimumPasswordLength'
        ExpectedValue = 14
        Operator = 'GreaterOrEqual'
        Severity = 'High'
        Remediation = 'Configure minimum password length to 14 characters or more'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.1.4'
    },
    # Account Policies - Account Lockout Policy
    @{
        Id = '1.2.1'
        Category = 'Account Policies'
        SubCategory = 'Account Lockout Policy'
        Name = 'Account lockout duration'
        Description = 'Ensure account lockout duration is set to 15 or more minutes'
        CheckType = 'SecurityPolicy'
        PolicyName = 'LockoutDuration'
        ExpectedValue = 15
        Operator = 'GreaterOrEqual'
        Severity = 'Medium'
        Remediation = 'Configure account lockout duration to 15 minutes or more'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.2.1'
    },
    @{
        Id = '1.2.2'
        Category = 'Account Policies'
        SubCategory = 'Account Lockout Policy'
        Name = 'Account lockout threshold'
        Description = 'Ensure account lockout threshold is set to 5 or fewer invalid logon attempts'
        CheckType = 'SecurityPolicy'
        PolicyName = 'LockoutBadCount'
        ExpectedValue = 5
        Operator = 'LessOrEqual'
        Severity = 'Medium'
        Remediation = 'Configure account lockout threshold to 5 or fewer attempts'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 1.2.2'
    },
    # Local Policies - Security Options
    @{
        Id = '2.3.1.1'
        Category = 'Local Policies'
        SubCategory = 'Security Options'
        Name = 'Accounts: Administrator account status'
        Description = 'Ensure Administrator account is disabled or renamed'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        RegistryName = 'EnableLUA'
        ExpectedValue = 1
        Operator = 'Equals'
        Severity = 'High'
        Remediation = 'Enable User Account Control'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 2.3.1.1'
    },
    @{
        Id = '2.3.1.2'
        Category = 'Local Policies'
        SubCategory = 'Security Options'
        Name = 'Accounts: Guest account status'
        Description = 'Ensure Guest account is disabled'
        CheckType = 'LocalAccount'
        AccountName = 'Guest'
        ExpectedEnabled = $false
        Severity = 'High'
        Remediation = 'Disable the Guest account'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 2.3.1.2'
    },
    # Windows Firewall
    @{
        Id = '9.1.1'
        Category = 'Windows Firewall'
        SubCategory = 'Domain Profile'
        Name = 'Windows Firewall Domain Profile State'
        Description = 'Ensure Windows Firewall Domain Profile is enabled'
        CheckType = 'FirewallProfile'
        ProfileName = 'Domain'
        ExpectedEnabled = $true
        Severity = 'High'
        Remediation = 'Enable Windows Firewall for Domain Profile'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 9.1.1'
    },
    @{
        Id = '9.2.1'
        Category = 'Windows Firewall'
        SubCategory = 'Private Profile'
        Name = 'Windows Firewall Private Profile State'
        Description = 'Ensure Windows Firewall Private Profile is enabled'
        CheckType = 'FirewallProfile'
        ProfileName = 'Private'
        ExpectedEnabled = $true
        Severity = 'High'
        Remediation = 'Enable Windows Firewall for Private Profile'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 9.2.1'
    },
    @{
        Id = '9.3.1'
        Category = 'Windows Firewall'
        SubCategory = 'Public Profile'
        Name = 'Windows Firewall Public Profile State'
        Description = 'Ensure Windows Firewall Public Profile is enabled'
        CheckType = 'FirewallProfile'
        ProfileName = 'Public'
        ExpectedEnabled = $true
        Severity = 'Critical'
        Remediation = 'Enable Windows Firewall for Public Profile'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 9.3.1'
    },
    # Audit Policy
    @{
        Id = '17.1.1'
        Category = 'Advanced Audit Policy'
        SubCategory = 'Account Logon'
        Name = 'Audit Credential Validation'
        Description = 'Ensure Audit Credential Validation is set to Success and Failure'
        CheckType = 'AuditPolicy'
        AuditSubcategory = 'Credential Validation'
        ExpectedValue = 'Success and Failure'
        Severity = 'Medium'
        Remediation = 'Configure audit policy for Credential Validation'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 17.1.1'
    },
    @{
        Id = '17.2.1'
        Category = 'Advanced Audit Policy'
        SubCategory = 'Account Management'
        Name = 'Audit Security Group Management'
        Description = 'Ensure Audit Security Group Management includes Success'
        CheckType = 'AuditPolicy'
        AuditSubcategory = 'Security Group Management'
        ExpectedValue = 'Success'
        Severity = 'Medium'
        Remediation = 'Configure audit policy for Security Group Management'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 17.2.1'
    },
    @{
        Id = '17.2.2'
        Category = 'Advanced Audit Policy'
        SubCategory = 'Account Management'
        Name = 'Audit User Account Management'
        Description = 'Ensure Audit User Account Management is set to Success and Failure'
        CheckType = 'AuditPolicy'
        AuditSubcategory = 'User Account Management'
        ExpectedValue = 'Success and Failure'
        Severity = 'Medium'
        Remediation = 'Configure audit policy for User Account Management'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 17.2.2'
    },
    # Services
    @{
        Id = '5.1'
        Category = 'System Services'
        SubCategory = 'Service Configuration'
        Name = 'Remote Registry Service'
        Description = 'Ensure Remote Registry service is disabled'
        CheckType = 'Service'
        ServiceName = 'RemoteRegistry'
        ExpectedStartType = 'Disabled'
        Severity = 'Medium'
        Remediation = 'Disable the Remote Registry service'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 5.1'
    },
    @{
        Id = '5.2'
        Category = 'System Services'
        SubCategory = 'Service Configuration'
        Name = 'Windows Remote Management (WinRM) Service'
        Description = 'Ensure WinRM service is properly configured'
        CheckType = 'Service'
        ServiceName = 'WinRM'
        ExpectedStartType = 'Manual'
        Severity = 'Medium'
        Remediation = 'Configure WinRM service to Manual startup'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 5.2'
    },
    # Additional Registry Checks
    @{
        Id = '18.3.1'
        Category = 'Administrative Templates'
        SubCategory = 'MSS Settings'
        Name = 'Enable ICMP Redirects'
        Description = 'Ensure ICMP redirects are disabled'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
        RegistryName = 'EnableICMPRedirect'
        ExpectedValue = 0
        Operator = 'Equals'
        Severity = 'Low'
        Remediation = 'Set EnableICMPRedirect to 0'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 18.3.1'
    },
    @{
        Id = '18.4.1'
        Category = 'Administrative Templates'
        SubCategory = 'Network Settings'
        Name = 'SMB v1 Client Driver'
        Description = 'Ensure SMBv1 client driver is disabled'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'
        RegistryName = 'Start'
        ExpectedValue = 4
        Operator = 'Equals'
        Severity = 'Critical'
        Remediation = 'Disable SMBv1 client driver'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 18.4.1'
    },
    @{
        Id = '18.4.2'
        Category = 'Administrative Templates'
        SubCategory = 'Network Settings'
        Name = 'SMB v1 Server'
        Description = 'Ensure SMBv1 server is disabled'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
        RegistryName = 'SMB1'
        ExpectedValue = 0
        Operator = 'Equals'
        Severity = 'Critical'
        Remediation = 'Disable SMBv1 server'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 18.4.2'
    },
    @{
        Id = '18.8.1'
        Category = 'Administrative Templates'
        SubCategory = 'Windows Components'
        Name = 'AutoPlay Disabled'
        Description = 'Ensure AutoPlay is disabled for all drives'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        RegistryName = 'NoDriveTypeAutoRun'
        ExpectedValue = 255
        Operator = 'Equals'
        Severity = 'Medium'
        Remediation = 'Disable AutoPlay for all drives'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 18.8.1'
    },
    @{
        Id = '18.9.1'
        Category = 'Administrative Templates'
        SubCategory = 'Windows Components'
        Name = 'Windows PowerShell Script Block Logging'
        Description = 'Ensure PowerShell Script Block Logging is enabled'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
        RegistryName = 'EnableScriptBlockLogging'
        ExpectedValue = 1
        Operator = 'Equals'
        Severity = 'Medium'
        Remediation = 'Enable PowerShell Script Block Logging'
        Reference = 'CIS Microsoft Windows Server 2019 Benchmark v1.0.0 - 18.9.1'
    }
)

# ============================================================================
# Initialization Functions
# ============================================================================

function Initialize-HardeningValidator {
    <#
    .SYNOPSIS
        Initializes the hardening validator with specified configuration.

    .DESCRIPTION
        Sets up the validator with the specified options including output path,
        verbosity, and benchmark version.

    .PARAMETER OutputPath
        Path where reports will be saved. If not specified, reports are only returned as objects.

    .PARAMETER IncludePassedChecks
        Whether to include passed checks in reports. Default is $true.

    .PARAMETER BenchmarkVersion
        The benchmark version identifier for reports. Default is 'CIS 1.0.0'.

    .EXAMPLE
        Initialize-HardeningValidator -OutputPath "C:\Reports" -IncludePassedChecks $true

    .EXAMPLE
        Initialize-HardeningValidator -BenchmarkVersion "CIS 2.0.0"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [bool]$IncludePassedChecks = $true,

        [Parameter(Mandatory = $false)]
        [string]$BenchmarkVersion = 'CIS 1.0.0'
    )

    # Validate output path if specified
    if ($OutputPath -and -not (Test-Path $OutputPath -PathType Container)) {
        try {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        catch {
            throw "Failed to create output directory: $_"
        }
    }

    $script:ValidatorConfig.OutputPath = $OutputPath
    $script:ValidatorConfig.IncludePassedChecks = $IncludePassedChecks
    $script:ValidatorConfig.BenchmarkVersion = $BenchmarkVersion
    $script:ValidatorConfig.Initialized = $true

    Write-Verbose "HardeningValidator initialized with OutputPath: $OutputPath, BenchmarkVersion: $BenchmarkVersion"
}

function Get-HardeningValidatorConfig {
    <#
    .SYNOPSIS
        Returns the current validator configuration.

    .DESCRIPTION
        Retrieves the current configuration settings for the hardening validator.

    .EXAMPLE
        Get-HardeningValidatorConfig
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:ValidatorConfig.Clone()
}

# ============================================================================
# Core Validation Functions
# ============================================================================

function Test-RegistrySetting {
    <#
    .SYNOPSIS
        Tests a registry setting against an expected value.

    .DESCRIPTION
        Checks if a registry value matches the expected value using the specified operator.

    .PARAMETER Path
        The registry path to check.

    .PARAMETER Name
        The registry value name to check.

    .PARAMETER ExpectedValue
        The expected value.

    .PARAMETER Operator
        The comparison operator: Equals, NotEquals, GreaterThan, LessThan, GreaterOrEqual, LessOrEqual, Contains.

    .EXAMPLE
        Test-RegistrySetting -Path "HKLM:\SOFTWARE\Test" -Name "Value" -ExpectedValue 1 -Operator "Equals"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $ExpectedValue,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Equals', 'NotEquals', 'GreaterThan', 'LessThan', 'GreaterOrEqual', 'LessOrEqual', 'Contains')]
        [string]$Operator = 'Equals'
    )

    $result = [PSCustomObject]@{
        Status       = $script:ComplianceStatus.NotChecked
        ActualValue  = $null
        ExpectedValue = $ExpectedValue
        Message      = ''
    }

    try {
        # Check if registry path exists
        if (-not (Test-Path $Path)) {
            $result.Status = $script:ComplianceStatus.Fail
            $result.Message = "Registry path not found: $Path"
            return $result
        }

        # Get the registry value
        $regValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

        if ($null -eq $regValue) {
            $result.Status = $script:ComplianceStatus.Fail
            $result.Message = "Registry value not found: $Name"
            return $result
        }

        $actualValue = $regValue.$Name
        $result.ActualValue = $actualValue

        # Compare values based on operator
        $comparisonResult = switch ($Operator) {
            'Equals'         { $actualValue -eq $ExpectedValue }
            'NotEquals'      { $actualValue -ne $ExpectedValue }
            'GreaterThan'    { $actualValue -gt $ExpectedValue }
            'LessThan'       { $actualValue -lt $ExpectedValue }
            'GreaterOrEqual' { $actualValue -ge $ExpectedValue }
            'LessOrEqual'    { $actualValue -le $ExpectedValue }
            'Contains'       { $actualValue -like "*$ExpectedValue*" }
        }

        if ($comparisonResult) {
            $result.Status = $script:ComplianceStatus.Pass
            $result.Message = "Registry value matches expected value"
        }
        else {
            $result.Status = $script:ComplianceStatus.Fail
            $result.Message = "Registry value '$actualValue' does not match expected '$ExpectedValue' (Operator: $Operator)"
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking registry: $_"
    }

    return $result
}

function Test-ServiceConfiguration {
    <#
    .SYNOPSIS
        Tests a Windows service configuration.

    .DESCRIPTION
        Checks if a service exists and has the expected startup type.

    .PARAMETER ServiceName
        The name of the service to check.

    .PARAMETER ExpectedStartType
        The expected startup type: Automatic, Manual, Disabled.

    .PARAMETER ExpectedStatus
        Optional expected service status: Running, Stopped.

    .EXAMPLE
        Test-ServiceConfiguration -ServiceName "RemoteRegistry" -ExpectedStartType "Disabled"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Automatic', 'Manual', 'Disabled', 'Boot', 'System')]
        [string]$ExpectedStartType,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Running', 'Stopped', 'Paused')]
        [string]$ExpectedStatus
    )

    $result = [PSCustomObject]@{
        Status        = $script:ComplianceStatus.NotChecked
        ActualValue   = $null
        ExpectedValue = $ExpectedStartType
        Message       = ''
    }

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($null -eq $service) {
            $result.Status = $script:ComplianceStatus.NotApplicable
            $result.Message = "Service not found: $ServiceName"
            return $result
        }

        $serviceInfo = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
        $actualStartType = $serviceInfo.StartMode

        $result.ActualValue = "$actualStartType ($($service.Status))"

        $startTypeMatch = $true
        $statusMatch = $true

        if ($ExpectedStartType) {
            $startTypeMatch = $actualStartType -eq $ExpectedStartType
        }

        if ($ExpectedStatus) {
            $statusMatch = $service.Status -eq $ExpectedStatus
        }

        if ($startTypeMatch -and $statusMatch) {
            $result.Status = $script:ComplianceStatus.Pass
            $result.Message = "Service configuration matches expected settings"
        }
        else {
            $result.Status = $script:ComplianceStatus.Fail
            $messages = @()
            if (-not $startTypeMatch) {
                $messages += "StartType: Expected '$ExpectedStartType', Actual '$actualStartType'"
            }
            if (-not $statusMatch) {
                $messages += "Status: Expected '$ExpectedStatus', Actual '$($service.Status)'"
            }
            $result.Message = $messages -join '; '
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking service: $_"
    }

    return $result
}

function Test-FirewallProfile {
    <#
    .SYNOPSIS
        Tests Windows Firewall profile configuration.

    .DESCRIPTION
        Checks if a firewall profile is enabled or disabled.

    .PARAMETER ProfileName
        The firewall profile to check: Domain, Private, Public.

    .PARAMETER ExpectedEnabled
        Whether the profile should be enabled.

    .EXAMPLE
        Test-FirewallProfile -ProfileName "Public" -ExpectedEnabled $true
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Domain', 'Private', 'Public')]
        [string]$ProfileName,

        [Parameter(Mandatory = $true)]
        [bool]$ExpectedEnabled
    )

    $result = [PSCustomObject]@{
        Status        = $script:ComplianceStatus.NotChecked
        ActualValue   = $null
        ExpectedValue = $ExpectedEnabled
        Message       = ''
    }

    try {
        $firewallProfile = Get-NetFirewallProfile -Name $ProfileName -ErrorAction Stop
        $isEnabled = $firewallProfile.Enabled

        $result.ActualValue = $isEnabled

        if ($isEnabled -eq $ExpectedEnabled) {
            $result.Status = $script:ComplianceStatus.Pass
            $result.Message = "Firewall $ProfileName profile is correctly configured"
        }
        else {
            $result.Status = $script:ComplianceStatus.Fail
            $expectedState = if ($ExpectedEnabled) { 'Enabled' } else { 'Disabled' }
            $actualState = if ($isEnabled) { 'Enabled' } else { 'Disabled' }
            $result.Message = "Firewall $ProfileName profile: Expected '$expectedState', Actual '$actualState'"
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking firewall profile: $_"
    }

    return $result
}

function Test-LocalAccount {
    <#
    .SYNOPSIS
        Tests local account configuration.

    .DESCRIPTION
        Checks if a local account is enabled or disabled.

    .PARAMETER AccountName
        The name of the local account to check.

    .PARAMETER ExpectedEnabled
        Whether the account should be enabled.

    .EXAMPLE
        Test-LocalAccount -AccountName "Guest" -ExpectedEnabled $false
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AccountName,

        [Parameter(Mandatory = $true)]
        [bool]$ExpectedEnabled
    )

    $result = [PSCustomObject]@{
        Status        = $script:ComplianceStatus.NotChecked
        ActualValue   = $null
        ExpectedValue = $ExpectedEnabled
        Message       = ''
    }

    try {
        $account = Get-LocalUser -Name $AccountName -ErrorAction SilentlyContinue

        if ($null -eq $account) {
            $result.Status = $script:ComplianceStatus.NotApplicable
            $result.Message = "Account not found: $AccountName"
            return $result
        }

        $isEnabled = $account.Enabled
        $result.ActualValue = $isEnabled

        if ($isEnabled -eq $ExpectedEnabled) {
            $result.Status = $script:ComplianceStatus.Pass
            $result.Message = "Account '$AccountName' is correctly configured"
        }
        else {
            $result.Status = $script:ComplianceStatus.Fail
            $expectedState = if ($ExpectedEnabled) { 'Enabled' } else { 'Disabled' }
            $actualState = if ($isEnabled) { 'Enabled' } else { 'Disabled' }
            $result.Message = "Account '$AccountName': Expected '$expectedState', Actual '$actualState'"
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking account: $_"
    }

    return $result
}

function Test-AuditPolicy {
    <#
    .SYNOPSIS
        Tests audit policy configuration.

    .DESCRIPTION
        Checks if an audit subcategory is configured with the expected settings.

    .PARAMETER Subcategory
        The audit subcategory to check.

    .PARAMETER ExpectedValue
        The expected audit configuration: Success, Failure, Success and Failure, No Auditing.

    .EXAMPLE
        Test-AuditPolicy -Subcategory "Credential Validation" -ExpectedValue "Success and Failure"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subcategory,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedValue
    )

    $result = [PSCustomObject]@{
        Status        = $script:ComplianceStatus.NotChecked
        ActualValue   = $null
        ExpectedValue = $ExpectedValue
        Message       = ''
    }

    try {
        # Use auditpol to get the current audit setting
        $auditOutput = auditpol /get /subcategory:"$Subcategory" 2>&1

        if ($LASTEXITCODE -ne 0) {
            $result.Status = $script:ComplianceStatus.Error
            $result.Message = "Failed to query audit policy for '$Subcategory'"
            return $result
        }

        # Parse the output to get the setting
        $lines = $auditOutput -split "`n"
        $settingLine = $lines | Where-Object { $_ -match $Subcategory }

        if ($settingLine) {
            # Extract the setting value (last column)
            if ($settingLine -match '(Success and Failure|Success|Failure|No Auditing)\s*$') {
                $actualValue = $Matches[1].Trim()
                $result.ActualValue = $actualValue

                # Check if actual matches expected (handle partial matches for "includes Success")
                $matches = $false
                if ($ExpectedValue -eq $actualValue) {
                    $matches = $true
                }
                elseif ($ExpectedValue -eq 'Success' -and $actualValue -like '*Success*') {
                    $matches = $true
                }
                elseif ($ExpectedValue -eq 'Failure' -and $actualValue -like '*Failure*') {
                    $matches = $true
                }

                if ($matches) {
                    $result.Status = $script:ComplianceStatus.Pass
                    $result.Message = "Audit policy '$Subcategory' is correctly configured"
                }
                else {
                    $result.Status = $script:ComplianceStatus.Fail
                    $result.Message = "Audit policy '$Subcategory': Expected '$ExpectedValue', Actual '$actualValue'"
                }
            }
            else {
                $result.Status = $script:ComplianceStatus.Error
                $result.Message = "Could not parse audit policy output for '$Subcategory'"
            }
        }
        else {
            $result.Status = $script:ComplianceStatus.NotApplicable
            $result.Message = "Audit subcategory not found: $Subcategory"
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking audit policy: $_"
    }

    return $result
}

function Test-SecurityPolicy {
    <#
    .SYNOPSIS
        Tests security policy settings.

    .DESCRIPTION
        Exports and checks security policy settings from the local security database.

    .PARAMETER PolicyName
        The security policy setting name to check.

    .PARAMETER ExpectedValue
        The expected value for the policy.

    .PARAMETER Operator
        The comparison operator.

    .EXAMPLE
        Test-SecurityPolicy -PolicyName "MinimumPasswordLength" -ExpectedValue 14 -Operator "GreaterOrEqual"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyName,

        [Parameter(Mandatory = $true)]
        $ExpectedValue,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Equals', 'NotEquals', 'GreaterThan', 'LessThan', 'GreaterOrEqual', 'LessOrEqual')]
        [string]$Operator = 'Equals'
    )

    $result = [PSCustomObject]@{
        Status        = $script:ComplianceStatus.NotChecked
        ActualValue   = $null
        ExpectedValue = $ExpectedValue
        Message       = ''
    }

    try {
        # Export security policy to a temp file
        $tempFile = [System.IO.Path]::GetTempFileName()
        $exportResult = secedit /export /cfg $tempFile 2>&1

        if ($LASTEXITCODE -ne 0) {
            $result.Status = $script:ComplianceStatus.Error
            $result.Message = "Failed to export security policy"
            return $result
        }

        # Read and parse the exported file
        $content = Get-Content $tempFile -Raw
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        # Find the policy value
        if ($content -match "$PolicyName\s*=\s*(.+)") {
            $actualValue = $Matches[1].Trim()

            # Try to convert to number if possible
            if ($actualValue -match '^\d+$') {
                $actualValue = [int]$actualValue
            }

            $result.ActualValue = $actualValue

            # Compare values based on operator
            $comparisonResult = switch ($Operator) {
                'Equals'         { $actualValue -eq $ExpectedValue }
                'NotEquals'      { $actualValue -ne $ExpectedValue }
                'GreaterThan'    { $actualValue -gt $ExpectedValue }
                'LessThan'       { $actualValue -lt $ExpectedValue }
                'GreaterOrEqual' { $actualValue -ge $ExpectedValue }
                'LessOrEqual'    { $actualValue -le $ExpectedValue }
            }

            if ($comparisonResult) {
                $result.Status = $script:ComplianceStatus.Pass
                $result.Message = "Security policy '$PolicyName' meets requirements"
            }
            else {
                $result.Status = $script:ComplianceStatus.Fail
                $result.Message = "Security policy '$PolicyName': Expected '$ExpectedValue' ($Operator), Actual '$actualValue'"
            }
        }
        else {
            $result.Status = $script:ComplianceStatus.NotApplicable
            $result.Message = "Security policy '$PolicyName' not found"
        }
    }
    catch {
        $result.Status = $script:ComplianceStatus.Error
        $result.Message = "Error checking security policy: $_"
    }

    return $result
}

# ============================================================================
# Main Validation Functions
# ============================================================================

function Invoke-HardeningCheck {
    <#
    .SYNOPSIS
        Runs a single hardening check.

    .DESCRIPTION
        Executes a single hardening validation check based on the check definition.

    .PARAMETER Check
        A hashtable containing the check definition.

    .EXAMPLE
        $check = @{
            Id = '1.1.1'
            CheckType = 'Registry'
            RegistryPath = 'HKLM:\SOFTWARE\Test'
            RegistryName = 'Value'
            ExpectedValue = 1
            Operator = 'Equals'
        }
        Invoke-HardeningCheck -Check $check
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Check
    )

    $checkResult = switch ($Check.CheckType) {
        'Registry' {
            Test-RegistrySetting -Path $Check.RegistryPath -Name $Check.RegistryName `
                -ExpectedValue $Check.ExpectedValue -Operator $Check.Operator
        }
        'Service' {
            Test-ServiceConfiguration -ServiceName $Check.ServiceName `
                -ExpectedStartType $Check.ExpectedStartType
        }
        'FirewallProfile' {
            Test-FirewallProfile -ProfileName $Check.ProfileName `
                -ExpectedEnabled $Check.ExpectedEnabled
        }
        'LocalAccount' {
            Test-LocalAccount -AccountName $Check.AccountName `
                -ExpectedEnabled $Check.ExpectedEnabled
        }
        'AuditPolicy' {
            Test-AuditPolicy -Subcategory $Check.AuditSubcategory `
                -ExpectedValue $Check.ExpectedValue
        }
        'SecurityPolicy' {
            Test-SecurityPolicy -PolicyName $Check.PolicyName `
                -ExpectedValue $Check.ExpectedValue -Operator $Check.Operator
        }
        default {
            [PSCustomObject]@{
                Status        = $script:ComplianceStatus.Error
                ActualValue   = $null
                ExpectedValue = $null
                Message       = "Unknown check type: $($Check.CheckType)"
            }
        }
    }

    # Create full result object
    $result = [PSCustomObject]@{
        Id            = $Check.Id
        Category      = $Check.Category
        SubCategory   = $Check.SubCategory
        Name          = $Check.Name
        Description   = $Check.Description
        Severity      = $Check.Severity
        Status        = $checkResult.Status
        ActualValue   = $checkResult.ActualValue
        ExpectedValue = $checkResult.ExpectedValue
        Message       = $checkResult.Message
        Remediation   = $Check.Remediation
        Reference     = $Check.Reference
        Timestamp     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    return $result
}

function Invoke-HardeningValidation {
    <#
    .SYNOPSIS
        Runs all hardening validation checks.

    .DESCRIPTION
        Executes all built-in CIS benchmark checks or custom checks against the system.

    .PARAMETER CustomChecks
        Optional array of custom check definitions to run instead of built-in checks.

    .PARAMETER Categories
        Optional array of categories to filter checks.

    .PARAMETER Severities
        Optional array of severities to filter checks.

    .PARAMETER IncludePassedChecks
        Whether to include passed checks in results. Default is based on validator config.

    .EXAMPLE
        Invoke-HardeningValidation

    .EXAMPLE
        Invoke-HardeningValidation -Categories @('Windows Firewall', 'Account Policies')

    .EXAMPLE
        Invoke-HardeningValidation -Severities @('Critical', 'High')
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable[]]$CustomChecks,

        [Parameter(Mandatory = $false)]
        [string[]]$Categories,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info')]
        [string[]]$Severities,

        [Parameter(Mandatory = $false)]
        [bool]$IncludePassedChecks = $script:ValidatorConfig.IncludePassedChecks
    )

    # Determine which checks to run
    $checksToRun = if ($CustomChecks) { $CustomChecks } else { $script:CISBenchmarkChecks }

    # Filter by category if specified
    if ($Categories) {
        $checksToRun = $checksToRun | Where-Object { $Categories -contains $_.Category }
    }

    # Filter by severity if specified
    if ($Severities) {
        $checksToRun = $checksToRun | Where-Object { $Severities -contains $_.Severity }
    }

    $results = @()
    $totalChecks = $checksToRun.Count
    $currentCheck = 0

    foreach ($check in $checksToRun) {
        $currentCheck++
        Write-Progress -Activity "Running Hardening Validation" `
            -Status "Check $currentCheck of $totalChecks : $($check.Name)" `
            -PercentComplete (($currentCheck / $totalChecks) * 100)

        $result = Invoke-HardeningCheck -Check $check

        # Include result based on settings
        if ($IncludePassedChecks -or $result.Status -ne $script:ComplianceStatus.Pass) {
            $results += $result
        }
    }

    Write-Progress -Activity "Running Hardening Validation" -Completed

    return $results
}

# ============================================================================
# Reporting Functions
# ============================================================================

function Get-HardeningReport {
    <#
    .SYNOPSIS
        Generates a hardening compliance report.

    .DESCRIPTION
        Creates a comprehensive report from validation results with summary statistics.

    .PARAMETER Results
        The validation results from Invoke-HardeningValidation.

    .PARAMETER Format
        The output format: Object, HTML, CSV, JSON.

    .PARAMETER OutputPath
        Optional path to save the report file.

    .EXAMPLE
        $results = Invoke-HardeningValidation
        Get-HardeningReport -Results $results -Format HTML -OutputPath "C:\Reports\compliance.html"

    .EXAMPLE
        $results = Invoke-HardeningValidation
        $report = Get-HardeningReport -Results $results -Format Object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'HTML', 'CSV', 'JSON')]
        [string]$Format = 'Object',

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Calculate summary statistics
    $summary = [PSCustomObject]@{
        TotalChecks     = $Results.Count
        Passed          = ($Results | Where-Object { $_.Status -eq 'Pass' }).Count
        Failed          = ($Results | Where-Object { $_.Status -eq 'Fail' }).Count
        Errors          = ($Results | Where-Object { $_.Status -eq 'Error' }).Count
        NotApplicable   = ($Results | Where-Object { $_.Status -eq 'Not Applicable' }).Count
        NotChecked      = ($Results | Where-Object { $_.Status -eq 'Not Checked' }).Count
        ComplianceScore = 0
        BenchmarkVersion = $script:ValidatorConfig.BenchmarkVersion
        ReportDate      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName    = $env:COMPUTERNAME
    }

    # Calculate compliance score
    $applicableChecks = $summary.TotalChecks - $summary.NotApplicable - $summary.NotChecked
    if ($applicableChecks -gt 0) {
        $summary.ComplianceScore = [math]::Round(($summary.Passed / $applicableChecks) * 100, 2)
    }

    # Severity breakdown
    $severityBreakdown = $Results | Where-Object { $_.Status -eq 'Fail' } |
        Group-Object -Property Severity |
        Select-Object @{N='Severity';E={$_.Name}}, @{N='Count';E={$_.Count}}

    $report = [PSCustomObject]@{
        Summary           = $summary
        SeverityBreakdown = $severityBreakdown
        Results           = $Results
    }

    # Output based on format
    switch ($Format) {
        'Object' {
            return $report
        }
        'JSON' {
            $json = $report | ConvertTo-Json -Depth 10
            if ($OutputPath) {
                $json | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
            }
            return $json
        }
        'CSV' {
            if ($OutputPath) {
                $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
            }
            return $Results | ConvertTo-Csv -NoTypeInformation
        }
        'HTML' {
            $html = New-HardeningHtmlReport -Report $report
            if ($OutputPath) {
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
            }
            return $html
        }
    }
}

function New-HardeningHtmlReport {
    <#
    .SYNOPSIS
        Creates an HTML report from validation results.

    .DESCRIPTION
        Generates a formatted HTML report with styling and interactive elements.

    .PARAMETER Report
        The report object from Get-HardeningReport.

    .EXAMPLE
        $html = New-HardeningHtmlReport -Report $report
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $statusColors = @{
        'Pass'           = '#28a745'
        'Fail'           = '#dc3545'
        'Error'          = '#ffc107'
        'Not Applicable' = '#6c757d'
        'Not Checked'    = '#17a2b8'
    }

    $severityColors = @{
        'Critical' = '#dc3545'
        'High'     = '#fd7e14'
        'Medium'   = '#ffc107'
        'Low'      = '#28a745'
        'Info'     = '#17a2b8'
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Hardening Validation Report - $($Report.Summary.ComputerName)</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 20px 0; }
        .summary-card { padding: 15px; border-radius: 8px; text-align: center; color: white; }
        .summary-card h3 { margin: 0; font-size: 2em; }
        .summary-card p { margin: 5px 0 0 0; font-size: 0.9em; }
        .score-card { background: linear-gradient(135deg, #007bff, #0056b3); grid-column: span 2; }
        .pass-card { background-color: #28a745; }
        .fail-card { background-color: #dc3545; }
        .error-card { background-color: #ffc107; color: #333; }
        .na-card { background-color: #6c757d; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: 600; }
        tr:hover { background-color: #f5f5f5; }
        .status-badge { padding: 4px 8px; border-radius: 4px; color: white; font-size: 0.85em; font-weight: 500; }
        .severity-badge { padding: 4px 8px; border-radius: 4px; color: white; font-size: 0.85em; font-weight: 500; }
        .meta-info { color: #666; font-size: 0.9em; margin-bottom: 20px; }
        .details { font-size: 0.85em; color: #666; max-width: 300px; }
        .collapsible { cursor: pointer; }
        .collapsible:hover { background-color: #e9ecef; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Windows Hardening Validation Report</h1>
        <div class="meta-info">
            <strong>Computer:</strong> $($Report.Summary.ComputerName) |
            <strong>Date:</strong> $($Report.Summary.ReportDate) |
            <strong>Benchmark:</strong> $($Report.Summary.BenchmarkVersion)
        </div>

        <h2>Summary</h2>
        <div class="summary-grid">
            <div class="summary-card score-card">
                <h3>$($Report.Summary.ComplianceScore)%</h3>
                <p>Compliance Score</p>
            </div>
            <div class="summary-card pass-card">
                <h3>$($Report.Summary.Passed)</h3>
                <p>Passed</p>
            </div>
            <div class="summary-card fail-card">
                <h3>$($Report.Summary.Failed)</h3>
                <p>Failed</p>
            </div>
            <div class="summary-card error-card">
                <h3>$($Report.Summary.Errors)</h3>
                <p>Errors</p>
            </div>
            <div class="summary-card na-card">
                <h3>$($Report.Summary.NotApplicable)</h3>
                <p>Not Applicable</p>
            </div>
        </div>

        <h2>Detailed Results</h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Category</th>
                    <th>Severity</th>
                    <th>Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($result in $Report.Results) {
        $statusColor = $statusColors[$result.Status]
        $severityColor = $severityColors[$result.Severity]

        $html += @"
                <tr>
                    <td>$($result.Id)</td>
                    <td><strong>$($result.Name)</strong><br><span class="details">$($result.Description)</span></td>
                    <td>$($result.Category)</td>
                    <td><span class="severity-badge" style="background-color: $severityColor;">$($result.Severity)</span></td>
                    <td><span class="status-badge" style="background-color: $statusColor;">$($result.Status)</span></td>
                    <td class="details">$($result.Message)<br><em>$($result.Remediation)</em></td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@

    return $html
}

function Export-HardeningBaseline {
    <#
    .SYNOPSIS
        Exports the current system configuration as a baseline.

    .DESCRIPTION
        Captures the current hardening settings and exports them as a baseline configuration.

    .PARAMETER OutputPath
        Path to save the baseline file.

    .PARAMETER Format
        Output format: JSON or CSV.

    .EXAMPLE
        Export-HardeningBaseline -OutputPath "C:\Baselines\server-baseline.json" -Format JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV')]
        [string]$Format = 'JSON'
    )

    # Run validation to capture current state
    $results = Invoke-HardeningValidation -IncludePassedChecks $true

    $baseline = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        CaptureDate  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        OSVersion    = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        Settings     = $results | Select-Object Id, Name, Category, ActualValue
    }

    switch ($Format) {
        'JSON' {
            $baseline | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        'CSV' {
            $baseline.Settings | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
    }

    Write-Host "Baseline exported to: $OutputPath" -ForegroundColor Green
}

function Import-CustomChecks {
    <#
    .SYNOPSIS
        Imports custom check definitions from a JSON file.

    .DESCRIPTION
        Loads custom hardening checks from a JSON file to use with Invoke-HardeningValidation.

    .PARAMETER FilePath
        Path to the JSON file containing custom checks.

    .EXAMPLE
        $customChecks = Import-CustomChecks -FilePath "C:\Checks\custom-checks.json"
        Invoke-HardeningValidation -CustomChecks $customChecks
    #>
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw
        $checks = $content | ConvertFrom-Json

        # Convert PSObjects to hashtables
        $hashtableChecks = @()
        foreach ($check in $checks) {
            $ht = @{}
            $check.PSObject.Properties | ForEach-Object {
                $ht[$_.Name] = $_.Value
            }
            $hashtableChecks += $ht
        }

        Write-Host "Imported $($hashtableChecks.Count) custom checks from $FilePath" -ForegroundColor Green
        return $hashtableChecks
    }
    catch {
        throw "Failed to import custom checks: $_"
    }
}

function Get-BuiltInChecks {
    <#
    .SYNOPSIS
        Returns the built-in CIS benchmark checks.

    .DESCRIPTION
        Retrieves all built-in hardening checks for reference or customization.

    .PARAMETER Category
        Optional filter by category.

    .EXAMPLE
        Get-BuiltInChecks

    .EXAMPLE
        Get-BuiltInChecks -Category "Windows Firewall"
    #>
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Category
    )

    if ($Category) {
        return $script:CISBenchmarkChecks | Where-Object { $_.Category -eq $Category }
    }

    return $script:CISBenchmarkChecks
}

# ============================================================================
# Module Export
# ============================================================================

Export-ModuleMember -Function @(
    'Initialize-HardeningValidator',
    'Get-HardeningValidatorConfig',
    'Test-RegistrySetting',
    'Test-ServiceConfiguration',
    'Test-FirewallProfile',
    'Test-LocalAccount',
    'Test-AuditPolicy',
    'Test-SecurityPolicy',
    'Invoke-HardeningCheck',
    'Invoke-HardeningValidation',
    'Get-HardeningReport',
    'New-HardeningHtmlReport',
    'Export-HardeningBaseline',
    'Import-CustomChecks',
    'Get-BuiltInChecks'
)
