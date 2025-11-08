<#
.SYNOPSIS
    Modular REST API authentication module for PowerShell 5+

.DESCRIPTION
    This module provides functions to authenticate with REST APIs using various methods
    including Basic Auth, Bearer Token, API Key, OAuth 2.0, and custom headers.

.NOTES
    Version: 1.0.0
    Author: PowerShell Apps
    Compatible with: PowerShell 5.0+
#>

#region Public Functions

<#
.SYNOPSIS
    Creates a REST API authentication session with stored credentials.

.DESCRIPTION
    Creates an authentication session object that can be reused for multiple API calls.
    Supports multiple authentication methods and automatically handles headers.

.PARAMETER BaseUri
    The base URI for the API (e.g., "https://api.example.com").

.PARAMETER AuthMethod
    The authentication method to use: Basic, Bearer, ApiKey, OAuth2, Custom, or None.

.PARAMETER Credential
    PSCredential object for Basic authentication (username:password).

.PARAMETER Token
    Bearer token or API key value.

.PARAMETER ApiKeyHeader
    The header name for API key authentication (e.g., "X-API-Key").

.PARAMETER OAuth2Config
    Hashtable containing OAuth2 configuration (ClientId, ClientSecret, TokenEndpoint, Scope).

.PARAMETER CustomHeaders
    Hashtable of custom headers to include with each request.

.PARAMETER TimeoutSeconds
    Request timeout in seconds. Default is 30.

.EXAMPLE
    # Basic Authentication
    $cred = Get-Credential
    $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Basic -Credential $cred

.EXAMPLE
    # Bearer Token
    $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod Bearer -Token "your-token-here"

.EXAMPLE
    # API Key
    $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod ApiKey -Token "your-key" -ApiKeyHeader "X-API-Key"

.EXAMPLE
    # OAuth2 Client Credentials
    $oauth = @{
        ClientId = "client-id"
        ClientSecret = "client-secret"
        TokenEndpoint = "https://auth.example.com/oauth/token"
        Scope = "api:read api:write"
    }
    $session = New-RestApiSession -BaseUri "https://api.example.com" -AuthMethod OAuth2 -OAuth2Config $oauth
#>
function New-RestApiSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Basic', 'Bearer', 'ApiKey', 'OAuth2', 'Custom', 'None')]
        [string]$AuthMethod,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$ApiKeyHeader = 'X-API-Key',

        [Parameter(Mandatory = $false)]
        [hashtable]$OAuth2Config,

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomHeaders = @{},

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30
    )

    # Ensure BaseUri doesn't end with /
    $BaseUri = $BaseUri.TrimEnd('/')

    $session = @{
        BaseUri = $BaseUri
        AuthMethod = $AuthMethod
        Headers = @{}
        TimeoutSeconds = $TimeoutSeconds
        OAuth2Config = $null
        OAuth2Token = $null
        TokenExpiry = $null
    }

    # Add custom headers
    foreach ($key in $CustomHeaders.Keys) {
        $session.Headers[$key] = $CustomHeaders[$key]
    }

    # Configure authentication based on method
    switch ($AuthMethod) {
        'Basic' {
            if ($null -eq $Credential) {
                throw "Credential parameter is required for Basic authentication"
            }
            $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(
                ("{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
            ))
            $session.Headers['Authorization'] = "Basic $base64Auth"
        }
        'Bearer' {
            if ([string]::IsNullOrEmpty($Token)) {
                throw "Token parameter is required for Bearer authentication"
            }
            $session.Headers['Authorization'] = "Bearer $Token"
        }
        'ApiKey' {
            if ([string]::IsNullOrEmpty($Token)) {
                throw "Token parameter is required for API Key authentication"
            }
            $session.Headers[$ApiKeyHeader] = $Token
        }
        'OAuth2' {
            if ($null -eq $OAuth2Config) {
                throw "OAuth2Config parameter is required for OAuth2 authentication"
            }
            # Validate OAuth2 config
            $requiredKeys = @('ClientId', 'ClientSecret', 'TokenEndpoint')
            foreach ($key in $requiredKeys) {
                if (-not $OAuth2Config.ContainsKey($key)) {
                    throw "OAuth2Config must contain '$key'"
                }
            }
            $session.OAuth2Config = $OAuth2Config
            # Get initial token
            $tokenResponse = Get-OAuth2Token -Config $OAuth2Config
            $session.OAuth2Token = $tokenResponse.access_token
            $session.Headers['Authorization'] = "Bearer $($tokenResponse.access_token)"

            # Calculate token expiry if provided
            if ($tokenResponse.expires_in) {
                $session.TokenExpiry = (Get-Date).AddSeconds($tokenResponse.expires_in - 60) # Refresh 60s early
            }
        }
        'Custom' {
            # Custom headers already added above
        }
        'None' {
            # No authentication
        }
    }

    # Add common headers
    $session.Headers['Accept'] = 'application/json'
    $session.Headers['Content-Type'] = 'application/json'

    return $session
}

