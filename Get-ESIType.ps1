[CmdletBinding()]

Param(
  [Parameter(Mandatory=$true)]$TypeID,
  [Switch] $Singularity=$false
)

if($Singularity) { 
  $DataSource = "singularity" 
} else { 
  $DataSource = "tranquility" 
}

$DataUri = 'https://esi.evetech.net/latest/universe/types/{0}/?datasource={1}&language=en-us' -f $TypeID, $DataSource
$DogmaAttributeUri = 'https://esi.evetech.net/latest/dogma/attributes/{0}' + '/?datasource={0}' -f $DataSource
$DogmaEffectUri = 'https://esi.evetech.net/latest/dogma/effects/{0}' + '/?datasource={0}' -f $DataSource

$DogmaAttributesFile = '.\DogmaAttributes-{0}.json' -f $DataSource
$DogmaEffectsFile = '.\DogmaEffects-{0}.json' -f $DataSource

$Response = Invoke-WebRequest -Uri $DataUri
$JSONObject = $Response.Content | ConvertFrom-Json

$ObjectDogmaAttributes = @()
$ObjectDogmaEffects = @()

# Look for files
try {
    $AttributesData = Get-Content -Path $DogmaAttributesFile -ErrorAction Stop | ConvertFrom-Json
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Verbose -Message ('File {0} was not found' -f $DogmaAttributesFile)
    $AttributesData = @()
}

try {
    $EffectsData = Get-Content -Path $DogmaEffectsFile -ErrorAction Stop | ConvertFrom-Json
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Verbose -Message ('File {0} was not found' -f $DogmaEffectsFile)
    $EffectsData = @()
}

# Get Missing Data and dump files
$JSONObject.dogma_attributes | % { 
  if($AttributesData.attribute_id -NotContains $_.attribute_id) {
    Write-Verbose -Message ('Updating Attribute: {0}' -f $_.attribute_id)    
    $AttributesData += (Invoke-WebRequest -Uri ($DogmaAttributeUri -f $_.attribute_id)).Content | ConvertFrom-Json
  }
  $Attribute = $AttributesData | ? attribute_id -eq $_.attribute_id
  $ObjectDogmaAttributes += [pscustomobject]@{
    Name = $Attribute.name
    Value = $_.value
    Description = $Attribute.description
  }
}

$JSONObject.dogma_effects | % { 
  if($EffectsData.effect_id -NotContains $_.effect_id) {
    Write-Verbose -Message ('Updating Effect: {0}' -f $_.effect_id)
    $EffectsData += (Invoke-WebRequest -Uri ($DogmaEffectUri -f $_.effect_id)).Content | ConvertFrom-Json
  }
  $Effect = $EffectsData | ? effect_id -eq $_.effect_id
  $ObjectDogmaEffects += [pscustomobject]@{
    Name = $Effect.name
    Value = $_.value
    Description = $Effect.description
  }
}

#Dump Files
Write-Verbose -Message ('Writing File {0}' -f $DogmaAttributesFile)   
$AttributesData | ConvertTo-Json | Out-File -FilePath $DogmaAttributesFile
Write-Verbose -Message ('Writing File {0}' -f $DogmaEffectsFile)   
$EffectsData | ConvertTo-Json | Out-File -FilePath $DogmaEffectsFile

Write-Verbose -Message 'Building final object'
$JSONObject.PSObject.Properties.Remove('dogma_attributes')
$JSONObject.PSObject.Properties.Remove('dogma_effects')
$JSONObject | Add-Member -MemberType NoteProperty -Name 'dogma_attributes' -Value ($ObjectDogmaAttributes | Sort-Object -Property Name)
$JSONObject | Add-Member -MemberType NoteProperty -Name 'dogma_effects' -Value ($ObjectDogmaEffects | Sort-Object -Property Name)

$JSONObject
