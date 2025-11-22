<#
.SYNOPSIS
    Modular PowerShell script for string encryption and decryption.

.DESCRIPTION
    This module provides comprehensive encryption and decryption functionality including
    AES encryption, DPAPI protection, SecureString handling, and hash generation.
    Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+
#>

#Requires -Version 5.0

# ============================================================================
# Key Generation and Management
# ============================================================================

function New-EncryptionKey {
    <#
    .SYNOPSIS
        Generates a new encryption key for AES encryption.

    .DESCRIPTION
        Creates a cryptographically secure random key for use with AES encryption.

    .PARAMETER KeySize
        Key size in bits: 128, 192, or 256. Default: 256.

    .PARAMETER AsBase64
        Return key as Base64 string instead of byte array.

    .EXAMPLE
        $key = New-EncryptionKey

    .EXAMPLE
        $keyString = New-EncryptionKey -KeySize 256 -AsBase64
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet(128, 192, 256)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [switch]$AsBase64
    )

    try {
        $keyBytes = New-Object byte[] ($KeySize / 8)
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($keyBytes)
        $rng.Dispose()

        if ($AsBase64) {
            return [Convert]::ToBase64String($keyBytes)
        }
        else {
            return $keyBytes
        }
    }
    catch {
        throw "Failed to generate encryption key: $_"
    }
}

function Export-EncryptionKey {
    <#
    .SYNOPSIS
        Exports an encryption key to a file.

    .DESCRIPTION
        Saves an encryption key to a file, optionally protected with DPAPI.

    .PARAMETER Key
        The encryption key (byte array or Base64 string).

    .PARAMETER FilePath
        Path to save the key file.

    .PARAMETER ProtectWithDPAPI
        Protect the key file using DPAPI (Windows Data Protection).

    .PARAMETER Force
        Overwrite existing file.

    .EXAMPLE
        Export-EncryptionKey -Key $key -FilePath "C:\Keys\mykey.key"

    .EXAMPLE
        Export-EncryptionKey -Key $key -FilePath "C:\Keys\mykey.key" -ProtectWithDPAPI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Key,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$ProtectWithDPAPI,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        # Convert to byte array if Base64 string
        if ($Key -is [string]) {
            $keyBytes = [Convert]::FromBase64String($Key)
        }
        else {
            $keyBytes = $Key
        }

        # Create directory if needed
        $keyDir = Split-Path -Path $FilePath -Parent
        if ($keyDir -and -not (Test-Path $keyDir)) {
            New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
        }

        # Check if file exists
        if ((Test-Path $FilePath) -and -not $Force) {
            throw "File already exists. Use -Force to overwrite."
        }

        if ($ProtectWithDPAPI) {
            # Protect with DPAPI
            Add-Type -AssemblyName System.Security
            $protectedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
                $keyBytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )
            [System.IO.File]::WriteAllBytes($FilePath, $protectedBytes)
        }
        else {
            # Save as Base64
            $base64Key = [Convert]::ToBase64String($keyBytes)
            Set-Content -Path $FilePath -Value $base64Key -Force
        }

        Write-Verbose "Key exported to: $FilePath"
    }
    catch {
        throw "Failed to export encryption key: $_"
    }
}

function Import-EncryptionKey {
    <#
    .SYNOPSIS
        Imports an encryption key from a file.

    .DESCRIPTION
        Loads an encryption key from a file.

    .PARAMETER FilePath
        Path to the key file.

    .PARAMETER ProtectedWithDPAPI
        Key file is protected with DPAPI.

    .PARAMETER AsBase64
        Return key as Base64 string instead of byte array.

    .EXAMPLE
        $key = Import-EncryptionKey -FilePath "C:\Keys\mykey.key"

    .EXAMPLE
        $key = Import-EncryptionKey -FilePath "C:\Keys\mykey.key" -ProtectedWithDPAPI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$ProtectedWithDPAPI,

        [Parameter(Mandatory = $false)]
        [switch]$AsBase64
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "Key file not found: $FilePath"
        }

        if ($ProtectedWithDPAPI) {
            # Unprotect with DPAPI
            Add-Type -AssemblyName System.Security
            $protectedBytes = [System.IO.File]::ReadAllBytes($FilePath)
            $keyBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $protectedBytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )
        }
        else {
            # Read as Base64
            $base64Key = Get-Content -Path $FilePath -Raw
            $keyBytes = [Convert]::FromBase64String($base64Key.Trim())
        }

        if ($AsBase64) {
            return [Convert]::ToBase64String($keyBytes)
        }
        else {
            return $keyBytes
        }
    }
    catch {
        throw "Failed to import encryption key: $_"
    }
}

