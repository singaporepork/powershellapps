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
- **iText 7 Integration**: Uses proven PDF library for reliable text extraction

#### Requirements

**Dependency**: iText 7 library (itext.kernel.dll and itext.io.dll) - See setup guide below

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

Provides instructions for installing the iText 7 dependency.

```powershell
Install-PdfReaderLibrary
```

#### Setup Instructions

**Step 1: Install iText 7**

Download iText 7 from one of these sources:
- GitHub: https://github.com/itext/itextsharp/releases/tag/5.5.13.3
- NuGet: https://www.nuget.org/packages/iText 7/5.5.13.3

**Step 2: Extract the DLL**

Extract `itext.kernel.dll and itext.io.dll` from the download.

**Step 3: Place the DLL**

Put `itext.kernel.dll and itext.io.dll` in one of these locations:
- `Modules/lib/itext.kernel.dll and itext.io.dll` (recommended)
- `C:\Program Files\iText 7\itext.kernel.dll and itext.io.dll`
- `%USERPROFILE%\Documents\PowerShell\Modules\iText 7\itext.kernel.dll and itext.io.dll`

**Step 4: Unblock the DLL** (if downloaded from web)

```powershell
Unblock-File -Path ".\Modules\lib\itext.kernel.dll and itext.io.dll"
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
2. Install iText 7 library (see Setup Instructions above)
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
- The DLL is blocked. Run: `Unblock-File -Path "path\to\itext.kernel.dll and itext.io.dll"`

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

iText 7 is licensed under AGPL v3. Ensure your usage complies with the license terms. Commercial licenses are available from iText.

---

### TextToJson

A comprehensive module for converting various text formats to JSON.

#### Features

- **Multiple Format Support**: Convert CSV, INI, XML, key-value pairs, and delimited text to JSON
- **Automatic Type Conversion**: Intelligently converts numbers, booleans, and strings
- **Nested Structures**: Supports nested objects from dot-notation and INI sections
- **JSON Formatting**: Pretty-print or compress JSON output
- **JSON Validation**: Test if strings are valid JSON
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **Flexible Options**: Custom delimiters, headers, and encoding support

#### Functions

##### ConvertTo-JsonFromCsv

Converts CSV data to JSON format.

```powershell
# From file
$json = ConvertTo-JsonFromCsv -FilePath "data.csv" -Pretty

# From text
$csvText = "Name,Age`nJohn,30`nJane,25"
$json = ConvertTo-JsonFromCsv -CsvText $csvText -Pretty

# Tab-delimited
$json = ConvertTo-JsonFromCsv -FilePath "data.tsv" -Delimiter "`t" -Pretty
```

##### ConvertTo-JsonFromKeyValue

Converts key-value pairs to JSON.

```powershell
# Simple key-value
$text = "name=John`nage=30`nemail=john@example.com"
$json = ConvertTo-JsonFromKeyValue -Text $text -Pretty

# Nested keys
$text = "user.name=John`nuser.age=30`naddress.city=NYC"
$json = ConvertTo-JsonFromKeyValue -Text $text -NestedSeparator '.' -Pretty
```

##### ConvertTo-JsonFromIni

Converts INI files to JSON.

```powershell
$json = ConvertTo-JsonFromIni -FilePath "config.ini" -Pretty
```

##### ConvertTo-JsonFromDelimitedText

Converts custom delimited text to JSON.

```powershell
# Pipe-delimited
$headers = @('Name', 'Age', 'City')
$json = ConvertTo-JsonFromDelimitedText -FilePath "data.txt" -Delimiter '|' -Headers $headers -Pretty

