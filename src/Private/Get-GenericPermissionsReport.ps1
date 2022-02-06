
function Get-GenericPermissionsReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $permissions
        
    )

    $ErrorActionPreference = "Stop"

    $projects = Get-Projects
    $actions = (Get-SecurityNameSpaces | First -Selector {$_.namespaceId -eq $($permissions.namespaceId)}).actions | Select-Object -Property bit,name,displayName

    $namespace =$permissions.namespace
    $reportObject = @{ 
        $namespace=@()                            
    }


    foreach($namespacePermissions in $permissions.permissions)
    { 
        $permissionsObject = @{ Permissions=@() }     
               
        $sid = $namespacePermissions.acesDictionary.PSObject.Properties.Name
        $extendedInfo = $namespacePermissions.acesDictionary.$sid.extendedInfo
        if($null -ne $extendedInfo.effectiveAllow)
        {
           $permissionsObject.Permissions += "Allowed Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.effectiveAllow } | Select-Object -ExpandProperty displayName) -join "; ") 
        }
            
        if($null -ne $extendedInfo.effectiveDeny)
        {
            $permissionsObject.Permissions += "Denied Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.effectiveDeny } | Select-Object -ExpandProperty displayName) -join "; ")
        }
        
        if($null -ne $extendedInfo.inheritedAllow)
        {
            $permissionsObject.Permissions += "Inherited Allowed Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.inheritedAllow } | Select-Object  -ExpandProperty displayName) -join "; ")
        }

        if($null -ne $extendedInfo.inheritedDeny)
        {
            $permissionsObject.Permissions += "Inherited Denied Actions: " + (($actions | Where-Object { $_.bit -band $extendedInfo.inheritedDeny } | Select-Object -ExpandProperty displayName)  -join "; ")
        }
        
        
        $token = $namespacePermissions.token     
        
        Write-Verbose "Token: $token"

        $token = Resolve-PermissionToken -Token $token -Namespace $namespace
        $project = $projects | Where-Object { $token -match $_.id }

        if($null -ne $project)
        {
            $projectName = $project.name
            $token = $token.Replace($project.id, "[$projectName]")
        }
        
        $permissionsObject."Resource Identifier Token" = $token

        $reportObject.$namespace += $permissionsObject
    }
    
    return $reportObject
}

function Resolve-PermissionToken {
    param (
        # Token value
        [Parameter(Mandatory = $true)]
        [string]
        $Token,

        [Parameter(Mandatory = $true)]
        [string]
        $Namespace,

        [Parameter(Mandatory = $false)]
        [psobject]
        $currentNode  
    )

    #vstfs:///Classification/Node/af606206-fbee-40f9-b19f-93be9f79ee60:vstfs:///Classification/Node/7d703b79-4250-4989-b2c9-53ff45409f02
    $regex = ".*?([0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}){1,}"
    $match = Select-String -InputObject $token -Pattern $regex -AllMatches
    
    if(-not $currentNode) {
      switch($Namespace)    
      {
          "Iteration" {  $currentNode = Get-Iterations;break }
          "CSS" { $currentNode = Get-Areas; break }
          "Environment" { $currentNode = Get-Environments -ProjectName "Banana";break}
          default {return $Token }
      }

    }

    if ($null -eq $currentNode.path)
    {
        $resource = $currentNode.value | Where-Object { $token.EndsWith("/$($_.id)") -or $token.EndsWith("\$($_.id)") }
        if($null -ne $resource) 
        {
            $tokenArray = $token -split { $_ -eq "\" -or $_ -eq "/" } #-replace "$($resource.id)", "$($resource.name)" -join "/"
            for ($i = 0; $i -lt $tokenArray.Count; $i++) {
                if ($tokenArray[$i] -eq "$($resource.id)") {
                    $tokenArray[$i] = "$($resource.name)"
                }
            }
            $token = $tokenArray -join "/"
        }
        return $token
    }
   
    if($match.Matches.Length -gt 0)
    {
        if($match.Matches.Length -gt 1) 
        {
           $childAreaId = $match.Matches[1].Groups[1].Value
           $childArea = $currentNode.children | FirstOrDefault -Select {$_.identifier -eq $childAreaId }
           if(-not $childArea.hasChildren)
           {
               return $childArea.path
           }
           $childToken = $Token.Replace($match.Matches[0].Groups[0], "")
           return Resolve-PermissionToken -Token $childToken -currentNode $childArea -namespace $Namespace

        }
       
        return $currentNode.path  
    }
    else {     
            return $token        
    }


    
}