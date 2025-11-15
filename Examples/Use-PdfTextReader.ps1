<#
.SYNOPSIS
    Example: Reading text from PDF files

.DESCRIPTION
    Demonstrates how to use the PdfTextReader module to extract text from PDF files.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\PdfTextReader.psm1"
Import-Module $modulePath -Force

Write-Host "=== PDF Text Reader Examples ===" -ForegroundColor Cyan
Write-Host ""

# Check if iTextSharp library is available
Write-Host "Checking for iTextSharp library..." -ForegroundColor Yellow
$testResult = Test-PdfFile -FilePath "nonexistent.pdf" 2>$null

if (-not $testResult -and $Error[0] -match "iTextSharp") {
    Write-Host "iTextSharp library not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To use this module, you need to install iTextSharp:" -ForegroundColor Yellow
    Write-Host "1. Run: Install-PdfReaderLibrary" -ForegroundColor Gray
    Write-Host "2. Follow the instructions to download and install the library" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Running installation helper..." -ForegroundColor Yellow
    Install-PdfReaderLibrary
    exit
}

# Example 1: Read entire PDF
Write-Host "Example 1: Reading entire PDF document" -ForegroundColor Yellow
Write-Host ""

$pdfPath = "C:\Documents\sample.pdf"
if (Test-Path $pdfPath) {
    Write-Host "Reading all pages from: $pdfPath" -ForegroundColor Gray
    $allText = Read-PdfText -FilePath $pdfPath

    Write-Host "Extracted text (first 200 characters):" -ForegroundColor Green
    Write-Host $allText.Substring(0, [Math]::Min(200, $allText.Length))
    Write-Host "..." -ForegroundColor Gray
}
else {
    Write-Host "Example file not found: $pdfPath" -ForegroundColor Gray
    Write-Host "To test, replace with an actual PDF path" -ForegroundColor Gray
}
Write-Host ""

# Example 2: Read specific pages
Write-Host "Example 2: Reading specific pages" -ForegroundColor Yellow

Write-Host "Command: Read-PdfText -FilePath `"document.pdf`" -Pages 1,3,5" -ForegroundColor Gray
Write-Host "This extracts text from pages 1, 3, and 5 only" -ForegroundColor Gray
Write-Host ""

# Example 3: Read page range
Write-Host "Example 3: Reading a range of pages" -ForegroundColor Yellow

Write-Host "Command: Read-PdfText -FilePath `"document.pdf`" -StartPage 2 -EndPage 5" -ForegroundColor Gray
Write-Host "This extracts text from pages 2 through 5" -ForegroundColor Gray
Write-Host ""

# Example 4: Get PDF information
Write-Host "Example 4: Getting PDF file information" -ForegroundColor Yellow

if (Test-Path $pdfPath) {
    Write-Host "Getting info for: $pdfPath" -ForegroundColor Gray
    $pdfInfo = Get-PdfInfo -FilePath $pdfPath

    Write-Host "PDF Information:" -ForegroundColor Green
    Write-Host "  File Name: $($pdfInfo.FileName)" -ForegroundColor Gray
    Write-Host "  Page Count: $($pdfInfo.PageCount)" -ForegroundColor Gray
    Write-Host "  Title: $($pdfInfo.Title)" -ForegroundColor Gray
    Write-Host "  Author: $($pdfInfo.Author)" -ForegroundColor Gray
    Write-Host "  Creator: $($pdfInfo.Creator)" -ForegroundColor Gray
    Write-Host "  File Size: $([Math]::Round($pdfInfo.FileSize / 1KB, 2)) KB" -ForegroundColor Gray
}
else {
    Write-Host "Command: Get-PdfInfo -FilePath `"document.pdf`"" -ForegroundColor Gray
    Write-Host "Returns: PageCount, Title, Author, Creator, FileSize, etc." -ForegroundColor Gray
}
Write-Host ""

# Example 5: Export PDF to text file
Write-Host "Example 5: Exporting PDF to text file" -ForegroundColor Yellow

if (Test-Path $pdfPath) {
    $outputPath = Join-Path $env:TEMP "pdf-export.txt"
    Write-Host "Exporting to: $outputPath" -ForegroundColor Gray

    $success = Export-PdfToText -PdfPath $pdfPath -OutputPath $outputPath

    if ($success) {
        Write-Host "Export successful!" -ForegroundColor Green
        Write-Host "Content preview:" -ForegroundColor Gray
        Get-Content $outputPath -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        Remove-Item $outputPath -Force
    }
}
else {
    Write-Host "Command: Export-PdfToText -PdfPath `"document.pdf`" -OutputPath `"output.txt`"" -ForegroundColor Gray
    Write-Host "Exports PDF text to a text file" -ForegroundColor Gray
}
Write-Host ""

