FUNCTION Install-7zip{
    $7Zip = $true;

    $WebClient = New-Object -TypeName System.Net.WebClient;
    $7ZipUrl = ‘http://downloads.sourceforge.net/sevenzip/7z920-x64.msi';
    $7ZipInstaller = “$ENV:TEMP\7z920-x64.msi”;
 
 
    TRY { 
        $7ZipPath = Resolve-Path -Path ((Get-Item -Path HKLM:\SOFTWARE\7-Zip -ErrorAction SilentlyContinue).GetValue(“Path”) + ‘\7z.exe’);
        IF (!$7ZipPath) {
            $7Zip = $false;
        }
    }CATCH {
        $7Zip = $false;
    }
 
 
 
    IF (!$7Zip) {
        $WebClient.DownloadFile($7ZipUrl,$7ZipInstaller);
        Start-Process -Wait -FilePath $7ZipInstaller;
        Remove-Item -Path $7ZipInstaller -Force -ErrorAction SilentlyContinue;
    }ELSE{
       Write-Warning "7 Zip already installed" 
    }
}

Install-7zip