param([Parameter(Mandatory=$true)][string]$SiderDir,[Parameter(Mandatory=$true)][string]$BackupDirectory)
. (Join-Path $PSScriptRoot 'scripts\Common.ps1')
$root=[IO.Path]::GetFullPath($SiderDir)
$backupRoot=Get-ContainedPath $root 'TouchlineMenu-backups'
$backup=[IO.Path]::GetFullPath($BackupDirectory)
if(!$backup.StartsWith($backupRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Choose a backup inside this SiderAddons/TouchlineMenu-backups folder.'}
$receiptPath=Join-Path $backup 'receipt.json'
$receipt=Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
if($receipt.status -ne 'installed'){throw 'This backup is not an installed release.'}
# Check every current and backed-up file first, preserving later user edits.
foreach($item in $receipt.files){
    $target=Get-ContainedPath $root $item.path
    if($null -ne $item.after){
        if(!(Test-Path -LiteralPath $target) -or (Get-Sha $target) -ne $item.after){throw "Changed since installation: $($item.path). Preserve your edits and restore this backup manually."}
    }elseif(Test-Path -LiteralPath $target){throw "A file was added after installation: $($item.path)"}
    if($null -ne $item.before){
        $saved=Get-ContainedPath (Join-Path $backup 'files') $item.path
        if(!(Test-Path -LiteralPath $saved) -or (Get-Sha $saved) -ne $item.before){throw "Backup verification failed: $($item.path)"}
    }
}
foreach($item in $receipt.files){
    $target=Get-ContainedPath $root $item.path
    if($null -ne $item.before){Copy-Checked (Get-ContainedPath (Join-Path $backup 'files') $item.path) $target $item.before}
    elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target}
}
$receipt.status='restored';$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
Write-Output 'Restored the previous files and Sider settings. Restart Sider and Football Life.'
