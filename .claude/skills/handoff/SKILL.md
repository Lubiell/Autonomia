---
name: handoff
description: Gera um documento de passagem para outra sessão ou agent continuar o trabalho desta conversa. Use com /handoff, opcionalmente dizendo para que será a próxima sessão.
disable-model-invocation: true
---

# Passagem de trabalho

Escreva um documento curto para uma sessão nova, que não viu esta conversa, continuar de onde parou.

Salve fora do repositório: na pasta temporária do sistema (ou na scratchpad da sessão, se houver). Diga o caminho no fim.

Se o usuário passou argumento, ele descreve o foco da próxima sessão: priorize o que serve a esse foco.

## Conteúdo
1. **Objetivo:** o pedido original em 1–3 linhas, com as palavras do usuário quando importarem.
2. **Estado:** o que está feito, verificado e onde (branch, commit, PR, URL). Separe o que foi verificado do que é suposição.
3. **Decisões:** o que foi decidido e por quê, inclusive o que foi recusado — para a próxima sessão não refazer a discussão.
4. **Arquivos-chave:** caminhos com uma linha sobre cada um.
5. **Como verificar:** comandos de teste/build e o resultado esperado.
6. **Pendências e bloqueios:** o que falta, o que espera o usuário.
7. **Próximo passo:** a primeira ação concreta.
8. **Skills e agents sugeridos** para a próxima sessão.

## Regras
- Não duplique o que já está registrado (PR, commit, `decisoes.md`, plano, issue): aponte o caminho ou a URL.
- Sem segredo, token, senha ou dado pessoal. Se for necessário, diga onde está, não o valor.
- Curto: o que não muda a próxima ação fica de fora.
