
function Invoke-AdoApi {
    [CmdletBinding()]
    param (
      # Parameter help description
      [Parameter(Mandatory = $false)]
      [string]
      $Area,

      [Parameter(Mandatory = $true)]
      [string]
      $Resource,

      [Parameter(Mandatory = $true)]
      [string]
      $Method,    
      
      [Parameter(Mandatory = $true)]
      [Hashtable]
      $RouteParameters,

      [Parameter(Mandatory = $false)]
      [String]
      $Payload,

      [Parameter()]
      [String]
      $ApiVersion = "6.0-preview",

      [Parameter()]
      [CliOutput]
      $OutputType="None"
    )
    
    begin {

    }
    
    process {
         
        $routeParams = Convert-HashToRouteParams $RouteParameters
        
        $infileParm = ""
        if(-not [String]::IsNullOrEmpty($Payload)){
            $infile = "{0}\{1}.tmp" -f $env:TEMP, [System.Guid]::NewGuid()
            $Payload | Out-File -FilePath $infile -Force -Encoding utf8NoBOM
            $infileParm = "--in-file ""$infile"""
        }

        $ret = Invoke-AzCliCommand "devops invoke --area $Area `
        --resource $Resource `
        --http-method $Method `
        --detect false `
        $infileParm `
        --route-parameters $routeParams  `
        --api-version ""$ApiVersion"" `
        --verbose" `
        -OutputType $OutputType

        if($OutputType -ne "None"){
            return $ret
        }
    }
    
    end {
        
    }
}

function Convert-HashToRouteParams
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hash
    )
    $hashstr = ""
    $keys = $Hash.keys
    foreach ($key in $keys)
    {
        $v = $Hash[$key]
        if ($key -match "\s")
        {
            $hashstr += "$key" + "=" + "$v" + " "
        }
        else
        {
            $hashstr += $key + "=" + "$v" + " "
        }
    }
    
    return $hashstr
}