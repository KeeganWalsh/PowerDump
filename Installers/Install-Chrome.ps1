$LocalTempDir = $env:TEMP
$ChromeInstaller = "ChromeInstaller.exe"
(new-object    System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller")
& "$LocalTempDir\$ChromeInstaller" /silent /install;
$Process2Monitor =  "ChromeInstaller"
DO { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name;
    IF ($ProcessesFound) {
		"Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 
	}ELSE{
		rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose 
	} 
}UNTIL (!$ProcessesFound)