<#
.SYNOPSIS
    Modular XML formatter for PowerShell 5+

.DESCRIPTION
    This module provides functions to transform XML files and strings into
    human-readable format with proper indentation and formatting.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
#>

#region Public Functions

<#
.SYNOPSIS
    Formats an XML string into human-readable format with proper indentation.

.DESCRIPTION
    Takes an XML string and formats it with proper indentation, line breaks,
    and optional settings for indent characters and declaration handling.

.PARAMETER XmlString
    The XML string to format.

.PARAMETER IndentChars
    The characters to use for indentation. Default is two spaces.

.PARAMETER OmitXmlDeclaration
    Switch. Omits the XML declaration from the output.

.PARAMETER PreserveWhitespace
    Switch. Preserves existing whitespace in text nodes.

.EXAMPLE
    # Format a compact XML string
    $xml = "<root><child>value</child></root>"
    $formatted = Format-XmlString -XmlString $xml
    Write-Host $formatted

.EXAMPLE
    # Format with tab indentation
    $formatted = Format-XmlString -XmlString $xml -IndentChars "`t"

.EXAMPLE
    # Format without XML declaration
    $formatted = Format-XmlString -XmlString $xml -OmitXmlDeclaration
#>
function Format-XmlString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$XmlString,

        [Parameter(Mandatory = $false)]
        [string]$IndentChars = '  ',

        [Parameter(Mandatory = $false)]
        [switch]$OmitXmlDeclaration,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveWhitespace
    )

    process {
        try {
            # Load XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            if ($PreserveWhitespace) {
                $xmlDoc.PreserveWhitespace = $true
            }
            $xmlDoc.LoadXml($XmlString)

            # Create settings for writer
            $settings = New-Object System.Xml.XmlWriterSettings
            $settings.Indent = $true
            $settings.IndentChars = $IndentChars
            $settings.NewLineChars = "`r`n"
            $settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
            $settings.OmitXmlDeclaration = $OmitXmlDeclaration

            # Write formatted XML to string
            $stringWriter = New-Object System.IO.StringWriter
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)

            $xmlDoc.Save($xmlWriter)
            $xmlWriter.Flush()
            $stringWriter.Flush()

            $result = $stringWriter.ToString()

            # Cleanup
            $xmlWriter.Close()
            $stringWriter.Close()

            return $result
        }
        catch {
            Write-Error "Failed to format XML string: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Formats an XML file into human-readable format.

.DESCRIPTION
    Reads an XML file and returns it formatted with proper indentation
    and line breaks for easy reading.

.PARAMETER FilePath
    Path to the XML file to format.

.PARAMETER IndentChars
    The characters to use for indentation. Default is two spaces.

.PARAMETER OmitXmlDeclaration
    Switch. Omits the XML declaration from the output.

.PARAMETER PreserveWhitespace
    Switch. Preserves existing whitespace in text nodes.

.EXAMPLE
    # Format an XML file
    $formatted = Format-XmlFile -FilePath "C:\data\config.xml"
    Write-Host $formatted

.EXAMPLE
    # Format with custom indentation
    $formatted = Format-XmlFile -FilePath "C:\data\config.xml" -IndentChars "    "

.EXAMPLE
    # Format and display without declaration
    $formatted = Format-XmlFile -FilePath "C:\data\config.xml" -OmitXmlDeclaration
#>
function Format-XmlFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$IndentChars = '  ',

        [Parameter(Mandatory = $false)]
        [switch]$OmitXmlDeclaration,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveWhitespace
    )

    try {
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Format using Format-XmlString
        $formatted = Format-XmlString -XmlString $content `
            -IndentChars $IndentChars `
            -OmitXmlDeclaration:$OmitXmlDeclaration `
            -PreserveWhitespace:$PreserveWhitespace

        return $formatted
    }
    catch {
        Write-Error "Failed to format XML file '$FilePath': $_"
        return $null
    }
}

<#
.SYNOPSIS
    Tests if a file or string contains valid XML.

.DESCRIPTION
    Validates whether the provided file path or string contains
    well-formed XML that can be parsed.

.PARAMETER FilePath
    Path to the file to validate.

.PARAMETER XmlString
    XML string to validate.

.PARAMETER Detailed
    Switch. Returns detailed validation result object instead of boolean.

.EXAMPLE
    # Test if a file is valid XML
    if (Test-XmlFile -FilePath "C:\data\config.xml") {
        Write-Host "Valid XML file"
    }

.EXAMPLE
    # Test an XML string
    $isValid = Test-XmlFile -XmlString "<root><child>value</child></root>"

.EXAMPLE
    # Get detailed validation result
    $result = Test-XmlFile -FilePath "C:\data\config.xml" -Detailed
    if (-not $result.IsValid) {
        Write-Host "Error: $($result.ErrorMessage)"
    }
#>
function Test-XmlFile {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$XmlString,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $result = @{
        IsValid = $false
        ErrorMessage = $null
        ErrorLine = $null
        ErrorPosition = $null
    }

    try {
        $xmlDoc = New-Object System.Xml.XmlDocument

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path $FilePath -PathType Leaf)) {
                $result.ErrorMessage = "File not found: $FilePath"
                if ($Detailed) { return [PSCustomObject]$result }
                return $false
            }
            $xmlDoc.Load($FilePath)
        }
        else {
            $xmlDoc.LoadXml($XmlString)
        }

        $result.IsValid = $true

        if ($Detailed) {
            return [PSCustomObject]$result
        }
        return $true
    }
    catch [System.Xml.XmlException] {
        $result.ErrorMessage = $_.Exception.Message
        $result.ErrorLine = $_.Exception.LineNumber
        $result.ErrorPosition = $_.Exception.LinePosition

        if ($Detailed) {
            return [PSCustomObject]$result
        }
        return $false
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message

        if ($Detailed) {
            return [PSCustomObject]$result
        }
        return $false
    }
}

<#
.SYNOPSIS
    Exports formatted XML to a file.

.DESCRIPTION
    Takes XML content from a file or string, formats it for human readability,
    and saves it to an output file.

.PARAMETER InputPath
    Path to the input XML file.

.PARAMETER XmlString
    XML string to format and export.

.PARAMETER OutputPath
    Path where the formatted XML will be saved.

.PARAMETER IndentChars
    The characters to use for indentation. Default is two spaces.

.PARAMETER OmitXmlDeclaration
    Switch. Omits the XML declaration from the output.

.PARAMETER Encoding
    The encoding to use for the output file. Default is UTF8.

.PARAMETER Force
    Switch. Overwrites the output file if it exists.

.EXAMPLE
    # Format and export XML file
    Export-FormattedXml -InputPath "C:\data\compact.xml" -OutputPath "C:\data\formatted.xml"

.EXAMPLE
    # Format XML string and export
    $xml = "<root><child>value</child></root>"
    Export-FormattedXml -XmlString $xml -OutputPath "C:\output.xml"

.EXAMPLE
    # Export with tab indentation and overwrite existing
    Export-FormattedXml -InputPath "C:\data\config.xml" `
        -OutputPath "C:\data\config-formatted.xml" `
        -IndentChars "`t" `
        -Force
#>
function Export-FormattedXml {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputPath,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$XmlString,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$IndentChars = '  ',

        [Parameter(Mandatory = $false)]
        [switch]$OmitXmlDeclaration,

        [Parameter(Mandatory = $false)]
        [ValidateSet('UTF8', 'UTF8NoBOM', 'ASCII', 'Unicode', 'UTF32')]
        [string]$Encoding = 'UTF8',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        # Check if output file exists
        if ((Test-Path $OutputPath) -and -not $Force) {
            Write-Error "Output file already exists. Use -Force to overwrite."
            return $false
        }

        # Get formatted XML
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $formatted = Format-XmlFile -FilePath $InputPath `
                -IndentChars $IndentChars `
                -OmitXmlDeclaration:$OmitXmlDeclaration
        }
        else {
            $formatted = Format-XmlString -XmlString $XmlString `
                -IndentChars $IndentChars `
                -OmitXmlDeclaration:$OmitXmlDeclaration
        }

        if ($null -eq $formatted) {
            return $false
        }

        # Determine encoding object
        $encodingObj = switch ($Encoding) {
            'UTF8' { New-Object System.Text.UTF8Encoding($true) }  # With BOM
            'UTF8NoBOM' { New-Object System.Text.UTF8Encoding($false) }
            'ASCII' { [System.Text.Encoding]::ASCII }
            'Unicode' { [System.Text.Encoding]::Unicode }
            'UTF32' { [System.Text.Encoding]::UTF32 }
        }

        # Save to file
        [System.IO.File]::WriteAllText($OutputPath, $formatted, $encodingObj)

        return $true
    }
    catch {
        Write-Error "Failed to export formatted XML: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Gets information about an XML document.

.DESCRIPTION
    Retrieves metadata and structural information about an XML file or string,
    including root element, namespace, element count, and encoding.

.PARAMETER FilePath
    Path to the XML file.

.PARAMETER XmlString
    XML string to analyze.

.EXAMPLE
    # Get info about XML file
    $info = Get-XmlInfo -FilePath "C:\data\config.xml"
    Write-Host "Root element: $($info.RootElement)"
    Write-Host "Total elements: $($info.ElementCount)"

.EXAMPLE
    # Get info about XML string
    $info = Get-XmlInfo -XmlString "<root><child>value</child></root>"
#>
function Get-XmlInfo {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$XmlString
    )

    try {
        $xmlDoc = New-Object System.Xml.XmlDocument

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $xmlDoc.Load($FilePath)
            $fileInfo = Get-Item $FilePath
            $fileName = $fileInfo.Name
            $fileSize = $fileInfo.Length
        }
        else {
            $xmlDoc.LoadXml($XmlString)
            $fileName = $null
            $fileSize = [System.Text.Encoding]::UTF8.GetByteCount($XmlString)
        }

        # Count elements recursively
        function Get-ElementCount($node) {
            $count = 0
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $count = 1
            }
            foreach ($child in $node.ChildNodes) {
                $count += Get-ElementCount $child
            }
            return $count
        }

        # Get all unique element names
        function Get-UniqueElements($node, $elements) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                if (-not $elements.Contains($node.LocalName)) {
                    $elements.Add($node.LocalName) | Out-Null
                }
            }
            foreach ($child in $node.ChildNodes) {
                Get-UniqueElements $child $elements
            }
        }

        $uniqueElements = New-Object System.Collections.ArrayList
        Get-UniqueElements $xmlDoc $uniqueElements

        # Get namespaces
        $namespaces = @()
        if ($xmlDoc.DocumentElement) {
            foreach ($attr in $xmlDoc.DocumentElement.Attributes) {
                if ($attr.Name -eq 'xmlns' -or $attr.Name.StartsWith('xmlns:')) {
                    $namespaces += @{
                        Prefix = if ($attr.Name -eq 'xmlns') { '' } else { $attr.Name.Substring(6) }
                        Uri = $attr.Value
                    }
                }
            }
        }

        # Get encoding from declaration
        $encoding = 'UTF-8'
        if ($xmlDoc.FirstChild -is [System.Xml.XmlDeclaration]) {
            if ($xmlDoc.FirstChild.Encoding) {
                $encoding = $xmlDoc.FirstChild.Encoding
            }
        }

        # Build result
        $info = [PSCustomObject]@{
            FileName = $fileName
            FileSize = $fileSize
            RootElement = $xmlDoc.DocumentElement.LocalName
            Encoding = $encoding
            Version = if ($xmlDoc.FirstChild -is [System.Xml.XmlDeclaration]) { $xmlDoc.FirstChild.Version } else { '1.0' }
            ElementCount = Get-ElementCount $xmlDoc
            UniqueElements = $uniqueElements.ToArray()
            UniqueElementCount = $uniqueElements.Count
            Namespaces = $namespaces
            HasNamespaces = $namespaces.Count -gt 0
            MaxDepth = Get-XmlMaxDepth $xmlDoc.DocumentElement
            HasComments = ($xmlDoc.SelectNodes('//comment()').Count -gt 0)
            HasCData = ($xmlDoc.SelectNodes('//text()[contains(., "CDATA")]').Count -gt 0 -or $xmlDoc.InnerXml.Contains('<![CDATA['))
        }

        return $info
    }
    catch {
        Write-Error "Failed to get XML info: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Converts an XML document object to a formatted string.

.DESCRIPTION
    Takes an XmlDocument or XmlNode object and converts it to a
    formatted, human-readable string.

.PARAMETER XmlDocument
    The XmlDocument or XmlNode to convert.

.PARAMETER IndentChars
    The characters to use for indentation. Default is two spaces.

.PARAMETER OmitXmlDeclaration
    Switch. Omits the XML declaration from the output.

.EXAMPLE
    # Load and format XML
    $xmlDoc = [xml](Get-Content "C:\data\config.xml")
    $formatted = ConvertTo-PrettyXml -XmlDocument $xmlDoc

.EXAMPLE
    # Create and format XML programmatically
    $xmlDoc = New-Object System.Xml.XmlDocument
    $root = $xmlDoc.CreateElement("root")
    $xmlDoc.AppendChild($root)
    $child = $xmlDoc.CreateElement("child")
    $child.InnerText = "value"
    $root.AppendChild($child)

    $formatted = ConvertTo-PrettyXml -XmlDocument $xmlDoc
#>
function ConvertTo-PrettyXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Xml.XmlNode]$XmlDocument,

        [Parameter(Mandatory = $false)]
        [string]$IndentChars = '  ',

        [Parameter(Mandatory = $false)]
        [switch]$OmitXmlDeclaration
    )

    process {
        try {
            # Get the owning document
            $doc = if ($XmlDocument -is [System.Xml.XmlDocument]) {
                $XmlDocument
            }
            else {
                $XmlDocument.OwnerDocument
            }

            # Create settings for writer
            $settings = New-Object System.Xml.XmlWriterSettings
            $settings.Indent = $true
            $settings.IndentChars = $IndentChars
            $settings.NewLineChars = "`r`n"
            $settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
            $settings.OmitXmlDeclaration = $OmitXmlDeclaration

            # Write formatted XML to string
            $stringWriter = New-Object System.IO.StringWriter
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)

            $doc.Save($xmlWriter)
            $xmlWriter.Flush()
            $stringWriter.Flush()

            $result = $stringWriter.ToString()

            # Cleanup
            $xmlWriter.Close()
            $stringWriter.Close()

            return $result
        }
        catch {
            Write-Error "Failed to convert XML to pretty format: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Minifies an XML string by removing unnecessary whitespace.

.DESCRIPTION
    Compresses XML by removing indentation, extra whitespace, and line breaks,
    producing a compact single-line representation.

.PARAMETER XmlString
    The XML string to minify.

.PARAMETER FilePath
    Path to the XML file to minify.

.PARAMETER PreserveComments
    Switch. Keeps XML comments in the output.

.EXAMPLE
    # Minify formatted XML string
    $minified = Compress-XmlString -XmlString $formattedXml

.EXAMPLE
    # Minify XML file
    $minified = Compress-XmlString -FilePath "C:\data\formatted.xml"

.EXAMPLE
    # Minify but keep comments
    $minified = Compress-XmlString -XmlString $xml -PreserveComments
#>
function Compress-XmlString {
    [CmdletBinding(DefaultParameterSetName='String')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='String', ValueFromPipeline = $true)]
        [string]$XmlString,

        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveComments
    )

    process {
        try {
            # Get XML content
            if ($PSCmdlet.ParameterSetName -eq 'File') {
                $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
            }
            else {
                $content = $XmlString
            }

            # Load XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.PreserveWhitespace = $false
            $xmlDoc.LoadXml($content)

            # Remove comments if requested
            if (-not $PreserveComments) {
                $comments = $xmlDoc.SelectNodes('//comment()')
                foreach ($comment in $comments) {
                    $comment.ParentNode.RemoveChild($comment) | Out-Null
                }
            }

            # Create settings for compact output
            $settings = New-Object System.Xml.XmlWriterSettings
            $settings.Indent = $false
            $settings.OmitXmlDeclaration = $false

            # Write compact XML to string
            $stringWriter = New-Object System.IO.StringWriter
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)

            $xmlDoc.Save($xmlWriter)
            $xmlWriter.Flush()
            $stringWriter.Flush()

            $result = $stringWriter.ToString()

            # Cleanup
            $xmlWriter.Close()
            $stringWriter.Close()

            return $result
        }
        catch {
            Write-Error "Failed to minify XML: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Extracts and formats a specific element from an XML document.

.DESCRIPTION
    Uses XPath to locate an element in an XML document and returns it
    as a formatted string.

.PARAMETER FilePath
    Path to the XML file.

.PARAMETER XmlString
    XML string to search.

.PARAMETER XPath
    The XPath expression to locate the element.

.PARAMETER IndentChars
    The characters to use for indentation. Default is two spaces.

.EXAMPLE
    # Extract and format a specific element
    $element = Get-FormattedXmlElement -FilePath "C:\data\config.xml" -XPath "//database"

.EXAMPLE
    # Extract from XML string
    $element = Get-FormattedXmlElement -XmlString $xml -XPath "/root/child[@name='test']"
#>
function Get-FormattedXmlElement {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$XmlString,

        [Parameter(Mandatory = $true)]
        [string]$XPath,

        [Parameter(Mandatory = $false)]
        [string]$IndentChars = '  '
    )

    try {
        $xmlDoc = New-Object System.Xml.XmlDocument

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $xmlDoc.Load($FilePath)
        }
        else {
            $xmlDoc.LoadXml($XmlString)
        }

        # Find element using XPath
        $node = $xmlDoc.SelectSingleNode($XPath)

        if ($null -eq $node) {
            Write-Warning "No element found for XPath: $XPath"
            return $null
        }

        # Format the element
        return Format-XmlString -XmlString $node.OuterXml -IndentChars $IndentChars -OmitXmlDeclaration
    }
    catch {
        Write-Error "Failed to get formatted XML element: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Compares two XML documents and shows differences.

.DESCRIPTION
    Compares the structure and content of two XML documents,
    returning information about their differences.

.PARAMETER ReferencePath
    Path to the reference XML file.

.PARAMETER DifferencePath
    Path to the difference XML file.

.PARAMETER ReferenceXml
    Reference XML string.

.PARAMETER DifferenceXml
    Difference XML string.

.PARAMETER IgnoreWhitespace
    Switch. Ignores whitespace differences in text content.

.EXAMPLE
    # Compare two XML files
    $diff = Compare-XmlDocuments -ReferencePath "C:\original.xml" -DifferencePath "C:\modified.xml"

.EXAMPLE
    # Compare XML strings
    $diff = Compare-XmlDocuments -ReferenceXml $xml1 -DifferenceXml $xml2
#>
function Compare-XmlDocuments {
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ReferencePath,

        [Parameter(Mandatory = $true, ParameterSetName='File')]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$DifferencePath,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$ReferenceXml,

        [Parameter(Mandatory = $true, ParameterSetName='String')]
        [string]$DifferenceXml,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreWhitespace
    )

    try {
        $refDoc = New-Object System.Xml.XmlDocument
        $diffDoc = New-Object System.Xml.XmlDocument

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $refDoc.Load($ReferencePath)
            $diffDoc.Load($DifferencePath)
        }
        else {
            $refDoc.LoadXml($ReferenceXml)
            $diffDoc.LoadXml($DifferenceXml)
        }

        $differences = @()

        # Compare function
        function Compare-XmlNodes($refNode, $diffNode, $path) {
            $diffs = @()

            # Check if nodes are of same type
            if ($refNode.NodeType -ne $diffNode.NodeType) {
                $diffs += [PSCustomObject]@{
                    Path = $path
                    Type = 'NodeTypeMismatch'
                    Reference = $refNode.NodeType.ToString()
                    Difference = $diffNode.NodeType.ToString()
                }
                return $diffs
            }

            # For elements, compare names
            if ($refNode.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                if ($refNode.LocalName -ne $diffNode.LocalName) {
                    $diffs += [PSCustomObject]@{
                        Path = $path
                        Type = 'ElementNameMismatch'
                        Reference = $refNode.LocalName
                        Difference = $diffNode.LocalName
                    }
                    return $diffs
                }

                # Compare attributes
                $refAttrs = @{}
                $diffAttrs = @{}

                foreach ($attr in $refNode.Attributes) {
                    $refAttrs[$attr.Name] = $attr.Value
                }
                foreach ($attr in $diffNode.Attributes) {
                    $diffAttrs[$attr.Name] = $attr.Value
                }

                foreach ($key in $refAttrs.Keys) {
                    if (-not $diffAttrs.ContainsKey($key)) {
                        $diffs += [PSCustomObject]@{
                            Path = "$path/@$key"
                            Type = 'AttributeMissing'
                            Reference = $refAttrs[$key]
                            Difference = $null
                        }
                    }
                    elseif ($refAttrs[$key] -ne $diffAttrs[$key]) {
                        $diffs += [PSCustomObject]@{
                            Path = "$path/@$key"
                            Type = 'AttributeValueDifferent'
                            Reference = $refAttrs[$key]
                            Difference = $diffAttrs[$key]
                        }
                    }
                }

                foreach ($key in $diffAttrs.Keys) {
                    if (-not $refAttrs.ContainsKey($key)) {
                        $diffs += [PSCustomObject]@{
                            Path = "$path/@$key"
                            Type = 'AttributeAdded'
                            Reference = $null
                            Difference = $diffAttrs[$key]
                        }
                    }
                }
            }

            # Compare text content
            if ($refNode.NodeType -eq [System.Xml.XmlNodeType]::Text -or
                $refNode.NodeType -eq [System.Xml.XmlNodeType]::CDATA) {
                $refText = $refNode.Value
                $diffText = $diffNode.Value

                if ($IgnoreWhitespace) {
                    $refText = $refText.Trim()
                    $diffText = $diffText.Trim()
                }

                if ($refText -ne $diffText) {
                    $diffs += [PSCustomObject]@{
                        Path = $path
                        Type = 'TextDifferent'
                        Reference = $refText
                        Difference = $diffText
                    }
                }
            }

            # Compare child nodes
            $refChildren = @($refNode.ChildNodes | Where-Object { $_.NodeType -ne [System.Xml.XmlNodeType]::Whitespace })
            $diffChildren = @($diffNode.ChildNodes | Where-Object { $_.NodeType -ne [System.Xml.XmlNodeType]::Whitespace })

            if ($refChildren.Count -ne $diffChildren.Count) {
                $diffs += [PSCustomObject]@{
                    Path = $path
                    Type = 'ChildCountDifferent'
                    Reference = $refChildren.Count
                    Difference = $diffChildren.Count
                }
            }

            $minCount = [Math]::Min($refChildren.Count, $diffChildren.Count)
            for ($i = 0; $i -lt $minCount; $i++) {
                $childPath = if ($refChildren[$i].NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    "$path/$($refChildren[$i].LocalName)[$($i + 1)]"
                }
                else {
                    "$path/text()[$($i + 1)]"
                }
                $diffs += Compare-XmlNodes $refChildren[$i] $diffChildren[$i] $childPath
            }

            return $diffs
        }

        $differences = Compare-XmlNodes $refDoc.DocumentElement $diffDoc.DocumentElement "/$($refDoc.DocumentElement.LocalName)"

        return [PSCustomObject]@{
            AreEqual = $differences.Count -eq 0
            DifferenceCount = $differences.Count
            Differences = $differences
        }
    }
    catch {
        Write-Error "Failed to compare XML documents: $_"
        return $null
    }
}

#endregion Public Functions

#region Private Functions

<#
.SYNOPSIS
    Gets the maximum depth of an XML element tree.
#>
function Get-XmlMaxDepth {
    param(
        [System.Xml.XmlNode]$Node,
        [int]$CurrentDepth = 1
    )

    $maxDepth = $CurrentDepth

    foreach ($child in $Node.ChildNodes) {
        if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
            $childDepth = Get-XmlMaxDepth -Node $child -CurrentDepth ($CurrentDepth + 1)
            if ($childDepth -gt $maxDepth) {
                $maxDepth = $childDepth
            }
        }
    }

    return $maxDepth
}

#endregion Private Functions

# Export public functions
Export-ModuleMember -Function @(
    'Format-XmlString',
    'Format-XmlFile',
    'Test-XmlFile',
    'Export-FormattedXml',
    'Get-XmlInfo',
    'ConvertTo-PrettyXml',
    'Compress-XmlString',
    'Get-FormattedXmlElement',
    'Compare-XmlDocuments'
)
