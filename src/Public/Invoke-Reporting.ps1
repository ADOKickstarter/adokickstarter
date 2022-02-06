function Invoke-Reporting {    
    [cmdletbinding()]
    Param(
        [Paramter(Mandatory = $true)]
        [ReportType]
        $ReportType,

        [Parameter(Mandatory = $true, ParameterSetName="YamlPreLoaded")]
        [Hashtable]
        $Properties,    

        [Parameter(Mandatory = $true, ParameterSetName="YamlNotLoaded")]
        [String]
        $YamlFilePath    
    )
    
begin{

}
process{
    $ErrorActionPreference = "Stop"
if($YamlFilePath){
    $Properties = Get-YamlProperties -YamlFilePath $YamlFilePath
} 

switch ($ReportType) {    
    YamlValidation { ValidateYaml $Properties }
    Permissioning { Write-Error "TODO: Permissioning report"}
    Default { Write-Error "Must supply a valid Report Type" }
}

}
end{

}



}

function ValidateYaml {
    Param(
        [Parameter(Mandatory = $true, Position=0)]
        [Hashtable]
        $Properties
    )
    begin{        
    }
    process{
        
        $json = $Properties | ConvertTo-Json -Depth 100
        
        if(-not (Test-Json -Json $Json -SchemaFile "$PSScriptRoot\\..\\Yaml\Schema\\Model-Schema.json"))
        {
            Write-Error "Yaml does not conform to schema"
        }


    }
    end{

    }

}




enum ReportType {
    None = 0
    YamlValidation = 1
    Permissioning = 2
}