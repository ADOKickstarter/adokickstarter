function Get-Teams {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    
    return Get-CachedScriptBlockResult -Key "teams" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "devops team list --detect false" -OutputType PsObject }
}