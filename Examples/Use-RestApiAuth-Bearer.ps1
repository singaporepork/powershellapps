<#
.SYNOPSIS
    Example: REST API authentication using Bearer Token

.DESCRIPTION
    Demonstrates how to use the RestApiAuth module with Bearer Token authentication.
    Bearer tokens are commonly used for JWT and personal access tokens.
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\RestApiAuth.psm1"
Import-Module $modulePath -Force

Write-Host "=== REST API Bearer Token Authentication Example ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Create session with Bearer Token
Write-Host "Example 1: Creating session with Bearer Token" -ForegroundColor Yellow

$bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example.token"

$session = New-RestApiSession -BaseUri "https://api.github.com" `
                               -AuthMethod Bearer `
                               -Token $bearerToken

Write-Host "Session created successfully" -ForegroundColor Green
Write-Host "Base URI: $($session.BaseUri)"
Write-Host "Auth Method: $($session.AuthMethod)"
Write-Host "Authorization Header: Bearer ****" -ForegroundColor Gray
Write-Host ""

# Example 2: Reading token from file
Write-Host "Example 2: Reading token from secure file" -ForegroundColor Yellow

# In production, you might store token in a file
$tokenFilePath = Join-Path $env:TEMP "api-token.txt"

# Simulated token file content
"your-secret-bearer-token-here" | Out-File -FilePath $tokenFilePath -Force

Write-Host "Token file created at: $tokenFilePath" -ForegroundColor Gray

# Read token from file
$token = Get-Content -Path $tokenFilePath -Raw
$token = $token.Trim()

$session = New-RestApiSession -BaseUri "https://api.example.com" `
                               -AuthMethod Bearer `
                               -Token $token

Write-Host "Session created from token file" -ForegroundColor Green

# Clean up
Remove-Item -Path $tokenFilePath -Force
Write-Host ""

# Example 3: Making API requests with Bearer token
Write-Host "Example 3: Making API requests" -ForegroundColor Yellow

try {
    # GET request
    Write-Host "Example GET request:" -ForegroundColor Gray
    Write-Host '  $repos = Invoke-RestApiRequest -Session $session -Endpoint "/user/repos"' -ForegroundColor Gray

    # POST with JSON body
    Write-Host ""
    Write-Host "Example POST request:" -ForegroundColor Gray
    Write-Host '  $newRepo = @{' -ForegroundColor Gray
    Write-Host '      name = "my-new-repo"' -ForegroundColor Gray
    Write-Host '      description = "Created via API"' -ForegroundColor Gray
    Write-Host '      private = $false' -ForegroundColor Gray
    Write-Host '  }' -ForegroundColor Gray
    Write-Host '  $response = Invoke-RestApiRequest -Session $session -Endpoint "/user/repos" -Method POST -Body $newRepo' -ForegroundColor Gray

    # PATCH request
    Write-Host ""
    Write-Host "Example PATCH request:" -ForegroundColor Gray
    Write-Host '  $update = @{ description = "Updated description" }' -ForegroundColor Gray
    Write-Host '  $response = Invoke-RestApiRequest -Session $session -Endpoint "/repos/user/repo" -Method PATCH -Body $update' -ForegroundColor Gray

    # DELETE request
    Write-Host ""
    Write-Host "Example DELETE request:" -ForegroundColor Gray
    Write-Host '  $response = Invoke-RestApiRequest -Session $session -Endpoint "/repos/user/repo" -Method DELETE' -ForegroundColor Gray
}
catch {
    Write-Host "API examples shown (would require valid token)" -ForegroundColor Yellow
}
Write-Host ""

# Example 4: Updating token in existing session
Write-Host "Example 4: Updating token in active session" -ForegroundColor Yellow

$newToken = "new-bearer-token-after-refresh"

Write-Host "Updating session with new token..." -ForegroundColor Gray
Update-RestApiSessionToken -Session $session -Token $newToken

Write-Host "Token updated successfully" -ForegroundColor Green
Write-Host "Useful when token expires and you get a new one" -ForegroundColor Gray
Write-Host ""

# Example 5: GitHub API real-world example
Write-Host "Example 5: GitHub API integration example" -ForegroundColor Yellow
Write-Host ""

function Get-GitHubUserRepos {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [ValidateSet('all', 'owner', 'member')]
        [string]$Type = 'owner'
    )

    try {
        # Create GitHub API session
        $session = New-RestApiSession -BaseUri "https://api.github.com" `
                                       -AuthMethod Bearer `
                                       -Token $Token

        # Determine endpoint
        if ($Username) {
            $endpoint = "/users/$Username/repos"
        }
        else {
            $endpoint = "/user/repos"
        }

        # Query parameters
        $params = @{
            type = $Type
            per_page = 100
            sort = 'updated'
        }

        Write-Host "Fetching repositories from GitHub..." -ForegroundColor Gray

        $repos = Invoke-RestApiRequest -Session $session `
                                        -Endpoint $endpoint `
                                        -Method GET `
                                        -QueryParameters $params

        Write-Host "Retrieved $($repos.Count) repositories" -ForegroundColor Green

        # Display repo info
        $repos | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.name) ($($_.language))" -ForegroundColor Gray
        }

        return $repos
    }
    catch {
        Write-Error "Failed to get GitHub repos: $_"
        return $null
    }
}

Write-Host "Function defined: Get-GitHubUserRepos" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  $token = "your-github-personal-access-token"' -ForegroundColor Gray
Write-Host '  $repos = Get-GitHubUserRepos -Token $token' -ForegroundColor Gray
Write-Host '  $repos = Get-GitHubUserRepos -Token $token -Username "octocat"' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Example Complete ===" -ForegroundColor Cyan
