<#
.SYNOPSIS
    Example usage of the FileContentSearcher module.

.DESCRIPTION
    This script demonstrates various file content searching functions provided by
    the FileContentSearcher module.

.NOTES
    Prerequisites:
    - Windows PowerShell 5.0 or later
#>

# Import the module
Import-Module "$PSScriptRoot\..\Modules\FileContentSearcher.psm1" -Force

Write-Host "FileContentSearcher Module Examples" -ForegroundColor Cyan
Write-Host "===================================`n" -ForegroundColor Cyan

# ============================================================================
# Example 1: Basic text search
# ============================================================================

Write-Host "Example 1: Basic text search" -ForegroundColor Yellow
Write-Host "----------------------------"

Write-Host @"
# Search for a pattern in a directory
`$results = Search-FileContent -Path "C:\Scripts" -Pattern "function"

# Display results
`$results | Format-Table Filename, LineNumber, Line -AutoSize

# Search with specific file filter
`$results = Search-FileContent -Path "C:\Scripts" -Pattern "Import-Module" -Include "*.ps1"
"@

Write-Host ""

# ============================================================================
# Example 2: Case-sensitive and regex search
# ============================================================================

Write-Host "Example 2: Case-sensitive and regex search" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host @"
# Case-sensitive search
`$results = Search-FileContent -Path "C:\Scripts" ``
    -Pattern "ERROR" ``
    -CaseSensitive

# Regex pattern search (find email addresses)
`$results = Search-FileContent -Path "C:\Logs" ``
    -Pattern "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

# Find IP addresses
`$results = Search-FileContent -Path "C:\Logs" ``
    -Pattern "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"

# Literal string match (no regex interpretation)
`$results = Search-FileContent -Path "C:\Code" ``
    -Pattern "[string]" ``
    -SimpleMatch
"@

Write-Host ""

# ============================================================================
# Example 3: Search with context lines
# ============================================================================

Write-Host "Example 3: Search with context lines" -ForegroundColor Yellow
Write-Host "------------------------------------"

Write-Host @"
# Get 2 lines before and after each match
`$results = Search-FileContent -Path "C:\Scripts" ``
    -Pattern "catch" ``
    -Context 2

# Display with context
foreach (`$result in `$results) {
    Write-Host "File: `$(`$result.Filename):`$(`$result.LineNumber)" -ForegroundColor Cyan

    # Show context before
    if (`$result.ContextBefore) {
        `$result.ContextBefore | ForEach-Object { Write-Host "  `$_" -ForegroundColor Gray }
    }

    # Show matched line
    Write-Host ">> `$(`$result.Line)" -ForegroundColor Yellow

    # Show context after
    if (`$result.ContextAfter) {
        `$result.ContextAfter | ForEach-Object { Write-Host "  `$_" -ForegroundColor Gray }
    }
    Write-Host ""
}
"@

Write-Host ""

# ============================================================================
# Example 4: Find text in files (simplified function)
# ============================================================================

Write-Host "Example 4: Find text in files" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Simple text search
`$results = Find-TextInFiles -Path "C:\Code" -Text "TODO"

# Search in specific file types
`$results = Find-TextInFiles -Path "C:\Code" ``
    -Text "deprecated" ``
    -FileTypes ".ps1", ".psm1"

# Recursive search in subdirectories (default)
`$results = Find-TextInFiles -Path "C:\Project" -Text "config"

# Non-recursive search
`$results = Find-TextInFiles -Path "C:\Project" -Text "config" -NoRecurse
"@

Write-Host ""

# ============================================================================
# Example 5: Test if file contains text
# ============================================================================

Write-Host "Example 5: Test if file contains text" -ForegroundColor Yellow
Write-Host "-------------------------------------"

Write-Host @"

# Check if a file contains specific text
if (Test-FileContainsText -Path "C:\config.ini" -Pattern "server=") {
    Write-Host "Configuration contains server setting"
}

