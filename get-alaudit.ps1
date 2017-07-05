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

#Check if NuGet is installed on system and if not then install it used to get PoshRSJob module
If((Get-PackageProvider -Name NuGet) -eq $null){
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser  
}

#Check if PoshRSJob module is installed and if not to install it
If((Get-Module -ListAvailable -name PoshRSJob) -eq $null){
  Install-Module -Name PoshRSJob -Scope CurrentUser -Force  
}
Install-Module -Name PoshRSJob -Scope CurrentUser -Force

#Set working directory
$WorkingDirectory = (Get-Item -Path ".\" -Verbose).FullName

#Declaring variables
$computers = @()

# Get computer list from text file in local working directory
$computers += Get-Content -Path ./computers.txt

# Get computer list based on groups in AD
$groups = @()
$groups = "Applocker-Audit, AppLocker-Enforce"
Foreach($group in $groups) {
    $computers += (Get-ADGroupMember -Identity $group).name
}


  $ALAuditData = $WorkingDirectory + "\ALAuditData.csv"
  If(Test-Path -Path $ALAuditData){
    $ALAuditDataTimeString = (Get-ChildItem -Path $ALAuditData).creationtime.tostring("MM.dd.yyyy.HH.mm")
    $ALAuditDataRenamed = $($WorkingDirectory) + "\ALAuditData" + $($ALAuditDataTimeString) + ".csv"
    Rename-Item -Path $ALAuditData -newname $ALAuditDataRenamed
  }
  #$alauditmtx = New-Object System.Threading.Mutex($false, "ALAuditMutex")
  #$ALAuditScriptBlock = get-command $($WorkingDirectory)\ALAuditScriptBlock.ps1 | Select-Object -ExpandProperty ScriptBlock
  #$computers | Start-RSJob -ScriptBlock $DCsScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $alauditmtx, $ALAuditData

#>