# ============================================================================
# AES Encryption Functions
# ============================================================================

function Protect-String {
    <#
    .SYNOPSIS
        Encrypts a string using AES encryption.

    .DESCRIPTION
        Encrypts a plaintext string using AES-256 encryption with a provided key.

    .PARAMETER PlainText
        The string to encrypt.

    .PARAMETER Key
        The encryption key (byte array or Base64 string).

    .PARAMETER KeySize
        Key size in bits (must match key). Default: 256.

    .EXAMPLE
        $encrypted = Protect-String -PlainText "Secret message" -Key $key

    .EXAMPLE
        $encrypted = Protect-String -PlainText "Secret" -Key "base64keystring"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$PlainText,

        [Parameter(Mandatory = $true)]
        [object]$Key,

        [Parameter(Mandatory = $false)]
        [ValidateSet(128, 192, 256)]
        [int]$KeySize = 256
    )

    process {
        try {
            # Convert key if Base64 string
            if ($Key -is [string]) {
                $keyBytes = [Convert]::FromBase64String($Key)
            }
            else {
                $keyBytes = $Key
            }

            # Validate key size
            $expectedKeySize = $KeySize / 8
            if ($keyBytes.Length -ne $expectedKeySize) {
                throw "Key size mismatch. Expected $expectedKeySize bytes, got $($keyBytes.Length) bytes."
            }

            # Create AES encryptor
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.KeySize = $KeySize
            $aes.Key = $keyBytes
            $aes.GenerateIV()
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

            # Encrypt
            $encryptor = $aes.CreateEncryptor()
            $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
            $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

            # Combine IV and encrypted data
            $result = New-Object byte[] ($aes.IV.Length + $encryptedBytes.Length)
            [Array]::Copy($aes.IV, 0, $result, 0, $aes.IV.Length)
            [Array]::Copy($encryptedBytes, 0, $result, $aes.IV.Length, $encryptedBytes.Length)

            # Cleanup
            $encryptor.Dispose()
            $aes.Dispose()

            return [Convert]::ToBase64String($result)
        }
        catch {
            throw "Encryption failed: $_"
        }
    }
}

function Unprotect-String {
    <#
    .SYNOPSIS
        Decrypts a string that was encrypted with Protect-String.

    .DESCRIPTION
        Decrypts an AES-encrypted string back to plaintext.

    .PARAMETER EncryptedText
        The Base64-encoded encrypted string.

    .PARAMETER Key
        The encryption key (byte array or Base64 string).

    .PARAMETER KeySize
        Key size in bits (must match encryption). Default: 256.

    .EXAMPLE
        $plainText = Unprotect-String -EncryptedText $encrypted -Key $key
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$EncryptedText,

        [Parameter(Mandatory = $true)]
        [object]$Key,

        [Parameter(Mandatory = $false)]
        [ValidateSet(128, 192, 256)]
        [int]$KeySize = 256
    )

    process {
        try {
            # Convert key if Base64 string
            if ($Key -is [string]) {
                $keyBytes = [Convert]::FromBase64String($Key)
            }
            else {
                $keyBytes = $Key
            }

            # Decode encrypted text
            $encryptedBytes = [Convert]::FromBase64String($EncryptedText)

            # Create AES decryptor
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.KeySize = $KeySize
            $aes.Key = $keyBytes
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
            $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

            # Extract IV from beginning
            $iv = New-Object byte[] 16
            [Array]::Copy($encryptedBytes, 0, $iv, 0, 16)
            $aes.IV = $iv

            # Extract encrypted data
            $dataLength = $encryptedBytes.Length - 16
            $encryptedData = New-Object byte[] $dataLength
            [Array]::Copy($encryptedBytes, 16, $encryptedData, 0, $dataLength)

            # Decrypt
            $decryptor = $aes.CreateDecryptor()
            $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)

            # Cleanup
            $decryptor.Dispose()
            $aes.Dispose()

            return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
        }
        catch {
            throw "Decryption failed: $_"
        }
    }
}

