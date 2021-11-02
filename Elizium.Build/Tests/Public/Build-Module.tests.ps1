
Describe 'Build-Module' {
  BeforeAll {
    Get-Module Elizium.Build | Remove-Module -Force;
    Import-Module .\Output\Elizium.Build\Elizium.Build.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;
  }

  Context 'given: blah' {
    It 'should: ' {
      InModuleScope Elizium.Build {
        # Build-Module
      }
    }
  }
}
