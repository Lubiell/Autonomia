---
name: livros
description: Indica livros de programação por tema e nível, priorizando os gratuitos e legais (do autor ou da editora).
argument-hint: "[tema e nível, ex.: python iniciante]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, pergunte em uma linha o tema e o nível (iniciante, intermediário, avançado).

Indique de 2 a 5 livros da lista abaixo, na ordem de leitura, com uma linha de por que cada um e o link. Gratuito primeiro; pago só quando nenhum gratuito cobre. Livro fora da lista: confirme com o agent `researcher` que ele existe e que a versão gratuita é do autor ou da editora. Nunca indique PDF pirata nem site de download não oficial.

## Gratuitos (lidos online, versão oficial)
| Livro | Tema e nível | Link |
|---|---|---|
| *Pense em Python*, Allen Downey (2ª ed., em português, Novatec, CC BY-NC) | Python, iniciante | https://penseallen.github.io/PensePython2e/ |
| *Think Python*, Allen Downey (3ª ed., em inglês, notebooks no Colab) | Python, iniciante | https://allendowney.github.io/ThinkPython/ |
| *Automate the Boring Stuff with Python*, Al Sweigart (3ª ed.) | Python para automatizar planilha, arquivo e web, iniciante | https://automatetheboringstuff.com/ |
| Tutorial oficial do Python (em português) | Python, iniciante a intermediário | https://docs.python.org/pt-br/3/tutorial/ |
| *Eloquent JavaScript*, Marijn Haverbeke (4ª ed., 2024) | JavaScript, iniciante a intermediário | https://eloquentjavascript.net/ |
| *You Don't Know JS Yet*, Kyle Simpson | JavaScript a fundo, intermediário | https://github.com/getify/You-Dont-Know-JS |
| MDN — Aprender desenvolvimento web (em português) | HTML, CSS e JavaScript, iniciante | https://developer.mozilla.org/pt-BR/docs/Learn |
| *Pro Git*, Scott Chacon e Ben Straub (2ª ed., em português) | Git, iniciante a avançado | https://git-scm.com/book/pt-br/v2 |
| *The Linux Command Line*, William Shotts | terminal e shell (vale para o Termux), iniciante | https://linuxcommand.org/tlcl.php |
| SQLBolt (tutorial interativo, no navegador) | SQL, iniciante | https://sqlbolt.com/ |
| Tutorial oficial do PostgreSQL | SQL e banco relacional, iniciante a intermediário | https://www.postgresql.org/docs/current/tutorial.html |
| *SQL Performance Explained* (versão web *Use The Index, Luke*), Markus Winand | SQL e índices, intermediário | https://use-the-index-luke.com/ |
| *High Performance Browser Networking*, Ilya Grigorik | rede e desempenho web, intermediário | https://hpbn.co/ |
| *Structure and Interpretation of Computer Programs* (edição em JavaScript) | fundamentos de computação, intermediário a avançado | https://sicp.sourceacademy.org/ |
| *Composing Programs*, John DeNero | fundamentos com Python (baseado no SICP), intermediário | https://www.composingprograms.com/ |
| *Crafting Interpreters*, Robert Nystrom | como linguagens funcionam por dentro, avançado | https://craftinginterpreters.com/ |
| *Operating Systems: Three Easy Pieces*, Remzi e Andrea Arpaci-Dusseau | sistemas operacionais, avançado | https://pages.cs.wisc.edu/~remzi/OSTEP/ |
| *Software Engineering at Google*, Winters, Manshreck e Wright | engenharia em equipe: revisão, testes, dependências, avançado | https://abseil.io/resources/swe-book |
| *Site Reliability Engineering* e *The Site Reliability Workbook* (Google) | operação, monitoramento e incidentes, avançado | https://sre.google/books/ |

## Pagos (clássicos; as regras já estão nos agents)
| Livro | Para quê | Onde está no Autonomia |
|---|---|---|
| *The Pragmatic Programmer*, Hunt e Thomas (2ª ed., 2019) | hábitos de quem programa bem | `debugger`, `architect` |
| *Refactoring*, Martin Fowler (2ª ed., 2018) | melhorar código sem quebrar | `reviewer`, `/refatorar` |
| *A Philosophy of Software Design*, John Ousterhout | reduzir complexidade no projeto | `architect`, `reviewer` |
| *Debugging: The 9 Indispensable Rules*, David Agans | achar bug com método | `debugger` |
| *Working Effectively with Legacy Code*, Michael Feathers | mexer em código sem teste | `architect`, `/refatorar` |
| *Test-Driven Development: By Example*, Kent Beck | testes primeiro | `tester` |
| *Designing Data-Intensive Applications*, Martin Kleppmann | bancos, filas e sistemas distribuídos | — |

Links conferidos em 2026-10-18. Link fora do ar: avise e procure o endereço novo no site do autor.

Responda em português do Brasil.
