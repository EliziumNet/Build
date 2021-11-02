
# === [ ProxyGit ] ===========================================================
#
function readHeadDate {
  [OutputType([string])]
  param()
  return $(git log -n 1 --format=%ai) ?? [string]::Empty;
}

function readLogTags {
  [OutputType([array])]
  param()
  return $((git log --tags --simplify-by-decoration --pretty="format:%ci %d") -match 'tag:') ?? @();
}

function readLogRange {
  [OutputType([array])]
  param(
    [Parameter()]
    [string]$range,

    [Parameter()]
    [string]$format
  )
  return $((git log $range --format=$format) ?? @());
}

function readRemote {
  [OutputType([string])]
  param()
  return $((git remote get-url origin) -replace '\.git$') ?? [string]::Empty;
}

function readRoot {
  [OutputType([string])]
  param()
  return $(git rev-parse --show-toplevel) ?? [string]::Empty;
}

class ProxyGit {
  ProxyGit() {}

  # All these are designed to be overridden by tests
  #
  [scriptblock]$ReadHeadDate = $function:readHeadDate;
  [scriptblock]$ReadLogTags = $function:readLogTags;
  [scriptblock]$ReadLogRange = $function:readLogRange;
  [scriptblock]$ReadRemote = $function:readRemote;
  [scriptblock]$ReadRoot = $function:readRoot;

  [string] HeadDate() {
    return $this.ReadHeadDate.InvokeReturnAsIs();
  }

  [array] LogTags() {
    return $this.ReadLogTags.InvokeReturnAsIs();
  }

  [array] LogRange([string]$range, [string]$format) {
    return $this.ReadLogRange.InvokeReturnAsIs($range, $format);
  }

  [string] Remote() {
    return $this.ReadRemote.InvokeReturnAsIs();
  }

  [string] Root() {
    return $this.ReadRoot.InvokeReturnAsIs();
  }
}

# === [ ModuleBuilder ] ======================================================
#
class ModuleBuilder {
  [string]$Parent;

  # REPO
  #
  [string]$RepoName;
  [string]$ModuleName;
  [string]$RepoScriptName;
  [string]$RepoScriptFileName;
  [string]$ModuleRootPath;
  [string]$RepoBuildScriptFilePath;
  [string]$OverridesFileName;
  [string]$OverridesFilePath;
  [PSCustomObject]$Overrides;

  # BUILDER (Build)
  #
  [string]$BuilderRootPath;
  [string]$BuilderScriptFileName = "Elizium.Build.tasks.ps1";
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

  hidden [int]$_depth = 4;

  ModuleBuilder([object]$proxy, [string]$builderRootPath) {
    $this.Proxy = $proxy;

    $this.BuilderRootPath = [string]::IsNullOrEmpty($builderRootPath) `
      ? $PSScriptRoot : $builderRootPath;
  }

  [void] Init() {
    [string]$repoRootPath = $this.Proxy.Root();
    $this.RepoName = Split-Path -Path $repoRootPath -Leaf;
    $this.OverridesFileName = "$($this.RepoName).overrides.json";

    $this.OverridesFilePath = $(
      Join-Path -Path $repoRootPath -ChildPath $this.OverridesFileName
    );
    $this.Overrides = $this.ReadOverrides();

    $this.Parent = ($this.Overrides)?.Parent ?? 'Elizium';
    $this.ModuleName = "$($this.Parent).$($this.RepoName)";

    $this.RepoScriptName = ($this.Overrides)?.RepoScriptName ?? $($this.ModuleName + '.build');
    $this.RepoScriptFileName = $($this.RepoScriptName + '.ps1');
    $this.ModuleRootPath = $(Join-Path -Path $repoRootPath -ChildPath $this.ModuleName);
    $this.RepoBuildScriptFilePath = $(
      Join-Path -Path $this.ModuleRootPath -ChildPath $this.RepoScriptFileName;
    );
    $this.BuilderScriptFilePath = $(
      Join-Path -Path $this.BuilderRootPath -ChildPath $this.BuilderScriptFileName
    );
  }

  [PSCustomObject] ReadOverrides() {
    [PSCustomObject]$result = if ($this.TestOverridesFileExists()) {
      [string]$json = Get-Content -LiteralPath $this.OverridesFilePath;
      $json | ConvertFrom-Json -Depth $this._depth;
    }
    else {
      $null;
    }
    return $result;
  }

  [boolean] EjectOverrides() {
    [string]$content = $([PSCustomObject]@{} | ConvertTo-Json -Depth $this._depth);

    [boolean]$result = if (-not($this.TestOverridesFileExists())) {
      Set-Content -LiteralPath $this.OverridesFilePath -Value $content;
      $true;
    }
    else {
      $false;
    }
    return $result;
  }

  [boolean] TestBuildScriptExists() {
    return Test-Path -Path $this.RepoBuildScriptFilePath -PathType Leaf;
  }

  [boolean] TestOverridesFileExists() {
    return Test-Path -Path $this.OverridesFilePath -PathType Leaf;
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
  InvokeBuildModuleBuilder([object]$proxy, [string]$builderRootPath) : base($proxy, $builderRootPath) {

  }

  [void] Build ([string[]]$task) {
    $null = $task.Count -eq 0 ? $(Invoke-Build) : $(Invoke-Build -Task $task);
  }
}
