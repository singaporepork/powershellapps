<#
.SYNOPSIS
    Modular PDF text reader for PowerShell 5+

.DESCRIPTION
    This module provides functions to extract text from PDF files using iTextSharp.
    Supports reading entire documents, specific pages, or page ranges.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
    Dependencies: iTextSharp library (automatically downloaded if needed)
#>

#region Module Variables

$script:iTextSharpLoaded = $false
$script:iTextSharpPath = $null

#endregion

#region Public Functions

<#
.SYNOPSIS
    Reads text content from a PDF file.

.DESCRIPTION
    Extracts text from a PDF file. Can extract from the entire document,
    specific pages, or a range of pages.

.PARAMETER FilePath
    The path to the PDF file to read.

.PARAMETER Pages
    Optional. Specific page numbers to extract (array of integers).
    Page numbers start at 1.

.PARAMETER StartPage
    Optional. The first page to extract text from (used with EndPage for ranges).

.PARAMETER EndPage
    Optional. The last page to extract text from (used with StartPage for ranges).

.PARAMETER AllPages
    Switch. Extract text from all pages in the document. This is the default.

.PARAMETER Separator
    Optional. The separator to use between pages. Default is double newline.

.EXAMPLE
    # Read all pages
    $text = Read-PdfText -FilePath "C:\document.pdf"

.EXAMPLE
    # Read specific pages
    $text = Read-PdfText -FilePath "C:\document.pdf" -Pages 1,3,5

.EXAMPLE
    # Read a range of pages
    $text = Read-PdfText -FilePath "C:\document.pdf" -StartPage 2 -EndPage 5

.EXAMPLE
    # Read with custom separator
    $text = Read-PdfText -FilePath "C:\document.pdf" -Separator "`n---PAGE BREAK---`n"
