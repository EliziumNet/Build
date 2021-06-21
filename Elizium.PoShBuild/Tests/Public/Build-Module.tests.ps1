using module Elizium.Klassy;

Describe 'Build-Module' {
  BeforeAll {
    Get-Module Elizium.PoShBuild | Remove-Module -Force;
    Import-Module .\Output\Elizium.PoShBuild\Elizium.PoShBuild.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;
  }

  Context 'given: blah' {
    It 'should: ' {
      InModuleScope Elizium.PoShBuild {
        # Build-Module
      }
    }
  }
}
