#!/usr/bin/env python3
"""Monta o Digifarma.bat: um arquivo só, com o menu de todas as ferramentas e, guardados no fim dele,
os programas (desmarcar-controlados.ps1, relatorios-digifarma.ps1 e Relatorios.bas). Ao abrir, o .bat
recria esses programas na própria pasta (só regrava o que mudou) e mostra o menu.

Uso:
  python3 montar-digifarma-bat.py             regrava o Digifarma.bat a partir dos programas desta pasta
  python3 montar-digifarma-bat.py --conferir  só confere se o Digifarma.bat está em dia (código 1 se não)
"""
import os
import sys

PASTA = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.join(PASTA, 'Digifarma.bat')
# (nome, codificação do arquivo na pasta)
PROGRAMAS = [
    ('desmarcar-controlados.ps1', 'utf-8-sig'),
    ('relatorios-digifarma.ps1', 'utf-8-sig'),
    ('Relatorios.bas', 'cp1252'),
]

# Parte que o cmd executa: só ASCII. Termina em "exit /b", antes dos programas guardados.
MENU = r'''@echo off
rem DIGIFARMA - todas as ferramentas num arquivo so.
rem Ao abrir, este .bat cria (ou atualiza) nesta mesma pasta os programas guardados no fim dele:
rem   desmarcar-controlados.ps1, relatorios-digifarma.ps1 e Relatorios.bas (macro do Excel).
rem Os registros e os relatorios gerados tambem ficam nesta pasta (subpasta "registros").
rem Se o banco ou a coluna de estoque forem outros, ajuste as duas linhas "set" abaixo.
rem (Arquivo gerado por montar-digifarma-bat.py.)
setlocal
set "BANCO=localhost:C:\Digifarma\Dados\Digifarma6.FDB"
set "ESTOQUE=-Estoque ComEstoque -CampoEstoque PROD_SALDO"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass"
set "DESMARCAR=%~dp0desmarcar-controlados.ps1"
set "RELATORIOS=%~dp0relatorios-digifarma.ps1"

set "DF_BAT=%~f0"
%PS% -Command "$t = [IO.File]::ReadAllText($env:DF_BAT); $i = $t.IndexOf('#EXTRATOR' + '-INICIO'); $j = $t.IndexOf('#EXTRATOR' + '-FIM'); if ($i -lt 0 -or $j -lt $i) { exit 3 }; Invoke-Expression $t.Substring($i, $j - $i)"
if errorlevel 1 (
  echo.
  echo   Nao consegui criar os programas na pasta "%~dp0".
  echo   Coloque este .bat numa pasta onde voce possa gravar, por exemplo C:\Ferramentas\Digifarma
  pause
  exit /b 1
)

:DF_menu
cls
echo.
echo   DIGIFARMA - FERRAMENTAS
echo   Banco: %BANCO%
echo.
echo   CONTROLADOS (altera o banco; faz backup antes)
echo     1 - Somente VER os controlados com estoque (simulacao, NAO altera nada)
echo     2 - DESMARCAR: na janela, clique nos produtos (Ctrl+clique para varios),
echo         clique OK e depois digite DESMARCAR aqui
echo     3 - Desfazer a ultima vez que desmarcou
echo.
echo   RELATORIOS (so leem o banco, nunca alteram nada)
echo     4 - Abrir a janela de relatorios (Curva ABC, Sugestao de compra e os demais, com datas)
echo     5 - Lotes vencendo (vencidos nos ultimos 30 dias e que vencem nos proximos 90)
echo     6 - Estoque negativo
echo     7 - Conferencia SNGPC (controlados: estoque x lotes)
echo     8 - Gerar o MAPA DO BANCO (mande o arquivo na conversa)
echo.
echo   PLANILHA DE COTACAO
echo     9 - Como colocar os relatorios dentro da planilha (macro do Excel)
echo.
echo     0 - Sair
echo.
choice /c 1234567890 /n /m "  Digite a opcao (0 a 9): "
if errorlevel 10 goto DF_fim
if errorlevel 9 goto DF_planilha
if errorlevel 8 goto DF_mapa
if errorlevel 7 goto DF_sngpc
if errorlevel 6 goto DF_negativo
if errorlevel 5 goto DF_lotes
if errorlevel 4 goto DF_janela
if errorlevel 3 goto DF_desfazer
if errorlevel 2 goto DF_aplicar
goto DF_simular

:DF_simular
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" %ESTOQUE% -Escolher
goto DF_pausa

:DF_aplicar
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" %ESTOQUE% -Escolher -Aplicar
goto DF_pausa

:DF_desfazer
set "ULTIMO="
for /f "delims=" %%d in ('dir /b /ad /o-n "%~dp0registros" 2^>nul') do if not defined ULTIMO if exist "%~dp0registros\%%d\desfazer.sql" set "ULTIMO=%~dp0registros\%%d\desfazer.sql"
if not defined ULTIMO (
  echo.
  echo   Nenhuma alteracao para desfazer em "%~dp0registros".
  goto DF_pausa
)
echo.
echo   Vai remarcar o que foi desmarcado nesta execucao:
echo   %ULTIMO%
choice /c SN /m "  Confirma"
if errorlevel 2 goto DF_menu
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" -Desfazer "%ULTIMO%"
goto DF_pausa

:DF_janela
echo.
echo   Digite a senha do Firebird; depois a janela abre.
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Janela
if errorlevel 1 pause
goto DF_menu

:DF_lotes
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio LotesVencendo -Abrir
goto DF_pausa

:DF_negativo
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio EstoqueNegativo -Abrir
goto DF_pausa

:DF_sngpc
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio ConferenciaSNGPC -Abrir
goto DF_pausa

:DF_mapa
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Mapa -ContarLinhas
goto DF_pausa

:DF_planilha
cls
echo.
echo   RELATORIOS DENTRO DA PLANILHA DE COTACAO (fazer uma vez so)
echo.
echo   1. Deixe a sua cotacao (Cotacao_Pronta_em_branco.xlsx) nesta pasta:
echo      %~dp0
echo   2. Abra a cotacao no Excel e aperte Alt+F11.
echo   3. Clique em Arquivo, Importar arquivo e escolha Relatorios.bas (desta pasta).
echo      Se ja tinha importado antes: botao direito em Relatorios, Remover, e importe de novo.
echo   4. Feche o editor, aperte Alt+F8, escolha InstalarRelatorios e clique em Executar.
echo   5. Salve como "Pasta de Trabalho Habilitada para Macro do Excel (*.xlsm)".
echo.
echo   Depois e so abrir o .xlsm, clicar em Habilitar conteudo e usar os botoes das abas.
echo.
if not exist "%~dp0Cotacao_Pronta_em_branco.xlsx" goto DF_pausa
choice /c SN /m "  Abrir a cotacao no Excel agora"
if errorlevel 2 goto DF_menu
start "" "%~dp0Cotacao_Pronta_em_branco.xlsx"
goto DF_menu

:DF_pausa
echo.
pause
goto DF_menu

:DF_fim
endlocal
exit /b 0

'''

