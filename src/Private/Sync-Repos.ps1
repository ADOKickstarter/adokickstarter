Function Sync-Repos {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ProjectProperties
    )

   

    $repos = Get-Repos -RefreshCache

    foreach($yamlRepo in $ProjectProperties.git.repos)
    {
        $repo = $repos | FirstOrDefault -Selector {$_.name -eq $yamlRepo.repo}
        if(-not $repo)
        {
            $repo = Invoke-AzCliCommand "repos create --name $($yamlRepo.repo) --detect false" -OutputType PsObject
        
            if($yamlRepo.settings.initOnCreation)
            {       
                # Got to create the branch to make it the default and apply policies to it
                Add-Readme -RepoDetails $repo -BranchName $yamlRepo.settings.defaultBranch
                Invoke-AzCliCommand " repos update --repository $($repo.id) --default-branch $($yamlRepo.settings.defaultBranch) --detect false"
        
                # Get ref for that commit
                $initRef = (Invoke-AzCliCommand "repos ref list --repository $($repo.id) --detect false" -OutputType PSObject) | First  
                foreach($branchKv in $yamlRepo.settings.branchPolicies)
                {  
                
                    $branchName = $branchKv.keys[0]                              
                    if($yamlRepo.settings.defaultBranch -ne $branchName)   
                    {
                        # TODO: need to init this branch by creating it from the default branch (need object id)
                        $branchRef = Invoke-AzCliCommand "repos ref create `
                                        --repository $($repo.id) `
                                        --name refs/heads/$branchName `
                                        --object-id $($initRef.objectId) `
                                        --detect false" `
                                        -OutputType PSObject                                              

                    }
               
        
                    if($branchKv.Values.minimumNumberOfReviewers)
                    {
                        $approveCountPolicy =  $branchKv.Values.minimumNumberOfReviewers
                        $ret = Invoke-AzCliCommand "repos policy approver-count create `
                                --repository-id $($repo.id) `
                                --branch $branchName `
                                --enabled true `
                                --allow-downvotes $($approveCountPolicy.allowDownVotes) `
                                --creator-vote-counts $($approveCountPolicy.creatorVoteCounts) `
                                --minimum-approver-count $($approveCountPolicy.minimumApproverCount) `
                                --reset-on-source-push $($approveCountPolicy.resetOnSourcePush) `
                                --blocking $($approveCountPolicy.blocking) `
                                --detect false"

                    }

                    if($branchKv.Values.checkForLinkedWorkItems -and $branchKv.checkForLinkedWorkItems -ne "None")
                    {
                        $blocking = ($branchKv.ValuescheckForLinkedWorkItems -eq "Required")
                        $ret = Invoke-AzCliCommand "repos policy work-item-linking create `
                                --repository-id $($repo.id) `
                                --branch $branchName `
                                --enabled true `
                                --blocking $blocking `
                                --detect false"
                    }

                    if($branchKv.Values.checkForCommentResolution -and $branchKv.Values.checkForCommentResolution -ne "None")
                    {
                        $blocking = ($branchKv.Values.checkForCommentResolution -eq "Required")
                        $ret = Invoke-AzCliCommand "repos policy comment-required create `
                                --repository-id $($repo.id) `
                                --branch $branchName `
                                --enabled true `
                                --blocking $blocking `
                                --detect false"
                    }

                    if($branchKv.Values.allowedMergeTypes)
                    {
                        $mergeStrategy =  $branchKv.Values.allowedMergeTypes        
                        $ret = Invoke-AzCliCommand "repos policy merge-strategy create `
                                      --blocking true `
                                      --repository-id $($repo.id) `
                                      --branch $branchName `
                                      --enabled true `
                                      --allow-no-fast-forward $($mergeStrategy.basicNoFastForward) `
                                      --allow-rebase $($mergeStrategy.rebaseWithMergeCommit) `
                                      --allow-rebase-merge $($mergeStrategy.rebaseWithMergeCommit) `
                                      --allow-squash $($mergeStrategy.allowSquashMerge) `
                                      --branch-match-type exact `
                                      --detect false"
                    }  
                }            

            }
        }
        else 
        {
            if($repo.defaultBranch -ne "refs/heads/$($yamlRepo.settings.defaultBranch)" )
            {
                Write-Warning "Repo $($repo.name): Default branch ($($repo.defaultBranch)) differs from yaml config (refs/heads/$($yamlRepo.settings.defaultBranch))"
            }
        }

        
    }
}