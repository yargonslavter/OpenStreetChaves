# Street Chaves - porte para Lazarus + SDL2

Estrutura (raiz = pasta onde fica o antigo `Chaves.exe`; tudo do porte fica em `source/`):

- `source/StreetChaves.lpi / .lpr` - projeto do Lazarus 4.8 (FPC 3.2.2), sem dependência da LCL. O build gera
  `StreetChaves.exe` na raiz (ao lado do `Chaves.exe`); units compiladas ficam em `source/build/`.
- `source/ChavesSDL.pas` - o "host": abre a janela SDL, mantém o laço principal (eventos -> lógica a intervalo
  fixo -> desenho -> apresentação), trata tela cheia (F11 / Alt+Enter), teclado, controles e foco da janela.
- `source/ChavesJogo.pas` - a classe `TJogo`: todo o jogo. O código vem de `{$I}` em `source/game/` (veja abaixo).
- `source/game/` - lógica do jogo:
  - `ChavesTipos`, `ChavesConst`, `ChavesTextos`, `ChavesGolpes` - tipos, constantes, textos e golpes;
  - `ChavesGfx.pas` - gráficos em software (`TSuperficie`, `TImagem`, `TListaImagens`);
  - `ChavesSom.pas` - áudio (`TBancoSom`, mixer sobre o áudio do SDL);
  - `Comum_*.inc` - partes compartilhadas (desenho, recursos, sprites, início, quadro, entrada, SDL);
  - `Estado0..12_*.inc` - um arquivo por estado do jogo (resolução, abertura, configuração, teclas, seleção,
    adversários, preparação da luta, luta, golpes, recordes, continuar, final, aviso, iniciais);
  - `ChavesDX.inc` - cria as listas de imagens, a tela e os sons embutidos.
- `source/legacy/` - o que sobrou da antiga camada DelphiX (a ser incorporado ao resto do código):
  `DXTipos` (cor), `DXClass` (coleção por nome e resolução de caminhos), `DXBmp` (leitor de BMP),
  `DXFonte` (texto pelo atlas de glifos).
- `source/3party/SDL2/` - SDL2-for-Pascal (ligação estática com `SDL2.dll`). Só `sdl2.pas` e seus `.inc` são usados;
  `sdl2_gfx/image/mixer/net/ttf` não são usados pelo jogo.
- `source/tools/GeraFonte/` - ferramenta separada (usa a LCL) que gera `Fontes/ComicSansMS.atlas` a partir da fonte
  Comic Sans MS instalada no Windows e confere o resultado contra todos os textos do jogo.
- `source/Embutidos/` - BMPs/WAVs extraídos do `Chaves.exe` original.
- `Cenarios/ Lutadores/ Sons/ Musicas/ Rostos/ ...` - recursos originais do jogo.

## Como o jogo funciona
A cada `IntervaloTimer` ms (28 por padrão) o host chama `TJogo.PassoSDL`, que executa um quadro da lógica
(`ExecutarQuadro`) e desenha no buffer `Tela` (400x300, ARGB). O host copia o buffer para uma textura SDL e a apresenta.
O estado atual (`Estado`, constantes `CHS_*` em `ChavesConst`) decide qual `Estado*_...` roda a cada quadro.

## Entrada
- Teclado: o host entrega scancodes do SDL (`SDL_SCANCODE_*`) a `TJogo.TeclaSDL`. Cada jogador tem um mapa de 8 ações
  (`MapaP1`, `MapaP2`: cima, baixo, esquerda, direita, botões 1..4). Padrão: P1 = setas + Z X C V (configurável em F2);
  P2 = W A S D + R T Y U.
- Controles: o host lê gamepads (`SDL_GameController`) e joysticks genéricos (`SDL_Joystick`) e entrega os bits ao jogo
  (`EntradaControle`); eles são somados aos do teclado em `TecP1` / `TecP2`.

## Dicas
- Não é preciso instalar nenhum pacote do Lazarus além do próprio Lazarus.
- Feche no Lazarus os arquivos que for alterar por fora, para o editor não gravar a versão antiga por cima.
