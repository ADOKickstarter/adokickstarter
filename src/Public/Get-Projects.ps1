function Get-Projects {
    [cmdletbinding()]
    param (
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )

    Get-CachedScriptBlockResult -Key "allprojects" -RefreshCache:$RefreshCache -ScriptBlock { (Invoke-AzCliCommand "devops project list --detect false --get-default-team-image-url false" -OutputType PSObject).value }
}