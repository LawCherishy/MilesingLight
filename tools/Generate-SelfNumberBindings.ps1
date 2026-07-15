[CmdletBinding()]
param(
    [ValidateSet('Check', 'Generate')]
    [string]$Mode = 'Check',

    [string]$Output = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrEmpty($Output)) {
    $Output = Join-Path $PSScriptRoot 'SELF_NUMBER_BINDINGS.generated.inc'
}

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ledger = Join-Path $repository 'docs\MILESINGS_LIGHT.md'
$tracked = Join-Path $repository 'src\Generated\SELF_NUMBER_BINDINGS.inc'
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$labels = @(
    'SELF NUMBER',
    'Operation',
    'Codable symbol',
    'Mathematical notation',
    'Origin',
    'Operands',
    'Function',
    'Reason',
    'Actual C++ use',
    'Direct proof'
)

function Read-StrictUtf8([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    return [pscustomobject]@{
        Bytes = $bytes
        Text = $utf8.GetString($bytes)
    }
}

function Test-EqualBytes([byte[]]$Left, [byte[]]$Right) {
    if ($Left.Length -ne $Right.Length) { return $false }
    for ($index = 0; $index -lt $Left.Length; ++$index) {
        if ($Left[$index] -ne $Right[$index]) { return $false }
    }
    return $true
}

function Get-Sha256([byte[]]$Bytes) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function ConvertTo-CppBytes([byte[]]$Bytes) {
    $builder = [Text.StringBuilder]::new()
    $previousWasOctal = $false
    foreach ($value in $Bytes) {
        if ($previousWasOctal -and $value -ge 0x30 -and $value -le 0x39) {
            # MSVC warns when a decimal digit immediately follows a complete
            # three-digit octal escape. Adjacent literals preserve the exact
            # bytes and remove that purely lexical ambiguity.
            [void]$builder.Append('""')
        }
        if ($value -eq 0x22) {
            [void]$builder.Append('\"')
            $previousWasOctal = $false
        }
        elseif ($value -eq 0x5c) {
            [void]$builder.Append('\\')
            $previousWasOctal = $false
        }
        elseif ($value -ge 0x20 -and $value -le 0x7e) {
            [void]$builder.Append([char]$value)
            $previousWasOctal = $false
        }
        else {
            [void]$builder.Append(('\{0:000}' -f [Convert]::ToString($value, 8)))
            $previousWasOctal = $true
        }
    }
    return $builder.ToString()
}

$source = Read-StrictUtf8 $ledger

$entries = [Collections.Generic.List[object]]::new()
$current = $null
$expectedField = 0
$lines = [Text.RegularExpressions.Regex]::Split($source.Text, "\r\n|\n|\r")
foreach ($line in $lines) {
    $matchedField = -1
    for ($field = 0; $field -lt $labels.Count; ++$field) {
        $prefix = $labels[$field] + ': '
        if ($line.StartsWith($prefix, [StringComparison]::Ordinal)) {
            $matchedField = $field
            $value = $line.Substring($prefix.Length)
            break
        }
    }
    if ($matchedField -lt 0) { continue }

    if ($matchedField -eq 0) {
        if ($null -ne $current) {
            if ($expectedField -ne $labels.Count) {
                throw "Binding entry $($entries.Count) ended before all ten fields were supplied."
            }
            $entries.Add($current)
        }
        $current = [Collections.Generic.List[string]]::new()
        $expectedField = 0
    }
    if ($null -eq $current) {
        throw "Field '$($labels[$matchedField])' appeared before a SELF NUMBER field."
    }
    if ($matchedField -ne $expectedField) {
        throw "Binding entry $($entries.Count) expected '$($labels[$expectedField])' but found '$($labels[$matchedField])'."
    }
    if ([string]::IsNullOrEmpty($value)) {
        throw "Binding entry $($entries.Count) has an empty '$($labels[$matchedField])' field."
    }
    $current.Add($value)
    ++$expectedField
}
if ($null -ne $current) {
    if ($expectedField -ne $labels.Count) {
        throw 'The final binding entry ended before all ten fields were supplied.'
    }
    $entries.Add($current)
}
if ($entries.Count -ne 112) {
    throw "Expected 112 binding entries; found $($entries.Count)."
}

$names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$blob = [Collections.Generic.List[byte]]::new()
$spans = [Collections.Generic.List[object]]::new()
foreach ($entry in $entries) {
    if (-not $names.Add($entry[0])) {
        throw "Duplicate self number '$($entry[0])'."
    }
    $entrySpans = [Collections.Generic.List[object]]::new()
    foreach ($value in $entry) {
        $valueBytes = $utf8.GetBytes($value)
        if ([Array]::IndexOf($valueBytes, [byte]0) -ge 0) {
            throw "Binding field for '$($entry[0])' contains a NUL byte."
        }
        $entrySpans.Add([pscustomobject]@{ Offset = $blob.Count; Size = $valueBytes.Length })
        $blob.AddRange($valueBytes)
        $blob.Add(0)
    }
    $spans.Add($entrySpans)
}

# Prove the byte blob and generated spans reconstruct every authored value.
for ($entryIndex = 0; $entryIndex -lt $entries.Count; ++$entryIndex) {
    for ($fieldIndex = 0; $fieldIndex -lt $labels.Count; ++$fieldIndex) {
        $span = $spans[$entryIndex][$fieldIndex]
        $reconstructed = $utf8.GetString($blob.GetRange($span.Offset, $span.Size).ToArray())
        if ($reconstructed -cne $entries[$entryIndex][$fieldIndex]) {
            throw "Byte reconstruction failed for entry $entryIndex field $fieldIndex."
        }
    }
}

$sha256 = Get-Sha256 $source.Bytes
$builder = [Text.StringBuilder]::new()
[void]$builder.AppendLine('// Generated from the binding Milesing Light ledger. DO NOT EDIT BY HAND.')
[void]$builder.AppendLine('// The build-only checker reconstructs every field from this blob and span table.')
[void]$builder.AppendLine('namespace generated_self_number_bindings {')
[void]$builder.AppendLine('struct TextSpan { std::uint32_t offset; std::uint32_t size; };')
[void]$builder.AppendLine('inline constexpr std::size_t field_count = 10;')
[void]$builder.AppendLine('inline constexpr std::size_t entry_count = 112;')
[void]$builder.AppendLine("inline constexpr std::size_t source_byte_count = $($source.Bytes.Length);")
[void]$builder.AppendLine("inline constexpr std::string_view source_sha256 = `"$sha256`";")
[void]$builder.AppendLine('inline constexpr std::array<std::string_view, field_count> field_names{{')
foreach ($label in $labels) {
    [void]$builder.AppendLine(('    "{0}",' -f $label.Replace('\', '\\').Replace('"', '\"')))
}
[void]$builder.AppendLine('}};')
[void]$builder.AppendLine('inline constexpr char utf8_blob[] =')
foreach ($entry in $entries) {
    foreach ($value in $entry) {
        $escaped = ConvertTo-CppBytes $utf8.GetBytes($value)
        [void]$builder.AppendLine(('    "{0}\000"' -f $escaped))
    }
}
[void]$builder.AppendLine('    ;')
[void]$builder.AppendLine("inline constexpr std::size_t blob_byte_count = $($blob.Count);")
[void]$builder.AppendLine('inline constexpr TextSpan entry_fields[entry_count][field_count] = {')
foreach ($entrySpans in $spans) {
    [void]$builder.Append('    {')
    for ($field = 0; $field -lt $entrySpans.Count; ++$field) {
        if ($field -gt 0) { [void]$builder.Append(', ') }
        [void]$builder.Append(('{{{0}u, {1}u}}' -f $entrySpans[$field].Offset, $entrySpans[$field].Size))
    }
    [void]$builder.AppendLine('},')
}
[void]$builder.AppendLine('};')
[void]$builder.AppendLine('constexpr std::string_view value(std::size_t entry, std::size_t field) noexcept {')
[void]$builder.AppendLine('    if (entry >= entry_count || field >= field_count) return {};')
[void]$builder.AppendLine('    const TextSpan span = entry_fields[entry][field];')
[void]$builder.AppendLine('    return {utf8_blob + span.offset, span.size};')
[void]$builder.AppendLine('}')
[void]$builder.AppendLine('static_assert(sizeof(utf8_blob) - 1 == blob_byte_count);')
[void]$builder.AppendLine('static_assert(value(0, 0) == "MY LIGHT");')
[void]$builder.AppendLine('static_assert(value(entry_count - 1, 0) == "LIGHT TREATMENT");')
[void]$builder.AppendLine('} // namespace generated_self_number_bindings')
$expected = $builder.ToString().Replace("`r`n", "`n")

if ($Mode -eq 'Generate') {
    $outputPath = [IO.Path]::GetFullPath($Output)
    $toolRoot = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') + '\'
    if (-not $outputPath.StartsWith($toolRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Generated output is restricted to this repository tools directory.'
    }
    [IO.File]::WriteAllText($outputPath, $expected, $utf8)
}
else {
    $actual = (Read-StrictUtf8 $tracked).Text.Replace("`r`n", "`n")
    if ($actual -cne $expected) {
        throw 'Tracked SELF_NUMBER_BINDINGS.inc differs from deterministic ledger output.'
    }
}

Write-Output ("verified entries={0} fields={1} source_bytes={2} blob_bytes={3} sha256={4}" -f `
    $entries.Count, ($entries.Count * $labels.Count), $source.Bytes.Length, $blob.Count, $sha256)
