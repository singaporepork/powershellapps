<#
.SYNOPSIS
    Modular text to JSON converter for PowerShell 5+

.DESCRIPTION
    This module provides functions to convert various text formats to JSON.
    Supports CSV, key-value pairs, INI files, delimited text, and custom formats.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
#>

#region Public Functions

<#
.SYNOPSIS
    Converts CSV text or file to JSON.

.DESCRIPTION
    Reads CSV data from a file or string and converts it to JSON format.
    Supports custom delimiters and headers.

.PARAMETER FilePath
    Path to the CSV file to convert.

.PARAMETER CsvText
    CSV text content as a string.

.PARAMETER Delimiter
    The delimiter used in the CSV. Default is comma (,).

.PARAMETER Headers
    Custom headers to use instead of the first row.

.PARAMETER NoHeaders
    Switch. Indicates the CSV has no header row. Auto-generates column names.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.EXAMPLE
    # Convert CSV file to JSON
    $json = ConvertTo-JsonFromCsv -FilePath "C:\data.csv" -Pretty

.EXAMPLE
    # Convert CSV text to JSON
    $csvText = "Name,Age`nJohn,30`nJane,25"
    $json = ConvertTo-JsonFromCsv -CsvText $csvText -Pretty

.EXAMPLE
    # Convert tab-delimited file
    $json = ConvertTo-JsonFromCsv -FilePath "C:\data.tsv" -Delimiter "`t" -Pretty
