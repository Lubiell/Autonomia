---
name: handoff
description: Gera um documento de passagem para outra sessão ou agent continuar o trabalho desta conversa. Use com /handoff, opcionalmente dizendo para que será a próxima sessão.
disable-model-invocation: true
---

# Passagem de trabalho

Escreva um documento curto para uma sessão nova, que não viu esta conversa, continuar de onde parou.

Salve fora do repositório, em `~/.claude/handoffs/AAAA-MM-DD-<tema>.md` (crie a pasta se faltar), para o `/retomar` encontrar depois. Diga o caminho no fim. Se o usuário pedir um lugar específico, vale o pedido.

Se o usuário passou argumento, ele descreve o foco da próxima sessão: priorize o que serve a esse foco.

## Conteúdo
1. **Objetivo:** o pedido original em 1–3 linhas, com as palavras do usuário quando importarem.
2. **Estado:** o que está feito, verificado e onde (branch, commit, PR, URL). Separe o que foi verificado do que é suposição.
3. **Decisões:** o que foi decidido e por quê, inclusive o que foi recusado — para a próxima sessão não refazer a discussão.
4. **Arquivos-chave:** caminhos com uma linha sobre cada um.
5. **Como verificar:** comandos de teste/build e o resultado esperado.
6. **O que não funcionou:** cada abordagem tentada que falhou, com o motivo exato (erro, causa) — sem isso a próxima sessão repete o beco sem saída. Nada falhou: escreva "nenhuma".
7. **Pendências e bloqueios:** o que falta, o que espera o usuário.
8. **Próximo passo:** a primeira ação concreta.
9. **Skills e agents sugeridos** para a próxima sessão.

## Regras
- Não duplique o que já está registrado (PR, commit, `decisoes.md`, plano, issue): aponte o caminho ou a URL.
- Sem segredo, token, senha ou dado pessoal. Se for necessário, diga onde está, não o valor.
- Curto: o que não muda a próxima ação fica de fora.
