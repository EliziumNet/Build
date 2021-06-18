using module Elizium.Klassy;

Describe 'ModuleBuilder' {
  BeforeAll {
    Get-Module Elizium.PoShBuild | Remove-Module -Force;
    Import-Module .\Output\Elizium.PoShBuild\Elizium.PoShBuild.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;

    InModuleScope Elizium.PoShBuild {
      [string]$script:_client = 'Willow';

      function script:Deploy-DummyBuildScript {
        param(
          [Parameter()]
          [string]$DirectoryPath,

          [Parameter()]
          [string]$ScriptFileName,

          [Parameter()]
          [string]$Content
        )
        if (-not(Test-Path -Path $DirectoryPath)) {
          New-Item -Path $DirectoryPath -ItemType Directory;
        }
        [string]$scriptPath = $(Join-Path $DirectoryPath -ChildPath $ScriptFileName);
        Set-Content -LiteralPath $scriptPath -Value $Content;
      }
    }
  }

  BeforeEach {
    InModuleScope Elizium.PoShBuild {
      [string]$script:_repoRootPath = Join-Path -Path $TestDrive -ChildPath $_client;
      [string]$script:_builderRootPath = Join-Path -Path $TestDrive -ChildPath 'BuilderRoot';

      [hashtable]$overrides = @{
        'ReadRoot' = [scriptblock] {
          return $script:_repoRootPath;
        }
      }
      [ProxyGit]$proxyGit = New-ProxyGit -Overrides $overrides;
      [ModuleBuilder]$script:_builder = [InvokeBuildModuleBuilder]::new(
        $proxyGit
      );

      # Overriding BuilderRootPath is only required in unit tests as the default is
      # the install location of the builder module which is PSScriptRoot.
      #
      $_builder.BuilderRootPath = $_builderRootPath;
      $_builder.Init();

      # Ensure that the repo module exists. This doesn't have to been done by the
      # builder, because in reality, the repo file structure is already there.
      #
      if (-not(Test-Path -Path $_builder.ModuleRootPath -PathType Container)) {
        $null = New-Item -Path $_builder.ModuleRootPath -ItemType Directory;
      }
    }
  }

  Context 'InvokeBuildModuleBuilder.ctor' {
    It 'should: set member properties correctly' {
      InModuleScope Elizium.PoShBuild {
        # REPO
        #
        $_builder.RepoName | Should -BeExactly $_client;
        $_builder.ModuleName | Should -BeExactly "Elizium.$_client";
        $_builder.RepoScriptName | Should -BeExactly "Elizium.$($_client).build";
        $_builder.RepoScriptFileName | Should -BeExactly "Elizium.$($_client).build.ps1";
        [string]$expectedModuleRootPath = $(
          Join-Path -Path $_repoRootPath -ChildPath $_builder.ModuleName
        );
        $_builder.ModuleRootPath | Should -BeExactly $expectedModuleRootPath;

        [string]$expectedScriptPath = $(
          Join-Path -Path $_builder.ModuleRootPath -ChildPath "Elizium.$($_client).build.ps1"
        );
        $_builder.RepoBuildScriptFilePath | Should -BeExactly $expectedScriptPath;

        # BUILDER
        #
        [string]$expectedBuilderScriptFilePath = $(
          Join-Path -Path $_builderRootPath -ChildPath $_builder.BuilderScriptFileName
        );
        $_builder.BuilderScriptFilePath | Should -BeExactly $expectedBuilderScriptFilePath;
      }
    }
  }

  Describe 'TestBuildScriptExists' {
    Context 'given: build script not present' {
      It 'should: return $false' {
        InModuleScope Elizium.PoShBuild {
          $_builder.TestBuildScriptExists() | Should -BeFalse;
        }
      }
    }

    Context 'given: build script IS present' {
      It 'should: return $true' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
            -ScriptFileName $_builder.RepoScriptFileName -Content 'DUMMY-CONTENT';

          $_builder.TestBuildScriptExists() | Should -BeTrue;
        }
      }
    }
  } # TestBuildScriptExists

  Describe 'ImportScript' {
    Context 'given: Repo does NOT contain the build script' {
      It 'should: copy the build script into the repo' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'DUMMY-CONTENT';

          $_builder.ImportScript($false);
          Test-Path -Path $_builder.RepoBuildScriptFilePath -PathType Leaf | Should -BeTrue;
        }
      }
    }

    Context 'given: Repo contains up to date build script' {
      It 'should: NOT copy the build script into the repo' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
            -ScriptFileName $_builder.RepoScriptFileName -Content 'CLIENT-REPO-CONTENT';

          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'BUILDER-CONTENT';

          $_builder.GetModifiedDate = [scriptblock] {
            [OutputType([DateTime])]
            param(
              [Parameter()]
              [ValidateSet('Builder', 'Client')]
              [string]$ScriptInstance,

              [Parameter()]
              [ModuleBuilder]$Builder
            )
            # Return the same date for client and builder
            #
            return [DateTime]::new(2021, 5, 3);
          }
          $_builder.ImportScript($false);

          Test-Path -Path $_builder.RepoBuildScriptFilePath -PathType Leaf | Should -BeTrue;
          Get-Content -Path $_builder.RepoBuildScriptFilePath | Should -BeExactly 'CLIENT-REPO-CONTENT';
        }
      }
    }

    Context 'given: Repo contains stale build script' {
      It 'should: NOT copy the build script into the repo' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
            -ScriptFileName $_builder.RepoScriptFileName -Content 'STALE-CONTENT';

          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'BUILDER-CONTENT';

          $_builder.GetModifiedDate = [scriptblock] {
            [OutputType([DateTime])]
            param(
              [Parameter()]
              [ValidateSet('Builder', 'Client')]
              [string]$ScriptInstance,

              [Parameter()]
              [ModuleBuilder]$Builder
            )
            # Return an older date for the client
            #
            return $ScriptInstance -eq 'Client' ? [DateTime]::new(2021, 5, 3) : [DateTime]::new(2021, 6, 3);
          }
          $_builder.ImportScript($false);

          Test-Path -Path $_builder.RepoBuildScriptFilePath -PathType Leaf | Should -BeTrue;
          Get-Content -Path $_builder.RepoBuildScriptFilePath | Should -BeExactly 'BUILDER-CONTENT';
        }
      }

      Context 'and: force' {
        It 'should: copy the build script into the repo' {
          InModuleScope Elizium.PoShBuild {
            Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
              -ScriptFileName $_builder.RepoScriptFileName -Content 'FORKED-RECENT-CONTENT';

            Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
              -ScriptFileName $_builder.BuilderScriptFileName -Content 'BUILDER-CONTENT';

            $_builder.GetModifiedDate = [scriptblock] {
              [OutputType([DateTime])]
              param(
                [Parameter()]
                [ValidateSet('Builder', 'Client')]
                [string]$ScriptInstance,

                [Parameter()]
                [ModuleBuilder]$Builder
              )
              # Return a newer date for the client. This scenario covers the case where the user
              # has tweaked the local build script so it has a more recent modified date, but
              # the version of the build script is newer than the base version of the repo. In this
              # case, the user should use the force option knowing that their local changes will
              # be discarded. (NB: local changes to build script is highly discouraged).
              #
              return $ScriptInstance -eq 'Client' ? [DateTime]::new(2021, 6, 3) : [DateTime]::new(2021, 5, 3);
            }
            $_builder.ImportScript($true);

            Test-Path -Path $_builder.RepoBuildScriptFilePath -PathType Leaf | Should -BeTrue;
            Get-Content -Path $_builder.RepoBuildScriptFilePath | Should -BeExactly 'BUILDER-CONTENT';
          }
        }
      }
    }
  } # ImportScript

  Describe 'Query' {
    Context 'given: Repo does NOT contain the build script' {
      It 'should: resolve query' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'DUMMY-CONTENT';

          [PSCustomObject]$builderResult = $_builder.Query('Builder');
          $builderResult | Should -Not -BeNullOrEmpty;
        }
      }
    }

    Context 'given: Repo contains up to date build script' {
      It 'should: resolve query' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
            -ScriptFileName $_builder.RepoScriptFileName -Content 'DUMMY-CONTENT';

          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'DUMMY-CONTENT';

          [PSCustomObject]$clientResult = $_builder.Query('Client');
          [PSCustomObject]$builderResult = $_builder.Query('Builder');

          $clientResult.Hash | Should -BeExactly $builderResult.Hash;
        }
      }
    }

    Context 'given: Repo contains stale build script' {
      It 'should: resolve query' {
        InModuleScope Elizium.PoShBuild {
          Deploy-DummyBuildScript -DirectoryPath $_builder.ModuleRootPath `
            -ScriptFileName $_builder.RepoScriptFileName -Content 'STALE-CONTENT';

          Deploy-DummyBuildScript -DirectoryPath $_builder.BuilderRootPath `
            -ScriptFileName $_builder.BuilderScriptFileName -Content 'BUILDER-CONTENT';

          [PSCustomObject]$clientResult = $_builder.Query('Client');
          [PSCustomObject]$builderResult = $_builder.Query('Builder');

          $clientResult.Hash | Should -Not -BeExactly $builderResult.Hash;
        }
      }
    }
  }
}
