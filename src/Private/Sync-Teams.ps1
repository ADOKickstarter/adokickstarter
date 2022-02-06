Function Sync-Teams {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ProjectProperties,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $AllProperties




    )
    begin{

    }
    process{

        $ErrorActionPreference = "Stop"
        $teams = $ProjectProperties.teams
        $existingTeams = Get-Teams -RefreshCache
        foreach($configuredTeam in $teams)
        {
            $existingTeam = $existingTeams | FirstOrDefault -Selector {$_.name -eq $configuredTeam.team}
            if(-not $existingTeam){
                $existingTeam = Add-Team -Name $configuredTeam.team -Properties $configuredTeam.properties                
            }

            if($configuredTeam.properties.backlogIteration)
            {
              
                if($configuredTeam.properties.backlogIteration -eq "<root>")
                {
                    $backlogIteration = Get-Iterations # It's the root iteration 

                    $ret = Invoke-AzCliCommand " boards iteration team set-backlog-iteration `
                                   --id $($backlogIteration.identifier) `
                                   --team $($existingTeam.id)
                                   --detect false"
                }
                else {
                    $path = "\$($ProjectProperties.name)\Iteration\$($configuredTeam.properties.backlogIteration)"
                    $backlogIteration = Invoke-AzCliCommand "boards iteration project list --depth 1 --detect false --path ""$path""" -OutputType PSObject
                    $ret = Invoke-AzCliCommand "boards iteration team set-backlog-iteration `
                    --id $($backlogIteration.identifier) `
                    --team $($existingTeam.id)
                    --detect false"
                }

                
            }

            if($configuredTeam.properties.areas)
            {
                #$areas = Get-Areas   TODO: validate area paths

                $existingTeamAreas = Invoke-AzCliCommand "boards area team list `
                                        --team $($existingTeam.name) 
                                        --detect false" `
                                        -OutputType PSObject
                foreach($teamArea in $configuredTeam.properties.areas)
                {
                    $default = ""
                    $isDefault = $false
                    if($teamArea.EndsWith("*") -or $configuredTeam.properties.areas.Count -eq 1)
                    {
                        $teamArea = $teamArea.Replace("*","")
                        $default = "--set-as-default"
                        $isDefault = $true
                    }
                    
                    if($teamArea -eq "<root>")
                    {
                        $path = "\$($ProjectProperties.name)"
                    }
                    else {
                        $path = "\$($ProjectProperties.name)\$teamArea"                        
                    }

                    if($existingTeamAreas.values.Length -eq 0 -or (-not $existingTeamAreas.values | Any -Selector {$_.value -eq $path}))
                    {

                    
                    $ret = Invoke-AzCliCommand "boards area team add `
                                        --path ""$path"" `
                                        --team $($existingTeam.name) `
                                        --include-sub-areas true `
                                        $default  `
                                        --detect false"
                    }
                    elseif($isDefault -and $existingTeam.default -ne $path)
                    {
                        $path = $path.Substring(1)
                        $ret = Invoke-AzCliCommand "boards area team update `
                        --path ""$path"" `
                        --team $($existingTeam.name) `
                        $default  `
                        --detect false"
                    }

                }
            } 
  
        }

        $ret = Get-Teams -RefreshCache

        
    }
    end{
        
    }

}

Function Get-GroupOrTeamDescriptor{
    param (
        
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $GroupOrTeamName
    )

    $descriptorArray = Invoke-AzCliCommand "devops security group list --query ""graphGroups[?displayName=='$GroupOrTeamName'].descriptor""`
    --detect false" -OutputType TSV 

    if (-not $descriptorArray -is [array]) {
        return $descriptorArray
    }

    if ($descriptorArray.Length -eq 1) {
        return $descriptorArray[0]
    }

    $descriptor = $descriptorArray | FirstOrDefault -Selector { $_.StartsWith("vssgp") }

    if ($descriptor) { return $descriptor }
    Write-Error "Cannot resolve descriptor from group name"
}

Function Add-Team{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $Properties   
    )

    begin{}
    process{
         $teamDetails = Invoke-AzCliCommand "devops team create `
                      --name $Name `
                      --detect false" `
                      -OutputType PSObject  
                      
        return $teamDetails
    }
    end{}
}



