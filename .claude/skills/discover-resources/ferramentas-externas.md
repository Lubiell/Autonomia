# Ferramentas externas — quando cada uma serve

Programas que rodam **fora** do agente. O Autonomia não os executa: diz quando cada um serve, como instalar e o que fazer quando não dá. Antes de instalar qualquer um, `auditoria.md`; a decisão fica em `decisoes.md`.

## Automação de navegador — `browser-use`
MIT, ativo. Agente que controla o navegador por linguagem natural. `pip install browser-use` e `playwright install chromium`; exige Python 3.11+.

- **Usar:** site que muda de layout, ou fluxo exploratório em que o seletor quebra toda hora.
- **Não usar:** rotina diária. Playwright puro ganha — é determinístico, dá para ler e depurar. Agente que "decide" o clique falha diferente a cada execução.
- **Padrão:** Playwright (skill `automacao`). `browser-use` é exceção.

## Automação de processo — `n8n`
Fluxo entre sistemas (recebeu pedido → dá baixa → manda mensagem), no PC ou em nuvem.

- **Papel do Claude:** escrever o que conversa com ele — Worker que recebe o webhook, script que chama a API, validação do payload. O fluxo em si se monta na tela do n8n.
- **Usar:** ligar sistemas que já existem.
- **Não usar:** lógica de negócio. Regra em fluxo visual não se versiona, não se testa e não se revisa; regra vai para código.

## Frameworks de agente — `CrewAI`, `LangGraph`
Bibliotecas Python para **construir** sistemas multiagente.

- **Usar:** só se o projeto for construir um agente próprio; aí é código normal, com teste e revisão.
- **Não usar:** para melhorar o trabalho do dia a dia. Não é ferramenta que se instala e passa a ajudar — é uma camada que se assume manter (dependência pesada, API que muda rápido).

## Agentes de código alternativos — `Aider`, `OpenHands`
Agentes completos, com o próprio ciclo de editar e commitar; rodam **ao lado**, nunca dentro.

- **Faz sentido:** trabalho em lote não supervisionado, ou provedor diferente.
- **Custo:** as regras do Autonomia não valem dentro deles. Recomendação: um agente principal; alternar por tarefa fragmenta histórico e método.

## Geração de imagem — `Fooocus`
GPL-3.0, Stable Diffusion local, **exige GPU dedicada**, sem atualização recente. Sem GPU não roda — não é questão de configurar melhor. Alternativa sem instalar nada: Canva (skill `pecas-graficas`) ou serviço de geração (skill `prompts-ia`).

## Catálogo de MCP — `awesome-mcp-servers`
MIT. Lista de servidores MCP, não software. Faltou conector para um sistema: consulte antes de escrever integração do zero. Presença na lista não é aval — cada servidor passa pela `auditoria.md`.

## Não usar — `claude-task-master`
Fatia tarefas a partir de um documento de requisitos: colide com a skill `spec` e a `plano` (duas camadas decidindo o mesmo). Licença NOASSERTION.

## Regra geral
Ferramenta externa entra quando resolve um problema que o Autonomia tem **e não resolve com o que já existe**. Uma por vez, usada por uma semana, decisão registrada com o motivo.
