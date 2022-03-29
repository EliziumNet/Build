using namespace System.IO;

Describe 'BuildEngine' {
  BeforeAll {
    Get-Module Elizium.Build | Remove-Module -Force;
    Import-Module .\Output\Elizium.Build\Elizium.Build.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;
  }

  BeforeDiscovery {
    InModuleScope Elizium.Build {
      [BuildEngine]$script:_Engine = [BuildEngine]::new([PSCustomObject]@{
          Directory = [PSCustomObject]@{
            Root = "Foo\Elizium.Foo"
          }
        });
    }
  }

  Context "given: client side config object" {
    InModuleScope Elizium.Build {
      It "should: initialise <Item> to <Expected>, because <Reason>" -TestCases @(
        # Module
        #
        @{
          Item     = $script:_Engine.Data.Module.Name;
          Expected = "Elizium.Foo";
          Reason   = "Module.Name";
        }

        , @{
          Item     = $script:_Engine.Data.Module.Out;
          Expected = "Foo\Elizium.Foo\Output\Elizium.Foo\Elizium.Foo";
          Reason   = "Module.Out";
        }

        # Directory
        #
        , @{
          Item     = $script:_Engine.Data.Directory.Admin;
          Expected = "Foo\Elizium.Foo\Admin";
          Reason   = "Directory.Admin";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.CustomModuleNameExclusions;
          Expected = "Foo\Elizium.Foo\Admin\module-name-check-exclusions.csv";
          Reason   = "Directory.CustomModuleNameExclusions";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.Final;
          Expected = "Final";
          Reason   = "Directory.Final";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.FileList;
          Expected = "Foo\Elizium.Foo\FileList";
          Reason   = "Directory.FileList";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.TestHelpers;
          Expected = "Foo\Elizium.Foo\Tests\Helpers";
          Reason   = "Directory.TestHelpers";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.Tests;
          Expected = "Foo\Elizium.Foo\Tests\*";
          Reason   = "Directory.Tests";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.Public;
          Expected = "Public";
          Reason   = "Directory.Public";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.Output;
          Expected = "Foo\Elizium.Foo\Output";
          Reason   = "Directory.Output";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.ModuleOut;
          Expected = "Foo\Elizium.Foo\Output\Elizium.Foo";
          Reason   = "Directory.ModuleOut";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.Root;
          Expected = "Foo\Elizium.Foo";
          Reason   = "Directory.Root";
        }

        , @{
          Item     = $script:_Engine.Data.Directory.ExternalHelp;
          Expected = "Foo\Elizium.Foo\Output\Elizium.Foo\en-GB";
          Reason   = "Directory.ExternalHelp";
        }

        # File
        #
        , @{
          Item     = $script:_Engine.Data.File.AdditionalExports;
          Expected = "Foo\Elizium.Foo\Init\additional-exports.ps1";
          Reason   = "File.AdditionalExports";
        }

        , @{
          Item     = $script:_Engine.Data.File.SourcePsd;
          Expected = "Foo\Elizium.Foo\Elizium.Foo.psd1";
          Reason   = "File.SourcePsd";
        }

        , @{
          Item     = $script:_Engine.Data.File.Stats;
          Expected = "Foo\Elizium.Foo\Output\stats.json";
          Reason   = "File.Stats";
        }
      ) {
        $Item | Should -BeExactly $Expected -Because $Reason;
      }  
    }
  }
}
