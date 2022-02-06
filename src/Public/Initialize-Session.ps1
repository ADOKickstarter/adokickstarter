
function Initialize-Session {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $OrganizationUrl,

        [Parameter(Mandatory = $false)]
        [String]
        $Project,
         
        [Parameter(Mandatory = $false)]
        [String]
        $Pattoken,

        [Parameter(Mandatory = $false)]        
        [switch]
        $Interactive = $false,

        [Parameter(Mandatory = $false)]      
        [switch]
        $Aad = $false,

        [Parameter(Mandatory = $false)]      
        [switch]
        $NoProject = $false


    )

    $ErrorActionPreference = "Stop"

    Write-Output "Checking for Azure CLI installation, version and devops extension"
    $azversion =  Invoke-AzCliCommand "version" -OutputType PSObject
    $azversion

    if(-not $azversion.extensions.'azure-devops')
    {
        Write-Error "Could not detect installation of azure-devops extension for azure cli"
    }
    else {

        Write-Output "Azure Devops extension version "
        Write-Output "Available versions:"
        Invoke-AzCliCommand "extension list-versions --name azure-devops" -OutputType PsObject | Format-Table
    }


    if(-not ($OrganizationUrl -And ($Project -or $NoProject)))
    {
        Write-Output "Using az devops defaults:"
        $config = & az devops configure --list
        if(-not $Project -and -not $NoProject)
        {
            # For some reason need to use the command directly
            $config = & az devops configure --list
            $ret = ($config | Where-Object { $_.StartsWith("project")}) -match "project = (.*)"
            if(-not $ret)
            {
                Write-Error "Cannot resolve Project from configured az devops defaults"
            }
            
            $Project = $Matches.1   

            if([string]::IsNullOrEmpty($Project))
            {
                Write-Error "No Project name configured or supplied"
            }
        }

        if(-not $OrganizationUrl)
        {
            $ret = ($config | Where-Object { $_.StartsWith("organization")}) -match "organization = (.*)"
            if(-not $ret)
            {
                Write-Error "Cannot resolve Organization Url from configured az devops defaults"
            }

            $OrganizationUrl = $Matches.1
            if([string]::IsNullOrEmpty($OrganizationUrl))
            { 
                Write-Error "No Organization Url configured or supplied"
            }
        }      
    }
    else {
        if($OrganizationUrl)
        {
            Invoke-AzCliCommand "devops configure --defaults organization=$OrganizationUrl"
        }

        if($Project)
        {
            Invoke-AzCliCommand "devops configure --defaults project=$Project"
        }
        elseif($NoProject)
        {
            Invoke-AzCliCommand "devops configure --defaults project=''"
        }        
    }

    if($Interactive)
    {
        if($Pattoken)
        {
            Write-Error "Interactive login and Pattoken parameter are incompatible"
        }
        
        if($Aad)
        {
            Invoke-AzCliCommand "login --allow-no-subscriptions"
        }
        else {     
            Invoke-AzCliCommand "devops login --organization $OrganizationUrl"            
        }
    }
    else {
        if(-not ($Pattoken -or $env:AZURE_DEVOPS_EXT_PAT))
        {
            Write-Error "No PAT Token detected - cannot login. Either supply a PAT token or set process/environment variable AZURE_DEVOPS_EXT_PAT to one"
        }

        if($Pattoken)
        {
            $env:AZURE_DEVOPS_EXT_PAT=$Pattoken          
        }       
    }

    ClearScriptBlockCache
    if($NoProject)
    {
        (Invoke-AzCliCommand "devops project list --detect false" -OutputType PsObject).value | Select-Object -Property name,description | Format-Table 
    }
    else{
        Get-Project | Format-List 
    }
    Write-Output "Session succesfully initialized"
    
}