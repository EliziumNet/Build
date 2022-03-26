using namespace System.IO;

# IMPORTANT-NOTE:
#
# The 2 functions Repair-Using and Get-UsingParseInfo are cloned
# into the the build script and the build.tasks file delivered to
# clients. This is because the functions are defined in this build
# build module, but at build time they are not defined, so they needed
# to be cloned in. One might think that you could just source the files
# but doing so would mean a diversion of the build.build script from
# the clients' build tasks file. The cloning is the lesser of 2 evils.
#

Describe 'Repair-Using' {
  BeforeAll {
    Get-Module Elizium.Build | Remove-Module -Force;
    Import-Module .\Output\Elizium.Build\Elizium.Build.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;

    [string]$script:RootPath = [Path]::Join("Tests", "Data", "Modules");
  }

  Context "<Skip>, <Tag>" {
    Context "given: source module at <PsModule>" {
      It "should: return corrected using <Namespaces>/<Modules> statements(s)" -TestCases @(
        @{
          PsModule   = "WithSingleInvalidNsStmt";
          Namespaces = @("System.IO");
        }

        , @{
          PsModule = "WithSingleInvalidModStmt";
          Modules  = @("Elizium.Loopz");
        }

        , @{
          PsModule   = "WithDuplicateNsStmts";
          Namespaces = @("System.IO");
        }

        , @{
          PsModule = "WithDuplicateModStmts";
          Modules  = @("Elizium.Loopz");
        }

        , @{
          PsModule   = "WithNsStmtsOnSameLine";
          Namespaces = @("System.IO", "System.Text");
        }

        , @{
          PsModule   = "WithNsAndModStmts";
          Namespaces = @("System.IO");
          Modules    = @("Elizium.Loopz");
        }

        , @{
          PsModule = "WithCommentedOutUsingStmt";
        }
      ) {

        function assert-using {
          [CmdletBinding()]
          param(
            [Parameter()]
            [object]$Content,

            [Parameter()]
            [ValidateSet("namespace", "module")]
            [string]$Entity,

            [Parameter()]
            [string]$Syntax
          )
          [string]$options = "IgnoreCase, MultiLine";
          [string]$pattern = "using $Entity $Syntax";
          [regex]$rexo = [regex]::new($pattern, $options);
          $rexo.IsMatch($Actual.Content) | Should -BeTrue;
          [System.Text.RegularExpressions.MatchCollection]$mc = $rexo.Matches($Content);
          $mc.Count | Should -Be 1 -Because $(
            "should be a single match for 'using $Entity $Syntax', but found: $($mc.Count)"
          )
        }

        function invoke-assert {
          [CmdletBinding()]
          param(
            [Parameter()]
            [PSCustomObject]$Actual,
    
            [Parameter()]
            [PSCustomObject]$Expected
          )
          $Actual.IsOk | Should -BeTrue;

          if ($Expected.Namespaces) {
            $Expected.Namespaces | ForEach-Object {
              [string]$namespace = $_;
              assert-using -Content $Actual.Content -Entity "namespace" -Syntax $namespace;
            }  
          }

          if ($Expected.Modules) {
            $Expected.Modules | ForEach-Object {
              [string]$module = $_;
              assert-using -Content $Actual.Content -Entity "module" -Syntax $module;
            }
          }
        }

        [PSCustomObject]$testInfo = [PSCustomObject]@{
          Skip  = $Skip;
          Label = $Label;
        }
        
        if (invoke-accept -Info $testInfo) {
          [string]$sourcePath = [Path]::Join($script:RootPath, "$($PsModule).psm1");
          [string]$repairedPath = [Path]::Join($TestDrive, "$($PsModule).repaired.psm1");

          [PSCustomObject]$parsedSource = Get-UsingParseInfo -Path $sourcePath -WithContent;
          [PSCustomObject]$repaired = Repair-Using -ParseInfo $parsedSource;

          Set-Content -LiteralPath $repairedPath -Value $repaired.Content;
          [PSCustomObject]$parsedRepaired = Get-UsingParseInfo -Path $repairedPath -WithContent;

          [PSCustomObject]$expected = [PSCustomObject]@{
            Namespaces = $Namespaces;
            Modules    = $Modules;
          }

          invoke-assert -Actual $parsedRepaired -Expected $expected;
        }
      }
    }  
  }
}
