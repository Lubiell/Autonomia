# Simulador de aparelhos (celular, tablet e PC)

Abre um site ou app web como se fosse **celular Android, iPhone, celular pequeno, tablet, notebook e monitor de PC**, tira um print de cada um e aponta o que quebrou. Serve para testar antes de publicar, sem precisar ter os aparelhos.

## O que ele simula
- **Tela** de cada aparelho (tamanho, densidade de pixels), **toque** e navegador de celular.
- **Celular deitado** (`--deitado`).
- **GPS**: o site recebe uma localização falsa (padrão: São Paulo), já com permissão dada.
- **Notificações**: permissão já concedida.
- **Rede**: normal, 4G, 3G lento ou sem sinal (`--rede`).
- **Modo escuro** do aparelho (`--escuro`).
- Idioma **pt-BR** e fuso de **São Paulo**.

## O que ele aponta
- ❌ Erro de JavaScript e erro no console.
- ❌ Imagem, script ou arquivo que não carregou (404, 500, arquivo faltando).
- ❌ Conteúdo mais largo que a tela (aparece rolagem para o lado no celular).
- ❌ Falta da tag `<meta name="viewport">` (site miniaturizado no celular).
- ⚠️ Botão ou link menor que 24 px, difícil de tocar.
- ⚠️ Página que demora mais de 5 s para carregar.
- ⚠️ Comportamento sem rede.

Saída: `0` = nada errado, `1` = achou problema, `2` = erro de uso ou o site não abriu. Dá para usar no CI.

## Limites (leia antes)
- Tudo roda no **Chromium**. O perfil "iPhone" imita a tela e o toque do iPhone, mas **não é o Safari de verdade**: diferenças do motor do Safari não aparecem.
- Simula **site e app web**. Não roda APK de Android nem programa de Windows; para isso é preciso um emulador real (Android Studio no PC) ou um runner do GitHub Actions com o sistema.
- Câmera, microfone, SMS, bateria e sensores não são simulados.

## Instalar (uma vez)
Precisa do Node.js 18 ou mais novo.

No PC (Windows, Mac ou Linux), dentro desta pasta:

```bash
npm ci
```

```bash
npx playwright install chromium
```

No Linux, se faltar biblioteca do sistema, troque o segundo comando por `npx playwright install --with-deps chromium`.

No celular Android (Termux) o Playwright não tem navegador próprio; rode no PC ou peça para o Claude rodar na nuvem.

## Usar

Um arquivo local:

```bash
node simular.js exemplos/site-com-problemas.html
```

Um site no ar, só celulares, rede 3G e modo escuro:

```bash
node simular.js https://exemplo.com.br --aparelhos=android,iphone,celular-pequeno --rede=3g --escuro
```

Uma pasta com `index.html` também serve. Veja todas as opções com `node simular.js --ajuda`.

Aparelhos: `android`, `iphone`, `celular-pequeno`, `tablet`, `notebook`, `pc`.

O resultado fica em `resultado/` (ou na pasta de `--saida`):
- `relatorio.md`: tabela por aparelho e a lista de problemas;
- `relatorio.json`: o mesmo, para outro programa ler;
- um print `.png` da página inteira por aparelho.

## Exemplos
- `exemplos/site-ok.html`: página responsiva, passa em todos os aparelhos.
- `exemplos/site-com-problemas.html`: faixa larga demais, imagem quebrada, erro de JavaScript e link pequeno, para ver o relatório em ação.

## Teste
Da raiz do repositório:

```bash
node --test tests/simulador.test.js
```
