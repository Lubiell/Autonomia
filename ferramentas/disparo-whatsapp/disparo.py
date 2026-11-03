#!/usr/bin/env python3
"""Envia foto e texto pelo WhatsApp, via servidor OpenWA, para quem autorizou receber.

Um contato por vez, com intervalo aleatório, limite diário, parada após falhas seguidas
e registro em CSV para retomar sem repetir envio. Sem --enviar, só simula.
Só biblioteca padrão do Python 3.8+. Veja o README.md desta pasta.
"""
import argparse
import base64
import csv
import io
import datetime as dt
import json
import mimetypes
import os
import random
import socket
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

RODAPE = "Responda SAIR para não receber mais."
# Não tenta de novo em outra rodada. "incerto" = o envio pode ter saído (timeout, 5xx,
# resposta estranha): melhor conferir à mão do que mandar duas vezes.
STATUS_FINAIS = {"enviado", "nao_existe", "incerto"}
CONTA_NO_LIMITE = {"enviado", "incerto"}
CAMPOS_LOG = ["telefone", "status", "horario", "detalhe"]
MAX_FALHAS_SEGUIDAS = 3
NEGATIVOS = {"nao", "não", "n", "0", "false", "no", "recusou"}
esperar = time.sleep  # trocado nos testes


class ErroOpenWA(Exception):
    def __init__(self, msg, incerto=False):
        super().__init__(msg)
        self.incerto = incerto  # True: o servidor pode ter recebido e enviado a mensagem


class ClienteOpenWA:
    """Chamadas REST do OpenWA usadas aqui (cabeçalho X-API-Key, erro = status fora de 2xx)."""

    def __init__(self, url, sessao, chave, timeout=30):
        self.base = url.rstrip("/") + "/api/sessions/" + urllib.parse.quote(sessao, safe="")
        self.chave = chave
        self.timeout = timeout

    def _req(self, metodo, caminho, corpo=None):
        dados = json.dumps(corpo).encode() if corpo is not None else None
        req = urllib.request.Request(self.base + caminho, data=dados, method=metodo)
        req.add_header("X-API-Key", self.chave)
        if dados is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as r:
                bruto = r.read()
        except urllib.error.HTTPError as e:
            texto = e.read().decode(errors="replace")[:300]
            if e.code in (401, 403):
                raise ErroOpenWA(f"chave recusada (HTTP {e.code}); confira OPENWA_API_KEY") from None
            raise ErroOpenWA(f"HTTP {e.code}: {texto}", incerto=e.code >= 500) from None
        except (urllib.error.URLError, OSError) as e:
            motivo = getattr(e, "reason", e)
            if isinstance(motivo, (TimeoutError, socket.timeout)) or isinstance(e, (TimeoutError, socket.timeout)):
                raise ErroOpenWA(f"sem resposta do OpenWA em {self.timeout}s", incerto=True) from None
            raise ErroOpenWA(f"sem conexão com o OpenWA ({motivo}); o servidor está ligado?") from None
        try:
            dados = json.loads(bruto) if bruto else {}
        except ValueError:
            raise ErroOpenWA("resposta do OpenWA não é JSON: " + bruto[:100].decode(errors="replace"),
                             incerto=True) from None
        if not isinstance(dados, dict):
            raise ErroOpenWA("resposta inesperada do OpenWA: " + str(dados)[:100], incerto=True)
        return dados

    def checar(self, numero):
        return self._req("GET", "/contacts/check/" + urllib.parse.quote(numero, safe=""))

    def enviar_texto(self, chat_id, texto):
        return self._req("POST", "/messages/send-text", {"chatId": chat_id, "text": texto})

    def enviar_imagem(self, chat_id, imagem, legenda):
        return self._req("POST", "/messages/send-image", dict(imagem, chatId=chat_id, caption=legenda))


def normalizar(telefone):
    """Devolve 55DDDNUMERO (12 ou 13 dígitos) ou None se não parecer telefone do Brasil."""
    d = "".join(c for c in str(telefone) if c.isdigit()).lstrip("0")
    if len(d) in (10, 11):
        d = "55" + d
    if len(d) in (12, 13) and d.startswith("55"):
        return d
    return None


def montar_texto(modelo, nome):
    texto = modelo.replace("{{nome}}", (nome or "").strip()).strip()
    if "SAIR" not in texto.upper():
        texto += "\n\n" + RODAPE
    return texto


def carregar_campanha(caminho):
    with open(caminho, encoding="utf-8") as f:
        c = json.load(f)
    if not str(c.get("texto", "")).strip():
        raise SystemExit("campanha: falta o campo 'texto'")
    if c.get("imagem") and c.get("imagem_url"):
        raise SystemExit("campanha: use 'imagem' (arquivo) ou 'imagem_url' (link), não os dois")
    imagem = None
    if c.get("imagem_url"):
        imagem = {"url": c["imagem_url"]}
    elif c.get("imagem"):
        arq = c["imagem"]
        if not os.path.isabs(arq):
            arq = os.path.join(os.path.dirname(os.path.abspath(caminho)), arq)
        try:
            with open(arq, "rb") as f:
                conteudo = f.read()
        except OSError:
            raise SystemExit(f"campanha: não achei a foto {arq}") from None
        imagem = {
            "base64": base64.b64encode(conteudo).decode(),
            "mimetype": mimetypes.guess_type(arq)[0] or "image/jpeg",
            "filename": os.path.basename(arq),
        }
    return c["texto"], imagem


