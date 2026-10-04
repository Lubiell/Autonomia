---
name: api-backend
description: Use ao criar ou revisar API, endpoint, rota de servidor, Worker, Cloud Function ou webhook — contrato e status HTTP, validação de entrada, autenticação e autorização, CORS, limites, erros, segredos e testes.
---

# API e backend

## Contrato
- Recursos com substantivo no plural (`/pedidos/123`); método pelo efeito: `GET` lê, `POST` cria, `PUT`/`PATCH` altera, `DELETE` remove. `GET` nunca altera dado.
- Status certo: 200, 201 (criado), 204 (sem corpo), 400 (entrada inválida), 401 (sem login), 403 (sem permissão), 404, 409 (conflito), 422 (regra de negócio), 429 (limite), 500.
- Erro sempre no mesmo formato JSON, por exemplo `{"erro": "codigo", "mensagem": "texto para humano"}`, sem stack trace nem detalhe interno.
- Listas paginadas (`limit` + cursor ou página), com limite máximo.

## Entrada
- Valide tudo no servidor: tipo, tamanho, formato, faixa. O front pode ser burlado.
- Rejeite campo desconhecido onde importar (ex.: `role` enviado pelo cliente).
- Upload: limite de tamanho e tipo conferido pelo conteúdo, não só pela extensão.

## Acesso
- Autenticação: token no cabeçalho `Authorization`, cookie com `HttpOnly`, `Secure` e `SameSite`. Senha só como hash (bcrypt, scrypt ou argon2).
- Autorização em cada rota e cada recurso: o usuário só lê e altera o que é dele (trocar o id na URL não pode abrir dado de outro).
- CORS: só as origens que precisam; nunca `*` em rota que usa credencial.
- Limite de requisições em login, cadastro, envio de e-mail e rotas caras.

## Integrações
- Chamada externa com timeout e nova tentativa limitada, com espera crescente.
- Webhook: confira a assinatura do provedor antes de processar; trate evento repetido sem duplicar (idempotência).
- Pagamento e criação sensível: chave de idempotência para clique duplo não cobrar duas vezes.

## Segredos e logs
- Segredo em variável de ambiente ou secret da plataforma (`wrangler secret put`, secrets do Firebase/GitHub), nunca no código nem no front.
- Log com data, rota, status e duração; sem senha, token, cartão ou dado pessoal.

## Testes por rota
Caminho feliz, entrada inválida (400/422), sem login (401), recurso de outro usuário (403/404). Use o agent `tester`.

Referência para aprofundar: OWASP Cheat Sheet Series (cheatsheetseries.owasp.org) e OWASP API Security Top 10. Antes de publicar, peça a auditoria do agent `security`.
