
function New-InvokeBuildModuleBuilder {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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
