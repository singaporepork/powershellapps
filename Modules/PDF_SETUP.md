# PdfTextReader Module - Setup Guide

## Overview

The PdfTextReader module allows you to extract text from PDF files in PowerShell 5+. It uses the **iText 7** library, which is the modern, actively maintained version of the PDF processing library.

## Why iText 7?

**iText 7** replaced the end-of-life iTextSharp 5.x library with:
- **Active Maintenance**: Regular updates and bug fixes
- **Modern API**: Cleaner, more intuitive interface
- **Better Performance**: Optimized for current .NET versions
- **Enhanced Features**: More capabilities for PDF processing
- **Long-term Support**: Continued development and support

## Prerequisites

- PowerShell 5.0 or later
- iText 7 library DLLs (itext.kernel.dll and itext.io.dll)

## Installation

### Option 1: Download from NuGet (Recommended)

1. **Visit NuGet**
   - Go to: https://www.nuget.org/packages/itext7/

2. **Download the Package**
   - Click "Download package" on the right side
   - This downloads a `.nupkg` file

3. **Extract the Package**
   - Rename the `.nupkg` file to `.zip`
   - Extract the ZIP file
   - Navigate to `lib\netstandard2.0\` folder inside

4. **Copy the DLLs**
   - Copy `itext.kernel.dll` and `itext.io.dll`
   - Place them in: `Modules/lib/`

### Option 2: Using NuGet CLI

If you have NuGet CLI installed:

```powershell
# Install to a temporary directory
nuget install itext7 -OutputDirectory C:\Temp\iText7

# Copy DLLs to module directory
$sourcePath = "C:\Temp\iText7\itext7.8.x.x\lib\netstandard2.0"
$destPath = ".\Modules\lib"
New-Item -ItemType Directory -Path $destPath -Force
Copy-Item "$sourcePath\itext.kernel.dll" $destPath
Copy-Item "$sourcePath\itext.io.dll" $destPath
```

### Option 3: Using the Install Helper

```powershell
Import-Module .\Modules\PdfTextReader.psm1
Install-PdfReaderLibrary
```

## Verifying Installation

```powershell
Import-Module .\Modules\PdfTextReader.psm1

# Test with a sample PDF
Test-PdfFile -FilePath "C:\path\to\sample.pdf"
```

## Licensing

**iText 7** is licensed under **AGPL v3**.

- **Open Source Projects**: Free to use under AGPL v3 terms
- **Closed-Source/Commercial**: Requires a commercial license
- More info: https://itextpdf.com/how-buy

## Troubleshooting

### DLLs Blocked

```powershell
Unblock-File -Path ".\Modules\lib\itext.kernel.dll"
Unblock-File -Path ".\Modules\lib\itext.io.dll"
```

### Missing DLLs

Ensure both required DLLs are present:
- itext.kernel.dll
- itext.io.dll

## Quick Start

```powershell
Import-Module .\Modules\PdfTextReader.psm1

# Read PDF
$text = Read-PdfText -FilePath "document.pdf"

# Get info
$info = Get-PdfInfo -FilePath "document.pdf"

# Search
$results = Search-PdfText -FilePath "document.pdf" -Pattern "invoice"
```
