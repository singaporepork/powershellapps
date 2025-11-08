<#
.SYNOPSIS
    Example: REST API authentication using API Key

.DESCRIPTION
    Demonstrates how to use the RestApiAuth module with API Key authentication.
    API keys are passed in custom headers (e.g., X-API-Key, api-key, etc.).
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\RestApiAuth.psm1"
Import-Module $modulePath -Force

Write-Host "=== REST API Key Authentication Example ===" -ForegroundColor Cyan
Write-Host ""

# Example 1: Create session with API Key (default header)
Write-Host "Example 1: Creating session with API Key (X-API-Key header)" -ForegroundColor Yellow

$apiKey = "sk_live_1234567890abcdef"

$session = New-RestApiSession -BaseUri "https://api.stripe.com/v1" `
                               -AuthMethod ApiKey `
                               -Token $apiKey `
                               -ApiKeyHeader "X-API-Key"

Write-Host "Session created successfully" -ForegroundColor Green
Write-Host "Base URI: $($session.BaseUri)"
Write-Host "Auth Method: $($session.AuthMethod)"
Write-Host "API Key Header: X-API-Key" -ForegroundColor Gray
Write-Host ""

# Example 2: Custom header name
Write-Host "Example 2: Using custom API key header name" -ForegroundColor Yellow

# Some APIs use different header names
$customHeaderExamples = @(
    @{ API = "SendGrid"; Header = "Authorization"; Note = "Uses 'Bearer' prefix" }
    @{ API = "Mailgun"; Header = "api-key"; Note = "Lowercase header" }
    @{ API = "Twilio"; Header = "X-Twilio-Signature"; Note = "Custom header" }
    @{ API = "OpenWeather"; Header = "appid"; Note = "Query param, not header" }
)

Write-Host "Different APIs use different header names:" -ForegroundColor Gray
$customHeaderExamples | ForEach-Object {
    Write-Host "  - $($_.API): $($_.Header) - $($_.Note)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Example with custom header:" -ForegroundColor Gray
$apiKey = "your-api-key-here"
$session = New-RestApiSession -BaseUri "https://api.example.com" `
                               -AuthMethod ApiKey `
                               -Token $apiKey `
                               -ApiKeyHeader "api-key"

Write-Host "Session created with 'api-key' header" -ForegroundColor Green
Write-Host ""

# Example 3: Reading API key from environment variable
Write-Host "Example 3: Using environment variables for API keys" -ForegroundColor Yellow

# Set environment variable (in production, set this in system/user environment)
$env:MY_API_KEY = "secret-api-key-123"

Write-Host "Reading API key from environment variable..." -ForegroundColor Gray
$apiKey = $env:MY_API_KEY

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "No API key found in environment" -ForegroundColor Red
}
else {
    $session = New-RestApiSession -BaseUri "https://api.example.com" `
                                   -AuthMethod ApiKey `
                                   -Token $apiKey

    Write-Host "Session created from environment variable" -ForegroundColor Green
}

# Clean up
Remove-Item Env:\MY_API_KEY
Write-Host ""

# Example 4: Making API requests
Write-Host "Example 4: Making API requests with API Key" -ForegroundColor Yellow

$apiKey = "your-api-key"
$session = New-RestApiSession -BaseUri "https://api.openweathermap.org/data/2.5" `
                               -AuthMethod ApiKey `
                               -Token $apiKey `
                               -ApiKeyHeader "appid"

Write-Host "Example API calls:" -ForegroundColor Gray
Write-Host ""
Write-Host "GET weather data:" -ForegroundColor Gray
Write-Host '  $params = @{ q = "London"; units = "metric" }' -ForegroundColor Gray
Write-Host '  $weather = Invoke-RestApiRequest -Session $session -Endpoint "/weather" -QueryParameters $params' -ForegroundColor Gray
Write-Host ""
Write-Host "GET forecast:" -ForegroundColor Gray
Write-Host '  $params = @{ lat = "51.5074"; lon = "-0.1278"; cnt = 5 }' -ForegroundColor Gray
Write-Host '  $forecast = Invoke-RestApiRequest -Session $session -Endpoint "/forecast" -QueryParameters $params' -ForegroundColor Gray
Write-Host ""

# Example 5: Headers without session
Write-Host "Example 5: Generate API key headers for one-off requests" -ForegroundColor Yellow

$apiKey = "your-api-key"
$headers = New-RestApiHeaders -AuthMethod ApiKey -Token $apiKey -ApiKeyHeader "X-API-Key"

Write-Host "Headers generated:"
$headers.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Use directly with Invoke-RestMethod:" -ForegroundColor Gray
Write-Host '  $response = Invoke-RestMethod -Uri "https://api.example.com/data" -Headers $headers' -ForegroundColor Gray
Write-Host ""

# Example 6: Real-world OpenWeather API example
Write-Host "Example 6: OpenWeather API integration" -ForegroundColor Yellow
Write-Host ""

function Get-WeatherData {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $true)]
        [string]$City,

        [Parameter(Mandatory = $false)]
        [ValidateSet('metric', 'imperial', 'standard')]
        [string]$Units = 'metric'
    )

    try {
        # OpenWeather API uses API key as query parameter
        # We'll use None auth and pass key in query params
        $session = New-RestApiSession -BaseUri "https://api.openweathermap.org/data/2.5" `
                                       -AuthMethod None

        $params = @{
            q = $City
            appid = $ApiKey
            units = $Units
        }

        Write-Host "Fetching weather data for $City..." -ForegroundColor Gray

        $weather = Invoke-RestApiRequest -Session $session `
                                          -Endpoint "/weather" `
                                          -Method GET `
                                          -QueryParameters $params

        Write-Host "Weather data retrieved successfully" -ForegroundColor Green
        Write-Host "  Temperature: $($weather.main.temp)°" -ForegroundColor Gray
        Write-Host "  Conditions: $($weather.weather[0].description)" -ForegroundColor Gray
        Write-Host "  Humidity: $($weather.main.humidity)%" -ForegroundColor Gray

        return $weather
    }
    catch {
        Write-Error "Failed to get weather data: $_"
        return $null
    }
}

Write-Host "Function defined: Get-WeatherData" -ForegroundColor Green
Write-Host "Usage:" -ForegroundColor Gray
Write-Host '  $apiKey = "your-openweather-api-key"' -ForegroundColor Gray
Write-Host '  $weather = Get-WeatherData -ApiKey $apiKey -City "London" -Units metric' -ForegroundColor Gray

Write-Host ""
Write-Host "=== Example Complete ===" -ForegroundColor Cyan
