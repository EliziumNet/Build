
function New-InvokeBuildModuleBuilder {
  [OutputType([InvokeBuildModuleBuilder])]
  param()

  [ProxyGit]$proxyGit = New-ProxyGit;
  [string]$NullBuilderRootPath = $null;
  [InvokeBuildModuleBuilder]$builder = [InvokeBuildModuleBuilder]::new(
    $proxyGit, $NullBuilderRootPath
  );
  $builder.Init();

  return $builder;
}