# Example 6: Search for text in PDF
Write-Host "Example 6: Searching for text in PDF" -ForegroundColor Yellow

if (Test-Path $pdfPath) {
    Write-Host "Searching for 'invoice' in: $pdfPath" -ForegroundColor Gray
    $searchResults = Search-PdfText -FilePath $pdfPath -Pattern "invoice"

    if ($searchResults) {
        Write-Host "Found $($searchResults.Count) match(es):" -ForegroundColor Green
        $searchResults | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Page $($_.Page): $($_.Match)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "No matches found" -ForegroundColor Gray
    }
}
else {
    Write-Host "Command: Search-PdfText -FilePath `"document.pdf`" -Pattern `"search term`"" -ForegroundColor Gray
    Write-Host "Returns matches with page numbers" -ForegroundColor Gray
}
Write-Host ""

# Example 7: Regex search
Write-Host "Example 7: Regular expression search" -ForegroundColor Yellow

Write-Host "Command: Search-PdfText -FilePath `"document.pdf`" -Pattern `"\d{3}-\d{3}-\d{4}`" -UseRegex" -ForegroundColor Gray
Write-Host "Searches for phone numbers (###-###-####)" -ForegroundColor Gray
Write-Host ""

# Example 8: Real-world usage - Invoice processor
Write-Host "Example 8: Real-world example - Invoice processor" -ForegroundColor Yellow
Write-Host ""

function Process-InvoicePdf {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InvoicePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory = $env:TEMP
    )

    try {
        Write-Host "Processing invoice: $InvoicePath" -ForegroundColor Cyan

        # Get PDF info
        $pdfInfo = Get-PdfInfo -FilePath $InvoicePath
        Write-Host "  Pages: $($pdfInfo.PageCount)" -ForegroundColor Gray

        # Extract text
        $text = Read-PdfText -FilePath $InvoicePath

        # Search for invoice number (pattern: INV-XXXXX)
        $invoiceResults = Search-PdfText -FilePath $InvoicePath -Pattern "INV-\d{5}" -UseRegex

        if ($invoiceResults) {
            $invoiceNumber = $invoiceResults[0].Match
            Write-Host "  Invoice Number: $invoiceNumber" -ForegroundColor Green
        }

        # Search for total amount (pattern: $XXX.XX)
        $amountResults = Search-PdfText -FilePath $InvoicePath -Pattern "\$\d+\.\d{2}" -UseRegex

        if ($amountResults) {
            Write-Host "  Amounts found: $($amountResults.Count)" -ForegroundColor Green
            $amountResults | Select-Object -First 3 | ForEach-Object {
                Write-Host "    Page $($_.Page): $($_.Match)" -ForegroundColor Gray
            }
        }

        # Export to text for archiving
        $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($InvoicePath) + ".txt"
        $outputPath = Join-Path $OutputDirectory $outputFileName

        Export-PdfToText -PdfPath $InvoicePath -OutputPath $outputPath | Out-Null
        Write-Host "  Exported to: $outputPath" -ForegroundColor Green

        return @{
            Success = $true
            InvoiceNumber = if ($invoiceResults) { $invoiceResults[0].Match } else { $null }
            PageCount = $pdfInfo.PageCount
            ExportPath = $outputPath
        }
    }
    catch {
        Write-Error "Failed to process invoice: $_"
        return @{ Success = $false }
    }
}

Write-Host "Function defined: Process-InvoicePdf" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  $result = Process-InvoicePdf -InvoicePath "C:\Invoices\invoice.pdf"' -ForegroundColor Gray
Write-Host '  if ($result.Success) {' -ForegroundColor Gray
Write-Host '      Write-Host "Invoice $($result.InvoiceNumber) processed"' -ForegroundColor Gray
Write-Host '  }' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Examples Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Replace example paths with actual PDF files to test functionality" -ForegroundColor Yellow
