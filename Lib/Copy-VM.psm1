Import-Module -Name VMware.VimAutomation.Core

function Copy-TemplateVM {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
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
        $CloneVM = Get-VM -Name $myTemplate.Client.CloneSource.Name -ErrorAction:SilentlyContinue;
        if (!$CloneVM) {
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            return @{"Operation" = "Failed"; "Message" = "Cannot clone a vm that does not exist."};
            Exit;
        }
        $VM = Get-VM $myTemplate.Client.Direct.Name -ErrorAction:SilentlyContinue;
        if ($VM) {
            return @{"Operation" = "Failed"; "Message" = "Cannot create a machine that already exists."};
            Exit;
        }

        $VMTemplate = $myTemplate.Client.Direct;
        $SourceSnapshot = Get-Snapshot -VM $CloneVM -Name "Clone Ready";

        $New_VM = New-VM @VMTemplate -LinkedClone -ReferenceSnapshot $SourceSnapshot -VM $CloneVM -VMHost $CloneVM.VMHost -ResourcePool $CloneVM.ResourcePool;
        if ($New_VM) {

            $startresult = @{"Started" = $false; "result" = ""};
            if ($StartVM) {
                $startresult.result = = Start-VM -VM $New_VM
            }
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            return @{"Operation" = "Sucess"; "Message" = "The VM was created sucessfully."; "Details" = @{ "Actions" = @{"StartResult" = $startresult} }};
        } else {
            Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
            return @{"Operation" = "Failed"; "Message" = "Failed creating vm. $New_VM"; "Details" = @{ "Actions" = @{"StartResult" = $startresult} }};
        }
        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
    }
}