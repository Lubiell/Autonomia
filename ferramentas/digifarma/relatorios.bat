@echo off
rem Relatorios do Digifarma (so leem o banco, nunca alteram nada).
rem Deixe na mesma pasta: este .bat, o relatorios-digifarma.ps1 e o Cotacao_Pronta_em_branco.xlsx.
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
echo   1 - Abrir a janela de relatorios (Curva ABC, Sugestao de compra, mapa)
echo   2 - Gerar so o MAPA DO BANCO, sem janela (mande o arquivo na conversa)
echo   3 - Sair
echo.
choice /c 123 /n /m "  Digite a opcao (1 a 3): "
if errorlevel 3 goto fim
if errorlevel 2 goto mapa
echo.
echo   Digite a senha do Firebird; depois a janela abre.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROGRAMA%" -Banco "%BANCO%" -Janela
if errorlevel 1 pause
goto menu

:mapa
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROGRAMA%" -Banco "%BANCO%" -Mapa -ContarLinhas
echo.
pause
goto menu

:fim
endlocal
