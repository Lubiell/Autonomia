---
name: trafego-pago
description: Use ao planejar, montar, analisar ou otimizar campanha de anúncios — Meta Ads (Instagram/Facebook), Google Ads, TikTok Ads — rastreamento e UTM, estrutura, públicos, orçamento, testes, métricas (CTR, CPC, CPA, ROAS) e relatório.
---

# Tráfego pago

## Antes de gastar
- Objetivo de negócio → evento que a campanha vai otimizar (compra, lead, mensagem). Otimize pelo que gera dinheiro, não por clique, quando houver volume.
- Rastreamento testado: Pixel e API de Conversões da Meta, tag do Google/GA4, eventos disparando com valor. Sem isso, a análise é chute.
- UTM em todo link (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`), padronizadas.
- Conta: CPA máximo = quanto pode custar uma venda e ainda dar lucro (lucro bruto por venda). Defina antes.

## Estrutura
- Campanha (objetivo) → conjunto/grupo (público, orçamento, posicionamento) → anúncio (criativo).
- Teste uma variável por vez (criativo, público ou oferta) e dê tempo e verba para concluir.
- Meta: o conjunto sai da fase de aprendizado com cerca de 50 eventos de otimização em 7 dias desde a última edição significativa, segundo a Meta. Mudar público, criativo ou evento de otimização, pausar, ou alterar muito orçamento ou lance reinicia a fase. Evite mexer todo dia.
- Criativo costuma pesar mais que segmentação: tenha variações de gancho e formato. Para escrever, use a skill `conteudo`.

## Métricas
- CTR = cliques ÷ impressões; CPC = gasto ÷ cliques; CPM = gasto ÷ mil impressões.
- Taxa de conversão = conversões ÷ cliques (ou visitas); CPA = gasto ÷ conversões; ROAS = receita ÷ gasto.
- Frequência alta com CTR caindo = criativo saturado.
- Diagnóstico pelo funil: CTR baixo → criativo/público; CTR bom e conversão baixa → página, oferta ou rastreamento.

## Análise
- Compare períodos iguais e com verba parecida; não conclua com poucos dados.
- Cada plataforma atribui conversão do seu jeito: não some as conversões da Meta, do Google e do GA4; use uma fonte de verdade.
- Planilha ou exportação grande: use a skill `analise-dados` ou o agent `data-analyst`.

## Políticas e lei
- Meta: proibido sugerir atributo pessoal do público ("Você está endividado?"); categorias especiais (crédito, emprego, moradia, política, saúde) têm restrições de segmentação.
- Sem promessa de ganho garantido, antes/depois enganoso ou urgência falsa (políticas das plataformas e Código de Defesa do Consumidor).
- LGPD: banner de consentimento de cookies onde o rastreamento exige; lista de clientes para público só com base legal.

## Relatório
Gasto, resultado, CPA, ROAS e variação contra o período anterior; o que foi testado e o que se aprendeu; próximo teste e por quê. Número sem dado: "não medido", nunca estimado sem avisar.
