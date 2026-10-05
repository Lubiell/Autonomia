---
name: discover-resources
description: Use quando a tarefa exigir uma capacidade que o projeto não tem e for preciso avaliar Skill, Plugin, MCP, biblioteca, ferramenta ou repositório GitHub antes de instalar.
---

# Descoberta de Recursos

Use quando a tarefa exigir uma capacidade que o projeto ainda não possui.

## Processo
1. Leia `decisoes.md`: o recurso pode já ter sido adotado ou recusado. Recusa só se reverte com motivo novo.
2. Verifique Skills, Plugins, Agents, MCPs e ferramentas já disponíveis.
3. Procure documentação oficial.
4. Procure o repositório oficial no GitHub.
5. Compare alternativas.
6. Audite com o checklist de `auditoria.md`: procedência, licença, scripts, hooks,
   permissões e acesso a secrets. Sinal de risco sem explicação: não instala.
7. Prefira recursos oficiais e maduros.
8. Prefira instalação local, versionada e reproduzível.
9. Apresente custo/benefício (inclusive o custo de contexto por turno) e peça confirmação antes de instalar.
10. Teste a integração.
11. Registre em `decisoes.md` o recurso, a origem, a versão e o motivo, adotado ou recusado.

## Bloqueios
Nunca execute cegamente instaladores ou scripts desconhecidos
(`curl | sh`, binários de origem não verificada).
Para auditoria de segurança do recurso, delegue ao agent `security`.
