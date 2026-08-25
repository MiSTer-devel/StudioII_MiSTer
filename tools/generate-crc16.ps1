#requires -Version 5.1

<#
.SYNOPSIS
Recursively inventories ROM, BIN, and ST2 files using the Studio II core's CRC16.

.DESCRIPTION
The scan always starts in the folder containing this script. Every file with a
.rom, .bin, or .st2 extension is hashed, including firmware/resident-game ROMs.

The algorithm matches rtl/rcastudioii.sv: CRC16-CCITT, polynomial 0x1021,
initial value 0xFFFF, calculated over every exact byte in the file.

.PARAMETER OutputPath
Optional path for a UTF-8 text inventory. Relative paths are resolved from the
folder containing this script. Without this parameter, the inventory is written
to the pipeline and can be redirected in the usual PowerShell manner.

.EXAMPLE
.\Generate-CRC16Inventory.ps1

.EXAMPLE
.\Generate-CRC16Inventory.ps1 -OutputPath crc16-hashes.generated.txt
#>

[CmdletBinding()]
param(
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-StudioIICrc16 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $LiteralPath
    )

    $crc = 0xFFFF
    $buffer = New-Object byte[] 65536
    $stream = [System.IO.File]::Open(
        $LiteralPath,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )

    try {
        while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            for ($index = 0; $index -lt $count; $index++) {
                $crc = $crc -bxor ([int]$buffer[$index] -shl 8)

                for ($bit = 0; $bit -lt 8; $bit++) {
                    if (($crc -band 0x8000) -ne 0) {
                        $crc = (($crc -shl 1) -bxor 0x1021) -band 0xFFFF
                    }
                    else {
                        $crc = ($crc -shl 1) -band 0xFFFF
                    }
                }
            }
        }
    }
    finally {
        $stream.Dispose()
    }

    return ('{0:X4}' -f $crc)
}

$scanRoot = $PSScriptRoot
$wantedExtensions = @('.rom', '.bin', '.st2')

$files = @(
    Get-ChildItem -LiteralPath $scanRoot -File -Recurse |
        Where-Object { $wantedExtensions -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object FullName
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# RCA Studio II CRC16-CCITT inventory')
$lines.Add('# Polynomial: 0x1021; initial value: 0xFFFF; input: exact file bytes')
$lines.Add('# Scan root: folder containing this script')
$lines.Add("# Files: $($files.Count)")
$lines.Add('#')
$lines.Add("CRC16`tBytes`tExtension`tRelative path")

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($scanRoot.Length).TrimStart('\', '/')
    $crc = Get-StudioIICrc16 -LiteralPath $file.FullName
    $lines.Add("$crc`t$($file.Length)`t$($file.Extension.ToLowerInvariant())`t$relativePath")
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $lines
}
else {
    if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath = Join-Path -Path $scanRoot -ChildPath $OutputPath
    }

    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        throw "Output directory does not exist: $outputDirectory"
    }

    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($resolvedOutput, $lines, $utf8WithoutBom)
    Write-Host "Hashed $($files.Count) file(s). Inventory written to: $resolvedOutput"
}
