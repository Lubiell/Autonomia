---
name: apis-gratuitas
description: Use quando um site, planilha, automação ou app precisar de dado externo grátis — CEP e endereço, CNPJ, feriados, câmbio, Selic e índices do Banco Central, clima, tabela FIPE, dados do IBGE, produto por código de barras, QR code, resumo da Wikipédia. Lista APIs públicas sem chave, testadas, com o link e o cuidado de cada uma.
---

# APIs gratuitas

Fonte: `public-apis/public-apis` (commit `339ab55`, 2026-10-21; 2.167 APIs, 976 sem chave e com HTTPS), filtrado para o que serve aos projetos do usuário e testado em 2026-10-23. APIs mudam: antes de usar, faça uma chamada de teste e leia os termos (limite de uso, uso comercial).

## Testadas e funcionando (2026-10-23)
| Dado | API | Exemplo de chamada | Cuidado |
|---|---|---|---|
| CEP → endereço | ViaCEP | `https://viacep.com.br/ws/01001000/json/` | CEP inexistente volta `{"erro": true}`, não 404 |
| CEP, CNPJ, feriados, bancos, DDD, FIPE e mais | BrasilAPI | `https://brasilapi.com.br/api/cep/v1/01001000` · `/api/cnpj/v1/{cnpj}` · `/api/feriados/v1/2026` | Comunitária, sem garantia; em produção tenha um plano B (ex.: ViaCEP) |
| Selic, IPCA, dólar PTAX e outras séries | Banco Central (SGS) | `https://api.bcb.gov.br/dados/serie/bcdata.sgs.11/dados/ultimos/1?formato=json` | Código da série no portal de dados abertos do BCB; Selic diária = 11 |
| Câmbio (dólar, euro → real) | Frankfurter | `https://api.frankfurter.dev/v1/latest?from=USD&to=BRL` | Taxa de referência do BCE, uma por dia útil; o domínio antigo `.app` redireciona |
| Feriados de 90+ países | Nager.Date | `https://date.nager.at/api/v3/PublicHolidays/2026/BR` | Só nacionais; feriado municipal não vem |
| Tabela FIPE (marcas, modelos, preço) | Parallelum FIPE | `https://parallelum.com.br/fipe/api/v1/carros/marcas` | Não oficial; confira o preço no site da FIPE antes de decisão com dinheiro |
| Produto por código de barras (alimentos) | Open Food Facts | `https://world.openfoodfacts.org/api/v2/product/{ean}.json` | Base colaborativa; produto pode faltar ou estar incompleto |
| Resumo de um assunto | Wikipédia | `https://pt.wikipedia.org/api/rest_v1/page/summary/{título}` | Mande um `User-Agent` identificando o app |

## Na lista, mas não confirmadas daqui
- **IBGE** (`servicodados.ibge.gov.br/api/docs`): municípios, estados, nomes, agregados. A conexão não completou neste ambiente; teste da sua máquina.
- **Open-Meteo** (`open-meteo.com`): previsão do tempo sem chave, só para uso **não comercial**. A conexão não completou neste ambiente.
- **AwesomeAPI de moedas** (`economia.awesomeapi.com.br`): a lista diz "sem limite", mas o teste devolveu 429 (cota excedida). Prefira Frankfurter ou BCB.
- **ReceitaWS** (CNPJ): limite baixo de consultas por minuto no plano grátis; para volume, BrasilAPI.
- **QR code** (`goqr.me/api`) e **GeraCódigo** (código de barras EAN-13, QR): geram imagem por URL. Não mande dado pessoal na URL.

## Regras ao usar
- Chame do servidor ou com cache quando o dado não muda a cada segundo (CEP, feriado, FIPE); respeite o limite de uso.
- Trate falha: timeout curto, mensagem clara ao usuário e plano B. API grátis cai sem aviso.
- Dado pessoal (CPF, nome de cliente) não vai para API de terceiro sem base legal; veja a skill `lgpd`. API que devolve dado de pessoa física a partir do CPF: não use.
- Precisando de chave de API: guarde em variável de ambiente ou segredo, nunca no código ou no front (veja `api-backend`).
- Dado que decide dinheiro, imposto ou saúde: confirme na fonte oficial e cite com a data.
