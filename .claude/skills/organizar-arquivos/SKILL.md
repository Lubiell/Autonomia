---
name: organizar-arquivos
description: Use para arrumar uma pasta bagunçada no PC ou no celular — renomear em lote, separar por tipo, data ou assunto, achar duplicados, converter formatos (imagem, PDF, planilha) e liberar espaço. Mostra o plano antes, não apaga nada e deixa como desfazer.
---

# Organizar arquivos

Regra de ouro: **nada some**. Mover e renomear, sim; apagar, nunca. Duplicados e lixo vão para uma pasta `_revisar/`, e quem apaga é o usuário.

## 1. Levantar
Liste a pasta por script, sem abrir os arquivos: quantidade por extensão, tamanho total, mais antigos e mais novos, nomes repetidos. No Windows, PowerShell; no celular, Termux; no Linux e macOS, shell. Pasta grande: resumo, nunca a lista inteira.

## 2. Propor o plano
Mostre em tabela a estrutura nova (ex.: `Documentos/2026/`, `Fotos/2026-10/`, `Notas fiscais/`), a regra de nome (ex.: `AAAA-MM-DD_assunto.ext`, sem acento nem espaço) e quantos arquivos vão para cada lugar. Espere o ok.

## 3. Executar com volta
- Gere o script e rode primeiro em modo de simulação, que só imprime o que faria.
- Ao executar de verdade, grave um registro `organizacao-<data>.csv` com caminho antigo e novo; o mesmo script desfaz lendo esse arquivo.
- Nome que já existe no destino: acrescente `_2`, nunca sobrescreva.
- Duplicados: compare por hash (conteúdo), não pelo nome; mova as cópias para `_revisar/duplicados/`.

## 4. Converter
Imagem e vídeo com a skill `midia`; PDF com a skill de conta `pdf`; planilha com `xlsx`. Converta para uma cópia e mantenha o original até o usuário conferir.

## 5. Conferir
Conte os arquivos antes e depois (precisa bater), mostre o espaço liberado e onde ficou o registro para desfazer.

## Limites
Não mexa em pasta do sistema, de programa instalado, de nuvem sincronizando (OneDrive, Google Drive) sem avisar, nem em arquivo aberto. Documento pessoal (RG, exame, extrato) fica onde está, só renomeado, e não sai do computador.
