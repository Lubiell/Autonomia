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

## Passo a passo

Rode no servidor, com o Digifarma **fechado em todos os computadores** (ou fora do horário de atendimento). Abra o PowerShell na pasta do programa.

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

4. Abra o Digifarma e confira alguns produtos da lista.

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

A pasta `registros/` está no `.gitignore` e não vai para o Git.

## Como desfazer

- **Só o que o programa desmarcou** (recomendado): `"C:\Program Files\Firebird\Firebird_X_X\isql.exe" -user SYSDBA -password SUA_SENHA -i desfazer.sql localhost:C:\CAMINHO\Digifarma6.FDB`. Ele remarca apenas os produtos que continuam desmarcados.
- **Voltar o banco inteiro**: restaure `backup-antes.fbk` com o `gbak` **num arquivo novo** e troque os arquivos com o Digifarma fechado. Na dúvida, peça ao suporte do Digifarma. Isso desfaz também tudo o que foi lançado depois do backup.

## Quando ele não acha sozinho

Os nomes das tabelas e colunas do Digifarma não são públicos. O programa procura colunas com `PSICO`, `CONTROLAD`, `ANTIMIC` ou `ANTIBIO` no nome e reconhece os valores `S/N`, `T/F`, `1/0` e `TRUE/FALSE`. Se houver dúvida, ele para e pede os nomes; ele nunca chuta. Use o que o `-Descobrir` mostrou:

| Parâmetro | Para quê |
|---|---|
| `-Tabela PRODUTOS` | tabela do cadastro de produtos |
| `-CampoPsicotropico X` / `-CampoAntimicrobiano Y` | colunas das marcações |
| `-ValorMarcado S -ValorDesmarcado N` | quando os valores não são os reconhecidos acima |
| `-CampoEstoque ESTOQUE` | coluna do saldo na tabela de produtos |
| `-TabelaEstoque T -CampoEstoque QTD -ChaveEstoque PRODUTO` | saldo em outra tabela (por loja, lote...): soma por produto |
| `-Isql 'C:\...\isql.exe'` | quando o Firebird não está na pasta padrão |
| `-PastaSaida D:\registros` | onde gravar log, lista e backup |
| `-SemBackup` | não fazer o backup (só se já tiver um recente) |
| `-Confirmar` | não perguntar a confirmação (uso em lote) |

Códigos de saída: `0` ok, `1` erro ou cancelado, `2` faltam informações (rode `-Descobrir`).

## Problemas comuns

- **"isql do Firebird não encontrado"**: informe `-Isql` com o caminho do `isql.exe` da pasta do Firebird.
- **"Your user name and password are not defined"**: usuário ou senha errados.
- **"lock conflict" ou "deadlock"**: algum computador está com o Digifarma aberto editando produto. Feche e rode de novo. Nada foi alterado.
- **"I/O error ... open"**: caminho do banco errado. Rodando no servidor, use `localhost:` antes do caminho.
- **O Windows não deixa rodar o script**: use `powershell -ExecutionPolicy Bypass -File ...` como nos exemplos, ou `Unblock-File .\desmarcar-controlados.ps1`.

## Testes

`testes/testar.sh` roda o programa contra um Firebird real em bancos descartáveis. Ele cobre descoberta, simulação, filtro de estoque (na própria tabela e em outra tabela), `-Codigos`, `-Escolher`, cancelamento, `desfazer.sql`, senha errada, colunas `SMALLINT`/`BOOLEAN` e tabela ambígua. Precisa de Linux com servidor Firebird, `isql-fb`, `gbak` e `pwsh`:

```bash
ISC_PASSWORD=senha_do_sysdba PWSH=/caminho/pwsh bash ferramentas/digifarma/testes/testar.sh
```

Os testes usam um banco **simulado**. O programa ainda não foi rodado contra um `Digifarma6.FDB` real, então comece sempre por `-Descobrir` e pela simulação.
