<#
.SYNOPSIS
    Example: REST API authentication using OAuth 2.0 Client Credentials

.DESCRIPTION
    Demonstrates how to use the RestApiAuth module with OAuth 2.0 authentication.
    Uses the Client Credentials flow with automatic token refresh.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\RestApiAuth.psm1"
Import-Module $modulePath -Force

Write-Host "=== REST API OAuth 2.0 Authentication Example ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Create session with OAuth 2.0
Write-Host "Example 1: Creating session with OAuth 2.0 Client Credentials" -ForegroundColor Yellow

$oauth2Config = @{
    ClientId = "your-client-id"
    ClientSecret = "your-client-secret"
    TokenEndpoint = "https://auth.example.com/oauth/token"
    Scope = "api:read api:write"
}

Write-Host "OAuth2 Configuration:" -ForegroundColor Gray
Write-Host "  Client ID: $($oauth2Config.ClientId)" -ForegroundColor Gray
Write-Host "  Token Endpoint: $($oauth2Config.TokenEndpoint)" -ForegroundColor Gray
Write-Host "  Scope: $($oauth2Config.Scope)" -ForegroundColor Gray
Write-Host ""

Write-Host "Creating OAuth2 session (this would obtain a token):" -ForegroundColor Gray
Write-Host '  $session = New-RestApiSession -BaseUri "https://api.example.com" `' -ForegroundColor Gray
Write-Host '                                 -AuthMethod OAuth2 `' -ForegroundColor Gray
Write-Host '                                 -OAuth2Config $oauth2Config' -ForegroundColor Gray
Write-Host ""

# Example 2: OAuth2 config from answer file
Write-Host "Example 2: Loading OAuth2 config from answer file" -ForegroundColor Yellow

# Create sample OAuth2 config file
$oauth2ConfigFile = Join-Path $PSScriptRoot "oauth2-config.json"
$sampleConfig = @{
    ClientId = "app-client-id-12345"
    ClientSecret = "secret-key-67890"
    TokenEndpoint = "https://oauth.example.com/v2/token"
    Scope = "user.read user.write"
    ApiBaseUri = "https://api.example.com/v2"
} | ConvertTo-Json

$sampleConfig | Out-File -FilePath $oauth2ConfigFile -Force

Write-Host "OAuth2 config file created at: $oauth2ConfigFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Loading config from file:" -ForegroundColor Gray

# Load config from file
$configJson = Get-Content -Path $oauth2ConfigFile -Raw | ConvertFrom-Json

$oauth2Config = @{
    ClientId = $configJson.ClientId
    ClientSecret = $configJson.ClientSecret
    TokenEndpoint = $configJson.TokenEndpoint
    Scope = $configJson.Scope
}

Write-Host "Config loaded successfully" -ForegroundColor Green
Write-Host ""

# Example 3: Automatic token refresh
Write-Host "Example 3: Automatic token refresh" -ForegroundColor Yellow

Write-Host "The module automatically handles token refresh:" -ForegroundColor Gray
Write-Host "1. When creating session, obtains initial access token" -ForegroundColor Gray
Write-Host "2. Stores token expiry time" -ForegroundColor Gray
Write-Host "3. Before each API call, checks if token is expired" -ForegroundColor Gray
Write-Host "4. If expired, automatically requests new token" -ForegroundColor Gray
Write-Host "5. Updates session with new token transparently" -ForegroundColor Gray
Write-Host ""

Write-Host "Example usage:" -ForegroundColor Gray
Write-Host '  $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod OAuth2 -OAuth2Config $oauth2Config' -ForegroundColor Gray
Write-Host '  # Make requests - token refresh happens automatically' -ForegroundColor Gray
Write-Host '  $data1 = Invoke-RestApiRequest -Session $session -Endpoint "/data"  # Uses token 1' -ForegroundColor Gray
Write-Host '  Start-Sleep -Seconds 3600  # Wait for token to expire' -ForegroundColor Gray
Write-Host '  $data2 = Invoke-RestApiRequest -Session $session -Endpoint "/data"  # Automatically gets new token' -ForegroundColor Gray
Write-Host ""

