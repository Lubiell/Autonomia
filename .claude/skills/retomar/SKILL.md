---
name: retomar
description: Retoma numa sessão nova o trabalho registrado pelo /handoff. Use com /retomar, opcionalmente com a data (AAAA-MM-DD) ou o caminho do arquivo.
disable-model-invocation: true
---

# Retomar sessão

Localize o documento de passagem: argumento com caminho → use exatamente esse arquivo; argumento com data → o mais recente daquele dia em `~/.claude/handoffs/`; sem argumento → o mais recente da pasta. Pasta vazia ou inexistente: diga que não há passagem salva (o `/handoff` cria uma) e pare.

Leia o arquivo inteiro e responda com o briefing:
1. **Objetivo** em 2–3 linhas, com suas palavras.
2. **Estado:** o que está feito e verificado, separado do que é suposição.
3. **O que não repetir:** cada abordagem que falhou, com o motivo. Mostre sempre, mesmo vazio ("nenhuma registrada").
4. **Pendências e bloqueios.**
5. **Próximo passo** do documento; sem um, pergunte por onde começar.

Avise no briefing: documento com mais de 7 dias (as coisas podem ter mudado); arquivo, branch ou commit citado que não existe mais.

Depois do briefing, espere o usuário antes de mexer em qualquer arquivo. "Continua" significa executar o próximo passo do documento.
