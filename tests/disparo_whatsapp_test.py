"""Testes do ferramentas/disparo-whatsapp/disparo.py contra um OpenWA falso local.

Rodar: python3 tests/disparo_whatsapp_test.py
"""
import base64
import contextlib
import csv
import io
import json
import os
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "ferramentas", "disparo-whatsapp"))
import disparo  # noqa: E402

CHAVE = "chave-de-teste"


class FalsoOpenWA(BaseHTTPRequestHandler):
    pedidos = []
    inexistentes = set()
    falhar_envio = False
    falhar_check = False
    resposta_invalida = False

    def log_message(self, *a):
        pass

    def _responder(self, codigo, corpo):
        dados = json.dumps(corpo).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(dados)))
        self.end_headers()
        self.wfile.write(dados)

    def _registrar(self):
        n = int(self.headers.get("Content-Length") or 0)
        corpo = json.loads(self.rfile.read(n)) if n else None
        FalsoOpenWA.pedidos.append((self.command, self.path, corpo))
        return self.headers.get("X-API-Key") == CHAVE

    def do_GET(self):
        if not self._registrar():
            return self._responder(401, {"message": "Unauthorized"})
        if FalsoOpenWA.falhar_check:
            return self._responder(503, {"message": "engine down"})
        pre = "/api/sessions/s1/contacts/check/"
        if self.path.startswith(pre):
            num = self.path[len(pre):]
            existe = num not in FalsoOpenWA.inexistentes
            return self._responder(200, {"number": num, "exists": existe,
                                         "whatsappId": num + "@c.us" if existe else None})
        self._responder(404, {"message": "not found"})

    def do_POST(self):
        if not self._registrar():
            return self._responder(401, {"message": "Unauthorized"})
        if FalsoOpenWA.falhar_envio:
            return self._responder(500, {"message": "engine down"})
        if FalsoOpenWA.resposta_invalida:
            self.send_response(200)
            self.send_header("Content-Length", "2")
            self.end_headers()
            return self.wfile.write(b"ok")
        if self.path in ("/api/sessions/s1/messages/send-text", "/api/sessions/s1/messages/send-image"):
            return self._responder(201, {"messageId": "msg-%d" % len(FalsoOpenWA.pedidos), "timestamp": 1})
        self._responder(404, {"message": "not found"})


