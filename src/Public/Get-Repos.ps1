function Get-Repos {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    
    return Get-CachedScriptBlockResult -Key "repos" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "repos list --detect false" -OutputType PSObject }
}