# Space-delimited with regex
$json = ConvertTo-JsonFromDelimitedText -Text $data -Delimiter '\s+' -Headers $headers -Pretty
```

##### ConvertTo-JsonFromXml

Converts XML to JSON.

```powershell
$json = ConvertTo-JsonFromXml -FilePath "data.xml" -Pretty
```

##### ConvertTo-JsonFromObject

Converts PowerShell objects/hashtables to JSON.

```powershell
$hashtable = @{ Name = "John"; Age = 30; Skills = @("PowerShell", "Python") }
$json = ConvertTo-JsonFromObject -InputObject $hashtable -Pretty
```

##### Format-JsonText

Formats JSON with proper indentation.

```powershell
$minified = '{"name":"John","age":30}'
$formatted = Format-JsonText -Json $minified
```

##### Test-JsonText

Validates if a string is valid JSON.

```powershell
if (Test-JsonText -Json $jsonString) {
    Write-Host "Valid JSON"
}
```

##### Export-ToJsonFile

Exports data to a JSON file.

```powershell
$data = @{ Name = "John"; Age = 30 }
Export-ToJsonFile -InputObject $data -FilePath "output.json" -Pretty -Force
```

#### Usage Examples

##### Example 1: Convert CSV to JSON

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Read CSV file and convert to JSON
$json = ConvertTo-JsonFromCsv -FilePath "C:\data\employees.csv" -Pretty

# Save to file
$json | Out-File -FilePath "C:\data\employees.json" -Encoding UTF8
```

##### Example 2: Migrate INI Configuration to JSON

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Convert old INI config to modern JSON
$json = ConvertTo-JsonFromIni -FilePath "C:\config\app.ini" -Pretty

# Save new configuration
$json | Out-File -FilePath "C:\config\app.json" -Encoding UTF8

Write-Host "Configuration migrated to JSON format"
```

##### Example 3: Build JSON from Nested Key-Value Data

```powershell
Import-Module ".\Modules\TextToJson.psm1"

$configText = @"
database.host=localhost
database.port=5432
database.name=myapp
api.endpoint=https://api.example.com
api.timeout=30
api.retries=3
"@

$json = ConvertTo-JsonFromKeyValue -Text $configText -NestedSeparator '.' -Pretty

# Result:
# {
#   "database": {
#     "host": "localhost",
#     "port": 5432,
#     "name": "myapp"
#   },
#   "api": {
#     "endpoint": "https://api.example.com",
#     "timeout": 30,
#     "retries": 3
#   }
# }
```

##### Example 4: Convert and Post to API

```powershell
Import-Module ".\Modules\TextToJson.psm1"
Import-Module ".\Modules\RestApiAuth.psm1"

# Convert CSV data to JSON
$json = ConvertTo-JsonFromCsv -FilePath "C:\exports\customers.csv" -Compress

# Post to API
$session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Bearer -Token $token
$response = Invoke-RestApiRequest -Session $session -Endpoint "/import/customers" -Method POST -Body $json

Write-Host "Imported $($response.recordsProcessed) records"
```

##### Example 5: Format and Validate JSON

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Receive minified JSON from API
$minified = Invoke-RestMethod -Uri "https://api.example.com/data"

# Validate
if (Test-JsonText -Json $minified) {
    # Format for readability
    $formatted = Format-JsonText -Json $minified

    # Save to file
    $formatted | Out-File -FilePath "C:\data\api-response.json" -Encoding UTF8

    Write-Host "JSON validated and formatted"
}
else {
    Write-Host "Invalid JSON received" -ForegroundColor Red
}
```

##### Example 6: Batch Convert Configuration Files

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Convert all INI files in directory to JSON
Get-ChildItem -Path "C:\legacy-configs" -Filter "*.ini" | ForEach-Object {
    $outputPath = $_.FullName -replace '\.ini$', '.json'

    Write-Host "Converting: $($_.Name)..."

    $json = ConvertTo-JsonFromIni -FilePath $_.FullName -Pretty
    $json | Out-File -FilePath $outputPath -Encoding UTF8

    Write-Host "  Saved to: $outputPath" -ForegroundColor Green
}

