<#
.SYNOPSIS
    Modular PDF text reader for PowerShell 5+

.DESCRIPTION
    This module provides functions to extract text from PDF files using iText 7.
    Supports reading entire documents, specific pages, or page ranges.

.NOTES
    Version: 2.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
    Dependencies: iText 7 library (itext7 NuGet package)
#>

#region Module Variables

$script:iTextLoaded = $false
$script:iTextPath = $null

#endregion

#region Public Functions

<#
.SYNOPSIS
    Reads text content from a PDF file.

.DESCRIPTION
    Extracts text from a PDF file using iText 7. Can extract from the entire document,
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
        # Ensure iText is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library. Please run Install-PdfReaderLibrary for setup instructions."
        }

        # Resolve full path
        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        # Validate PDF file
        if (-not (Test-PdfFile -FilePath $FilePath)) {
            throw "File is not a valid PDF or is corrupted"
        }

        Write-Verbose "Reading PDF file: $FilePath"

        # Create PDF reader and document
        $pdfReader = New-Object iText.Kernel.Pdf.PdfReader($FilePath)
        $pdfDocument = New-Object iText.Kernel.Pdf.PdfDocument($pdfReader)
        $totalPages = $pdfDocument.GetNumberOfPages()

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

        foreach ($pageNum in $pagesToExtract) {
            try {
                $page = $pdfDocument.GetPage($pageNum)
                $strategy = New-Object iText.Kernel.Pdf.Canvas.Parser.Listener.LocationTextExtractionStrategy
                $pageText = [iText.Kernel.Pdf.Canvas.Parser.PdfTextExtractor]::GetTextFromPage($page, $strategy)
                $extractedText += $pageText
                Write-Verbose "Extracted text from page $pageNum"
            }
            catch {
                Write-Warning "Failed to extract text from page $pageNum: $_"
            }
        }

        # Close the document and reader
        $pdfDocument.Close()
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
        # Ensure iText is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library"
        }

        # Resolve full path
        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        Write-Verbose "Getting PDF info for: $FilePath"

        # Create PDF reader and document
        $pdfReader = New-Object iText.Kernel.Pdf.PdfReader($FilePath)
        $pdfDocument = New-Object iText.Kernel.Pdf.PdfDocument($pdfReader)

        # Get document info
        $docInfo = $pdfDocument.GetDocumentInfo()

        # Create info object
        $info = @{
            FilePath = $FilePath
            FileName = [System.IO.Path]::GetFileName($FilePath)
            PageCount = $pdfDocument.GetNumberOfPages()
            Title = $docInfo.GetTitle()
            Author = $docInfo.GetAuthor()
            Subject = $docInfo.GetSubject()
            Keywords = $docInfo.GetKeywords()
            Creator = $docInfo.GetCreator()
            Producer = $docInfo.GetProducer()
            PdfVersion = $pdfDocument.GetPdfVersion().ToString()
            FileSize = (Get-Item $FilePath).Length
        }

        # Close the document and reader
        $pdfDocument.Close()
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

        # Ensure iText is loaded
        if (-not (Initialize-PdfReader)) {
            return $false
        }

        # Try to open the PDF
        $pdfReader = New-Object iText.Kernel.Pdf.PdfReader($FilePath)
        $pdfDocument = New-Object iText.Kernel.Pdf.PdfDocument($pdfReader)
        $isValid = ($pdfDocument.GetNumberOfPages() -gt 0)
        $pdfDocument.Close()
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
        # Ensure iText is loaded
        if (-not (Initialize-PdfReader)) {
            throw "Failed to initialize PDF reader library"
        }

        $FilePath = Resolve-Path -Path $FilePath -ErrorAction Stop

        Write-Verbose "Searching PDF for pattern: $Pattern"

        # Create PDF reader and document
        $pdfReader = New-Object iText.Kernel.Pdf.PdfReader($FilePath)
        $pdfDocument = New-Object iText.Kernel.Pdf.PdfDocument($pdfReader)
        $totalPages = $pdfDocument.GetNumberOfPages()

        $results = @()

        # Search each page
        for ($pageNum = 1; $pageNum -le $totalPages; $pageNum++) {
            $page = $pdfDocument.GetPage($pageNum)
            $strategy = New-Object iText.Kernel.Pdf.Canvas.Parser.Listener.LocationTextExtractionStrategy
            $pageText = [iText.Kernel.Pdf.Canvas.Parser.PdfTextExtractor]::GetTextFromPage($page, $strategy)

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

        $pdfDocument.Close()
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
    Initializes the PDF reader library (iText 7).
#>
function Initialize-PdfReader {
    [CmdletBinding()]
    param()

    if ($script:iTextLoaded) {
        return $true
    }

    try {
        # Try to find iText 7 DLLs in common locations
        $possiblePaths = @(
            (Join-Path $PSScriptRoot "lib"),
            (Join-Path $PSScriptRoot "..\lib"),
            "$env:USERPROFILE\Documents\PowerShell\Modules\iText7"
        )

        $foundPath = $null
        foreach ($basePath in $possiblePaths) {
            if (Test-Path $basePath) {
                # Check for required DLLs
                $kernelDll = Join-Path $basePath "itext.kernel.dll"
                $ioDll = Join-Path $basePath "itext.io.dll"

                if ((Test-Path $kernelDll) -and (Test-Path $ioDll)) {
                    $foundPath = $basePath
                    break
                }
            }
        }

        if ($foundPath) {
            Write-Verbose "Loading iText 7 from: $foundPath"

            # Load required assemblies in order
            $requiredDlls = @(
                "itext.io.dll",
                "itext.kernel.dll"
            )

            foreach ($dll in $requiredDlls) {
                $dllPath = Join-Path $foundPath $dll
                if (Test-Path $dllPath) {
                    Add-Type -Path $dllPath
                    Write-Verbose "Loaded: $dll"
                }
                else {
                    Write-Warning "Missing required DLL: $dll"
                    return $false
                }
            }

            $script:iTextPath = $foundPath
            $script:iTextLoaded = $true
            return $true
        }

        # If not found, provide instructions
        Write-Warning "iText 7 library not found."
        Write-Warning "Please download iText 7 and place the DLLs in one of these locations:"
        foreach ($path in $possiblePaths) {
            Write-Warning "  - $path"
        }
        Write-Warning ""
        Write-Warning "Required DLLs: itext.kernel.dll, itext.io.dll"
        Write-Warning "Download from: https://github.com/itext/itext-dotnet"
        Write-Warning "Or use NuGet: Install-Package itext7"
        Write-Warning "Or run: Install-PdfReaderLibrary"

        return $false
    }
    catch {
        Write-Error "Failed to initialize PDF reader: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Downloads and installs the iText 7 library.
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

        Write-Host "iText 7 Installation Instructions" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "iText 7 is the modern, actively maintained version of the PDF library." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Required Files:" -ForegroundColor Cyan
        Write-Host "  - itext.kernel.dll" -ForegroundColor White
        Write-Host "  - itext.io.dll" -ForegroundColor White
        Write-Host ""
        Write-Host "Installation Options:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Option 1: Download from NuGet (Recommended)" -ForegroundColor Green
        Write-Host "  1. Go to: https://www.nuget.org/packages/itext7/" -ForegroundColor Gray
        Write-Host "  2. Download the package (.nupkg file)" -ForegroundColor Gray
        Write-Host "  3. Rename .nupkg to .zip and extract" -ForegroundColor Gray
        Write-Host "  4. Copy DLLs from lib\netstandard2.0\ to: $DestinationPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Option 2: Use NuGet CLI (if available)" -ForegroundColor Green
        Write-Host "  nuget install itext7 -OutputDirectory $DestinationPath" -ForegroundColor Gray
        Write-Host "  Then copy DLLs from the lib\netstandard2.0\ folder" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Option 3: Download from GitHub" -ForegroundColor Green
        Write-Host "  1. Go to: https://github.com/itext/itext-dotnet/releases" -ForegroundColor Gray
        Write-Host "  2. Download the latest release" -ForegroundColor Gray
        Write-Host "  3. Extract and find the DLLs" -ForegroundColor Gray
        Write-Host "  4. Copy to: $DestinationPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "IMPORTANT - License Information:" -ForegroundColor Yellow
        Write-Host "  iText 7 is licensed under AGPL v3" -ForegroundColor White
        Write-Host "  Commercial license required for closed-source applications" -ForegroundColor White
        Write-Host "  More info: https://itextpdf.com/how-buy" -ForegroundColor White
        Write-Host ""
        Write-Host "Destination path: $DestinationPath" -ForegroundColor Cyan
        Write-Host ""

        return $false
    }
    catch {
        Write-Error "Failed to show installation instructions: $_"
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
