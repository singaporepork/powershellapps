<#
.SYNOPSIS
    Example: Batch processing PDF files

.DESCRIPTION
    Demonstrates how to process multiple PDF files in batch operations.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\PdfTextReader.psm1"
Import-Module $modulePath -Force

Write-Host "=== Batch PDF Processing Examples ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Process all PDFs in a folder
Write-Host "Example 1: Extract text from all PDFs in a folder" -ForegroundColor Yellow
Write-Host ""

function Export-AllPdfsToText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFolder,

        [Parameter(Mandatory = $true)]
        [string]$OutputFolder
    )

    try {
        # Create output folder if it doesn't exist
        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
        }

        # Get all PDF files
        $pdfFiles = Get-ChildItem -Path $SourceFolder -Filter "*.pdf" -File

        Write-Host "Found $($pdfFiles.Count) PDF file(s)" -ForegroundColor Cyan

        $processed = 0
        $failed = 0

        foreach ($pdfFile in $pdfFiles) {
            Write-Host "Processing: $($pdfFile.Name)..." -ForegroundColor Gray

            try {
                # Generate output path
                $outputFile = Join-Path $OutputFolder ($pdfFile.BaseName + ".txt")

                # Extract and export text
                $success = Export-PdfToText -PdfPath $pdfFile.FullName -OutputPath $outputFile

                if ($success) {
                    $processed++
                    Write-Host "  ✓ Exported to: $outputFile" -ForegroundColor Green
                }
                else {
                    $failed++
                    Write-Host "  ✗ Failed to export" -ForegroundColor Red
                }
            }
            catch {
                $failed++
                Write-Host "  ✗ Error: $_" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Processed: $processed" -ForegroundColor Green
        Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })

        return @{
            Total = $pdfFiles.Count
            Processed = $processed
            Failed = $failed
        }
    }
    catch {
        Write-Error "Batch export failed: $_"
        return $null
    }
}

Write-Host "Function defined: Export-AllPdfsToText" -ForegroundColor Green
Write-Host "Usage: Export-AllPdfsToText -SourceFolder `"C:\PDFs`" -OutputFolder `"C:\TextOutput`"" -ForegroundColor Gray
Write-Host ""

# Example 2: Generate PDF inventory
Write-Host "Example 2: Generate PDF inventory report" -ForegroundColor Yellow
Write-Host ""

function Get-PdfInventory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputCsv
    )

    try {
        $pdfFiles = Get-ChildItem -Path $FolderPath -Filter "*.pdf" -Recurse -File

        Write-Host "Analyzing $($pdfFiles.Count) PDF file(s)..." -ForegroundColor Cyan

        $inventory = @()

        foreach ($pdfFile in $pdfFiles) {
            Write-Host "  Analyzing: $($pdfFile.Name)" -ForegroundColor Gray

            try {
                $info = Get-PdfInfo -FilePath $pdfFile.FullName

                $inventory += [PSCustomObject]@{
                    FileName = $pdfFile.Name
                    FullPath = $pdfFile.FullName
                    PageCount = $info.PageCount
                    Title = $info.Title
                    Author = $info.Author
                    Creator = $info.Creator
                    FileSize_KB = [Math]::Round($pdfFile.Length / 1KB, 2)
                    CreatedDate = $pdfFile.CreationTime
                    ModifiedDate = $pdfFile.LastWriteTime
                    IsEncrypted = $info.IsEncrypted
                }
            }
            catch {
                Write-Warning "  Failed to analyze: $($pdfFile.Name)"
            }
        }

        # Display results
        Write-Host ""
        Write-Host "Inventory Summary:" -ForegroundColor Cyan
        Write-Host "  Total PDFs: $($inventory.Count)" -ForegroundColor Gray
        Write-Host "  Total Pages: $($inventory | Measure-Object -Property PageCount -Sum | Select-Object -ExpandProperty Sum)" -ForegroundColor Gray
        Write-Host "  Total Size: $([Math]::Round(($inventory | Measure-Object -Property FileSize_KB -Sum | Select-Object -ExpandProperty Sum) / 1024, 2)) MB" -ForegroundColor Gray

        # Export to CSV if specified
        if ($OutputCsv) {
            $inventory | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "  Exported to: $OutputCsv" -ForegroundColor Green
        }

        return $inventory
    }
    catch {
        Write-Error "Failed to generate inventory: $_"
        return $null
    }
}

