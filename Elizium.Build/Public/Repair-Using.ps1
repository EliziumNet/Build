
function Repair-Using {
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$ParseInfo
  )
  [System.Text.RegularExpressions.MatchCollection]$mc = $ParseInfo.Rexo.Matches(
    $ParseInfo.Content
  );

  $withoutUsingStatements = $ParseInfo.Rexo.Replace($ParseInfo.Content, [string]::Empty);

  [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new();

  [string[]]$statements = $(foreach ($m in $mc) {
      [System.Text.RegularExpressions.GroupCollection]$groups = $m.Groups;
      [string]$syntax = $groups["syntax"];
      [string]$name = $groups["name"];

      "using $syntax $name;";
    }) | Select-Object -unique;

  $statements | ForEach-Object {
    $builder.AppendLine($_);
  }
  $builder.Append($withoutUsingStatements);

  return [PSCustomObject]@{
    Content = $builder.ToString();
  }
}
