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
