---
name: midia
description: Use para processar vídeo, áudio e imagem por linha de comando — cortar, juntar, converter, comprimir, extrair áudio, gerar legenda e miniatura, redimensionar e otimizar imagens para site ou rede social (ffmpeg, ImageMagick).
---

# Vídeo, áudio e imagem

Trabalhe em cópia; nunca sobrescreva o original. Confira se `ffmpeg` (ou `magick`) está instalado; se não, diga como instalar (Windows: `winget install --id Gyan.FFmpeg -e`) e pare.

## Vídeo (ffmpeg)
- Informações: `ffprobe -hide_banner arquivo.mp4`
- Cortar sem recodificar (rápido, corta no quadro-chave mais próximo): `ffmpeg -ss 00:01:00 -to 00:02:30 -i in.mp4 -c copy corte.mp4`
- Comprimir para web/WhatsApp: `ffmpeg -i in.mp4 -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k saida.mp4` (CRF menor = mais qualidade e mais peso; 18–28 é o usual).
- Vertical 9:16 para Reels/TikTok (1080×1920) com recorte central: `ffmpeg -i in.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:a copy vertical.mp4`
- Extrair áudio: `ffmpeg -i in.mp4 -vn -c:a libmp3lame -q:a 2 audio.mp3`
- Miniatura: `ffmpeg -ss 00:00:05 -i in.mp4 -frames:v 1 capa.jpg`
- Juntar vídeos do mesmo formato: lista `lista.txt` com linhas `file 'a.mp4'` e `ffmpeg -f concat -safe 0 -i lista.txt -c copy junto.mp4`
- Legenda embutida: `ffmpeg -i in.mp4 -vf subtitles=legenda.srt saida.mp4`. Para gerar o `.srt` a partir da fala, use uma ferramenta de transcrição (ex.: Whisper) e revise o texto.

## Imagem
- Redimensionar e comprimir para site: largura máxima pelo uso real (ex.: 1600 px), WebP ou AVIF, qualidade ~80: `magick in.jpg -resize 1600x -quality 80 out.webp`
- Lote: rode em pasta de saída separada e confira algumas antes de apagar qualquer coisa.
- Tamanhos comuns: post quadrado 1080×1080, retrato 1080×1350, Stories/Reels 1080×1920, Open Graph 1200×630.
- Remova metadados (localização GPS) de foto antes de publicar: `magick in.jpg -strip out.jpg`.

## Direitos
Use só mídia própria, licenciada ou de banco com licença compatível; música em vídeo de anúncio precisa de licença comercial.

## Entregar
O comando usado, o arquivo gerado, tamanho antes e depois, e o que conferir (sincronia de áudio, corte, legibilidade da legenda).
