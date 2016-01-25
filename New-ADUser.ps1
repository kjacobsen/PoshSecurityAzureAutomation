[CMDLetBinding()]
Param
(
    [object]$WebHookData
)

$Inputs = ConvertFrom-Json ($WebHookData.RequestBody)

$FirstName = $Inputs.FirstName.trim()
$LastName = $Inputs.LastName.trim()

#Display name is simply the firstname space lastname
$DisplayName = '{0} {1}' -f $FirstName, $LastName

#Sam account is firstname . lastname
$SAMAccountName = '{0}.{1}' -f ($FirstName.ToLower()), ($LastName.ToLower())

$UPN = '{0}@core.poshsecurity.com' -f $SAMAccountName

#generate a password for the user
$null = [Reflection.Assembly]::LoadWithPartialName('System.Web') 
$PasswordPlain = ([System.Web.Security.Membership]::GeneratePassword(15,0))
$PasswordSecure = ConvertTo-SecureString  -String $PasswordPlain -AsPlainText -Force

#Get admin cred
$domainCred = Get-AutomationPSCredential -Name 'DomainAdminCred'

#Setup the parameters
$NewUserParameters = [pscustomobject]@{
    SamAccountName        = $SAMAccountName
    UserPrincipalName     = $UPN
    AccountPassword       = $PasswordSecure
    DisplayName           = $DisplayName
    name                  = $DisplayName
    enabled               = $true
    GivenName             = $FirstName
    Surname               = $LastName
}

try
{
    $NewUserParameters | New-ADUser -credential $domainCred
}
catch
{ 
    throw "An error occurred creating the user, application will now exit. $_" 
}

$SlackBody = @{
    'token'='xoxp-19299915893-19297589508-19300980723-66e335aa91'
    'channel' = '#usercreation'
    'text' = 'Created User {0} {1}, their password is {2}' -f $FirstName, $LastName, $PasswordPlain
}

Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -body $SlackBody -Method post