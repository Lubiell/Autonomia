Attribute VB_Name = "Relatorios"
' Relatórios do Digifarma dentro da planilha de cotação (Excel).
' Os botões das abas "Curva ABC", "Sugestão de compra", "Lotes vencendo", "Estoque negativo" e
' "Conferência SNGPC" chamam o relatorios-digifarma.ps1, que só lê o banco do Digifarma, esperam o resultado
' e escrevem na aba. A sugestão também preenche PRODUTO e QUANT da aba "Cotação".
' Instalação (uma vez): Alt+F11 > Arquivo > Importar arquivo > Relatorios.bas; depois Alt+F8 >
' InstalarRelatorios > Executar; por fim salve como "Pasta de Trabalho Habilitada para Macro (*.xlsm)".
Option Explicit

Private Const ABA_ABC As String = "Curva ABC"
Private Const ABA_SUG As String = "Sugestão de compra"
Private Const ABA_CFG As String = "Config relatórios"
Private Const ABA_COT As String = "Cotação"
Private Const ABA_LOT As String = "Lotes vencendo"
Private Const ABA_NEG As String = "Estoque negativo"
Private Const ABA_SNG As String = "Conferência SNGPC"
Private Const TXT_SENHA As String = " A senha do Firebird é pedida numa janela preta."
Private Const LINHA_CAB As Long = 8      ' cabeçalho do resultado
Private Const LINHA_DADOS As Long = 9    ' primeira linha do resultado
Private Const COT_PRIMEIRA As Long = 3   ' aba Cotação: PRODUTO e QUANT de A3 a B1002
Private Const COT_ULTIMA As Long = 1002
Private Const BANCO_PADRAO As String = "localhost:C:\Digifarma\Dados\Digifarma6.FDB"

