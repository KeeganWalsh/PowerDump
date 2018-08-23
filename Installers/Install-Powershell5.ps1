$Server = "PSDSC52"
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)" -CimSession $Server
IF(!(Test-Path "\\$Server\C$\Temp")){New-Item "\\$Server\C$\Temp" -ItemType Directory | Out-Null}
Copy-Item -Path "\\lvnprdpilots\software\WinMgmtFramework5-KB3066437-x64.msu" -Destination "\\$Server\C$\Temp"
Invoke-Command -ComputerName PSDSC51 -ScriptBlock{
    &"C:\Temp\WinMgmtFramework5-KB3066437-x64.msu" /quiet /forcerestart
}