# ============================================================================
# DPAPI Functions (Windows Data Protection)
# ============================================================================

function Protect-StringWithDPAPI {
    <#
    .SYNOPSIS
        Encrypts a string using Windows DPAPI.

    .DESCRIPTION
        Uses Windows Data Protection API to encrypt data. Can only be decrypted
        by the same user on the same machine (CurrentUser) or any user on the
        same machine (LocalMachine).

    .PARAMETER PlainText
        The string to encrypt.

    .PARAMETER Scope
        Protection scope: CurrentUser or LocalMachine.

    .EXAMPLE
        $encrypted = Protect-StringWithDPAPI -PlainText "Secret" -Scope CurrentUser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$PlainText,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser'
    )

    process {
        try {
            Add-Type -AssemblyName System.Security

            $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
            $protectionScope = [System.Security.Cryptography.DataProtectionScope]::$Scope

            $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
                $plainBytes,
                $null,
                $protectionScope
            )

            return [Convert]::ToBase64String($encryptedBytes)
        }
        catch {
            throw "DPAPI encryption failed: $_"
        }
    }
}

function Unprotect-StringWithDPAPI {
    <#
    .SYNOPSIS
        Decrypts a string encrypted with DPAPI.

    .DESCRIPTION
        Decrypts data that was encrypted using Windows DPAPI.

    .PARAMETER EncryptedText
        The Base64-encoded encrypted string.

    .PARAMETER Scope
        Protection scope used during encryption.

    .EXAMPLE
        $plainText = Unprotect-StringWithDPAPI -EncryptedText $encrypted
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$EncryptedText,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser'
    )

    process {
        try {
            Add-Type -AssemblyName System.Security

            $encryptedBytes = [Convert]::FromBase64String($EncryptedText)
            $protectionScope = [System.Security.Cryptography.DataProtectionScope]::$Scope

            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encryptedBytes,
                $null,
                $protectionScope
            )

            return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
        }
        catch {
            throw "DPAPI decryption failed: $_"
        }
    }
}

# ============================================================================
# SecureString Functions
# ============================================================================

function ConvertTo-EncryptedString {
    <#
    .SYNOPSIS
        Converts a SecureString to an encrypted string.

    .DESCRIPTION
        Converts a SecureString to an encrypted string that can be stored or transmitted.

    .PARAMETER SecureString
        The SecureString to convert.

    .PARAMETER Key
        Optional encryption key. If not provided, uses DPAPI (user/machine specific).

    .EXAMPLE
        $secure = Read-Host -AsSecureString
        $encrypted = ConvertTo-EncryptedString -SecureString $secure

    .EXAMPLE
        $encrypted = ConvertTo-EncryptedString -SecureString $secure -Key $key
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Security.SecureString]$SecureString,

        [Parameter(Mandatory = $false)]
        [object]$Key
    )

    process {
        try {
            if ($Key) {
                # Convert key if Base64 string
                if ($Key -is [string]) {
                    $keyBytes = [Convert]::FromBase64String($Key)
                }
                else {
                    $keyBytes = $Key
                }

                return ConvertFrom-SecureString -SecureString $SecureString -Key $keyBytes
            }
            else {
                return ConvertFrom-SecureString -SecureString $SecureString
            }
        }
        catch {
            throw "Failed to convert SecureString: $_"
        }
    }
}

