function Get-Areas {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    
    return Get-CachedScriptBlockResult -Key "areas" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "boards area project list --depth 10 --detect false" -OutputType PSObject }
}