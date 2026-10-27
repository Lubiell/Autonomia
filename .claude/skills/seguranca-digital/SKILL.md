---
name: seguranca-digital
description: Use para proteger pessoa ou pequena empresa — senhas e gerenciador, verificação em duas etapas, backup, atualizações, golpes e phishing, Wi-Fi, celular, conta invadida e resposta a incidente — e para planejar estudo de segurança em laboratório próprio.
---

# Segurança digital (defesa)

Para código e sistemas, use o agent `security`. Esta skill cuida de pessoas, contas e máquinas.

## Básico que evita a maioria dos problemas
- **Senhas:** uma diferente por serviço, longa, num gerenciador de senhas (Bitwarden, 1Password, o do navegador). Nunca reutilize a do e-mail.
- **Verificação em duas etapas** em e-mail, banco, redes sociais, GitHub, Cloudflare, Google: prefira app autenticador ou chave física a SMS. Guarde os códigos de recuperação offline.
- **Atualizações** automáticas no sistema, navegador e celular.
- **Backup 3-2-1:** 3 cópias, em 2 tipos de mídia, 1 fora de casa (nuvem). Teste a restauração.
- **E-mail é a chave mestra:** quem entra nele redefine as outras senhas. Proteja-o primeiro.

## Golpes
- Desconfie de urgência, prêmio, cobrança inesperada, "seu banco" pedindo código, link encurtado. Confira pelo canal oficial, nunca pelo link recebido.
- Ninguém legítimo pede o código de verificação recebido por SMS ou WhatsApp.
- Ative a verificação em duas etapas do WhatsApp (PIN).

## Conta invadida
1. De um aparelho limpo: troque a senha do e-mail e da conta, encerre as outras sessões, revise a recuperação (e-mail e telefone) e os aplicativos conectados.
2. Ative a verificação em duas etapas; troque senhas repetidas em outros serviços.
3. Avise os contatos se houve golpe em seu nome; registre boletim de ocorrência se houve prejuízo; fale com o banco na hora em caso de transação.
4. Vazamento de dado de clientes: siga a skill `lgpd` (comunicação à ANPD e aos titulares).

## Empresa pequena
Contas individuais (nada de senha compartilhada), acesso só ao necessário, remoção no dia em que alguém sai, Wi-Fi de visitantes separado, computador com disco criptografado (BitLocker no Windows, FileVault no Mac).

## Wi-Fi lento no roteador de casa
Só no roteador da própria pessoa, com o Claude Code num aparelho ligado à rede lenta (sessão na nuvem não alcança a rede de casa).
1. **Diagnóstico primeiro, sem mudar nada:** velocidade e atraso com a rede carregada; banda (2,4/5 GHz), canal e vizinhos nele, largura, modo (Wi-Fi 4/5/6), potência e band steering, contra o melhor que o modelo permite.
2. **Senha do roteador** no cofre do sistema (Gerenciador de Credenciais no Windows, Keychain no Mac, `secret-tool` no Linux), gravada e lida por comando que a pessoa roda; nunca no chat, nunca exibida. Login falhou uma vez: pare e pergunte.
3. **Acesso:** página de administração ou API oficial do modelo. Biblioteca de terceiros ou integração do Home Assistant é dependência nova: pergunte antes. Captcha ou conta da operadora: abra o navegador e deixe a pessoa entrar.
4. **Antes de cada mudança:** configuração inteira salva numa pasta `roteador` na pasta pessoal; valor antigo e novo na tela; aplica só com o sim; relê o valor e mede de novo.
5. **Nunca:** mudar nome ou senha do Wi-Fi (formulário que reenvia a senha mantém a mesma), reiniciar sem perguntar, atualizar firmware, resetar ou usar brecha. Ferramenta que fica instalada para controlar o roteador, com a senha guardada, só se a pessoa pedir.
6. **Operadora travou as configurações:** arrume o que der no computador e escreva a mensagem exata para a operadora.

Entregue: antes X Mbps, depois Y Mbps; **Arrumado**, **Como desfazer**, **O que preciso de você**. Adaptado do guia de @souoallan (breezedm.app/wifi).

## Estudar segurança ofensiva
Só em ambiente seu: máquina virtual isolada com laboratórios feitos para isso (OWASP Juice Shop, DVWA), plataformas de CTF e programas de bug bounty dentro do escopo publicado. Testar sistema de terceiros sem autorização por escrito é crime (Lei 12.737/2012). O Autonomia não instala ferramentas de ataque.
