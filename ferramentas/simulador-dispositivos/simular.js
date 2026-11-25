#!/usr/bin/env node
// Simulador de aparelhos: abre um site ou app web como se fosse celular,
// tablet e PC, tira print de cada um e aponta os problemas encontrados.
// Uso: node simular.js <url-ou-arquivo.html> [opções]  (veja --ajuda)
'use strict';

const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium, devices } = require('playwright');

const APARELHOS = {
  'android': { nome: 'Celular Android (Pixel 7)', base: devices['Pixel 7'] },
  'iphone': { nome: 'iPhone 13', base: devices['iPhone 13'] },
  'celular-pequeno': { nome: 'Celular pequeno (iPhone SE)', base: devices['iPhone SE'] },
  'tablet': { nome: 'Tablet (iPad Mini)', base: devices['iPad Mini'] },
  'notebook': { nome: 'PC notebook (1366x768)', base: { viewport: { width: 1366, height: 768 }, deviceScaleFactor: 1, isMobile: false, hasTouch: false } },
  'pc': { nome: 'PC monitor (1920x1080)', base: { viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1, isMobile: false, hasTouch: false } },
};

// Perfis de rede no formato do Chrome DevTools (bytes/s e ms).
const REDES = {
  normal: null,
  '4g': { latency: 70, downloadThroughput: (9 * 1024 * 1024) / 8, uploadThroughput: (9 * 1024 * 1024) / 8 },
  '3g': { latency: 300, downloadThroughput: (1.6 * 1024 * 1024) / 8, uploadThroughput: (750 * 1024) / 8 },
  offline: 'offline',
};

const AJUDA = `Uso: node simular.js <url-ou-arquivo.html> [opções]

Opções:
  --aparelhos=a,b   quais simular (padrão: todos): ${Object.keys(APARELHOS).join(', ')}
  --rede=TIPO       normal (padrão), 4g, 3g ou offline
  --escuro          liga o modo escuro do aparelho
  --deitado         celular e tablet na horizontal
  --gps=LAT,LON     localização simulada (padrão: -23.5505,-46.6333, São Paulo)
  --espera=MS       espera extra depois de carregar, em ms (padrão: 500)
  --saida=PASTA     onde salvar prints e relatório (padrão: ./resultado)
  --ajuda           mostra esta ajuda

Saída: 0 = nenhum problema; 1 = achou problema; 2 = erro de uso ou o site não abriu.`;

function lerArgs(argv) {
  const op = { alvo: null, aparelhos: Object.keys(APARELHOS), rede: 'normal', escuro: false, deitado: false,
    gps: { latitude: -23.5505, longitude: -46.6333 }, espera: 500, saida: path.resolve('resultado') };
  for (const arg of argv) {
    const [chave, ...resto] = arg.split('=');
    const valor = resto.join('=');
    if (chave === '--ajuda' || chave === '-h' || chave === '--help') { op.ajuda = true; }
    else if (chave === '--aparelhos') { op.aparelhos = valor.split(',').map((s) => s.trim()).filter(Boolean); }
    else if (chave === '--rede') { op.rede = valor; }
    else if (chave === '--escuro') { op.escuro = true; }
    else if (chave === '--deitado') { op.deitado = true; }
    else if (chave === '--gps') {
      const [lat, lon] = valor.split(',').map(Number);
      if (!Number.isFinite(lat) || !Number.isFinite(lon)) throw new Error(`--gps inválido: "${valor}" (use LAT,LON)`);
      op.gps = { latitude: lat, longitude: lon };
    }
    else if (chave === '--espera') {
      op.espera = Number(valor);
      if (!Number.isFinite(op.espera) || op.espera < 0) throw new Error(`--espera inválido: "${valor}"`);
    }
    else if (chave === '--saida') { op.saida = path.resolve(valor); }
    else if (chave.startsWith('--')) { throw new Error(`opção desconhecida: ${chave}`); }
    else if (!op.alvo) { op.alvo = arg; }
    else { throw new Error(`argumento a mais: ${arg}`); }
  }
  if (op.ajuda) return op;
  if (!op.alvo) throw new Error('informe a URL ou o arquivo .html');
  const desconhecidos = op.aparelhos.filter((a) => !APARELHOS[a]);
  if (desconhecidos.length || !op.aparelhos.length) throw new Error(`aparelho desconhecido: ${desconhecidos.join(', ') || '(vazio)'}`);
  if (!(op.rede in REDES)) throw new Error(`--rede inválida: "${op.rede}" (use ${Object.keys(REDES).join(', ')})`);
  return op;
}

