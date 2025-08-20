param(
  [switch]$Fix,
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Ensure we run from repo root (folder that has pubspec.yaml)
if (-not (Test-Path .\pubspec.yaml)) {
  Write-Host "This does not look like the repo root. Please 'cd' to the folder with pubspec.yaml." -ForegroundColor Yellow
  exit 1
}

# Collect Dart files
$targets = @()
$targets += Get-ChildItem -Path .\lib -Include *.dart -Recurse -ErrorAction SilentlyContinue
if (Test-Path .\test) {
  $targets += Get-ChildItem -Path .\test -Include *.dart -Recurse -ErrorAction SilentlyContinue
}

if (-not $targets) {
  Write-Host "No Dart files found under lib/ (and test/ if present)." -ForegroundColor Yellow
  exit 0
}

$pattern = "package:aevara_master"
$replacement = "package:aevara_app"

$hits = @()
foreach ($f in $targets) {
  $text = Get-Content -Path $f.FullName -Raw -Encoding UTF8
  if ($text -match $pattern) {
    $hits += $f.FullName
    Write-Host "Hit: $($f.FullName)" -ForegroundColor Cyan

    if ($Fix -and -not $WhatIf) {
      $bak = "$($f.FullName).bak"
      if (-not (Test-Path $bak)) { Copy-Item $f.FullName $bak }
      $new = $text -replace $pattern, $replacement
      Set-Content -Path $f.FullName -Value $new -Encoding UTF8
      Write-Host "  -> replaced to $replacement" -ForegroundColor Green
    }
  }
}

if (-not $hits) {
  Write-Host "✅ No files contain '$pattern'." -ForegroundColor Green
} elseif ($WhatIf) {
  Write-Host "`nDRY RUN ONLY. Re-run with -Fix to apply replacements." -ForegroundColor Yellow
} else {
  Write-Host "`nDone. Replacements applied to $($hits.Count) file(s)." -ForegroundColor Green
  Write-Host "Backups saved as *.bak next to changed files."
}
