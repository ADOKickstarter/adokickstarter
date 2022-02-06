return @{
    SwitchAzureBoardsEnable = @{
          Method="PATCH"
          Area="Blah"
          Resource=""
          RouteParameters=@{

          }
    }
    GetProjectProperties = @{
       Method="GET"
       Area="Core"
       Resource="properties"
       RouteParameters=@{projectId="{projectId}"}       
    }
}