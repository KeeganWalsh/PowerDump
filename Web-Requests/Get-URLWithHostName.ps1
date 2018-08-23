FUNCTION Get-URLWithHostName ([string]$Site, [string]$HostName) {
    $wc = New-Object net.webclient 
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} 
    $wc.Headers.add("HOST","$Site") 
    $url=”https://$HostName”
    $probe = $wc.downloadData($url)
    $s = [text.encoding]::ascii.getString($probe) 
    return $s
}