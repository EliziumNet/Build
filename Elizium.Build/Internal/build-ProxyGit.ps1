
function build-ProxyGit {
  [OutputType([ProxyGit])]
  param(
    [Parameter()]
    [hashtable]$Overrides = @{}
  )
  [ProxyGit]$proxy = [ProxyGit]::new();

  if ($Overrides.Count -gt 0) {
    [array]$members = ($proxy | Get-Member -MemberType Property).Name;

    $Overrides.PSBase.Keys | ForEach-Object {
      [string]$name = $_;

      if ($members -contains $name) {
        $proxy.$name = $Overrides[$name];
      }
      else {
        throw [System.Management.Automation.MethodInvocationException]::new(
          "'$name' does not exist on Proxy"
        );
      }
    }

  }

  return $proxy;
}
