<#
.SYNOPSIS
    Example usage of the HardeningValidator module.

.DESCRIPTION
    This script demonstrates various ways to use the HardeningValidator module
    for validating Windows OS hardening settings against CIS Benchmarks.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
    - Administrator privileges (required for most checks)
    - Run this script from an elevated PowerShell session
#>

#Requires -Version 5.0

# Import the module
Import-Module "$PSScriptRoot\..\Modules\HardeningValidator.psm1" -Force

Write-Host "HardeningValidator Module Examples" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "`n"

# ============================================================================
# Example 1: Basic Hardening Validation
# ============================================================================

Write-Host "Example 1: Basic Hardening Validation" -ForegroundColor Yellow
Write-Host "--------------------------------------"

# Run all built-in CIS benchmark checks
Write-Host "Running full hardening validation..." -ForegroundColor Gray
$results = Invoke-HardeningValidation

# Display summary
$passed = ($results | Where-Object { $_.Status -eq 'Pass' }).Count
$failed = ($results | Where-Object { $_.Status -eq 'Fail' }).Count
$total = $results.Count

Write-Host "`nValidation Complete:" -ForegroundColor Green
Write-Host "  Total Checks: $total"
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor Red

Write-Host "`n"

# ============================================================================
# Example 2: Filter Checks by Category
# ============================================================================

Write-Host "Example 2: Filter Checks by Category" -ForegroundColor Yellow
Write-Host "-------------------------------------"

# Run only Windows Firewall checks
Write-Host "Running Windows Firewall checks only..." -ForegroundColor Gray
$firewallResults = Invoke-HardeningValidation -Categories @('Windows Firewall')

foreach ($result in $firewallResults) {
    $color = if ($result.Status -eq 'Pass') { 'Green' } else { 'Red' }
    Write-Host "  [$($result.Status)] $($result.Name)" -ForegroundColor $color
}

Write-Host "`n"

# ============================================================================
# Example 3: Filter by Severity
# ============================================================================

Write-Host "Example 3: Filter by Severity (Critical and High only)" -ForegroundColor Yellow
Write-Host "-------------------------------------------------------"

# Run only critical and high severity checks
Write-Host "Running critical and high severity checks..." -ForegroundColor Gray
$criticalResults = Invoke-HardeningValidation -Severities @('Critical', 'High')

foreach ($result in $criticalResults) {
    $statusColor = if ($result.Status -eq 'Pass') { 'Green' } elseif ($result.Status -eq 'Fail') { 'Red' } else { 'Yellow' }
    Write-Host "  [$($result.Severity)] $($result.Name): $($result.Status)" -ForegroundColor $statusColor
}

Write-Host "`n"

# ============================================================================
# Example 4: Generate HTML Report
# ============================================================================

Write-Host "Example 4: Generate HTML Report" -ForegroundColor Yellow
Write-Host "--------------------------------"

