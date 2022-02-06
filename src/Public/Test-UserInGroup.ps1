Function Test-UserInGroup{
    [cmdletbinding()]
    Param(
 

       [Parameter(Mandatory = $true)]
       [ValidateScript({IsValidEmail $_})]
       [string]
       $UserEmailAddress, 



       [Parameter(Mandatory = $true)]
       [string]
       $GroupName

    )


    process {     
       $ErrorActionPreference = "Stop"      

       $userDescriptor = Invoke-AzCliCommand "devops user list --query ""items[?user.principalName=='$UserEmailAddress'].user.descriptor"" --detect false" -OutputType TSV

       if($null -eq $userDescriptor){
         Write-Error "Invalid user email address/UPN: $UserEmailAddress"
      }

       $groupDescriptor = Invoke-AzCliCommand "devops security group list --query ""graphGroups[?displayName=='$GroupName'].descriptor"" --detect false" -OutputType TSV

      if($null -eq $groupDescriptor){
         Write-Error "Invalid group $GroupName (Parameter is case-sensitive)"
      }

      try {
         $ret = Invoke-AzCliCommand "devops invoke --area graph --resource memberships --route-parameters containerDescriptor=$groupDescriptor subjectDescriptor=$userDescriptor --api-version 6.1-preview"   
      }
      catch {
         Write-Error "User $UserEmailAddress not in correct group" 
      }
      

    }
}
