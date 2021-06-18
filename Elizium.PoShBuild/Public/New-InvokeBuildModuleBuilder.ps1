
function New-InvokeBuildModuleBuilder {
  [OutputType([InvokeBuildModuleBuilder])]
  param()

  [ProxyGit]$proxyGit = New-ProxyGit;
  [InvokeBuildModuleBuilder]$builder = [InvokeBuildModuleBuilder]::new(
    $proxyGit
  );
  $builder.Init();

  return $builder;
}
