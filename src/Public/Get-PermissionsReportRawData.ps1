Function Get-PermissionsReportRawData{
    [cmdletbinding(DefaultParameterSetName='SecurityGroup')]
    Param(
        [Parameter(Mandatory = $true, Position=0,
        ParameterSetName='SecurityGroup')]
        [string]
        $TeamOrGroupName,

        [Parameter(Mandatory=$true,
        ParameterSetName='Individual')]
        [string]
        $IndividualEmail,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Namespaces

    )

  
    $namespacesToIgnore = Get-DeprecatedOrReadonlyNamespaces
    $allNamespaces =  Get-SecurityNameSpaces  | Where-Object {-not $namespacesToIgnore.Contains($_.name)}
    if($null -ne $Namespaces -or $Namespaces.Length -gt 0){
        $allNamespaces = $allNamespaces | Where-Object {$Namespaces.Contains($_.name) }
    }

    $descriptor = ''
    if ($PSCmdlet.ParameterSetName -eq 'SecurityGroup'){
        $descriptor = Get-GroupOrTeamDescriptor $TeamOrGroupName
    } else {
        $descriptor = $IndividualEmail
    }

    $allPermissions = @()
    foreach($namespace in $allNamespaces){
           
           Write-Verbose "Retrieving permissions for namespace $($namespace.name)"
           $permissions = Invoke-AzCliCommand "devops security permission list `
                --id $($namespace.namespaceId) `
                --subject $descriptor `
                --detect false" `
                -OutputType PSObject
           
           if($permissions.Count -ne 0)
           {      
                $sid = $permissions[0].acesDictionary.PSObject.Properties.Name  # Assumption is it's always same in t his context, have done a bit of testing           
                $permissions = $permissions |  Where-Object {$null -ne $_.acesDictionary.$sid.extendedInfo.effectiveAllow -or $null -ne $_.acesDictionary.$sid.extendedInfo.inheritedAllow -or $null -ne $_.acesDictionary.$sid.extendedInfo.effectiveDeny -or $null -ne $_.acesDictionary.$sid.extendedInfo.inheritedDeny}
           }

           $allPermissions += @{
               "namespace"=$namespace.name
               "namespaceId"=$namespace.namespaceId
               "permissions"=$permissions
           }

    }

    return $allPermissions

}
