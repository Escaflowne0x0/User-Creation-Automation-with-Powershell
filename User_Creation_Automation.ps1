Write-Host 
" 
 _     _                      ______                      _               
| |   | |                    / _____)                _   (_)              
| |   | | ___  ____  ____   | /       ____ ____ ____| |_  _  ___  ____    
| |   | |/___)/ _  )/ ___)  | |      / ___) _  ) _  |  _)| |/ _ \|  _ \   
| |___| |___ ( (/ /| |      | \_____| |  ( (/ ( ( | | |__| | |_| | | | |  
 \______(___/ \____)_|       \______)_|   \____)_||_|\___)_|\___/|_| |_|  
                                                                          
                                         _                                
   /\         _                     _   (_)                               
  /  \  _   _| |_  ___  ____   ____| |_  _  ___  ____                     
 / /\ \| | | |  _)/ _ \|    \ / _  |  _)| |/ _ \|  _ \                    
| |__| | |_| | |_| |_| | | | ( ( | | |__| | |_| | | | |                   
|______|\____|\___)___/|_|_|_|\_||_|\___)_|\___/|_| |_|                   
                                                                          
                                                      "                                                                                                                                         
Write-Host "by Escaflowne." -ForegroundColor Cyan 
#Environment variables 
$ScriptVer = '1.0'
$PasswordLength = 10 #characters
$ExchangeOnlineURI = 'https://outlook.office365.com/powershell-liveid/'

#Import PowerShell Modules and types
Import-Module ActiveDirectory
Add-Type -AssemblyName 'System.Web' #Enable the GeneratePassword method 


#cls

function Create-Password #Creates a secure password for the user
{
 
    # Random-Word-Api
    [string]$pass1 = Invoke-RestMethod -Method GET -Uri https://random-word-api.herokuapp.com/word?swear=0
    $pass1=$pass1.Replace($pass1[0],$pass1[0].ToString().ToUpper())
    [string]$pass2 = Invoke-RestMethod -Method GET -Uri https://random-word-api.herokuapp.com/word?swear=0
    $pass2=$pass2.Replace($pass2[0],$pass2[0].ToString().ToUpper())
    $number=get-random -Minimum 1000 -Maximum 9999
    #$symbol= [System.Web.Security.Membership]::GeneratePassword(1,1)
    $symbol= Get-Random ('@','.','$','#','!','?','+','=','(',')','*','-')
    [string]$pwd=$null
    foreach($element in Get-Random ($pass1,$pass2,$number,$symbol) -Count 4)
    {
        [string]$pwd = $pwd+$element
    }

    Return $pwd
    
}


#Get new user information
$fName = Read-Host("Type in the new employee's first name (and middle name, if any)")
$lName = Read-Host("Type in the last name")
$ticket = Read-Host("Enter the ticket number for this request (Enter N/A if there is none)")

#This will allow you to choose the location/OU if you have more than one, change it as you please.
$OUPath = Read-host "`r`nEnter the OU location name exactly as it's listed here:     
            Location1
            Lotation2
            Location3

Type it here"
                            
while ($OUPath -notmatch "(Location1|Lotation2|Location3)")
{
    $OUPath = Read-Host("Once more to confirm please:")
}

#This will apply if you have more than one location. Change here the Path for your Domain and Users's directory OU.
$Oufinal = ("OU="+$OUPath+",OU=Users,DC=YOURDOMAIN")

#LogFile will take the name as typed
#Logs will be saved in C:\Script\Logs but you can change the path off course
if (!(Test-Path C:\Scripts\Logs -PathType Container)) {mkdir C:\Scripts\Logs}
$logFile = ("C:\Scripts\Logs\"+ $fName + " " + $lName + " - " + (Get-Date -format MMddyyyy.HHmmss) + ".txt")
Write-Host "`r`nCreating log file: $logfile`r`n" -ForegroundColor green -BackgroundColor black
New-Item $logFile -ItemType File | Out-Null
Add-Content $logFile "New user creation as per ticket $ticket`r`nRunning script version $scriptver"

#Creating mandatory fields
#customizing e-mail address
$UPN = $fName.substring(0,1)+$lName.Replace(" ","")+"@YOURDOMAIN"
$cUPN = $null
$cUPN = Read-Host "`r`nWas there a preferred e-mail address requested (other than $UPN (Y/N)"
while ($cUPN -notmatch "(y|Y|n|N)")
{
    $cUPN = Read-Host("Please enter Y/N")
}
if (($cUPN -eq "Y") -or ($cUPN -eq "y"))
{
    $UPN = Read-host "Enter e-mail address including @YOURDOMAIN"
    $alias = $upn.replace
}
else
{
    $UPN = $fName.substring(0,1)+$lName.Replace(" ","")+"@YOURDOMAIN"
    
}
#customizing user ID
$cSAM = $null
$SAM = ($fname.substring(0,1)+$lName.Replace(" ","")).tolower()
$cSAM = Read-Host "`r`nWas there a preferred username (other than $SAM)? (Y/N)"
while ($cSAM -notmatch "(y|Y|n|N)")
{
    $cSAM = Read-Host("Please enter Y/N")
}
if (($cSAM -eq "Y") -or ($cSAM -eq "y"))
{
    $SAM = Read-Host "Enter the username as requested"
}
$password = Create-Password
$secPW = ConvertTo-SecureString -string $password -AsPlainText -Force
$proxyAddresses = @("SMTP:$UPN","smtp:$alias")
#Requesting aditional aliases
$extraAlias = Read-Host ("Do you want to set up additional e-mail alias for this user? (Y/N)")
while ($extraAlias -notmatch "(y|Y|n|N)")
{
    $extraAlias = Read-Host("Please enter Y/N")
}
if (($extraAlias -eq "Y") -or ($extraAlias -eq "y"))
{
    do
    {
        $proxyAddresses = $ProxyAddresses + "smtp:$(Read-Host("Type in the additional e-mail address alias"))"
        $quitAlias = Read-Host("Add another alias? (Y/N)")
        while ($quitAlias -notmatch "(y|Y|n|N)")
            {
                $quitAlias = Read-Host("Please enter Y/N")
            }
    }
    Until (($quitAlias -eq "n") -or ($quitAlias -eq "N"))
}
#Define Role

try #to create the account
{
    New-ADUser -SamAccountName $SAM -GivenName $fname -Surname $lName -EmailAddress $UPN -DisplayName "$fname $lname" -Path $Oufinal -UserPrincipalName $UPN  -AccountPassword $secPW -Name "$fname $lname" -Enabled $true -OtherAttributes @{ProxyAddresses=$proxyAddresses} -ChangePasswordAtLogon $false
    Add-Content $logFile "`r`n== Account created: ==`r`nUser: $((Get-ADUser $SAM).samAccountName) `r`nPassword: $Password" 
    
}
catch #account not created
{
    Add-Content $logFile "`r`nUser not created:`r`n$($_.Exception.Message)"
    Write-Host("There was an error creating the user, please check the log $logFile") -ForegroundColor White -BackgroundColor Red
}
try #Force AD-Sync
{

    Write-Host "Waiting for user to get synchronized in AzureAD" -ForegroundColor green -BackgroundColor black
    Start-Sleep -Seconds 330 #this will allow time for the synchronization process to create the user in O365
    Write-Host "`r`nSyncronizing ActiveDirectory with AzureAD" -ForegroundColor green -BackgroundColor black
    Add-Content $logFile "`r`n-----`r`nADSync"
    Start-ADSyncSyncCycle -PolicyType Delta | Out-File $logFile -Append
}
catch ##AD was not able to sync##
{
      Add-Content $logFile "`r`n-----`r`nUser was not sync with office 365:`r`n$($_.Exception.Message)`r`n-----"
      Write-Host("There was an error while trying to sync with Office 365, please check the log $logFile") -ForegroundColor White -BackgroundColor Red
}


Try ###Ask if you want to assign a license##
{

  $Licenseyesno = Read-Host "`r`nDo you want to assign an Office 365 License for this account (Y/N)"
  while ($Licenseyesno -notmatch "(y|Y|n|N)")
   {
    $Licenseyesno = Read-Host("Please enter Y/N")
   }
  if (($Licenseyesno -eq "Y") -or ($Licenseyesno -eq "y"))
   {
       
    Try ###Choose which license do you want to assign, you can add here more according to your needs###
    {
        Write-Host "Choose the type of license that you want to assign:

        1.O365_BUSINESS_PREMIUM (Business Standard)

        2.O365_BUSINESS_ESSENTIALS (Business Basic)
        "

        $PickLicense = Read-Host ("Enter 1 or 2 to select")

        If ($PickLicense -eq 1)
        {
         $AzLicense = "O365_BUSINESS_PREMIUM"
        }
        ElseIf ($PickLicense -eq 2)
        {
         $AzLicense = "O365_BUSINESS_ESSENTIALS"
        }
        
    }
    catch
    {
        Add-Content $logFile "`r`n-----`r`nFailed to select the license`r`n$($_.Exception.Message)`r`n-----"
        Write-Host("Failed to select the needed license, please check the log $logFile for further details") -ForegroundColor White -BackgroundColor Red
    }

    try #####Accessing to O365 and assigning license#####
    { 
        Write-Host "`r`nConnecting to Microsoft Cloud services" -ForegroundColor green -BackgroundColor black
        
        Connect-MsolService ##Connect to O365 MSOL services##
        try ##Add user location in Azure##
        {
            Start-Sleep -Seconds 60 #this will give some time the account to check the settings before adding the license.
			#We are adding the User's location, that by default is set to US, but you can change that or add a question.
            Get-MsolUser -UserPrincipalName $UPN | Set-MsolUser -UsageLocation US
            Write-Host "Waiting for user to be added on the correct location in AzureAD" -ForegroundColor green -BackgroundColor black
            Start-Sleep -Seconds 120 #this will give some time the account to check the settings before adding the license.
        }
        catch ##Failed to assign the user to US location##
        {
            Add-Content $logFile "`r`n-----`r`nFailed to assign the location for $UPN`r`n$($_.Exception.Message)`r`n-----"
            Write-Host("Failed to assign the location for the user account, please check the log $logFile") -ForegroundColor White -BackgroundColor Red
        }
        
        Connect-AzureAD #-Credential $AZCred
        try #setting license
        {
            Write-Host "Verifying Office 365 available licenses" -ForegroundColor Green -BackgroundColor black
            $TotalLicenses = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $AZLicense -EQ | Select-Object ConsumedUnits -ExpandProperty PrepaidUnits).Enabled
            $UsedLicenses = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $AZLicense -EQ | Select-Object ConsumedUnits -ExpandProperty PrepaidUnits).ConsumedUnits

            IF ( $UsedLicenses -eq $TotalLicenses)
               { 
                Read-Host("There are no Available licenses, Go to Crayon and buy a new 'Business Premium license'. When you are ready Press enter to Continue")
                $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
                $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
                # Find the SkuID of the license we want to add - in this example we'll use the O365_BUSINESS_PREMIUM license
                $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $AZLicense -EQ).SkuID
                # Set the Office license as the license we want to add in the $licenses object
                $licenses.AddLicenses = $license
                Set-AzureADUserLicense -ObjectId $UPN -AssignedLicenses $licenses
                Write-Host "License $AZLicense assigned to the user $UPN" -ForegroundColor Green -BackgroundColor black
                Add-Content $logFile "`r`n`r`n== License assigned to user: $AZLicense ==`r`nE-Mail address: $UPN"
               }
            ElseIf ($UsedLicenses -Lt $TotalLicenses)
               {
                $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
                $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
                # Find the SkuID of the license we want to add - in this example we'll use the O365_BUSINESS_PREMIUM license
                $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $AZLicense -EQ).SkuID
                # Set the Office license as the license we want to add in the $licenses object
                $licenses.AddLicenses = $license
                Set-AzureADUserLicense -ObjectId $UPN -AssignedLicenses $licenses
                Write-Host "License $AZLicense assigned to the user $UPN" -ForegroundColor Green -BackgroundColor black
                Add-Content $logFile "`r`n`r`n== License assigned to user: $AZLicense ==`r`nE-Mail address: $UPN"
               }
            
        }
        catch ##Failed to assign license##
        {
            Add-Content $logFile "`r`n-----`r`nAdding Licenses failed:`r`n$($_.Exception.Message)`r`n-----"
            Write-Host("There was an error assigning the Office 365 Licenses for $UPN, please check the log $logFile and remediate in https://portal.microsoft.com ") -ForegroundColor White -BackgroundColor Red
        }       

    }
    catch #connection to AzureAD failed
    {
        Add-Content $logFile "`r`n-----`r`nConnection to AzureAD Failed:`r`n$($_.Exception.Message)`r`n-----"
        Write-Host("There was an error connecting to AzureAD / Office365, please check the log $logFile") -ForegroundColor White -BackgroundColor Red


    }
   }
   
}
finally
{
    Write-Host "The process has finished. Please check $logfile for details. Gracias =)"
    #Disconnect all cloud sessions
    Disconnect-AzureAD -ErrorAction SilentlyContinue
    Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
    invoke-Item $logFile
    [void](Read-Host 'Press Enter to exit…')
}