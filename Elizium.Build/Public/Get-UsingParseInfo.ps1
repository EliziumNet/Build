
function Get-UsingParseInfo {
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string]$Path,

    [Parameter()]
    [string]$Pattern = $("\s*using (?<syntax>namespace|module)\s+(?<name>[\w\.]+);?"),

    [Parameter()]
    [switch]$WithContent
  )
  [regex]$rexo = [regex]::new($Pattern, "IgnoreCase, MultiLine");
  [array]$records = Invoke-ScriptAnalyzer -Path $Path | Where-Object {
    $_.RuleName -eq "UsingMustBeAtStartOfScript"
  };

  [PSCustomObject]$result = [PSCustomObject]@{
    Records = $records;
    IsOk    = $records.Count -eq 0;
    Rexo    = $rexo;
  }

  if ($WithContent.IsPresent) {
    $result | Add-Member -MemberType NoteProperty -Name "Content" -Value $(
      Get-Content -LiteralPath $Path -Raw;
    )
  }

  return $result;
}