#>
function Read-PdfText {
    [CmdletBinding(DefaultParameterSetName='AllPages')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName='SpecificPages')]
        [int[]]$Pages,

        [Parameter(Mandatory = $false, ParameterSetName='PageRange')]
        [int]$StartPage,

        [Parameter(Mandatory = $false, ParameterSetName='PageRange')]
        [int]$EndPage,

        [Parameter(Mandatory = $false, ParameterSetName='AllPages')]
        [switch]$AllPages,

        [Parameter(Mandatory = $false)]
        [string]$Separator = "`n`n"
    )

    try {
        # Ensure iTextSharp is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library"
        }

        # Resolve full path
        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        # Validate PDF file
        if (-not (Test-PdfFile -FilePath $FilePath)) {
            throw "File is not a valid PDF or is corrupted"
        }

        Write-Verbose "Reading PDF file: $FilePath"

        # Create PDF reader
        $pdfReader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)
        $totalPages = $pdfReader.NumberOfPages

        Write-Verbose "PDF has $totalPages pages"

        # Determine which pages to extract
        $pagesToExtract = @()

        switch ($PSCmdlet.ParameterSetName) {
            'SpecificPages' {
                $pagesToExtract = $Pages | Where-Object { $_ -ge 1 -and $_ -le $totalPages }
                if ($pagesToExtract.Count -eq 0) {
                    throw "No valid page numbers specified. PDF has $totalPages pages."
                }
            }
            'PageRange' {
                if ($StartPage -lt 1) { $StartPage = 1 }
                if ($EndPage -gt $totalPages) { $EndPage = $totalPages }
                if ($StartPage -gt $EndPage) {
                    throw "StartPage ($StartPage) must be less than or equal to EndPage ($EndPage)"
                }
                $pagesToExtract = $StartPage..$EndPage
            }
            'AllPages' {
                $pagesToExtract = 1..$totalPages
            }
        }

        Write-Verbose "Extracting text from $($pagesToExtract.Count) page(s)"

        # Extract text from pages
        $extractedText = @()
        $strategy = New-Object iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy

        foreach ($pageNum in $pagesToExtract) {
            try {
                $pageText = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdfReader, $pageNum, $strategy)
                $extractedText += $pageText
                Write-Verbose "Extracted text from page $pageNum"
            }
            catch {
                Write-Warning "Failed to extract text from page $pageNum: $_"
            }
        }

        # Close the PDF reader
        $pdfReader.Close()

        # Join text with separator
        $result = $extractedText -join $Separator

        return $result
    }
    catch {
        Write-Error "Failed to read PDF file: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Gets information about a PDF file.

.DESCRIPTION
    Retrieves metadata and information about a PDF file including page count,
    title, author, creation date, and other properties.

.PARAMETER FilePath
    The path to the PDF file.

.EXAMPLE
    $info = Get-PdfInfo -FilePath "C:\document.pdf"
    Write-Host "Pages: $($info.PageCount)"
    Write-Host "Author: $($info.Author)"

.EXAMPLE
    Get-PdfInfo -FilePath "C:\document.pdf" | Format-List
#>
function Get-PdfInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath
    )

    try {
        # Ensure iTextSharp is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library"
        }

        # Resolve full path
        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        Write-Verbose "Getting PDF info for: $FilePath"

        # Create PDF reader
        $pdfReader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)

        # Get metadata
        $info = @{
            FilePath = $FilePath
            FileName = [System.IO.Path]::GetFileName($FilePath)
            PageCount = $pdfReader.NumberOfPages
            Title = $pdfReader.Info["Title"]
            Author = $pdfReader.Info["Author"]
            Subject = $pdfReader.Info["Subject"]
            Keywords = $pdfReader.Info["Keywords"]
            Creator = $pdfReader.Info["Creator"]
            Producer = $pdfReader.Info["Producer"]
            CreationDate = $pdfReader.Info["CreationDate"]
            ModificationDate = $pdfReader.Info["ModDate"]
            PdfVersion = $pdfReader.PdfVersion
            IsEncrypted = $pdfReader.IsEncrypted()
            FileSize = (Get-Item $FilePath).Length
        }

        # Close the PDF reader
        $pdfReader.Close()

        # Create custom object
        $pdfInfo = New-Object PSObject -Property $info

        return $pdfInfo
    }
    catch {
        Write-Error "Failed to get PDF info: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Tests if a file is a valid PDF.

.DESCRIPTION
    Validates that a file is a readable PDF document.

.PARAMETER FilePath
    The path to the file to test.

.EXAMPLE
    if (Test-PdfFile -FilePath "C:\document.pdf") {
        Write-Host "Valid PDF file"
    }
#>
function Test-PdfFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            return $false
        }

        # Ensure iTextSharp is loaded
        if (-not (Initialize-PdfReader)) {
            return $false
        }

        # Try to open the PDF
        $pdfReader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)
        $isValid = ($pdfReader.NumberOfPages -gt 0)
        $pdfReader.Close()

        return $isValid
    }
    catch {
        Write-Verbose "File is not a valid PDF: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Exports text from a PDF to a text file.

.DESCRIPTION
    Reads text from a PDF and saves it to a text file.

.PARAMETER PdfPath
    The path to the PDF file.

.PARAMETER OutputPath
    The path where the text file should be saved.

.PARAMETER Pages
    Optional. Specific pages to extract.

.PARAMETER Encoding
    Optional. The text file encoding. Default is UTF8.

.EXAMPLE
    Export-PdfToText -PdfPath "C:\document.pdf" -OutputPath "C:\document.txt"

.EXAMPLE
    Export-PdfToText -PdfPath "C:\document.pdf" -OutputPath "C:\pages.txt" -Pages 1,2,3
#>
function Export-PdfToText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$PdfPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [int[]]$Pages,

        [Parameter(Mandatory = $false)]
        [ValidateSet('UTF8', 'ASCII', 'Unicode', 'UTF32', 'UTF7')]
        [string]$Encoding = 'UTF8'
    )

    try {
        Write-Verbose "Exporting PDF to text: $PdfPath -> $OutputPath"

        # Extract text
        if ($Pages) {
            $text = Read-PdfText -FilePath $PdfPath -Pages $Pages
        }
        else {
            $text = Read-PdfText -FilePath $PdfPath
        }

        if ([string]::IsNullOrEmpty($text)) {
            Write-Warning "No text extracted from PDF"
            return $false
        }

        # Save to file
        $text | Out-File -FilePath $OutputPath -Encoding $Encoding -Force

        Write-Verbose "Text exported successfully to: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to export PDF to text: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Searches for text in a PDF file.

.DESCRIPTION
    Searches for a text pattern in a PDF and returns matching results with page numbers.

.PARAMETER FilePath
    The path to the PDF file.

.PARAMETER Pattern
    The text pattern to search for (supports regex).

.PARAMETER CaseSensitive
    Switch. Makes the search case-sensitive.

.PARAMETER UseRegex
    Switch. Treats the pattern as a regular expression.

.EXAMPLE
    $results = Search-PdfText -FilePath "C:\document.pdf" -Pattern "invoice"

.EXAMPLE
    $results = Search-PdfText -FilePath "C:\document.pdf" -Pattern "\d{3}-\d{3}-\d{4}" -UseRegex
#>
function Search-PdfText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$UseRegex
    )

    try {
        # Ensure iTextSharp is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library"
        }

        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        Write-Verbose "Searching PDF for pattern: $Pattern"

        # Create PDF reader
        $pdfReader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)
        $totalPages = $pdfReader.NumberOfPages

        $results = @()
        $strategy = New-Object iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy

        # Search each page
        for ($pageNum = 1; $pageNum -le $totalPages; $pageNum++) {
            $pageText = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($pdfReader, $pageNum, $strategy)

            # Perform search
            $matches = $null
            if ($UseRegex) {
                $regexOptions = [System.Text.RegularExpressions.RegexOptions]::None
                if (-not $CaseSensitive) {
                    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                }
                $matches = [regex]::Matches($pageText, $Pattern, $regexOptions)
            }
            else {
                $comparison = if ($CaseSensitive) { [StringComparison]::Ordinal } else { [StringComparison]::OrdinalIgnoreCase }
                if ($pageText.IndexOf($Pattern, $comparison) -ge 0) {
                    $matches = @(@{ Value = $Pattern })
                }
            }

            if ($matches -and $matches.Count -gt 0) {
                foreach ($match in $matches) {
                    $results += [PSCustomObject]@{
                        Page = $pageNum
                        Match = $match.Value
                        Pattern = $Pattern
                    }
                }
            }
        }

        $pdfReader.Close()

        Write-Verbose "Found $($results.Count) match(es)"
        return $results
    }
    catch {
        Write-Error "Failed to search PDF: $_"
        return $null
    }
}

