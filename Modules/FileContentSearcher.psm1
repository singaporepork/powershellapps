<#
.SYNOPSIS
    Modular PowerShell script for searching contents of files.

.DESCRIPTION
    This module provides comprehensive functions for searching text within files,
    with support for regex, multiple patterns, context lines, and various output formats.
    Compatible with PowerShell 5.0 and later.

.NOTES
    Author: PowerShell Automation
    Version: 1.0.0
    Requires: PowerShell 5.0+
#>

#Requires -Version 5.0

# ============================================================================
# Core Search Functions
# ============================================================================

function Search-FileContent {
    <#
    .SYNOPSIS
        Searches for text patterns in file contents.

    .DESCRIPTION
        Searches files for specified text or regex patterns with various filtering options.

    .PARAMETER Path
        Path to search (file or directory).

    .PARAMETER Pattern
        Text or regex pattern to search for.

    .PARAMETER Include
        File patterns to include (e.g., "*.txt", "*.log").

    .PARAMETER Exclude
        File patterns to exclude.

    .PARAMETER Recurse
        Search subdirectories recursively.

    .PARAMETER CaseSensitive
        Perform case-sensitive search.

    .PARAMETER SimpleMatch
        Treat pattern as literal text, not regex.

    .PARAMETER Context
        Number of context lines before and after match.

    .PARAMETER ContextBefore
        Number of lines before match.

    .PARAMETER ContextAfter
        Number of lines after match.

    .PARAMETER List
        Return only file names, not match details.

    .PARAMETER NotMatch
        Return lines that don't match the pattern.

    .PARAMETER AllMatches
        Return all matches per line (for regex).

    .PARAMETER Encoding
        File encoding (Default, UTF8, ASCII, etc.).

    .EXAMPLE
        Search-FileContent -Path "C:\Logs" -Pattern "error" -Include "*.log" -Recurse

    .EXAMPLE
        Search-FileContent -Path "C:\Code" -Pattern "TODO" -Include "*.cs","*.js" -Recurse -CaseSensitive

    .EXAMPLE
        Search-FileContent -Path "C:\Config" -Pattern "password" -Context 2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$SimpleMatch,

        [Parameter(Mandatory = $false)]
        [int]$Context,

        [Parameter(Mandatory = $false)]
        [int]$ContextBefore,

        [Parameter(Mandatory = $false)]
        [int]$ContextAfter,

        [Parameter(Mandatory = $false)]
        [switch]$List,

        [Parameter(Mandatory = $false)]
        [switch]$NotMatch,

        [Parameter(Mandatory = $false)]
        [switch]$AllMatches,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = 'Default'
    )

    try {
        # Build Get-ChildItem parameters
        $gciParams = @{
            Path = $Path
            File = $true
        }

        if ($Recurse) {
            $gciParams['Recurse'] = $true
        }

        # Get files
        $files = @()
        foreach ($pattern in $Include) {
            $gciParams['Filter'] = $pattern
            $files += Get-ChildItem @gciParams -ErrorAction SilentlyContinue
        }

        # Remove duplicates
        $files = $files | Sort-Object FullName -Unique

        # Apply exclusions
        if ($Exclude) {
            foreach ($exc in $Exclude) {
                $files = $files | Where-Object { $_.Name -notlike $exc }
            }
        }

        if ($files.Count -eq 0) {
            Write-Verbose "No files found matching criteria"
            return @()
        }

        # Build Select-String parameters
        $ssParams = @{
            Pattern     = $Pattern
            Encoding    = $Encoding
        }

        if ($CaseSensitive) {
            $ssParams['CaseSensitive'] = $true
        }

        if ($SimpleMatch) {
            $ssParams['SimpleMatch'] = $true
        }

        if ($Context) {
            $ssParams['Context'] = $Context
        }
        else {
            if ($ContextBefore) {
                $ssParams['Context'] = @($ContextBefore, 0)
            }
            if ($ContextAfter) {
                if ($ssParams.ContainsKey('Context')) {
                    $ssParams['Context'] = @($ContextBefore, $ContextAfter)
                }
                else {
                    $ssParams['Context'] = @(0, $ContextAfter)
                }
            }
        }

        if ($List) {
            $ssParams['List'] = $true
        }

        if ($NotMatch) {
            $ssParams['NotMatch'] = $true
        }

        if ($AllMatches) {
            $ssParams['AllMatches'] = $true
        }

        # Perform search
        $results = $files | Select-String @ssParams

        # Format output
        if ($List) {
            return $results | ForEach-Object {
                [PSCustomObject]@{
                    FileName = $_.Filename
                    Path     = $_.Path
                }
            }
        }
        else {
            return $results | ForEach-Object {
                $result = [PSCustomObject]@{
                    FileName   = $_.Filename
                    Path       = $_.Path
                    LineNumber = $_.LineNumber
                    Line       = $_.Line
                    Pattern    = $_.Pattern
                }

                # Add context if present
                if ($_.Context) {
                    $result | Add-Member -NotePropertyName 'PreContext' -NotePropertyValue ($_.Context.PreContext -join "`n")
                    $result | Add-Member -NotePropertyName 'PostContext' -NotePropertyValue ($_.Context.PostContext -join "`n")
                }

                # Add matches if AllMatches
                if ($AllMatches -and $_.Matches) {
                    $result | Add-Member -NotePropertyName 'Matches' -NotePropertyValue ($_.Matches.Value -join ', ')
                }

                $result
            }
        }
    }
    catch {
        throw "Search failed: $_"
    }
}