# Executado pela linha "%PS% -Command" acima: recria os programas guardados abaixo.
EXTRATOR = r'''#EXTRATOR-INICIO
# Recria, na pasta deste .bat, os programas guardados no fim dele. Só regrava o que mudou.
$ErrorActionPreference = 'Stop'
$bat = $env:DF_BAT
$pasta = Split-Path -Parent $bat
$utf8Bom = New-Object Text.UTF8Encoding $true
$ansi = [Text.Encoding]::GetEncoding(1252)
$nome = $null
$linhas = New-Object Collections.Generic.List[string]
foreach ($l in [IO.File]::ReadAllLines($bat)) {
    if ($null -eq $nome) {
        if ($l.StartsWith('#ARQUIVO-INICIO ')) { $nome = $l.Substring(16).Trim(); $linhas.Clear() }
        continue
    }
    if ($l -ceq '#ARQUIVO-FIM') {
        $texto = ($linhas -join "`r`n") + "`r`n"
        if ($nome.EndsWith('.bas')) { $enc = $ansi } else { $enc = $utf8Bom }
        $destino = Join-Path $pasta $nome
        $atual = $null
        if (Test-Path -LiteralPath $destino) { $atual = [IO.File]::ReadAllText($destino, $enc) }
        if ($atual -cne $texto) {
            [IO.File]::WriteAllText($destino, $texto, $enc)
            Write-Host "  Atualizado: $nome"
        }
        $nome = $null
        continue
    }
    $linhas.Add($l)
}
#EXTRATOR-FIM
'''


def montar():
    assert MENU.isascii(), 'a parte executada pelo cmd tem de ser ASCII'
    partes = [MENU, EXTRATOR]
    for nome, codificacao in PROGRAMAS:
        with open(os.path.join(PASTA, nome), encoding=codificacao, newline='') as f:
            texto = f.read().replace('\r\n', '\n')
        for n, linha in enumerate(texto.split('\n'), 1):
            # Linha começando com ":" seria confundida com rótulo pelo cmd; os marcadores, com o fim do arquivo.
            if linha.lstrip().startswith(':') or linha.startswith(('#ARQUIVO-', '#EXTRATOR-')):
                sys.exit(f'{nome}:{n}: linha que atrapalha o .bat: {linha!r}')
        if not texto.endswith('\n'):
            texto += '\n'
        partes.append(f'#ARQUIVO-INICIO {nome}\n{texto}#ARQUIVO-FIM\n')
    return ''.join(partes)


def main():
    novo = montar()
    if '--conferir' in sys.argv[1:]:
        try:
            with open(SAIDA, encoding='utf-8', newline='') as f:
                atual = f.read().replace('\r\n', '\n')
        except FileNotFoundError:
            atual = None
        if atual != novo:
            sys.exit('Digifarma.bat desatualizado: rode python3 montar-digifarma-bat.py')
        print('Digifarma.bat em dia')
        return
    # UTF-8 sem BOM (o BOM quebraria a primeira linha do cmd) e CRLF em tudo.
    with open(SAIDA, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(novo)
    print(f'gravado {SAIDA}')


if __name__ == '__main__':
    main()
