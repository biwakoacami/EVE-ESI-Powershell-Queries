[CmdletBinding()]

Param(
  [Parameter(Mandatory=$true)]
  $TypeID,
  [Switch] $Singularity=$false,
  [Switch] $Refresh=$false
)


if($Singularity) { 
  $DataSource = "singularity" 
} else { 
  $DataSource = "tranquility" 
}

if 

$DataUri = 'https://esi.tech.ccp.is/latest/insurance/prices/?datasource={0}&language=en-us' -f $DataSource
$InsuranceFile = '.\Insurance-{0}.json' -f $DataSource

# Look for files
try {
    $InsuranceData = Get-Content -Path $InsuranceFile -ErrorAction Stop | ConvertFrom-Json
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Verbose -Message ('File {0} was not found' -f $DogmaAttributesFile)
    $InsuranceData = $null
}

if($Refresh -or $null -eq $InsuranceData) {
    Write-Verbose -Message "Refresh was requested. Querying ESI and replacing local file."     
    $Response = Invoke-WebRequest -Uri $DataUri
    $Response.Content | Out-File -FilePath $InsuranceFile -Force
    $InsuranceData = $Response.Content | ConvertFrom-Json
}

$InsuranceData | ? type_id -eq $TypeID | Select -ExpandProperty levels
