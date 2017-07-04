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

$computers = @()

# Get computer list from text file in local working directory
$computers += Get-Content -Path ./computers.txt

# Get computer list based on groups in AD
$groups = @()
$groups = "Applocker-Audit, AppLocker-Enforce"
Foreach($group in $groups) {
    $computers += get-adgroupmember $group
}