# Case-sensitive check
`$hasError = Test-FileContainsText -Path "C:\app.log" ``
    -Pattern "ERROR" ``
    -CaseSensitive

# Check multiple files via pipeline
`$filesWithTODO = Get-ChildItem "C:\Scripts\*.ps1" |
    Where-Object { Test-FileContainsText -Path `$_.FullName -Pattern "TODO" }
"@

Write-Host ""

# ============================================================================
# Example 6: Multi-pattern search
# ============================================================================

Write-Host "Example 6: Multi-pattern search" -ForegroundColor Yellow
Write-Host "-------------------------------"

Write-Host @"
# Search for multiple patterns
`$patterns = @("error", "warning", "critical")
`$results = Search-FileContentMultiple -Path "C:\Logs" ``
    -Patterns `$patterns ``
    -Include "*.log"

# Require all patterns to match in same file
`$results = Search-FileContentMultiple -Path "C:\Config" ``
    -Patterns @("database", "password") ``
    -MatchAll

# Display grouped results
`$results | Group-Object Path | ForEach-Object {
    Write-Host "`nFile: `$(`$_.Name)" -ForegroundColor Cyan
    `$_.Group | ForEach-Object {
        Write-Host "  Line `$(`$_.LineNumber): `$(`$_.Line.Trim())"
    }
}
"@

Write-Host ""

# ============================================================================
# Example 7: Search and replace
# ============================================================================

Write-Host "Example 7: Search and replace" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Replace text in files (with backup)
`$replaced = Replace-FileContent -Path "C:\Scripts" ``
    -Pattern "old-server" ``
    -Replacement "new-server" ``
    -Include "*.config" ``
    -CreateBackup

# Replace without confirmation (be careful!)
Replace-FileContent -Path "C:\Code" ``
    -Pattern "deprecated_function" ``
    -Replacement "new_function" ``
    -Force

# Preview changes without applying (WhatIf)
Replace-FileContent -Path "C:\Scripts" ``
    -Pattern "localhost" ``
    -Replacement "192.168.1.100" ``
    -WhatIf

# Regex replacement
Replace-FileContent -Path "C:\Config" ``
    -Pattern "version=\d+\.\d+\.\d+" ``
    -Replacement "version=2.0.0" ``
    -CreateBackup
"@

Write-Host ""

# ============================================================================
# Example 8: Export search results
# ============================================================================

Write-Host "Example 8: Export search results" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host @"
# Search and export to CSV
`$results = Search-FileContent -Path "C:\Logs" -Pattern "error"
Export-SearchResults -Results `$results ``
    -OutputPath "C:\Reports\errors.csv" ``
    -Format CSV

# Export to JSON
Export-SearchResults -Results `$results ``
    -OutputPath "C:\Reports\errors.json" ``
    -Format JSON

# Export to HTML (includes styling)
Export-SearchResults -Results `$results ``
    -OutputPath "C:\Reports\errors.html" ``
    -Format HTML

# Export to plain text
Export-SearchResults -Results `$results ``
    -OutputPath "C:\Reports\errors.txt" ``
    -Format Text
"@

Write-Host ""

# ============================================================================
# Example 9: Get search summary
# ============================================================================

Write-Host "Example 9: Get search summary" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Get summary of search results
`$results = Search-FileContent -Path "C:\Logs" -Pattern "error|warning"
`$summary = Get-SearchSummary -Results `$results

# Display summary
Write-Host "Total Matches: `$(`$summary.TotalMatches)"
Write-Host "Files with Matches: `$(`$summary.FilesWithMatches)"
Write-Host "Unique Files: `$(`$summary.UniqueFiles -join ', ')"

# Summary includes file breakdown
`$summary.FileBreakdown | Format-Table File, MatchCount -AutoSize
"@

Write-Host ""

# ============================================================================
# Example 10: Get additional line context
# ============================================================================

Write-Host "Example 10: Get additional line context" -ForegroundColor Yellow
Write-Host "---------------------------------------"

Write-Host @"
# Get more context for a specific match
`$results = Search-FileContent -Path "C:\Scripts" -Pattern "function"
`$firstMatch = `$results | Select-Object -First 1

# Get 5 lines before and after
`$context = Get-LineContext -Path `$firstMatch.Path ``
    -LineNumber `$firstMatch.LineNumber ``
    -Before 5 ``
    -After 5

# Display context
Write-Host "Context around line `$(`$context.MatchLineNumber):" -ForegroundColor Cyan
foreach (`$line in `$context.Lines) {
    if (`$line.LineNumber -eq `$context.MatchLineNumber) {
        Write-Host ">> `$(`$line.LineNumber): `$(`$line.Content)" -ForegroundColor Yellow
    } else {
        Write-Host "   `$(`$line.LineNumber): `$(`$line.Content)"
    }
}
"@

Write-Host ""

# ============================================================================
# Example 11: Log file analysis
# ============================================================================

Write-Host "Example 11: Log file analysis" -ForegroundColor Yellow
Write-Host "-----------------------------"

Write-Host @"
# Analyze log files for errors
Import-Module ".\Modules\FileContentSearcher.psm1"

function Analyze-LogFiles {
    param(
        [string]`$LogPath,
        [string]`$OutputPath
    )

    # Search for different severity levels
    `$errors = Search-FileContent -Path `$LogPath ``
        -Pattern "ERROR|CRITICAL|FATAL" ``
        -Include "*.log" ``
        -Context 1

    `$warnings = Search-FileContent -Path `$LogPath ``
        -Pattern "WARNING|WARN" ``
        -Include "*.log"

    # Generate report
    `$report = [PSCustomObject]@{
        AnalyzedPath = `$LogPath
        ErrorCount = `$errors.Count
        WarningCount = `$warnings.Count
        ErrorSummary = Get-SearchSummary -Results `$errors
        WarningSummary = Get-SearchSummary -Results `$warnings
    }

    # Export errors to HTML for easy viewing
    if (`$errors) {
        Export-SearchResults -Results `$errors ``
            -OutputPath "`$OutputPath\errors.html" ``
            -Format HTML
    }

    return `$report
}

# Run analysis
`$report = Analyze-LogFiles -LogPath "C:\Logs" -OutputPath "C:\Reports"
`$report | Format-List
"@

Write-Host ""

# ============================================================================
# Example 12: Code audit - find security issues
# ============================================================================

Write-Host "Example 12: Code audit - find security issues" -ForegroundColor Yellow
Write-Host "----------------------------------------------"

Write-Host @"
# Search for potential security issues in code
Import-Module ".\Modules\FileContentSearcher.psm1"

function Find-SecurityIssues {
    param([string]`$CodePath)

    `$issues = @()

    # Hardcoded passwords
    `$passwords = Search-FileContent -Path `$CodePath ``
        -Pattern "password\s*=\s*[`"'][^`"']+[`"']" ``
        -Include "*.ps1", "*.config", "*.json"
    if (`$passwords) {
        `$issues += [PSCustomObject]@{
            Issue = "Hardcoded Password"
            Count = `$passwords.Count
            Results = `$passwords
        }
    }

    # Plain text credentials
    `$credentials = Search-FileContent -Path `$CodePath ``
        -Pattern "ConvertTo-SecureString.*-AsPlainText" ``
        -Include "*.ps1"
    if (`$credentials) {
        `$issues += [PSCustomObject]@{
            Issue = "Plain Text Credentials"
            Count = `$credentials.Count
            Results = `$credentials
        }
    }

    # Invoke-Expression (potential code injection)
    `$invokeExp = Search-FileContent -Path `$CodePath ``
        -Pattern "Invoke-Expression|iex\s+" ``
        -Include "*.ps1"
    if (`$invokeExp) {
        `$issues += [PSCustomObject]@{
            Issue = "Invoke-Expression Usage"
            Count = `$invokeExp.Count
            Results = `$invokeExp
        }
    }

    return `$issues
}

# Run audit
`$issues = Find-SecurityIssues -CodePath "C:\MyProject"
`$issues | ForEach-Object {
    Write-Host "`n`$(`$_.Issue): `$(`$_.Count) occurrences" -ForegroundColor Yellow
    `$_.Results | Select-Object -First 3 | ForEach-Object {
        Write-Host "  `$(`$_.Filename):`$(`$_.LineNumber)" -ForegroundColor Gray
    }
}
"@

Write-Host ""

# ============================================================================
# Example 13: Find and update configuration values
# ============================================================================

Write-Host "Example 13: Find and update configuration values" -ForegroundColor Yellow
Write-Host "------------------------------------------------"

Write-Host @"
# Update configuration across multiple files
Import-Module ".\Modules\FileContentSearcher.psm1"

function Update-ConfigValue {
    param(
        [string]`$ConfigPath,
        [string]`$Key,
        [string]`$OldValue,
        [string]`$NewValue
    )

    # First, find all occurrences
    `$pattern = "`$Key\s*=\s*`$OldValue"
    `$matches = Search-FileContent -Path `$ConfigPath ``
        -Pattern `$pattern ``
        -Include "*.config", "*.ini", "*.json"

    if (`$matches) {
        Write-Host "Found `$(`$matches.Count) occurrences to update"

        # Preview changes
        `$matches | ForEach-Object {
            Write-Host "  `$(`$_.Filename):`$(`$_.LineNumber)" -ForegroundColor Gray
        }

        # Perform replacement
        `$replacement = "`$Key=`$NewValue"
        Replace-FileContent -Path `$ConfigPath ``
            -Pattern `$pattern ``
            -Replacement `$replacement ``
            -Include "*.config", "*.ini" ``
            -CreateBackup

        Write-Host "Configuration updated successfully" -ForegroundColor Green
    } else {
        Write-Host "No matching configuration found" -ForegroundColor Yellow
    }
}

# Update database server across all configs
Update-ConfigValue -ConfigPath "C:\App\Config" ``
    -Key "DatabaseServer" ``
    -OldValue "old-db-server" ``
    -NewValue "new-db-server"
"@

Write-Host ""

# ============================================================================
# Example 14: Compare search results between directories
# ============================================================================

Write-Host "Example 14: Compare search results" -ForegroundColor Yellow
Write-Host "----------------------------------"

Write-Host @"
# Compare TODO items between branches/versions
Import-Module ".\Modules\FileContentSearcher.psm1"

function Compare-CodeSearches {
    param(
        [string]`$Path1,
        [string]`$Path2,
        [string]`$Pattern
    )

    `$results1 = Search-FileContent -Path `$Path1 -Pattern `$Pattern
    `$results2 = Search-FileContent -Path `$Path2 -Pattern `$Pattern

    `$summary1 = Get-SearchSummary -Results `$results1
    `$summary2 = Get-SearchSummary -Results `$results2

    [PSCustomObject]@{
        Pattern = `$Pattern
        Path1Matches = `$summary1.TotalMatches
        Path2Matches = `$summary2.TotalMatches
        Path1Files = `$summary1.FilesWithMatches
        Path2Files = `$summary2.FilesWithMatches
        Difference = `$summary2.TotalMatches - `$summary1.TotalMatches
    }
}

# Compare TODOs between old and new version
`$comparison = Compare-CodeSearches ``
    -Path1 "C:\Project\v1" ``
    -Path2 "C:\Project\v2" ``
    -Pattern "TODO|FIXME|HACK"

`$comparison | Format-List
"@

Write-Host ""

# ============================================================================
# Example 15: Pipeline usage
# ============================================================================

Write-Host "Example 15: Pipeline usage" -ForegroundColor Yellow
Write-Host "--------------------------"

Write-Host @"
# Using pipeline for advanced filtering

# Get files modified in last 7 days and search them
Get-ChildItem "C:\Logs" -Recurse -File |
    Where-Object { `$_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
    ForEach-Object {
        Search-FileContent -Path `$_.FullName -Pattern "error"
    } |
    Export-SearchResults -OutputPath "C:\Reports\recent_errors.csv" -Format CSV

# Search multiple directories
@("C:\App1\Logs", "C:\App2\Logs", "C:\App3\Logs") | ForEach-Object {
    Search-FileContent -Path `$_ -Pattern "critical"
} | Group-Object Path | Select-Object Name, Count

# Filter results by line content
`$results = Search-FileContent -Path "C:\Logs" -Pattern "error"
`$filteredResults = `$results | Where-Object {
    `$_.Line -notmatch "expected error|test error"
}
"@

Write-Host ""
Write-Host "Examples complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Tips for effective searching:" -ForegroundColor Gray
Write-Host "- Use -SimpleMatch for literal strings (faster, no regex)" -ForegroundColor Gray
Write-Host "- Use -Context to see surrounding lines for better understanding" -ForegroundColor Gray
Write-Host "- Use -Include to limit file types and improve performance" -ForegroundColor Gray
Write-Host "- Use Get-SearchSummary for quick overview of results" -ForegroundColor Gray
Write-Host "- Always use -CreateBackup when replacing content" -ForegroundColor Gray

