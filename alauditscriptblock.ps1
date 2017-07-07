        Param($alauditmtx, $ALAuditDataFile)


        $DCsmtx, $DCsMetaResultsFile
        $alauditmtx, $ALAuditDataFile

        $computer = $_

        

        #Test Connection and exit if not available

        If((Test-Connection -ComputerName $computer -Quiet) -eq $false){exit}

        
        #Creating object to output to .csv

        $aleventcsvdata = New-Object psobject

        $computer = get-adcomputer -Identity $computer -Properties OperatingSystem 
        $ComputerOU = $computer.DistinguishedName -creplace "^[^,]*,",""       

        #Get events from Microsoft-Windows-AppLocker/EXE and DLL log

        $exedllevents = Get-WinEvent -ComputerName $computer.name -LogName 'Microsoft-Windows-AppLocker/EXE and DLL' -FilterXPath "*[System[(EventID=8003 or EventID=8004)]]"

        foreach($exedllevent in $exedllevents){
            
            $exedlleventxml = [xml]$exedllevent.ToXml()
        
            $userprincipalname = (Get-ADUser $exedlleventxml.Event.UserData.RuleAndFileData.TargetUser).UserPrincipalName
            $username = (Get-ADUser $exedlleventxml.Event.UserData.RuleAndFileData.TargetUser).Name

            Clear-Item $aleventcsvdata
       
            $aleventcsvdata = New-Object PSObject -Property @{            
                MachineName         = $computer.name                 
                MachineOU           = $ComputerOU             
                MachineOS           = $computer.OperatingSystem
                UserPrincipalName   = $userprincipalname            
                UserName            = $username
                PolicyName          = $exedlleventxml.Event.UserData.RuleAndFileData.PolicyName           
                CreateDate          = $exedlleventxml.Event.System.TimeCreated.SystemTime           
                EventID             = $exedlleventxml.Event.System.EventID           
                FilePath            = $exedlleventxml.Event.UserData.RuleAndFileData.FilePath         
                FileHash            = $exedlleventxml.Event.UserData.RuleAndFileData.FileHash           
                Fqbn                = $exedlleventxml.Event.UserData.RuleAndFileData.Fqbn           
         
                }

        
            $alauditmtx.WaitOne(300000)
            $aleventcsvdata | Export-Csv $ALAuditDataFile -Encoding ASCII -NoTypeInformation -Append
            $alauditmtx.ReleaseMutex()


        }


        $scriptmsievents = Get-WinEvent -ComputerName $computer.name -LogName 'Microsoft-Windows-AppLocker/MSI and Script' -FilterXPath "*[System[(EventID=8006 or EventID=8007)]]"

        foreach($scriptmsievent in $scriptmsievents){
            
            $scriptmsieventxml = [xml]$scriptmsievent.ToXml()
        
            #Test for constrained language test scripts if so then continue to next event
            # Match partial path in temp directory with form XXXXXXXX.XXX.PS* or __PSScriptPolicyTest_XXXXXXXX.XXX.PS*
	    $pattern1 = "\\APPDATA\\LOCAL\\TEMP\\[A-Z0-9]{8}\.[A-Z0-9]{3}\.PS"
            $pattern2 = "\\APPDATA\\LOCAL\\TEMP\\[0-9]{1}\\[A-Z0-9]{8}\.[A-Z0-9]{3}\.PS"
	    $pattern3 = "\\APPDATA\\LOCAL\\TEMP\\(__PSScriptPolicyTest_)?[A-Z0-9]{8}\.[A-Z0-9]{3}\.PS"
            $pattern4 = "\\APPDATA\\LOCAL\\TEMP\\[0-9]{1}\\(__PSScriptPolicyTest_)?[A-Z0-9]{8}\.[A-Z0-9]{3}\.PS"

            If($scriptmsieventxml.Event.UserData.RuleAndFileData.FilePath -match $pattern1){continue}
            If($scriptmsieventxml.Event.UserData.RuleAndFileData.FilePath -match $pattern2){continue}
            If($scriptmsieventxml.Event.UserData.RuleAndFileData.FilePath -match $pattern3){continue}
            If($scriptmsieventxml.Event.UserData.RuleAndFileData.FilePath -match $pattern4){continue}

            $userprincipalname = (Get-ADUser $scriptmsieventxml.Event.UserData.RuleAndFileData.TargetUser).UserPrincipalName
            $username = (Get-ADUser $scriptmsieventxml.Event.UserData.RuleAndFileData.TargetUser).Name

            Clear-Item $aleventcsvdata
       
            $aleventcsvdata = New-Object PSObject -Property @{            
                MachineName         = $computer.name                 
                MachineOU           = $ComputerOU             
                MachineOS           = $computer.OperatingSystem
                UserPrincipalName   = $userprincipalname            
                UserName            = $username
                PolicyName          = $scriptmsieventxml.Event.UserData.RuleAndFileData.PolicyName           
                CreateDate          = $scriptmsieventxml.Event.System.TimeCreated.SystemTime           
                EventID             = $scriptmsieventxml.Event.System.EventID           
                FilePath            = $scriptmsieventxml.Event.UserData.RuleAndFileData.FilePath         
                FileHash            = $scriptmsieventxml.Event.UserData.RuleAndFileData.FileHash           
                Fqbn                = $scriptmsieventxml.Event.UserData.RuleAndFileData.Fqbn           
         
                }

        
            $alauditmtx.WaitOne(300000)
            $aleventcsvdata | Export-Csv $ALAuditDataFile -Encoding ASCII -NoTypeInformation -Append
            $alauditmtx.ReleaseMutex()


        }
