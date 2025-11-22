<#
.SYNOPSIS
    Example usage of the StringEncryption module.

.DESCRIPTION
    This script demonstrates various encryption, decryption, and security
    functions provided by the StringEncryption module.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\StringEncryption.psm1" -Force

Write-Host "StringEncryption Module Examples" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# ============================================================================
# Example 1: Generate encryption key
# ============================================================================

Write-Host "Example 1: Generate encryption key" -ForegroundColor Yellow
Write-Host "-----------------------------------"

# Generate a 256-bit key
$key = New-EncryptionKey -KeySize 256
Write-Host "Generated key (bytes): $($key.Length) bytes"

# Generate as Base64 string
$keyBase64 = New-EncryptionKey -KeySize 256 -AsBase64
Write-Host "Generated key (Base64): $($keyBase64.Substring(0, 20))..."

Write-Host ""

# ============================================================================
# Example 2: Basic string encryption/decryption
# ============================================================================

Write-Host "Example 2: AES string encryption" -ForegroundColor Yellow
Write-Host "---------------------------------"

$secretMessage = "This is my secret message!"
Write-Host "Original: $secretMessage"

# Encrypt
$encrypted = Protect-String -PlainText $secretMessage -Key $key
Write-Host "Encrypted: $($encrypted.Substring(0, 30))..."

# Decrypt
$decrypted = Unprotect-String -EncryptedText $encrypted -Key $key
Write-Host "Decrypted: $decrypted"

Write-Host ""

# ============================================================================
# Example 3: Export and import keys
# ============================================================================

Write-Host "Example 3: Key export/import" -ForegroundColor Yellow
Write-Host "----------------------------"

$keyPath = "$PSScriptRoot\test-key.key"

# Export key
Export-EncryptionKey -Key $key -FilePath $keyPath -Force
Write-Host "Key exported to: $keyPath"

# Import key
$importedKey = Import-EncryptionKey -FilePath $keyPath
Write-Host "Key imported: $($importedKey.Length) bytes"

# Verify keys match
$keysMatch = [System.Linq.Enumerable]::SequenceEqual([byte[]]$key, [byte[]]$importedKey)
Write-Host "Keys match: $keysMatch"

# Cleanup
Remove-Item $keyPath -Force

Write-Host ""

# ============================================================================
# Example 4: DPAPI encryption (Windows-specific)
# ============================================================================

Write-Host "Example 4: DPAPI encryption" -ForegroundColor Yellow
Write-Host "---------------------------"

$password = "MySecretPassword123!"
Write-Host "Original password: $password"

# Encrypt with DPAPI (only decryptable by same user on same machine)
$dpApiEncrypted = Protect-StringWithDPAPI -PlainText $password -Scope CurrentUser
Write-Host "DPAPI encrypted: $($dpApiEncrypted.Substring(0, 30))..."

# Decrypt
$dpApiDecrypted = Unprotect-StringWithDPAPI -EncryptedText $dpApiEncrypted
Write-Host "Decrypted: $dpApiDecrypted"

Write-Host ""

# ============================================================================
# Example 5: SecureString handling
# ============================================================================

Write-Host "Example 5: SecureString handling" -ForegroundColor Yellow
Write-Host "---------------------------------"

# Create SecureString from plain text
$securePassword = New-SecureStringFromPlainText -PlainText "MyPassword123"
Write-Host "Created SecureString"

# Convert to encrypted string (portable with key)
$encryptedSecure = ConvertTo-EncryptedString -SecureString $securePassword -Key $key
Write-Host "Encrypted SecureString: $($encryptedSecure.Substring(0, 30))..."

# Convert back to SecureString
$recoveredSecure = ConvertFrom-EncryptedString -EncryptedString $encryptedSecure -Key $key
Write-Host "Recovered SecureString"

# Get plain text from SecureString
$plainText = Get-PlainTextFromSecureString -SecureString $recoveredSecure
Write-Host "Plain text: $plainText"

Write-Host ""

# ============================================================================
# Example 6: Hashing
# ============================================================================

Write-Host "Example 6: String hashing" -ForegroundColor Yellow
Write-Host "-------------------------"

$textToHash = "Hello, World!"
Write-Host "Text: $textToHash"

# Generate hashes with different algorithms
$sha256 = Get-StringHash -InputString $textToHash -Algorithm SHA256
$sha512 = Get-StringHash -InputString $textToHash -Algorithm SHA512
$md5 = Get-StringHash -InputString $textToHash -Algorithm MD5

Write-Host "SHA256: $sha256"
Write-Host "SHA512: $($sha512.Substring(0, 32))..."
Write-Host "MD5: $md5"

# Verify hash
$isValid = Test-StringHash -InputString $textToHash -Hash $sha256 -Algorithm SHA256
Write-Host "Hash verification: $isValid"

Write-Host ""

# ============================================================================
# Example 7: Password generation
# ============================================================================

Write-Host "Example 7: Password generation" -ForegroundColor Yellow
Write-Host "-------------------------------"

# Simple password
$password1 = New-RandomPassword -Length 12
Write-Host "Simple (12 chars): $password1"

# With special characters
$password2 = New-RandomPassword -Length 16 -IncludeSpecial
Write-Host "With special (16): $password2"

