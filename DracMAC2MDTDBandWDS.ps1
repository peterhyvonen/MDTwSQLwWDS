Function GetDRACInfo {
Param ($netname, $SecurePassword)
    #Need to make password secure
    #query drac
    $SwitchLogon = "root"
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $SecureStringAsPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $SwitchCliCommand = "E:\temp\idrac-command.txt" #racadm getsysinfo
    $path = "C:\Program Files (x86)\PuTTY\plink.exe"
    $dracresults = echo y | & $path -l $SwitchLogon  -pw $SecureStringAsPlainText  -m $SwitchCliCommand $_ $netname
       
        return ($dracresults)
}

Function Check4Existing {
Param ($netname, $mac)
            Connect-MDTDatabase –sqlServer $env:sqlservername –instance SQLExpress4MDT –database MDTDB
            if (Get-MDTComputer -macAddress $mac) {
                Write-Host "$mac found $netname may already exist pleast check manaully"
            } 
            Else {
                Write-Host "Adding $netname and $mac to MDT Database"
                New-MDTComputer -description $netname –macAddress $mac –settings @{OSInstall='YES';OSDComputerName=$netname}
                $mac2 = $mac -replace ":","-"
                WDSUTIL /add-device /device:$netname /ID:$mac2
            }
}

Function Add2DataBase {
Param ($netname, $SecurePassword)
    #Need to add if DRAC Fails
    $dracresults = GetDRACInfo $netname $SecurePassword
    if ($dracresults -like "RAC Information*") {
            $dracresults
            foreach ($dracresult in $dracresults) {  
                    if ($dracresult -like "NIC.Integrated.1-1-1*") {
                        $mac = $dracresult
                        $mac = $mac -replace ".*= " 
                        $mac = $mac.Substring(0,17)
                        $mac = $mac.ToUpper()
                    }
                    
                    else {
                        #do nothing
                    }                
            }
            $netname = $netname -replace "-drac" 
            $netname = $netname.ToUpper()
            Check4Existing $netname $mac
        }
        else {
            Write-Host "Drac not found"
        }

      }

Function OpenFile {
    Param ([string]$filename)
    #Need to add if DRAC Fails
    write-host $filename
    $netnames = Get-Content $filename
    $SecurePassword = Read-Host 'password' -AsSecureString
    foreach ($netname in $netnames) {
        Add2DataBase $netname $SecurePassword

    }
}

Import-Module E:\DeploymentShare\Tools\MDTDB\MDTDB.psm1
$location = "E:\temp\dracnames.txt"
OpenFile -filename $location
$bool = Read-Host "Would you like to add a role?(y for yes, any other character for no):"
if ($bool -eq 'y') {
   E:\DeploymentShare\Tools\AddMDTRole2Server.ps1
}