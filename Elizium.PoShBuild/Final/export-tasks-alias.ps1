
Set-Alias -Name 'PoShBuild.tasks' -Value $(
  Join-Path -Path $PSScriptRoot -ChildPath 'Elizium.PoShBuild.tasks.ps1'
);

Export-ModuleMember -Alias 'PoShBuild.tasks';
