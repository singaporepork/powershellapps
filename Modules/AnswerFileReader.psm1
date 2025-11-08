<#
.SYNOPSIS
    Modular answer file reader for PowerShell 5+

.DESCRIPTION
    This module provides functions to read configuration values from various answer file formats.
    Supports INI-style, JSON, XML, and simple key-value pair files.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
#>

#region Public Functions

<#
.SYNOPSIS
    Reads values from an answer file and returns them as a hashtable.

.DESCRIPTION
    Automatically detects the file format (INI, JSON, XML, or key-value) and parses accordingly.
    Returns a hashtable with all key-value pairs from the file.

.PARAMETER FilePath
    The path to the answer file to read.

.PARAMETER Format
    Optional. Explicitly specify the file format (Auto, INI, JSON, XML, KeyValue).
    Default is Auto, which attempts to detect the format.

.PARAMETER DefaultSection
    For INI files, specify which section to read. If not specified, reads all sections.

.EXAMPLE
    $config = Read-AnswerFile -FilePath "C:\config\answers.ini"

.EXAMPLE
    $config = Read-AnswerFile -FilePath "C:\config\settings.json" -Format JSON

.EXAMPLE
    $config = Read-AnswerFile -FilePath "C:\config\answers.ini" -DefaultSection "Database"
#>
function Read-AnswerFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Auto', 'INI', 'JSON', 'XML', 'KeyValue')]
        [string]$Format = 'Auto',

        [Parameter(Mandatory = $false)]
        [string]$DefaultSection = $null
    )

    try {
        # Resolve the full path
        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        # Detect format if Auto
        if ($Format -eq 'Auto') {
            $Format = Get-FileFormat -FilePath $FilePath
        }

        # Read file based on format
        switch ($Format) {
            'JSON' {
                return Read-JsonAnswerFile -FilePath $FilePath
            }
            'XML' {
                return Read-XmlAnswerFile -FilePath $FilePath
            }
            'INI' {
                return Read-IniAnswerFile -FilePath $FilePath -Section $DefaultSection
            }
            'KeyValue' {
                return Read-KeyValueAnswerFile -FilePath $FilePath
            }
            default {
                throw "Unsupported file format: $Format"
            }
        }
    }
    catch {
        Write-Error "Failed to read answer file '$FilePath': $_"
        return $null
    }
}

<#
.SYNOPSIS
    Gets a specific value from an answer file.

.DESCRIPTION
    Reads an answer file and returns a specific value by key.

.PARAMETER FilePath
    The path to the answer file to read.

.PARAMETER Key
    The key name to retrieve the value for.

.PARAMETER DefaultValue
    Optional. The default value to return if the key is not found.

.PARAMETER Section
    Optional. For INI files, specify the section where the key is located.

.EXAMPLE
    $dbServer = Get-AnswerFileValue -FilePath "C:\config\answers.ini" -Key "ServerName"

.EXAMPLE
    $port = Get-AnswerFileValue -FilePath "C:\config\answers.ini" -Key "Port" -DefaultValue 1433
#>
function Get-AnswerFileValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        $DefaultValue = $null,

        [Parameter(Mandatory = $false)]
        [string]$Section = $null
    )

    try {
        $allValues = Read-AnswerFile -FilePath $FilePath -DefaultSection $Section

        if ($null -eq $allValues) {
            return $DefaultValue
        }

        # Handle nested keys (e.g., "Section.Key" for INI files)
        if ($Key.Contains('.') -and $allValues.ContainsKey($Key.Split('.')[0])) {
            $parts = $Key.Split('.')
            $value = $allValues[$parts[0]]
            for ($i = 1; $i -lt $parts.Length; $i++) {
                if ($value -is [hashtable] -and $value.ContainsKey($parts[$i])) {
                    $value = $value[$parts[$i]]
                }
                else {
                    return $DefaultValue
                }
            }
            return $value
        }

        # Direct key lookup
        if ($allValues.ContainsKey($Key)) {
            return $allValues[$Key]
        }

        return $DefaultValue
    }
    catch {
        Write-Error "Failed to get value for key '$Key': $_"
        return $DefaultValue
    }
}

<#
.SYNOPSIS
    Tests if a key exists in an answer file.

.PARAMETER FilePath
    The path to the answer file to check.

.PARAMETER Key
    The key name to test for.

.PARAMETER Section
    Optional. For INI files, specify the section to check.

.EXAMPLE
    if (Test-AnswerFileKey -FilePath "C:\config\answers.ini" -Key "ServerName") {
        # Key exists
    }
#>
function Test-AnswerFileKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$Section = $null
    )

    try {
        $allValues = Read-AnswerFile -FilePath $FilePath -DefaultSection $Section

        if ($null -eq $allValues) {
            return $false
        }

        # Handle nested keys
        if ($Key.Contains('.')) {
            $parts = $Key.Split('.')
            $value = $allValues[$parts[0]]
            for ($i = 1; $i -lt $parts.Length; $i++) {
                if ($value -is [hashtable] -and $value.ContainsKey($parts[$i])) {
                    $value = $value[$parts[$i]]
                }
                else {
                    return $false
                }
            }
            return $true
        }

        return $allValues.ContainsKey($Key)
    }
    catch {
        return $false
    }
}

