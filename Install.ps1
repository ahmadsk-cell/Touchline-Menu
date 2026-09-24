param([Parameter(Mandatory=$true)][string]$SiderDir)
. (Join-Path $PSScriptRoot 'scripts\Common.ps1')
$root=[IO.Path]::GetFullPath($SiderDir)
$iniPath=Get-ContainedPath $root 'sider.ini'
if(!(Test-Path -LiteralPath $iniPath -PathType Leaf)){throw 'Select the SiderAddons folder containing sider.ini.'}
foreach($required in @('livecpk\MenuC1987','livecpk\UIColors','modules\UIColors.lua')){
    if(!(Test-Path -LiteralPath (Get-ContainedPath $root $required))){throw "Install the required MenuC1987 and UIColors mods first. Missing: $required"}
}
$encoding=[Text.Encoding]::GetEncoding(28591)
$ini=$encoding.GetString([IO.File]::ReadAllBytes($iniPath))
foreach($pattern in @('(?mi)^[ \t]*cpk\.root[ \t]*=[ \t]*"\.\\livecpk\\MenuC1987"','(?mi)^[ \t]*cpk\.root[ \t]*=[ \t]*"\.\\livecpk\\UIColors"','(?mi)^[ \t]*lua\.module[ \t]*=[ \t]*"UIColors\.lua"')){
    if($ini -notmatch $pattern){throw 'Enable MenuC1987, UIColors LiveCPK and UIColors.lua in sider.ini before installing.'}
}
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
$changes=@();$seen=@{}
# Validate the entire payload before changing anything in the target game.
foreach($item in $manifest.files){
    if($seen.ContainsKey($item.path)){throw 'Duplicate manifest path'};$seen[$item.path]=$true
    if($item.path -notmatch '^livecpk/TouchlinePrologue2/' -and $item.path -ne 'content/ui-colors/map_exe.txt'){throw 'Unexpected payload path'}
    $source=Get-ContainedPath $PSScriptRoot $item.path
    $target=Get-ContainedPath $root $item.path
    if(!(Test-Path -LiteralPath $source -PathType Leaf) -or (Get-Sha $source) -ne $item.sha256){throw "Package checksum failed: $($item.path)"}
    $changes+=@{path=$item.path;source=$source;after=$item.sha256;before=$(if(Test-Path -LiteralPath $target){Get-Sha $target}else{$null})}
}
# Earlier development builds installed this obsolete override. Remove only a
# known development copy; never remove an independently modified file.
foreach($item in $manifest.retired){
    $target=Get-ContainedPath $root $item.path
    if(Test-Path -LiteralPath $target){
        $hash=Get-Sha $target
        if($item.known_sha256 -notcontains $hash){throw "An independently edited obsolete override exists: $($item.path). Move it aside before installing."}
        $changes+=@{path=$item.path;source=$null;after=$null;before=$hash}
    }
}
$newline=if($ini.Contains("`r`n")){"`r`n"}else{"`n"}
$clean=[regex]::Replace($ini,'(?mi)^[ \t]*cpk\.root[ \t]*=[ \t]*"\.\\livecpk\\TouchlinePrologue2"[^\r\n]*(\r?\n|$)','')
$first=[regex]::Match($clean,'(?mi)^[ \t]*cpk\.root[ \t]*=')
if(!$first.Success){throw 'No LiveCPK roots found in sider.ini.'}
$updated=$clean.Insert($first.Index,'cpk.root = ".\livecpk\TouchlinePrologue2"'+$newline)
$backup=Get-ContainedPath $root ('TouchlineMenu-backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup | Out-Null
$newIni=Join-Path $backup 'sider.ini.installed'
[IO.File]::WriteAllBytes($newIni,$encoding.GetBytes($updated))
$changes+=@{path='sider.ini';source=$newIni;after=(Get-Sha $newIni);before=(Get-Sha $iniPath)}
$receipt=@{schema=1;version=$manifest.version;status='prepared';files=@($changes | ForEach-Object {@{path=$_.path;before=$_.before;after=$_.after}})}
$receiptPath=Join-Path $backup 'receipt.json'
# Finish and verify every backup before installing or retiring any file.
foreach($change in $changes){
    if($null -ne $change.before){Copy-Checked (Get-ContainedPath $root $change.path) (Get-ContainedPath (Join-Path $backup 'files') $change.path) $change.before}
}
$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
try {
    foreach($change in $changes){
        $target=Get-ContainedPath $root $change.path
        if($null -ne $change.after){Copy-Checked $change.source $target $change.after}
        elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target}
    }
    $receipt.status='installed'
    $receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
} catch {
    foreach($change in $changes){
        $target=Get-ContainedPath $root $change.path
        if($null -ne $change.before){Copy-Checked (Get-ContainedPath (Join-Path $backup 'files') $change.path) $target $change.before}
        elseif(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target}
    }
    $receipt.status='rolled-back';$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
    throw
}
Write-Output "Installed Touchline Menu $($manifest.version). Restart Sider and Football Life."
Write-Output "Backup: $backup"