function ConvertFrom-EncryptedString {
    <#
    .SYNOPSIS
        Converts an encrypted string back to a SecureString.

    .DESCRIPTION
        Converts an encrypted string (from ConvertTo-EncryptedString) back to a SecureString.

    .PARAMETER EncryptedString
        The encrypted string to convert.

    .PARAMETER Key
        The encryption key if one was used during encryption.

    .PARAMETER AsPlainText
        Return as plain text string instead of SecureString.

    .EXAMPLE
        $secure = ConvertFrom-EncryptedString -EncryptedString $encrypted

    .EXAMPLE
        $plainText = ConvertFrom-EncryptedString -EncryptedString $encrypted -Key $key -AsPlainText
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$EncryptedString,

        [Parameter(Mandatory = $false)]
        [object]$Key,

        [Parameter(Mandatory = $false)]
        [switch]$AsPlainText
    )

    process {
        try {
            if ($Key) {
                # Convert key if Base64 string
                if ($Key -is [string]) {
                    $keyBytes = [Convert]::FromBase64String($Key)
                }
                else {
                    $keyBytes = $Key
                }

                $secureString = ConvertTo-SecureString -String $EncryptedString -Key $keyBytes
            }
            else {
                $secureString = ConvertTo-SecureString -String $EncryptedString
            }

            if ($AsPlainText) {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                try {
                    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                }
                finally {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
            }
            else {
                return $secureString
            }
        }
        catch {
            throw "Failed to convert encrypted string: $_"
        }
    }
}

function New-SecureStringFromPlainText {
    <#
    .SYNOPSIS
        Creates a SecureString from plain text.

    .DESCRIPTION
        Converts a plain text string to a SecureString.

    .PARAMETER PlainText
        The plain text to convert.

    .EXAMPLE
        $secure = New-SecureStringFromPlainText -PlainText "MyPassword"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$PlainText
    )

    try {
        $secureString = New-Object System.Security.SecureString
        foreach ($char in $PlainText.ToCharArray()) {
            $secureString.AppendChar($char)
        }
        $secureString.MakeReadOnly()
        return $secureString
    }
    catch {
        throw "Failed to create SecureString: $_"
    }
}

function Get-PlainTextFromSecureString {
    <#
    .SYNOPSIS
        Extracts plain text from a SecureString.

    .DESCRIPTION
        Converts a SecureString back to plain text. Use with caution.

    .PARAMETER SecureString
        The SecureString to convert.

    .EXAMPLE
        $plainText = Get-PlainTextFromSecureString -SecureString $secure
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Security.SecureString]$SecureString
    )

    process {
        try {
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            try {
                return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
        catch {
            throw "Failed to extract plain text: $_"
        }
    }
}

# ============================================================================
# Hash Functions
# ============================================================================

function Get-StringHash {
    <#
    .SYNOPSIS
        Generates a hash of a string.

    .DESCRIPTION
        Creates a cryptographic hash of the input string.

    .PARAMETER InputString
        The string to hash.

    .PARAMETER Algorithm
        Hash algorithm: SHA256, SHA384, SHA512, MD5, SHA1.

    .PARAMETER AsBytes
        Return hash as byte array instead of hex string.

    .EXAMPLE
        $hash = Get-StringHash -InputString "Hello World"

    .EXAMPLE
        $hash = Get-StringHash -InputString "Hello World" -Algorithm SHA512
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $false)]
        [ValidateSet('SHA256', 'SHA384', 'SHA512', 'MD5', 'SHA1')]
        [string]$Algorithm = 'SHA256',

        [Parameter(Mandatory = $false)]
        [switch]$AsBytes
    )

    process {
        try {
            $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
            $inputBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
            $hashBytes = $hasher.ComputeHash($inputBytes)
            $hasher.Dispose()

            if ($AsBytes) {
                return $hashBytes
            }
            else {
                return [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
            }
        }
        catch {
            throw "Failed to generate hash: $_"
        }
    }
}

function Test-StringHash {
    <#
    .SYNOPSIS
        Verifies a string against a hash.

    .DESCRIPTION
        Checks if a string matches a given hash value.

    .PARAMETER InputString
        The string to verify.

    .PARAMETER Hash
        The hash to compare against.

    .PARAMETER Algorithm
        Hash algorithm used.

    .EXAMPLE
        if (Test-StringHash -InputString "Hello" -Hash $storedHash) {
            Write-Host "Match!"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $true)]
        [string]$Hash,

        [Parameter(Mandatory = $false)]
        [ValidateSet('SHA256', 'SHA384', 'SHA512', 'MD5', 'SHA1')]
        [string]$Algorithm = 'SHA256'
    )

    try {
        $computedHash = Get-StringHash -InputString $InputString -Algorithm $Algorithm
        return $computedHash -eq $Hash.ToLower()
    }
    catch {
        throw "Failed to verify hash: $_"
    }
}

