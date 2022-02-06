function Get-Iterations {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    
    return Get-CachedScriptBlockResult -Key "iterations" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "boards iteration project list --depth 10 --detect false" -OutputType PSObject }
}