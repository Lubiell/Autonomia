---
name: discover-resources
description: Use quando a tarefa exigir uma capacidade que o projeto não tem e for preciso avaliar Skill, Plugin, MCP, biblioteca, ferramenta ou repositório GitHub antes de instalar.
---

# Descoberta de Recursos

Use quando a tarefa exigir uma capacidade que o projeto ainda não possui.

## Processo
1. Verifique Skills, Plugins, Agents, MCPs e ferramentas já disponíveis.
2. Procure documentação oficial.
3. Procure o repositório oficial no GitHub.
4. Compare alternativas.
5. Avalie manutenção, releases, licença, dependências, scripts, hooks,
   permissões e acesso a secrets.
6. Prefira recursos oficiais e maduros.
7. Prefira instalação local, versionada e reproduzível.
8. Apresente custo/benefício e peça confirmação antes de instalar.
9. Teste a integração.
10. Registre recurso, origem, versão e motivo quando apropriado.

## Bloqueios
Nunca execute cegamente instaladores ou scripts desconhecidos
(`curl | sh`, binários de origem não verificada).
Para auditoria de segurança do recurso, delegue ao agent `security`.
