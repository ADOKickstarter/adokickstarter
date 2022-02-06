function Get-SecurityNameSpaces {
    param (
        [Parameter()]
        [bool]
        $LocalOnly = $false
    )
    $ErrorActionPreference = "Stop"
    
    if($LocalOnly){
     return Get-CachedScriptBlockResult -Key "SecurityNamespacesLocal" -ScriptBlock { 
            Invoke-AzCliCommand "devops security permission namespace list   --local-only --detect false" -OutputType PSObject 
        }
    }

    return Get-CachedScriptBlockResult -Key "SecurityNamespaces" -ScriptBlock { 
       Invoke-AzCliCommand "devops security permission namespace list $local --detect false" -OutputType PSObject 
    }
}


function Get-DeprecatedOrReadonlyNamespaces {
    return @("CrossProjectWidgetView",
    "DataProvider",
    "Favorites",
    "Graph",
    "Identity2",
    "IdentityPicker",
    "Job",
    "Location",
    "ProjectAnalysisLanguageMetrics",
    "Proxy",
    "Publish",
    "Registry",
    "Security",
    "ServicingOrchestration",
    "SettingEntries",
    "Social",
    "StrongBox",
    "TeamLabSecurity",
    "TestManagement",
    "VersionControlItems2",
    "ViewActivityPaneSecurity",
    "WebPlatform",
    "WorkItemsHub",
    "WorkItemTracking",
    "WorkItemTrackingConfiguration")
}

