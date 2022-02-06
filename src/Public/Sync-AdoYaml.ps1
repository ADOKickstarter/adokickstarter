function Sync-AdoYaml {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [string]
      $YamlPath
    )
    begin{
      
    }
    process{     
      
      $config = Get-Content -Path $YamlPath | ConvertFrom-Yaml  

      Sync-Projects $config
      
    }
    end{

    }
    
}