Function Set-OStype {
    Param ($type)
    if ($type -like "Win7Desk") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN7DESK-2016Q3\WIN7DESK-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\w7\amd64\netkvm.inf"
    }
    elseif ($type -like "Win8Desk") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN8DESK-2016Q3\WIN8DESK-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\w8.1\amd64\netkvm.inf"
    }
    elseif ($type -like "Win10Desk") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN10DESK-2016Q3\WIN10DESK-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\w10\amd64\netkvm.inf"
        }
    elseif ($type -like "Win08R2") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN8R2-2016Q3\WIN8R2-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\2k8R2\amd64\netkvm.inf"
        }
    elseif ($type -like "Win12R2") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN12R2-2016Q3\WIN12R2-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\2k12R2\amd64\netkvm.inf"
        }
    elseif ($type -like "Win16") {
        $WIMPath = "E:\DeploymentShare\Operating Systems\WIN16-2016Q3\WIN16-2016Q3.wim"
        $VirtPath = "H:\VirtIO\NetKVM\2k16\amd64\netkvm.inf"
        }
    else {
    }
    return $WIMPath, $VirtPath
}

Function New-DiskpartSilentFile {
    Param ($type)
    New-Item E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt -type file
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "create vdisk file=H:\VHD\$type.vhd maximum=15000 type=expandable"
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "select vdisk file=H:\VHD\$type.vhd"
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "attach vdisk "
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "create partition primary"
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "assign letter=v"
    Add-Content E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt "format quick FS=NTFS label=VHD"
}
Function Run-Diskpart {
    diskpart /s E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt
    Remove-Item E:\DeploymentShare\CustomMDTScripts\vhd4openstack.txt
}
Function New-BootableVHD {
    Param ($WIMPath)
    dism /Apply-Image /ImageFile:$WIMPath /index:1 /ApplyDir:V:\
    V:\Windows\System32\bcdboot V:\Windows
}
Function Add-DriversandSoftware {
    Param ($VirtPath)
    Dism /Image:V:\ /Add-Driver /Driver:$VirtPath
    Copy-Item "H:\Cloudbase Solutions" -Destination "V:\Program Files" -Recurse
}
$types = "Win7Desk", "Win8Desk", "Win10Desk", "Win08R2", "Win12R2"
foreach ($type in $types) {
    $WimPath, $VirtPath = Set-OStype -type $type 
    New-DiskpartSilentFile -type $type
    New-BootableVHD -WIMPath $WimPath
    Add-DriversandSoftware -VirtPath $VirtPath
    cd H:\VHD
    "C:\qemu-img-win-x64-2_3_0\qemu-img.exe convert -O qcow2 $type.vhd $type.qcow2"
    mountvol v: /p
}