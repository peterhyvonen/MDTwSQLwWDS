$computers = Get-WdsClient
Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "E:\DeploymentShare"
$targets = Get-MDTMonitorData -Path DS001:
foreach ($target in $targets) {
    foreach ($computer in $computers) {
        if ($target.Name -eq $computer.DeviceName) {
            Remove-WdsClient -DeviceName $target.Name
        }
    }
}