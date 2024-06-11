Import-Module -Name VMware.VimAutomation.Core
#Import-Module $PSScriptRoot/Machine-utils.psm1

function New-TemplateVM {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Name,
        [Parameter(ValueFromPipeline=$true, Mandatory=$false)][bool]$StartVM = $false
    )

    if (-not(Test-Path $Template)) {
        return @{"Operation" = "Failed"; "Message" = "The provided VMTemplate does not exist."};
    };

    $myTemplate = Get-Content $Template | ConvertFrom-Json -AsHashtable
    Set-PowerCLIConfiguration -Scope User `
        -ParticipateInCeip:$false `
        -Confirm:$false `
        -InvalidCertificateAction:Ignore `
        -DefaultVIServerMode:Single | Out-Null
    ;

    $server = Connect-VIServer -Server $myTemplate.Host.Address`
        -Protocol:https `
        -User:$myTemplate.Host.Username `
        -Password:$myTemplate.Host.Password
    ;

    if ($server.IsConnected) {
        $VMExists = Get-VM -Name $Name -ErrorAction:SilentlyContinue;
        if ($VMExists) {
            return @{"Operation" = "Failed"; "Message" = "A VM With the same name already exists."};
            Exit;
        }

        $VMTemplate = $myTemplate.Client.Direct;
        $New_VM = New-VM @VMTemplate -Name $Name;
        if ($New_VM) {
            #Initialize-CDDrive -VM $New_VM -ISO $myTemplate.Client.CDDrive.ISO -Datastore $myTemplate.Client.CDDrive.Datastore;

            $startresult = @{"Started" = $false; "result" = ""};
            if ($StartVM) {
                #$startresult.result = Start-VM -VM $New_VM
            }
            else {
                $startresult.result = @{}
            }
        } else {
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            return @{"Operation" = "Failed"; "Message" = "Failed creating vm."; "Details" = @{ "Actions" = @{"StartResult" = $startresult} }};
        }
        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
        return @{"Operation" = "Success"; "Message" = "The VM was created successfully."; "Details" = @{ "Actions" = @{"StartResult" = $startresult} }};
    }
}
