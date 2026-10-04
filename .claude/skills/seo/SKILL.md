---
name: seo
description: Use ao criar, revisar ou publicar página ou site que precisa ser encontrado no Google — título e meta description, headings, URLs, imagens, sitemap, robots.txt, dados estruturados, compartilhamento em redes (Open Graph) e desempenho (Core Web Vitals).
---

# SEO de site

Revise no HTML real (arquivo ou página no ar), não de memória. Aponte cada problema com arquivo:linha ou URL e a correção.

## Por página
- **`<title>`** único, com o assunto principal no começo; em torno de 50–60 caracteres para não ser cortado.
- **`<meta name="description">`** única, que convide ao clique; em torno de 150–160 caracteres. O Google pode reescrever, mas usa como base.
- **Um `<h1>`** que diga o assunto da página; `h2`/`h3` em ordem, sem pular nível só pelo visual.
- **Texto:** responde à pergunta de quem buscou, com o termo que a pessoa usaria. Sem repetir palavra-chave à força.
- **URL** curta, legível, com hífen e minúsculas (`/servicos/limpeza-de-sofa`).
- **Imagens:** `alt` descrevendo a imagem (vazio só em imagem decorativa), `width`/`height` definidos, formato leve (WebP/AVIF), `loading="lazy"` abaixo da dobra.
- **Links internos** com texto que diga o destino (não "clique aqui"); nenhum link quebrado.
- **`<link rel="canonical">`** quando a mesma página tiver mais de um endereço.
- **`<html lang="pt-BR">`** e `<meta name="viewport" content="width=device-width, initial-scale=1">`.

## Compartilhamento
- Open Graph: `og:title`, `og:description`, `og:image` (1200×630 px), `og:url`, `og:type`. `twitter:card` = `summary_large_image`.

## Site inteiro
- `sitemap.xml` com as páginas indexáveis e `robots.txt` apontando para ele; nada importante bloqueado no `robots.txt`.
- HTTPS em tudo e redirecionamento único (http→https, com ou sem `www`, escolha um).
- Página 404 própria, que devolve status 404.
- Página que não deve aparecer no Google: `<meta name="robots" content="noindex">` (não só `robots.txt`).
- GitHub Pages em site de projeto: o endereço tem `/<repo>/`; confira canonical, sitemap e links com esse caminho.

## Dados estruturados
- JSON-LD no `<head>` quando couber: `Organization` ou `LocalBusiness` (nome, endereço, telefone, horário iguais aos do Perfil da Empresa no Google), `Product`, `FAQPage`, `Article`, `BreadcrumbList`. Só o que aparece de fato na página.
- Valide no Teste de Pesquisa Aprimorada do Google ou no validator.schema.org.

## Desempenho (Core Web Vitals)
- Metas do Google: LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1, medidas no percentil 75 das visitas reais, celular e desktop separados.
- Comuns: imagem grande sem compressão, fonte e script bloqueando a renderização, elemento sem tamanho que empurra o layout.
- Meça com o Lighthouse do Chrome (DevTools) ou o PageSpeed Insights na URL publicada.

## Depois de publicar
- Google Search Console: verificar o domínio, enviar o `sitemap.xml`, inspecionar a URL nova.
- Resultado de busca leva dias a semanas; não prometa posição.

## Entregar
Lista por prioridade (BLOQUEIA indexação → CORRIGIR → OPCIONAL), cada item com onde está e a correção pronta (trecho de HTML).