def chave(numero):
    """Identidade do telefone que ignora o nono dígito: 55 + DDD + últimos 8 dígitos."""
    return numero[:4] + numero[-8:]


def ler_texto(caminho):
    """Lê arquivo de texto em UTF-8 (com ou sem BOM) ou, se falhar, cp1252 (CSV antigo do Excel)."""
    with open(caminho, "rb") as f:
        bruto = f.read()
    try:
        return bruto.decode("utf-8-sig")
    except UnicodeDecodeError:
        return bruto.decode("cp1252", errors="replace")


def ler_csv(caminho):
    texto = ler_texto(caminho)
    amostra = texto[:2048]
    sep = ";" if amostra.count(";") > amostra.count(",") else ","  # Excel em pt-BR salva com ;
    return [{(k or "").strip().lower(): (v or "").strip() for k, v in linha.items()}
            for linha in csv.DictReader(io.StringIO(texto, newline=""), delimiter=sep)]


def carregar_descadastro(caminho):
    """Devolve as chaves dos números que pediram para sair, ou None se o arquivo não existe."""
    if not caminho or not os.path.exists(caminho):
        return None
    saida = set()
    for linha in ler_texto(caminho).splitlines():
        n = normalizar(linha.replace(";", ",").split(",")[0])
        if n:
            saida.add(chave(n))
    return saida


def carregar_log(caminho):
    """Devolve (chaves dos números com status final, quantos envios contam no limite de hoje)."""
    finais, hoje = set(), 0
    if not os.path.exists(caminho) or os.path.getsize(caminho) == 0:
        return finais, hoje
    linhas = ler_csv(caminho)
    if linhas and not set(CAMPOS_LOG) <= set(linhas[0]):
        raise SystemExit(f"registro {caminho}: colunas inesperadas ({', '.join(linhas[0])}). "
                         "Não abra/salve este arquivo no Excel; restaure o original antes de continuar.")
    data = dt.date.today().isoformat()
    for linha in linhas:
        numero = normalizar(linha["telefone"])
        if numero and linha["status"] in STATUS_FINAIS:
            finais.add(chave(numero))
        if linha["status"] in CONTA_NO_LIMITE and linha["horario"].startswith(data):
            hoje += 1
    return finais, hoje


class Registro:
    def __init__(self, caminho):
        novo = not os.path.exists(caminho) or os.path.getsize(caminho) == 0
        self.f = open(caminho, "a", encoding="utf-8", newline="")
        self.w = csv.DictWriter(self.f, fieldnames=CAMPOS_LOG)
        if novo:
            self.w.writeheader()

    def __call__(self, telefone, status, detalhe=""):
        self.w.writerow({"telefone": telefone, "status": status,
                         "horario": dt.datetime.now().isoformat(timespec="seconds"), "detalhe": detalhe})
        self.f.flush()  # cada linha vai para o disco: Ctrl+C não perde o que já foi enviado

    def close(self):
        self.f.close()


def enviar_um(cliente, numero, texto, imagem):
    """Confere o número no WhatsApp e envia. Devolve (status, detalhe)."""
    try:
        info = cliente.checar(numero)
    except ErroOpenWA as e:
        raise ErroOpenWA(str(e)) from None  # falhou antes de enviar: pode tentar de novo
    if not info.get("exists"):
        return "nao_existe", ""
    chat_id = info.get("whatsappId") or numero + "@c.us"
    if imagem:
        r = cliente.enviar_imagem(chat_id, imagem, texto)
    else:
        r = cliente.enviar_texto(chat_id, texto)
    return "enviado", str(r.get("messageId", ""))


