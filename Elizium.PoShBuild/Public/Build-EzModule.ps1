
function Build-EzModule {
  <#
  .NAME
    Build-EzModule

  .SYNOPSIS
    Builds client module with a common build script.

  .DESCRIPTION
    This function relieves the stress and overhead of having the build script managed
  independently in client modules repo's. Instead, the client repo can import the build
  script from here, PoShBuild meaning that any changes to the core build script are
  easily replicated to clients.

  .LINK
    https://github.com/EliziumNet/PoShBuild

  .PARAMETER Task
    Build script task(s) to invoke

  .PARAMETER Import
    switch to indicate build script should be imported

  .PARAMETER Force
    switch to indicated force copying of build script (overwrite existing script)

  .PARAMETER Query
    switch to indicate running query of build script status

  .PARAMETER Eject
    switch to indicate dummy overrides file is to be created in the required location
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
  [CmdletBinding(DefaultParameterSetName = 'RunBuild')]
  [Alias('bumo')]
  param(
    [Parameter(ParameterSetName = 'RunBuild')]
    [string[]]$Task = @(),

    [Parameter(Mandatory, ParameterSetName = 'RunImport')]
    [switch]$Import,

    [Parameter(ParameterSetName = 'RunImport')]
    [switch]$Force,

    [Parameter(ParameterSetName = 'QueryScriptStatus')]
    [switch]$Query,

    [Parameter(ParameterSetName = 'EjectOverrides')]
    [switch]$Eject
  )
  [hashtable]$colours = @{
    'Ok'       = 'Green';
    'Destruct' = 'Red';
    'Error'    = 'DarkRed';
    'Info'     = 'Cyan';
    'Instruct' = 'Magenta';
  }

  [InvokeBuildModuleBuilder]$builder = New-InvokeBuildModuleBuilder;

  if ($PSCmdlet.ParameterSetName -eq 'RunBuild') {
    $builder.Build($Task);
  }
  elseif ($PSCmdlet.ParameterSetName -eq 'RunImport') {
    Write-Verbose $("Importing build script $($Force ? 'with force': [string]::Empty) ...");
    Write-Verbose $("===> from: '$($builder.BuilderScriptFilePath)'");
    Write-Verbose $("===>   to: '$($builder.RepoBuildScriptFilePath)'");

    $builder.ImportScript($Force.IsPresent);

    if (-not(Test-Path -Path $builder.RepoBuildScriptFilePath)) {
      # Should never happen
      #
      Write-Error "Failed to import build script: '$($builder.RepoBuildScriptFilePath)'";
    }
  }
  elseif ($PSCmdlet.ParameterSetName -eq 'QueryScriptStatus') {
    [PSCustomObject]$builderResult = $builder.Query('Builder');
    
    if ($builder.TestBuildScriptExists()) {
      [PSCustomObject]$clientResult = $builder.Query('Client');

      if ($builderResult.Date.Ticks -ge $clientResult.Date.Ticks) {
        Write-Host $(
          "Build script '$($builder.RepoScriptFileName)' " +
          "[repo:$($clientResult.Short), build: $($builderResult.Short)]" +
          " IS present in repo and up to date."
        ) -ForegroundColor $colours['Info'];
      }
      else {
        Write-Host $(
          "Build script '$($builder.RepoScriptFileName)' " +
          "[repo:$($clientResult.Short), build: $($builderResult.Short)]" +
          " IS present in repo, but stale, please run the import (with Force if necessary)."
        ) -ForegroundColor $colours['Info'];
      }
    }
    else {
      Write-Host $(
        "Build script '$($builder.RepoScriptFileName)' " +
        "[build: $($builderResult.Short)] " +
        "not present in repo, please run the import."
      ) -ForegroundColor $colours['Instruct'];
    }

    if ($builder.TestBuildScriptExists() -and $builder.Overrides) {
      Write-Host "Overrides present at: '$($builder.OverridesFilePath)'" -ForegroundColor $colours['Ok'];
      [PSCustomObject]$overrides = $builder.Overrides;

      [array]$items = $($overrides.psobject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" });
      [string]$message = "Overridden items: '$($items -join ', ')'";
      Write-Host $message -ForegroundColor $colours['Destruct'];
    }
    else {
      Write-Host "No overrides present at: '$($builder.OverridesFilePath)'" -ForegroundColor $colours['Ok'];
    }
  }
  elseif ($PSCmdlet.ParameterSetName -eq 'EjectOverrides') {
    [boolean]$ejected = $builder.EjectOverrides();

    if ($ejected) {
      Write-Host "Ejected Overrides to: '$($builder.OverridesFilePath)'" -ForegroundColor  $colours['Ok'];
    }
    else {
      Write-Host "Overrides already present at: '$($builder.OverridesFilePath)', skipped!" -ForegroundColor  $colours['Error'];
    }
  }
}
