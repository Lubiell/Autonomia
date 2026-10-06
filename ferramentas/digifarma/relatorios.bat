@echo off
rem Relatorios do Digifarma (so leem o banco, nunca alteram nada).
rem Deixe este arquivo na mesma pasta do relatorios-digifarma.ps1.
rem Se o banco for outro, ajuste a linha abaixo.
setlocal
set "BANCO=localhost:C:\Digifarma\Dados\Digifarma6.FDB"
set "PROGRAMA=%~dp0relatorios-digifarma.ps1"

if not exist "%PROGRAMA%" (
  echo Nao achei "%PROGRAMA%".
  echo Coloque este .bat na mesma pasta do relatorios-digifarma.ps1.
  pause
  exit /b 1
)

:menu
cls
echo.
echo   RELATORIOS DO DIGIFARMA (so leitura, nao altera nada)
echo   Banco: %BANCO%
echo.
echo   1 - Gerar o MAPA DO BANCO (so nomes de tabelas e colunas, sem dados)
echo       Leva alguns minutos. Depois mande o arquivo na conversa.
echo   2 - Sair
echo.
choice /c 12 /n /m "  Digite a opcao (1 ou 2): "
if errorlevel 2 goto fim
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROGRAMA%" -Banco "%BANCO%" -Mapa -ContarLinhas
echo.
pause
goto menu

:fim
endlocal
