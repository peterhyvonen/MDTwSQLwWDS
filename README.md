# MDTwSQLwWDS
No touch Microsoft Deployment Tools Solution
Setting Up an MDT server (CLI/Powershell)
Created by Pete Hyvonen
Prereqs
Windows 2012 R2 or better with NICs for the vlans you wish to PXE boot and a DHCP server (can go on the same box or just link to it). Disk Config should be as follows C 100GB,  E 200GB+ (Deployment Share, recommend 500GB). If you plan on doing 0 touch or using a database add S 10 GB (SQL Install), H 10 GB (Data, can be larger or smaller depending on how long you keep records), and L 10 GB (Logs)
Make a disk online Set-Disk -Number 1 -IsOffline $False;  Set-Disk -Number 1 -IsReadOnly $False (to prevent popups before partitioning run Stop-Service -Name ShellHWDetection)
Partition and format disk New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter E | Format-Volume
Set the drive label Set-Volume -DriveLetter E -NewFileSystemLabel "Share"
Set-ExecutionPolicy unrestricted
Enable-PSRemoting
Run windows updates if needed.
Some of the required files that will need to be downloaded include:
The Microsoft Assessment and Deployment Kit for Windows 8.1 Uppdate (adksetup.exe) http://www.microsoft.com/en-us/download/details.aspx?id=39982
MDT 2013 (MicrosoftDeploymentToolkit2013_x64.msi) https://www.microsoft.com/en-us/download/details.aspx?id=48595
Optional:
SQL Server Express with Tools (SQLEXPRWT_x64_ENU.exe) https://www.microsoft.com/en-us/server-cloud/products/sql-server-editions/sql-server-express.aspx
SQL CLI Silent Install (or make a custom ini yourself, see SQL Install steps below to walk you through making your own ini): SQLExpress4MDT.ini
MDTSQL Powershell Cmdlets http://blogs.technet.com/b/mniehaus/archive/2009/05/15/manipulating-the-microsoft-deployment-toolkit-database-using-powershell.aspx
 
Install WDS (Step 1)
Next install WDS via a administrator powershell window Add-WindowsFeature WDS
Configure WDS for stand alone with E:\RemoteInstall
Run from CMD
WDSUTIL /Initialize-Server /RemInst:"E:\RemoteInstall" /standalone
WDSUTIL /Set-Server /AnswerClients:Known
WDSUTIL /Set-Server /PxePromptPolicy /Known:NoPrompt
Shutdown -r -t0
Install ADK (Step 2)
I would always recommend downloading the ADK to a local folder or network share, since these files take a while to download and are commonly used in many Microsoft products, including System Center.
Run from CMD
adksetup.exe /quiet /installpath "E:\Windows Kits\10" /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.ImagingAndConfigurationDesigner OptionId.UserStateMigrationTool
wait for the directory to show up on E, takes 5-10 min.
Install SQL Express - Optional
Prereqs
Install .NET 3.5 with Add-WindowsFeature WAS-NET-Environment
From CLI
Setup.exe /ConfigurationFile=SQLExpress4MDT.INI /IAcceptSQLServerLicenseTerms
To make your own ini config file run (from the SQL directory) Setup.exe /ACTION=INSTALL /UIMODE=Normal
when done you will need to comment out UIMode and set Quiet="True" to have a silent install file.
Additional Configuration
Once complete you will need to configure SQLExpress for NamedPipes or TCP/IP (not working with TCP/IP yet)
Install MDT
Next, we’ll download the MDT 2013 install files from: http://www.microsoft.com/en-us/download/details.aspx?id=40796. Click Download:
From CLI
msiexec /i "MicrosoftDeploymentToolkit2013_x64.msi" INSTALLDIR="E:\MDT" /qb
 
Configuring Microsoft Deployment Tools
From CLI
$Folder = "E:\DeploymentShare"
$Share = "DeploymentShare$"
Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
New-Item -Path $Folder -Type Directory 
New-SmbShare –Name $Share –Path $Folder –FullAccess EVERYONE
New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root $Folder -NetworkPath "\\$ENV:COMPUTERNAME\$Share" -Description "Deployment Share" | Add-MDTPersistentDrive
(instructions to be written) Create a local user with permissions to the share
(instructions to be written) Copy the boot.ini and custom.ini file from git and replace the one in E:\DeploymentShare\Control

Optional - Configure MDT Database on SQL
Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
(Has Error) New-MDTDatabase -SQLServer "server name" -Instance "SQLExpress4MDT" -Netlib "DBMSSOCN" -Database "MDTDB"
 
Below Should work (Not Tested, use DBMSSOCN is for TCP/IP instead of DBNMPNTW)
Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "E:\DeploymentShare"
new-MDTDatabase -path "DS001:" -SQLServer "wdsmdtsrv001" -Instance "SQLExpress4MDT" -Netlib "DBNMPNTW" -Database "MDTDB" -SQLShare "DeploymentShare$" -Verbose
Configure Monitoring
Import-Module "E:\MDT\bin\MicrosoftDeploymentToolkit.psd1"
(Does not appear to work) Enable-MDTMonitorService -DataPort 9801 -EventPort 9800

Configure MDT
Drivers
OS
Task Sequence
Applications
Custom Scripts (WDS/Prestage Device with sctask cleanup, firewall, powershell remoting)