#>
function ConvertTo-JsonFromCsv {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='Text')]
        [string]$CsvText,

        [Parameter(Mandatory = $false)]
        [string]$Delimiter = ',',

        [Parameter(Mandatory = $false)]
        [string[]]$Headers,

        [Parameter(Mandatory = $false)]
        [switch]$NoHeaders,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty
    )

    try {
        # Get CSV content
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $content = Get-Content -Path $FilePath -Raw
        }
        else {
            $content = $CsvText
        }

        # Parse CSV
        if ($NoHeaders) {
            # Import without headers, then add auto-generated headers
            $data = $content | ConvertFrom-Csv -Delimiter $Delimiter -Header (1..100 | ForEach-Object { "Column$_" })
        }
        elseif ($Headers) {
            # Use custom headers
            $data = $content | ConvertFrom-Csv -Delimiter $Delimiter -Header $Headers
        }
        else {
            # Use first row as headers
            $data = $content | ConvertFrom-Csv -Delimiter $Delimiter
        }

        # Convert to JSON
        if ($Pretty) {
            $json = $data | ConvertTo-Json -Depth 10
        }
        else {
            $json = $data | ConvertTo-Json -Depth 10 -Compress
        }

        return $json
    }
    catch {
        Write-Error "Failed to convert CSV to JSON: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Converts key-value text to JSON.

.DESCRIPTION
    Parses key-value pairs from text and converts to JSON format.
    Supports various delimiters (=, :, space) and nested keys.

.PARAMETER FilePath
    Path to the key-value file.

.PARAMETER Text
    Key-value text content as a string.

.PARAMETER Delimiter
    The delimiter between key and value. Default is '=' (also supports ':').

.PARAMETER NestedSeparator
    Character to separate nested keys. Default is '.' (e.g., "parent.child=value").

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.EXAMPLE
    # Convert key-value file to JSON
    $json = ConvertTo-JsonFromKeyValue -FilePath "C:\config.txt" -Pretty

.EXAMPLE
    # Convert key-value text
    $text = "name=John`nage=30`nemail=john@example.com"
    $json = ConvertTo-JsonFromKeyValue -Text $text -Pretty

.EXAMPLE
    # With nested keys
    $text = "user.name=John`nuser.age=30`nuser.email=john@example.com"
    $json = ConvertTo-JsonFromKeyValue -Text $text -NestedSeparator '.' -Pretty
#>
function ConvertTo-JsonFromKeyValue {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='Text')]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$Delimiter = '=',

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = '.',

        [Parameter(Mandatory = $false)]
        [switch]$Pretty
    )

    try {
        # Get text content
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $lines = Get-Content -Path $FilePath
        }
        else {
            $lines = $Text -split "`n"
        }

        $hashtable = @{}

        foreach ($line in $lines) {
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
                continue
            }

            # Parse key-value
            $parts = $line -split $Delimiter, 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()

                # Remove quotes if present
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                # Handle nested keys
                if ($key.Contains($NestedSeparator)) {
                    $keyParts = $key -split [regex]::Escape($NestedSeparator)
                    $current = $hashtable

                    for ($i = 0; $i -lt $keyParts.Length - 1; $i++) {
                        if (-not $current.ContainsKey($keyParts[$i])) {
                            $current[$keyParts[$i]] = @{}
                        }
                        $current = $current[$keyParts[$i]]
                    }

                    $current[$keyParts[-1]] = Convert-ValueType -Value $value
                }
                else {
                    $hashtable[$key] = Convert-ValueType -Value $value
                }
            }
        }

        # Convert to JSON
        if ($Pretty) {
            $json = $hashtable | ConvertTo-Json -Depth 10
        }
        else {
            $json = $hashtable | ConvertTo-Json -Depth 10 -Compress
        }

        return $json
    }
    catch {
        Write-Error "Failed to convert key-value to JSON: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Converts INI file to JSON.

.DESCRIPTION
    Parses an INI file with sections and converts to hierarchical JSON.

.PARAMETER FilePath
    Path to the INI file.

.PARAMETER Text
    INI text content as a string.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.EXAMPLE
    $json = ConvertTo-JsonFromIni -FilePath "C:\config.ini" -Pretty

.EXAMPLE
    $iniText = "[Database]`nServer=localhost`nPort=1433`n[App]`nName=MyApp"
    $json = ConvertTo-JsonFromIni -Text $iniText -Pretty
#>
function ConvertTo-JsonFromIni {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='Text')]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty
    )

    try {
        # Get text content
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $lines = Get-Content -Path $FilePath
        }
        else {
            $lines = $Text -split "`n"
        }

        $hashtable = @{}
        $currentSection = 'General'

        foreach ($line in $lines) {
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#') -or $line.TrimStart().StartsWith(';')) {
                continue
            }

            # Check for section
            if ($line -match '^\s*\[(.+)\]\s*$') {
                $currentSection = $matches[1].Trim()
                if (-not $hashtable.ContainsKey($currentSection)) {
                    $hashtable[$currentSection] = @{}
                }
                continue
            }

            # Parse key-value
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Remove quotes
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                if (-not $hashtable.ContainsKey($currentSection)) {
                    $hashtable[$currentSection] = @{}
                }

                $hashtable[$currentSection][$key] = Convert-ValueType -Value $value
            }
        }

        # Convert to JSON
        if ($Pretty) {
            $json = $hashtable | ConvertTo-Json -Depth 10
        }
        else {
            $json = $hashtable | ConvertTo-Json -Depth 10 -Compress
        }

        return $json
    }
    catch {
        Write-Error "Failed to convert INI to JSON: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Converts delimited text to JSON array.

.DESCRIPTION
    Parses delimited text (space, tab, pipe, etc.) and converts to JSON array.

.PARAMETER FilePath
    Path to the delimited file.

.PARAMETER Text
    Delimited text content as a string.

.PARAMETER Delimiter
    The delimiter character or regex pattern.

.PARAMETER Headers
    Column headers for the data.

.PARAMETER SkipLines
    Number of lines to skip from the beginning.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.EXAMPLE
    # Convert pipe-delimited text
    $json = ConvertTo-JsonFromDelimitedText -FilePath "C:\data.txt" -Delimiter '|' -Headers @('Name','Age','City') -Pretty

.EXAMPLE
    # Convert space-delimited text
    $text = "John 30 NYC`nJane 25 LA"
    $json = ConvertTo-JsonFromDelimitedText -Text $text -Delimiter '\s+' -Headers @('Name','Age','City') -Pretty
#>
function ConvertTo-JsonFromDelimitedText {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='Text')]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Delimiter,

        [Parameter(Mandatory = $false)]
        [string[]]$Headers,

        [Parameter(Mandatory = $false)]
        [int]$SkipLines = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty
    )

    try {
        # Get text content
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $lines = Get-Content -Path $FilePath
        }
        else {
            $lines = $Text -split "`n"
        }

        # Skip lines if specified
        if ($SkipLines -gt 0) {
            $lines = $lines | Select-Object -Skip $SkipLines
        }

        $data = @()

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            # Split by delimiter
            $values = $line -split $Delimiter

            # Create object
            $obj = @{}
            for ($i = 0; $i -lt $values.Length; $i++) {
                $value = $values[$i].Trim()

                if ($Headers -and $i -lt $Headers.Length) {
                    $obj[$Headers[$i]] = Convert-ValueType -Value $value
                }
                else {
                    $obj["Column$($i + 1)"] = Convert-ValueType -Value $value
                }
            }

            $data += $obj
        }

        # Convert to JSON
        if ($Pretty) {
            $json = $data | ConvertTo-Json -Depth 10
        }
        else {
            $json = $data | ConvertTo-Json -Depth 10 -Compress
        }

        return $json
    }
    catch {
        Write-Error "Failed to convert delimited text to JSON: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Converts a hashtable to formatted JSON.

.DESCRIPTION
    Converts a PowerShell hashtable or object to JSON with various formatting options.

.PARAMETER InputObject
    The hashtable or object to convert.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.PARAMETER Depth
    Maximum depth for nested objects. Default is 10.

.PARAMETER Compress
    Switch. Removes all whitespace from the JSON output.

.EXAMPLE
    $hashtable = @{ Name = "John"; Age = 30; City = "NYC" }
    $json = ConvertTo-JsonFromObject -InputObject $hashtable -Pretty

.EXAMPLE
    $object = [PSCustomObject]@{ Name = "Jane"; Age = 25 }
    $json = ConvertTo-JsonFromObject -InputObject $object -Pretty
#>
function ConvertTo-JsonFromObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty,

        [Parameter(Mandatory = $false)]
        [int]$Depth = 10,

        [Parameter(Mandatory = $false)]
        [switch]$Compress
    )

    process {
        try {
            if ($Compress) {
                $json = $InputObject | ConvertTo-Json -Depth $Depth -Compress
            }
            elseif ($Pretty) {
                $json = $InputObject | ConvertTo-Json -Depth $Depth
            }
            else {
                $json = $InputObject | ConvertTo-Json -Depth $Depth
            }

            return $json
        }
        catch {
            Write-Error "Failed to convert object to JSON: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Formats JSON text with proper indentation.

.DESCRIPTION
    Takes minified or poorly formatted JSON and returns properly indented JSON.

.PARAMETER Json
    The JSON string to format.

.PARAMETER IndentSize
    Number of spaces per indent level. Default is 2.

.EXAMPLE
    $minified = '{"name":"John","age":30}'
    $formatted = Format-JsonText -Json $minified
#>
function Format-JsonText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Json,

        [Parameter(Mandatory = $false)]
        [int]$IndentSize = 2
    )

    process {
        try {
            # Parse and re-serialize to format
            $obj = $Json | ConvertFrom-Json
            $formatted = $obj | ConvertTo-Json -Depth 100

            # Adjust indentation if not 2 spaces
            if ($IndentSize -ne 2) {
                $formatted = $formatted -replace '(?m)^( {2})+', {
                    ' ' * ($_.Value.Length / 2 * $IndentSize)
                }
            }

            return $formatted
        }
        catch {
            Write-Error "Failed to format JSON: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Validates if a string is valid JSON.

.DESCRIPTION
    Tests whether the provided string is valid JSON format.

.PARAMETER Json
    The JSON string to validate.

.EXAMPLE
    if (Test-JsonText -Json $jsonString) {
        Write-Host "Valid JSON"
    }
#>
function Test-JsonText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Json
    )

    process {
        try {
            $null = $Json | ConvertFrom-Json -ErrorAction Stop
            return $true
        }
        catch {
            Write-Verbose "Invalid JSON: $_"
            return $false
        }
    }
}

<#
.SYNOPSIS
    Converts XML to JSON.

.DESCRIPTION
    Parses XML and converts it to JSON format.

.PARAMETER FilePath
    Path to the XML file.

.PARAMETER XmlText
    XML content as a string.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.EXAMPLE
    $json = ConvertTo-JsonFromXml -FilePath "C:\data.xml" -Pretty

.EXAMPLE
    $xml = '<root><name>John</name><age>30</age></root>'
    $json = ConvertTo-JsonFromXml -XmlText $xml -Pretty
#>
function ConvertTo-JsonFromXml {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='Text')]
        [string]$XmlText,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty
    )

    try {
        # Load XML
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            [xml]$xmlDoc = Get-Content -Path $FilePath -Raw
        }
        else {
            [xml]$xmlDoc = $XmlText
        }

        # Convert XML to hashtable
        $hashtable = ConvertFrom-XmlNode -XmlNode $xmlDoc.DocumentElement

        # Convert to JSON
        if ($Pretty) {
            $json = $hashtable | ConvertTo-Json -Depth 10
        }
        else {
            $json = $hashtable | ConvertTo-Json -Depth 10 -Compress
        }

        return $json
    }
    catch {
        Write-Error "Failed to convert XML to JSON: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Exports data to a JSON file.

.DESCRIPTION
    Saves data as JSON to a file with optional formatting.

.PARAMETER InputObject
    The data to export.

.PARAMETER FilePath
    Path where the JSON file should be saved.

.PARAMETER Pretty
    Switch. Formats the JSON output with indentation.

.PARAMETER Force
    Switch. Overwrites the file if it exists.

.EXAMPLE
    $data = @{ Name = "John"; Age = 30 }
    Export-ToJsonFile -InputObject $data -FilePath "C:\output.json" -Pretty -Force
#>
function Export-ToJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Pretty,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    process {
        try {
            # Convert to JSON
            if ($Pretty) {
                $json = $InputObject | ConvertTo-Json -Depth 10
            }
            else {
                $json = $InputObject | ConvertTo-Json -Depth 10 -Compress
            }

            # Save to file
            if ($Force) {
                $json | Out-File -FilePath $FilePath -Encoding UTF8 -Force
            }
            else {
                if (Test-Path $FilePath) {
                    throw "File already exists. Use -Force to overwrite."
                }
                $json | Out-File -FilePath $FilePath -Encoding UTF8
            }

            Write-Verbose "JSON exported to: $FilePath"
            return $true
        }
        catch {
            Write-Error "Failed to export to JSON file: $_"
            return $false
        }
    }
}