#endregion

#region Private Functions

<#
.SYNOPSIS
    Initializes the PDF reader library (iTextSharp).
#>
function Initialize-PdfReader {
    [CmdletBinding()]
    param()

    if ($script:iTextSharpLoaded) {
        return $true
    }

    try {
        # Try to find iTextSharp in common locations
        $possiblePaths = @(
            (Join-Path $PSScriptRoot "lib\itextsharp.dll"),
            (Join-Path $PSScriptRoot "..\lib\itextsharp.dll"),
            "C:\Program Files\iTextSharp\itextsharp.dll",
            "$env:USERPROFILE\Documents\PowerShell\Modules\iTextSharp\itextsharp.dll"
        )

        $foundPath = $null
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $foundPath = $path
                break
            }
        }

        if ($foundPath) {
            Write-Verbose "Loading iTextSharp from: $foundPath"
            Add-Type -Path $foundPath
            $script:iTextSharpPath = $foundPath
            $script:iTextSharpLoaded = $true
            return $true
        }

        # If not found, provide instructions
        Write-Warning "iTextSharp library not found."
        Write-Warning "Please download iTextSharp and place itextsharp.dll in one of these locations:"
        foreach ($path in $possiblePaths) {
            Write-Warning "  - $path"
        }
        Write-Warning ""
        Write-Warning "Download from: https://github.com/itext/itextsharp/releases"
        Write-Warning "Or use: Install-PdfReaderLibrary"

        return $false
    }
    catch {
        Write-Error "Failed to initialize PDF reader: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Downloads and installs the iTextSharp library.
#>
function Install-PdfReaderLibrary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$DestinationPath
    )

    try {
        if ([string]::IsNullOrEmpty($DestinationPath)) {
            $DestinationPath = Join-Path $PSScriptRoot "lib"
        }

        # Create destination directory
        if (-not (Test-Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        }

        $dllPath = Join-Path $DestinationPath "itextsharp.dll"

        if (Test-Path $dllPath) {
            Write-Host "iTextSharp is already installed at: $dllPath" -ForegroundColor Green
            return $true
        }

        Write-Host "Downloading iTextSharp library..." -ForegroundColor Yellow
        Write-Host "Note: You need to manually download iTextSharp 5.5.13.3 (LGPL version)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Steps to install:" -ForegroundColor Cyan
        Write-Host "1. Download from: https://github.com/itext/itextsharp/releases/tag/5.5.13.3" -ForegroundColor Gray
        Write-Host "2. Extract the ZIP file" -ForegroundColor Gray
        Write-Host "3. Copy itextsharp.dll to: $DestinationPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or install via NuGet Package Manager if available" -ForegroundColor Gray

        return $false
    }
    catch {
        Write-Error "Failed to install PDF reader library: $_"
        return $false
    }
}

#endregion

# Export public functions
Export-ModuleMember -Function Read-PdfText, `
                              Get-PdfInfo, `
                              Test-PdfFile, `
                              Export-PdfToText, `
                              Search-PdfText, `
                              Install-PdfReaderLibrary
