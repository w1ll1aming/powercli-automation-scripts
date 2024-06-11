Import-Module -Name VMware.VimAutomation.Core

function Start-TemplateVM {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Name
    )

    Set-PowerCLIConfiguration -Scope User `
        -ParticipateInCeip:$false `
        -Confirm:$false `
        -InvalidCertificateAction:Ignore `
        -DefaultVIServerMode:Single | Out-Null
    ;

    if (-not(Test-Path $Template)) {
        return @{"Operation" = "Failed"; "Error" = "The provided VMTemplate does not exist."};
    };
    $myTemplate = Get-Content $Template | ConvertFrom-Json -AsHashtable

    $server = Connect-VIServer -Server $myTemplate.Host.Address`
        -Protocol:https `
        -User:$myTemplate.Host.Username `
        -Password:$myTemplate.Host.Password
    ;

    if ($server.IsConnected) {
        $machine = Get-VM -Name $Name -ErrorAction:SilentlyContinue;
        if (!$machine) {
            return @{"Operation" = "Failed"; "Message" = "No VM With the specified name exists."};
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            Exit;
        }
        if ($machine.PowerState -eq "PoweredOff") {
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            return @{"Operation" = "Failed"; "Error" = "The machine is already powered off."};
        }
        $result = Stop-VM -VM $machine -Confirm:$false;

        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
        # If you want to include the result returned by PowerCLI to the API then change '@{}' to '$result' at the end of the 'Result' json.
        return @{"Operation" = "Success"; "Message" = "The VM was stopped successfully."; "Details" = @{ "Machine" = @{"Result" = @{}} }};
    }
}