#endregion

#region Private Functions

<#
.SYNOPSIS
    Detects the format of an answer file.
#>
function Get-FileFormat {
    param([string]$FilePath)

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $firstLine = Get-Content -Path $FilePath -First 1 -ErrorAction SilentlyContinue

    # Check by extension first
    switch ($extension) {
        '.json' { return 'JSON' }
        '.xml' { return 'XML' }
        '.ini' { return 'INI' }
    }

    # Try to detect by content
    if ($firstLine -match '^\s*{' -or $firstLine -match '^\s*\[') {
        # Could be JSON
        try {
            $content = Get-Content -Path $FilePath -Raw
            $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            return 'JSON'
        }
        catch {
            # Not valid JSON, might be INI with [section]
            return 'INI'
        }
    }
    elseif ($firstLine -match '^\s*<') {
        return 'XML'
    }
    elseif ($firstLine -match '^\s*\[.+\]') {
        return 'INI'
    }

    # Default to key-value format
    return 'KeyValue'
}

<#
.SYNOPSIS
    Reads a JSON answer file.
#>
function Read-JsonAnswerFile {
    param([string]$FilePath)

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $jsonObject = ConvertFrom-Json -InputObject $content

    # Convert PSCustomObject to Hashtable for consistency
    return ConvertTo-Hashtable -InputObject $jsonObject
}

<#
.SYNOPSIS
    Reads an XML answer file.
#>
function Read-XmlAnswerFile {
    param([string]$FilePath)

    [xml]$xmlContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $hashtable = @{}

    # Process all child elements of root
    foreach ($element in $xmlContent.DocumentElement.ChildNodes) {
        if ($element.NodeType -eq 'Element') {
            if ($element.HasChildNodes -and $element.FirstChild.NodeType -eq 'Element') {
                # Nested elements - create nested hashtable
                $hashtable[$element.Name] = @{}
                foreach ($child in $element.ChildNodes) {
                    if ($child.NodeType -eq 'Element') {
                        $hashtable[$element.Name][$child.Name] = $child.InnerText
                    }
                }
            }
            else {
                # Simple element
                $hashtable[$element.Name] = $element.InnerText
            }
        }
    }

    return $hashtable
}

<#
.SYNOPSIS
    Reads an INI-style answer file.
#>
function Read-IniAnswerFile {
    param(
        [string]$FilePath,
        [string]$Section = $null
    )

    $hashtable = @{}
    $currentSection = 'Global'

    $content = Get-Content -Path $FilePath -Encoding UTF8

    foreach ($line in $content) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#') -or $line.TrimStart().StartsWith(';')) {
            continue
        }

        # Check for section header
        if ($line -match '^\s*\[(.+)\]\s*$') {
            $currentSection = $matches[1].Trim()
            continue
        }

        # Parse key-value pair
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Remove quotes if present
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                $value = $matches[1]
            }

            # If a specific section is requested, only return values from that section
            if ($null -ne $Section -and $Section -ne '' -and $currentSection -eq $Section) {
                $hashtable[$key] = $value
            }
            elseif ($null -eq $Section -or $Section -eq '') {
                # Return all sections in nested hashtables
                if (-not $hashtable.ContainsKey($currentSection)) {
                    $hashtable[$currentSection] = @{}
                }
                $hashtable[$currentSection][$key] = $value
            }
        }
    }

    return $hashtable
}

<#
.SYNOPSIS
    Reads a simple key-value answer file.
#>
function Read-KeyValueAnswerFile {
    param([string]$FilePath)

    $hashtable = @{}
    $content = Get-Content -Path $FilePath -Encoding UTF8

    foreach ($line in $content) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#') -or $line.TrimStart().StartsWith(';')) {
            continue
        }

        # Parse key-value pair (supports =, :, or whitespace as delimiter)
        if ($line -match '^([^=:]+)[=:](.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Remove quotes if present
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                $value = $matches[1]
            }

            $hashtable[$key] = $value
        }
        elseif ($line -match '^(\S+)\s+(.+)$') {
            # Space-separated key-value
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Remove quotes if present
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                $value = $matches[1]
            }

            $hashtable[$key] = $value
        }
    }

    return $hashtable
}

<#
.SYNOPSIS
    Converts a PSCustomObject to a Hashtable recursively.
#>
function ConvertTo-Hashtable {
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @()
            foreach ($object in $InputObject) {
                $collection += ConvertTo-Hashtable -InputObject $object
            }
            return $collection
        }
        elseif ($InputObject -is [PSObject]) {
            $hashtable = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hashtable[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hashtable
        }
        else {
            return $InputObject
        }
    }
}

#endregion

# Export public functions
Export-ModuleMember -Function Read-AnswerFile, Get-AnswerFileValue, Test-AnswerFileKey
