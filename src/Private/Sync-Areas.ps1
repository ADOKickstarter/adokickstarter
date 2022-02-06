Function Sync-Areas {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ProjectProperties
    )


    process{
            $yamlAreas = $ProjectProperties.boards.areas
            $startAreas = Get-Areas -RefreshCache
            
            foreach($yamlArea in $YamlAreas)
            {   
                Sync-AreaRecursive $yamlArea $startAreas
            }
    }
}

Function Sync-AreaRecursive {
    param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $YamlArea,
    [Parameter(Mandatory = $true)]
    [PSObject]
    $ParentArea

    )

    process{
        if($YamlArea -is [hashtable])
        { 
            $areaName = $YamlArea.Keys.GetEnumerator() | First 
        }
        else {
            $areaName = $YamlArea
        }
        $existingArea = $null
        if($ParentArea.hasChildren)
        {
            $existingArea = $ParentArea.children | FirstOrDefault -Selector {$_.name -eq $areaName}
        }

        if(-not $existingArea)
        {
            $existingArea = Invoke-AzCliCommand "boards area project create `
                                    --name ""$areaName"" `
                                    --path ""$($ParentArea.path)"" `
                                    --detect false" `
                                    -OutputType PSObject
        }

        if($YamlArea -is [hashtable])
        { 
            foreach($yamlProperty in $YamlArea.Keys)
            {
               foreach($yamlChildArea in $YamlArea.$yamlProperty)
               {
                   Sync-AreaRecursive $yamlChildArea $existingArea
               }
            }
        }        
    }
}