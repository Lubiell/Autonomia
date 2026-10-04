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

## Estudar segurança ofensiva
Só em ambiente seu: máquina virtual isolada com laboratórios feitos para isso (OWASP Juice Shop, DVWA), plataformas de CTF e programas de bug bounty dentro do escopo publicado. Testar sistema de terceiros sem autorização por escrito é crime (Lei 12.737/2012). O Autonomia não instala ferramentas de ataque.
