<#
.SYNOPSIS
    Deploy the VMSS using ARM

.PARAMETER ResourceGroup
    The name of the resource group to deploy the VMSS to

.PARAMETER AdminPassword
    The password to use for the admin account on the VMSS
#>
param (
    [string]
    $ResourceGroup,

    [securestring]
    $AdminPassword
)

./build-placeholders.ps1

New-AzResourceGroupDeployment -Name "manual-$(Get-Date -Format "MMdd-hhmmss")" -ResourceGroupName $ResourceGroup -TemplateFile .\vmss.template.json -TemplateParameterFile .\vmss.parameters.generated.json -adminPassword $AdminPassword -Verbose
