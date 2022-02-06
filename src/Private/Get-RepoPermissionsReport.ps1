function Get-RepoPermissionsReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $gitRepoPermissions
        
    )

    $ErrorActionPreference = "Stop"
    
    $repos = Get-Repos
    
    $gitSecurityNamespace = Invoke-AzCliCommand "devops security permission namespace show `
              --id  $($gitRepoPermissions.namespaceId) `
              --detect false" `
              -OutputType PSObject
    
    $actions = $gitSecurityNamespace.actions | Select-Object -Property bit,name,displayName
    $repoReportObject = @{ 
                            "Git Repositories"=@()                            
                        }

    
    foreach($repoPermission in $gitRepoPermissions.permissions)
    { 
        $reportObject = @{ Permissions=@() }     
               
        $sid = $repoPermission.acesDictionary.PSObject.Properties.Name
        $extendedInfo = $repoPermission.acesDictionary.$sid.extendedInfo
        if($null -ne $extendedInfo.effectiveAllow)
        {
           $reportObject.Permissions += "Allowed Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.effectiveAllow } | Select-Object -ExpandProperty displayName) -join "; ") 
        }
            
        if($null -ne $extendedInfo.effectiveDeny)
        {
            $reportObject.Permissions += "Denied Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.effectiveDeny } | Select-Object -ExpandProperty displayName) -join "; ")
        }
        
        if($null -ne $extendedInfo.inheritedAllow)
        {
            $reportObject.Permissions += "Inherited Allowed Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.inheritedAllow } | Select-Object -ExpandProperty displayName) -join "; ")
        }

        if($null -ne $extendedInfo.inheritedDeny)
        {
            $reportObject.Permissions += "Inherited Denied Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.inheritedDeny } | Select-Object -ExpandProperty displayName)  -join "; ")
        }
        
        # Get repo name
        $token = $repoPermission.token              
        Write-Verbose "Token: $token"
        $repo = $repos | FirstOrDefault -Selector {$token.Contains($_.id) }
        if($null -ne $repo)
        {
            $reportObject."Repository Name" = $repo.name}
        else {
            $reportObject."Repository Name" = "Default Inherited Permissions"
        }

        $repoReportObject."Git Repositories" += $reportObject
    }

    return $repoReportObject
}