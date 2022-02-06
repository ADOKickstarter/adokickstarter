function Invoke-RawAdoApi {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [string]
      $ResourcePath,

      [Parameter(Mandatory = $true)]
      [string]
      $Method,    

      [Parameter(Mandatory = $false)]
      [String]
      $Body,

      [Parameter()]
      [String]
      $ApiVersion = "6.1-preview"
    )
    
    begin {

    }
    
    process {
        $ErrorActionPreference = "Stop"
        $headers = @{}
        if(-not [String]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)){
            $authValue = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":" + $env:AZURE_DEVOPS_EXT_PAT))

            $headers = @{
                Authorization = "Basic $authValue";
                #'X-VSS-ForceMsaPassThrough' = $true
            }
        } else {
            $azureDevopsResourceId = "499b84ac-1321-427f-aa17-267ca6975798"
            $token = &az account get-access-token --resource $azureDevopsResourceId | ConvertFrom-Json
            $authValue = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":" + $token.accessToken))

            $headers = @{
                Authorization = "Basic $authValue";
                'X-VSS-ForceMsaPassThrough' = $true
            }
        }
        
        $config = & az devops configure --list
        $m = ($config | Where-Object { $_.StartsWith("organization")}) -match "organization = (.*)"
        $organization = $Matches.1
        $queryString = "?api-version=$ApiVersion"
        $apiUrl = "{0}/_apis/$ResourcePath$queryString" -f $organization        
        
        $headers.accept = "application/json;excludeUrls=true;enumsAsNumbers=true;msDateFormat=true;noArrayWrap=true"
        Write-Output $Method $apiUrl $headers.accept $Body

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if($method -eq "GET" -or [String]::IsNullOrEmpty($Body))
        {
            $response = Invoke-RestMethod –Uri $apiUrl –Method $Method  –Headers $headers –ContentType 'application/json' –Verbose
            return $response
        }
        else
        {
            $response = Invoke-RestMethod –Uri $apiUrl –Method $Method  –Headers $headers –ContentType 'application/json' –Verbose -Body $Body
            return $response
        }
    }
    
    end {
        
    }
}





