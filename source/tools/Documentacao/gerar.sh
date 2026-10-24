#!/bin/sh
# Gera a documentacao do codigo (HTML) com o PasDoc: https://pasdoc.github.io
# Uso: rode nesta pasta (source/tools/Documentacao). Resultado em ./html/index.html
cd "$(dirname "$0")"
mkdir -p html
pasdoc --format html --output html --title "Open Street Chaves" --language br.utf8 \
  --define FPC --define UNIX --include ../../game --include ../../3party/SDL2 \
  --visible-members private,protected,public,published \
  --implementation-comments prefer-interface --auto-abstract \
  --source fontes.txt
