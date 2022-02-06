function Sync-Environments {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $ProjectProperties,
        [Parameter(Mandatory)]
        [hashtable]
        $AllProperties
    )

    process {
        $ErrorActionPreference = "Stop"
        $definedTeams = Get-Teams
        $projectId = Get-Project | Select-Object -ExpandProperty id

        $environmentsToSync = $ProjectProperties.environments
        $definedEnvironments = Get-Environments -RefreshCache -ProjectName $ProjectProperties.name

        $environmentNamespace = Invoke-AzCliCommand "devops security permission namespace list --detect false --query ""[?name=='Environment']""" -OutputType PsObject
        $actionValues = @{}
        foreach ($action in $environmentNamespace.actions) {
            $actionValues[$action.name] = $action.bit
        }

        foreach($environment in $environmentsToSync)
        {
            $existingEnvironment = $definedEnvironments.value | FirstOrDefault -Selector { $_.name -eq $environment.name }
            $environmentInUse = $null
            
            if ($null -eq $existingEnvironment)
            {
                $payload = [PSCustomObject]@{
                    name = $environment.name
                    description = $environment.description
                } | ConvertTo-Json
                $createdEnvironment = Invoke-AdoApi -Area "distributedtask" -Resource "environments" -Method "POST" -Payload $payload -RouteParameters @{"project"="$($ProjectProperties.name)"} -OutputType PsObject
                $environmentInUse = $createdEnvironment
            } else
            {
                $environmentInUse = $existingEnvironment
                Write-Verbose "$($environmentInUse.name) already in use"
            }

            foreach($permission in $environment.permissions)
            {
                $existingTeam = $definedTeams | FirstOrDefault -Select { $_.name -eq $permission.identity}

                if ($null -eq $existingTeam)
                {
                    Write-Warning "Team defined in configuration: $($permission.identity), not found in ADO"
                    continue
                }

                $existingTeamDescriptor = Get-GroupOrTeamDescriptor -GroupOrTeamName $existingTeam.name
                
                $environmentToken = "Environments/$projectId/$($environmentInUse.id)"

                $permissionsToSync = $AllProperties.permissionSets | FirstOrDefault -Selector { $_.permissionSet -eq $permission.permissionSet }
                if ($null -ne $permissionsToSync)
                {
                    $allowActions = Get-ActionBits -ActionList $permissionsToSync.allowActions -ActionMap $actionValues
                    $denyActions = Get-ActionBits -ActionList $permissionsToSync.denyActions -ActionMap $actionValues
                    $updateResult = Invoke-AzCliCommand "devops security permission update --namespace-id $($environmentNamespace.namespaceId) --subject $existingTeamDescriptor --token $environmentToken --allow-bit $allowActions --deny-bit $denyActions --merge false --detect false" -OutputType PsObject
                    Write-Verbose "Successfully update permissions for $($environmentInUse.name) at $($updateResult.token)"
                } else
                {
                    Write-Warning "Permission Set defined in YAML under environments did not match any permission in permissionSets"    
                }
            }
        }
    }
}

function Get-ActionBits {
    param (
        [Parameter(Mandatory)]
        [array]
        $ActionList,
        [Parameter(Mandatory)]
        [hashtable]
        $ActionMap
    )

    $sum = 0
    foreach ($action in $ActionList)
    {
        $bits = $ActionMap[$action]

        if ($null -eq $bits)
        {
            Write-Warning "'$action' permission defined in config did not match known permissions"
        } else
        {
            $sum += $bits
        }
    }
    return $sum
}