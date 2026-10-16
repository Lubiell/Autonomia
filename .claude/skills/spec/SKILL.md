---
name: spec
description: Use antes de escrever código em tarefa de risco — mudança de schema ou migração de dado, dado pessoal, de saúde ou financeiro, dinheiro, apagar dado sem volta, contrato de API que outro código consome. Propõe caminhos com custo, escreve uma spec curta no repositório e espera o ok antes de codar.
---

# Spec — desenhar antes de codar

Único ponto em que se para e espera o usuário. Vale só para tarefa de risco; para o resto, siga direto — pedir aprovação de coisa simples desperdiça o tempo dele.

## Quando aplicar
Basta um destes:
- Muda schema de banco ou migra dado existente.
- Toca dado pessoal, de saúde ou financeiro.
- Envolve dinheiro: preço, cobrança, cálculo de valor.
- Apaga ou sobrescreve dado que não dá para recuperar.
- Muda contrato de API que outro código já consome.

Não aplicar: bug pontual, CSS, campo novo em tela, script isolado, texto. Pedido com duas leituras já tem regra própria no `CLAUDE.md`.

## Como fazer
1. Busque sozinho, pelos conectores e pelo código, tudo o que der. Pergunte só o resto, **uma pergunta por vez**, de preferência múltipla escolha — ele responde do celular.
2. **Duas ou três alternativas** com o custo de cada uma e uma recomendação explícita. Não devolva a decisão sem opinião.
3. **Spec curta** (meia página) em `docs/specs/AAAA-MM-DD-nome.md`, commitada junto — spec no chat some, no repositório a próxima sessão lê:

```markdown
# Spec — <nome>
Data: <AAAA-MM-DD>

## Problema
<o que está errado hoje, em uma frase>

## Solução escolhida
<o que vai ser feito, e por que esta e não a outra>

## Fora de escopo
<o que deliberadamente não será feito>

## Arquivos afetados
<lista>

## Como saber que deu certo
<critério verificável, não "vai funcionar">

## Risco e volta atrás
<o que pode quebrar e como reverter>
```

4. **Espere o "ok".** Depois dele, siga o ciclo inteiro sem parar: código, testes, PR e merge pelas regras do `CLAUDE.md`.

## O que não fazer
- Escrever a spec e começar a codar na mesma resposta. O gate é o gate.
- Spec de três páginas para tarefa de uma hora: se a spec demora mais que o trabalho, a tarefa era simples.
- Trocar a spec no meio sem avisar. Mudou o entendimento, diga e atualize o arquivo.

"Fora de escopo" é a seção que mais importa: é ela que impede o trabalho de crescer sozinho.
