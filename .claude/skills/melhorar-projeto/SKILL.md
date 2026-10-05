---
name: melhorar-projeto
description: Use quando pedirem para melhorar, revisar ou avaliar um projeto (site, sistema, app, automação, base de dados) ou perguntarem "o que falta", "como deixar melhor", "qual agente usar". Diagnostica por área e sugere, em ordem de prioridade, o agent ou a skill que resolve cada ponto.
---

# Melhorar projeto: diagnóstico e agent indicado

## 1. Diagnóstico rápido (só leitura)
Levante a stack real e o estado: README/CLAUDE.md, comandos de teste/build/lint, CI, `git status`. Projeto grande ou desconhecido: delegue o levantamento ao `scout`. Confira cada área com evidência (arquivo, comando, saída), nunca por suposição:

| Área | Sinal de problema | Agent | Skill |
|---|---|---|---|
| Arquitetura | módulos acoplados, decisão técnica em aberto, recurso grande por vir | `architect` | `api-backend`, `banco-dados` |
| Erros | bug conhecido, teste falhando, exceção em log | `debugger` | — |
| Testes | sem testes, sem CI, cobertura só do caminho feliz | `tester` | `webapp-testing` |
| Qualidade do código | duplicação, função enorme, diff recente sem revisão | `reviewer` | — |
| Segurança | segredo no código, dependência vulnerável, entrada sem validação, regras de banco abertas | `security` | `seguranca-digital`, `firebase-security-rules-auditor`, `lgpd` |
| Deploy e operação | deploy manual, sem backup, sem monitoramento, Git bagunçado | `devops` | `deploy-web`, `wrangler`, `automacao` |
| Site e interface | erro no console, layout quebrado no celular, formulário sem teste | `qa-web` | `frontend-design`, `accessibility`, `performance`, `seo` |
| Dados | planilha ou base sem consistência, métrica sem acompanhamento | `data-analyst` | `analise-dados` |
| Documentação | sem README, instalação não reproduzível, sem CHANGELOG | `docs-writer` | — |
| Ferramentas e mercado | biblioteca desatualizada, dúvida entre serviços, lei ou preço a conferir | `researcher` | `discover-resources` |
| Negócio | sem público definido, sem métrica de resultado, marca inconsistente | — | `produto`, `negocios`, `marca`, `conteudo`, `trafego-pago` |

## 2. Entregue
Tabela curta, da maior para a menor prioridade (impacto × risco ÷ esforço), no máximo 7 linhas:

| # | Melhoria | Evidência | Agent / skill | Esforço |
|---|---|---|---|---|

Depois: "Comece por: <item 1> com o `<agent>`." Pontos sem evidência ficam fora ou marcados "[verificar]".

## 3. Execute
- Siga para os itens indicados, delegando a cada agent objetivo, arquivos, restrições e critério de sucesso.
- Antes, peça confirmação só no que a regra exige (operação irreversível, credencial, dependência nova, mudança grande de arquitetura).
- Um agent por arquivo de cada vez; alteração de código não trivial passa pelo `reviewer` no fim.