def disparar(contatos, modelo, imagem, cliente, registro, descadastro, finais, enviados_hoje,
             limite_dia, intervalo, enviar, saida=print):
    """Percorre os contatos. Devolve um dicionário com a contagem de cada resultado."""
    cont = {}
    vistos = set()
    falhas = 0
    primeiro = True

    def marcar(chave):
        cont[chave] = cont.get(chave, 0) + 1

    for c in contatos:
        bruto = c.get("telefone", "")
        numero = normalizar(bruto)
        if not numero:
            marcar("invalido")
            saida(f"pulado (telefone inválido): {bruto!r}")
            continue
        k = chave(numero)
        if k in vistos:
            marcar("repetido")
            continue
        vistos.add(k)
        consentimento = c.get("consentimento", "")
        if not consentimento or consentimento.strip().lower() in NEGATIVOS:
            marcar("sem_consentimento")
            saida(f"pulado (sem consentimento): {numero}")
            continue
        if k in descadastro:
            marcar("descadastrado")
            continue
        if k in finais:
            marcar("ja_feito")
            continue
        if enviados_hoje >= limite_dia:
            saida(f"limite diário de {limite_dia} atingido; rode de novo amanhã para continuar")
            marcar("limite")
            break
        texto = montar_texto(modelo, c.get("nome"))
        if not enviar:
            marcar("simulado")
            enviados_hoje += 1
            saida(f"[simulação] enviaria para {numero}: {texto.splitlines()[0][:60]}")
            continue
        if not primeiro:
            esperar(random.uniform(*intervalo))
        primeiro = False
        try:
            status, detalhe = enviar_um(cliente, numero, texto, imagem)
            falhas = 0
        except ErroOpenWA as e:
            status, detalhe = ("incerto" if e.incerto else "erro"), str(e)
            falhas += 1
        registro(numero, status, detalhe)
        marcar(status)
        if status in CONTA_NO_LIMITE:
            enviados_hoje += 1
        if status == "incerto":
            saida(f"  confira no WhatsApp se {numero} recebeu; não será reenviado automaticamente")
        saida(f"{status}: {numero} {detalhe}".rstrip())
        if falhas >= MAX_FALHAS_SEGUIDAS:
            saida(f"parado: {MAX_FALHAS_SEGUIDAS} falhas seguidas. Último erro: {detalhe}")
            marcar("parado")
            break
    return cont


def faixa(texto):
    try:
        a, b = (float(x) for x in texto.split("-"))
    except ValueError:
        raise argparse.ArgumentTypeError("use MIN-MAX em segundos, ex.: 20-60") from None
    if a < 0 or b < a:
        raise argparse.ArgumentTypeError("MIN-MAX inválido")
    return a, b


def main(argv=None):
    p = argparse.ArgumentParser(description="Disparo de WhatsApp (foto + texto) via OpenWA.")
    p.add_argument("--contatos", default="contatos.csv", help="CSV com telefone,nome,consentimento")
    p.add_argument("--campanha", default="campanha.json", help="JSON com texto e imagem ou imagem_url")
    p.add_argument("--descadastro", default="descadastro.csv", help="números que pediram para sair")
    p.add_argument("--log", default="envios.csv", help="registro de envios (usado para retomar)")
    p.add_argument("--url", default=os.environ.get("OPENWA_URL", "http://localhost:2785"))
    p.add_argument("--sessao", default=os.environ.get("OPENWA_SESSAO"), help="id da sessão no OpenWA")
    p.add_argument("--limite-dia", type=int, default=50, help="máximo de envios por dia (padrão 50)")
    p.add_argument("--intervalo", type=faixa, default=(20.0, 60.0), help="espera entre envios, MIN-MAX s")
    p.add_argument("--enviar", action="store_true", help="envia de verdade (sem isto, só simula)")
    p.add_argument("--teste", metavar="NUMERO", help="manda só para este número e sai")
    a = p.parse_args(argv)

    modelo, imagem = carregar_campanha(a.campanha)
    precisa_servidor = a.enviar or a.teste
    chave = os.environ.get("OPENWA_API_KEY", "")
    if precisa_servidor and (not chave or not a.sessao):
        raise SystemExit("defina OPENWA_API_KEY e OPENWA_SESSAO (ou --sessao) antes de enviar")
    cliente = ClienteOpenWA(a.url, a.sessao or "", chave)

    if a.teste:
        numero = normalizar(a.teste)
        if not numero:
            raise SystemExit(f"número de teste inválido: {a.teste}")
        try:
            status, detalhe = enviar_um(cliente, numero, montar_texto(modelo, "Teste"), imagem)
        except ErroOpenWA as e:
            raise SystemExit(f"erro: {e}") from None
        print(f"{status}: {numero} {detalhe}".rstrip())
        return 0 if status == "enviado" else 1

    contatos = ler_csv(a.contatos)
    if contatos and "telefone" not in contatos[0]:
        raise SystemExit("contatos: falta a coluna 'telefone' (colunas: telefone,nome,consentimento)")
    finais, hoje = carregar_log(a.log)
    descadastro = carregar_descadastro(a.descadastro)
    if descadastro is None:
        print(f"AVISO: {a.descadastro} não encontrado; ninguém está marcado como descadastrado.")
        descadastro = set()
    registro = Registro(a.log) if a.enviar else (lambda *x, **k: None)
    if not a.enviar:
        print("SIMULAÇÃO: nada será enviado. Para enviar de verdade, acrescente --enviar.")
    try:
        cont = disparar(contatos, modelo, imagem, cliente, registro, descadastro,
                        finais, hoje, a.limite_dia, a.intervalo, a.enviar)
    except KeyboardInterrupt:
        print("\ninterrompido; o que já foi enviado está no registro e não será repetido")
        return 130
    finally:
        if a.enviar:
            registro.close()
    print("resumo:", ", ".join(f"{k}={v}" for k, v in sorted(cont.items())) or "nada a fazer")
    return 1 if cont.get("parado") else 0


if __name__ == "__main__":
    sys.exit(main())
