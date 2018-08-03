<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
    [Parameter(Mandatory=$True)][string]$subscriptionId,
    [Parameter(Mandatory=$True)][string]$resourceGroupName,
    [Parameter(Mandatory=$True)][string]$resourceGroupLocation,
    [Parameter(Mandatory=$True)][string]$deploymentName,
    [Parameter(Mandatory=$True)][ValidateScript({Test-Path $_ -PathType 'Leaf'})][string]$templateFilePath,
    [Parameter(Mandatory=$True)][ValidateScript({Test-Path $_ -PathType 'Leaf'})][string]$parametersFilePath
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )
    Write-Output "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}
$ErrorActionPreference = "Stop"
# Load parameters
$params = ConvertFrom-Json -InputObject (Get-Content $parametersFilePath -Raw)
# sign in
Write-Output "Logging in...";
$Cred = Import-Clixml -Path .\autoadmin.xml;
Login-AzureRmAccount -Credential $Cred;
# select subscription
Write-Output "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;
# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network","microsoft.storage");
if($resourceProviders.length) {
    Write-Output "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}
#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Output "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = $params.parameters.location.value;
    }
    Write-Output "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Output "Using existing resource group '$resourceGroupName'";
}
# validate the template file
$Test = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -ErrorAction SilentlyContinue;
if($Test){
    Write-Error -Message "Deployment template has errors, aborting the deployment: $($Test.Message)"
}
else{
    # Start the deployment
    Write-Output "Starting deployment...";
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose;
}
#.\deploy.ps1 -subscriptionId '07d6806b-5745-4a24-a0a5-78abf8ac63e1' -resourceGroupName 'rgtwo' -resourceGroupLocation 'South India' -deploymentName 'rgtwo' -templateFilePath .\template.json -parametersFilePath .\parameters.json -Verbose