Function Sync-Projects {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $AllProperties    
    )
    $ErrorActionPreference = "Stop"
    foreach($projectKv in $AllProperties.projects)
    {
        $project = $projectKv.project
        
        $projectName = $project.name

        $projectExists = Get-Projects -RefreshCache | Any -Selector {$_.name -eq $projectName }
        
        $projectDetails = @{}
        if($projectExists)
        {
            $projectDetails = Get-Project $projectName
        }
        else
        {
            $projectDetails = Add-Project -ProjectName $projectName -ProcessTemplate $project.boards.processTemplate
        }

        
        Invoke-AzCliCommand "devops configure --defaults project=$projectName"
        $featureSwitch = Get-Content -Path "$PSScriptRoot\..\Payloads\Switch-Feature.json" | ConvertFrom-Json 
        
        $featureSwitch.featureId = "ms.vss-work.agile"
        $featureSwitch.state = [int][bool]::Parse($project.features.boards)
        $body = $featureSwitch | ConvertTo-Json -depth 100
        Invoke-RawAdoApi -ResourcePath "FeatureManagement/FeatureStates/host/project/$($projectDetails.id)/$($featureSwitch.featureId)" -Body $body -Method PATCH
        
        $featureSwitch.featureId = "ms.vss-code.version-control"
        $featureSwitch.state = [int][bool]::Parse($project.features.repos)
        $body = $featureSwitch | ConvertTo-Json -depth 100
        Invoke-RawAdoApi -ResourcePath "FeatureManagement/FeatureStates/host/project/$($projectDetails.id)/$($featureSwitch.featureId)" -Body $body -Method PATCH

        $featureSwitch.featureId = "ms.vss-build.pipelines"
        $featureSwitch.state = [int][bool]::Parse($project.features.pipelines)
        $body = $featureSwitch | ConvertTo-Json -depth 100
        Invoke-RawAdoApi -ResourcePath "FeatureManagement/FeatureStates/host/project/$($projectDetails.id)/$($featureSwitch.featureId)" -Body $body -Method PATCH

        $featureSwitch.featureId = "ms.vss-test-web.test"
        $featureSwitch.state = [int][bool]::Parse($project.features.testplans)
        $body = $featureSwitch | ConvertTo-Json -depth 100
        Invoke-RawAdoApi -ResourcePath "FeatureManagement/FeatureStates/host/project/$($projectDetails.id)/$($featureSwitch.featureId)" -Body $body -Method PATCH

        $featureSwitch.featureId = "ms.feed.feed"
        $featureSwitch.state = [int][bool]::Parse($project.features.artifacts)
        $body = $featureSwitch | ConvertTo-Json -depth 100
        Invoke-RawAdoApi -ResourcePath "FeatureManagement/FeatureStates/host/project/$($projectDetails.id)/$($featureSwitch.featureId)" -Body $body -Method PATCH
    

        # # Repos
        Sync-Repos -ProjectProperties $project
        # Boards

        Sync-Areas -ProjectProperties $project

        Sync-Iterations -ProjectProperties $project

        Sync-Teams -ProjectProperties $project -AllProperties $AllProperties
        

    }   
                    
}