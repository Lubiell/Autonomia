---
name: pecas-graficas
description: Use para criar ou revisar peça gráfica — cartaz, etiqueta, folheto, post visual, banner — pelo conector do Canva ou à mão, ou montar o briefing para um designer, com checklist de design para quem não é designer e regras para peças de varejo.
---

# Peças gráficas

## Antes de criar: briefing
Transforme a ideia solta em briefing de uma tela, que serve para o Canva ou para mandar a um designer:
- **Peça e uso:** formato, medidas finais (mm ou px), onde vai (impresso, Instagram, WhatsApp) e sangria se for impressa.
- **Objetivo e público:** a única coisa que a pessoa deve fazer ou lembrar.
- **Texto final:** título, apoio, preço, chamada, contato e logo, já revisados. Texto final antes do layout.
- **Visual:** cores e fontes da marca (skill `marca`), referências que gosta e o que evitar.
- **Materiais e prazo:** fotos e logo em alta, quem aprova, data de entrega e quantidade impressa.
Faltando algo, pergunte só o essencial; o resto, assuma e marque como suposição.

## Caminho recomendado: conector do Canva
Em claude.ai → Configurações → Conectores → Canva → autorizar. Cria design, edita existente, busca na biblioteca, redimensiona e exporta conversando; funciona pelo app do celular. Veja se ele está conectado na sessão antes de pedir arquivo ao usuário.

- **Limites por plano:** redimensionar exige plano pago; autofill de template e Brand Kit exigem Canva Enterprise. Para lote sem Enterprise, use o **Bulk Create** com CSV dentro do próprio Canva.
- **O conector não** roda sozinho nem tem gatilho por evento, e interpreta a intenção: revise antes de publicar.
- **Connect API** (OAuth 2.0 com PKCE, jobs assíncronos, HTTP 429 com espera crescente) só vale para gerar peça em lote de forma programada.

## Checklist de design
- **Um ponto focal por peça.** Se tudo grita, nada é lido.
- **Hierarquia:** título grande, subtítulo médio, corpo pequeno.
- **Contraste:** claro contra escuro, grande contra pequeno. A chamada para ação é o elemento de maior contraste.
- **No máximo 2 ou 3 fontes; 4 a 6 cores**, uma dominante e o resto acento.
- **Espaço em branco é ativo:** separa e agrupa. Peça lotada é peça ilegível.
- **Alinhamento consistente** e o mesmo espaçamento entre blocos.

## Peças de varejo
- **Post:** uma mensagem só, headline curta, logo, chamada clara. Lote → Bulk Create com planilha. Texto da legenda: skill `conteudo`.
- **Cartaz de promoção:** preço enorme (é lido de longe), um produto, ação óbvia.
- **Etiqueta:** legível em tamanho pequeno, alto contraste, campos sempre na mesma posição.
- **Folheto:** seções com hierarquia clara, espaço em branco generoso, ícones do mesmo estilo.

Identidade (paleta, fontes, tom): skill `marca`.

## Regra que vale sempre
Peça com dado pessoal, documento ou nome de cliente não vai para nuvem de design nem para exemplo. Use dado fictício.
