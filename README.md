# PowerShell Modular Scripts

A collection of reusable, modular PowerShell scripts designed to work across different environments and be easily integrated into other scripts.

## Compatibility

All scripts are compatible with PowerShell 5.0 and later.

## Modules

### AnswerFileReader

A comprehensive module for reading configuration values from various answer file formats.

#### Features

- **Multiple Format Support**: Automatically detects and reads INI, JSON, XML, and simple key-value files
- **Flexible API**: Read entire files, specific sections, or individual values
- **Error Handling**: Graceful error handling with default value support
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **Well Documented**: Comprehensive help documentation for all functions

#### Supported File Formats

1. **INI Files** - Supports sections and comments
2. **JSON Files** - Native JSON parsing with nested object support
3. **XML Files** - Hierarchical XML configuration files
4. **Key-Value Files** - Simple key=value or key:value pairs

#### Functions

##### Read-AnswerFile

Reads an entire answer file and returns a hashtable with all values.

```powershell
# Auto-detect format
$config = Read-AnswerFile -FilePath "C:\config\settings.ini"

# Explicitly specify format
$config = Read-AnswerFile -FilePath "C:\config\settings.json" -Format JSON

# Read specific section from INI file
$dbConfig = Read-AnswerFile -FilePath "C:\config\settings.ini" -DefaultSection "Database"
```

##### Get-AnswerFileValue

Retrieves a specific value from an answer file by key.

```powershell
# Get a value
$server = Get-AnswerFileValue -FilePath "C:\config\settings.ini" -Key "Database.ServerName"

# Get value with default
$port = Get-AnswerFileValue -FilePath "C:\config\settings.ini" -Key "Database.Port" -DefaultValue 1433

# Get from specific section
$user = Get-AnswerFileValue -FilePath "C:\config\settings.ini" -Key "Username" -Section "Database"
```

##### Test-AnswerFileKey

Tests whether a key exists in an answer file.

```powershell
if (Test-AnswerFileKey -FilePath "C:\config\settings.ini" -Key "Database.ServerName") {
    Write-Host "Server name is configured"
}
```

#### Usage Examples

##### Example 1: Basic Usage

```powershell
# Import the module
Import-Module ".\Modules\AnswerFileReader.psm1"

# Read configuration
$config = Read-AnswerFile -FilePath ".\config.ini"

# Use the values
Write-Host "Server: $($config.Database.ServerName)"
Write-Host "Port: $($config.Database.Port)"
```

##### Example 2: INI File with Sections

**config.ini:**
```ini
[Database]
ServerName=sql-server-01
Port=1433
DatabaseName=ProductionDB

[Application]
AppName=MyApp
Version=1.0.0
```

**Script:**
```powershell
Import-Module ".\Modules\AnswerFileReader.psm1"

# Read specific section
$dbConfig = Read-AnswerFile -FilePath ".\config.ini" -DefaultSection "Database"

# Use values
$connectionString = "Server=$($dbConfig.ServerName);Database=$($dbConfig.DatabaseName);Port=$($dbConfig.Port)"
```

##### Example 3: JSON Configuration

**config.json:**
```json
{
  "Database": {
    "ServerName": "sql-server-01",
    "Port": 1433
  },
  "Application": {
    "AppName": "MyApp"
  }
}
```

**Script:**
```powershell
Import-Module ".\Modules\AnswerFileReader.psm1"

$config = Read-AnswerFile -FilePath ".\config.json"
$server = $config.Database.ServerName
```

##### Example 4: Simple Key-Value File

**config.txt:**
```
ServerName=web-server-01
Port=80
Environment=Production
```

**Script:**
```powershell
Import-Module ".\Modules\AnswerFileReader.psm1"

$config = Read-AnswerFile -FilePath ".\config.txt"
Write-Host "Deploying to $($config.Environment) at $($config.ServerName):$($config.Port)"
```

##### Example 5: Using in Deployment Scripts

```powershell
Import-Module ".\Modules\AnswerFileReader.psm1"

function Deploy-Application {
    param(
        [string]$AnswerFilePath
    )

    # Read configuration from answer file
    $config = Read-AnswerFile -FilePath $AnswerFilePath

    # Validate required settings exist
    if (-not (Test-AnswerFileKey -FilePath $AnswerFilePath -Key "Application.TargetServer")) {
        throw "TargetServer not specified in answer file"
    }

    # Get values with defaults
    $targetServer = Get-AnswerFileValue -FilePath $AnswerFilePath -Key "Application.TargetServer"
    $deployPath = Get-AnswerFileValue -FilePath $AnswerFilePath -Key "Application.DeployPath" -DefaultValue "C:\Deploy"
    $enableBackup = Get-AnswerFileValue -FilePath $AnswerFilePath -Key "Application.EnableBackup" -DefaultValue $true

    Write-Host "Deploying to: $targetServer"
    Write-Host "Deploy path: $deployPath"

    if ($enableBackup) {
        Write-Host "Backup enabled"
        # Perform backup
    }

    # Continue with deployment...
}

# Use the function
Deploy-Application -AnswerFilePath ".\deployment-config.ini"
```

