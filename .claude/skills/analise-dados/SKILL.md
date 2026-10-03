---
name: analise-dados
description: Use ao analisar uma base de dados (CSV, planilha, tabela, query), montar ou revisar um dashboard, ou investigar por que um indicador mudou. Conduz definir → validar → investigar → priorizar → entregar, sem pular etapa e sem inventar número.
---

# Análise de dados e diagnóstico

Ordem fixa. Não avance sem o usuário confirmar a etapa anterior; se ele quiser pular, diga em que etapa estamos e pergunte se segue assim mesmo.

## 1. Definir — problema em número
- Reclamação ("a margem está ruim") não é problema. Problema tem número e período ("a margem caiu de 14% para 11,4% em 3 meses"). Sem número, pergunte qual dado mediria.
- Critério de resolvido: que número encerra o assunto.
- Escopo (o que entra, o que fica de fora, período), quem decide e o custo de não resolver.
- Devolva o enunciado em até 3 linhas para confirmação.

## 2. Validar — o dado e a métrica
- Qualidade, com quantas linhas cada problema afeta: duplicata, data como texto, categoria escrita de jeitos diferentes, código lido como número, espaço invisível, tipos misturados, total que não bate com a origem.
- Granularidade: o que uma linha representa. Níveis misturados (item e pedido) dobram somas.
- Cobertura: período, meses incompletos, até quando a base é confiável.
- Métrica: mede o que se quer ou um substituto? O denominador é o universo certo (margem ÷ receita, não ÷ custo)?
- Limpeza: mostre antes/depois e o de-para para aprovação. Não apague linha nem corrija valor incerto sem perguntar; preserve o original.

## 3. Investigar — causa com dado
- Distribua as hipóteses: método/regra de cálculo, sistema/carga, dado de origem, pessoas/processo, definição do indicador, ambiente (sazonalidade, mercado).
- Cada uma: CONFIRMADA, DESCARTADA ou PONTO CEGO (não há dado para avaliar), com o dado que sustenta.
- Na mais provável, pergunte "por quê?" até 5 vezes, com evidência em cada nível; sem dado, pare.
- Tendência ou sazonalidade: compare com o mesmo período de anos anteriores antes de concluir.
- Correlação não é causa: diga que outro fator explicaria.

## 4. Priorizar — onde está o efeito
- Quanto cada causa confirmada explica, em % e em valor; quantas somam 80%.
- 80/20 é padrão observado, não lei. Se o efeito estiver espalhado, diga isso: não há causa dominante e a estratégia muda.
- Recomende por onde começar e por que essa, não só a de maior impacto absoluto.

## 5. Entregar — uma página
1. Problema quantificado, com período.
2. Causa raiz, quanto explica e o dado que sustenta.
3. Ações por impacto ÷ esforço: o que muda, efeito esperado em número, como saber que funcionou, prazo.
4. Controle: indicador, faixas com o número de cada corte, frequência, responsável.
5. Pontos cegos: o que passar a medir e por quê.
6. O que invalidaria este diagnóstico.

Campo sem dado: "não é possível concluir com os dados disponíveis" e qual dado faltaria. Nunca invente para completar.

## Dashboard
- Antes do visual: público, decisão que a tela provoca e no máximo 5 indicadores. Cada KPI com numerador, denominador, filtros, exclusões e regra de data (competência ou caixa).
- Cor por regra: comparação mínima (meta, mês anterior, mesmo mês do ano anterior) e a partir de que desvio vira atenção ou alerta.
- Gráfico pela pergunta: série temporal para evolução, barras ordenadas para ranking, sem pizza nem rosca e sem enfeite. Destaque um elemento, o resto em cinza.
- Tela em blocos na ordem da leitura: o que aconteceu, onde, por quê, o que fazer. Título que conclui, não que só nomeia o assunto.
- Filtros atualizam tudo (KPIs, gráficos, alertas, tabela). Fonte, período e horário de atualização visíveis. Legível no celular.
- Antes de publicar: totais conciliados com a origem, metas e premissas fornecidas (não inventadas), hipótese separada de fato, nenhum dado pessoal ou restrito no arquivo.

## Atalhos por situação
- Painel novo: definir → validar (granularidade, cobertura, limpeza) → KPIs → visual → título e cartão de leitura.
- Painel existente: cortar indicadores sem decisão → poda visual → régua de cor → blocos → variação → ação.
- Antes de reunião: conferir totais → quebrar a variação → tendência ou sazonalidade → cartão de 3 linhas → as 5 perguntas mais difíceis do público.
- Número não bate: granularidade → inconsistências → definição do KPI → conciliação com a origem, só apontando, sem corrigir.
