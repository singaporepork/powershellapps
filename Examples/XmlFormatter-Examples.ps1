<#
.SYNOPSIS
    Examples demonstrating XmlFormatter module functionality.

.DESCRIPTION
    This script shows various ways to use the XmlFormatter module to
    transform XML into human-readable format.

.NOTES
    Run this script to see all examples in action.
    Prerequisites: PowerShell 5.0+
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\XmlFormatter.psm1"
Import-Module $modulePath -Force

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "XmlFormatter Module - Examples" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

#region Example 1: Basic XML String Formatting

Write-Host "Example 1: Basic XML String Formatting" -ForegroundColor Yellow
Write-Host "-" * 40

# Compact XML string
$compactXml = '<?xml version="1.0"?><configuration><appSettings><add key="ServerName" value="localhost"/><add key="Port" value="8080"/><add key="Environment" value="Development"/></appSettings><connectionStrings><add name="Default" connectionString="Server=localhost;Database=MyDB;Trusted_Connection=true"/></connectionStrings></configuration>'

Write-Host "Original compact XML:"
Write-Host $compactXml -ForegroundColor Gray
Write-Host ""

# Format the XML
$formatted = Format-XmlString -XmlString $compactXml
Write-Host "Formatted XML:"
Write-Host $formatted -ForegroundColor Green
Write-Host ""

#endregion

#region Example 2: Custom Indentation

Write-Host "Example 2: Custom Indentation" -ForegroundColor Yellow
Write-Host "-" * 40

$xml = '<root><parent><child>value1</child><child>value2</child></parent></root>'

# Format with tab indentation
$tabFormatted = Format-XmlString -XmlString $xml -IndentChars "`t"
Write-Host "Formatted with tabs:"
Write-Host $tabFormatted -ForegroundColor Green
Write-Host ""

# Format with 4 spaces
$spaceFormatted = Format-XmlString -XmlString $xml -IndentChars "    "
Write-Host "Formatted with 4 spaces:"
Write-Host $spaceFormatted -ForegroundColor Green
Write-Host ""

#endregion

#region Example 3: Testing XML Validity

Write-Host "Example 3: Testing XML Validity" -ForegroundColor Yellow
Write-Host "-" * 40

# Valid XML
$validXml = '<root><child>value</child></root>'
$isValid = Test-XmlFile -XmlString $validXml
Write-Host "Valid XML test: $isValid" -ForegroundColor $(if ($isValid) { 'Green' } else { 'Red' })

# Invalid XML
$invalidXml = '<root><child>value</root>'
$isValid = Test-XmlFile -XmlString $invalidXml
Write-Host "Invalid XML test: $isValid" -ForegroundColor $(if ($isValid) { 'Green' } else { 'Red' })

# Get detailed validation result
$result = Test-XmlFile -XmlString $invalidXml -Detailed
if (-not $result.IsValid) {
    Write-Host "Error: $($result.ErrorMessage)" -ForegroundColor Red
    if ($result.ErrorLine) {
        Write-Host "Line: $($result.ErrorLine), Position: $($result.ErrorPosition)" -ForegroundColor Red
    }
}
Write-Host ""

#endregion

#region Example 4: Getting XML Information

Write-Host "Example 4: Getting XML Information" -ForegroundColor Yellow
Write-Host "-" * 40

$sampleXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<bookstore xmlns="http://example.com/books" xmlns:price="http://example.com/pricing">
    <book category="fiction">
        <title>The Great Gatsby</title>
        <author>F. Scott Fitzgerald</author>
        <year>1925</year>
        <price:cost currency="USD">12.99</price:cost>
    </book>
    <book category="non-fiction">
        <title>A Brief History of Time</title>
        <author>Stephen Hawking</author>
        <year>1988</year>
        <price:cost currency="USD">15.99</price:cost>
    </book>
    <!-- This is a comment -->
</bookstore>
'@

$info = Get-XmlInfo -XmlString $sampleXml

Write-Host "XML Document Information:"
Write-Host "  Root Element: $($info.RootElement)" -ForegroundColor Cyan
Write-Host "  Encoding: $($info.Encoding)" -ForegroundColor Cyan
Write-Host "  Version: $($info.Version)" -ForegroundColor Cyan
Write-Host "  Total Elements: $($info.ElementCount)" -ForegroundColor Cyan
Write-Host "  Unique Elements: $($info.UniqueElementCount)" -ForegroundColor Cyan
Write-Host "  Max Depth: $($info.MaxDepth)" -ForegroundColor Cyan
Write-Host "  Has Namespaces: $($info.HasNamespaces)" -ForegroundColor Cyan
Write-Host "  Has Comments: $($info.HasComments)" -ForegroundColor Cyan
Write-Host "  Unique Element Names: $($info.UniqueElements -join ', ')" -ForegroundColor Cyan

