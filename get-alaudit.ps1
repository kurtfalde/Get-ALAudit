<#
get-alaudit
7-3-2017
Kurt Falde

Script designed to get an array of computer objects from various methods and then connect to those systems to gather back AppLocker Audit reporting data
Requires:
PoshRSJob Module
AD Powershell cmdlets installed
RPC connectivity to remote systems to connect to via get-winevent to gather back reporting data

#>

<#

#Check if NuGet is installed on system and if not then install it used to get PoshRSJob module
If((Get-PackageProvider -Name NuGet) -eq $null){
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser  
}

#Check if PoshRSJob module is installed and if not to install it
If((Get-Module -ListAvailable -name PoshRSJob) -eq $null){
  Install-Module -Name PoshRSJob -Scope CurrentUser -Force  
}
Install-Module -Name PoshRSJob -Scope CurrentUser -Force
#>

#Set working directory
$WorkingDirectory = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
cd $WorkingDirectory

#Import PoshRSJob module from same directory
Import-Module -Name $WorkingDirectory\PoshRSJob -Verbose

#Declaring variables
$computers = @()

# Get computer list from text file in local working directory
$computers += Get-Content -Path ./computers.txt

# Get computer list based on groups in AD ad groups with comma separators if this is to be used
$groups = @()
#$groups = ""
If($groups -ne $null){
Foreach($group in $groups) {
    $computers += (Get-ADGroupMember -Identity $group).name
}
}

# Add computers to array based on an OU in AD example to put in the OUs line below "OU=something,dc=contoso,dc=com,ou=somethingelse,dc=contoso,dc=com"
$OUs = @()
#$OUs = ""
if($OUs -ne $null){
Foreach($OU in $OUs){
    $computers += (get-adcomputer -filter * -searchbase $OU).name
}
}
 
 
  $ALAuditDataFile = $WorkingDirectory + "\ALAuditData.csv"
  If(Test-Path -Path $ALAuditDataFile){
    $ALAuditDataTimeString = (Get-ChildItem -Path $ALAuditDataFile).lastwritetime.tostring("MM.dd.yyyy.HH.mm")
    $ALAuditDataFileRenamed = $($WorkingDirectory) + "\ALAuditData" + $($ALAuditDataTimeString) + ".csv"
    Rename-Item -Path $ALAuditDataFile -newname $ALAuditDataFileRenamed
  }

  $alauditmtx = New-Object System.Threading.Mutex($false, "ALAuditMutex")
  $ALAuditScriptBlock = get-command "$($WorkingDirectory)\alauditscriptblock.ps1" | Select-Object -ExpandProperty ScriptBlock
  $computers | Start-RSJob -ScriptBlock $ALAuditScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $alauditmtx, $ALAuditDataFile
