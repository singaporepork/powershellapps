# PdfTextReader Module - Setup Guide

## Overview

The PdfTextReader module allows you to extract text from PDF files in PowerShell 5+. It uses the iTextSharp library for PDF processing.

## Prerequisites

- PowerShell 5.0 or later
- iTextSharp library (itextsharp.dll)

## Installation

### Option 1: Download iTextSharp Manually

1. **Download iTextSharp 5.5.13.3** (LGPL/MPL version)
   - GitHub Release: https://github.com/itext/itextsharp/releases/tag/5.5.13.3
   - NuGet Package: https://www.nuget.org/packages/iTextSharp/5.5.13.3

2. **Extract the DLL**
   - If downloading from GitHub: Extract the ZIP and find `itextsharp.dll` in the `lib` folder
   - If using NuGet: Extract the .nupkg (it's a ZIP file) and find the DLL in `lib/net40/`

3. **Place the DLL** in one of these locations:
   ```
   Modules/lib/itextsharp.dll
   C:\Program Files\iTextSharp\itextsharp.dll
   %USERPROFILE%\Documents\PowerShell\Modules\iTextSharp\itextsharp.dll
   ```

### Option 2: Using NuGet (if NuGet.exe is available)

```powershell
# Download NuGet package
nuget install iTextSharp -Version 5.5.13.3 -OutputDirectory C:\Temp\iTextSharp

# Copy DLL to module directory
$sourceDll = "C:\Temp\iTextSharp\iTextSharp.5.5.13.3\lib\itextsharp.dll"
$destPath = ".\Modules\lib"
New-Item -ItemType Directory -Path $destPath -Force
Copy-Item $sourceDll $destPath
```

### Option 3: Using the Install Helper

```powershell
Import-Module .\Modules\PdfTextReader.psm1
Install-PdfReaderLibrary
```

This will show you instructions and the exact paths where you should place the DLL.

## Verifying Installation

```powershell
Import-Module .\Modules\PdfTextReader.psm1

# Test with a sample PDF
Test-PdfFile -FilePath "C:\path\to\sample.pdf"
```

If the module loads successfully, you should not see any errors about missing iTextSharp.

## Directory Structure

After installation, your directory should look like:

```
powershellapps/
├── Modules/
│   ├── PdfTextReader.psm1
│   └── lib/
│       └── itextsharp.dll  ← Place the DLL here
├── Examples/
│   ├── Use-PdfTextReader.ps1
│   └── Use-PdfTextReader-Batch.ps1
└── README.md
```

## Licensing

iTextSharp 5.5.13.3 is available under the AGPL/LGPL license. Make sure your usage complies with the license terms:

- **AGPL**: Free for open-source projects
- **Commercial License**: Required for closed-source commercial applications

For more information: https://itextpdf.com/how-buy

## Alternative: iText 7

If you need a more modern version, consider iText 7:
- More features and better performance
- Requires .NET Framework 4.5+ or .NET Core
- Different API (module would need updates)

## Troubleshooting

### Error: "Could not load file or assembly 'itextsharp'"

**Solution**: The DLL is not in a recognized location. Use `Install-PdfReaderLibrary` to see where to place it.

### Error: "This method can be called only from a trusted context"

**Solution**: The DLL may be blocked. Unblock it:
```powershell
Unblock-File -Path ".\Modules\lib\itextsharp.dll"
```

### Error: "PDF appears to be corrupted"

**Solution**: The PDF file may be damaged or password-protected. Try opening it in Adobe Reader first.

### PowerShell 7 Compatibility

While this module targets PowerShell 5, it should also work in PowerShell 7. However, you may need to use a different version of iTextSharp or iText 7 for optimal compatibility.

## Getting Help

```powershell
# Get help for module functions
Get-Help Read-PdfText -Full
Get-Help Get-PdfInfo -Full
Get-Help Search-PdfText -Full
Get-Help Export-PdfToText -Full
```

## Quick Start

```powershell
# Import module
Import-Module .\Modules\PdfTextReader.psm1

# Read entire PDF
$text = Read-PdfText -FilePath "C:\Documents\sample.pdf"

# Get PDF information
$info = Get-PdfInfo -FilePath "C:\Documents\sample.pdf"
Write-Host "Pages: $($info.PageCount)"

# Export to text file
Export-PdfToText -PdfPath "C:\Documents\sample.pdf" -OutputPath "C:\output.txt"

# Search for text
$results = Search-PdfText -FilePath "C:\Documents\sample.pdf" -Pattern "invoice"
```

## Next Steps

- Review the examples in the `Examples` folder
- Check the README.md for full documentation
- Test with your own PDF files