class Base(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv = HTTPServer(("127.0.0.1", 0), FalsoOpenWA)
        cls.url = "http://127.0.0.1:%d" % cls.srv.server_address[1]
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()
        cls.srv.server_close()

    def setUp(self):
        FalsoOpenWA.pedidos = []
        FalsoOpenWA.inexistentes = set()
        FalsoOpenWA.falhar_envio = False
        FalsoOpenWA.falhar_check = False
        FalsoOpenWA.resposta_invalida = False
        self.tmp = tempfile.mkdtemp()
        os.environ["OPENWA_API_KEY"] = CHAVE
        self.campanha({"texto": "Oi {{nome}}, novidades na loja!", "imagem_url": "https://ex.com/foto.jpg"})
        self.sleeps = []
        disparo.esperar = self.sleeps.append  # sem espera real nos testes

    def arq(self, nome):
        return os.path.join(self.tmp, nome)

    def campanha(self, dados):
        with open(self.arq("campanha.json"), "w", encoding="utf-8") as f:
            json.dump(dados, f)

    def contatos(self, linhas, sep=","):
        with open(self.arq("contatos.csv"), "w", encoding="utf-8", newline="") as f:
            f.write(sep.join(["telefone", "nome", "consentimento"]) + "\n")
            for l in linhas:
                f.write(sep.join(l) + "\n")

    def rodar(self, *extra):
        argv = ["--contatos", self.arq("contatos.csv"), "--campanha", self.arq("campanha.json"),
                "--descadastro", self.arq("descadastro.csv"), "--log", self.arq("envios.csv"),
                "--url", self.url, "--sessao", "s1", *extra]
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            cod = disparo.main(argv)
        return cod, out.getvalue()

    def log(self):
        with open(self.arq("envios.csv"), encoding="utf-8", newline="") as f:
            return list(csv.DictReader(f))

    def envios(self):
        return [p for p in FalsoOpenWA.pedidos if p[0] == "POST"]


class TestNormalizar(unittest.TestCase):
    def test_formatos(self):
        n = disparo.normalizar
        self.assertEqual(n("(11) 98765-4321"), "5511987654321")
        self.assertEqual(n("+55 11 98765-4321"), "5511987654321")
        self.assertEqual(n("011 98765-4321"), "5511987654321")
        self.assertEqual(n("11 3456-7890"), "551134567890")
        self.assertIsNone(n("12345"))
        self.assertIsNone(n(""))
        self.assertIsNone(n("1 202 555 0100 999"))

    def test_texto_com_rodape(self):
        self.assertTrue(disparo.montar_texto("Oi {{nome}}", "Ana").startswith("Oi Ana"))
        self.assertIn(disparo.RODAPE, disparo.montar_texto("Oi", ""))
        self.assertEqual(disparo.montar_texto("Oi. Responda SAIR para sair.", "x").count("SAIR"), 1)


class TestDisparo(Base):
    def test_simulacao_nao_envia_nada(self):
        self.contatos([["11987654321", "Ana", "sim"]])
        cod, out = self.rodar()
        self.assertEqual(cod, 0)
        self.assertEqual(FalsoOpenWA.pedidos, [])
        self.assertIn("SIMULAÇÃO", out)
        self.assertFalse(os.path.exists(self.arq("envios.csv")))

    def test_envia_imagem_com_corpo_certo(self):
        self.contatos([["11987654321", "Ana", "sim"]])
        cod, _ = self.rodar("--enviar")
        self.assertEqual(cod, 0)
        metodo, caminho, corpo = self.envios()[0]
        self.assertEqual(caminho, "/api/sessions/s1/messages/send-image")
        self.assertEqual(corpo["chatId"], "5511987654321@c.us")
        self.assertEqual(corpo["url"], "https://ex.com/foto.jpg")
        self.assertTrue(corpo["caption"].startswith("Oi Ana, novidades"))
        self.assertIn(disparo.RODAPE, corpo["caption"])
        self.assertEqual(self.log()[0]["status"], "enviado")

    def test_imagem_local_vai_em_base64(self):
        with open(self.arq("foto.png"), "wb") as f:
            f.write(b"\x89PNGfake")
        self.campanha({"texto": "Oi", "imagem": "foto.png"})
        self.contatos([["11987654321", "Ana", "sim"]])
        self.rodar("--enviar")
        corpo = self.envios()[0][2]
        self.assertEqual(base64.b64decode(corpo["base64"]), b"\x89PNGfake")
        self.assertEqual(corpo["mimetype"], "image/png")
        self.assertEqual(corpo["filename"], "foto.png")

    def test_sem_imagem_envia_texto(self):
        self.campanha({"texto": "Só texto"})
        self.contatos([["11987654321", "Ana", "sim"]])
        self.rodar("--enviar")
        caminho, corpo = self.envios()[0][1:]
        self.assertEqual(caminho, "/api/sessions/s1/messages/send-text")
        self.assertTrue(corpo["text"].startswith("Só texto"))

    def test_pula_sem_consentimento_descadastro_e_repetido(self):
        with open(self.arq("descadastro.csv"), "w", encoding="utf-8") as f:
            f.write("(21) 99999-0000\n")
        self.contatos([["11987654321", "Ana", ""], ["21999990000", "Bia", "sim"],
                       ["11911112222", "Cris", "sim"], ["+55 11 91111-2222", "Cris", "sim"], ["abc", "X", "sim"]])
        self.rodar("--enviar")
        destinos = [c["chatId"] for _, _, c in self.envios()]
        self.assertEqual(destinos, ["5511911112222@c.us"])

    def test_nao_repete_quem_ja_recebeu(self):
        self.contatos([["11987654321", "Ana", "sim"], ["11911112222", "Cris", "sim"]])
        self.rodar("--enviar")
        self.assertEqual(len(self.envios()), 2)
        FalsoOpenWA.pedidos = []
        self.rodar("--enviar")
        self.assertEqual(self.envios(), [])

    def test_numero_sem_whatsapp_nao_envia_e_nao_tenta_de_novo(self):
        FalsoOpenWA.inexistentes = {"5511987654321"}
        self.contatos([["11987654321", "Ana", "sim"]])
        self.rodar("--enviar")
        self.assertEqual(self.envios(), [])
        self.assertEqual(self.log()[0]["status"], "nao_existe")
        FalsoOpenWA.pedidos = []
        self.rodar("--enviar")
        self.assertEqual(FalsoOpenWA.pedidos, [])

    def test_limite_diario_vale_entre_rodadas(self):
        self.contatos([["1198765432%d" % i, "N", "sim"] for i in range(5)])
        self.rodar("--enviar", "--limite-dia", "2")
        self.assertEqual(len(self.envios()), 2)
        FalsoOpenWA.pedidos = []
        _, out = self.rodar("--enviar", "--limite-dia", "2")
        self.assertEqual(self.envios(), [])
        self.assertIn("limite diário", out)

    def test_falha_antes_de_enviar_para_em_3_e_tenta_de_novo_depois(self):
        FalsoOpenWA.falhar_check = True
        self.contatos([["1198765432%d" % i, "N", "sim"] for i in range(6)])
        cod, out = self.rodar("--enviar")
        self.assertEqual(cod, 1)
        self.assertIn("3 falhas seguidas", out)
        self.assertEqual([l["status"] for l in self.log()], ["erro"] * 3)
        FalsoOpenWA.falhar_check = False
        FalsoOpenWA.pedidos = []
        self.rodar("--enviar")
        self.assertEqual(len(self.envios()), 6)  # erro antes do envio não é final: tenta de novo

    def test_erro_5xx_no_envio_vira_incerto_e_nao_reenvia(self):
        FalsoOpenWA.falhar_envio = True
        self.contatos([["1198765432%d" % i, "N", "sim"] for i in range(5)])
        cod, out = self.rodar("--enviar")
        self.assertEqual(cod, 1)
        self.assertEqual([l["status"] for l in self.log()], ["incerto"] * 3)
        self.assertIn("confira no WhatsApp", out)
        FalsoOpenWA.falhar_envio = False
        FalsoOpenWA.pedidos = []
        self.rodar("--enviar")
        self.assertEqual(len(self.envios()), 2)  # só os que nunca foram tentados

    def test_resposta_que_nao_e_json_vira_incerto_sem_traceback(self):
        FalsoOpenWA.resposta_invalida = True
        self.contatos([["11987654321", "Ana", "sim"]])
        self.rodar("--enviar")
        self.assertEqual(self.log()[0]["status"], "incerto")

    def test_registro_salvo_pelo_excel_interrompe_em_vez_de_reenviar(self):
        self.contatos([["11987654321", "Ana", "sim"]])
        with open(self.arq("envios.csv"), "w", encoding="utf-8-sig", newline="") as f:
            f.write("telefone;status;horario;detalhe\n5511987654321;enviado;2026-01-01T10:00:00;x\n")
        self.rodar("--enviar")  # ; e BOM são entendidos: ninguém recebe de novo
        self.assertEqual(self.envios(), [])
        with open(self.arq("envios.csv"), "w", encoding="utf-8") as f:
            f.write("Telefone do cliente,Situação\n5511987654321,enviado\n")
        with self.assertRaises(SystemExit):
            self.rodar("--enviar")
        self.assertEqual(FalsoOpenWA.pedidos, [])

    def test_csv_antigo_do_excel_em_cp1252(self):
        with open(self.arq("contatos.csv"), "w", encoding="cp1252", newline="") as f:
            f.write("telefone;nome;consentimento\n11987654321;João;balcão\n")
        self.rodar("--enviar")
        self.assertTrue(self.envios()[0][2]["caption"].startswith("Oi João"))

    def test_consentimento_negativo_nao_recebe(self):
        self.contatos([["11987654321", "Ana", "não"], ["11911112222", "Bia", "NAO"], ["11933334444", "Cris", "0"]])
        self.rodar("--enviar")
        self.assertEqual(self.envios(), [])

    def test_descadastro_casa_com_e_sem_nono_digito(self):
        with open(self.arq("descadastro.csv"), "w", encoding="utf-8") as f:
            f.write("1187654321\n")  # cadastrado sem o 9
        self.contatos([["11987654321", "Ana", "sim"], ["1187654321", "Ana", "sim"]])
        self.rodar("--enviar")
        self.assertEqual(self.envios(), [])

    def test_avisa_quando_descadastro_nao_existe(self):
        self.contatos([["11987654321", "Ana", "sim"]])
        _, out = self.rodar()
        self.assertIn("não encontrado", out)

    def test_espera_entre_envios_dentro_da_faixa(self):
        self.contatos([["1198765432%d" % i, "N", "sim"] for i in range(3)])
        self.rodar("--enviar", "--intervalo", "20-60")
        self.assertEqual(len(self.sleeps), 2)  # entre envios, não antes do primeiro
        self.assertTrue(all(20 <= s <= 60 for s in self.sleeps))

    def test_chave_errada_da_mensagem_clara(self):
        os.environ["OPENWA_API_KEY"] = "errada"
        self.contatos([["11987654321", "Ana", "sim"]])
        _, out = self.rodar("--enviar")
        self.assertIn("chave recusada", out)

    def test_csv_do_excel_com_ponto_e_virgula(self):
        self.contatos([["11987654321", "Ana", "sim"]], sep=";")
        self.rodar("--enviar")
        self.assertEqual(len(self.envios()), 1)

    def test_modo_teste_manda_um_so(self):
        self.contatos([["11987654321", "Ana", "sim"]])
        cod, out = self.rodar("--teste", "(11) 90000-1111")
        self.assertEqual(cod, 0)
        self.assertEqual([c["chatId"] for _, _, c in self.envios()], ["5511900001111@c.us"])
        self.assertFalse(os.path.exists(self.arq("envios.csv")))

    def test_enviar_sem_chave_recusa(self):
        os.environ.pop("OPENWA_API_KEY")
        self.contatos([["11987654321", "Ana", "sim"]])
        with self.assertRaises(SystemExit):
            self.rodar("--enviar")
        self.assertEqual(FalsoOpenWA.pedidos, [])


if __name__ == "__main__":
    unittest.main(verbosity=1)