#### Installation

1. Copy the `AnswerFileReader.psm1` file to your PowerShell modules directory or project
2. Import the module in your script:
   ```powershell
   Import-Module ".\Modules\AnswerFileReader.psm1"
   ```

#### Testing

Run the example script to see all features in action:

```powershell
.\Examples\Use-AnswerFileReader.ps1
```

---

### RestApiAuth

A comprehensive module for authenticating with REST APIs using various authentication methods.

#### Features

- **Multiple Authentication Methods**: Basic, Bearer Token, API Key, OAuth 2.0 Client Credentials, Custom Headers
- **Session Management**: Create reusable authenticated sessions for multiple API calls
- **Automatic Token Refresh**: OAuth 2.0 tokens are automatically refreshed when expired
- **Error Handling**: Comprehensive error handling with detailed error messages
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **Flexible Usage**: Use sessions or generate headers for one-off requests

#### Supported Authentication Methods

1. **Basic Authentication** - Username and password (base64 encoded)
2. **Bearer Token** - JWT tokens, personal access tokens
3. **API Key** - Custom header-based API keys
4. **OAuth 2.0** - Client credentials flow with automatic token refresh
5. **Custom Headers** - Any custom authentication header scheme
6. **None** - For public APIs or when authentication is handled externally

#### Functions

##### New-RestApiSession

Creates an authenticated session for making REST API requests.

```powershell
# Basic Authentication
$cred = Get-Credential
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Basic -Credential $cred

# Bearer Token
$session = New-RestApiSession -BaseUri "https://api.github.com" -AuthMethod Bearer -Token $token

# API Key
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod ApiKey -Token $apiKey -ApiKeyHeader "X-API-Key"

# OAuth 2.0
$oauth = @{
    ClientId = "client-id"
    ClientSecret = "client-secret"
    TokenEndpoint = "https://auth.example.com/oauth/token"
    Scope = "api:read api:write"
}
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod OAuth2 -OAuth2Config $oauth
```

##### Invoke-RestApiRequest

Makes REST API requests using an authenticated session.

```powershell
# GET request
$users = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method GET

# POST request with body
$body = @{ name = "John Doe"; email = "john@example.com" }
$response = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method POST -Body $body

# GET with query parameters
$params = @{ page = 1; limit = 10 }
$users = Invoke-RestApiRequest -Session $session -Endpoint "/users" -QueryParameters $params
```

##### Test-RestApiConnection

Tests API connectivity and authentication.

```powershell
if (Test-RestApiConnection -Session $session) {
    Write-Host "API connection successful"
}
```

##### Update-RestApiSessionToken

Updates the authentication token in an existing session.

```powershell
Update-RestApiSessionToken -Session $session -Token $newToken
```

##### New-RestApiHeaders

Generates authentication headers for one-off requests.

```powershell
$headers = New-RestApiHeaders -AuthMethod Bearer -Token $token
Invoke-RestMethod -Uri "https://api.example.com/users" -Headers $headers
```

#### Usage Examples

##### Example 1: GitHub API with Bearer Token

```powershell
Import-Module ".\Modules\RestApiAuth.psm1"

# Create session with personal access token
$token = $env:GITHUB_TOKEN
$session = New-RestApiSession -BaseUri "https://api.github.com" -AuthMethod Bearer -Token $token

# Get authenticated user's repositories
$repos = Invoke-RestApiRequest -Session $session -Endpoint "/user/repos" -Method GET

# Display repositories
$repos | ForEach-Object {
    Write-Host "$($_.name) - $($_.description)"
}
```

##### Example 2: Basic Authentication

```powershell
Import-Module ".\Modules\RestApiAuth.psm1"

# Get credentials
$cred = Get-Credential -Message "Enter API credentials"

# Create session
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Basic -Credential $cred

# Test connection
if (Test-RestApiConnection -Session $session -TestEndpoint "/health") {
    Write-Host "Connected successfully"

    # Make API call
    $data = Invoke-RestApiRequest -Session $session -Endpoint "/data" -Method GET
}
```

