Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
Import-Module "E:\DeploymentShare\Tools\MDTDB\MDTDB.psm1"
Connect-MDTDatabase -sqlSever $env:sqlserver -instance SQLExpress4MDT -database MDTDB
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "E:\DeploymentShare"
$targets = Get-MDTMonitorData -Path DS001:
$dbobjects = Get-MDTComputer
foreach ($target in $targets) {
	if ($target.PercentComplete -eq 100) {		
		foreach ($dbobject in $dbobjects) {
			if ($target.Name -eq $dbobject.OSDComputerName) {
        			Write-Host "Deleting $target.Name and $dbobject.OSDComputerName"
                    Remove-MDTComputer -ID $dbobject.id 
				    Remove-MDTMonitorData -ComputerObject $target
    			}
		}
	}
}