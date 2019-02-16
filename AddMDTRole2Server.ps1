Import-Module E:\DeploymentShare\Tools\MDTDB\MDTDB.psm1
Connect-MDTDatabase –sqlServer $env:sqlservername –instance SQLExpress4MDT –database MDTDB
$database = Get-MDTComputer
$netnames = Get-Content "E:\temp\dracnames.txt"
$roles = Get-MDTRole
$i = 1
$j = 1
$role2apply
foreach ($label in $roles.role) {
   write-host "$i $label" 
   $i++
}
$number = Read-Host "Please enter the number for the role you wish to apply"

foreach ($role in $roles.role) {
    if ($number -eq $j)  {
        $role2apply = $role
        $role
    }
    $j++
}

foreach ($netname in $netnames) {
        $netname = $netname -replace "-drac" 
        $netname = $netname.ToUpper()
        foreach ($entry in $database) {
                if ($entry.OSDComputername -eq $netname) { 
                   $cname = $entry.OSDComputername
                   $id = $entry.ID
                   write-host "I found $netname and $cname"
                   write-host "applying $role2apply to $id"
                   Set-MDTComputerRole  -id $id -roles $role2apply
                }
        }
   }

foreach ($nname in $netnames) {
        $nname = $nname -replace "-drac" 
        $nname = $nname.ToUpper()
        foreach ($line in $database) {
                if ($line.OSDComputername -eq $nname) { 
                $unique = $line.ID
                $state = Get-MDTComputerRole -id $unique
                write-host "$nname found the following:"
                $state 
                }
        }
}
   
  