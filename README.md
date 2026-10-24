# OpenStreetChaves

Repositório dedicado para engenharia reversa e melhoria do antigo jogo brasileiro chamado Street Chaves.

O jogo original (Delphi 5 + DelphiX, `Chaves.exe`). Este projeto o reconstrói em
Lazarus/Free Pascal, mantendo a fidelidade ao original, e o migra para **SDL2** para ficar portável.

## Estado desta versão (build atual)

O jogo roda **100% em SDL2**: janela, desenho, som e entrada. O programa principal não usa mais a LCL
nem formulários.

| Parte | Como é feito agora |
|-------|--------------------|
| Janela e vídeo | SDL2: o jogo desenha num buffer 400x300 (ARGB) em software e o SDL o apresenta (escala com barras pretas; F11 / Alt+Enter = tela cheia) |
| Gráficos | `ChavesGfx.pas`: superfícies, imagens e listas de imagens próprias (cópia normal, alfa, soma, subtração, rotação), BMP lido sem bibliotecas |
| Texto | Atlas de glifos pré-renderizados (`Fontes/ComicSansMS.atlas`), sem depender de fonte do sistema em tempo de execução |
| Som | `ChavesSom.pas`: mixer próprio sobre o áudio do SDL (sem MCI, sem SDL2_mixer) |
| Entrada | Teclado por código físico do SDL (`SDL_SCANCODE_*`) e controles (gamepads e joysticks genéricos) para os jogadores 1 e 2 |
| Lógica do jogo | `TJogo` (`ChavesJogo.pas`), dividida em um arquivo `.inc` por estado do jogo (`source/game/Estado*.inc`) |

O que ainda falta para ser "SDL puro" em todas as plataformas está em [`source/MIGRACAO_SDL.md`](source/MIGRACAO_SDL.md).

# Requisitos para construir o jogo

1. **Lazarus 4.8** oficial (https://www.lazarus-ide.org/), com Free Pascal 3.2.2.
2. **SDL2.dll** (64 bits, versão **2.28 ou mais nova**) na **raiz do projeto**, ao lado do `StreetChaves.exe`.
   Baixe em https://github.com/libsdl-org/SDL/releases (arquivo `SDL2-2.28.x-win32-x64.zip`).
   O Git ignora `*.dll`, então cada pessoa que clonar o repositório precisa colocar a DLL.
   Sem a DLL o programa nem abre.
3. **Atlas de fonte** `Fontes/ComicSansMS.atlas` (já deve estar na pasta `Fontes/` do repositório).
   Se o arquivo não existir, o jogo avisa ao abrir. Para gerá-lo uma vez (precisa da fonte *Comic Sans MS*
   instalada no Windows): abra `source/tools/GeraFonte/GeraFonte.lpi`, construa e execute. Ele grava o
   atlas e confere o resultado contra todos os textos do jogo (log em `GeraFonte.log`).
   Atenção: a Comic Sans MS é uma fonte da Microsoft; decida se o atlas pode ser distribuído ou se vale
   trocá-la por uma fonte livre (por exemplo, Comic Neue, licença OFL).
4. **Pasta `Dados/`** na raiz (já vem no repositório): `Jogo.ini` (valores do jogo e padrões), `Recursos.ini`
   (lista de imagens e sons) e `Textos/` (textos em português e espanhol). Sem o `Recursos.ini` o jogo avisa ao abrir e fecha.
5. Abra `source/StreetChaves.lpi` e use o menu Executar -> Construir (Ctrl+F9).

Pronto! O executável `StreetChaves.exe` aparece na raiz do projeto (ao lado das pastas `Cenarios`, `Lutadores`,
`Sons`, etc.) e é só abrir.

O programa `StreetChaves.exe --demo` abre um quadro de teste da infraestrutura SDL (útil para diagnosticar vídeo e entrada).

# Controles do jogo

## Teclado
As teclas para jogar o Open Street Chaves são (as teclas são físicas, então funcionam em qualquer layout de teclado):
* Direcionais para mover e navegar;
* Tecla ESC: Fecha o jogo;
* Tecla 5 (ou 5 do teclado numérico): Serve para dar fichas (pois o jogo simula uma máquina de fliperama);
* Teclas 1 e 2 (ou 1 e 2 do teclado numérico): Opção de escolher com qual player jogar (precisa ter fichas);
* Tecla P: Pausa o jogo;
* Tecla G: Lista de golpes do lutador;
* Teclas "-" e "=": Muda a velocidade do jogo;
* Teclas "Z", "X", "C", "V": Golpes (soco baixo, soco alto, chute baixo, chute alto), a tecla "Z" também é usada para confirmar escolhas;
* Teclas "," e ".": Deslocam a imagem para a esquerda e para a direita;
* Tecla F1: Configurações do jogo;
* Tecla F2: Remapear as teclas do jogador 1;
* F11 ou Alt+Enter: Alterna tela cheia.

O jogador 2 usa por padrão: W A S D (direcionais) e R T Y U (golpes).

## Controle (gamepad / joystick)
Ligue o controle antes ou durante o jogo. O primeiro controle conectado é o jogador 1 e o segundo é o jogador 2.
* Direcional ou analógico esquerdo: mover e navegar;
* Botões A, B, X, Y (ou botões 1, 2, 3, 4 em joysticks genéricos): os quatro golpes (mesma ordem de Z, X, C, V);
* Start (botão 9 em joysticks genéricos): entrar como jogador 1 ou 2 (precisa ter fichas);
* Back/Select (botão 8 em joysticks genéricos): dar ficha.

O título da janela mostra os controles detectados. Ainda não é possível remapear os botões do controle.

# Estrutura do repositório

Veja [`source/LEIAME.md`](source/LEIAME.md) para o detalhe de cada pasta e unit.

# Bugs conhecidos e limitações
* O build foi testado somente em Windows 64 bits; o código não usa mais APIs do Windows, mas Linux e macOS ainda não foram testados;
* A tela cheia usa o escalonamento do SDL (com barras pretas para manter 4:3); a melhoria de resolução do jogo ainda não foi feita;
* O remapeamento (F2) vale só para o teclado do jogador 1; o controle usa botões fixos;
* Diferenças mínimas (1 a 3 pixels em poucos glifos) no texto em relação ao original, por causa do atlas de fonte.