if ($info.Namespaces.Count -gt 0) {
    Write-Host "  Namespaces:" -ForegroundColor Cyan
    foreach ($ns in $info.Namespaces) {
        $prefix = if ($ns.Prefix) { $ns.Prefix } else { "(default)" }
        Write-Host "    $prefix = $($ns.Uri)" -ForegroundColor Gray
    }
}
Write-Host ""

#endregion

#region Example 5: Omit XML Declaration

Write-Host "Example 5: Omit XML Declaration" -ForegroundColor Yellow
Write-Host "-" * 40

$xml = '<?xml version="1.0" encoding="UTF-8"?><root><child>value</child></root>'

$withDeclaration = Format-XmlString -XmlString $xml
Write-Host "With declaration:"
Write-Host $withDeclaration -ForegroundColor Green
Write-Host ""

$withoutDeclaration = Format-XmlString -XmlString $xml -OmitXmlDeclaration
Write-Host "Without declaration:"
Write-Host $withoutDeclaration -ForegroundColor Green
Write-Host ""

#endregion

#region Example 6: Minifying XML

Write-Host "Example 6: Minifying XML" -ForegroundColor Yellow
Write-Host "-" * 40

$prettyXml = @'
<?xml version="1.0"?>
<root>
    <child>
        <grandchild>value1</grandchild>
        <grandchild>value2</grandchild>
    </child>
    <!-- A comment -->
</root>
'@

Write-Host "Original formatted XML:"
Write-Host $prettyXml -ForegroundColor Gray
Write-Host ""

$minified = Compress-XmlString -XmlString $prettyXml
Write-Host "Minified XML:"
Write-Host $minified -ForegroundColor Green
Write-Host ""

$minifiedNoComments = Compress-XmlString -XmlString $prettyXml
Write-Host "Minified without comments (comments removed by default):"
Write-Host $minifiedNoComments -ForegroundColor Green
Write-Host ""

#endregion

#region Example 7: Extract Specific Element

Write-Host "Example 7: Extract Specific Element" -ForegroundColor Yellow
Write-Host "-" * 40

$configXml = @'
<?xml version="1.0"?>
<configuration>
    <database>
        <server>localhost</server>
        <port>5432</port>
        <name>mydb</name>
        <credentials>
            <username>admin</username>
            <password>secret</password>
        </credentials>
    </database>
    <logging>
        <level>INFO</level>
        <path>/var/log/app.log</path>
    </logging>
</configuration>
'@

# Extract just the database section
$databaseSection = Get-FormattedXmlElement -XmlString $configXml -XPath "//database"
Write-Host "Extracted database section:"
Write-Host $databaseSection -ForegroundColor Green
Write-Host ""

# Extract credentials
$credentials = Get-FormattedXmlElement -XmlString $configXml -XPath "//credentials"
Write-Host "Extracted credentials section:"
Write-Host $credentials -ForegroundColor Green
Write-Host ""

#endregion

#region Example 8: Compare XML Documents

Write-Host "Example 8: Compare XML Documents" -ForegroundColor Yellow
Write-Host "-" * 40

$xml1 = @'
<config>
    <server name="web01">
        <port>80</port>
        <ssl>true</ssl>
    </server>
</config>
'@

$xml2 = @'
<config>
    <server name="web02">
        <port>443</port>
        <ssl>true</ssl>
        <timeout>30</timeout>
    </server>
</config>
'@

$comparison = Compare-XmlDocuments -ReferenceXml $xml1 -DifferenceXml $xml2

Write-Host "XML Comparison Result:"
Write-Host "  Are Equal: $($comparison.AreEqual)" -ForegroundColor $(if ($comparison.AreEqual) { 'Green' } else { 'Yellow' })
Write-Host "  Differences Found: $($comparison.DifferenceCount)" -ForegroundColor Cyan
Write-Host ""

if ($comparison.Differences.Count -gt 0) {
    Write-Host "Differences:" -ForegroundColor Yellow
    foreach ($diff in $comparison.Differences) {
        Write-Host "  Path: $($diff.Path)" -ForegroundColor Gray
        Write-Host "    Type: $($diff.Type)" -ForegroundColor Cyan
        Write-Host "    Reference: $($diff.Reference)" -ForegroundColor Red
        Write-Host "    Difference: $($diff.Difference)" -ForegroundColor Green
        Write-Host ""
    }
}

#endregion

#region Example 9: Convert XmlDocument Object to Pretty String