# ============================================================================
# File Encryption Functions
# ============================================================================

function Protect-File {
    <#
    .SYNOPSIS
        Encrypts a file using AES encryption.

    .DESCRIPTION
        Encrypts a file and saves the encrypted version.

    .PARAMETER FilePath
        Path to the file to encrypt.

    .PARAMETER Key
        The encryption key.

    .PARAMETER OutputPath
        Path for the encrypted file. Default: original path with .encrypted extension.

    .PARAMETER DeleteOriginal
        Delete the original file after encryption.

    .EXAMPLE
        Protect-File -FilePath "C:\data.txt" -Key $key

    .EXAMPLE
        Protect-File -FilePath "C:\data.txt" -Key $key -OutputPath "C:\data.enc" -DeleteOriginal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [object]$Key,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$DeleteOriginal
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        # Convert key if Base64 string
        if ($Key -is [string]) {
            $keyBytes = [Convert]::FromBase64String($Key)
        }
        else {
            $keyBytes = $Key
        }

        # Set output path
        if (-not $OutputPath) {
            $OutputPath = "$FilePath.encrypted"
        }

        # Read file content
        $fileContent = [System.IO.File]::ReadAllBytes($FilePath)

        # Create AES encryptor
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = $keyBytes.Length * 8
        $aes.Key = $keyBytes
        $aes.GenerateIV()
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        # Encrypt
        $encryptor = $aes.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($fileContent, 0, $fileContent.Length)

        # Combine IV and encrypted data
        $result = New-Object byte[] ($aes.IV.Length + $encryptedBytes.Length)
        [Array]::Copy($aes.IV, 0, $result, 0, $aes.IV.Length)
        [Array]::Copy($encryptedBytes, 0, $result, $aes.IV.Length, $encryptedBytes.Length)

        # Write encrypted file
        [System.IO.File]::WriteAllBytes($OutputPath, $result)

        # Cleanup
        $encryptor.Dispose()
        $aes.Dispose()

        # Delete original if requested
        if ($DeleteOriginal) {
            Remove-Item -Path $FilePath -Force
        }

        Write-Verbose "File encrypted: $OutputPath"

        return [PSCustomObject]@{
            OriginalFile   = $FilePath
            EncryptedFile  = $OutputPath
            OriginalSize   = $fileContent.Length
            EncryptedSize  = $result.Length
        }
    }
    catch {
        throw "File encryption failed: $_"
    }
}

function Unprotect-File {
    <#
    .SYNOPSIS
        Decrypts a file that was encrypted with Protect-File.

    .DESCRIPTION
        Decrypts an encrypted file and saves the decrypted version.

    .PARAMETER FilePath
        Path to the encrypted file.

    .PARAMETER Key
        The encryption key.

    .PARAMETER OutputPath
        Path for the decrypted file.

    .PARAMETER DeleteEncrypted
        Delete the encrypted file after decryption.

    .EXAMPLE
        Unprotect-File -FilePath "C:\data.encrypted" -Key $key -OutputPath "C:\data.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [object]$Key,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$DeleteEncrypted
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        # Convert key if Base64 string
        if ($Key -is [string]) {
            $keyBytes = [Convert]::FromBase64String($Key)
        }
        else {
            $keyBytes = $Key
        }

        # Read encrypted file
        $encryptedBytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Create AES decryptor
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = $keyBytes.Length * 8
        $aes.Key = $keyBytes
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        # Extract IV
        $iv = New-Object byte[] 16
        [Array]::Copy($encryptedBytes, 0, $iv, 0, 16)
        $aes.IV = $iv

        # Extract encrypted data
        $dataLength = $encryptedBytes.Length - 16
        $encryptedData = New-Object byte[] $dataLength
        [Array]::Copy($encryptedBytes, 16, $encryptedData, 0, $dataLength)

        # Decrypt
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)

        # Write decrypted file
        [System.IO.File]::WriteAllBytes($OutputPath, $decryptedBytes)

        # Cleanup
        $decryptor.Dispose()
        $aes.Dispose()

        # Delete encrypted if requested
        if ($DeleteEncrypted) {
            Remove-Item -Path $FilePath -Force
        }

        Write-Verbose "File decrypted: $OutputPath"

        return [PSCustomObject]@{
            EncryptedFile  = $FilePath
            DecryptedFile  = $OutputPath
            DecryptedSize  = $decryptedBytes.Length
        }
    }
    catch {
        throw "File decryption failed: $_"
    }
}

