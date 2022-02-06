BeforeAll {
    Import-Module $PSScriptRoot\..\src\ADOKickStarter.psm1 -Verbose -Force
    Initialize-Session -OrganizationUrl $organizationUrl -NoProject -Pattoken $pattoken   
    $testYamlPath = "$PSScriptRoot/Project.Tests.yml"
    $config = Get-Content -Path $testYamlPath | ConvertFrom-Yaml   
    $configProject = $config.projects.project
    $proj = Get-Projects -RefreshCache | Where-Object {$_.name -eq $configProject.name}
    if($proj){
      Invoke-AzCliCommand "devops project delete --id $($proj.id) --yes"
    }

    Sync-AdoYaml -YamlPath $testYamlPath
    $project = Get-Project -ProjectName $configProject.name -RefreshCache
}

Describe "Project Creation and Configuration" {
   It "Should be created" {
       $project | Should -Not -Be $null
   }
   
}

AfterAll {
    $proj = Get-Projects -RefreshCache | Where-Object {$_.name -eq $configProject.name}
    if($proj){
      Invoke-AzCliCommand "devops project delete --id $($proj.id) --yes"
    }

}