Write-Host "Batch conversion complete!"
```

##### Example 7: System Inventory to JSON

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Collect system information
$systemInfo = @{
    ComputerName = $env:COMPUTERNAME
    OSVersion = [System.Environment]::OSVersion.VersionString
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Memory = @{
        TotalGB = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    Processors = (Get-CimInstance Win32_Processor).Name
    Disks = Get-PSDrive -PSProvider FileSystem | Select-Object Name,
        @{Name='UsedGB';Expression={[Math]::Round($_.Used/1GB,2)}},
        @{Name='FreeGB';Expression={[Math]::Round($_.Free/1GB,2)}}
}

# Export as JSON
Export-ToJsonFile -InputObject $systemInfo -FilePath "C:\reports\system-inventory.json" -Pretty -Force

Write-Host "System inventory exported to JSON"
```

##### Example 8: Parse Log Data to JSON

```powershell
Import-Module ".\Modules\TextToJson.psm1"

# Parse pipe-delimited log file
$logFile = @"
2024-01-15 10:30:15|INFO|Application started|UserService
2024-01-15 10:30:16|INFO|Database connected|DataLayer
2024-01-15 10:31:20|ERROR|Failed to process request|OrderService
2024-01-15 10:31:25|WARN|Retry attempt 1|OrderService
"@

$headers = @('Timestamp', 'Level', 'Message', 'Component')
$json = ConvertTo-JsonFromDelimitedText -Text $logFile -Delimiter '\|' -Headers $headers -Pretty

# Now you can analyze logs as structured JSON
$logs = $json | ConvertFrom-Json
$errors = $logs | Where-Object { $_.Level -eq 'ERROR' }

Write-Host "Found $($errors.Count) error(s) in logs"
```

#### Installation

1. Copy the `TextToJson.psm1` file to your PowerShell modules directory or project
2. Import the module in your script:
   ```powershell
   Import-Module ".\Modules\TextToJson.psm1"
   ```

#### Testing

Run the example script:

```powershell
.\Examples\Use-TextToJson.ps1
```

#### Common Use Cases

- **Configuration Migration**: Convert INI/XML configs to JSON for modern applications
- **Data Export**: Convert CSV exports to JSON for API consumption
- **Log Parsing**: Transform structured log files to JSON for analysis
- **API Integration**: Format data as JSON payloads for REST APIs
- **Documentation**: Convert structured text documentation to JSON
- **Data Transformation**: Normalize data from various formats to JSON
- **Automation**: Build JSON configs from PowerShell scripts
- **Reporting**: Export system information as JSON for dashboards

#### Type Conversion

The module automatically converts values:
- **Numbers**: `"123"` → `123`, `"45.67"` → `45.67`
- **Booleans**: `"true"`/`"false"` → `true`/`false`
- **Strings**: All other values remain as strings

#### Best Practices

1. **Use -Pretty for Files**: Always use `-Pretty` for human-readable JSON files
2. **Use -Compress for APIs**: Omit `-Pretty` or use `-Compress` for API payloads
3. **Validate JSON**: Use `Test-JsonText` before consuming JSON
4. **Handle Encoding**: Always specify UTF8 encoding when writing files
5. **Test First**: Validate conversions with sample data before batch operations

---

### UnixTimeConverter

A comprehensive module for converting between DateTime objects and Unix timestamps.

#### Features

- **Bidirectional Conversion**: DateTime to Unix time and vice versa
- **Multiple Precision Levels**: Seconds, milliseconds, and microseconds
- **Timezone Handling**: Automatic UTC conversion with local time support
- **Time Arithmetic**: Add/subtract time from timestamps
- **Validation**: Test if values are valid Unix timestamps
- **Formatting**: Convert timestamps to readable date strings
- **Batch Operations**: Convert multiple dates efficiently
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **Pipeline Support**: Full pipeline integration

#### Functions

##### ConvertTo-UnixTime
Converts DateTime objects to Unix timestamps.

##### ConvertFrom-UnixTime
Converts Unix timestamps to DateTime objects.

##### Get-UnixTime
Gets the current Unix timestamp.

##### ConvertTo-UnixTimeFromString
Parses date strings and converts to Unix timestamps.

##### Format-UnixTimestamp
Formats Unix timestamps as readable strings.

##### Test-UnixTimestamp
Validates if a number is a reasonable Unix timestamp.

##### Get-TimeDifference
Calculates time differences between dates.

