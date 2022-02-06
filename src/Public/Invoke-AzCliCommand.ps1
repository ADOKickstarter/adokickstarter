Function Invoke-AzCliCommand{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Command,

        [Parameter(Mandatory = $false)]
        [CliOutput]
        $OutputType,

        [Parameter(Mandatory = $false)]
        [switch]
        $SuppressOutput,

        [Parameter(Mandatory = $False)]
        [hashtable]
        $Secrets,

        [Parameter(Mandatory = $False)]
        [switch]
        $DisableSslVerification
    )
    
begin {

}

end {
    $ErrorActionPreference = "Stop"     

    if ($DisableSslVerification){
        $env:ADAL_PYTHON_SSL_NO_VERIFY = "true"
        $env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "true"
    }
    else{
        Remove-Item env:\ADAL_PYTHON_SSL_NO_VERIFY -ErrorAction SilentlyContinue
        Remove-Item env:\AZURE_CLI_DISABLE_CONNECTION_VERIFICATION -ErrorAction SilentlyContinue
    }

    $command = $command -replace "`n|`r"
  
    if ($null -ne $Secrets) {
        $secretsParameters = Get-ParameterString $Secrets
        $printableParameters = Get-ParameterString $Secrets -MaskValues
        $runCommand = "{0} {1}" -f $Command, $secretsParameters
        $printableRunCommand = "az {0} {1}" -f $Command, $printableParameters
    } else {
        $runCommand = $command
        $printableRunCommand = "az {0}" -f $command
    }

    if ($OutputType -eq "Tsv") {
        
        $runCommand = "{0} --output tsv" -f $runCommand
        $printableRunCommand = "{0} --output tsv" -f $printableRunCommand
    }

    $printableRunCommand = $printableRunCommand -replace "[ ]{2,}", " "
    Write-Host "Executing following az command:"
    Write-Host $printableRunCommand -ForegroundColor DarkMagenta

    $commandArgs =  [regex]::Split( $runCommand, ' (?=(?:[^"]|"[^"]*")*$)' )

    # Executing the command
    $output = & az $commandArgs 
    
    Write-Verbose "AzCli Exit Code $LASTEXITCODE"
        
    # if ($null -ne $output -and ($PSBoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue' )) {
    #     Write-Verbose "Command complete. Output:"
    #     # Note sensitive details may be disclosed hence keep this commented out unless needed.
    #     Write-Host $output
    #  }

    if ($? -ne $true -or $LASTEXITCODE -ne 0) {
        Write-Error "Error executing az command: $printableRunCommand"         
        return
    }

    if($null -eq $output) {
        return
    }
    
    switch ($OutputType) {
        Json { return $output  }
        Tsv { return $output }
        PsObject {
            try{
                $Json = -Join $Output | ConvertFrom-Json -ErrorAction Stop
                Return $Json
            }
            catch{
                Write-Debug "az output is not valid json"     
            }
        }
        Default { return }
    }
}
}