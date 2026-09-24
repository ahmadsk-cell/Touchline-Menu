$ErrorActionPreference='Stop'
function Get-ContainedPath([string]$Root,[string]$Relative) {
    if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)'){throw "Invalid relative path: $Relative"}
    $base=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $result=[IO.Path]::GetFullPath((Join-Path $base $Relative))
    if(!$result.StartsWith($base+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw "Path outside target: $Relative"}
    return $result
}
function Get-Sha([string]$Path) {
    $algorithm=[Security.Cryptography.SHA256]::Create()
    $stream=[IO.File]::OpenRead($Path)
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose();$algorithm.Dispose() }
}
function Copy-Checked([string]$Source,[string]$Destination,[string]$Hash) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination
    if((Get-Sha $Destination) -ne $Hash){throw "Copy verification failed: $Destination"}
}
