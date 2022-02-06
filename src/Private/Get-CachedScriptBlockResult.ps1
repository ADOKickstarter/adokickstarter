Function Get-CachedScriptBlockResult {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $Key,

        [Parameter(Mandatory = $true)]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter()]
        [switch]
        $RefreshCache = $false
    )

    $CACHE_VARIABLE_NAME = "ADOKickstarter_Cache"

    if (-not (Get-Variable -Name $CACHE_VARIABLE_NAME -Scope Global -ErrorAction SilentlyContinue)) {
        Set-Variable -Name $CACHE_VARIABLE_NAME -Scope Global -Value @{}
    }

    $cache = Get-Variable -Name $CACHE_VARIABLE_NAME -Scope Global
    if ((-not $cache.Value.ContainsKey($Key)) -or $null -eq $cache.Value[$key] -or $RefreshCache) {
        $cachedValue = &$ScriptBlock
        $cache.Value[$Key] = $cachedValue
    }
    else {
        Write-Information "Getting cached value - key: $key"
        $cachedValue = $cache.Value[$Key]
    }

   return $cachedValue
}

Function ClearScriptBlockCache{
    Param(
        [Parameter(Mandatory = $false)]
        $Key
    )

    $CACHE_VARIABLE_NAME = "ADOKickstarter_Cache"
    if($key){

        $cache = Get-Variable -Name $CACHE_VARIABLE_NAME -Scope Global
        $cache.Value[$key] = @{}
        return
    }

    Set-Variable -Name $CACHE_VARIABLE_NAME -Scope Global -Value @{}


}