
function New-InvokeBuildModuleBuilder {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  [OutputType([InvokeBuildModuleBuilder])]
  param()

  [ProxyGit]$proxyGit = build-ProxyGit;
  [string]$NullBuilderRootPath = $null;
  [InvokeBuildModuleBuilder]$builder = [InvokeBuildModuleBuilder]::new(
    $proxyGit, $NullBuilderRootPath
  );
  $builder.Init();

  return $builder;
}