<#
.SYNOPSIS
    Invokes a REST API request using an authenticated session.

.DESCRIPTION
    Wrapper around Invoke-RestMethod that uses a session created by New-RestApiSession.
    Automatically handles authentication headers and token refresh for OAuth2.

.PARAMETER Session
    The session object created by New-RestApiSession.

.PARAMETER Endpoint
    The API endpoint path (e.g., "/users" or "users/123").

.PARAMETER Method
    HTTP method: GET, POST, PUT, DELETE, PATCH. Default is GET.

.PARAMETER Body
    Request body (will be converted to JSON automatically if it's a hashtable or object).

.PARAMETER QueryParameters
    Hashtable of query string parameters.

.PARAMETER AdditionalHeaders
    Additional headers for this specific request.

.EXAMPLE
    $response = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method GET

.EXAMPLE
    $body = @{ name = "John Doe"; email = "john@example.com" }
    $response = Invoke-RestApiRequest -Session $session -Endpoint "/users" -Method POST -Body $body

.EXAMPLE
    $params = @{ page = 1; limit = 10 }
    $response = Invoke-RestApiRequest -Session $session -Endpoint "/users" -QueryParameters $params
#>
function Invoke-RestApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $false)]
        $Body,

        [Parameter(Mandatory = $false)]
        [hashtable]$QueryParameters = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalHeaders = @{}
    )

    try {
        # Check if OAuth2 token needs refresh
        if ($Session.AuthMethod -eq 'OAuth2' -and $Session.TokenExpiry) {
            if ((Get-Date) -ge $Session.TokenExpiry) {
                Write-Verbose "OAuth2 token expired, refreshing..."
                $tokenResponse = Get-OAuth2Token -Config $Session.OAuth2Config
                $Session.OAuth2Token = $tokenResponse.access_token
                $Session.Headers['Authorization'] = "Bearer $($tokenResponse.access_token)"

                if ($tokenResponse.expires_in) {
                    $Session.TokenExpiry = (Get-Date).AddSeconds($tokenResponse.expires_in - 60)
                }
            }
        }

        # Build URI
        $Endpoint = $Endpoint.TrimStart('/')
        $uri = "$($Session.BaseUri)/$Endpoint"

        # Add query parameters
        if ($QueryParameters.Count -gt 0) {
            $queryString = ($QueryParameters.GetEnumerator() | ForEach-Object {
                "$($_.Key)=$([System.Uri]::EscapeDataString($_.Value))"
            }) -join '&'
            $uri = "$uri`?$queryString"
        }

        # Merge headers
        $headers = $Session.Headers.Clone()
        foreach ($key in $AdditionalHeaders.Keys) {
            $headers[$key] = $AdditionalHeaders[$key]
        }

        # Prepare request parameters
        $requestParams = @{
            Uri = $uri
            Method = $Method
            Headers = $headers
            TimeoutSec = $Session.TimeoutSeconds
        }

        # Add body if provided
        if ($null -ne $Body) {
            if ($Body -is [string]) {
                $requestParams.Body = $Body
            }
            else {
                $requestParams.Body = ($Body | ConvertTo-Json -Depth 10)
            }
        }

        Write-Verbose "Sending $Method request to: $uri"

        # Make the request
        $response = Invoke-RestMethod @requestParams

        return $response
    }
    catch {
        $errorDetails = @{
            Message = $_.Exception.Message
            StatusCode = $null
            ResponseContent = $null
        }

        if ($_.Exception.Response) {
            $errorDetails.StatusCode = [int]$_.Exception.Response.StatusCode

            # Try to read response content
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorDetails.ResponseContent = $reader.ReadToEnd()
                $reader.Close()
            }
            catch {
                # Couldn't read response
            }
        }

        Write-Error "REST API request failed: $($errorDetails.Message) | Status: $($errorDetails.StatusCode) | Response: $($errorDetails.ResponseContent)"
        throw
    }
}

<#
.SYNOPSIS
    Tests a REST API connection and authentication.

.DESCRIPTION
    Verifies that the API is reachable and authentication is working.

.PARAMETER Session
    The session object created by New-RestApiSession.

.PARAMETER TestEndpoint
    Optional endpoint to test. If not specified, tests the base URI.

.EXAMPLE
    $isConnected = Test-RestApiConnection -Session $session

.EXAMPLE
    $isConnected = Test-RestApiConnection -Session $session -TestEndpoint "/health"
