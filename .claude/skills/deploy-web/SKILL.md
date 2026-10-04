---
name: deploy-web
description: Use antes de publicar um site ou API — GitHub Pages, Cloudflare Pages/Workers/D1, Firebase Hosting ou similar — para conferir build, segredos, migração de banco, plano de volta e o site no ar depois do deploy.
---

# Deploy de site e API

Publicar é ação externa: confirme com o usuário antes do comando que publica, salvo autorização explícita para aquele deploy.

## Antes
1. Build e testes do projeto passando na mesma versão que vai subir (`git status` limpo, commit identificado).
2. Nenhum segredo no que vai ao ar: `.env`, chave de API no JavaScript do navegador, token em arquivo estático. Chave usada no navegador é pública por definição; o que precisa ser secreto fica no servidor (variável de ambiente ou secret da plataforma).
3. Configuração do ambiente certo: URL da API, domínio, variáveis de produção, não de teste.
4. Plano de volta definido antes: qual versão restaurar e como.
5. Banco: migração revisada, com backup antes de aplicar em produção. Nunca `DELETE`/`UPDATE` sem `WHERE`.

## Por plataforma
- **GitHub Pages:** confira a origem (branch ou GitHub Actions). Em site de projeto o endereço tem `/<repo>/`: caminhos absolutos (`/css/x.css`) quebram; use relativos ou a base certa. Página 404 própria, se houver.
- **Cloudflare Pages:** `npx wrangler pages deploy <pasta>`; teste antes na URL de preview que o deploy devolve.
- **Cloudflare Workers:** `npx wrangler deploy`; segredos com `npx wrangler secret put NOME`, nunca no `wrangler.toml`. Para voltar: `npx wrangler rollback` (volta o código; dados de D1/KV não voltam junto).
- **Cloudflare D1:** backup com `npx wrangler d1 export <banco> --remote --output=backup.sql`; migração com `npx wrangler d1 migrations apply <banco> --remote`, depois de aplicar em `--local` e conferir.
- **Firebase Hosting:** preview com `firebase hosting:channel:deploy <nome>`; produção com `firebase deploy --only hosting`. Regras do Firestore/Storage revisadas se mudaram: regra aberta é dado exposto.

## Depois
1. Abra a URL de produção de verdade (não o localhost): página carrega, sem erro no console, recursos sem 404, HTTPS ativo.
2. Teste o fluxo principal que a mudança tocou. Para teste mais completo, use o agent `qa-web`.
3. Cache: se o usuário vê a versão antiga, confira cache do navegador e da CDN antes de mexer no código.
4. Deu errado: volte para a versão anterior primeiro, investigue depois.

Relate: o que subiu (commit), onde (URL), o que foi conferido no ar e o que não foi.
