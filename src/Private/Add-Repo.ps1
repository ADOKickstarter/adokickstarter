Function Add-Repo{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $RepoName
    )


    process {     
       $ErrorActionPreference = "Stop"

       $existingProject = Invoke-AzCliCommand "devops project list --query ""value[?name=='$ProjectName'] | length(@)"" " -OutputType TSV
       if($existingProject -eq 0) {
           Write-Error "Project '$ProjectName' does not exist"
           return
       }
       Invoke-AzCliCommand "devops configure --defaults ""project=$ProjectName"""
       # Check repo doesn't exist
       $repos = Invoke-AzCliCommand "repos list `
                                --query ""[].name""
                                --detect false" -OutputType PsObject
       
       $repoExists = $repos -contains $RepoName

       if($repoExists -eq $true){
            Write-Error "Repo $RepoName in Project '$ProjectName' already exists"
            return
       }
   
       # check the requester is a project contributor         
       Test-UserInGroup -UserEmailAddress $RepoCreatorEmailAddress -GroupName $RequiredGroupMembership

       $repoDetails = Invoke-AzCliCommand "repos create --name $RepoName --detect false" -OutputType PsObject

       if($repoDetails.size -eq 0){
            Add-Readme -RepoName "$RepoName"
       }

       $repoDetails = Invoke-AzCliCommand "repos show --repository ""$RepoName"" `
       --detect false" -OutputType PsObject

       $ret = Invoke-AzCliCommand "repos policy approver-count create `
       --branch ""main"" `
       --enabled true `
       --creator-vote-counts false `
       --minimum-approver-count 1`
       --reset-on-source-push true`
       --allow-downvotes true
       --blocking true `
       --repository-id $($repoDetails.id) `
       --detect false"
       
       $approversGroup =  "$ProjectName-PR-Approvers"
       
       $approversGroupDescriptor = Invoke-AzCliCommand "devops security group list --query ""graphGroups[?displayName=='$approversGroup'].descriptor""`
        --detect false" -OutputType TSV 
       if($null -eq $approversGroupDescriptor){
           Write-Warning "Approvers group does not exist in project - cannot apply mandatory reviewers policy"
           return
       }


    $ret = Invoke-AzCliCommand "repos policy required-reviewer create `
                --branch ""main"" `
                --enabled true `
                --blocking true `
                --repository-id $($repoDetails.id) `
                --required-reviewer-ids ""$approversGroup"" `
                --message ""Pull Request review required"" `
                --detect false"
    }
}


   # TODO : https://docs.microsoft.com/en-us/azure/devops/organizations/settings/naming-restrictions?view=azure-devops#azure-repos
   function IsValidRepoName { 
    param([string]$RepoName)
    #length < 65 chars
    
    # no unicode control characters
    # no spaces (spaces not recommended)
    # no special caracters (/:\#&%;@"{})
}