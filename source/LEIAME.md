# Street Chaves - porte para Lazarus + SDL2

Estrutura (raiz = pasta onde fica o antigo `Chaves.exe`; tudo do porte fica em `source/`):

- `source/StreetChaves.lpi / .lpr` - projeto do Lazarus 4.8 (FPC 3.2.2), sem dependência da LCL. O build gera
  `StreetChaves.exe` na raiz (ao lado do `Chaves.exe`); units compiladas ficam em `source/build/`.
- `source/ChavesSDL.pas` - o "host": abre a janela SDL, mantém o laço principal (eventos -> lógica a intervalo
  fixo -> desenho -> apresentação), trata tela cheia (F11 / Alt+Enter), teclado, controles e foco da janela.
- `source/ChavesJogo.pas` - a classe `TJogo`: todo o jogo. O código vem de `{$I}` em `source/game/` (veja abaixo).
- `source/game/` - lógica do jogo:
  - `ChavesTipos`, `ChavesConst`, `ChavesGolpes` - tipos, constantes e golpes;
  - `ChavesTextos.pas` - lê os textos de `Dados/Textos/<idioma>.ini`;
  - `ChavesGfx.pas` - gráficos em software (`TSuperficie`, `TImagem`, `TListaImagens`) e leitor de BMP;
  - `ChavesFonte.pas` - texto pelo atlas de glifos (`Fontes/ComicSansMS.atlas`), usado também pela GeraFonte;
  - `ChavesSom.pas` - áudio (`TBancoSom`, mixer sobre o áudio do SDL);
  - `Comum_*.inc` - partes compartilhadas (desenho, recursos, sprites, início, quadro, entrada, SDL);
  - `Estado0..12_*.inc` - um arquivo por estado do jogo (resolução, abertura, configuração, teclas, seleção,
    adversários, preparação da luta, luta, golpes, recordes, continuar, final, aviso, iniciais);
  - `ChavesDados.pas` - leitura dos arquivos de dados (`Dados/*.ini`, `Chaves.ini`).
- `source/3party/SDL2/` - SDL2-for-Pascal (ligação estática com `SDL2.dll`). Só `sdl2.pas` e seus `.inc` são usados;
  `sdl2_gfx/image/mixer/net/ttf` não são usados pelo jogo.
- `source/tools/GeraFonte/` - ferramenta separada (usa a LCL) que gera `Fontes/ComicSansMS.atlas` a partir da fonte
  Comic Sans MS instalada no Windows e confere o resultado contra todos os textos do jogo.
- `Embutidos/` (na raiz) - BMPs/WAVs extraídos do `Chaves.exe` original (ícones, abertura, finais e música dos menus).
- `Dados/` (na raiz) - arquivos de dados lidos pelo jogo:
  - `Jogo.ini` - valores do jogo (intervalo do quadro, gravidade, carga do especial, voador), padrões da
    configuração F1 e recordes iniciais;
  - `Recursos.ini` - imagens e sons carregados (listas com nome, séries numeradas e quantidades). O código
    usa as imagens pelo nome (`ImgIcone.PorNome('Mesa')`), não pela posição.
  - `Lutadores/CNN.ini` - dados de cada personagem: `[Geral]` (altura do sprite, velocidade, chefe, quem nunca
    enfrenta, cenários e música quando é o adversário) e `[Golpes]` (lista da tecla G), editados à mão;
    `[Sequencias]` (setas que avançam a sequência de cada golpe especial) e `[Botoes]` (botão + passo da
    sequência -> comando), lidos por `golpe`/`sequenciagolpe`;
    `[CentroX]`, `[Corpo]` e `[Ataque]` (centro do sprite e caixas de colisão de cada quadro, lidos por
    `ChavesGolpes`).
  - `Cenarios/Cenario-NN.ini` - dados de cada cenário: animações do fundo (`[AnimacaoN]`, com os personagens
    que as escondem e a faixa de `ContPisca` de cada quadro), item que quebra (`[Item]`) e voador (`[Voador]`).
    O limite da câmera vem do tamanho da imagem do cenário. `[Geral] Musica` = música própria do cenário.
  - `Efeitos.ini` - os 36 tipos de efeito da luta (fagulhas, sangue, projéteis...): o que cada um define ao
    ser criado (duração, dano, caixa, velocidade, sorteios) e as regras de animação (`AnimN`) de cada quadro.
  - `Finais.ini` - roteiro do final de cada personagem: linhas `condição de tempo: comando` (carregar cenário
    e lutadores, desenhar, falas, tela preta, explosão, efeitos) e a primeira linha das legendas.
  - `Som.ini` - volume de cada som (em % do arquivo), com medidas e sugestões comentadas; busca pelo
    nome do arquivo, depois pela pasta, depois `Padrao`. A seção `[Volume]` do `Chaves.ini` ajusta só aquele
    computador e vale mais que o `Som.ini`.
  - `Textos/PT.ini` e `Textos/ES.ini` - todos os textos do jogo, um arquivo por idioma (listas numeradas
    `[Nomes]`, `[Texto]`, `[Dialogo]`, `[Finais]`... e a seção `[Interface]` com os textos que o original
    deixava fixos no código). Texto com espaço nas pontas fica entre aspas.
- `Chaves.ini` (na raiz, criado pelo jogo) - configuração salva na tela F1 (substitui o antigo `Chaves.dat`).
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
