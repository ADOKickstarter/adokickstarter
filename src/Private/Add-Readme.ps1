Function Add-Readme{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]
        $RepoDetails,

        [Parameter(Mandatory = $true)]
        [string]
        $BranchName

    )
    process {   
        $ErrorActionPreference = "Stop"
       $payload = Get-Content -Raw -Path "$PSScriptRoot/../Payloads/Add-Readme-Payload.json" | ConvertFrom-Json
      
       $payload.refUpdates[0].name = "refs/heads/$BranchName" 

       if($repoDetails.size -gt 0){
           return;
       }

     
       $RepoDetails.PSObject.Properties.Remove('defaultBranch')
       $RepoDetails.PSObject.Properties.Remove('isFork')
       $RepoDetails.PSObject.Properties.Remove('parentRepository')
       $RepoDetails.PSObject.Properties.Remove('validRemoteurls')

       $RepoDetails.project.PSObject.Properties.Remove('abbreviation')
       $RepoDetails.project.PSObject.Properties.Remove('defaultTeamImageUrl')
       $RepoDetails.project.PSObject.Properties.Remove('description')      
       
       $RepoDetails.project.state = 1
      
       $payload.repository = $repoDetails
       $timestamp = Get-Date -Format "yyyyMMddHHmmssfff"
       $payloadTempFile = "$env:TEMP\\tmpPayload-$timestamp.json"
        
       $payload | ConvertTo-Json -depth 100 | Out-File $payloadTempFile -Encoding utf8
        
       
        $ret = Invoke-AzCliCommand "devops invoke --area git `
                                    --resource pushes `
                                    --http-method POST `
                                    --in-file $payloadTempFile `
                                    --detect false `
                                    --route-parameters repositoryId=$($repoDetails.id)  `
                                    --api-version ""5.0"" "
                             
    
    }
}