function resolverAlvo(alvo) {
  if (/^https?:\/\//i.test(alvo) || /^file:\/\//i.test(alvo)) return alvo;
  const caminho = path.resolve(alvo);
  if (!fs.existsSync(caminho)) throw new Error(`arquivo não encontrado: ${alvo}`);
  const final = fs.statSync(caminho).isDirectory() ? path.join(caminho, 'index.html') : caminho;
  if (!fs.existsSync(final)) throw new Error(`pasta sem index.html: ${alvo}`);
  return pathToFileURL(final).href;
}

async function simularAparelho(navegador, id, url, op) {
  const { nome, base } = APARELHOS[id];
  const config = { ...base };
  delete config.defaultBrowserType; // tudo roda no Chromium; ver README
  if (op.deitado && config.isMobile) {
    config.viewport = { width: base.viewport.height, height: base.viewport.width };
    if (base.screen) config.screen = { width: base.screen.height, height: base.screen.width };
  }
  const contexto = await navegador.newContext({
    ...config,
    locale: 'pt-BR',
    timezoneId: 'America/Sao_Paulo',
    colorScheme: op.escuro ? 'dark' : 'light',
    geolocation: op.gps,
    permissions: ['geolocation', 'notifications'],
  });
  const pagina = await contexto.newPage();
  const problemas = [];
  const avisos = [];

  pagina.on('console', (msg) => {
    if (msg.type() === 'error') problemas.push(`Erro no console: ${msg.text()}`);
  });
  pagina.on('pageerror', (erro) => problemas.push(`Erro de JavaScript: ${erro.message}`));
  pagina.on('requestfailed', (req) => {
    if (op.rede === 'offline') return; // offline é esperado falhar
    problemas.push(`Falhou ao carregar: ${req.url()} (${req.failure()?.errorText || 'erro'})`);
  });
  pagina.on('response', (resp) => {
    if (resp.status() >= 400) problemas.push(`Resposta ${resp.status()}: ${resp.url()}`);
  });

  const rede = REDES[op.rede];
  if (rede && rede !== 'offline') {
    const cdp = await contexto.newCDPSession(pagina);
    await cdp.send('Network.enable');
    await cdp.send('Network.emulateNetworkConditions', { offline: false, ...rede });
  }

  const inicio = Date.now();
  try {
    await pagina.goto(url, { waitUntil: 'load', timeout: 60000 });
  } catch (erro) {
    problemas.push(`Página não abriu: ${erro.message.split('\n')[0]}`);
  }
  const carregou = Date.now() - inicio;
  // Offline: depois da primeira carga, corta a rede e recarrega, como
  // quem perde o sinal com o app aberto.
  if (rede === 'offline') {
    await contexto.setOffline(true);
    try {
      await pagina.reload({ waitUntil: 'load', timeout: 15000 });
      avisos.push('Sem rede: a página recarregou (tem cache ou é arquivo local).');
    } catch {
      avisos.push('Sem rede: a página não recarrega offline (normal em site sem service worker).');
    }
  }
  await pagina.waitForTimeout(op.espera);

  const medidas = await pagina.evaluate(() => {
    const largura = document.documentElement.clientWidth;
    const doc = document.documentElement;
    const larguraConteudo = Math.max(doc.scrollWidth, document.body ? document.body.scrollWidth : 0);
    const viewport = document.querySelector('meta[name="viewport"]');
    const pequenos = [];
    for (const el of document.querySelectorAll('a, button, input, select, textarea, [role="button"]')) {
      const r = el.getBoundingClientRect();
      const visivel = r.width > 0 && r.height > 0 && getComputedStyle(el).visibility !== 'hidden';
      if (visivel && (r.width < 24 || r.height < 24) && el.type !== 'hidden') {
        pequenos.push((el.innerText || el.getAttribute('aria-label') || el.tagName).trim().slice(0, 40));
      }
    }
    return { largura, larguraConteudo, temViewport: !!viewport, pequenos: pequenos.slice(0, 5), totalPequenos: pequenos.length };
  }).catch(() => null);

  if (medidas) {
    if (medidas.larguraConteudo > medidas.largura + 1) {
      problemas.push(`Conteúdo mais largo que a tela (${medidas.larguraConteudo}px numa tela de ${medidas.largura}px): aparece rolagem para o lado.`);
    }
    if (config.isMobile && !medidas.temViewport) {
      problemas.push('Falta <meta name="viewport">: no celular o site aparece miniaturizado.');
    }
    if (config.hasTouch && medidas.totalPequenos) {
      avisos.push(`${medidas.totalPequenos} botão(ões)/link(s) menor(es) que 24px, difícil de tocar: ${medidas.pequenos.join(' | ')}`);
    }
  }
  if (op.rede !== 'offline' && carregou > 5000) avisos.push(`Demorou ${(carregou / 1000).toFixed(1)} s para carregar.`);

  const print = path.join(op.saida, `${id}.png`);
  await pagina.screenshot({ path: print, fullPage: true }).catch((e) => problemas.push(`Não tirou print: ${e.message}`));
  await contexto.close();

  return { id, nome, largura: config.viewport.width, altura: config.viewport.height, carregouMs: carregou,
    print: path.basename(print), problemas: [...new Set(problemas)], avisos };
}

function montarRelatorio(url, op, resultados) {
  const linhas = [`# Simulação de aparelhos`, '', `- Endereço: ${url}`,
    `- Rede: ${op.rede}${op.escuro ? ' · modo escuro' : ''}${op.deitado ? ' · deitado' : ''}`,
    `- GPS: ${op.gps.latitude}, ${op.gps.longitude}`, '',
    '| Aparelho | Tela | Carregou | Problemas | Avisos |', '|---|---|---|---|---|'];
  for (const r of resultados) {
    linhas.push(`| ${r.nome} | ${r.largura}x${r.altura} | ${(r.carregouMs / 1000).toFixed(1)} s | ${r.problemas.length} | ${r.avisos.length} |`);
  }
  for (const r of resultados) {
    linhas.push('', `## ${r.nome}`, '', `Print: ${r.print}`);
    if (!r.problemas.length && !r.avisos.length) linhas.push('', 'Nenhum problema encontrado.');
    for (const p of r.problemas) linhas.push(`- ❌ ${p}`);
    for (const a of r.avisos) linhas.push(`- ⚠️ ${a}`);
  }
  return linhas.join('\n') + '\n';
}

async function main() {
  let op;
  let url;
  try {
    op = lerArgs(process.argv.slice(2));
    if (op.ajuda) { console.log(AJUDA); return 0; }
    url = resolverAlvo(op.alvo);
  } catch (erro) {
    console.error(`Erro: ${erro.message}\n\n${AJUDA}`);
    return 2;
  }
  fs.mkdirSync(op.saida, { recursive: true });
  const navegador = await chromium.launch();
  const resultados = [];
  try {
    for (const id of op.aparelhos) {
      process.stdout.write(`Simulando ${APARELHOS[id].nome}... `);
      const r = await simularAparelho(navegador, id, url, op);
      console.log(r.problemas.length ? `${r.problemas.length} problema(s)` : 'ok');
      resultados.push(r);
    }
  } finally {
    await navegador.close();
  }
  fs.writeFileSync(path.join(op.saida, 'relatorio.md'), montarRelatorio(url, op, resultados));
  fs.writeFileSync(path.join(op.saida, 'relatorio.json'), JSON.stringify({ url, opcoes: { ...op, saida: undefined }, resultados }, null, 2));
  console.log(`\nRelatório e prints em: ${op.saida}`);
  if (resultados.every((r) => r.problemas.some((p) => p.startsWith('Página não abriu')))) return 2;
  return resultados.some((r) => r.problemas.length) ? 1 : 0;
}

main().then((codigo) => { process.exitCode = codigo; }, (erro) => { console.error(erro); process.exitCode = 2; });
