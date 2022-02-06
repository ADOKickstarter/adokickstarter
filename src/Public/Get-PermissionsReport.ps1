function Get-PermissionsReport {
        [CmdletBinding(DefaultParameterSetName='SecurityGroup')]
        Param(
            [Parameter(Mandatory = $true,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName,
            ParameterSetName='SecurityGroup')]
            [string]
            $TeamOrGroupName,

            [Parameter(Mandatory=$true,
            ParameterSetName='Individual')]
            [string]
            $IndividualEmail,
            
            [Parameter(Mandatory = $false)]
            [string[]]
            $Namespaces,

            [Parameter(Mandatory=$false)]
            [ValidateSet("Console", "HTML", IgnoreCase = $true)]
            [string]
            $FormatOutput = $null


        )
    begin{
       $reportData = @()
    }
    process{
        $rawReportData=@()
        if($PSCmdlet.ParameterSetName -eq 'SecurityGroup'){
            $rawReportData = Get-PermissionsReportRawData -TeamOrGroupName $TeamOrGroupName -Namespaces $Namespaces
        } else {
            $rawReportData = Get-PermissionsReportRawData -IndividualEmail $IndividualEmail -Namespaces $Namespaces
        }
       
      
        foreach($namespaceReport in $rawReportData)
        {
            switch($namespaceReport.namespace)
            {
                "Git Repositories" { $reportData += Get-RepoPermissionsReport $namespaceReport; Break }
                default {$reportData += Get-GenericPermissionsReport $namespaceReport }
            }
        }

     
    }
    end{
      if(-not [string]::IsNullOrWhiteSpace($FormatOutput))
      {
          #Namespace |
          #          | Resource Name Field | Resource Name
          #          | "Permissions"       | Permissions[0]
          #          |                     | Permissions[1] ...
          $formatted = @()
          foreach($item in $reportData)
          {           
              #Namespace |
              $namespace = $($item.Keys)
            #   $formatted += @{
            #       Namespace=$item.Keys[0]
            #       Resource=""
            #       Permissions=""         
            #      }
            foreach($resource1 in $item.Values)
            {
                if($resource1.Length -eq 0)
                {
                    continue
                }
   
              foreach($resource in $resource1.Values)
               {
                    #          | Resource Name  | 1st permissions value
                    #          |                | 2nd permissions value...
                   
                    if($resource -is [string]){
                        if([string]::IsNullOrEmpty($resource)){$col2 = "-"} else {$col2 =  $resource }
                        continue
                    }
                    else {
                    foreach($perms in $resource){
                    $formatted += @{
                        Namespace=$namespace
                        Resource=$col2
                        Permissions=$perms
                    }
                    $col2 = "-"
                }
                }                 
                  
      
            }
            }     
          }
          switch($FormatOutput.ToLower()) 
          {
            "console" { return $formatted | ForEach-Object {[PSCustomObject]$_} | Format-Table -Wrap -Property Resource,Permissions -GroupBy NamesPace }
            "html" { return $formatted | ForEach-Object {[PSCustomObject]$_} | ConvertTo-Html -Title "Permission Lists" -Property Resource,Permissions }
          }         
            
      }
      
      return $reportData
    }
    
}
