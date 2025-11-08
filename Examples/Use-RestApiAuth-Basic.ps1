<#
.SYNOPSIS
    Example: REST API authentication using Basic Authentication

.DESCRIPTION
    Demonstrates how to use the RestApiAuth module with Basic Authentication.
    Basic auth uses username and password encoded in base64.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\RestApiAuth.psm1"
Import-Module $modulePath -Force

Write-Host "=== REST API Basic Authentication Example ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Create session with Basic Auth
Write-Host "Example 1: Creating session with Basic Authentication" -ForegroundColor Yellow

# Create credentials
$username = "api-user"
$password = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Create authenticated session
$session = New-RestApiSession -BaseUri "https://api.example.com" `
                               -AuthMethod Basic `
                               -Credential $credential

Write-Host "Session created successfully" -ForegroundColor Green
Write-Host "Base URI: $($session.BaseUri)"
Write-Host "Auth Method: $($session.AuthMethod)"
Write-Host ""

# Example 2: Using Get-Credential for interactive input
Write-Host "Example 2: Interactive credential input" -ForegroundColor Yellow
Write-Host "In production, you would use:" -ForegroundColor Gray
Write-Host '  $cred = Get-Credential -Message "Enter API credentials"' -ForegroundColor Gray
Write-Host '  $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Basic -Credential $cred' -ForegroundColor Gray
Write-Host ""

# Example 3: Make API requests
Write-Host "Example 3: Making API requests with Basic Auth session" -ForegroundColor Yellow
Write-Host "Note: These are example API calls and will fail without a real API" -ForegroundColor Gray
Write-Host ""

try {
    # GET request
    Write-Host "GET /users request:" -ForegroundColor Gray
    Write-Host '  $users = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method GET' -ForegroundColor Gray

    # POST request with body
    Write-Host "POST /users request:" -ForegroundColor Gray
    Write-Host '  $newUser = @{ name = "John Doe"; email = "john@example.com" }' -ForegroundColor Gray
    Write-Host '  $response = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method POST -Body $newUser' -ForegroundColor Gray

    # GET with query parameters
    Write-Host "GET /users with query parameters:" -ForegroundColor Gray
    Write-Host '  $params = @{ page = 1; limit = 10; sort = "name" }' -ForegroundColor Gray
    Write-Host '  $users = Invoke-RestApiRequest -Session $session -Endpoint "/users" -QueryParameters $params' -ForegroundColor Gray
}
catch {
    Write-Host "API calls shown as examples (would fail without real API endpoint)" -ForegroundColor Yellow
}
Write-Host ""

# Example 4: Using headers directly without a session
Write-Host "Example 4: Generate headers for one-off requests" -ForegroundColor Yellow

$headers = New-RestApiHeaders -AuthMethod Basic -Credential $credential

Write-Host "Headers generated:"
$headers.GetEnumerator() | ForEach-Object {
    $value = $_.Value
    if ($_.Key -eq 'Authorization') {
        $value = $_.Value.Substring(0, [Math]::Min(20, $_.Value.Length)) + "..."
    }
    Write-Host "  $($_.Key): $value" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Use with Invoke-RestMethod:" -ForegroundColor Gray
Write-Host '  Invoke-RestMethod -Uri "https://api.example.com/users" -Headers $headers' -ForegroundColor Gray
Write-Host ""

# Example 5: Real-world example with error handling
Write-Host "Example 5: Production-ready example with error handling" -ForegroundColor Yellow
Write-Host ""

function Get-ApiUsers {
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ApiBaseUri = "https://api.example.com",

        [Parameter(Mandatory = $false)]
        [int]$PageSize = 50
    )

    try {
        # Create session
        $session = New-RestApiSession -BaseUri $ApiBaseUri `
                                       -AuthMethod Basic `
                                       -Credential $Credential

        # Test connection
        Write-Host "Testing API connection..." -ForegroundColor Gray
        if (-not (Test-RestApiConnection -Session $session -TestEndpoint "/health")) {
            throw "API connection test failed"
        }
        Write-Host "Connection successful" -ForegroundColor Green

        # Get users
        Write-Host "Fetching users..." -ForegroundColor Gray
        $queryParams = @{ limit = $PageSize }
        $users = Invoke-RestApiRequest -Session $session `
                                        -Endpoint "/users" `
                                        -Method GET `
                                        -QueryParameters $queryParams

        Write-Host "Retrieved $($users.Count) users" -ForegroundColor Green
        return $users
    }
    catch {
        Write-Error "Failed to get users: $_"
        return $null
    }
}

Write-Host "Function defined: Get-ApiUsers" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  $cred = Get-Credential' -ForegroundColor Gray
Write-Host '  $users = Get-ApiUsers -Credential $cred -ApiBaseUri "https://api.example.com"' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Example Complete ===" -ForegroundColor Cyan
