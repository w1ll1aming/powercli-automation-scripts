function New-VMTemplate {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, HelpMessage="")][string]$OutputFile,
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, HelpMessage="")][Hashtable]$Content
    )

    $Content | ConvertTo-Json | Out-File $OutputFile;
}