##### Example 3: API Key Authentication

```powershell
Import-Module ".\Modules\RestApiAuth.psm1"

# Read API key from environment
$apiKey = $env:OPENWEATHER_API_KEY

# Create session (OpenWeather uses 'appid' in query params, we use None auth)
$session = New-RestApiSession -BaseUri "https://api.openweathermap.org/data/2.5" -AuthMethod None

# Get weather data (API key in query params)
$params = @{
    q = "London"
    appid = $apiKey
    units = "metric"
}

$weather = Invoke-RestApiRequest -Session $session -Endpoint "/weather" -QueryParameters $params

Write-Host "Temperature in London: $($weather.main.temp)°C"
```

##### Example 4: OAuth 2.0 with Microsoft Graph

```powershell
Import-Module ".\Modules\RestApiAuth.psm1"

# Configure OAuth2
$oauth2Config = @{
    ClientId = $env:AZURE_CLIENT_ID
    ClientSecret = $env:AZURE_CLIENT_SECRET
    TokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    Scope = "https://graph.microsoft.com/.default"
}

# Create session (automatically obtains token)
$session = New-RestApiSession -BaseUri "https://graph.microsoft.com/v1.0" `
                               -AuthMethod OAuth2 `
                               -OAuth2Config $oauth2Config

# Get users from Azure AD
$params = @{ '$top' = 10 }
$users = Invoke-RestApiRequest -Session $session -Endpoint "/users" -QueryParameters $params

# Token is automatically refreshed when expired
Start-Sleep -Seconds 3600
$moreUsers = Invoke-RestApiRequest -Session $session -Endpoint "/users" -QueryParameters $params
```

##### Example 5: Custom Headers

```powershell
Import-Module ".\Modules\RestApiAuth.psm1"

# Create session with custom headers
$customHeaders = @{
    'X-Custom-Auth' = 'custom-value'
    'X-Request-ID' = [guid]::NewGuid().ToString()
}

$session = New-RestApiSession -BaseUri "https://api.example.com" `
                               -AuthMethod Custom `
                               -CustomHeaders $customHeaders

# Make request
$response = Invoke-RestApiRequest -Session $session -Endpoint "/data"
```

#### Installation

1. Copy the `RestApiAuth.psm1` file to your PowerShell modules directory or project
2. Import the module in your script:
   ```powershell
   Import-Module ".\Modules\RestApiAuth.psm1"
   ```

#### Testing

Run the example scripts to see different authentication methods:

```powershell
.\Examples\Use-RestApiAuth-Basic.ps1
.\Examples\Use-RestApiAuth-Bearer.ps1
.\Examples\Use-RestApiAuth-ApiKey.ps1
.\Examples\Use-RestApiAuth-OAuth2.ps1
```

#### Common Use Cases

**Integrating with popular APIs:**

- **GitHub**: Bearer token authentication
- **Microsoft Graph**: OAuth 2.0 client credentials
- **OpenWeather**: API key in query parameters
- **Stripe**: API key in Authorization header
- **Auth0**: OAuth 2.0 client credentials
- **Okta**: OAuth 2.0 client credentials

**Security Best Practices:**

1. Store credentials in environment variables or secure vaults
2. Never hardcode passwords or secrets in scripts
3. Use `Get-Credential` for interactive credential input
4. Rotate tokens and API keys regularly
5. Use OAuth 2.0 when available for better security

---

### PdfTextReader

A comprehensive module for extracting text from PDF files using PowerShell.

#### Features

- **Text Extraction**: Extract text from entire PDFs, specific pages, or page ranges
- **PDF Information**: Retrieve metadata including page count, author, title, creation date
- **Text Search**: Search for text patterns using literal or regex matching
- **Batch Processing**: Process multiple PDFs with built-in batch functions
- **Export Functionality**: Save extracted text to files with various encodings
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **iTextSharp Integration**: Uses proven PDF library for reliable text extraction

#### Requirements

**Dependency**: iTextSharp library (itextsharp.dll) - See setup guide below

#### Functions

##### Read-PdfText

Extracts text from a PDF file.

```powershell
# Read all pages
$text = Read-PdfText -FilePath "C:\document.pdf"

# Read specific pages
$text = Read-PdfText -FilePath "C:\document.pdf" -Pages 1,3,5

# Read page range
$text = Read-PdfText -FilePath "C:\document.pdf" -StartPage 2 -EndPage 5

# Custom page separator
$text = Read-PdfText -FilePath "C:\document.pdf" -Separator "`n---PAGE---`n"
```

##### Get-PdfInfo