Write-Host "Example 9: Convert XmlDocument Object" -ForegroundColor Yellow
Write-Host "-" * 40

# Create XML document programmatically
$xmlDoc = New-Object System.Xml.XmlDocument
$declaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
$xmlDoc.AppendChild($declaration) | Out-Null

$root = $xmlDoc.CreateElement("employees")
$xmlDoc.AppendChild($root) | Out-Null

# Add employee elements
@(
    @{ Name = "John Doe"; Department = "Engineering"; Id = "E001" },
    @{ Name = "Jane Smith"; Department = "Marketing"; Id = "E002" }
) | ForEach-Object {
    $emp = $xmlDoc.CreateElement("employee")
    $emp.SetAttribute("id", $_.Id)

    $name = $xmlDoc.CreateElement("name")
    $name.InnerText = $_.Name
    $emp.AppendChild($name) | Out-Null

    $dept = $xmlDoc.CreateElement("department")
    $dept.InnerText = $_.Department
    $emp.AppendChild($dept) | Out-Null

    $root.AppendChild($emp) | Out-Null
}

# Convert to pretty string
$prettyXml = ConvertTo-PrettyXml -XmlDocument $xmlDoc
Write-Host "Programmatically created and formatted XML:"
Write-Host $prettyXml -ForegroundColor Green
Write-Host ""

#endregion

#region Example 10: Working with Files (Demonstration)

Write-Host "Example 10: Working with Files" -ForegroundColor Yellow
Write-Host "-" * 40

# Create a temporary XML file for demonstration
$tempDir = [System.IO.Path]::GetTempPath()
$tempInputFile = Join-Path $tempDir "sample-input.xml"
$tempOutputFile = Join-Path $tempDir "sample-output.xml"

# Write compact XML to temp file
$compactConfig = '<settings><app name="Demo" version="1.0"><feature enabled="true">Feature1</feature><feature enabled="false">Feature2</feature></app><logging level="DEBUG" path="./logs"/></settings>'
$compactConfig | Out-File -FilePath $tempInputFile -Encoding UTF8

Write-Host "Created temporary input file: $tempInputFile"

# Format the file
$formattedContent = Format-XmlFile -FilePath $tempInputFile
Write-Host "Formatted content from file:"
Write-Host $formattedContent -ForegroundColor Green
Write-Host ""

# Export formatted XML
$exportResult = Export-FormattedXml -InputPath $tempInputFile -OutputPath $tempOutputFile -Force
if ($exportResult) {
    Write-Host "Formatted XML exported to: $tempOutputFile" -ForegroundColor Cyan

    # Get info about the file
    $fileInfo = Get-XmlInfo -FilePath $tempOutputFile
    Write-Host "Output file info:"
    Write-Host "  Root: $($fileInfo.RootElement)" -ForegroundColor Gray
    Write-Host "  Elements: $($fileInfo.ElementCount)" -ForegroundColor Gray
    Write-Host "  Depth: $($fileInfo.MaxDepth)" -ForegroundColor Gray
}

# Cleanup temp files
Remove-Item $tempInputFile -Force -ErrorAction SilentlyContinue
Remove-Item $tempOutputFile -Force -ErrorAction SilentlyContinue
Write-Host "Temporary files cleaned up."
Write-Host ""

#endregion

#region Example 11: Pipeline Usage

Write-Host "Example 11: Pipeline Usage" -ForegroundColor Yellow
Write-Host "-" * 40

# Format multiple XML strings using pipeline
$xmlStrings = @(
    '<item id="1"><name>Item 1</name></item>',
    '<item id="2"><name>Item 2</name></item>',
    '<item id="3"><name>Item 3</name></item>'
)

Write-Host "Formatting multiple XML strings via pipeline:"
$xmlStrings | Format-XmlString -OmitXmlDeclaration | ForEach-Object {
    Write-Host $_ -ForegroundColor Green
    Write-Host ""
}

#endregion

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Examples Complete!" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "For more information, use:" -ForegroundColor Yellow
Write-Host "  Get-Help Format-XmlString -Full"
Write-Host "  Get-Help Format-XmlFile -Full"
Write-Host "  Get-Help Test-XmlFile -Full"
Write-Host "  Get-Help Export-FormattedXml -Full"
Write-Host "  Get-Help Get-XmlInfo -Full"
Write-Host "  Get-Help ConvertTo-PrettyXml -Full"
Write-Host "  Get-Help Compress-XmlString -Full"
Write-Host "  Get-Help Get-FormattedXmlElement -Full"
Write-Host "  Get-Help Compare-XmlDocuments -Full"
Write-Host ""
