# Azure DevOps Kickstarter Scripts

## Introduction

The Azure DevOps (ADO) Kickstarter tooling is a Powershell module that supports the configuration and management of Azure DevOps
### Key Features

- Wrapper functions around the Azure CLI (to leverage teh Azure DevOps Extension for the Azure CLI)
- A yaml based basic setup/configuration toolset to help with rapid setup adn configuration of an Azure DevOps project
- Permissions reporting to help maintain permissioninng integrity



## Getting Started

### Prerequisites

- Powershell - Core (latest - tested on 7.2.1) or for Windows ("Desktop" - tested on 5.1.22000.282)
- Set up powershell gallery-based module installation - https://docs.microsoft.com/en-us/powershell/scripting/gallery/overview?view=powershell-7.2 
- powershell-yaml module - https://www.powershellgallery.com/packages/powershell-yaml/0.4.2 
- Azure CLI (latest - tested on 2.32.0)
- Azure DevOps extension for Azure CLI ("azure-devops"latest - tested on 0.20.0)
- Various utility functions to help when scripting/interacting with Azure DevOps

The module has been tested on Windows 10/11 but can run on linux subject to the prereqs being run.

### Module Installation
Currently the module is loaded using the import module directly from the source code tree under the src folder
To install:
**Import-Module ".\src\ADOKickStarter.psm1" -Force -Verbose**

### Initialization/Authentication

The module can authenticate using the following mechanisms:
- Azure DevOps Server: Personal Access Token (PAT)
- Azure Devops Services: Personal Access Token, AAD Authentication
Note: Windows NTLM/KErberos auth is not supported for Azure DevOps Server

The personal access token should be full scoped - note this should be carefully handled as a secret