# Initialize validator with output path
$reportPath = "$env:TEMP\HardeningReport"
if (-not (Test-Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

Initialize-HardeningValidator -OutputPath $reportPath -BenchmarkVersion "CIS Windows Server 2019 v1.0.0"

# Run validation and generate report
$results = Invoke-HardeningValidation
$htmlPath = Join-Path $reportPath "compliance-report.html"
$report = Get-HardeningReport -Results $results -Format HTML -OutputPath $htmlPath

Write-Host "HTML report generated at: $htmlPath" -ForegroundColor Green
Write-Host "Compliance Score: $($report.Summary.ComplianceScore)%" -ForegroundColor Cyan

Write-Host "`n"

# ============================================================================
# Example 5: Generate JSON Report
# ============================================================================

Write-Host "Example 5: Generate JSON Report" -ForegroundColor Yellow
Write-Host "--------------------------------"

$jsonPath = Join-Path $reportPath "compliance-report.json"
$jsonReport = Get-HardeningReport -Results $results -Format JSON -OutputPath $jsonPath

Write-Host "JSON report generated at: $jsonPath" -ForegroundColor Green

Write-Host "`n"

# ============================================================================
# Example 6: Generate CSV Report
# ============================================================================

Write-Host "Example 6: Generate CSV Report" -ForegroundColor Yellow
Write-Host "-------------------------------"

$csvPath = Join-Path $reportPath "compliance-report.csv"
$csvReport = Get-HardeningReport -Results $results -Format CSV -OutputPath $csvPath

Write-Host "CSV report generated at: $csvPath" -ForegroundColor Green

Write-Host "`n"

# ============================================================================
# Example 7: Individual Check Tests
# ============================================================================

Write-Host "Example 7: Individual Check Tests" -ForegroundColor Yellow
Write-Host "----------------------------------"

# Test a specific registry setting
Write-Host "`nTesting UAC setting (registry):" -ForegroundColor Gray
$uacResult = Test-RegistrySetting -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "EnableLUA" -ExpectedValue 1 -Operator "Equals"
Write-Host "  Status: $($uacResult.Status)" -ForegroundColor $(if ($uacResult.Status -eq 'Pass') { 'Green' } else { 'Red' })
Write-Host "  Actual Value: $($uacResult.ActualValue)"
Write-Host "  Message: $($uacResult.Message)"

# Test Windows Firewall
Write-Host "`nTesting Windows Firewall (Public profile):" -ForegroundColor Gray
$fwResult = Test-FirewallProfile -ProfileName "Public" -ExpectedEnabled $true
Write-Host "  Status: $($fwResult.Status)" -ForegroundColor $(if ($fwResult.Status -eq 'Pass') { 'Green' } else { 'Red' })
Write-Host "  Actual Value: $($fwResult.ActualValue)"
Write-Host "  Message: $($fwResult.Message)"

# Test a service
Write-Host "`nTesting Remote Registry service:" -ForegroundColor Gray
$svcResult = Test-ServiceConfiguration -ServiceName "RemoteRegistry" -ExpectedStartType "Disabled"
Write-Host "  Status: $($svcResult.Status)" -ForegroundColor $(if ($svcResult.Status -eq 'Pass') { 'Green' } else { 'Red' })
Write-Host "  Actual Value: $($svcResult.ActualValue)"
Write-Host "  Message: $($svcResult.Message)"

# Test local account
Write-Host "`nTesting Guest account status:" -ForegroundColor Gray
$acctResult = Test-LocalAccount -AccountName "Guest" -ExpectedEnabled $false
Write-Host "  Status: $($acctResult.Status)" -ForegroundColor $(if ($acctResult.Status -eq 'Pass') { 'Green' } else { 'Red' })
Write-Host "  Actual Value: $($acctResult.ActualValue)"
Write-Host "  Message: $($acctResult.Message)"

Write-Host "`n"

# ============================================================================
# Example 8: Custom Check Definition
# ============================================================================

Write-Host "Example 8: Custom Check Definition" -ForegroundColor Yellow
Write-Host "-----------------------------------"

# Define custom checks
$customChecks = @(
    @{
        Id = 'CUSTOM-001'
        Category = 'Custom Checks'
        SubCategory = 'Organization Policy'
        Name = 'Check PowerShell Execution Policy Registry'
        Description = 'Verify PowerShell execution policy is configured'
        CheckType = 'Registry'
        RegistryPath = 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
        RegistryName = 'ExecutionPolicy'
        ExpectedValue = 'RemoteSigned'
        Operator = 'Equals'
        Severity = 'Medium'
        Remediation = 'Set PowerShell execution policy to RemoteSigned'
        Reference = 'Organization Security Policy'
    },
    @{
        Id = 'CUSTOM-002'
        Category = 'Custom Checks'
        SubCategory = 'Network Security'
        Name = 'Windows Update Service'
        Description = 'Ensure Windows Update service is running'
        CheckType = 'Service'
        ServiceName = 'wuauserv'
        ExpectedStartType = 'Manual'
        Severity = 'High'
        Remediation = 'Configure Windows Update service'
        Reference = 'Organization Security Policy'
    }
)

Write-Host "Running custom checks..." -ForegroundColor Gray
$customResults = Invoke-HardeningValidation -CustomChecks $customChecks

foreach ($result in $customResults) {
    $color = if ($result.Status -eq 'Pass') { 'Green' } elseif ($result.Status -eq 'Fail') { 'Red' } else { 'Yellow' }
    Write-Host "  [$($result.Id)] $($result.Name): $($result.Status)" -ForegroundColor $color
}

Write-Host "`n"

# ============================================================================
# Example 9: Export Baseline Configuration
# ============================================================================

Write-Host "Example 9: Export Baseline Configuration" -ForegroundColor Yellow
Write-Host "-----------------------------------------"

$baselinePath = Join-Path $reportPath "system-baseline.json"
Export-HardeningBaseline -OutputPath $baselinePath -Format JSON

Write-Host "`n"

# ============================================================================
# Example 10: List Built-in Checks
# ============================================================================

Write-Host "Example 10: List Built-in Checks" -ForegroundColor Yellow
Write-Host "---------------------------------"

# Get all built-in checks
$allChecks = Get-BuiltInChecks
Write-Host "Total built-in checks: $($allChecks.Count)" -ForegroundColor Cyan

# Group by category
$categories = $allChecks | Group-Object -Property Category
Write-Host "`nChecks by category:" -ForegroundColor Gray
foreach ($cat in $categories) {
    Write-Host "  $($cat.Name): $($cat.Count) checks"
}

# Get checks for specific category
Write-Host "`nWindows Firewall checks:" -ForegroundColor Gray
$fwChecks = Get-BuiltInChecks -Category "Windows Firewall"
foreach ($check in $fwChecks) {
    Write-Host "  - $($check.Id): $($check.Name)"
}

Write-Host "`n"

# ============================================================================
# Example 11: Failed Checks Only Report
# ============================================================================

Write-Host "Example 11: Failed Checks Only Report" -ForegroundColor Yellow
Write-Host "--------------------------------------"

# Run validation excluding passed checks
$failedOnly = Invoke-HardeningValidation -IncludePassedChecks $false

if ($failedOnly.Count -eq 0) {
    Write-Host "No failed checks found - system is fully compliant!" -ForegroundColor Green
}
else {
    Write-Host "Failed checks that need remediation:" -ForegroundColor Red
    foreach ($result in $failedOnly) {
        if ($result.Status -eq 'Fail') {
            Write-Host "`n  [$($result.Id)] $($result.Name)" -ForegroundColor Red
            Write-Host "    Severity: $($result.Severity)"
            Write-Host "    Message: $($result.Message)"
            Write-Host "    Remediation: $($result.Remediation)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n"

# ============================================================================
# Example 12: Report Object Analysis
# ============================================================================

Write-Host "Example 12: Report Object Analysis" -ForegroundColor Yellow
Write-Host "-----------------------------------"

$results = Invoke-HardeningValidation
$report = Get-HardeningReport -Results $results -Format Object

Write-Host "Report Summary:" -ForegroundColor Cyan
Write-Host "  Computer: $($report.Summary.ComputerName)"
Write-Host "  Report Date: $($report.Summary.ReportDate)"
Write-Host "  Benchmark: $($report.Summary.BenchmarkVersion)"
Write-Host "  Compliance Score: $($report.Summary.ComplianceScore)%"
Write-Host "`nStatistics:"
Write-Host "  Total Checks: $($report.Summary.TotalChecks)"
Write-Host "  Passed: $($report.Summary.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($report.Summary.Failed)" -ForegroundColor Red
Write-Host "  Errors: $($report.Summary.Errors)" -ForegroundColor Yellow
Write-Host "  Not Applicable: $($report.Summary.NotApplicable)" -ForegroundColor Gray

if ($report.SeverityBreakdown) {
    Write-Host "`nFailures by Severity:" -ForegroundColor Cyan
    foreach ($severity in $report.SeverityBreakdown) {
        Write-Host "  $($severity.Severity): $($severity.Count)"
    }
}

Write-Host "`n"

# ============================================================================
# Summary
# ============================================================================

Write-Host "Examples Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "`nReports saved to: $reportPath"
Write-Host "  - compliance-report.html"
Write-Host "  - compliance-report.json"
Write-Host "  - compliance-report.csv"
Write-Host "  - system-baseline.json"
Write-Host "`nFor production use, run this script as Administrator for accurate results."
Write-Host "Some checks require elevated privileges to access security policies and audit settings."