Write-Host "Function defined: Get-PdfInventory" -ForegroundColor Green
Write-Host "Usage: Get-PdfInventory -FolderPath `"C:\Documents`" -OutputCsv `"inventory.csv`"" -ForegroundColor Gray
Write-Host ""

# Example 3: Search across multiple PDFs
Write-Host "Example 3: Search for text across multiple PDFs" -ForegroundColor Yellow
Write-Host ""

function Search-PdfFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $true)]
        [string]$SearchPattern,

        [Parameter(Mandatory = $false)]
        [switch]$UseRegex,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive
    )

    try {
        $pdfFiles = Get-ChildItem -Path $FolderPath -Filter "*.pdf" -Recurse -File

        Write-Host "Searching $($pdfFiles.Count) PDF file(s) for: '$SearchPattern'" -ForegroundColor Cyan
        Write-Host ""

        $allResults = @()

        foreach ($pdfFile in $pdfFiles) {
            Write-Host "Searching: $($pdfFile.Name)..." -ForegroundColor Gray

            try {
                $results = Search-PdfText -FilePath $pdfFile.FullName `
                                          -Pattern $SearchPattern `
                                          -UseRegex:$UseRegex `
                                          -CaseSensitive:$CaseSensitive

                if ($results) {
                    foreach ($result in $results) {
                        $allResults += [PSCustomObject]@{
                            FileName = $pdfFile.Name
                            FilePath = $pdfFile.FullName
                            Page = $result.Page
                            Match = $result.Match
                        }
                    }
                    Write-Host "  Found $($results.Count) match(es)" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "  Error searching file: $_"
            }
        }

        Write-Host ""
        Write-Host "Search Results:" -ForegroundColor Cyan
        Write-Host "  Files with matches: $($allResults | Select-Object -Unique FileName | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Gray
        Write-Host "  Total matches: $($allResults.Count)" -ForegroundColor Gray

        if ($allResults.Count -gt 0) {
            Write-Host ""
            Write-Host "First 10 matches:" -ForegroundColor Yellow
            $allResults | Select-Object -First 10 | Format-Table FileName, Page, Match -AutoSize
        }

        return $allResults
    }
    catch {
        Write-Error "Search failed: $_"
        return $null
    }
}

Write-Host "Function defined: Search-PdfFolder" -ForegroundColor Green
Write-Host "Usage: Search-PdfFolder -FolderPath `"C:\Documents`" -SearchPattern `"contract`"" -ForegroundColor Gray
Write-Host ""

# Example 4: Extract specific pages from multiple PDFs
Write-Host "Example 4: Extract first page from all PDFs (for previews)" -ForegroundColor Yellow
Write-Host ""

function Export-PdfFirstPages {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFolder,

        [Parameter(Mandatory = $true)]
        [string]$OutputFolder
    )

    try {
        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
        }

        $pdfFiles = Get-ChildItem -Path $SourceFolder -Filter "*.pdf" -File

        Write-Host "Extracting first page from $($pdfFiles.Count) PDF(s)..." -ForegroundColor Cyan

        foreach ($pdfFile in $pdfFiles) {
            Write-Host "  Processing: $($pdfFile.Name)" -ForegroundColor Gray

            try {
                # Extract first page
                $firstPageText = Read-PdfText -FilePath $pdfFile.FullName -Pages 1

                # Save to file
                $outputFile = Join-Path $OutputFolder ($pdfFile.BaseName + "_page1.txt")
                $firstPageText | Out-File -FilePath $outputFile -Encoding UTF8

                Write-Host "    Saved to: $outputFile" -ForegroundColor Green
            }
            catch {
                Write-Warning "    Failed: $_"
            }
        }

        Write-Host "Complete!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to extract first pages: $_"
    }
}

Write-Host "Function defined: Export-PdfFirstPages" -ForegroundColor Green
Write-Host "Usage: Export-PdfFirstPages -SourceFolder `"C:\PDFs`" -OutputFolder `"C:\Previews`"" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Batch Processing Examples Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "These functions can be used to:" -ForegroundColor Yellow
Write-Host "  • Convert multiple PDFs to text files" -ForegroundColor Gray
Write-Host "  • Create PDF inventory reports" -ForegroundColor Gray
Write-Host "  • Search for content across PDF libraries" -ForegroundColor Gray
Write-Host "  • Extract specific pages for processing" -ForegroundColor Gray
