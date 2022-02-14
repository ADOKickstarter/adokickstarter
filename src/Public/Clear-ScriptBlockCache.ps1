Function Clear-ScriptBlockCache{
    [CmdletBinding()]
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