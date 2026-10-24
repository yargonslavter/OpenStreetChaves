@echo off
rem Gera a documentacao do codigo (HTML) com o PasDoc: https://pasdoc.github.io
rem Uso: rode nesta pasta (source\tools\Documentacao). Resultado em html\index.html
cd /d "%~dp0"
if not exist html mkdir html
pasdoc --format html --output html --title "Open Street Chaves" --language br.utf8 --define FPC --define WINDOWS --include ..\..\game --include ..\..\3party\SDL2 --visible-members private,protected,public,published --implementation-comments prefer-interface --auto-abstract --source fontes.txt
