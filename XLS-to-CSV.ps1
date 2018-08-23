function ConvertFrom-XLx {
  param (
         [parameter( Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
         [string]$path , 
         [switch]$PassThru
        )

    Begin{ 
        $objExcel = New-Object -ComObject Excel.Application 
    }Process{ 
        
        if ((test-path $path) -and ( $path -match ".xl\w*$")) {
        
            $path = (resolve-path -Path $path).path 
            $savePath = $path -replace ".xl\w*$",".csv"
            $objworkbook=$objExcel.Workbooks.Open( $path)
            $objworkbook.SaveAs($savePath,6) # 6 is the code for .CSV 
            $objworkbook.Close($false) 
        
            if ($PassThru) {
                Import-Csv -Path $savePath 
            } 

        }else{
            Write-Host "$path : not found"
        } 

    } 
    End{ 
        $objExcel.Quit() 
    }
}

$cwd = Split-Path -parent $MyInvocation.MyCommand.Definition

Get-ChildItem ($cwd + "*.xls") | ConvertFrom-XLx