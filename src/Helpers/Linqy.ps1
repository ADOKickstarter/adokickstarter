function FirstOrDefault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [object]
        $InputValue,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [boolean]
        $Selector
    )
    begin{       
        $first = $null
    }
    process{
             $ErrorActionPreference = "Stop"
             
             if(-not $first -and $Selector -eq $true)
             {  
                 $first = $InputValue
             } 
             # At present not possible to break pipeline processing once item has been found 
        }
    end{           
            return $first
        }
}


function Any {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [object]
        $InputValue,

        [Parameter(Mandatory=$true,ValueFromPipeline, ValueFromPipelineByPropertyName, ValueFromRemainingArguments)]
        [boolean]
        $Selector
    )
    begin{       
       
    }
    process{
             $ErrorActionPreference = "Stop"
             
             if($Selector -eq $true) {
             return $true
               }
             # At present not possible to break pipeline processing once item has been found 
        }
    end{           
            return $false
        }
}




function First {
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [array]
        $InputValue,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Nullable[boolean]]
        $Selector
    )
    begin{       
        $first = $null
    }
    process{
             $ErrorActionPreference = "Stop"
             
             if(-not $first)
             {  
                if($null -eq $Selector)
                {
                    $first = $InputValue
                }
                elseif($Selector)
                { 
                    $first = $InputValue
                }
             }
       
             # At present not possible to break pipeline processing once item has been found
        }
        end{           
            if($first)
            {
                return $first
            }
            Write-Error "No matching items found in pipeline"
        }
}

function SingleOrDefault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [array]
        $InputValue,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [boolean]
        $Selector
    )
    begin{       
        $first = $null
    }
    process{
             $ErrorActionPreference = "Stop"
             
             
             if($Selector -eq $true)
             {  
                 if(-not $first)
                 {
                   $first = $InputValue
                 }
                 else {
                     Write-Error "More than one matching items found in sequence"
                 }
             }
       
             # At present not possible to break pipeline processing once item has been found
        }
        end{  
                return $first         
     
        }
}


function Single {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [array]
        $InputValue,

        [Parameter(Mandatory=$true,ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [boolean]
        $Selector
    )
    begin{       
        $first = $null
    }
    process{
             $ErrorActionPreference = "Stop"
                          
             if($Selector -eq $true)
             {  
                 if(-not $first)
                 {
                   $first = $InputValue
                 }
                 else {
                     Write-Error "More than one matching items found in sequence"
                 }
             }
       
             # At present not possible to break pipeline processing once item has been found
        }
        end{          
            if($first)
            {
                return $first
            }
            Write-Error "No matching items found in pipeline"
     
        }
}