function Find-TextInFiles {
    <#
    .SYNOPSIS
        Finds files containing specified text.

    .DESCRIPTION
        Returns list of files that contain the specified text pattern.

    .PARAMETER Path
        Directory to search.

    .PARAMETER Pattern
        Text pattern to find.

    .PARAMETER Include
        File patterns to include.

    .PARAMETER Recurse
        Search subdirectories.

    .PARAMETER CaseSensitive
        Case-sensitive search.

    .PARAMETER SimpleMatch
        Literal text match.

    .EXAMPLE
        Find-TextInFiles -Path "C:\Projects" -Pattern "deprecated" -Include "*.cs" -Recurse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$SimpleMatch
    )

    $params = @{
        Path          = $Path
        Pattern       = $Pattern
        Include       = $Include
        Recurse       = $Recurse
        List          = $true
        CaseSensitive = $CaseSensitive
        SimpleMatch   = $SimpleMatch
    }

    Search-FileContent @params
}

function Test-FileContainsText {
    <#
    .SYNOPSIS
        Tests if a file contains specified text.

    .DESCRIPTION
        Returns true if the file contains the pattern, false otherwise.

    .PARAMETER FilePath
        Path to the file.

    .PARAMETER Pattern
        Pattern to search for.

    .PARAMETER CaseSensitive
        Case-sensitive search.

    .PARAMETER SimpleMatch
        Literal text match.

    .EXAMPLE
        if (Test-FileContainsText -FilePath "config.xml" -Pattern "debug=true") {
            Write-Host "Debug mode is enabled"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$SimpleMatch
    )

    try {
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            throw "File not found: $FilePath"
        }

        $params = @{
            Path        = $FilePath
            Pattern     = $Pattern
            Quiet       = $true
        }

        if ($CaseSensitive) {
            $params['CaseSensitive'] = $true
        }

        if ($SimpleMatch) {
            $params['SimpleMatch'] = $true
        }

        return Select-String @params
    }
    catch {
        throw "Test failed: $_"
    }
}

# ============================================================================
# Multi-Pattern Search Functions
# ============================================================================

function Search-FileContentMultiple {
    <#
    .SYNOPSIS
        Searches for multiple patterns in files.

    .DESCRIPTION
        Searches files for multiple patterns simultaneously.

    .PARAMETER Path
        Path to search.

    .PARAMETER Patterns
        Array of patterns to search for.

    .PARAMETER Include
        File patterns to include.

    .PARAMETER Recurse
        Search subdirectories.

    .PARAMETER CaseSensitive
        Case-sensitive search.

    .PARAMETER MatchAll
        File must contain all patterns.

    .EXAMPLE
        Search-FileContentMultiple -Path "C:\Logs" -Patterns "error","warning","critical" -Include "*.log"

    .EXAMPLE
        Search-FileContentMultiple -Path "C:\Code" -Patterns "TODO","FIXME","HACK" -Recurse -MatchAll
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Patterns,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$MatchAll
    )

    try {
        $allResults = @()

        foreach ($pattern in $Patterns) {
            $params = @{
                Path          = $Path
                Pattern       = $pattern
                Include       = $Include
                Recurse       = $Recurse
                CaseSensitive = $CaseSensitive
            }

            $results = Search-FileContent @params
            $allResults += $results
        }

        if ($MatchAll) {
            # Group by file and check if all patterns found
            $groupedByFile = $allResults | Group-Object Path
            $matchingFiles = $groupedByFile | Where-Object {
                $filePatterns = $_.Group.Pattern | Sort-Object -Unique
                $allFound = $true
                foreach ($p in $Patterns) {
                    if ($p -notin $filePatterns) {
                        $allFound = $false
                        break
                    }
                }
                $allFound
            }

            return $matchingFiles.Group
        }
        else {
            return $allResults | Sort-Object Path, LineNumber
        }
    }
    catch {
        throw "Multi-pattern search failed: $_"
    }
}