Retrieves PDF metadata and information.

```powershell
$info = Get-PdfInfo -FilePath "C:\document.pdf"

Write-Host "Pages: $($info.PageCount)"
Write-Host "Author: $($info.Author)"
Write-Host "Title: $($info.Title)"
Write-Host "File Size: $($info.FileSize) bytes"
```

##### Test-PdfFile

Validates if a file is a readable PDF.

```powershell
if (Test-PdfFile -FilePath "C:\document.pdf") {
    Write-Host "Valid PDF file"
}
```

##### Export-PdfToText

Exports PDF text to a file.

```powershell
# Export entire PDF
Export-PdfToText -PdfPath "C:\document.pdf" -OutputPath "C:\output.txt"

# Export specific pages
Export-PdfToText -PdfPath "C:\document.pdf" -OutputPath "C:\pages.txt" -Pages 1,2,3

# Specify encoding
Export-PdfToText -PdfPath "C:\document.pdf" -OutputPath "C:\output.txt" -Encoding UTF8
```

##### Search-PdfText

Searches for text patterns in PDFs.

```powershell
# Simple text search
$results = Search-PdfText -FilePath "C:\document.pdf" -Pattern "invoice"

# Regex search for phone numbers
$results = Search-PdfText -FilePath "C:\document.pdf" -Pattern "\d{3}-\d{3}-\d{4}" -UseRegex

# Case-sensitive search
$results = Search-PdfText -FilePath "C:\document.pdf" -Pattern "CompanyName" -CaseSensitive

# Display results
$results | ForEach-Object {
    Write-Host "Page $($_.Page): $($_.Match)"
}
```

##### Install-PdfReaderLibrary

Provides instructions for installing the iTextSharp dependency.

```powershell
Install-PdfReaderLibrary
```

#### Setup Instructions

**Step 1: Install iTextSharp**

Download iTextSharp 5.5.13.3 from one of these sources:
- GitHub: https://github.com/itext/itextsharp/releases/tag/5.5.13.3
- NuGet: https://www.nuget.org/packages/iTextSharp/5.5.13.3

**Step 2: Extract the DLL**

Extract `itextsharp.dll` from the download.

**Step 3: Place the DLL**

Put `itextsharp.dll` in one of these locations:
- `Modules/lib/itextsharp.dll` (recommended)
- `C:\Program Files\iTextSharp\itextsharp.dll`
- `%USERPROFILE%\Documents\PowerShell\Modules\iTextSharp\itextsharp.dll`

**Step 4: Unblock the DLL** (if downloaded from web)

```powershell
Unblock-File -Path ".\Modules\lib\itextsharp.dll"
```

**Step 5: Verify Installation**

```powershell
Import-Module .\Modules\PdfTextReader.psm1
Test-PdfFile -FilePath "C:\path\to\sample.pdf"
```

For detailed setup instructions, see `Modules/PDF_SETUP.md`

#### Usage Examples

##### Example 1: Extract Text from PDF

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

# Read entire PDF
$text = Read-PdfText -FilePath "C:\Reports\monthly-report.pdf"

# Display first 500 characters
Write-Host $text.Substring(0, 500)
```

##### Example 2: Get PDF Information

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

# Get all PDF files in a folder
Get-ChildItem "C:\Documents" -Filter "*.pdf" | ForEach-Object {
    $info = Get-PdfInfo -FilePath $_.FullName

    [PSCustomObject]@{
        FileName = $_.Name
        Pages = $info.PageCount
        Author = $info.Author
        SizeKB = [Math]::Round($_.Length / 1KB, 2)
    }
} | Format-Table
```

##### Example 3: Extract Invoice Data

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

function Get-InvoiceData {
    param([string]$PdfPath)

    # Search for invoice number
    $invoiceNum = Search-PdfText -FilePath $PdfPath -Pattern "INV-\d{5}" -UseRegex

    # Search for amounts
    $amounts = Search-PdfText -FilePath $PdfPath -Pattern "\$\d+\.\d{2}" -UseRegex

    # Search for date (MM/DD/YYYY)
    $dates = Search-PdfText -FilePath $PdfPath -Pattern "\d{2}/\d{2}/\d{4}" -UseRegex

    return @{
        InvoiceNumber = if ($invoiceNum) { $invoiceNum[0].Match } else { "Not Found" }
        Amount = if ($amounts) { $amounts[0].Match } else { "Not Found" }
        Date = if ($dates) { $dates[0].Match } else { "Not Found" }
    }
}

