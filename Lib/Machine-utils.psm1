function Initialize-CDDrive {
    Param (
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Pass in the VM here.")][VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VM,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Pass a datastore name. Formatted like this: '[Your_Datastore]'")][string]$Datastore,
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Pass a path to an ISO file on the previously passed datastore.")][string]$ISO,
        [parameter(valuefrompipeline = $true, mandatory = $false, HelpMessage = "Connect the cd drive at power on.")][bool]$StartConnected = $true
    )

    $ISOFullPath = "$($Datastore) $($ISO)";
    $CDDrives = Get-CDDrive -VM $VM;
    if ($null -ne $CDDrives) {
        $CDDrives | Set-CDDrive -ISOPath $ISOFullPath `
            -Confirm:$false `
            -StartConnected:$StartConnected | Out-Null
        ;
    } else {
        New-CDDrive -VM $VM `
            -ISOPath $ISOFullPath `
            -Confirm:$false `
            -StartConnected:$StartConnected | Out-Null
        ;
    }
}