function Get-YamlProperties {
    param (
        
        [Parameter(Mandatory = $true)]
        [string]
        $YamlFilePath
    )

    begin {        
    }
    process{
        $ErrorActionPreference = "Stop"
        if(-not (Test-Path -Path $YamlFilePath -PathType Leaf))
        {
            Write-Error "File ""$YamlPath"" does not exist or not accessible"
        }
        try {
             $properties = Get-Content -Path $YamlPath | ConvertFrom-Yaml 
             return $properties
   
        }
        catch {
            Write-Error "Error loading yaml file at ""$YamlPath"""
            Write-Error "Error is $_.Message"
        }
    }
        
    end{

    }

    
}