# Example 4: Multiple OAuth2 providers
Write-Host "Example 4: Different OAuth2 provider configurations" -ForegroundColor Yellow
Write-Host ""

# Azure AD / Microsoft Identity Platform
Write-Host "Azure AD OAuth2:" -ForegroundColor Cyan
$azureConfig = @{
    ClientId = "azure-app-client-id"
    ClientSecret = "azure-app-client-secret"
    TokenEndpoint = "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token"
    Scope = "https://graph.microsoft.com/.default"
}
Write-Host "  Token Endpoint: $($azureConfig.TokenEndpoint)" -ForegroundColor Gray
Write-Host "  Scope: $($azureConfig.Scope)" -ForegroundColor Gray
Write-Host ""

# Auth0
Write-Host "Auth0 OAuth2:" -ForegroundColor Cyan
$auth0Config = @{
    ClientId = "auth0-client-id"
    ClientSecret = "auth0-client-secret"
    TokenEndpoint = "https://your-domain.auth0.com/oauth/token"
    Scope = "read:users write:users"
}
Write-Host "  Token Endpoint: $($auth0Config.TokenEndpoint)" -ForegroundColor Gray
Write-Host "  Scope: $($auth0Config.Scope)" -ForegroundColor Gray
Write-Host ""

# Okta
Write-Host "Okta OAuth2:" -ForegroundColor Cyan
$oktaConfig = @{
    ClientId = "okta-client-id"
    ClientSecret = "okta-client-secret"
    TokenEndpoint = "https://your-domain.okta.com/oauth2/default/v1/token"
    Scope = "custom_scope"
}
Write-Host "  Token Endpoint: $($oktaConfig.TokenEndpoint)" -ForegroundColor Gray
Write-Host "  Scope: $($oktaConfig.Scope)" -ForegroundColor Gray
Write-Host ""

# Example 5: Real-world Microsoft Graph API example
Write-Host "Example 5: Microsoft Graph API integration" -ForegroundColor Yellow
Write-Host ""

function Get-AzureADUsers {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret,

        [Parameter(Mandatory = $false)]
        [int]$Top = 10
    )

    try {
        # Configure OAuth2 for Microsoft Graph
        $oauth2Config = @{
            ClientId = $ClientId
            ClientSecret = $ClientSecret
            TokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
            Scope = "https://graph.microsoft.com/.default"
        }

        Write-Host "Authenticating with Azure AD..." -ForegroundColor Gray

        # Create session with OAuth2
        $session = New-RestApiSession -BaseUri "https://graph.microsoft.com/v1.0" `
                                       -AuthMethod OAuth2 `
                                       -OAuth2Config $oauth2Config

        Write-Host "Authentication successful" -ForegroundColor Green

        # Get users from Azure AD
        Write-Host "Fetching users from Azure AD..." -ForegroundColor Gray

        $params = @{
            '$top' = $Top
            '$select' = 'displayName,userPrincipalName,mail'
        }

        $users = Invoke-RestApiRequest -Session $session `
                                        -Endpoint "/users" `
                                        -Method GET `
                                        -QueryParameters $params

        Write-Host "Retrieved $($users.value.Count) users" -ForegroundColor Green

        # Display users
        $users.value | ForEach-Object {
            Write-Host "  - $($_.displayName) ($($_.userPrincipalName))" -ForegroundColor Gray
        }

        return $users.value
    }
    catch {
        Write-Error "Failed to get Azure AD users: $_"
        return $null
    }
}

Write-Host "Function defined: Get-AzureADUsers" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  $users = Get-AzureADUsers -TenantId "your-tenant-id" `' -ForegroundColor Gray
Write-Host '                             -ClientId "your-client-id" `' -ForegroundColor Gray
Write-Host '                             -ClientSecret "your-secret" `' -ForegroundColor Gray
Write-Host '                             -Top 10' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Example Complete ===" -ForegroundColor Cyan

# Clean up sample file
if (Test-Path $oauth2ConfigFile) {
    Remove-Item -Path $oauth2ConfigFile -Force
}