##### Add-UnixTime
Performs time arithmetic on Unix timestamps.

##### Get-UnixDayBoundary
Gets the start or end of day for a timestamp.

##### ConvertTo-UnixTimeBatch
Converts multiple dates at once.

#### Quick Examples

```powershell
Import-Module ".\Modules\UnixTimeConverter.psm1"

# Get current Unix timestamp
$now = Get-UnixTime

# Convert date to Unix time
$timestamp = ConvertTo-UnixTime -DateTime (Get-Date "2024-01-15 10:30:00")

# Convert Unix time back to DateTime
$date = ConvertFrom-UnixTime -Timestamp 1705315800 -ToLocalTime

# Format Unix timestamp
$formatted = Format-UnixTimestamp -Timestamp 1705315800
# Output: 2024-01-15 10:30:00

# Parse date string
$timestamp = ConvertTo-UnixTimeFromString -DateString "2024-12-25"

# Add time to timestamp
$future = Add-UnixTime -Timestamp $now -Days 7 -Hours 2

# Get time difference
$days = Get-TimeDifference -StartDate $start -EndDate $end -Unit Days
```

#### Common Use Cases

- **API Integration**: Send/receive timestamps in Unix format
- **Log Processing**: Parse and analyze logs with Unix timestamps
- **Database Operations**: Query time-based data efficiently
- **Authentication**: Token expiry and session management
- **File Management**: Work with file metadata as timestamps
- **Scheduling**: Calculate future execution times

For detailed examples and documentation, see `Examples/unix-time-guide.md`

---

### ScheduledTaskUpdater

A comprehensive module for managing and updating Windows Scheduled Tasks.

#### Features

- **Task Management**: Get, update, enable, disable, start, and stop scheduled tasks
- **Trigger Updates**: Modify when tasks run (daily, weekly, at startup, at logon)
- **Action Updates**: Change what the task executes
- **Principal Updates**: Modify security context (user account, privileges)
- **Settings Updates**: Configure task behavior (timeouts, retries, battery options)
- **Bulk Operations**: List tasks by path, process multiple tasks
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later
- **WhatIf Support**: Test changes before applying them

#### Requirements

- Windows operating system
- Administrator privileges (for most operations)
- ScheduledTasks module (built-in on Windows)

#### Functions

##### Test-ScheduledTaskExists

Checks if a scheduled task exists.

```powershell
if (Test-ScheduledTaskExists -TaskName "MyTask") {
    Write-Host "Task exists"
}

# Check in specific path
Test-ScheduledTaskExists -TaskName "Cleanup" -TaskPath "\MyCompany\Scripts\"
```

##### Get-ScheduledTaskInfo

Gets detailed information about a task.

```powershell
$info = Get-ScheduledTaskInfo -TaskName "MyTask"

Write-Host "State: $($info.State)"
Write-Host "Triggers: $($info.Triggers.Count)"
Write-Host "Actions: $($info.Actions[0].Execute)"
```

##### Update-ScheduledTaskTrigger

Updates when the task runs.

```powershell
# Run daily at 9:00 AM
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "09:00"

# Run weekly on Monday, Wednesday, Friday
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Weekly `
    -StartTime "08:00" -DaysOfWeek Monday, Wednesday, Friday

# Run at system startup
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType AtStartup

# Run at user logon
Update-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType AtLogon
```

##### Add-ScheduledTaskTrigger

Adds a trigger without removing existing triggers.

```powershell
# Add an additional daily trigger
Add-ScheduledTaskTrigger -TaskName "MyTask" -TriggerType Daily -StartTime "14:00"
```

##### Update-ScheduledTaskAction

Updates what the task executes.

```powershell
# Run a PowerShell script
Update-ScheduledTaskAction -TaskName "MyTask" `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -File C:\Scripts\MyScript.ps1"

# Run an executable with working directory
Update-ScheduledTaskAction -TaskName "MyTask" `
    -Execute "C:\App\program.exe" `
    -Argument "--config settings.json" `
    -WorkingDirectory "C:\App"