# ============================================================================
# Utility Functions
# ============================================================================

function New-RandomPassword {
    <#
    .SYNOPSIS
        Generates a random password.

    .DESCRIPTION
        Creates a cryptographically secure random password.

    .PARAMETER Length
        Password length. Default: 16.

    .PARAMETER IncludeSpecial
        Include special characters.

    .PARAMETER ExcludeAmbiguous
        Exclude ambiguous characters (0, O, l, 1, I).

    .PARAMETER AsSecureString
        Return as SecureString instead of plain text.

    .EXAMPLE
        $password = New-RandomPassword -Length 20 -IncludeSpecial

    .EXAMPLE
        $securePassword = New-RandomPassword -AsSecureString
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(8, 128)]
        [int]$Length = 16,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecial,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeAmbiguous,

        [Parameter(Mandatory = $false)]
        [switch]$AsSecureString
    )

    try {
        $lowercase = 'abcdefghijklmnopqrstuvwxyz'
        $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        $numbers = '0123456789'
        $special = '!@#$%^&*()_+-=[]{}|;:,.<>?'

        if ($ExcludeAmbiguous) {
            $lowercase = $lowercase -replace '[l]', ''
            $uppercase = $uppercase -replace '[OI]', ''
            $numbers = $numbers -replace '[01]', ''
        }

        $charSet = $lowercase + $uppercase + $numbers
        if ($IncludeSpecial) {
            $charSet += $special
        }

        $charArray = $charSet.ToCharArray()
        $password = New-Object char[] $Length

        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $randomBytes = New-Object byte[] $Length

        $rng.GetBytes($randomBytes)

        for ($i = 0; $i -lt $Length; $i++) {
            $password[$i] = $charArray[$randomBytes[$i] % $charArray.Length]
        }

        $rng.Dispose()

        $passwordString = -join $password

        if ($AsSecureString) {
            return New-SecureStringFromPlainText -PlainText $passwordString
        }
        else {
            return $passwordString
        }
    }
    catch {
        throw "Failed to generate password: $_"
    }
}

function Test-EncryptedString {
    <#
    .SYNOPSIS
        Tests if a string appears to be encrypted.

    .DESCRIPTION
        Checks if a string appears to be Base64-encoded encrypted data.

    .PARAMETER InputString
        The string to test.

    .EXAMPLE
        if (Test-EncryptedString -InputString $data) {
            Write-Host "Data appears to be encrypted"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$InputString
    )

    try {
        # Check if it's valid Base64
        if ($InputString -match '^[A-Za-z0-9+/=]+$' -and $InputString.Length % 4 -eq 0) {
            $bytes = [Convert]::FromBase64String($InputString)
            # Encrypted data should be at least IV (16 bytes) + some data
            return $bytes.Length -gt 16
        }
        return $false
    }
    catch {
        return $false
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # Key management
    'New-EncryptionKey',
    'Export-EncryptionKey',
    'Import-EncryptionKey',

    # AES encryption
    'Protect-String',
    'Unprotect-String',

    # DPAPI
    'Protect-StringWithDPAPI',
    'Unprotect-StringWithDPAPI',

    # SecureString
    'ConvertTo-EncryptedString',
    'ConvertFrom-EncryptedString',
    'New-SecureStringFromPlainText',
    'Get-PlainTextFromSecureString',

    # Hashing
    'Get-StringHash',
    'Test-StringHash',

    # File encryption
    'Protect-File',
    'Unprotect-File',

    # Utilities
    'New-RandomPassword',
    'Test-EncryptedString'
)