# ============================================================================
# Search and Replace Functions
# ============================================================================

function Replace-FileContent {
    <#
    .SYNOPSIS
        Replaces text in file contents.

    .DESCRIPTION
        Finds and replaces text patterns in files.

    .PARAMETER Path
        Path to search.

    .PARAMETER Pattern
        Pattern to find.

    .PARAMETER Replacement
        Replacement text.

    .PARAMETER Include
        File patterns to include.

    .PARAMETER Recurse
        Search subdirectories.

    .PARAMETER CaseSensitive
        Case-sensitive search.

    .PARAMETER SimpleMatch
        Treat pattern as literal text.

    .PARAMETER WhatIf
        Show what would be replaced without making changes.

    .PARAMETER CreateBackup
        Create .bak backup files before replacing.

    .EXAMPLE
        Replace-FileContent -Path "C:\Config" -Pattern "localhost" -Replacement "server01" -Include "*.config"

    .EXAMPLE
        Replace-FileContent -Path "C:\Code" -Pattern "oldFunction" -Replacement "newFunction" -Include "*.cs" -Recurse -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$Replacement,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [switch]$SimpleMatch,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )

    try {
        # Find files with matches first
        $searchParams = @{
            Path          = $Path
            Pattern       = $Pattern
            Include       = $Include
            Recurse       = $Recurse
            CaseSensitive = $CaseSensitive
            SimpleMatch   = $SimpleMatch
            List          = $true
        }

        $filesToProcess = Search-FileContent @searchParams

        if (-not $filesToProcess) {
            Write-Verbose "No files found containing the pattern"
            return @()
        }

        $results = @()

        foreach ($file in $filesToProcess) {
            $filePath = $file.Path

            if ($PSCmdlet.ShouldProcess($filePath, "Replace '$Pattern' with '$Replacement'")) {
                # Create backup if requested
                if ($CreateBackup) {
                    Copy-Item -Path $filePath -Destination "$filePath.bak" -Force
                }

                # Read content
                $content = Get-Content -Path $filePath -Raw

                # Count matches before
                if ($SimpleMatch) {
                    if ($CaseSensitive) {
                        $matchCount = ([regex]::Matches($content, [regex]::Escape($Pattern))).Count
                    }
                    else {
                        $matchCount = ([regex]::Matches($content, [regex]::Escape($Pattern), 'IgnoreCase')).Count
                    }
                }
                else {
                    $regexOptions = if ($CaseSensitive) { 'None' } else { 'IgnoreCase' }
                    $matchCount = ([regex]::Matches($content, $Pattern, $regexOptions)).Count
                }

                # Perform replacement
                if ($SimpleMatch) {
                    if ($CaseSensitive) {
                        $newContent = $content.Replace($Pattern, $Replacement)
                    }
                    else {
                        $newContent = $content -ireplace [regex]::Escape($Pattern), $Replacement
                    }
                }
                else {
                    if ($CaseSensitive) {
                        $newContent = $content -creplace $Pattern, $Replacement
                    }
                    else {
                        $newContent = $content -ireplace $Pattern, $Replacement
                    }
                }

                # Write back
                Set-Content -Path $filePath -Value $newContent -NoNewline

                $results += [PSCustomObject]@{
                    FilePath     = $filePath
                    MatchCount   = $matchCount
                    Status       = 'Replaced'
                }

                Write-Verbose "Replaced $matchCount occurrence(s) in: $filePath"
            }
            else {
                $results += [PSCustomObject]@{
                    FilePath     = $filePath
                    MatchCount   = 0
                    Status       = 'WhatIf'
                }
            }
        }

        return $results
    }
    catch {
        throw "Replace operation failed: $_"
    }
}

