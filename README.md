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