# Exclude ambiguous characters
$password3 = New-RandomPassword -Length 20 -ExcludeAmbiguous
Write-Host "No ambiguous (20): $password3"

# As SecureString
$securePass = New-RandomPassword -Length 16 -IncludeSpecial -AsSecureString
Write-Host "As SecureString: (SecureString object created)"

Write-Host ""

# ============================================================================
# Example 8: File encryption
# ============================================================================

Write-Host "Example 8: File encryption" -ForegroundColor Yellow
Write-Host "--------------------------"

# Create test file
$testFile = "$PSScriptRoot\test-data.txt"
$testContent = "This is sensitive file content that needs encryption."
Set-Content -Path $testFile -Value $testContent

Write-Host "Created test file with content"

# Encrypt file
$encryptedFile = "$PSScriptRoot\test-data.encrypted"
$encryptResult = Protect-File -FilePath $testFile -Key $key -OutputPath $encryptedFile
Write-Host "Encrypted: $($encryptResult.OriginalSize) bytes -> $($encryptResult.EncryptedSize) bytes"

# Decrypt file
$decryptedFile = "$PSScriptRoot\test-data-decrypted.txt"
$decryptResult = Unprotect-File -FilePath $encryptedFile -Key $key -OutputPath $decryptedFile
Write-Host "Decrypted: $($decryptResult.DecryptedSize) bytes"

# Verify content
$recoveredContent = Get-Content -Path $decryptedFile -Raw
Write-Host "Content matches: $($recoveredContent.Trim() -eq $testContent)"

# Cleanup
Remove-Item $testFile, $encryptedFile, $decryptedFile -Force

Write-Host ""

# ============================================================================
# Example 9: Pipeline support
# ============================================================================

Write-Host "Example 9: Pipeline support" -ForegroundColor Yellow
Write-Host "---------------------------"

# Encrypt multiple strings
$secrets = @("Secret1", "Secret2", "Secret3")
$encryptedSecrets = $secrets | Protect-String -Key $key
Write-Host "Encrypted $($encryptedSecrets.Count) secrets"

# Decrypt multiple strings
$decryptedSecrets = $encryptedSecrets | Unprotect-String -Key $key
Write-Host "Decrypted: $($decryptedSecrets -join ', ')"

Write-Host ""

# ============================================================================
# Example 10: Test if data is encrypted
# ============================================================================

Write-Host "Example 10: Test encrypted data" -ForegroundColor Yellow
Write-Host "--------------------------------"

$plainData = "This is plain text"
$encryptedData = Protect-String -PlainText "Encrypted content" -Key $key

$isPlainEncrypted = Test-EncryptedString -InputString $plainData
$isEncryptedEncrypted = Test-EncryptedString -InputString $encryptedData

Write-Host "Plain text appears encrypted: $isPlainEncrypted"
Write-Host "Encrypted data appears encrypted: $isEncryptedEncrypted"

Write-Host ""

# ============================================================================
# Example 11: Complete workflow - Storing credentials
# ============================================================================

Write-Host "Example 11: Complete credential workflow" -ForegroundColor Yellow
Write-Host "----------------------------------------"

Write-Host @"
# Generate and save a key (do this once, store securely)
`$key = New-EncryptionKey -KeySize 256
Export-EncryptionKey -Key `$key -FilePath "C:\Keys\app.key" -ProtectWithDPAPI

# Store credentials
`$username = "admin"
`$password = "P@ssw0rd123!"
`$encryptedPassword = Protect-String -PlainText `$password -Key `$key

# Save to config file
@{ Username = `$username; Password = `$encryptedPassword } |
    ConvertTo-Json | Set-Content "C:\Config\credentials.json"

# Later, retrieve credentials
`$key = Import-EncryptionKey -FilePath "C:\Keys\app.key" -ProtectedWithDPAPI
`$config = Get-Content "C:\Config\credentials.json" | ConvertFrom-Json
`$decryptedPassword = Unprotect-String -EncryptedText `$config.Password -Key `$key
"@

Write-Host ""

# ============================================================================
# Example 12: Hash-based password verification
# ============================================================================

Write-Host "Example 12: Password verification" -ForegroundColor Yellow
Write-Host "----------------------------------"

# "Registration" - store hash, not password
$userPassword = "UserPassword123!"
$storedHash = Get-StringHash -InputString $userPassword -Algorithm SHA256
Write-Host "Stored hash: $storedHash"

# "Login" - verify against stored hash
$loginAttempt = "UserPassword123!"
$isValid = Test-StringHash -InputString $loginAttempt -Hash $storedHash
Write-Host "Login attempt valid: $isValid"

$badAttempt = "WrongPassword"
$isInvalid = Test-StringHash -InputString $badAttempt -Hash $storedHash
Write-Host "Bad attempt valid: $isInvalid"

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Security Notes:" -ForegroundColor Gray
Write-Host "- Always use 256-bit keys for AES encryption" -ForegroundColor Gray
Write-Host "- Store keys securely (DPAPI-protected or HSM)" -ForegroundColor Gray
Write-Host "- Never store passwords in plain text - use hashes" -ForegroundColor Gray
Write-Host "- Use different keys for different purposes" -ForegroundColor Gray
Write-Host "- Rotate keys periodically" -ForegroundColor Gray
