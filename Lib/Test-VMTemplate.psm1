# TODO: This function is currently not working.
function Test-VMTemplate {
    Param (
        [parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Pass in template to test.")][PSCustomObject]$Template
    )

    $requiredKeys = @{
        "Host"=@("Address", "Username", "Password");
        "Client"=@("Name", "VMHost")
    };
    foreach ($requiredKey in $requiredKeys.Keys) {
        if ($Template.psobject.properties.match($requiredKey).Count -lt 1) { return ($false, $requiredKey); }
        foreach ($subKeyRequired in $requiredKeys[$requiredKey]) {
            if ($Template[$requiredKey].psobject.properties.match($subKeyRequired) -lt 1) { return ($false, $requiredKey); }
        }
    }
}