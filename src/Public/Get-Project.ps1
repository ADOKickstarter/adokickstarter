function Get-Project {
    [cmdletbinding()]
    param (
        # Optional project name
        [Parameter(Mandatory = $false)]
        [string]
        $ProjectName,

        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    

    if([string]::IsNullOrEmpty($ProjectName))
    {
        $config = & az devops configure --list
        $m = ($config | Where-Object { $_.StartsWith("project")}) -match "project = (.*)"
        $ProjectName = $Matches.1
    }
    $key = "project-{0}" -f $($ProjectName.Replace(" ", ""))
    return Get-CachedScriptBlockResult -Key $key -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "devops project show --project ""$projectName""  --detect false" -OutputType PSObject }

}