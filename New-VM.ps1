param (
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Name
)

Import-Module $PSScriptRoot/Lib/New-VM.psm1

$VirtualMachine = New-TemplateVM -Template $PSScriptRoot/$Template -Name $Name | ConvertTo-Json -Depth 4
$VirtualMachine;