#>
function Test-RestApiConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session,

        [Parameter(Mandatory = $false)]
        [string]$TestEndpoint = '/'
    )

    try {
        $null = Invoke-RestApiRequest -Session $Session -Endpoint $TestEndpoint -Method GET -ErrorAction Stop
        Write-Verbose "Connection test successful"
        return $true
    }
    catch {
        Write-Warning "Connection test failed: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Updates the authentication token in an existing session.

.DESCRIPTION
    Allows updating the Bearer token or API key in an active session without recreating it.

.PARAMETER Session
    The session object to update.

.PARAMETER Token
    The new token value.

.EXAMPLE
    Update-RestApiSessionToken -Session $session -Token "new-token-value"
#>
function Update-RestApiSessionToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session,

        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    switch ($Session.AuthMethod) {
        'Bearer' {
            $Session.Headers['Authorization'] = "Bearer $Token"
        }
        'ApiKey' {
            # Find the API key header and update it
            foreach ($key in $Session.Headers.Keys) {
                if ($key -ne 'Authorization' -and $key -ne 'Accept' -and $key -ne 'Content-Type') {
                    $Session.Headers[$key] = $Token
                    break
                }
            }
        }
        'OAuth2' {
            $Session.OAuth2Token = $Token
            $Session.Headers['Authorization'] = "Bearer $Token"
        }
        default {
            throw "Token update not supported for authentication method: $($Session.AuthMethod)"
        }
    }

    Write-Verbose "Session token updated successfully"
}

<#
.SYNOPSIS
    Creates headers for REST API authentication without a full session.

.DESCRIPTION
    Generates authentication headers that can be used directly with Invoke-RestMethod.
    Useful for one-off requests without creating a session.

.PARAMETER AuthMethod
    The authentication method: Basic, Bearer, or ApiKey.

.PARAMETER Credential
    PSCredential for Basic authentication.

.PARAMETER Token
    Token for Bearer or API key authentication.

.PARAMETER ApiKeyHeader
    Header name for API key authentication.

.EXAMPLE
    $headers = New-RestApiHeaders -AuthMethod Bearer -Token "your-token"
    Invoke-RestMethod -Uri "https://api.example.com/users" -Headers $headers

.EXAMPLE
    $cred = Get-Credential
    $headers = New-RestApiHeaders -AuthMethod Basic -Credential $cred
#>
function New-RestApiHeaders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Basic', 'Bearer', 'ApiKey')]
        [string]$AuthMethod,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$ApiKeyHeader = 'X-API-Key'
    )

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
    }

    switch ($AuthMethod) {
        'Basic' {
            if ($null -eq $Credential) {
                throw "Credential parameter is required for Basic authentication"
            }
            $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(
                ("{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
            ))
            $headers['Authorization'] = "Basic $base64Auth"
        }
        'Bearer' {
            if ([string]::IsNullOrEmpty($Token)) {
                throw "Token parameter is required for Bearer authentication"
            }
            $headers['Authorization'] = "Bearer $Token"
        }
        'ApiKey' {
            if ([string]::IsNullOrEmpty($Token)) {
                throw "Token parameter is required for API Key authentication"
            }
            $headers[$ApiKeyHeader] = $Token
        }
    }

    return $headers
}

#endregion

#region Private Functions

<#
.SYNOPSIS
    Obtains an OAuth2 access token using client credentials flow.
#>
function Get-OAuth2Token {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    try {
        $body = @{
            grant_type = 'client_credentials'
            client_id = $Config.ClientId
            client_secret = $Config.ClientSecret
        }

        if ($Config.ContainsKey('Scope') -and -not [string]::IsNullOrEmpty($Config.Scope)) {
            $body.scope = $Config.Scope
        }

        # Convert body to form-urlencoded format
        $formBody = ($body.GetEnumerator() | ForEach-Object {
            "$($_.Key)=$([System.Uri]::EscapeDataString($_.Value))"
        }) -join '&'

        $headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded'
            'Accept' = 'application/json'
        }

        Write-Verbose "Requesting OAuth2 token from: $($Config.TokenEndpoint)"

        $response = Invoke-RestMethod -Uri $Config.TokenEndpoint `
                                       -Method POST `
                                       -Headers $headers `
                                       -Body $formBody

        if (-not $response.access_token) {
            throw "OAuth2 token response did not contain access_token"
        }

        Write-Verbose "OAuth2 token obtained successfully"
        return $response
    }
    catch {
        Write-Error "Failed to obtain OAuth2 token: $_"
        throw
    }
}

#endregion

# Export public functions
Export-ModuleMember -Function New-RestApiSession, `
                              Invoke-RestApiRequest, `
                              Test-RestApiConnection, `
                              Update-RestApiSessionToken, `
                              New-RestApiHeaders
