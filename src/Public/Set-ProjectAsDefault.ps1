
function Set-ProjectAsDefault {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ProjectName
    )

    $ErrorActionPreference = "Stop"
    
    Clear-ScriptBlockCache
    $project = Get-Projects | Where-Object {$_.name -eq $ProjectName}

    if(-not $project)
    {
        Write-Error "Project $ProjectName does not exist in the current organization or you do not have access to it"        
    }

    Invoke-AzCliCommand "devops configure --defaults project=""$ProjectName"""   
}