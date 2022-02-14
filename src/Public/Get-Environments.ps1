function Get-Environments {
    Param(
        [Parameter()]
        [switch]
        $RefreshCache = $false,
        [Parameter(Mandatory)]
        [string]
        $ProjectName
    )

    return Get-CachedScriptBlockResult -Key "allenvironments" -RefreshCache:$RefreshCache -ScriptBlock  { Invoke-AdoApi -Area "distributedtask" -Resource "environments" -Method "GET" -Routeparameters @{"project" = "$ProjectName"} -OutputType PSObject }
}