# Spec — Plataforma de atendimento por WhatsApp para farmácias (MVP)
Data: 2026-11-04
Status: **aguardando ok do usuário**

## Problema
O usuário quer oferecer a drogarias uma plataforma de atendimento por WhatsApp no estilo da grupounicocontato.com.br. A plataforma teria:
- atendimento com várias pessoas e filas por filial;
- chatbot;
- funil de recompra;
- integração com ERP;
- relatórios;
- API oficial da Meta.

Hoje não existe nada disso, e o produto inteiro levaria meses. É preciso escolher o caminho e cortar um MVP que dê para testar com uma farmácia piloto.

## Alternativas consideradas
| | Custo | Prazo do MVP | Risco |
|---|---|---|---|
| **A) Base aberta ([Chatwoot](https://github.com/chatwoot/chatwoot), MIT) + conector próprio para farmácia** | VPS ~R$ 60–150/mês [Provável] + domínio | 2–4 semanas | Depende das atualizações do Chatwoot; os recursos pagos dele (IA "Captain", SLA) não entram |
| B) Tudo do zero: caixa de entrada, filas, usuários, permissões, relatórios e app | Igual ou maior | 3–6 meses | Alto: reconstrói o que já existe pronto antes de validar se alguém compra |
| C) Revender uma plataforma pronta (white-label) | Mensalidade do fornecedor | Dias | Margem menor; o produto e o cliente ficam na mão do fornecedor |

**Escolha recomendada: A.** O Chatwoot já tem caixa de entrada com WhatsApp Cloud API, vários atendentes, times e filas, etiquetas, ficha do contato, automações, relatórios e app de celular. O esforço vai só no que é de farmácia. A API oficial é obrigatória aqui: cliente não oficial (como o OpenWA da ferramenta de disparo) põe o número da farmácia em risco de ban, e isso não é aceitável num serviço vendido para terceiros.

## Solução (MVP)
1. **Servidor:** Chatwoot self-hosted em Docker numa VPS **no Brasil**, com HTTPS, backup diário criptografado do Postgres e uma conta Chatwoot por rede de farmácias, para separar os dados de cada cliente.
2. **WhatsApp:** uma caixa de entrada por número, via Cloud API. A conta Meta (WABA) é **da farmácia**, que paga as mensagens dela direto à Meta. Respostas dentro da janela de 24 h são grátis. Mensagem iniciada pela empresa é cobrada por modelo (*template*): marketing ~US$ 0,06 e utilidade ~US$ 0,007 no Brasil [Provável; conferir na tabela oficial antes de orçar].
3. **Conector próprio** (serviço pequeno, em Python como o resto do kit), ligado como *Agent Bot* do Chatwoot:
   - dá boas-vindas e pergunta a filial e o assunto (orçamento, entrega, outro);
   - manda a conversa para o time certo (filial e setor) e passa para um humano;
   - fora do horário, responde com o horário de funcionamento.
4. **Painel:** o próprio Chatwoot, no navegador e no app, mais os relatórios nativos (tempo de primeira resposta, volume por time).

## Fora de escopo (MVP)
- **Leitura de receita por foto (OCR/IA).** É dado sensível de saúde (LGPD, art. 11) e exige um cuidado próprio; fica para uma spec separada.
- **Atendente com IA** respondendo sozinho.
- **Funil de recompra e lembretes.** Saber que alguém compra remédio de uso contínuo é dado de saúde, e cada lembrete é um template pago; fica para a fase 2.
- **Integração com ERP, estoque e preço**, catálogo ou loja no WhatsApp, disparo de marketing.
- **Venda de medicamento controlado pelo bot.** A venda remota segue a RDC 44/2009 e é responsabilidade da farmácia. Para controlados, a regra é controversa, então o bot não oferece nem orienta.
- **Cobrança do seu cliente**, landing page e marca.
- Copiar marca, textos, depoimentos ou números de terceiros.

## Onde fica o código
Em um repositório novo do produto (por exemplo `lubiell/farma-atende`), criado pelo usuário e anexado à sessão. Esta spec fica aqui até lá.

## Arquivos afetados (no repositório novo)
- `docker-compose.yml`, `.env.example` (sem segredo) e `docs/instalacao.md`: subir o Chatwoot.
- `conector/`: Agent Bot (webhook com validação de assinatura, roteamento, horário) e os testes dele.
- `.github/workflows/test.yml`: CI.
- `docs/lgpd.md`: modelo de contrato de operador, prazo de retenção e procedimento em caso de incidente.

## Como saber que deu certo
- Os testes do conector passam localmente e no CI e cobrem estes casos:
  - escolha da filial leva ao time certo;
  - mensagem fora do horário recebe o horário de funcionamento;
  - assunto não reconhecido vai para um humano;
  - webhook sem assinatura válida é recusado.
- **Piloto com uma farmácia e duas filiais:**
  1. uma mensagem real chega no número oficial;
  2. o bot pergunta a filial;
  3. a conversa aparece na fila daquela filial;
  4. o balconista responde pelo app;
  5. o relatório mostra o tempo de primeira resposta.

## Pré-requisitos (fora do código)
- Verificação da empresa no Meta Business. Pode levar de dias a semanas.
- Um número que ainda não esteja preso a outra API.
- Contrato com a farmácia piloto. A farmácia é a **controladora** dos dados e você é o **operador**, e as conversas podem conter dado de saúde.

## Risco e volta atrás
- **Vazamento de conversa com dado de saúde.** É o maior risco. Para reduzir: HTTPS, contas separadas por cliente, acesso com 2FA, backup criptografado e nenhum dado de produção no repositório.
- **Atraso na verificação da Meta:** atrasa o piloto, não o código.
- **Atualização do Chatwoot que quebra o conector:** fixar a versão da imagem e travar o contrato do webhook com testes.
- **Para reverter:** desligar o Agent Bot (o Chatwoot segue funcionando sem ele). Em último caso, apagar a VPS. O número pode sair da Cloud API e voltar ao app WhatsApp Business.
