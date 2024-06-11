param (
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Name
)

Import-Module $PSScriptRoot/Lib/Stop-VM.psm1

$State = Start-TemplateVM -Template $PSScriptRoot/$Template -Name $Name | ConvertTo-Json -Depth 4
$State;