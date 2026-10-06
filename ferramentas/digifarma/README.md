# Desmarcar psicotrópico e antimicrobiano no Digifarma

`desmarcar-controlados.ps1` tira a marcação de **Psicotrópico** (controlado) e de **Antimicrobiano** dos produtos no banco do Digifarma (Firebird, arquivo `Digifarma6.FDB`). Com ele você pode:

- ver só os controlados **com estoque** (`-Estoque ComEstoque`) ou sem estoque (`-Estoque SemEstoque`);
- **escolher** na lista quais produtos desmarcar (`-Escolher`) ou informar os códigos (`-Codigos 12,345`);
- desmarcar só psicotrópico, só antimicrobiano ou os dois (`-Desmarcar Psicotropico|Antimicrobiano|Ambos`).

Sem `-Aplicar` o programa só **simula**: mostra a lista e não altera nada. Com `-Aplicar` ele pede confirmação, faz backup do banco, desmarca tudo numa única transação e confere o resultado.

## Antes de usar: SNGPC

A marcação é o que faz o Digifarma escriturar o produto no SNGPC.

- Desmarque só produto **marcado por engano**, ou com orientação do farmacêutico responsável. Medicamento que é de fato controlado (Portaria 344/98) ou antimicrobiano continua obrigado a ser escriturado.
- A ANVISA só aceita o arquivo se a classificação do produto (controlado ou antimicrobiano) for a mesma do primeiro envio. Produto já enviado com uma classificação e depois alterado gera erro no SNGPC. O próprio Digifarma orienta a finalizar o inventário e reenviar ([Digifarma: como corrigir erros no SNGPC](http://www.digifarma.com.br/conhecimento/saiba-como-corrigir-erros-no-sngpc)).
- O produto **com estoque** está no inventário de controlados do SNGPC. Desmarcar esse produto é justamente o caso que mais precisa de cuidado.

## O que precisa

- Windows com PowerShell (já vem instalado).
- O Firebird instalado no servidor do Digifarma. O programa usa o `isql.exe` e o `gbak.exe` que vêm com ele e os procura em `C:\Program Files\Firebird\...`. Se não achar, informe o caminho com `-Isql`.
- Usuário e senha do Firebird (padrão `SYSDBA`). A senha é pedida na hora e não fica gravada em lugar nenhum.

## Jeito mais fácil: o atalho `desmarcar-controlados.bat`

Coloque `desmarcar-controlados.bat` na mesma pasta do `desmarcar-controlados.ps1`, por exemplo `C:\Ferramentas\digifarma`, e dê dois cliques nele. Aparece um menu:

1. **Ver os controlados com estoque e escolher**: simulação, não altera nada.
2. **DESMARCAR**: abre a janela com a lista. A janela não tem botão "Desmarcar": clique nos produtos (Ctrl+clique para vários, Shift+clique para uma sequência) e depois em **OK**. Em seguida, digite `DESMARCAR` na janela preta. O programa faz backup antes de alterar.
3. **Desfazer a última vez que desmarcou**: usa o `desfazer.sql` mais recente da pasta `registros`.

O banco (`localhost:C:\Digifarma\Dados\Digifarma6.FDB`) e a coluna de estoque (`PROD_SALDO`) ficam nas primeiras linhas do `.bat`. Se mudarem, abra o arquivo no Bloco de Notas e ajuste.

## Com o Digifarma aberto

Pode usar com o Digifarma aberto nos outros computadores:

- Ler, simular e fazer o backup funcionam normalmente.
- Na hora de gravar, se um produto estiver em uso naquele instante (por exemplo, uma venda baixando o estoque), o programa espera até 5 segundos por ele.
- Se o produto continuar em uso, ele grava os outros e tenta de novo depois (`-Tentativas`, padrão 3, com 10 segundos entre as tentativas).
- O que continuar em uso fica marcado e aparece no final, com o comando para rodar de novo só para esses produtos (código de saída `3`).

Cuidados:

- Ninguém deve estar com a **tela de cadastro** de um desses produtos aberta. Se a pessoa salvar essa tela depois, o Digifarma pode gravar a marcação de volta. Para conferir, rode a simulação de novo mais tarde com os mesmos `-Codigos`.
- Um computador que estava com o produto na tela pode precisar fechar e abrir a tela para ver a mudança.
- Em caso raro, uma venda desse mesmo produto no mesmo segundo pode dar aviso de conflito no caixa e precisar ser repetida.

## Passo a passo pelo PowerShell

Rode no servidor. Abra o PowerShell na pasta do programa.

1. **Descobrir** onde estão as marcações e o estoque. Só lê, não altera nada:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\desmarcar-controlados.ps1 -Banco 'localhost:C:\CAMINHO\Digifarma6.FDB' -Descobrir
   ```

   O resultado mostra as colunas candidatas e quantos produtos têm cada valor, por exemplo `PRODUTOS.CONTROLADO 'S'=120 'N'=4300`. Também mostra a escolha automática e a coluna de estoque. Confira se batem com a tela de cadastro de produtos.

2. **Ver os controlados com estoque e escolher** quais desmarcar. É uma simulação e não altera nada:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\desmarcar-controlados.ps1 -Banco 'localhost:C:\CAMINHO\Digifarma6.FDB' -Estoque ComEstoque -Escolher
   ```

   No Windows PowerShell abre uma janela com a lista (código, descrição, estoque, marcações). Use a caixa de filtro para buscar e selecione vários produtos com Ctrl ou Shift. Clique OK. Sem janela, aparece uma lista numerada: digite `1,3,5-8` ou `T` para todos. No final, o programa mostra o comando para aplicar exatamente essa escolha (`-Codigos ...`).

3. **Aplicar**: o mesmo comando com `-Aplicar` (ou o `-Codigos ...` sugerido). Digite `DESMARCAR` para confirmar.

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\desmarcar-controlados.ps1 -Banco 'localhost:C:\CAMINHO\Digifarma6.FDB' -Estoque ComEstoque -Escolher -Aplicar
   ```

4. Confira alguns produtos da lista no Digifarma.

Para desmarcar **todos** os marcados de uma vez, sem escolher, rode sem `-Escolher` e sem `-Codigos`.

`-Banco`: use `localhost:` antes do caminho quando rodar no próprio servidor, ou `NOMEDOSERVIDOR:C:\CAMINHO\Digifarma6.FDB` de outro computador. O caminho é o do arquivo no disco do servidor. Se não souber onde fica, procure por `Digifarma6.FDB` no servidor.

## O que fica gravado

Cada execução cria `registros\AAAAMMDD-HHMMSS\` ao lado do programa, com estes arquivos:

| Arquivo | Conteúdo |
|---|---|
| `log.txt` | o que foi feito, com data e hora |
| `produtos-a-desmarcar.csv` | os produtos escolhidos e os valores **de antes** (abre no Excel) |
| `backup-antes.fbk` | backup do banco inteiro, feito antes de alterar (só com `-Aplicar`) |
| `desfazer.sql` | comandos para remarcar exatamente o que foi desmarcado (só com `-Aplicar`) |

O `backup-antes.fbk` é uma cópia do banco inteiro, **com dados de clientes** (LGPD). Guarde a pasta só no servidor, com acesso restrito, e apague o backup quando não precisar mais dele. A pasta `registros/` está no `.gitignore` e não vai para o Git.

## Como desfazer

- **Só o que o programa desmarcou** (recomendado): rode o programa com `-Desfazer` e o `desfazer.sql` daquela execução. A senha é pedida do mesmo jeito e não aparece na tela. Ele remarca apenas os produtos que continuam desmarcados.

  ```powershell
  powershell -ExecutionPolicy Bypass -File .\desmarcar-controlados.ps1 -Banco 'localhost:C:\CAMINHO\Digifarma6.FDB' -Desfazer .\registros\AAAAMMDD-HHMMSS\desfazer.sql
  ```
- **Voltar o banco inteiro**: restaure `backup-antes.fbk` com o `gbak` **num arquivo novo** e troque os arquivos com o Digifarma fechado. Na dúvida, peça ao suporte do Digifarma. Isso desfaz também tudo o que foi lançado depois do backup.

## Quando ele não acha sozinho

Os nomes das tabelas e colunas do Digifarma não são públicos. O programa procura colunas com `PSICO`, `CONTROLAD`, `ANTIMIC` ou `ANTIBIO` no nome, mas só escolhe sozinho uma tabela com `PROD` no nome. Ele reconhece os valores `S/N`, `T/F`, `1/0` e `TRUE/FALSE`, desde que os dois apareçam na coluna. Por exemplo, se só existem `S` e vazio, ele não adivinha o que é "desmarcado". Se houver dúvida, ele para (código 2) e pede os nomes ou valores; ele nunca chuta. Use o que o `-Descobrir` mostrou:

| Parâmetro | Para quê |
|---|---|
| `-Tabela PRODUTOS` | tabela do cadastro de produtos |
| `-CampoPsicotropico X` / `-CampoAntimicrobiano Y` | colunas das marcações |
| `-ValorMarcado S -ValorDesmarcado N` | quando os valores não são os reconhecidos acima; `-ValorDesmarcado NULL` deixa a coluna vazia |
| `-CampoEstoque ESTOQUE` | coluna do saldo na tabela de produtos |
| `-CampoDescricao PROD_NOME` | coluna com o nome do produto, se a lista aparecer sem descrição (o log mostra as colunas de texto) |
| `-TabelaEstoque T -CampoEstoque QTD -ChaveEstoque PRODUTO` | saldo em outra tabela (por loja, lote...): soma `QTD` por produto; os três são obrigatórios juntos |
| `-Isql 'C:\...\isql.exe'` | quando o Firebird não está na pasta padrão |
| `-PastaSaida D:\registros` | onde gravar log, lista e backup |
| `-SemBackup` | não fazer o backup (só se já tiver um recente) |
| `-SemPerguntar` | não pedir para digitar DESMARCAR (uso em lote) |
| `-Tentativas 3` | quantas vezes tentar os produtos que estavam em uso em outro computador (1 a 10) |
| `-Desfazer arquivo.sql` | remarca o que uma execução anterior desmarcou (veja "Como desfazer") |

Códigos de saída: `0` ok, `1` erro ou cancelado, `2` faltam informações (rode `-Descobrir`), `3` alguns produtos estavam em uso e continuam marcados.

## Problemas comuns

- **"isql do Firebird não encontrado"**: informe `-Isql` com o caminho do `isql.exe` da pasta do Firebird.
- **"Your user name and password are not defined"**: usuário ou senha errados.
- **"continuaram em uso em outro computador e seguem marcados"**: algum computador estava usando esses produtos durante todas as tentativas. Rode de novo mais tarde com o comando `-Aplicar -Codigos ...` mostrado no final.
- **"I/O error ... open"**: caminho do banco errado. Rodando no servidor, use `localhost:` antes do caminho.
- **O Windows não deixa rodar o script**: use `powershell -ExecutionPolicy Bypass -File ...` como nos exemplos, ou `Unblock-File .\desmarcar-controlados.ps1`.

## Relatórios (`relatorios-digifarma.ps1` e `relatorios.bat`)

Programa separado que **só lê** o banco e nunca altera nada. Coloque na mesma pasta:

- `relatorios.bat`;
- `relatorios-digifarma.ps1`;
- `Cotacao_Pronta_em_branco.xlsx`.

Dê dois cliques em `relatorios.bat`. O menu tem duas opções:

1. **Abrir a janela de relatórios.** Nela você escolhe a **data de início** e a **data de fim** do período de vendas, e clica no botão do relatório:
   - **Gerar Curva ABC**: os produtos vendidos no período, do maior para o menor faturamento, com a classe. A são os que somam até 80% do faturamento, B até 95%, C o resto. Vendas canceladas não contam.
   - **Gerar Sugestão de compra (cotação)**: para cada produto, calcula a venda média por dia × os **dias de estoque desejados** (campo na janela, padrão 30) − o estoque atual. Grava uma planilha com a conta e uma **cópia preenchida da cotação**. A cópia tem PRODUTO (nome e código de barras) e QUANT na aba Cotação, a partir da linha 3, até 1000 produtos. As fórmulas, cores e abas de fornecedores da sua planilha ficam como estão e recalculam ao abrir. O `Cotacao_Pronta_em_branco.xlsx` original nunca é alterado.
   - **Gerar mapa do banco.**
2. **Gerar só o mapa do banco**, sem janela. Use esta opção se a janela não abrir.

O mapa do banco é um arquivo de texto com os nomes e tipos das tabelas e colunas, as chaves, os índices e quantas linhas cada tabela tem. Ele **não leva nenhum dado** de cliente, venda ou produto. É com ele que se configura onde ficam as vendas no seu Digifarma.

Tudo vai para a pasta `registros\`:

- `curva-abc_AAAA-MM-DD_a_AAAA-MM-DD.csv`;
- `sugestao-compra_....csv`;
- `Cotacao_AAAA-MM-DD_HHMM.xlsx`;
- `mapa-do-banco-....txt`.

**Configuração das vendas:** os relatórios precisam saber em qual tabela e coluna estão os itens vendidos, a data e a marca de venda cancelada. Isso fica no bloco `$EsquemaPadrao`, no começo do `relatorios-digifarma.ps1`, ou num arquivo `-Esquema config.psd1`. Enquanto não estiver configurado, os botões avisam "ainda falta configurar onde ficam as vendas". O primeiro passo é gerar o mapa do banco e mandar o arquivo na conversa.

## Relatórios dentro da planilha (macro do Excel)

Os mesmos dois relatórios podem ficar **dentro da sua planilha de cotação**, em abas novas com as datas e um botão. O botão chama o `relatorios-digifarma.ps1`, que só lê o banco, e traz o resultado para a aba.

**Instalação (uma vez só):**

1. Coloque na mesma pasta `relatorios-digifarma.ps1`, `Relatorios.bas` e a sua cotação (`Cotacao_Pronta_em_branco.xlsx`).
2. Abra a cotação no Excel.
3. Aperte **Alt+F11** para abrir o editor do VBA. Vá em **Arquivo > Importar arquivo** e escolha `Relatorios.bas`. Feche o editor.
4. Aperte **Alt+F8**, escolha **InstalarRelatorios** e clique em **Executar**. Ele cria estas abas:
   - **Sugestão de compra** e **Curva ABC**, logo depois da aba Cotação;
   - **Config relatórios**, no fim. Nela ficam o banco, a pasta do `.ps1` e o usuário do Firebird.
5. Use **Arquivo > Salvar como > Pasta de Trabalho Habilitada para Macro do Excel (\*.xlsm)**. Guarde esse `.xlsm` como a sua cotação em branco. Mantenha também o `.xlsx` na pasta: a janela do `relatorios.bat` ainda usa esse arquivo.

**Uso:**

1. Abra o `.xlsm`. Se aparecer a faixa amarela, clique em **Habilitar conteúdo**.
2. Na aba **Curva ABC** ou **Sugestão de compra**, preencha:
   - a **data de início** (B3);
   - a **data de fim** (B4);
   - na sugestão, os **dias de estoque** (B5).
3. Clique no botão. Abre uma janela preta pedindo a **senha do Firebird**, que não fica gravada em lugar nenhum. Enquanto ela está aberta, o Excel fica parado ("Não respondendo"); é normal. Quando ela fecha, o resultado aparece na aba, a partir da linha 8.
4. A sugestão também preenche **PRODUTO e QUANT** na aba Cotação, até 1000 produtos. Se passar disso, entram os 1000 mais vendidos, e o resto fica só na aba da sugestão. Se a Cotação já estiver preenchida, ele pergunta antes. Ao substituir, apaga também os preços, desempates e condições já digitados (colunas E a P e R a AD), porque não valeriam para os produtos novos. A proteção da aba Cotação volta como estava.
5. Se der erro, a janela preta fica aberta mostrando o motivo. Aperte uma tecla para fechar.

Observações:

- Se o Excel avisar **"a Microsoft bloqueou macros porque a origem deste arquivo não é confiável"**, feche o Excel. Clique com o botão direito no `.xlsm` > **Propriedades**, marque **Desbloquear** e clique em **OK**.
- Se a planilha estiver numa pasta do **OneDrive**, o Excel pode informar um endereço da internet como pasta. Nesse caso, escreva em **B4** da aba Config relatórios a pasta do computador onde está o `relatorios-digifarma.ps1` (por exemplo `C:\Digifarma\Relatorios`).
- Instalar de novo (Alt+F8 > InstalarRelatorios) refaz as abas dos relatórios. Mantém as datas, os dias e o que estiver na aba Config relatórios.
- A configuração das vendas (item anterior) vale para a planilha também. Enquanto ela não for feita, a janela preta avisa "ainda falta configurar onde ficam as vendas".

## Testes

`testes/testar.sh` roda o programa contra um Firebird real em bancos descartáveis. Ele cobre:

- descoberta e simulação;
- filtros de estoque (na própria tabela e em outra tabela);
- `-Codigos`, `-Escolher` e cancelamento;
- `-Desfazer` e `desfazer.sql`;
- bloqueio de outra sessão no meio da alteração;
- senha errada;
- colunas `SMALLINT`/`BOOLEAN` e desmarcado como `NULL`;
- tabela ambígua ou sem `PROD` no nome;
- código com `|`;
- relatórios: Curva ABC, sugestão de compra, período inválido ou sem vendas e cotação preenchida a partir de um modelo em branco;
- o arquivo de texto que a macro do Excel lê (`-ArquivoSaida`).

A macro do Excel (`Relatorios.bas`) não é coberta por esses testes: o VBA só roda no Excel do Windows.

Precisa de Linux com servidor Firebird, `isql-fb`, `gbak`, `pwsh` e `python3`:

```bash
ISC_PASSWORD=senha_do_sysdba PWSH=/caminho/pwsh bash ferramentas/digifarma/testes/testar.sh
```

Os testes usam um banco **simulado**. O programa ainda não foi rodado contra um `Digifarma6.FDB` real, então comece sempre por `-Descobrir` e pela simulação.
