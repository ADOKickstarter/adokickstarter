Function Sync-Iterations {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ProjectProperties
    )


    process{
            $yamlIterations = $ProjectProperties.boards.iterations
            $startIterations = Get-Iterations -RefreshCache
            
            foreach($yamlIteration in $YamlIterations)
            {   
                Sync-IterationRecursive $yamlIteration $startIterations
            }

            $ret = Get-Iterations -RefreshCache
    }
}

Function Sync-IterationRecursive {
    param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $YamlIteration,
    [Parameter(Mandatory = $true)]
    [PSObject]
    $ParentIteration
    )

    process{
        if($YamlIteration -is [hashtable])
        { 
            $IterationName = $YamlIteration.Keys.GetEnumerator() | First -Selector {-not @("childIterationLength","startDate","endDate").Contains($_) }
            
        }
        else {
            $IterationName = $YamlIteration
        }
        $existingIteration = $null
        if($ParentIteration.hasChildren)
        {
            $existingIteration = $ParentIteration.children | FirstOrDefault -Selector {$_.name -eq $IterationName}
        }
        
        if(-not $existingIteration)
        {
            $existingIteration = Invoke-AzCliCommand "boards iteration project create `
                                    --name ""$IterationName"" `
                                    --path ""$($ParentIteration.path)"" `
                                    --detect false" `
                                    -OutputType PSObject
        }

        if($YamlIteration.endDate)
        {
            $existingIteration = Invoke-AzCliCommand "boards iteration project update `
            --name ""$IterationName"" `
            --path ""$($ParentIteration.path)\$IterationName"" `
            --start-date $($YamlIteration.startDate.ToString("yyyy-MM-dd")) `
            --finish-date $($YamlIteration.endDate.ToString("yyyy-MM-dd")) `
            --detect false" `
            -OutputType PSObject
        }
        

        if($YamlIteration -is [hashtable])
        { 
            
            [Nullable[DateTime]]$childStartDate = $null
            if($YamlIteration.startDate)
            {
                if($YamlIteration.startDate -is [DateTime] -or $YamlIteration.startDate -is [Nullable[DateTime]])
                {
                    $childStartDate = $YamlIteration.startDate
                }
                else 
                {   
                    $childStartDate = [DateTime]::Now
                    if(-not [DateTime]::TryParse($YamlIteration.startDate, [ref]$childStartDate))
                    {
                        $childStartDate = $null
                    } 
                }
            }

            foreach($yamlProperty in $YamlIteration.Keys | Where-Object {-not @("childIterationLength","startDate","endDate").Contains($_) })
            {
               foreach($yamlChildIteration in $YamlIteration.$yamlProperty)
               {   
                   
                   if($YamlIteration.childIterationLength -gt 0)            
                   {
                       if($yamlChildIteration -is [string])
                       {
                           $yamlChildIteration = @{ $yamlChildIteration=@{}}
                       }
                       $yamlChildIteration.startDate = $childStartDate
                       $yamlChildIteration.endDate = $childStartDate.AddDays($YamlIteration.childIterationLength - 1)
                   }
                   if ($yamlChildIteration.Count -gt 0 -or $yamlChildIteration -is [string]) {
                        Sync-IterationRecursive $yamlChildIteration $existingIteration
                   }
                    if($childStartDate)
                    {
                        $childStartDate = $childStartDate.AddDays($YamlIteration.childIterationLength)
                    }
               }
            }

            if($YamlIteration.startDate -and $YamlIteration.childIterationLength)
            {
                $startDate = [DateTime]::Parse($YamlIteration.startDate)
                $existingIteration = Invoke-AzCliCommand "boards iteration project update `
                --name ""$IterationName"" `
                --path ""$($ParentIteration.path)\$IterationName"" `
                --start-date $($startDate.ToString("yyyy-MM-dd")) `
                --finish-date $($childStartDate.AddDays(-1).ToString("yyyy-MM-dd")) `
                --detect false" `
                -OutputType PSObject
            }            
        } 
    }
}