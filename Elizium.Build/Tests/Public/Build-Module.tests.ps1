using namespace System.IO;

Describe 'Build-Module' {
  BeforeAll {
    Get-Module Elizium.Build | Remove-Module -Force;
    Import-Module .\Output\Elizium.Build\Elizium.Build.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;
  }

  Context 'given: module and client task script' {
    It 'should: ensure they are in sync' {
      [string]$builder = "Elizium.Build.build.ps1";
      [string]$client = [Path]::Join(
        "FileList", "Elizium.Build.tasks.ps1"
      );
      $builderHash = (Get-FileHash -Path $builder -Algorithm SHA256).Hash;
      $clientHash = (Get-FileHash -Path $client -Algorithm SHA256).Hash;

      $builderHash | Should -BeExactly $clientHash -Because $(
        "Builder and client scripts must be in sync, but are not."
      );
    }
  }
}
