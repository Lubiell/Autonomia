// Testes do ferramentas/simulador-dispositivos/simular.js.
// Rodar: node --test tests/simulador.test.js  (precisa do Playwright e do Chromium)
'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PASTA = path.join(__dirname, '..', 'ferramentas', 'simulador-dispositivos');
const SCRIPT = path.join(PASTA, 'simular.js');

function rodar(args) {
  const saida = fs.mkdtempSync(path.join(os.tmpdir(), 'simulador-'));
  const r = spawnSync(process.execPath, [SCRIPT, ...args, `--saida=${saida}`], { encoding: 'utf8', cwd: PASTA, timeout: 120000 });
  const json = path.join(saida, 'relatorio.json');
  const relatorio = fs.existsSync(json) ? JSON.parse(fs.readFileSync(json, 'utf8')) : null;
  return { codigo: r.status, texto: r.stdout + r.stderr, relatorio, saida };
}

test('site responsivo passa em todos os aparelhos e gera prints', () => {
  const r = rodar(['exemplos/site-ok.html']);
  assert.strictEqual(r.codigo, 0, r.texto);
  assert.strictEqual(r.relatorio.resultados.length, 6);
  for (const a of r.relatorio.resultados) {
    assert.deepStrictEqual(a.problemas, [], a.nome);
    assert.ok(fs.statSync(path.join(r.saida, a.print)).size > 0, `print de ${a.nome}`);
  }
  assert.ok(fs.existsSync(path.join(r.saida, 'relatorio.md')));
});

test('site com problemas: rolagem lateral só no celular, erros em todos', () => {
  const r = rodar(['exemplos/site-com-problemas.html', '--aparelhos=iphone,pc']);
  assert.strictEqual(r.codigo, 1, r.texto);
  const [iphone, pc] = r.relatorio.resultados;
  const tem = (a, trecho) => a.problemas.some((p) => p.includes(trecho));
  assert.ok(tem(iphone, 'mais largo que a tela'), 'iphone deveria ter rolagem lateral');
  assert.ok(!tem(pc, 'mais largo que a tela'), 'pc não deveria ter rolagem lateral');
  for (const a of [iphone, pc]) {
    assert.ok(tem(a, 'funcaoQueNaoExiste'), `${a.nome}: erro de JavaScript`);
    assert.ok(tem(a, 'imagem-que-nao-existe.png'), `${a.nome}: imagem quebrada`);
  }
  assert.ok(iphone.avisos.some((a) => a.includes('difícil de tocar')), 'iphone: botão pequeno');
});

test('falta de meta viewport é apontada no celular', () => {
  const pasta = fs.mkdtempSync(path.join(os.tmpdir(), 'simulador-pag-'));
  const arquivo = path.join(pasta, 'index.html');
  fs.writeFileSync(arquivo, '<!doctype html><html><body><p>oi</p></body></html>');
  const r = rodar([pasta, '--aparelhos=android,notebook']);
  assert.strictEqual(r.codigo, 1, r.texto);
  const [android, notebook] = r.relatorio.resultados;
  assert.ok(android.problemas.some((p) => p.includes('viewport')));
  assert.deepStrictEqual(notebook.problemas, []);
});

test('opções: deitado inverte a tela, rede offline e modo escuro rodam', () => {
  const r = rodar(['exemplos/site-ok.html', '--aparelhos=iphone', '--deitado', '--escuro', '--rede=offline', '--gps=-22.9,-43.2']);
  assert.strictEqual(r.codigo, 0, r.texto);
  const [a] = r.relatorio.resultados;
  assert.ok(a.largura > a.altura, `deitado: ${a.largura}x${a.altura}`);
  assert.ok(a.avisos.some((x) => x.startsWith('Sem rede')));
  assert.deepStrictEqual(r.relatorio.opcoes.gps, { latitude: -22.9, longitude: -43.2 });
});

test('erros de uso saem com código 2', () => {
  assert.strictEqual(rodar([]).codigo, 2);
  assert.strictEqual(rodar(['exemplos/site-ok.html', '--aparelhos=nokia']).codigo, 2);
  assert.strictEqual(rodar(['exemplos/site-ok.html', '--rede=5g']).codigo, 2);
  assert.strictEqual(rodar(['nao-existe.html']).codigo, 2);
  assert.strictEqual(rodar(['exemplos/site-ok.html', '--gps=abc']).codigo, 2);
});
