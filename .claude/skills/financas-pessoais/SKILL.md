---
name: financas-pessoais
description: Use para dinheiro da pessoa física no Brasil — orçamento do mês, controle de gastos, reserva de emergência, dívidas e cartão, empréstimo, metas, investimento básico (Tesouro, CDB, poupança), aposentadoria e Imposto de Renda pessoa física. Faz as contas por planilha e mostra a fórmula; não substitui planejador financeiro.
---

# Finanças pessoais

Orienta e faz contas; não recomenda produto financeiro específico nem promete rendimento. Decisão com dinheiro é do usuário. Dado financeiro dele não vai para repositório público nem para fora da tarefa.

## Ordem de prioridade
1. **Saber para onde vai o dinheiro:** um mês de gastos em planilha (skill `xlsx`), por categoria: moradia, alimentação, transporte, saúde, dívidas, lazer, outros. Some entradas e saídas; o saldo é o ponto de partida.
2. **Parar de pagar juro alto:** cartão rotativo e cheque especial primeiro. Liste cada dívida com saldo, juro ao mês e parcela; quite ou renegocie da maior taxa para a menor. Troca de dívida cara por mais barata (consignado, portabilidade) só com o Custo Efetivo Total (CET) na mão.
3. **Reserva de emergência:** alguns meses do gasto essencial, em aplicação com liquidez diária e baixo risco. O tamanho depende da estabilidade da renda (autônomo precisa de mais); mostre a conta com o gasto real dele.
4. **Metas com prazo:** valor, data e quanto guardar por mês. Prazo curto pede aplicação de baixo risco.
5. **Longo prazo e aposentadoria:** só depois dos passos acima.

## Contas (sempre por planilha ou script, com a fórmula)
- Juros compostos: `VF = VP × (1 + i)^n`; converta taxa anual em mensal por `(1 + a)^(1/12) − 1`.
- Rendimento real: desconte inflação, imposto e taxas. Compare aplicações pelo líquido, não pelo bruto.
- Parcelado x à vista: traga as parcelas a valor presente pela taxa que o dinheiro renderia.

## Investimento básico
Explique risco, liquidez, garantia (FGC para CDB e poupança, dentro do limite vigente) e imposto (tabela regressiva de IR em renda fixa; LCI/LCA isentas para pessoa física). Taxas, limites e alíquotas mudam: busque a fonte oficial (Tesouro Direto, Banco Central, Receita Federal, FGC) e cite com a data. Sem fonte, marque [CONFERIR].

## Imposto de Renda pessoa física
Prazo, obrigatoriedade, faixas e deduções mudam todo ano: consulte gov.br/receitafederal e cite o ano-base. Ajude a organizar informes de rendimento, recibos médicos e de educação. MEI declara a pessoa física à parte; o lado da empresa fica com a skill `mei-impostos`.

## Limites
Não indique ação, fundo ou criptomoeda específicos, nem "onde investir" como certeza. Golpe com promessa de ganho garantido: alerte e use a skill `seguranca-digital`. Situação de superendividamento: indique o Procon e a renegociação pela Lei do Superendividamento (Lei 14.181/2021).
