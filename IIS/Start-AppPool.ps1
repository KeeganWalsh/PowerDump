PARAM(
    [parameter(Mandatory=$TRUE,HelpMessage="Enter Server Name")]$ServerName,
    [parameter(Mandatory=$TRUE,HelpMessage="Enter App Pool Name")]$AppPool
)
Invoke-Command -ComputerName $ServerName -ArgumentList $AppPool -ScriptBlock {PARAM($AppPool)Import-Module WebAdministration -Verbose:$FALSE; Start-WebAppPool -Name $AppPool}