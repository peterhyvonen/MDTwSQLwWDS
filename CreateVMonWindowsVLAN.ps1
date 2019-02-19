Param ([string]$vm,
       [string]$role2apply
        )

Function Set-VMinVMWare {
    Param ($vm)
    Write-Verbose "Function New-MDTRecord with Parameters :: $vm"
    $prettyscsi = Get-ScsiController -VM $vm
    Set-ScsiController $prettyscsi -Type "VirtualLsiLogicSAS"
    $oldnic = Get-NetworkAdapter $vm
    Remove-NetworkAdapter -NetworkAdapter $oldnic -Confirm:$false
    Start-Sleep 5
    $vlan = get-networkadapter -vm $env:mdtserver
    New-NetworkAdapter $vm -Type "e1000" -NetworkName $vlan.NetworkName -StartConnected
}

Function Clean-NICforMDT {
    param ($vm)
    Write-Verbose "Function New-MDTRecord with Parameters :: $vm"
    $newnic = Get-NetworkAdapter $vm
    $nic += $vm + "," + $newnic.MacAddress + ";"
    $nic = $nic.split(";")
    return $nic
}

Function New-MDTRecord {
    param ($role2apply, $vm)
    Write-Verbose "Function New-MDTRecord with Parameters :: $role2apply :: $vm"
    $nic = Clean-NICforMDT -vm $vm
    Write-Verbose "Clean-NICforMDT returned $nic"
    $hostname, $maccolon = $nic.split(",")
    $maccolon = $maccolon.toUpper()
    $maccolon = $maccolon -replace " ", ""
    $macdash = $maccolon -replace ":", "-"
    $macdash = $macdash -replace " ", ""
    Write-Verbose "Mac Formatted as colon $maccolon as dash $macdash"
    $session = New-PSSession -computerName $env:mdtserver
    Invoke-Command -session $session -ScriptBlock {param($hostname, $macdash) WDSUTIL /add-device /device:$hostname /ID:$macdash} -Args $hostname, $macdash
    Invoke-Command -session $session -ScriptBlock {Import-Module E:\DeploymentShare\Tools\MDTDB\MDTDB.psm1} 
    Invoke-Command -session $session -ScriptBlock {Connect-MDTDatabase –sqlServer $env:sqlserver –instance SQLExpress4MDT –database MDTDB}
    Invoke-Command -session $session -ScriptBlock {param($hostname, $maccolon) New-MDTComputer -description $hostname –macAddress $maccolon –settings @{OSInstall='YES';OSDComputerName=$hostname}} -Args $hostname, $maccolon
    Invoke-Command -session $session -ScriptBlock {param($maccolon) $computer = Get-MDTComputer -macAddress $maccolon} -Args $maccolon 
    Invoke-Command -session $session -ScriptBlock {param($role2apply) Set-MDTComputerRole  -id $computer.id -roles $role2apply} -Args $role2apply
    Remove-PSSession $session
}
Connect-VIServer 1krkitvwvcntr01.tsi.lan
#Make ALL setting
#Move VMs to Number of VMs with same role
New-VM -Name $vm -Datastore $envvmwaredatastore -DiskGB 100 -DiskStorageFormat Thin -Location $env:vmwarelocation -MemoryGB 16 -NumCpu 8 -ResourcePool $env:vmwareresourcepool 
Start-Sleep 10
Set-VMinVMWare -vm $vm
Start-Sleep 10
New-MDTRecord -nic $nic -role2apply $role2apply -vm $vm
Start-Sleep 10
Start-VM -VM $vm
