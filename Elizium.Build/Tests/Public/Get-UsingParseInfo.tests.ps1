using namespace System.IO;

Describe 'Get-UsingParseInfo' {
  BeforeAll {
    Get-Module Elizium.Build | Remove-Module -Force;
    Import-Module .\Output\Elizium.Build\Elizium.Build.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;

    [string]$script:RootPath = [Path]::Join("Tests", "Data", "Modules");
  }

  Context "<Skip>, <Tag>" {
    Context "given: source module at <PsModule>" {
      It "should: return Diagnostic Record as <Expected>" -TestCases @(
        @{
          PsModule = "WithoutUsingStmt";
          Expected = @{
            IsOk = $true;
          }
        }

        , @{
          PsModule = "WithSingleInvalidNsStmt";
          Expected = @{
            IsOk = $false;
          }
        }

        , @{
          PsModule = "WithSingleInvalidModStmt";
          Expected = @{
            IsOk = $false;
          }
        }
      ) {
        function invoke-assert {
          param(
            [Parameter()]
            [PSCustomObject]$Actual,
    
            [Parameter()]
            [PSCustomObject]$Expected
          )
          $Actual.IsOk | Should -Be $Expected.IsOk;
        }

        [PSCustomObject]$testInfo = [PSCustomObject]@{
          Skip  = $Skip;
          Label = $Label;
        }
        
        if (invoke-accept -Info $testInfo) {
          [string]$modulePath = [Path]::Join($script:RootPath, "$($PsModule).psm1");
          [PSCustomObject]$actual = Get-UsingParseInfo -Path $modulePath;
    
          invoke-assert -Actual $actual -Expected $Expected;
        }
      }
    }  
  }
}