```

##### Update-ScheduledTaskPrincipal

Updates the security context.

```powershell
# Run as SYSTEM with highest privileges
Update-ScheduledTaskPrincipal -TaskName "MyTask" `
    -UserId "SYSTEM" `
    -RunLevel Highest

# Run as specific user
Update-ScheduledTaskPrincipal -TaskName "MyTask" `
    -UserId "DOMAIN\ServiceAccount" `
    -LogonType Password `
    -RunLevel Limited
```

##### Update-ScheduledTaskSettings

Updates task behavior settings.

```powershell
# Allow on battery and set time limit
Update-ScheduledTaskSettings -TaskName "MyTask" `
    -AllowStartIfOnBatteries $true `
    -ExecutionTimeLimit "PT2H"

# Configure restart on failure
Update-ScheduledTaskSettings -TaskName "MyTask" `
    -RestartCount 3 `
    -RestartInterval "PT10M"

# Start when available, wake to run
Update-ScheduledTaskSettings -TaskName "MyTask" `
    -StartWhenAvailable $true `
    -WakeToRun $true
```

##### Enable/Disable Tasks

```powershell
# Disable a task
Disable-ScheduledTaskState -TaskName "MyTask"

# Enable a task
Enable-ScheduledTaskState -TaskName "MyTask"
```

##### Start/Stop Tasks

```powershell
# Run task immediately
Start-ScheduledTaskNow -TaskName "MyTask"

# Stop running task
Stop-ScheduledTaskNow -TaskName "MyTask"
```

##### Get-ScheduledTasksByPath

Lists all tasks in a folder.

```powershell
# List tasks in custom folder
Get-ScheduledTasksByPath -TaskPath "\MyCompany\Scripts\"

# List recursively
Get-ScheduledTasksByPath -TaskPath "\" -Recurse
```

##### Update-ScheduledTaskDescription

Updates the task description.

```powershell
Update-ScheduledTaskDescription -TaskName "MyTask" `
    -Description "Daily backup - runs at 3 AM"
```

#### Usage Examples

##### Example 1: Complete Task Update

```powershell
Import-Module ".\Modules\ScheduledTaskUpdater.psm1"

$taskName = "DailyBackup"

