---
name: banco-dados
description: Use ao modelar tabelas ou coleções, escrever migração, query ou índice, ou mexer em regras de acesso — SQLite/Cloudflare D1, PostgreSQL, MySQL, Firestore. Cobre integridade, desempenho, SQL injection, backup e LGPD.
---

# Banco de dados

## Modelagem
- Chave primária em toda tabela; chave estrangeira onde há relação, com a ação de exclusão pensada (`RESTRICT`, `CASCADE`, `SET NULL`).
- Tipos certos: dinheiro em centavos inteiros ou `DECIMAL`, nunca ponto flutuante; datas em ISO 8601 e UTC; booleano como booleano (ou 0/1 no SQLite).
- `NOT NULL`, `UNIQUE` e `CHECK` para regra que o dado precisa cumprir: o banco garante melhor que o código.
- Índice para o que aparece em `WHERE`, `JOIN` e `ORDER BY` frequentes; não indexe tudo (cada índice pesa na escrita).
- SQLite local: chave estrangeira só vale com `PRAGMA foreign_keys = ON` em cada conexão; no D1 já vem ativa.

## Migração
- Versionada no repositório, uma mudança por arquivo, aplicada primeiro em local/teste.
- Backup antes de aplicar em produção (D1: `npx wrangler d1 export <banco> --remote --output=backup.sql`).
- Mudança destrutiva em etapas: cria a coluna nova → preenche → código passa a usar → remove a antiga depois.
- Nunca `DELETE`/`UPDATE` sem `WHERE`; rode antes o `SELECT` com o mesmo `WHERE` e confira a contagem.

## Query
- Sempre parametrizada (`?`, `$1`, bind do ORM). Concatenar texto do usuário na SQL é SQL injection.
- Só as colunas usadas, com `LIMIT`/paginação em listas.
- N+1 (uma query por item num laço): troque por `JOIN` ou `IN (...)`.
- Lenta: `EXPLAIN` (ou `EXPLAIN QUERY PLAN` no SQLite) antes de mexer.
- Várias escritas que precisam acontecer juntas: transação (D1: `batch`).

## Firestore
- Regras de segurança: nunca `allow read, write: if true` em produção; cada regra checa `request.auth` e o dono do documento.
- Modele pelas consultas que o app faz; consulta com filtro e ordenação em campos diferentes pede índice composto.
- Cada leitura custa: evite ler a coleção inteira para contar ou filtrar no cliente.

## Dados pessoais (LGPD)
- Guarde só o necessário; acesso restrito; nada de dado pessoal em log, exemplo ou commit.
- Senha só como hash (bcrypt, scrypt ou argon2), nunca texto puro nem criptografia reversível.

## Restauração
Backup que nunca foi restaurado não é backup: teste restaurar numa base de teste.
