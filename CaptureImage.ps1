param ($vms)
# change the custom.ini to capture
$sessionwds = New-PSSession -computerName $env:mdtservername
Invoke-Command -session $sessionwds -ScriptBlock {(Get-Content E:\MDT\Templates\CustomSetting.ini).replace('SkipCapture=YES', 'SkipCapture=NO') | Set-Content E:\MDT\Templates\CustomSetting.ini }
# run the vbs script on the VM
foreach ($vm in $vms) {
    $sessionvm = New-PSSession -computerName $vm
    Invoke-Command -session $sessionvm -ScriptBlock {\\dvwds-inap02.dev.tsi.lan\DeploymentShare$\Scripts\LightTouch.vbs}
}
Invoke-Command -session $sessionwds -ScriptBlock {(Get-Content E:\MDT\Templates\CustomSetting.ini).replace('SkipCapture=NO', 'SkipCapture=YES') | Set-Content E:\MDT\Templates\CustomSetting.ini }