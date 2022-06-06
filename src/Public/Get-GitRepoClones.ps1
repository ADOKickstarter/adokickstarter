function Get-GitRepoClones {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [array]
        $repos,
        [Parameter()]
        [string]
        $cloneParentFolder
    )

    process {
        $ErrorActionPreference = "Stop"
        if ($null -ne $cloneParentFolder) {
            # Todo: check location valid
            Push-Location -Path $cloneParentFolder
        }

        try {
            foreach ($repo in $repos) {
                # TODO: check if repo clone already exists and skip if so
                Write-Output "Cloning $($repo.name)"
                & git clone $($repo.remoteUrl)
            }
        }
        finally {
            
            if ($null -ne $cloneParentFolder) {
                Pop-Location           
            }
        }
    }

}