# ============================================================================
# Export Functions
# ============================================================================

function Export-SearchResults {
    <#
    .SYNOPSIS
        Exports search results to a file.

    .DESCRIPTION
        Exports search results to CSV, JSON, or HTML format.

    .PARAMETER Results
        Search results to export.

    .PARAMETER OutputPath
        Output file path.

    .PARAMETER Format
        Output format: CSV, JSON, or HTML.

    .EXAMPLE
        $results = Search-FileContent -Path "C:\Logs" -Pattern "error" -Recurse
        Export-SearchResults -Results $results -OutputPath "C:\report.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CSV', 'JSON', 'HTML')]
        [string]$Format = 'CSV'
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        try {
            switch ($Format) {
                'CSV' {
                    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation
                }
                'JSON' {
                    $allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                'HTML' {
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Search Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .match { background-color: #ffff00; }
        pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <h1>Search Results</h1>
    <p>Total matches: $($allResults.Count)</p>
    <table>
        <tr>
            <th>File</th>
            <th>Line</th>
            <th>Content</th>
        </tr>
"@
                    foreach ($result in $allResults) {
                        $escapedLine = [System.Web.HttpUtility]::HtmlEncode($result.Line)
                        $html += @"
        <tr>
            <td>$($result.FileName)</td>
            <td>$($result.LineNumber)</td>
            <td><pre>$escapedLine</pre></td>
        </tr>
"@
                    }

                    $html += @"
    </table>
</body>
</html>
"@
                    Add-Type -AssemblyName System.Web
                    $html | Out-File -FilePath $OutputPath -Encoding UTF8
                }
            }

            Write-Verbose "Exported $($allResults.Count) results to: $OutputPath"

            return [PSCustomObject]@{
                OutputPath = $OutputPath
                Format     = $Format
                Count      = $allResults.Count
            }
        }
        catch {
            throw "Export failed: $_"
        }
    }
}

# ============================================================================
# Analysis Functions
# ============================================================================

function Get-SearchSummary {
    <#
    .SYNOPSIS
        Gets a summary of search results.

    .DESCRIPTION
        Analyzes search results and provides a summary by file.

    .PARAMETER Results
        Search results to analyze.

    .EXAMPLE
        $results = Search-FileContent -Path "C:\Logs" -Pattern "error"
        Get-SearchSummary -Results $results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$Results
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        if ($allResults.Count -eq 0) {
            return $null
        }

        $grouped = $allResults | Group-Object Path

        $summary = $grouped | ForEach-Object {
            [PSCustomObject]@{
                FileName   = Split-Path $_.Name -Leaf
                Path       = $_.Name
                MatchCount = $_.Count
                Lines      = ($_.Group.LineNumber | Sort-Object -Unique) -join ', '
            }
        }

        return $summary | Sort-Object MatchCount -Descending
    }
}

function Get-LineContext {
    <#
    .SYNOPSIS
        Gets lines around a specific line number in a file.

    .DESCRIPTION
        Retrieves context lines before and after a specified line.

    .PARAMETER FilePath
        Path to the file.

    .PARAMETER LineNumber
        Target line number.

    .PARAMETER Before
        Lines before the target.

    .PARAMETER After
        Lines after the target.

    .EXAMPLE
        Get-LineContext -FilePath "app.log" -LineNumber 100 -Before 5 -After 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$LineNumber,

        [Parameter(Mandatory = $false)]
        [int]$Before = 3,

        [Parameter(Mandatory = $false)]
        [int]$After = 3
    )

    try {
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            throw "File not found: $FilePath"
        }

        $lines = Get-Content -Path $FilePath
        $totalLines = $lines.Count

        $startLine = [Math]::Max(1, $LineNumber - $Before)
        $endLine = [Math]::Min($totalLines, $LineNumber + $After)

        $contextLines = @()

        for ($i = $startLine; $i -le $endLine; $i++) {
            $isTarget = ($i -eq $LineNumber)
            $contextLines += [PSCustomObject]@{
                LineNumber = $i
                Content    = $lines[$i - 1]
                IsMatch    = $isTarget
            }
        }

        return $contextLines
    }
    catch {
        throw "Failed to get context: $_"
    }
}

# ============================================================================
# Utility Functions
# ============================================================================

