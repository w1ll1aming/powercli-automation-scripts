Import-Module -Name VMware.VimAutomation.Core

Import-Module -Name VMware.VimAutomation.Core

function Get-TemplateVM {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template
    )

    Set-PowerCLIConfiguration -Scope User `
        -ParticipateInCeip:$false `
        -Confirm:$false `
        -InvalidCertificateAction:Ignore `
        -DefaultVIServerMode:Single | Out-Null
    ;

    if (-not(Test-Path $Template)) {
        return @{"Operation" = "Failed"; "Message" = "The provided VMTemplate does not exist."};
    };
    $myTemplate = Get-Content $Template | ConvertFrom-Json -AsHashtable

    $server = Connect-VIServer -Server $myTemplate.Host.Address`
        -Protocol:https `
        -User:$myTemplate.Host.Username `
        -Password:$myTemplate.Host.Password
    ;

    if ($server.IsConnected) {
        $VM = Get-VM -Name $myTemplate.Client.Direct.Name -ErrorAction:SilentlyContinue;

        if (!$VM) {
            return @{"Operation" = "Failed"; "Message" = "No VM With the specified name exists."};
            Exit;
        }

        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
        return $VM;
    }
}

function Get-VMs {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template
    )

    Set-PowerCLIConfiguration -Scope User `
        -ParticipateInCeip:$false `
        -Confirm:$false `
        -InvalidCertificateAction:Ignore `
        -DefaultVIServerMode:Single | Out-Null
    ;

    if (-not(Test-Path $Template)) {
        return @{"Operation" = "Failed"; "Message" = "The provided VMTemplate does not exist."};
    };

    $myTemplate = Get-Content $Template | ConvertFrom-Json -AsHashtable

    $server = Connect-VIServer -Server $myTemplate.Host.Address`
        -Protocol:https `
        -User:$myTemplate.Host.Username `
        -Password:$myTemplate.Host.Password
    ;

    if ($server.IsConnected) {
        $VMs = Get-VM;

        $VMs = $VMs | Select-Object Name, PowerState, NumCpu, MemoryGB;

        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
        return $VMs;
    }
}