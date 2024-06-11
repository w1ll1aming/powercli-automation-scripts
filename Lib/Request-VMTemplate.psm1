Import-Module -Name VMware.VimAutomation.Core

function Format-Template($template, $map) {
    foreach ($key in $map.Keys) {
        $template = $template.Replace($key, $map[$key]);
    }

    return $template;
}

function Request-VMTemplate {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$Template,
        [Parameter(ValueFromPipeline=$true, Mandatory=$false)][Object[]]$bannedProperties = $null
    )

    $myTemplate = Get-Content $Template | ConvertFrom-Json
    $vmhardware = @{"Host" = $myTemplate.Host; "Client" = @{};}

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
        Write-Host "Connected to: $($server.Name):$($server.Port)"

        $machine = Get-VM -Name $myTemplate.Client.Name;
        $properties = $myTemplate.Config.Backup.Properties;

        if ($null -eq $bannedProperties) {
            $bannedProperties = @(
                "ExtensionData",
                "Folder",
                "VMResourceConfiguration",
                "ResourcePool",
                "VMHost",
                "CustomFields",
                "DatastoreIdList",
                "PowerState",
                "Uid",
                "Id",
                "PersistentId",
                "VMHostId",
                "GuestId",
                "FolderId",
                "CreateDate",
                "UsedSpaceGB",
                "Guest"
            );
        }

        $i = 0;
        $machine.PSOBject.Properties | ForEach-Object {
            if (!$bannedProperties.Contains($_.Name)) {
                if (!$myTemplate.Config.Backup.BackupAll) {
                    if ($properties[$i] -eq $_.Name) {
                        if ($null -ne $_.Value) { $vmhardware["Client"][$_.Name] = $_.Value.toString(); } 
                        else { $vmhardware["Client"][$_.Name] = $_.Value; }
                    }
                } else {
                    if ($null -ne $_.Value) { $vmhardware["Client"][$_.Name] = $_.Value.toString(); } 
                    else { $vmhardware["Client"][$_.Name] = $_.Value; }
                }
            };
            $i++;
        }
        Remove-Variable i;

        $TemplateFormatMap = @{
            "%current-dir%" = $(Get-Location).Path;
            "%vm-name%" = $machine.Name;
        };

        $file = Format-Template -Template $myTemplate.Config.Output.File ` -Map $TemplateFormatMap;
        $directory = Format-Template -Template $myTemplate.Config.Output.Directory -Map $TemplateFormatMap;

        $fullpath = "$($directory)\$($file)"

        Set-Content `
            -Path $fullpath `
            -Value ($vmhardware | ConvertTo-Json -Depth 100 -Compress:$false)
        ;

        Write-Host "Created File: $($fullpath)."
        Disconnect-VIServer -Server $myTemplate.Host.Address -Confirm:$false -Force | Out-Null
    }
}