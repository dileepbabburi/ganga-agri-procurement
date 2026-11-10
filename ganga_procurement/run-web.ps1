$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolRoot = Join-Path (Split-Path -Parent $projectRoot) '.tools'
$env:Path = "$(Join-Path $toolRoot 'git\cmd');$(Join-Path $toolRoot 'flutter\bin');$env:Path"
Set-Location $projectRoot
& (Join-Path $toolRoot 'flutter\bin\flutter.bat') run -d chrome