#endregion

#region Private Functions

<#
.SYNOPSIS
    Converts a value to its appropriate type.
#>
function Convert-ValueType {
    param([string]$Value)

    # Try to convert to number
    $number = 0
    if ([int]::TryParse($Value, [ref]$number)) {
        return $number
    }

    $decimal = 0.0
    if ([double]::TryParse($Value, [ref]$decimal)) {
        return $decimal
    }

    # Try to convert to boolean
    if ($Value -eq 'true' -or $Value -eq 'True' -or $Value -eq 'TRUE') {
        return $true
    }
    if ($Value -eq 'false' -or $Value -eq 'False' -or $Value -eq 'FALSE') {
        return $false
    }

    # Return as string
    return $Value
}

<#
.SYNOPSIS
    Recursively converts XML node to hashtable.
#>
function ConvertFrom-XmlNode {
    param([System.Xml.XmlNode]$XmlNode)

    $hashtable = @{}

    # Handle attributes
    if ($XmlNode.Attributes) {
        foreach ($attr in $XmlNode.Attributes) {
            $hashtable["@$($attr.Name)"] = $attr.Value
        }
    }

    # Handle child nodes
    if ($XmlNode.HasChildNodes) {
        foreach ($child in $XmlNode.ChildNodes) {
            if ($child.NodeType -eq 'Element') {
                $childValue = if ($child.HasChildNodes -and $child.FirstChild.NodeType -eq 'Element') {
                    ConvertFrom-XmlNode -XmlNode $child
                }
                else {
                    $child.InnerText
                }

                if ($hashtable.ContainsKey($child.Name)) {
                    # Convert to array if multiple elements with same name
                    if ($hashtable[$child.Name] -isnot [System.Collections.ArrayList]) {
                        $hashtable[$child.Name] = @($hashtable[$child.Name])
                    }
                    $hashtable[$child.Name] += $childValue
                }
                else {
                    $hashtable[$child.Name] = $childValue
                }
            }
        }
    }

    return $hashtable
}

#endregion

# Export public functions
Export-ModuleMember -Function ConvertTo-JsonFromCsv, `
                              ConvertTo-JsonFromKeyValue, `
                              ConvertTo-JsonFromIni, `
                              ConvertTo-JsonFromDelimitedText, `
                              ConvertTo-JsonFromObject, `
                              ConvertTo-JsonFromXml, `
                              Format-JsonText, `
                              Test-JsonText, `
                              Export-ToJsonFile