# Verify task exists
if (Test-ScheduledTaskExists -TaskName $taskName) {
    # Update trigger
    Update-ScheduledTaskTrigger -TaskName $taskName `
        -TriggerType Daily `
        -StartTime "03:00"

    # Update action
    Update-ScheduledTaskAction -TaskName $taskName `
        -Execute "powershell.exe" `
        -Argument "-File C:\Scripts\Backup.ps1"

    # Configure settings
    Update-ScheduledTaskSettings -TaskName $taskName `
        -StartWhenAvailable $true `
        -ExecutionTimeLimit "PT4H" `
        -RestartCount 2

    # Run as SYSTEM
    Update-ScheduledTaskPrincipal -TaskName $taskName `
        -UserId "SYSTEM" `
        -RunLevel Highest

    # Enable the task
    Enable-ScheduledTaskState -TaskName $taskName

    Write-Host "Task updated successfully"
}
```

##### Example 2: Bulk Disable Tasks

```powershell
Import-Module ".\Modules\ScheduledTaskUpdater.psm1"

# Disable all tasks in a folder
$tasks = Get-ScheduledTasksByPath -TaskPath "\OldJobs\"
$tasks | ForEach-Object {
    Disable-ScheduledTaskState -TaskName $_.TaskName -TaskPath $_.TaskPath
    Write-Host "Disabled: $($_.TaskName)"
}
```

##### Example 3: Generate Task Report

```powershell
Import-Module ".\Modules\ScheduledTaskUpdater.psm1"

# Get all tasks in company folder
$tasks = Get-ScheduledTasksByPath -TaskPath "\MyCompany\" -Recurse

# Generate report
$report = $tasks | ForEach-Object {
    $info = Get-ScheduledTaskInfo -TaskName $_.TaskName -TaskPath $_.TaskPath

    [PSCustomObject]@{
        Name = $_.TaskName
        Path = $_.TaskPath
        State = $_.State
        Triggers = $info.Triggers.Count
        RunLevel = $info.Principal.RunLevel
    }
}

$report | Export-Csv -Path "C:\Reports\tasks.csv" -NoTypeInformation
```

#### Time Duration Format

Task scheduler uses ISO 8601 duration format:

| Format | Meaning |
|--------|---------|
| `PT0S` | No limit |
| `PT30M` | 30 minutes |
| `PT1H` | 1 hour |
| `PT2H30M` | 2 hours 30 minutes |
| `P1D` | 1 day |

#### Installation

1. Copy `ScheduledTaskUpdater.psm1` to your modules directory
2. Import the module:
   ```powershell
   Import-Module ".\Modules\ScheduledTaskUpdater.psm1"
   ```

#### Testing

Run the example script:

```powershell
.\Examples\ScheduledTaskUpdater-Examples.ps1
```

#### Common Use Cases

- **Deployment Automation**: Update task schedules during deployments
- **Maintenance Windows**: Temporarily disable tasks during maintenance
- **Security Hardening**: Update principals to use least privilege
- **Monitoring**: Generate reports of all scheduled tasks
- **Migration**: Bulk update tasks when moving servers
- **Compliance**: Ensure tasks meet organizational standards

#### Troubleshooting

**"Access Denied" Error**
- Run PowerShell as Administrator

**Task Not Found**
- Verify task name and path
- Use `Get-ScheduledTasksByPath` to list available tasks

**Invalid Duration Format**
- Use ISO 8601: `PT` for time, `P` for periods

For detailed documentation, see `Modules/SCHEDULEDTASK_GUIDE.md`

---

### Logger

A comprehensive logging module with multiple output targets and log levels.

#### Features

- **Multiple Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Multiple Outputs**: Console, file, or both
- **Log Rotation**: Automatic rotation based on file size
- **Colored Output**: Color-coded console messages
- **Exception Logging**: Include exception details in logs
- **Operation Tracking**: Track start/completion of operations
- **Thread-Safe**: Safe for concurrent file access
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later

#### Functions

##### Initialize-Logger

Sets up logging configuration.

```powershell
# Console only
Initialize-Logger -LogLevel INFO -LogToConsole $true

# File and console
Initialize-Logger -LogPath "C:\Logs\app.log" `
    -LogLevel DEBUG `
    -LogToConsole $true `
    -LogToFile $true `
    -MaxFileSizeMB 10 `
    -MaxLogFiles 5
```

##### Log Level Functions

```powershell
Write-LogDebug "Debug information"
Write-LogInfo "Application started"
Write-LogWarning "Configuration missing, using defaults"
Write-LogError "Failed to connect to database"
Write-LogCritical "System failure - shutting down"
```

##### Write-LogMessage

Core function with full control.

```powershell
Write-LogMessage -Message "Custom message" -Level WARNING

# With exception
try { ... } catch {
    Write-LogMessage -Message "Operation failed" -Level ERROR -Exception $_.Exception
}
```

##### Write-LogError with Exception

```powershell
try {
    Get-Content "missing.txt" -ErrorAction Stop
}
catch {
    Write-LogError "File read failed" -Exception $_.Exception
}
```

##### Operation Tracking

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Start-LogOperation "Database Backup"

# ... perform backup ...

$stopwatch.Stop()
Complete-LogOperation "Database Backup" -Success $true -Duration $stopwatch.Elapsed
```

##### Headers and Separators

```powershell
Write-LogHeader "Application Startup"
Write-LogSeparator
Write-LogSeparator -Character "=" -Length 80
```

##### Log Object Properties

```powershell
$config = @{ Server = "localhost"; Port = 8080 }
Write-LogObject -InputObject $config -Name "Configuration"
```

##### Read Log Entries

```powershell
# Get last 50 entries
Get-LogEntries -Last 50

# Get errors only
Get-LogEntries -Level ERROR

# Get entries since time
Get-LogEntries -Since (Get-Date).AddHours(-1)

# Get as objects
Get-LogEntries -AsObject | Where-Object { $_.Level -eq 'ERROR' }
```

##### Log File Management

```powershell
# Get current log path
$path = Get-LogFilePath

# Get file size info
$size = Get-LogFileSize
Write-Host "Size: $($size.SizeMB) MB ($($size.PercentUsed)% of max)"

# Rotate logs manually
Invoke-LogRotation

# Clear log file
Clear-LogFile
Clear-LogFile -Archive  # Archive before clearing
```

##### Dynamic Log Level

```powershell
# Change level at runtime
Set-LogLevel -Level DEBUG

# Get current config
$config = Get-LoggerConfig
```

#### Usage Example

```powershell
Import-Module ".\Modules\Logger.psm1"

# Initialize
Initialize-Logger -LogPath "C:\Logs\myapp.log" `
    -LogLevel INFO `
    -LogToConsole $true `
    -LogToFile $true

# Application logging
Write-LogHeader "Application Started"

$config = @{ Environment = "Production"; Version = "2.0" }
Write-LogObject -InputObject $config -Name "Config"

Start-LogOperation "Data Processing"
try {
    Write-LogInfo "Processing records..."
    # ... process data ...
    Complete-LogOperation "Data Processing" -Success $true
}
catch {
    Write-LogError "Processing failed" -Exception $_.Exception
    Complete-LogOperation "Data Processing" -Success $false
}

Write-LogHeader "Application Shutdown"
```

#### Log Output Format

Default format: `[timestamp] [level] message`

```
[2024-01-15 10:30:45] [INFO    ] Application started
[2024-01-15 10:30:46] [WARNING ] Configuration not found
[2024-01-15 10:30:47] [ERROR   ] Connection failed
```

#### Installation

1. Copy `Logger.psm1` to your modules directory
2. Import the module:
   ```powershell
   Import-Module ".\Modules\Logger.psm1"
   ```

#### Testing

Run the example script:

```powershell
.\Examples\Logger-Examples.ps1
```

#### Common Use Cases

- **Application Logging**: Track application events and errors
- **Script Debugging**: Enable DEBUG level during development
- **Audit Trails**: Log important operations to file
- **Error Tracking**: Capture exceptions with stack traces
- **Performance Monitoring**: Track operation durations

---

### StringEncryption

A comprehensive module for string and file encryption, decryption, and security operations.

#### Features

- **AES Encryption**: 128/192/256-bit AES encryption for strings and files
- **DPAPI Support**: Windows Data Protection API for user/machine-bound encryption
- **SecureString Handling**: Convert between SecureString and encrypted strings
- **Key Management**: Generate, export, import encryption keys
- **Hashing**: SHA256, SHA384, SHA512, MD5, SHA1 hash generation
- **Password Generation**: Cryptographically secure random passwords
- **File Encryption**: Encrypt and decrypt entire files
- **PowerShell 5 Compatible**: Works with PowerShell 5.0 and later

#### Functions

##### Key Management

```powershell
# Generate a new key
$key = New-EncryptionKey -KeySize 256
$keyBase64 = New-EncryptionKey -KeySize 256 -AsBase64

# Export key to file
Export-EncryptionKey -Key $key -FilePath "C:\Keys\app.key"
Export-EncryptionKey -Key $key -FilePath "C:\Keys\app.key" -ProtectWithDPAPI

# Import key from file
$key = Import-EncryptionKey -FilePath "C:\Keys\app.key"
$key = Import-EncryptionKey -FilePath "C:\Keys\app.key" -ProtectedWithDPAPI
```

##### AES String Encryption

```powershell
# Encrypt a string
$encrypted = Protect-String -PlainText "Secret message" -Key $key

# Decrypt a string
$plainText = Unprotect-String -EncryptedText $encrypted -Key $key

# Pipeline support
$secrets = @("Secret1", "Secret2") | Protect-String -Key $key
```

##### DPAPI Encryption

```powershell
# Encrypt with DPAPI (user/machine bound)
$encrypted = Protect-StringWithDPAPI -PlainText "Secret" -Scope CurrentUser

# Decrypt
$plainText = Unprotect-StringWithDPAPI -EncryptedText $encrypted
```

##### SecureString Operations

```powershell
# Create SecureString from text
$secure = New-SecureStringFromPlainText -PlainText "Password"

# Convert to encrypted string (portable)
$encrypted = ConvertTo-EncryptedString -SecureString $secure -Key $key

# Convert back to SecureString
$secure = ConvertFrom-EncryptedString -EncryptedString $encrypted -Key $key

# Get plain text from SecureString
$plainText = Get-PlainTextFromSecureString -SecureString $secure
```

##### Hashing

```powershell
# Generate hash
$hash = Get-StringHash -InputString "Hello World" -Algorithm SHA256

# Verify hash
$isValid = Test-StringHash -InputString "Hello World" -Hash $hash
```

##### Password Generation

```powershell
# Generate random password
$password = New-RandomPassword -Length 16

# With special characters
$password = New-RandomPassword -Length 20 -IncludeSpecial

# Exclude ambiguous characters (0, O, l, 1, I)
$password = New-RandomPassword -Length 16 -ExcludeAmbiguous

# As SecureString
$secure = New-RandomPassword -AsSecureString
```

##### File Encryption

```powershell
# Encrypt a file
Protect-File -FilePath "C:\data.txt" -Key $key -OutputPath "C:\data.enc"

# Decrypt a file
Unprotect-File -FilePath "C:\data.enc" -Key $key -OutputPath "C:\data.txt"

# Delete original after encryption
Protect-File -FilePath "C:\data.txt" -Key $key -DeleteOriginal
```

##### Utility Functions

```powershell
# Test if data appears encrypted
if (Test-EncryptedString -InputString $data) {
    Write-Host "Data is encrypted"
}
```

#### Usage Example

```powershell
Import-Module ".\Modules\StringEncryption.psm1"

# Generate and save encryption key
$key = New-EncryptionKey -KeySize 256
Export-EncryptionKey -Key $key -FilePath "C:\Keys\app.key" -ProtectWithDPAPI

# Encrypt sensitive data
$apiKey = "sk-1234567890abcdef"
$encrypted = Protect-String -PlainText $apiKey -Key $key

# Store encrypted value in config
@{
    ApiKey = $encrypted
    Endpoint = "https://api.example.com"
} | ConvertTo-Json | Set-Content "config.json"

# Later, retrieve and decrypt
$key = Import-EncryptionKey -FilePath "C:\Keys\app.key" -ProtectedWithDPAPI
$config = Get-Content "config.json" | ConvertFrom-Json
$apiKey = Unprotect-String -EncryptedText $config.ApiKey -Key $key
```

#### Password Storage Example

```powershell
Import-Module ".\Modules\StringEncryption.psm1"

# Registration - store hash only
$password = "UserPassword123!"
$hash = Get-StringHash -InputString $password -Algorithm SHA256

# Login - verify against hash
$loginAttempt = Read-Host "Enter password"
if (Test-StringHash -InputString $loginAttempt -Hash $hash) {
    Write-Host "Login successful"
}
```

#### Installation

1. Copy `StringEncryption.psm1` to your modules directory
2. Import the module:
   ```powershell
   Import-Module ".\Modules\StringEncryption.psm1"
   ```

#### Testing

Run the example script:

```powershell
.\Examples\StringEncryption-Examples.ps1
```

#### Common Use Cases

- **Credential Storage**: Securely store API keys and passwords
- **Configuration Files**: Encrypt sensitive config values
- **File Protection**: Encrypt sensitive documents
- **Password Management**: Generate and verify passwords
- **Data Integrity**: Hash data for verification
- **Secure Communication**: Encrypt data before transmission

#### Security Best Practices

- Use 256-bit keys for AES encryption
- Store keys separately from encrypted data
- Use DPAPI for keys that don't need to be portable
- Hash passwords instead of encrypting them
- Rotate encryption keys periodically
- Never log or display decrypted sensitive data

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
