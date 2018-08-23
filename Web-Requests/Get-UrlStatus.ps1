#Send a request to a URL and get its status
FUNCTION Get-Status ([string]$url) {
	$req = [system.Net.WebRequest]::Create($url)
	
	Try {
		$req.Timeout = 600000 # = 10 minutes
		$res = $req.GetResponse()
		$code = [int]$res.statuscode
		
		switch -Wildcard ($code) {
			"2??" {return $true}
			"3??" {return $true}
			default {return $false}
		}
	}

	catch { 
		return $false
	}

	$res.close()
	$req.Abort()
}