Function Add-Project{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectName, 

       [Parameter(Mandatory = $false)]
       [string]
       [ValidateNotNullOrEmpty()]
       $ProcessTemplate = "Agile" ,
       
       [Parameter(Mandatory = $false)]
       [string]
       $Description = "Project created by ADOKickstarter automation"

    
    )


    process {     
       $ErrorActionPreference = "Stop"
     
       $existingProject = Invoke-AzCliCommand "devops project list --query ""value[?name=='$ProjectName'] | length(@)"" --detect false" -OutputType TSV
       if($existingProject -eq 1)
       {
           Write-Error "Project '$ProjectName' already exists"
           return
       }
     
       $project = Invoke-AzCliCommand "devops project create --name ""$ProjectName"" `
                               --description ""$Description"" `
                               --detect false `
                               --process ""$ProcessTemplate"" " -OutputType PSObject

       Invoke-AzCliCommand "devops configure --defaults ""project=$ProjectName"""
                  
       return $project
    }
}
