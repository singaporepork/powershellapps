# Text to JSON Conversion Guide

## Overview

The TextToJson module provides comprehensive tools for converting various text formats to JSON. This guide covers common scenarios and best practices.

## Supported Input Formats

### 1. CSV (Comma-Separated Values)
- Standard CSV with headers
- Custom delimiters (tabs, semicolons, etc.)
- CSV without headers (auto-generates column names)

### 2. Key-Value Pairs
- Simple key=value format
- Colon separator (key:value)
- Nested keys (parent.child=value)
- Type conversion (numbers, booleans)

### 3. INI Files
- Sectioned configuration files
- Standard [Section] format
- Comments (# and ;)

### 4. Delimited Text
- Custom delimiters (pipe, space, etc.)
- Regex-based delimiters
- Custom headers

### 5. XML
- Hierarchical XML documents
- Attributes and elements
- Nested structures

### 6. PowerShell Objects
- Hashtables
- PSCustomObjects
- Arrays and nested objects

## Quick Reference

### CSV to JSON
```powershell
# From file
$json = ConvertTo-JsonFromCsv -FilePath "data.csv" -Pretty

# From text
$csvText = "Name,Age`nJohn,30`nJane,25"
$json = ConvertTo-JsonFromCsv -CsvText $csvText -Pretty

# Tab-delimited
$json = ConvertTo-JsonFromCsv -FilePath "data.tsv" -Delimiter "`t" -Pretty
```

### Key-Value to JSON
```powershell
# Simple key-value
$json = ConvertTo-JsonFromKeyValue -FilePath "config.txt" -Pretty

# Nested keys
$text = "user.name=John`nuser.age=30"
$json = ConvertTo-JsonFromKeyValue -Text $text -NestedSeparator '.' -Pretty
```

### INI to JSON
```powershell
$json = ConvertTo-JsonFromIni -FilePath "app.ini" -Pretty
```

### Delimited Text to JSON
```powershell
# Pipe-delimited with headers
$headers = @('ID', 'Name', 'Status')
$json = ConvertTo-JsonFromDelimitedText -FilePath "data.txt" -Delimiter '|' -Headers $headers -Pretty

# Space-delimited
$json = ConvertTo-JsonFromDelimitedText -FilePath "data.txt" -Delimiter '\s+' -Headers $headers -Pretty
```

### XML to JSON
```powershell
$json = ConvertTo-JsonFromXml -FilePath "data.xml" -Pretty
```

### Object to JSON
```powershell
$data = @{ Name = "John"; Age = 30 }
$json = ConvertTo-JsonFromObject -InputObject $data -Pretty
```

## Common Scenarios

### Scenario 1: Migrate INI Configuration to JSON

```powershell
# Old config.ini file
$iniPath = "C:\old-config.ini"
$jsonPath = "C:\new-config.json"

$json = ConvertTo-JsonFromIni -FilePath $iniPath -Pretty
$json | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Host "Configuration migrated to JSON"
```

### Scenario 2: Convert CSV Data Export to JSON API Format

```powershell
# Export from database as CSV, convert to JSON for API
$csvPath = "C:\exports\customers.csv"
$json = ConvertTo-JsonFromCsv -FilePath $csvPath -Pretty

# Post to API
$headers = @{ 'Content-Type' = 'application/json' }
Invoke-RestMethod -Uri "https://api.example.com/import" -Method POST -Body $json -Headers $headers
```

### Scenario 3: Build JSON from PowerShell Data

```powershell
# Collect system info and export as JSON
$systemInfo = @{
    ComputerName = $env:COMPUTERNAME
    OSVersion = [System.Environment]::OSVersion.VersionString
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Disks = Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
}

$json = ConvertTo-JsonFromObject -InputObject $systemInfo -Pretty
Export-ToJsonFile -InputObject $systemInfo -FilePath "C:\reports\system-info.json" -Pretty -Force
```

### Scenario 4: Format and Validate JSON

```powershell
# Receive minified JSON from API
$minifiedJson = Invoke-RestMethod -Uri "https://api.example.com/data"

# Validate
if (Test-JsonText -Json $minifiedJson) {
    # Format for readability
    $formatted = Format-JsonText -Json $minifiedJson
    $formatted | Out-File "C:\data\formatted-response.json"
}
```

### Scenario 5: Batch Convert Multiple Files

```powershell
# Convert all INI files in a directory to JSON
$iniFiles = Get-ChildItem -Path "C:\configs" -Filter "*.ini"

foreach ($file in $iniFiles) {
    $outputPath = $file.FullName -replace '\.ini$', '.json'
    $json = ConvertTo-JsonFromIni -FilePath $file.FullName -Pretty
    $json | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Host "Converted: $($file.Name) -> $([System.IO.Path]::GetFileName($outputPath))"
}
```

## Type Conversion

The module automatically converts values to appropriate types:

- **Numbers**: "123" → 123, "45.67" → 45.67
- **Booleans**: "true" → true, "false" → false
- **Strings**: Everything else remains as strings

Example:
```
Input:  age=30, price=19.99, active=true, name=John
Output: {"age": 30, "price": 19.99, "active": true, "name": "John"}
```

## Nested Structures

### Nested Key-Value
```powershell
$text = @"
user.name=John
user.age=30
user.address.city=NYC
user.address.zip=10001
"@

$json = ConvertTo-JsonFromKeyValue -Text $text -NestedSeparator '.' -Pretty
```

Output:
```json
{
  "user": {
    "name": "John",
    "age": 30,
    "address": {
      "city": "NYC",
      "zip": 10001
    }
  }
}
```

### INI Sections
```ini
[database]
server=localhost
port=1433

[app]
name=MyApp
version=1.0
```

Output:
```json
{
  "database": {
    "server": "localhost",
    "port": 1433
  },
  "app": {
    "name": "MyApp",
    "version": "1.0"
  }
}
```

## Best Practices

1. **Use -Pretty for Human-Readable Output**
   - Always use `-Pretty` when creating files for manual editing
   - Omit `-Pretty` for API payloads to reduce size

2. **Validate Before Using**
   ```powershell
   if (Test-JsonText -Json $json) {
       # Safe to use
   }
   ```

3. **Handle Encoding Properly**
   ```powershell
   $json | Out-File -FilePath "output.json" -Encoding UTF8
   ```

4. **Preserve Data Types**
   - The module attempts automatic type conversion
   - Review output to ensure types are correct
   - Manually convert if needed

5. **Use Appropriate Depth**
   ```powershell
   $json = ConvertTo-JsonFromObject -InputObject $data -Depth 20 -Pretty
   ```

## Troubleshooting

### Issue: Numbers Converted to Strings
**Solution**: The input likely has quotes around numbers. Remove quotes in source data.

### Issue: Nested Structure Not Created
**Solution**: Ensure you're using the correct `-NestedSeparator` parameter.

### Issue: Special Characters Corrupted
**Solution**: Always use UTF8 encoding when reading/writing files.

### Issue: Large Files Fail to Convert
**Solution**: Process files in chunks or increase available memory.

## Performance Tips

1. **CSV Files**: Use `-Delimiter` parameter for faster parsing
2. **Large Files**: Consider streaming or chunking
3. **Batch Operations**: Process files in parallel using `ForEach-Object -Parallel` (PowerShell 7+)
4. **Compressed Output**: Use `-Compress` for smallest file size

## Integration Examples

### With AnswerFileReader Module
```powershell
# Read config, modify, export as JSON
Import-Module .\Modules\AnswerFileReader.psm1
Import-Module .\Modules\TextToJson.psm1

$config = Read-AnswerFile -FilePath "config.ini"
$config.Database.Server = "new-server.example.com"

Export-ToJsonFile -InputObject $config -FilePath "updated-config.json" -Pretty -Force
```

### With RestApiAuth Module
```powershell
# Convert CSV data and post to API
Import-Module .\Modules\TextToJson.psm1
Import-Module .\Modules\RestApiAuth.psm1

$json = ConvertTo-JsonFromCsv -FilePath "data.csv" -Compress

$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Bearer -Token $token
$response = Invoke-RestApiRequest -Session $session -Endpoint "/data/import" -Method POST -Body $json
```

## Additional Resources

- PowerShell JSON documentation: `Get-Help ConvertTo-Json -Full`
- JSON specification: https://www.json.org/
- Online JSON validators: https://jsonlint.com/