function Get-FilesByContent {
    <#
    .SYNOPSIS
        Gets files grouped by whether they contain a pattern.

    .DESCRIPTION
        Returns files categorized as matching or not matching a pattern.

    .PARAMETER Path
        Directory to search.

    .PARAMETER Pattern
        Pattern to search for.

    .PARAMETER Include
        File patterns to include.

    .PARAMETER Recurse
        Search subdirectories.

    .EXAMPLE
        $result = Get-FilesByContent -Path "C:\Config" -Pattern "debug" -Include "*.config"
        Write-Host "Files with debug: $($result.Matching.Count)"
        Write-Host "Files without debug: $($result.NotMatching.Count)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    try {
        # Get all files
        $gciParams = @{
            Path   = $Path
            File   = $true
        }

        if ($Recurse) {
            $gciParams['Recurse'] = $true
        }

        $allFiles = @()
        foreach ($inc in $Include) {
            $gciParams['Filter'] = $inc
            $allFiles += Get-ChildItem @gciParams -ErrorAction SilentlyContinue
        }

        $allFiles = $allFiles | Sort-Object FullName -Unique

        # Find matching files
        $matchingFiles = Find-TextInFiles -Path $Path -Pattern $Pattern -Include $Include -Recurse:$Recurse
        $matchingPaths = $matchingFiles.Path

        # Categorize
        $matching = $allFiles | Where-Object { $_.FullName -in $matchingPaths }
        $notMatching = $allFiles | Where-Object { $_.FullName -notin $matchingPaths }

        return [PSCustomObject]@{
            Matching    = $matching
            NotMatching = $notMatching
            Pattern     = $Pattern
        }
    }
    catch {
        throw "Failed to categorize files: $_"
    }
}

function Get-DuplicateLines {
    <#
    .SYNOPSIS
        Finds duplicate lines across files.

    .DESCRIPTION
        Identifies lines that appear in multiple files.

    .PARAMETER Path
        Directory to search.

    .PARAMETER Include
        File patterns to include.

    .PARAMETER Recurse
        Search subdirectories.

    .PARAMETER MinOccurrences
        Minimum occurrences to report.

    .EXAMPLE
        Get-DuplicateLines -Path "C:\Code" -Include "*.cs" -Recurse -MinOccurrences 3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [int]$MinOccurrences = 2
    )

    try {
        $gciParams = @{
            Path   = $Path
            File   = $true
        }

        if ($Recurse) {
            $gciParams['Recurse'] = $true
        }

        $files = @()
        foreach ($inc in $Include) {
            $gciParams['Filter'] = $inc
            $files += Get-ChildItem @gciParams -ErrorAction SilentlyContinue
        }

        $lineOccurrences = @{}

        foreach ($file in $files) {
            $lines = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
            $lineNumber = 0

            foreach ($line in $lines) {
                $lineNumber++
                $trimmedLine = $line.Trim()

                if ($trimmedLine.Length -gt 0) {
                    if (-not $lineOccurrences.ContainsKey($trimmedLine)) {
                        $lineOccurrences[$trimmedLine] = @()
                    }

                    $lineOccurrences[$trimmedLine] += [PSCustomObject]@{
                        File       = $file.FullName
                        LineNumber = $lineNumber
                    }
                }
            }
        }

        # Filter by minimum occurrences
        $duplicates = $lineOccurrences.GetEnumerator() |
            Where-Object { $_.Value.Count -ge $MinOccurrences } |
            Sort-Object { $_.Value.Count } -Descending |
            ForEach-Object {
                [PSCustomObject]@{
                    Line        = $_.Key
                    Occurrences = $_.Value.Count
                    Files       = ($_.Value.File | Sort-Object -Unique) -join '; '
                }
            }

        return $duplicates
    }
    catch {
        throw "Failed to find duplicates: $_"
    }
}

# ============================================================================
# Export Module Members
# ============================================================================

Export-ModuleMember -Function @(
    # Core search
    'Search-FileContent',
    'Find-TextInFiles',
    'Test-FileContainsText',

    # Multi-pattern
    'Search-FileContentMultiple',

    # Replace
    'Replace-FileContent',

    # Export
    'Export-SearchResults',

    # Analysis
    'Get-SearchSummary',
    'Get-LineContext',

    # Utilities
    'Get-FilesByContent',
    'Get-DuplicateLines'
)
