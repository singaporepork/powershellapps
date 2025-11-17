<#
.SYNOPSIS
    Example: Converting various text formats to JSON

.DESCRIPTION
    Demonstrates how to use the TextToJson module to convert different text formats to JSON.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\TextToJson.psm1"
Import-Module $modulePath -Force

Write-Host "=== Text to JSON Converter Examples ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Convert CSV to JSON
Write-Host "Example 1: Converting CSV to JSON" -ForegroundColor Yellow

$csvText = @"
Name,Age,City,Email
John Doe,30,New York,john@example.com
Jane Smith,25,Los Angeles,jane@example.com
Bob Johnson,35,Chicago,bob@example.com
"@

Write-Host "CSV Input:" -ForegroundColor Gray
Write-Host $csvText -ForegroundColor DarkGray
Write-Host ""

$json = ConvertTo-JsonFromCsv -CsvText $csvText -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 2: Convert key-value to JSON
Write-Host "Example 2: Converting key-value pairs to JSON" -ForegroundColor Yellow

$keyValueText = @"
name=John Doe
age=30
email=john@example.com
city=New York
active=true
salary=75000
"@

Write-Host "Key-Value Input:" -ForegroundColor Gray
Write-Host $keyValueText -ForegroundColor DarkGray
Write-Host ""

$json = ConvertTo-JsonFromKeyValue -Text $keyValueText -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 3: Convert INI file to JSON
Write-Host "Example 3: Converting INI format to JSON" -ForegroundColor Yellow

$iniText = @"
[Database]
Server=localhost
Port=1433
DatabaseName=ProductionDB
Username=dbadmin

[Application]
AppName=MyApplication
Version=1.0.0
Environment=Production

[Logging]
LogLevel=Information
LogPath=C:\Logs
EnableDebug=false
"@

Write-Host "INI Input:" -ForegroundColor Gray
Write-Host $iniText -ForegroundColor DarkGray
Write-Host ""

$json = ConvertTo-JsonFromIni -Text $iniText -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 4: Convert nested key-value to JSON
Write-Host "Example 4: Converting nested key-value to JSON" -ForegroundColor Yellow

$nestedText = @"
user.name=John Doe
user.age=30
user.email=john@example.com
address.street=123 Main St
address.city=New York
address.zip=10001
preferences.theme=dark
preferences.notifications=true
"@

Write-Host "Nested Key-Value Input:" -ForegroundColor Gray
Write-Host $nestedText -ForegroundColor DarkGray
Write-Host ""

$json = ConvertTo-JsonFromKeyValue -Text $nestedText -NestedSeparator '.' -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 5: Convert delimited text to JSON
Write-Host "Example 5: Converting pipe-delimited text to JSON" -ForegroundColor Yellow

$pipeDelimited = @"
John Doe|30|New York|Engineer
Jane Smith|25|Los Angeles|Designer
Bob Johnson|35|Chicago|Manager
"@

Write-Host "Pipe-Delimited Input:" -ForegroundColor Gray
Write-Host $pipeDelimited -ForegroundColor DarkGray
Write-Host ""

$headers = @('Name', 'Age', 'City', 'Role')
$json = ConvertTo-JsonFromDelimitedText -Text $pipeDelimited -Delimiter '\|' -Headers $headers -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 6: Convert hashtable to JSON
Write-Host "Example 6: Converting PowerShell hashtable to JSON" -ForegroundColor Yellow

$hashtable = @{
    Name = "John Doe"
    Age = 30
    Email = "john@example.com"
    Address = @{
        Street = "123 Main St"
        City = "New York"
        Zip = "10001"
    }
    Skills = @("PowerShell", "Python", "JavaScript")
}

Write-Host "Hashtable:" -ForegroundColor Gray
$hashtable | Format-List

$json = ConvertTo-JsonFromObject -InputObject $hashtable -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 7: Format existing JSON
Write-Host "Example 7: Formatting minified JSON" -ForegroundColor Yellow

$minified = '{"name":"John Doe","age":30,"email":"john@example.com","address":{"city":"New York","zip":"10001"}}'

Write-Host "Minified JSON:" -ForegroundColor Gray
Write-Host $minified -ForegroundColor DarkGray
Write-Host ""

$formatted = Format-JsonText -Json $minified

Write-Host "Formatted JSON:" -ForegroundColor Green
Write-Host $formatted -ForegroundColor DarkGray
Write-Host ""

# Example 8: Validate JSON
Write-Host "Example 8: Validating JSON" -ForegroundColor Yellow

$validJson = '{"name":"John","age":30}'
$invalidJson = '{"name":"John","age":30'

Write-Host "Testing valid JSON: $validJson" -ForegroundColor Gray
if (Test-JsonText -Json $validJson) {
    Write-Host "Result: Valid JSON" -ForegroundColor Green
}
else {
    Write-Host "Result: Invalid JSON" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing invalid JSON: $invalidJson" -ForegroundColor Gray
if (Test-JsonText -Json $invalidJson) {
    Write-Host "Result: Valid JSON" -ForegroundColor Green
}
else {
    Write-Host "Result: Invalid JSON" -ForegroundColor Red
}
Write-Host ""

# Example 9: Convert XML to JSON
Write-Host "Example 9: Converting XML to JSON" -ForegroundColor Yellow

$xmlText = @"
<?xml version="1.0" encoding="UTF-8"?>
<user>
    <name>John Doe</name>
    <age>30</age>
    <email>john@example.com</email>
    <address>
        <street>123 Main St</street>
        <city>New York</city>
        <zip>10001</zip>
    </address>
</user>
"@

Write-Host "XML Input:" -ForegroundColor Gray
Write-Host $xmlText -ForegroundColor DarkGray
Write-Host ""

$json = ConvertTo-JsonFromXml -XmlText $xmlText -Pretty

Write-Host "JSON Output:" -ForegroundColor Green
Write-Host $json -ForegroundColor DarkGray
Write-Host ""

# Example 10: Real-world scenario - Config file migration
Write-Host "Example 10: Real-world example - Migrating configuration files" -ForegroundColor Yellow
Write-Host ""

function Convert-ConfigToJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        Write-Host "Converting configuration file..." -ForegroundColor Cyan
        Write-Host "  Source: $ConfigPath" -ForegroundColor Gray

        # Detect file type
        $extension = [System.IO.Path]::GetExtension($ConfigPath).ToLower()

        switch ($extension) {
            '.ini' {
                Write-Host "  Format: INI" -ForegroundColor Gray
                $json = ConvertTo-JsonFromIni -FilePath $ConfigPath -Pretty
            }
            '.csv' {
                Write-Host "  Format: CSV" -ForegroundColor Gray
                $json = ConvertTo-JsonFromCsv -FilePath $ConfigPath -Pretty
            }
            '.xml' {
                Write-Host "  Format: XML" -ForegroundColor Gray
                $json = ConvertTo-JsonFromXml -FilePath $ConfigPath -Pretty
            }
            default {
                Write-Host "  Format: Key-Value (default)" -ForegroundColor Gray
                $json = ConvertTo-JsonFromKeyValue -FilePath $ConfigPath -Pretty
            }
        }

        # Save to file
        $json | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

        Write-Host "  Output: $OutputPath" -ForegroundColor Gray
        Write-Host "Conversion complete!" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Failed to convert configuration: $_"
        return $false
    }
}

Write-Host "Function defined: Convert-ConfigToJson" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  Convert-ConfigToJson -ConfigPath "C:\old-config.ini" -OutputPath "C:\new-config.json"' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Examples Complete ===" -ForegroundColor Cyan