$invoiceData = Get-InvoiceData -PdfPath "C:\Invoices\invoice.pdf"
$invoiceData | Format-List
```

##### Example 4: Batch Convert PDFs to Text

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

$sourceFolder = "C:\PDFs"
$outputFolder = "C:\TextFiles"

# Create output folder
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

# Process all PDFs
Get-ChildItem -Path $sourceFolder -Filter "*.pdf" | ForEach-Object {
    $outputFile = Join-Path $outputFolder ($_.BaseName + ".txt")

    Write-Host "Converting: $($_.Name)..."
    Export-PdfToText -PdfPath $_.FullName -OutputPath $outputFile
}

Write-Host "Conversion complete!"
```

##### Example 5: Search Multiple PDFs

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

function Search-PdfFolder {
    param(
        [string]$FolderPath,
        [string]$Pattern
    )

    $results = @()

    Get-ChildItem -Path $FolderPath -Filter "*.pdf" -Recurse | ForEach-Object {
        $matches = Search-PdfText -FilePath $_.FullName -Pattern $Pattern

        foreach ($match in $matches) {
            $results += [PSCustomObject]@{
                File = $_.Name
                Page = $match.Page
                Match = $match.Match
                Path = $_.FullName
            }
        }
    }

    return $results
}

# Search for all email addresses
$emails = Search-PdfFolder -FolderPath "C:\Documents" -Pattern "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
$emails | Format-Table -AutoSize
```

##### Example 6: PDF Inventory Report

```powershell
Import-Module ".\Modules\PdfTextReader.psm1"

$pdfFolder = "C:\Company\Documents"
$reportPath = "C:\Reports\pdf-inventory.csv"

Get-ChildItem -Path $pdfFolder -Filter "*.pdf" -Recurse | ForEach-Object {
    $info = Get-PdfInfo -FilePath $_.FullName

    [PSCustomObject]@{
        FileName = $_.Name
        Folder = $_.Directory.Name
        FullPath = $_.FullName
        PageCount = $info.PageCount
        Title = $info.Title
        Author = $info.Author
        Created = $info.CreationDate
        FileSizeMB = [Math]::Round($_.Length / 1MB, 2)
        IsEncrypted = $info.IsEncrypted
    }
} | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "Inventory saved to: $reportPath"
```

#### Installation

1. Copy the `PdfTextReader.psm1` file to your PowerShell modules directory or project
2. Install iTextSharp library (see Setup Instructions above)
3. Import the module in your script:
   ```powershell
   Import-Module ".\Modules\PdfTextReader.psm1"
   ```

#### Testing

Run the example scripts:

```powershell
.\Examples\Use-PdfTextReader.ps1
.\Examples\Use-PdfTextReader-Batch.ps1
```

#### Common Use Cases

- **Invoice Processing**: Extract invoice numbers, amounts, and dates
- **Report Analysis**: Convert PDF reports to text for data analysis
- **Contract Review**: Search for specific terms and clauses
- **Archive Management**: Create searchable text indexes
- **Form Processing**: Extract data from PDF forms
- **Compliance**: Search documents for required information
- **Data Migration**: Convert legacy PDF documents to text

#### Troubleshooting

**"Could not load file or assembly 'itextsharp'"**
- The DLL is not in a recognized location
- Run `Install-PdfReaderLibrary` to see where to place it

**"This method can be called only from a trusted context"**
- The DLL is blocked. Run: `Unblock-File -Path "path\to\itextsharp.dll"`

**"PDF appears to be corrupted"**
- The PDF may be damaged or password-protected
- Try opening in Adobe Reader first

**No text extracted**
- PDF may contain scanned images instead of text
- Consider using OCR tools for image-based PDFs

#### Limitations

- **Image-based PDFs**: Cannot extract text from scanned documents (requires OCR)
- **Password-protected PDFs**: Cannot read encrypted/protected PDFs
- **Complex Layouts**: Text extraction follows PDF's internal structure, which may differ from visual layout
- **Special Fonts**: Some custom fonts may not extract correctly

#### License Note

iTextSharp 5.5.13.3 is licensed under AGPL/LGPL. Ensure your usage complies with the license terms. Commercial licenses are available from iText.

---

## Getting Started

1. Clone or download this repository
2. Import the desired module using `Import-Module`
3. Refer to the examples in the `Examples` directory
4. Use `Get-Help <Function-Name> -Full` for detailed help on any function

## Contributing

This is a modular script repository designed for reusability. Each module should:
- Be self-contained and independent
- Work with PowerShell 5.0+
- Include comprehensive error handling
- Provide detailed help documentation
- Include usage examples

## License

These scripts are provided as-is for use in your projects.
