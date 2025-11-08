# Testing Guide for AnswerFileReader Module

## Manual Testing Instructions

Since this module is designed for PowerShell 5+, testing should be performed in a Windows environment or on a system with PowerShell Core installed.

## Quick Test

Run the example script to test all functionality:

```powershell
cd powershellapps
.\Examples\Use-AnswerFileReader.ps1
```

This will test:
- Reading INI files (with sections)
- Reading JSON files
- Reading XML files
- Reading simple key-value files
- Getting specific values
- Testing for key existence
- Using default values

## Unit Testing Checklist

### Test 1: Read INI File
```powershell
Import-Module ".\Modules\AnswerFileReader.psm1"
$config = Read-AnswerFile -FilePath ".\Examples\sample-config.ini"

# Verify structure
$config.Database.ServerName -eq "sql-server-01"
$config.Application.AppName -eq "MyApplication"
```

### Test 2: Read Specific Section
```powershell
$dbConfig = Read-AnswerFile -FilePath ".\Examples\sample-config.ini" -DefaultSection "Database"

# Verify only Database section is returned
$dbConfig.ServerName -eq "sql-server-01"
$dbConfig.ContainsKey("AppName") -eq $false
```

### Test 3: Get Specific Value
```powershell
$value = Get-AnswerFileValue -FilePath ".\Examples\sample-config.ini" -Key "Database.ServerName"

# Verify value
$value -eq "sql-server-01"
```

### Test 4: Default Values
```powershell
$value = Get-AnswerFileValue -FilePath ".\Examples\sample-config.ini" -Key "NonExistent.Key" -DefaultValue "Default"

# Verify default is returned
$value -eq "Default"
```

### Test 5: Test Key Existence
```powershell
$exists = Test-AnswerFileKey -FilePath ".\Examples\sample-config.ini" -Key "Database.ServerName"
$notExists = Test-AnswerFileKey -FilePath ".\Examples\sample-config.ini" -Key "Fake.Key"

# Verify results
$exists -eq $true
$notExists -eq $false
```

### Test 6: JSON File
```powershell
$config = Read-AnswerFile -FilePath ".\Examples\sample-config.json"

# Verify nested values
$config.Database.ServerName -eq "sql-server-01"
$config.Database.Port -eq 1433
```

### Test 7: XML File
```powershell
$config = Read-AnswerFile -FilePath ".\Examples\sample-config.xml"

# Verify values
$config.Database.ServerName -eq "sql-server-01"
```

### Test 8: Key-Value File
```powershell
$config = Read-AnswerFile -FilePath ".\Examples\sample-config.txt"

# Verify values
$config.ServerName -eq "web-server-01"
$config.Port -eq "80"
```

## Automated Test Script

Create a test script to validate all functionality:

```powershell
# Test-AnswerFileReader.ps1
Import-Module ".\Modules\AnswerFileReader.psm1" -Force

$testsPassed = 0
$testsFailed = 0

function Test-Condition {
    param([bool]$Condition, [string]$TestName)
    if ($Condition) {
        Write-Host "[PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host "Running AnswerFileReader Tests..." -ForegroundColor Cyan
Write-Host ""

# Test INI file reading
$config = Read-AnswerFile -FilePath ".\Examples\sample-config.ini"
Test-Condition ($config.Database.ServerName -eq "sql-server-01") "INI: Read nested value"
Test-Condition ($config.Database.Port -eq "1433") "INI: Read port value"

# Test specific section
$dbConfig = Read-AnswerFile -FilePath ".\Examples\sample-config.ini" -DefaultSection "Database"
Test-Condition ($dbConfig.ServerName -eq "sql-server-01") "INI: Read specific section"
Test-Condition (-not $dbConfig.ContainsKey("AppName")) "INI: Section isolation"

# Test Get-AnswerFileValue
$value = Get-AnswerFileValue -FilePath ".\Examples\sample-config.ini" -Key "Database.ServerName"
Test-Condition ($value -eq "sql-server-01") "Get value by key"

$value = Get-AnswerFileValue -FilePath ".\Examples\sample-config.ini" -Key "Fake.Key" -DefaultValue "Default"
Test-Condition ($value -eq "Default") "Default value handling"

# Test key existence
$exists = Test-AnswerFileKey -FilePath ".\Examples\sample-config.ini" -Key "Database.ServerName"
Test-Condition ($exists -eq $true) "Test existing key"

$exists = Test-AnswerFileKey -FilePath ".\Examples\sample-config.ini" -Key "Fake.Key"
Test-Condition ($exists -eq $false) "Test non-existent key"

# Test JSON
$jsonConfig = Read-AnswerFile -FilePath ".\Examples\sample-config.json"
Test-Condition ($jsonConfig.Database.ServerName -eq "sql-server-01") "JSON: Read nested value"
Test-Condition ($jsonConfig.Database.Port -eq 1433) "JSON: Read numeric value"

# Test XML
$xmlConfig = Read-AnswerFile -FilePath ".\Examples\sample-config.xml"
Test-Condition ($xmlConfig.Database.ServerName -eq "sql-server-01") "XML: Read nested value"

# Test key-value
$txtConfig = Read-AnswerFile -FilePath ".\Examples\sample-config.txt"
Test-Condition ($txtConfig.ServerName -eq "web-server-01") "Key-Value: Read value"
Test-Condition ($txtConfig.Port -eq "80") "Key-Value: Read port"

Write-Host ""
Write-Host "Test Results:" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
    exit 1
}
```

## Expected Output

When running `Use-AnswerFileReader.ps1`, you should see output demonstrating:
1. Successful reading of all file formats
2. Correct parsing of nested values
3. Proper section handling for INI files
4. Working key existence checks
5. Default value functionality

## Compatibility Verification

The module has been designed for PowerShell 5.0+ with the following considerations:
- No use of PowerShell 6+ specific features
- Compatible cmdlets and syntax
- Standard .NET Framework classes
- No dependencies on external modules

## Error Handling Tests

Test error scenarios:
```powershell
# Non-existent file
$config = Read-AnswerFile -FilePath ".\non-existent.ini"  # Should return null with error

# Invalid JSON
# Create a file with invalid JSON and test
```

## Performance Testing

For large files, verify performance:
```powershell
Measure-Command { Read-AnswerFile -FilePath ".\large-config.ini" }
```
