
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
      
      [Parameter(Mandatory = $false)]
      [Hashtable]
      $RouteParameters = @{},

      [Parameter(Mandatory = $false)]
      [Hashtable]
      $QueryParameters = @{},

      [Parameter(Mandatory = $false)]
      [string]
      $Query = $null,


      [Parameter(Mandatory = $false)]
      [String]
      $Payload,

      [Parameter()]
      [String]
      $ApiVersion = "6.0-preview",

      [Parameter()]
      [CliOutput]
      $OutputType="PSObject"
    )
    
    begin {

    }
    
    process {
         
        $project = Get-Project
        $RouteParameters.project = $project.id
        $routeParams = Convert-HashToParams $RouteParameters
        $queryParams = Convert-HashToParams $QueryParameters
        
        $infileParm = ""
        if(-not [String]::IsNullOrEmpty($Payload)){
            $infile = "{0}\{1}.tmp" -f $env:TEMP, [System.Guid]::NewGuid()
            $Payload | Out-File -FilePath $infile -Force -Encoding utf8NoBOM
            $infileParm = "--in-file ""$infile"""
        }

        if($Query)
        {
            $queryArg = "--query $Query"
        }

        $ret = Invoke-AzCliCommand "devops invoke --area $Area `
        --resource $Resource `
        --http-method $Method `
        --detect false `
        $infileParm `
        --route-parameters $routeParams  `
        --query-parameters $queryParams `
        --api-version ""$ApiVersion"" `
        $queryArg `
        --verbose" `
        -OutputType $OutputType

        if($OutputType -ne "None"){
            return $ret
        }
    }
    
    end {
        
    }
}

function Convert-HashToParams
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