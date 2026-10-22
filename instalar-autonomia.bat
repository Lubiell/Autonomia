@echo off
rem Instala ou atualiza o Autonomia no Claude Code deste PC (pasta %USERPROFILE%\.claude).
rem Baixa a versao mais nova do GitHub e roda o install.ps1. Pode rodar de novo para atualizar.
setlocal
if not defined AUTONOMIA_ZIP set "AUTONOMIA_ZIP=https://github.com/Lubiell/Autonomia/archive/refs/heads/main.zip"
echo Baixando o Autonomia...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$d = Join-Path $env:TEMP 'autonomia-instalar';" ^
  "if (Test-Path $d) { Remove-Item $d -Recurse -Force };" ^
  "New-Item -ItemType Directory $d | Out-Null;" ^
  "$z = Join-Path $d 'autonomia.zip';" ^
  "Invoke-WebRequest $env:AUTONOMIA_ZIP -OutFile $z -UseBasicParsing;" ^
  "Expand-Archive $z $d -Force;" ^
  "$src = Get-ChildItem $d -Directory | Select-Object -First 1;" ^
  "& (Join-Path $src.FullName 'install.ps1')"
if errorlevel 1 (
  echo.
  echo FALHOU. Confira a internet e rode de novo; se repetir, mande a mensagem acima para o Claude.
  if not defined AUTONOMIA_SEM_PAUSA pause
  exit /b 1
)
echo.
echo Pronto. Feche e abra o Claude Code de novo para carregar o Autonomia.
if not defined AUTONOMIA_SEM_PAUSA pause
exit /b 0
