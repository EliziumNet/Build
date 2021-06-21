
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
    switch to indicate build script should be imported.

  .PARAMETER Force
    switch to indicated force copying of build script (overwrite existing script)

  .PARAMETER Query
    switch to indicate running query of build script status
  #>
  [CmdletBinding(DefaultParameterSetName = 'RunBuild')]
  [Alias('build-mod')]
  param(
    [Parameter(ParameterSetName = 'RunBuild')]
    [string[]]$Task = @(),

    [Parameter(Mandatory, ParameterSetName = 'RunImport')]
    [switch]$Import,

    [Parameter(ParameterSetName = 'RunImport')]
    [switch]$Force,

    [Parameter(ParameterSetName = 'QueryScriptStatus')]
    [switch]$Query
  )
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
      Write-Error "Failed to import build script: '$($builder.RepoBuildScriptFilePath)'"
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
        );
      }
      else {
        Write-Host $(
          "Build script '$($builder.RepoScriptFileName)' " +
          "[repo:$($clientResult.Short), build: $($builderResult.Short)]" +
          " IS present in repo, but stale, please run the import (with Force if necessary)."
        );
      }
    }
    else {
      Write-Host $(
        "Build script '$($builder.RepoScriptFileName)' " +
        "[build: $($builderResult.Short)]" +
        "not present in repo, please run the import."
      );
    }
  }
}