' ---------- instalação: cria as abas, os campos e os botões ----------
Public Sub InstalarRelatorios()
    Dim cfg As Worksheet, abc As Worksheet, sug As Worksheet, banco As String, pasta As String, usuario As String
    Dim lot As Worksheet, neg As Worksheet, sng As Worksheet
    On Error GoTo Falha
    Application.ScreenUpdating = False
    Set sug = PegarOuCriarAba(ABA_SUG, ABA_COT)
    Set abc = PegarOuCriarAba(ABA_ABC, ABA_SUG)
    Set lot = PegarOuCriarAba(ABA_LOT, ABA_ABC)
    Set neg = PegarOuCriarAba(ABA_NEG, ABA_LOT)
    Set sng = PegarOuCriarAba(ABA_SNG, ABA_NEG)
    Set cfg = PegarOuCriarAba(ABA_CFG, "")

    ' Instalar de novo mantém o que já foi configurado.
    banco = Trim$(CStr(cfg.Range("B3").Value))
    pasta = Trim$(CStr(cfg.Range("B4").Value))
    usuario = Trim$(CStr(cfg.Range("B5").Value))
    If banco = "" Then banco = BANCO_PADRAO
    If pasta = "" Then pasta = ThisWorkbook.Path
    If usuario = "" Then usuario = "SYSDBA"
    With cfg
        .Cells.Clear
        .Range("A1").Value = "CONFIGURAÇÃO DOS RELATÓRIOS DO DIGIFARMA"
        .Range("A1").Font.Bold = True
        .Range("A1").Font.Size = 14
        .Range("A3").Value = "Banco do Digifarma:"
        .Range("B3").Value = banco
        .Range("A4").Value = "Pasta do relatorios-digifarma.ps1:"
        .Range("B4").Value = pasta
        .Range("A5").Value = "Usuário do Firebird:"
        .Range("B5").Value = usuario
        .Range("A3:A5").Font.Bold = True
        .Range("B3:B5").Interior.Color = RGB(255, 255, 204)
        .Range("A7").Value = "A senha do Firebird é pedida numa janela preta a cada relatório; ela não fica gravada na planilha."
        .Range("A8").Value = "Os relatórios só leem o banco do Digifarma; nada é alterado nele."
        .Columns("A").ColumnWidth = 34
        .Columns("B").ColumnWidth = 60
    End With
    DefinirNome "CfgBanco", cfg.Range("B3")
    DefinirNome "CfgPasta", cfg.Range("B4")
    DefinirNome "CfgUsuario", cfg.Range("B5")

    MontarAba abc, "CURVA ABC", "Preencha as datas (dd/mm/aaaa) e clique no botão." & TXT_SENHA, _
              "Gerar Curva ABC", "GerarCurvaABC", True, False
    MontarAba sug, "SUGESTÃO DE COMPRA", "Preencha as datas (dd/mm/aaaa) e os dias e clique no botão." & TXT_SENHA, _
              "Gerar sugestão de compra", "GerarSugestaoCompra", True, True
    MontarAba lot, "LOTES VENCENDO", "Lotes com saldo que vencem entre as duas datas; com o início no passado, " & _
              "aparecem também os já vencidos." & TXT_SENHA, "Gerar lotes vencendo", "GerarLotesVencendo", True, False, _
              "Vencimento de:", "Vencimento até:", -30, 90
    MontarAba neg, "ESTOQUE NEGATIVO", "Produtos com estoque abaixo de zero. Clique no botão." & TXT_SENHA, _
              "Gerar estoque negativo", "GerarEstoqueNegativo", False, False
    MontarAba sng, "CONFERÊNCIA SNGPC", "Psicotrópicos e antimicrobianos com estoque diferente da soma dos lotes, " & _
              "estoque negativo, lote vencido com saldo ou lote negativo. Clique no botão." & TXT_SENHA, _
              "Gerar conferência SNGPC", "GerarConferenciaSNGPC", False, False

    Application.ScreenUpdating = True
    abc.Activate
    MsgBox "Pronto: abas """ & ABA_SUG & """, """ & ABA_ABC & """, """ & ABA_LOT & """, """ & ABA_NEG & """, """ & _
           ABA_SNG & """ e """ & ABA_CFG & """ criadas." & vbLf & vbLf & _
           "Agora salve como ""Pasta de Trabalho Habilitada para Macro do Excel (*.xlsm)"".", vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' Cria a aba logo depois de "depoisDe" (ou no fim, se ela não existir).
Private Function PegarOuCriarAba(ByVal nome As String, ByVal depoisDe As String) As Worksheet
    Dim ws As Worksheet, ref As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(nome)
    If Len(depoisDe) > 0 Then Set ref = ThisWorkbook.Worksheets(depoisDe)
    On Error GoTo 0
    If ws Is Nothing Then
        If ref Is Nothing Then Set ref = ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count)
        Set ws = ThisWorkbook.Worksheets.Add(After:=ref)
        ws.Name = nome
    End If
    Set PegarOuCriarAba = ws
End Function

Private Sub DefinirNome(ByVal nome As String, ByVal alvo As Range)
    On Error Resume Next
    ThisWorkbook.Names(nome).Delete
    On Error GoTo 0
    ThisWorkbook.Names.Add Name:=nome, RefersTo:="='" & alvo.Worksheet.Name & "'!" & alvo.Address
End Sub

Private Sub MontarAba(ByVal ws As Worksheet, ByVal titulo As String, ByVal instrucao As String, _
                     ByVal textoBotao As String, ByVal macro As String, ByVal comDatas As Boolean, _
                     ByVal comDias As Boolean, Optional ByVal rotuloIni As String = "Data de início:", _
                     Optional ByVal rotuloFim As String = "Data de fim:", Optional ByVal iniPadrao As Long = -29, _
                     Optional ByVal fimPadrao As Long = 0)
    Dim b As Object, ini As Variant, fim As Variant, dias As Variant
    ' Instalar de novo mantém as datas e os dias já preenchidos e não duplica os botões.
    ini = ws.Range("B3").Value
    fim = ws.Range("B4").Value
    dias = ws.Range("B5").Value
    If Not IsDate(ini) Then ini = Date + iniPadrao
    If Not IsDate(fim) Then fim = Date + fimPadrao
    If VarType(dias) <> vbDouble Then dias = 30
    If ws.Buttons.Count > 0 Then ws.Buttons.Delete
    ws.Cells.Clear
    ws.Range("A1").Value = titulo
    ws.Range("A1").Font.Bold = True
    ws.Range("A1").Font.Size = 14
    ws.Range("A2").Value = instrucao
    ws.Range("A2").Font.Italic = True
    If comDatas Then
        ws.Range("A3").Value = rotuloIni
        ws.Range("B3").Value = ini
        ws.Range("A4").Value = rotuloFim
        ws.Range("B4").Value = fim
        ws.Range("B3:B4").NumberFormat = "dd/mm/yyyy"
        ws.Range("B3:B4").Interior.Color = RGB(255, 255, 204)
    End If
    If comDias Then
        ws.Range("A5").Value = "Dias de estoque desejados:"
        ws.Range("B5").Value = dias
        ws.Range("B5").Interior.Color = RGB(255, 255, 204)
    End If
    ws.Range("A3:A5").Font.Bold = True
    ws.Columns("A").ColumnWidth = 26
    ws.Columns("B").ColumnWidth = 14
    Set b = ws.Buttons.Add(ws.Range("D3").Left, ws.Range("D3").Top, 220, 34)
    b.Placement = xlFreeFloating   ' não estica quando o relatório muda a largura das colunas
    b.OnAction = macro
    b.Caption = textoBotao
    b.Name = "btn" & macro
End Sub

' ---------- Curva ABC ----------
Public Sub GerarCurvaABC()
    Dim ws As Worksheet, ini As Date, fim As Date, arq As String, d As Variant
    Dim n As Long, i As Long, saida() As Variant, total As Double, qa As Long, qb As Long, qc As Long
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_ABC)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    arq = ArquivoTemporario("abc")
    If Not RodarPrograma("CurvaABC", ini, fim, 30, arq) Then Exit Sub
    d = LerTabela(arq)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Classe, Posicao, Codigo, CodBarras, Descricao, Quantidade, Faturamento, Fatia, Acumulado, Estoque
    n = UBound(d, 1) - 1
    ReDim saida(1 To n, 1 To 10)
    For i = 1 To n
        saida(i, 1) = d(i + 1, 1)
        saida(i, 2) = CLng(Val(d(i + 1, 2)))
        saida(i, 3) = d(i + 1, 3)
        saida(i, 4) = d(i + 1, 4)
        saida(i, 5) = d(i + 1, 5)
        saida(i, 6) = Val(d(i + 1, 6))
        saida(i, 7) = Val(d(i + 1, 7))
        saida(i, 8) = Val(d(i + 1, 8))
        saida(i, 9) = Val(d(i + 1, 9))
        saida(i, 10) = Val(d(i + 1, 10))
        total = total + saida(i, 7)
        Select Case saida(i, 1)
            Case "A": qa = qa + 1
            Case "B": qb = qb + 1
            Case Else: qc = qc + 1
        End Select
    Next i

    Application.ScreenUpdating = False
    LimparResultado ws
    EscreverCabecalho ws, Array("Classe", "Posição", "Código", "Código de barras", "Descrição", "Quantidade vendida", _
                                "Faturamento (R$)", "% do faturamento", "% acumulado", "Estoque atual")
    ws.Cells(LINHA_DADOS, 3).Resize(n, 3).NumberFormat = "@"
    ws.Cells(LINHA_DADOS, 1).Resize(n, 10).Value = saida
    ws.Cells(LINHA_DADOS, 7).Resize(n, 1).NumberFormat = "#,##0.00"
    ws.Cells(LINHA_DADOS, 8).Resize(n, 2).NumberFormat = "0.00%"
    ' O arquivo vem na ordem da posição, então as classes ficam em faixas seguidas: A, depois B, depois C.
    If qa > 0 Then ws.Cells(LINHA_DADOS, 1).Resize(qa, 1).Interior.Color = RGB(198, 239, 206)
    If qb > 0 Then ws.Cells(LINHA_DADOS + qa, 1).Resize(qb, 1).Interior.Color = RGB(255, 235, 156)
    If qc > 0 Then ws.Cells(LINHA_DADOS + qa + qb, 1).Resize(qc, 1).Interior.Color = RGB(230, 230, 230)
    ws.Columns("C:D").ColumnWidth = 16
    ws.Columns("E").ColumnWidth = 50
    ws.Columns("F:J").ColumnWidth = 15
    ws.Range("A6").Value = "Período: " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                           "   |   Produtos: " & n & "   |   Faturamento: R$ " & Format$(total, "#,##0.00") & _
                           "   |   A: " & qa & "   B: " & qb & "   C: " & qc
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox "Curva ABC pronta: " & n & " produtos (A: " & qa & ", B: " & qb & ", C: " & qc & ").", vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Sugestão de compra ----------
Public Sub GerarSugestaoCompra()
    Dim ws As Worksheet, ini As Date, fim As Date, dias As Long, arq As String, d As Variant
    Dim n As Long, i As Long, saida() As Variant, fora As Long, naCotacao As Long, msg As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_SUG)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    If Not IsNumeric(ws.Range("B5").Value) Then
        MsgBox "Preencha em B5 quantos dias de estoque comprar (de 1 a 365).", vbExclamation, "Relatórios do Digifarma"
        Exit Sub
    End If
    dias = CLng(ws.Range("B5").Value)
    If dias < 1 Or dias > 365 Then
        MsgBox "Os dias de estoque (B5) devem ser de 1 a 365.", vbExclamation, "Relatórios do Digifarma"
        Exit Sub
    End If
    arq = ArquivoTemporario("sugestao")
    If Not RodarPrograma("SugestaoCompra", ini, fim, dias, arq) Then Exit Sub
    d = LerTabela(arq)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Quantidade, MediaDia, Estoque, Comprar, NaCotacao
    n = UBound(d, 1) - 1
    ReDim saida(1 To n, 1 To 7)
    For i = 1 To n
        saida(i, 1) = d(i + 1, 1)
        saida(i, 2) = d(i + 1, 2)
        saida(i, 3) = d(i + 1, 3)
        saida(i, 4) = Val(d(i + 1, 4))
        saida(i, 5) = Val(d(i + 1, 5))
        saida(i, 6) = Val(d(i + 1, 6))
        saida(i, 7) = CLng(Val(d(i + 1, 7)))
        If d(i + 1, 8) <> "1" Then fora = fora + 1
    Next i

    Application.ScreenUpdating = False
    LimparResultado ws
    EscreverCabecalho ws, Array("Código", "Código de barras", "Descrição", "Vendido no período", "Média por dia", _
                                "Estoque atual", "Comprar (para " & dias & " dias)")
    ws.Cells(LINHA_DADOS, 1).Resize(n, 3).NumberFormat = "@"
    ws.Cells(LINHA_DADOS, 1).Resize(n, 7).Value = saida
    ws.Cells(LINHA_DADOS, 5).Resize(n, 1).NumberFormat = "0.00"
    ws.Cells(LINHA_DADOS, 7).Resize(n, 1).Font.Bold = True
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 50
    ws.Columns("D:G").ColumnWidth = 16
    ws.Range("A6").Value = "Período: " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                           "   |   Produtos para comprar: " & n & "   |   Estoque para " & dias & " dias"
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True

    naCotacao = PreencherCotacao(d, n)
    msg = "Sugestão de compra pronta: " & n & " produtos."
    Select Case naCotacao
        Case -2: msg = msg & vbLf & "Não achei a aba """ & ABA_COT & """ nesta planilha."
        Case -1: msg = msg & vbLf & "A aba """ & ABA_COT & """ não foi alterada."
        Case Else: msg = msg & vbLf & "A aba """ & ABA_COT & """ foi preenchida com " & naCotacao & " produtos (PRODUTO e QUANT)."
    End Select
    If fora > 0 And naCotacao >= 0 Then msg = msg & vbLf & fora & " produtos não couberam na Cotação (ela tem 1000 linhas); eles estão só nesta aba."
    ws.Activate
    MsgBox msg, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' Preenche PRODUTO (nome - código de barras) e QUANT da aba Cotação. Devolve quantos produtos escreveu,
' -1 se o usuário não quis substituir o que já estava lá, -2 se a aba não existe.
Private Function PreencherCotacao(d As Variant, ByVal n As Long) As Long
    Dim wc As Worksheet, protegida As Boolean, prod() As Variant, k As Long, i As Long, nome As String
    Dim usadas As Long, numErro As Long, descErro As String
    On Error Resume Next
    Set wc = ThisWorkbook.Worksheets(ABA_COT)
    On Error GoTo 0
    If wc Is Nothing Then
        PreencherCotacao = -2
        Exit Function
    End If
    ' Colunas digitadas à mão: A-B (produto, quant), E-P (preços), R (desempate), S-AD (condições).
    ' C, D e Q são fórmulas e ficam como estão.
    With Application.WorksheetFunction
        usadas = .CountA(wc.Range("A" & COT_PRIMEIRA & ":B" & COT_ULTIMA)) + _
                 .CountA(wc.Range("E" & COT_PRIMEIRA & ":P" & COT_ULTIMA)) + _
                 .CountA(wc.Range("R" & COT_PRIMEIRA & ":AD" & COT_ULTIMA))
    End With
    If usadas > 0 Then
        If MsgBox("A aba """ & ABA_COT & """ já está preenchida. Substituir pelos produtos da sugestão de compra?" & vbLf & vbLf & _
                  "Isso apaga os produtos, as quantidades e também os preços, desempates e condições já digitados " & _
                  "(colunas A, B, E a P e R a AD), porque eles não valeriam para os produtos novos.", _
                  vbYesNo + vbQuestion + vbDefaultButton2, "Relatórios do Digifarma") <> vbYes Then
            PreencherCotacao = -1
            Exit Function
        End If
    End If
    ReDim prod(1 To COT_ULTIMA - COT_PRIMEIRA + 1, 1 To 2)
    For i = 2 To n + 1
        If d(i, 8) = "1" And k < COT_ULTIMA - COT_PRIMEIRA + 1 Then
            k = k + 1
            nome = d(i, 3)
            If Len(d(i, 2)) > 0 Then nome = nome & " - " & d(i, 2)
            If Len(nome) > 0 Then
                If InStr("=+-@", Left$(nome, 1)) > 0 Then nome = "'" & nome   ' não virar fórmula
            End If
            prod(k, 1) = nome
            prod(k, 2) = CLng(Val(d(i, 7)))
        End If
    Next i
    protegida = wc.ProtectContents
    On Error GoTo Falha
    If protegida Then wc.Unprotect
    wc.Range("A" & COT_PRIMEIRA & ":B" & COT_ULTIMA).ClearContents
    wc.Range("E" & COT_PRIMEIRA & ":P" & COT_ULTIMA).ClearContents
    wc.Range("R" & COT_PRIMEIRA & ":AD" & COT_ULTIMA).ClearContents
    If k > 0 Then wc.Range("A" & COT_PRIMEIRA).Resize(k, 2).Value = prod
    If protegida Then ProtegerCotacao wc
    PreencherCotacao = k
    Exit Function
Falha:
    numErro = Err.Number
    descErro = Err.Description
    Resume Restaurar
Restaurar:
    On Error Resume Next
    If protegida Then ProtegerCotacao wc
    On Error GoTo 0
    Err.Raise numErro, , descErro
End Function

' Mesma proteção da planilha original: sem senha, com a formatação de linhas e colunas liberada.
Private Sub ProtegerCotacao(ByVal wc As Worksheet)
    wc.Protect DrawingObjects:=False, Contents:=True, Scenarios:=False, _
               AllowFormattingColumns:=True, AllowFormattingRows:=True
End Sub

' ---------- Lotes vencendo ----------
Public Sub GerarLotesVencendo()
    Dim ws As Worksheet, ini As Date, fim As Date, arq As String, d As Variant
    Dim n As Long, i As Long, nv As Long, n30 As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_LOT)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    arq = ArquivoTemporario("lotes")
    If Not RodarPrograma("LotesVencendo", ini, fim, 30, arq) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Vencimento, Dias, Codigo, CodBarras, Descricao, Lote, QtdLote, Estoque, Controle (do mais antigo ao mais novo)
    n = UBound(d, 1) - 1
    For i = 2 To n + 1
        If Val(d(i, 2)) < 0 Then
            nv = nv + 1
        ElseIf Val(d(i, 2)) <= 30 Then
            n30 = n30 + 1
        End If
    Next i
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Vencimento", "Dias para vencer", "Código", "Código de barras", "Descrição", "Lote", _
                               "Saldo do lote", "Estoque do produto", "Controle"), "DITTTTNNT"
    ' Na ordem do vencimento: primeiro os vencidos (vermelho), depois os que vencem em até 30 dias (amarelo).
    If nv > 0 Then ws.Cells(LINHA_DADOS, 1).Resize(nv, 9).Interior.Color = RGB(255, 199, 206)
    If n30 > 0 Then ws.Cells(LINHA_DADOS + nv, 1).Resize(n30, 9).Interior.Color = RGB(255, 235, 156)
    ws.Columns("C:D").ColumnWidth = 16
    ws.Columns("E").ColumnWidth = 50
    ws.Columns("F:I").ColumnWidth = 16
    If n = 0 Then
        resumo = "Nenhum lote com saldo vence de " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & "."
    Else
        resumo = "Vencimento de " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                 "   |   Lotes: " & n & "   |   Já vencidos: " & nv & "   |   Vencem em até 30 dias: " & n30
    End If
    ws.Range("A6").Value = resumo
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Estoque negativo ----------
Public Sub GerarEstoqueNegativo()
    Dim ws As Worksheet, arq As String, d As Variant, n As Long, i As Long, nc As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_NEG)
    arq = ArquivoTemporario("negativo")
    If Not RodarPrograma("EstoqueNegativo", Date, Date, 30, arq, False) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Estoque, Controle (do mais negativo ao menos negativo)
    n = UBound(d, 1) - 1
    For i = 2 To n + 1
        If Len(d(i, 5)) > 0 Then nc = nc + 1
    Next i
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Código", "Código de barras", "Descrição", "Estoque atual", "Controle"), "TTTNT"
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 50
    ws.Columns("D:E").ColumnWidth = 18
    If n = 0 Then
        resumo = "Nenhum produto com estoque negativo."
    Else
        resumo = "Produtos com estoque negativo: " & n & "   |   Controlados (SNGPC): " & nc
    End If
    ws.Range("A6").Value = resumo & "   |   Consultado em " & Format$(Now, "dd\/mm\/yyyy hh:nn")
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Conferência SNGPC ----------
Public Sub GerarConferenciaSNGPC()
    Dim ws As Worksheet, arq As String, d As Variant, n As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_SNG)
    arq = ArquivoTemporario("sngpc")
    If Not RodarPrograma("ConferenciaSNGPC", Date, Date, 30, arq, False) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Controle, Estoque, SomaLotes, Diferenca, QtdVencida, LotesNegativos, Situacao
    n = UBound(d, 1) - 1
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Código", "Código de barras", "Descrição", "Controle", "Estoque do produto", "Soma dos lotes", _
                               "Diferença", "Saldo em lotes vencidos", "Lotes com saldo negativo", "Situação"), "TTTTNNNNIT"
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 45
    ws.Columns("D").ColumnWidth = 18
    ws.Columns("E:I").ColumnWidth = 14
    ws.Columns("J").ColumnWidth = 60
    If n = 0 Then
        resumo = "Nenhum problema encontrado nos psicotrópicos e antimicrobianos."
    Else
        resumo = "Controlados com problema: " & n
    End If
    ws.Range("A6").Value = resumo & "   |   Consultado em " & Format$(Now, "dd\/mm\/yyyy hh:nn")
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- apoio ----------
Private Function LerPeriodo(ByVal ws As Worksheet, ByRef ini As Date, ByRef fim As Date) As Boolean
    If Not IsDate(ws.Range("B3").Value) Or Not IsDate(ws.Range("B4").Value) Then
        MsgBox "Preencha a data de início (B3) e a data de fim (B4) no formato dd/mm/aaaa.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    ini = CDate(ws.Range("B3").Value)
    fim = CDate(ws.Range("B4").Value)
    If ini > fim Then
        MsgBox "A data de início está depois da data de fim.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    LerPeriodo = True
End Function

Private Function ValorCfg(ByVal nome As String) As String
    On Error Resume Next
    ValorCfg = Trim$(CStr(ThisWorkbook.Names(nome).RefersToRange.Value))
    If Err.Number <> 0 Then ValorCfg = ""
    On Error GoTo 0
End Function

Private Function ArquivoTemporario(ByVal prefixo As String) As String
    Dim arq As String
    arq = Environ$("TEMP") & "\digifarma-" & prefixo & "-" & Format$(Now, "yyyymmdd-hhnnss") & ".tsv"
    ApagarArquivo arq
    ArquivoTemporario = arq
End Function

' Dir$ dá erro com caminho inválido (por exemplo, endereço do OneDrive); aí conta como "não existe".
Private Function Existe(ByVal arq As String) As Boolean
    On Error Resume Next
    Existe = Len(Dir$(arq)) > 0
End Function

Private Sub ApagarArquivo(ByVal arq As String)
    On Error Resume Next
    If Existe(arq) Then Kill arq
    On Error GoTo 0
End Sub

' Roda o relatorios-digifarma.ps1 numa janela preta (onde a senha é digitada) e espera terminar.
' Se der erro, a janela fica aberta (pause) mostrando o motivo.
Private Function RodarPrograma(ByVal relatorio As String, ByVal ini As Date, ByVal fim As Date, _
                               ByVal dias As Long, ByVal arq As String, Optional ByVal comDatas As Boolean = True) As Boolean
    Dim pasta As String, ps1 As String, banco As String, usuario As String, cmd As String, datas As String
    pasta = ValorCfg("CfgPasta")
    If pasta = "" Then pasta = ThisWorkbook.Path
    If Right$(pasta, 1) = "\" Then pasta = Left$(pasta, Len(pasta) - 1)
    ps1 = pasta & "\relatorios-digifarma.ps1"
    If InStr(pasta, "://") > 0 Then
        MsgBox "A pasta """ & pasta & """ é um endereço da internet (OneDrive/SharePoint)." & vbLf & _
               "Informe a pasta do computador onde está o relatorios-digifarma.ps1 na aba """ & ABA_CFG & """ (célula B4).", _
               vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If pasta = "" Or Not Existe(ps1) Then
        MsgBox "Não achei o relatorios-digifarma.ps1 na pasta """ & pasta & """." & vbLf & _
               "Informe a pasta certa na aba """ & ABA_CFG & """ (célula B4).", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    banco = ValorCfg("CfgBanco")
    usuario = ValorCfg("CfgUsuario")
    If usuario = "" Then usuario = "SYSDBA"
    If banco = "" Then
        MsgBox "Informe o banco do Digifarma na aba """ & ABA_CFG & """ (célula B3).", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If InStr(pasta & banco & usuario & arq, """") > 0 Or InStr(pasta & banco & usuario & arq, "%") > 0 Then
        MsgBox "O banco, a pasta e o usuário (aba """ & ABA_CFG & """) não podem ter aspas ("") nem o sinal %.", _
               vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If comDatas Then datas = " -DataInicio " & Format$(ini, "dd\/mm\/yyyy") & " -DataFim " & Format$(fim, "dd\/mm\/yyyy")
    cmd = "cmd.exe /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & ps1 & """" & _
          " -Banco """ & banco & """ -Usuario """ & usuario & """ -Relatorio " & relatorio & datas & _
          " -DiasEstoque " & dias & " -ArquivoSaida """ & arq & """ || pause"
    CreateObject("WScript.Shell").Run cmd, 1, True
    If Not Existe(arq) Then
        MsgBox "O relatório não foi gerado. O motivo apareceu na janela preta.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    RodarPrograma = True
End Function

' Lê o arquivo de texto (UTF-8, separado por tabulação) para uma matriz: linha 1 = cabeçalho.
' permitirVazio: aceita arquivo só com o cabeçalho (nada encontrado).
Private Function LerTabela(ByVal arq As String, Optional ByVal permitirVazio As Boolean = False) As Variant
    Dim st As Object, txt As String, linhas() As String, campos() As String
    Dim n As Long, i As Long, j As Long, k As Long, ncol As Long, d() As String
    Set st = CreateObject("ADODB.Stream")
    st.Type = 2
    st.Charset = "utf-8"
    st.Open
    st.LoadFromFile arq
    txt = st.ReadText(-1)
    st.Close
    If Len(txt) > 0 Then
        If AscW(Left$(txt, 1)) = &HFEFF Then txt = Mid$(txt, 2)
    End If
    txt = Replace(txt, vbCr, "")
    linhas = Split(txt, vbLf)
    For i = 0 To UBound(linhas)
        If Len(linhas(i)) > 0 Then n = n + 1
    Next i
    If n < 1 Or (n < 2 And Not permitirVazio) Then
        MsgBox "O relatório veio vazio.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    ncol = UBound(Split(linhas(0), vbTab)) + 1
    ReDim d(1 To n, 1 To ncol)
    For i = 0 To UBound(linhas)
        If Len(linhas(i)) > 0 Then
            j = j + 1
            campos = Split(linhas(i), vbTab)
            For k = 0 To ncol - 1
                If k <= UBound(campos) Then d(j, k + 1) = campos(k)
            Next k
        End If
    Next i
    LerTabela = d
End Function

Private Sub LimparResultado(ByVal ws As Worksheet)
    ws.Range(ws.Rows(LINHA_CAB - 2), ws.Rows(ws.Rows.Count)).Clear
End Sub

Private Sub EscreverCabecalho(ByVal ws As Worksheet, ByVal titulos As Variant)
    Dim r As Range
    Set r = ws.Cells(LINHA_CAB, 1).Resize(1, UBound(titulos) - LBound(titulos) + 1)
    r.Value = titulos
    r.Font.Bold = True
    r.Interior.Color = RGB(221, 235, 247)
    r.WrapText = True
End Sub

' Escreve a tabela lida (linha 1 = cabeçalho do arquivo) com os títulos em LINHA_CAB e os dados a partir de
' LINHA_DADOS. tipos: uma letra por coluna: T = texto, N = número, I = inteiro, D = data (aaaa-mm-dd).
Private Sub EscreverDados(ByVal ws As Worksheet, d As Variant, ByVal titulos As Variant, ByVal tipos As String)
    Dim n As Long, nc As Long, i As Long, j As Long, saida() As Variant, v As String
    n = UBound(d, 1) - 1
    nc = Len(tipos)
    LimparResultado ws
    EscreverCabecalho ws, titulos
    If n < 1 Then Exit Sub
    ReDim saida(1 To n, 1 To nc)
    For i = 1 To n
        For j = 1 To nc
            v = d(i + 1, j)
            Select Case Mid$(tipos, j, 1)
                Case "N"
                    saida(i, j) = Val(v)
                Case "I"
                    saida(i, j) = CLng(Val(v))
                Case "D"
                    If Len(v) = 10 Then saida(i, j) = DateSerial(CInt(Left$(v, 4)), CInt(Mid$(v, 6, 2)), CInt(Mid$(v, 9, 2)))
                Case Else
                    saida(i, j) = v
            End Select
        Next j
    Next i
    For j = 1 To nc
        Select Case Mid$(tipos, j, 1)
            Case "T": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "@"
            Case "D": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "dd/mm/yyyy"
            Case "I": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "0"
        End Select
    Next j
    ws.Cells(LINHA_DADOS, 1).Resize(n, nc).Value = saida
End Sub
