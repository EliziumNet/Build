
class ModuleBuilder {
  # REPO
  #
  [string]$RepoName;
  [string]$ModuleName;
  [string]$RepoScriptName;
  [string]$RepoScriptFileName;
  [string]$ModuleRootPath;
  [string]$RepoBuildScriptFilePath;

  # BUILDER (PoShBuild)
  #
  [string]$BuilderRootPath = $PSScriptRoot;
  [string]$BuilderScriptFileName = 'Elizium.PoShBuild.tasks.ps1';
  [string]$BuilderScriptFilePath;
  [object]$Proxy;

  [scriptblock]$GetModifiedDate = [scriptblock] {
    [OutputType([DateTime])]
    param(
      [Parameter()]
      [ValidateSet('Builder', 'Client')]
      [string]$ScriptInstance,

      [Parameter()]
      [ModuleBuilder]$Builder
    )
    [string]$scriptPath = ($ScriptInstance -eq 'Builder') ? `
      $Builder.BuilderScriptFilePath : $Builder.RepoBuildScriptFilePath;

    return $(Get-Item -LiteralPath $scriptPath).LastWriteTime;
  }

  ModuleBuilder([object]$proxy) {
    $this.Proxy = $proxy;
  }

  [void] Init() {
    [string]$repoRootPath = $this.Proxy.Root();

    $this.RepoName = Split-Path -Path $repoRootPath -Leaf;
    $this.ModuleName = $('Elizium.' + $this.RepoName);
    $this.RepoScriptName = $($this.ModuleName + '.build');
    $this.RepoScriptFileName = $($this.RepoScriptName + '.ps1');
    $this.ModuleRootPath = $(Join-Path -Path $repoRootPath -ChildPath $this.ModuleName);
    $this.RepoBuildScriptFilePath = $(
      Join-Path -Path $this.ModuleRootPath -ChildPath $this.RepoScriptFileName;
    );
    $this.BuilderScriptFilePath = $(
      Join-Path -Path $this.BuilderRootPath -ChildPath $this.BuilderScriptFileName
    );
  }

  [boolean] TestBuildScriptExists() {
    return Test-Path -Path $this.RepoBuildScriptFilePath -PathType Leaf;
  }

  [void] ImportScript ([boolean]$force) {
    if ($this.TestBuildScriptExists() -and -not($force)) {
      [DateTime]$localDate = $this.GetModifiedDate.InvokeReturnAsIs(
        'Client', $this
      );

      [DateTime]$sourceDate = $this.GetModifiedDate.InvokeReturnAsIs(
        'Builder', $this
      );

      if ($sourceDate.Ticks -gt $localDate.Ticks) {
        $this.AcquireScript($force);
      }
    }
    else {
      $this.AcquireScript($force);
    }
  }

  [void] AcquireScript ([boolean]$force) {
    Copy-Item -LiteralPath $this.BuilderScriptFilePath `
      -Destination $this.RepoBuildScriptFilePath -Force:$force;
  }

  [PSCustomObject] Query ([string]$instance) {

    [PSCustomObject]$status = if (@('Builder', 'Client') -contains $instance) {
      [string]$scriptPath, [string]$hash = switch ($instance) {
        'Builder' {
          @(
            $this.BuilderScriptFilePath,
            $(Get-FileHash -Path $this.BuilderScriptFilePath -Algorithm SHA256).Hash;
          );
          break;
        }

        'Client' {
          @(
            $this.RepoBuildScriptFilePath,
            $(Get-FileHash -Path $this.RepoBuildScriptFilePath -Algorithm SHA256).Hash;
          );
          break;
        }
      }

      [PSCustomObject]@{
        Path  = $scriptPath;
        Hash  = $hash;
        Short = $hash.SubString(0, 7);
        Date  = $this.GetModifiedDate.InvokeReturnAsIs(
          $instance, $this
        );
      }
    }
    else {
      throw [System.Management.Automation.MethodInvocationException]::new(
        "Invalid '$instance' specified (ModuleBuilder.Query)");
    }

    return $status;
  }

  [void] Build () {
    throw [System.Management.Automation.MethodInvocationException]::new(
      'Abstract method not implemented (ModuleBuilder.Build)');
  }
}

class InvokeBuildModuleBuilder : ModuleBuilder {
  InvokeBuildModuleBuilder([object]$proxy) : base($proxy) {

  }

  [void] Build ([string[]]$task) {
    $null = $task.Count -eq 0 ? $(Invoke-Build) : $(Invoke-Build -Task $task);
  }
}