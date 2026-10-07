# Auditoria antes de instalar

Skill instalada tem a autoridade de uma instrução do sistema; hook e script rodam com as permissões do usuário. Instalar é dar acesso à máquina. Vale também "só para testar".

## Checagem rápida
1. **Procedência:** mantenedor identificável, commits recentes e licença explícita. Faltou um dos três, não instala. Licença `NOASSERTION` conta como ausente.
2. **Idade e movimento:** repositório recente, sem histórico e com muitas skills de uma vez é sinal de conteúdo gerado em massa.
3. **Tamanho:** coleção de centenas de skills traz gatilhos sobrepostos e custo de `description` em toda requisição.
4. **Ler o `SKILL.md` inteiro**, não só a descrição.
5. **Listar e ler cada executável:** `find . -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.ps1' \)`.

## Varredura automática (primeira triagem)
`NVIDIA/SkillSpector` (Apache-2.0) faz análise estática de uma skill, pasta, zip ou repositório. Exige Python 3.12+; rode isolado, sem instalar no sistema, fixando o commit auditado:

```bash
uvx --python 3.12 --from git+https://github.com/NVIDIA/SkillSpector@3c8e4b9 skillspector scan ./pasta-da-skill --no-llm
```

Leia cada achado antes de decidir: no modo `--no-llm` há muito falso positivo. Em 2026-10-07, nas skills do Autonomia, ele marcou como "não instalar" a própria `discover-resources` por citar `curl | sh` e `mimikatz` como coisas a evitar, e comentários HTML de exemplo como "instrução escondida". Varredura limpa não dispensa os passos acima.

## Sinais nos scripts
Achou algum, não instala até saber para onde vai e levando o quê:

| Sinal | Risco |
|---|---|
| `curl`, `wget`, `requests.post`, `socket`, `Invoke-WebRequest` | envio de dado para fora |
| `eval`, `exec`, `compile`, `__import__`, `Invoke-Expression` | código montado em tempo de execução |
| `base64`, `chr()` encadeado, hex longo | ofuscação |
| leitura de `~/.ssh`, `~/.aws`, `.env`, variáveis de ambiente | coleta de credencial |
| `os.system`, `subprocess(shell=True)`, crase | injeção de comando |
| escrita fora da própria pasta, em `.bashrc` ou `settings.json` | persistência |
| `sudo`, `chmod 777`, cron, tarefa agendada | escalada de privilégio |
| `--dangerously-skip-permissions`, `bypassPermissions` | desliga as defesas |

Rede sozinha nem sempre é ataque (cache de documentação usa `curl`). Se a leitura não responder destino e conteúdo, não instala.

## Sinais no markdown
- Mandar ignorar regras anteriores ou o system prompt.
- Texto escondido: comentário HTML, caractere de largura zero.
- Ler arquivo fora do escopo ou enviar conteúdo para algum lugar.
- Pedir permissão maior do que a função justifica.

## Hooks
- Hook roda sozinho; `SessionStart` dispara ao abrir o projeto, antes de qualquer pedido.
- Repositório clonado pode trazer `.claude/` com hooks: ler o `settings.json` dele antes de abrir o projeto no Claude Code.
- Plugin que injeta texto em toda sessão (SessionStart, pós-compactação) cobra contexto para sempre.

## Depois de instalar
- Observar a primeira invocação numa sessão nova.
- Conferir se surgiu arquivo fora da pasta do recurso.
- Sem uso há duas semanas: desinstalar e registrar em `decisoes.md`.
