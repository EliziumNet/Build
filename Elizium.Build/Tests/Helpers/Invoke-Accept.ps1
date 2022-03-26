function invoke-accept {
  param(
    [Parameter()]
    [PSCustomObject]$Info
  )
  [string]$label = $(Get-PsObjectField -Object $Info -Field 'Label');
  [boolean]$doSkip = $false;

  $skip = $(Get-PsObjectField -Object $Info -Field 'Skip');
  if ($skip) {
    $doSkip = $true;
    [string]$message = $($skip -is [string]) ? $skip : "No reason";
    Write-Host "  ⛔ Skip Test: '$($message)'";
  }

  [boolean]$accept = if ([string]::IsNullOrEmpty($env:tag)) {
    -not($doSkip);
  }
  elseif (-not([string]::IsNullOrEmpty($label)) -and $env:tag -eq $label) {
    Write-Host "  💚 Labelled Test: '$($label)'";
    $true
  }
  else {
    Write-Host "  ⚠️ Test Bypassed";
    $false;
  }

  return $accept;
}