To set up a session:
Run the Initialize-Session funtion:
**Initialize-Session [[-OrganizationUrl] <string>] [[-Project] <string>] [[-Pattoken] <string>] [-Interactive] [-Aad] [-NoProject] [<CommonParameters>]**
Parameters (all are optional)
- OrganizationUrl - the full url (be it Server or Services) e.g. https://dev.azure.com/myorg or https://adoserver:8888/ (optional if this has already been set using the az devops configure command or in a previous execution of Initialize-Session)
- Project - the project name (optional if this has already been set using the az devops configure command or in a previous execution of Initialize-Session)
- NoProject - where there is no project to be selected or the intent is to execute commands at the Organization/Project Collection level (e.g. create a new project)
- Pattoken - a pattoken generated for your user account (or a suitable user) that is configured for all scopes (can be refined should the need arise). The user's permissions in the Project Collection determine what can be done using this token. If not supplied then either AAD authentication is used or an existing, valid PAT token has already been supplied and/or configured (as the AZURE_DEVOPS_EXT_PAT environment/process variable)
- Interactive - login will be interactive therefore a PAT token will be prompted for or AAD 
- AAD - only compatible with Interactive- authentication will be via Azure Active Directory (a browser window/tab will open with your AAD domain's login flow)

Once successfully authenticated the command will retrieve the details about the default project specified/previously configured or if -NoProject was specified then the list of existing projects
If a PAT Token is configured and initialize-session has already been run, then either it does not have to be run or you can run it without any parameters to verify you can proceed


### Isolated network/Offline installation guidance

Powershell modules can be downloaded and stored in a folder and installed from there. References:
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/working-with-packages/manual-download?view=powershell-7.2
- https://learn-inside.com/install-powershell-module-in-offline-mode/

Azure CLI is installed from a self-contained MSI

Azure DevOps extension for Azure CLI - this is done via having a python PIP repo, see:
- https://github.com/Azure/azure-devops-cli-extension/issues/1055
- https://github.com/Azure/azure-cli-extensions/issues/2484#issuecomment-809682541 


## Sync

This is the mechanism by which a Project can be set up and elements of its configuration can be synchronised using definitions in a Yaml file. 

### Yaml Configuration file ###
The yaml based configuration file represents a reusable templating mechanism for projects and a bridge between the UI and the underlying APIs and data. Some of the yaml tries to reflect nomenclature found in the UI, and overall it acts as an accelerator to alleviate a lot of (fiddly) UI interaction to configure Teams, Boards, Repos and (in time) Permissions.

Two yaml files are in the repo in the yaml folder:
1. SupportedModel.yml - this file contains the supported yml configuration covering the currently implemented scope
2. DesignModel.yml - this file shows design intent for the next possible features as well as the supported yaml definitions
SupportedModel.yml can be run to create and configure a new project. 

To get started take SupportedModel.yml and edit to reflect your desired configuration - Project name, features, areas, iterations, repos, teams.

Don't forget you can run this to create/modify an existing project and delete the project and start again. However be wary of running this against a project that is live/in use - notwithstanding it is mainly additive/idempotent - see note 2 below.


To apply the configuration in the file run the following cmdlet (after importinghte module and running Initialise-Session)
**Sync-AdoYaml [-YamlPath] <string> [<CommonParameters>]**
The configured project will be changed to whichever project is being created / configured (and left as the last project configured)
Separate files can be used for different projects - it is not recommended that different files be applied to the same project.

**Notes:**
1. Initially primarily to be used at initial project creation and immediate configuration thereafter. Due to the complexity of the product (mainly in its vast sprawl) and the ease with which configuration can be changed in the UI or via tools, configuration drift from the yaml and/or incompatibilities are highly likely after time (e.g. new iterations, new areas, repo policy changes)
2. It is mostly additive and idempotent - it will not delete definitions/resources but add any definitions not found. In places changes will update/replace an existing configuration. 
3. It is highly extensible - once familiar with the tooling incorporating additional capabilities can be extremely fast especially if it's covered by the Azure DevOps extentiosn for the Azure CLI or by a supported/documented API endpoint
4. The yaml file is converted in to a hashtable object tree - hashtables do have some foibles especially if you want to use variable/dynamic key names (e.g in the Areas hierarchy) but once understood very powerful and enables simple readable yaml structures.

### Yaml Configuration Reference ###
Hopefully the yaml is self-explanatory to anyone familiar with the product and UI.

1. **modelVersion** - there in case massive changes trigger a minor or major version change to the way the yaml is processed
2. **projects** - array of one or more projects
3. **project - name** - the name of the project - cannot be changed once a project is created and is used as the reference, spaces supported (but not recommended)
4. **project - features** - a list of boolean properties mapped to the features of the project
5. **boards - processTemplate** - the name of the process template that the project uses - applied only at project creation (changing it in TODOs)
6. **boards - areas** - the hierarchy of areas - spaces supported.
7. **boards - iterations** - the hierarchy of iterations, for a given iteration start date can be specified and then child iteration length (in days) specified - then all children will have contiguous start/finish dates and the end of the last child iteration will also be the finish date of that iteration. Iteration length includes the start date. Spaces supported in names, date in dd-MM-yyyy format, child iteration length is an integer. 
8. **teams - team** - the name of team
9. ** team - properties - backlogIteration** - the path of the iteration that represents the backlog iteration - if "<Root>" then will be the root iteration of the entire project.
10. **teams - team - properties - areas ** - the areas assigned to the teams, an asterisk (*) denotes the default area, or if only one area assigned then that is automatically made the default. Note all sub-areas are automatically included by default
11. **git - repos - repo ** - Repo name - cannot be changed once repo is created
12. **git - repos - repo - settings - defaultBranch ** - the default branch - required - must exist or to apply on repo creation initOnCreation must be true. The default branch is initialised with a templated readme file in the initial commit.
13.  **git - repos - repo - settings - initOnCreation ** - true/false - this means if repo doesn't exist, when created, the settings will be applied
14.  **git - repos - repo - settings - branchPolicies ** if initOnCreation is true then these branches will be created and the policies applied. Branches subsequent to the default branch are branched off its intialised ref.



## Permissions Report
The permissions report is key to ensuring that security segregation in a project is maintained. Azure DevOps security is based on a concept of security Namespaces that cover the various resrouces/functional areas of the product. For a given Azure DevOps group or team and a given set of security namespaces (or all namespaces), the report displays the configured  permissions settings (including explicit deny access settings). Returns permissions data that describes what permissions a team has in a given namespace in an intermediate data format (using a powershell hashtable object) or as output formatted for the console (using the -FormatOutput switch)

**Get-PermissionsReport [-TeamOrGroupName] <string> [-Namespaces <string[]>] [-FormatOutput] [<CommonParameters>]**

Parameters:
- TeamOrGroupName (required) - the name of the Azure DevOps group or project team to report on
- Namespaces (optional) - comma-separated list of one or Namespaces to report on. Namespaces are documented at https://docs.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference or are available using the az devops cliu command: **az devops security permission namespace list** (you can use the --query/--output parameters or powershell to filter/format the output). If absent ALL non-depreacated/non read-only namespaces are used (WARNING: This takes quite a while).
- FormatOutput (optional) - formats the output for display in tabulated format in the Powershell console, grouped by namespace.

## Invoke-AzCliCommand
This is a wrapper for the Azure CLI (and thus the DevOps extension) to enable it to interact with powershell scripting. One useful feature is it will print the full command before executing it (note: secrets are masked if passed using the -Secrets parameter)

**Invoke-AzCliCommand [-Command] <string> [[-OutputType] <CliOutput>] [[-Secrets] <hashtable>] [-SuppressOutput] [-DisableSslVerification] [<CommonParameters>]**


Parameters:
 - Command - the az command (without "az") to execute - this can include powershell variables to provide the inputs (note instead of the *--output* parameter use the cmdlet -OutputType parameter, see below)
 - OutputType - valid values: None, Json, PSObject, TSV - controls the *--output* parameter of the az cli command - if none the output is returned raw. Common use would be to turn json output to Powershell Hashtable object for onward processing
 -Secrets - a hashtable with SecureString or String values that map to values required in the command. THe name of the hashtable property should match the name of the Az cli command parameter e.g. *@{ password=<securestring> }* then would translate to **az something dosomething *--password <raw value>* **
- SuppressOutput - if you want to hide the outputs of the cmdlet 
- DisableSslVerification - for use when an http proxy is sitting between the cli and azure / azure devops



## API-based updates ##

There are three types of interaction with ADO in this library
1. Via Azure DevOps extension based CLI calls e.g. *az devops project list*
2. API calls via *az devops invoke ...* - these have to use supported/documented api uri routes to work - this covers only a subset of the API - beyond what the CLI extension supports but nowhere near the totality of what can be done in the UI. This uses the *Invoke-AdoApi* helper public function
3. What have been termed "raw API calls" - these are API calls mainly based on using a tool such as fiddler to chrome dev tools to record a UI update, save the request payload json. and construct a RESTful HTTP(s) call to the API endpoints using the recorded URI pattern to make the change. THis uses the *Invoke-RawAdoAPi* private function

##Powershell Notes/Hints & Tips##

###Why Powershell###
1. Well-know script language at least within the Microsoft eco-system. Many examples and guidance. Easy to use for anyone with a scripting or programming background (once foibles are understood) - especially powerfull for those with .NET programming skills.
2. Is cross-platform not just for windows
3. Supports functions/commandlets and modules

## Hints & Tips ##

1. Once a module is installed you can interrogate its syntax using Get-Command, note also inellisense/auto-completion is supported in the powershell terminal (Ctrl+SpaceBar). To get the syntax of a cmdlet:
*Get-Command <cmdlet> -Syntax* e.g. *Get-Command Invoke-AzCliCommand -Syntax*
2. Commandlets should be prefixed with an apporved verb to avoid irksome warnings (it is how it is) - to get those verbs run Get-Verb
3. Any text editor can be used to develop powershell, and there's the Powershell ISE app that comes with windows BUT on balance the best experience is using Visual Studio Code and the Powershell extension - this ahs a lot of powershell functionality including debugging support. Also consider the Windows Terminal app for raw console use as it supports multiple different terminal types (cmd, git-bash, powershell core and desktop) in multiple tabs.
4. ` is a line continuation mark handy for spreading cmdlet parameters over multiple lines - can be used within quote pairs.





## Suggested enhancements / Next steps##

(T-Shirt size estimates - XS,S,M,L,XL,XXL) - medium about half to 3/4 a days work
1. Update JSON schema and enforce validation (see below) - M
2. Team iteration assignment - S
3. Team/group repo access/permissioning - using PermissionSets (see DesignModel.yaml) - M
4. Team/group boards access/permissioning - S
5. Permissioning report on individual user account) - XS
6. Improved validation of elements so typos/misnamed references can be communicated more clearly (e.g bad Area names/paths) - M
7. Change ProcessTemplate - S
8. Support team areas not having all Sub-Areas assigned - M
9. Test coverage - (using pester) - isolated - XL
10. Test coverage - (using pester) against an actual organization in Azure DevOps Service - M





Projects:
1. Generate a yaml file from a project - or a snippet of part of a project so as not to export the whole project

Repos:
1. Be able to set permissions inheritance at the top level (e.g. Repo default) and/or per repo - this will need a UI-recorded raw API update
2. Expand policy types and settings as these
3. Be able to do some changes as post-creation updates (although)

# JSON-schema based YAML Validation #
This would be fairly quick to implement - there is no implementableYAML schema approach but YAML is convertible to JSON so JSON Schema can be used.
Steps
1. Convert the yaml file to JSON - *Get-Content <path. to yaml> | ConvertFrom-Yaml | ConvertTo-Json -Depth 100 | Out-File <json path>
2. Use a JSON schema generation tool (several online) to infer the schema from the JSON
3. Amend the JSON schema with the bits it couldn't infer (enums, formats etc)
4. In the module after loading the yaml convert to json (in memory, no need to save to file) and use the Test-Json cmdlet to ensure it adheres to the schema. Only thing will be, as with many of these tools the error messages may not be as helpful as you'd like but it's a start.