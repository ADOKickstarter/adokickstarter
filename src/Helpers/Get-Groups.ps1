function Get-Groups {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false
    )
    
    return Get-CachedScriptBlockResult -Key "securitygroups" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AzCliCommand "devops security group list --detect false" -OutputType PSObject }
}