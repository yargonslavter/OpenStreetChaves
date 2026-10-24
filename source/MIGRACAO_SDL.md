# Migracao para SDL2 (plano em fases)

Objetivo: o jogo rodar so com SDL2 (janela, desenho, som, entrada), sem LCL/formulario, para
facilitar Linux, macOS e Android. Cada fase terminou com o jogo jogavel.

## Requisitos
- `SDL2.dll` (x64, versao 2.28 ou mais nova) ao lado do `StreetChaves.exe` (raiz do projeto).
  As units em `3party/SDL2` ligam a DLL ao abrir o programa (sem carga dinamica): **sem a DLL o programa nao abre**.
  O Git ignora `*.dll`: cada clone precisa baixar a DLL em https://github.com/libsdl-org/SDL/releases .
- `Fontes/ComicSansMS.atlas` (gerado por `tools/GeraFonte`; veja o README da raiz).
- `source/3party/SDL2` esta no caminho de busca de units do `StreetChaves.lpi`.
- SDL2_ttf / SDL2_image / SDL2_mixer / SDL2_gfx NAO sao usados (evitam DLLs extras).

## Fases
| # | Fase | Situacao |
|---|------|----------|
| 0 | Infra SDL (`ChavesSDL.pas`): janela, quadro de teste (`--demo`), teclado, F11 | Feita |
| 1 | Jogo atual dentro da janela SDL | Feita |
| 2 | Extrair o jogo do formulario (`TJogo` em `ChavesJogo.pas`, estados em `game/Estado*.inc`) | Feita |
| 3 | Superficie e imagens sem LCL (`ChavesGfx.pas`, com leitor de BMP proprio) | Feita |
| 4 | Texto sem fonte do sistema (atlas de glifos `ComicSansMS.atlas`, ferramenta `tools/GeraFonte`) | Feita |
| 5 | Audio SDL (`ChavesSom.pas`: mixer proprio sobre o callback de audio; sem MCI nem TTimer) | Feita |
| 6 | Entrada SDL: teclado por `SDL_SCANCODE_*` (sem VK_), gamepad/joystick P1 e P2 | Feita (falta remapear controle e toque) |
| 7 | Remover LCL do projeto principal | Feita (LCL fora do `.lpi` e do `.lpr`) |
| 8 | Linux/macOS: compilar e testar; Android | A fazer |

## Limpeza da camada DelphiX (feita)
- Removidos: `DXInput` (virou `MapaP1/MapaP2` + leitura de teclas/controles no `TJogo`), `DXSounds` (virou `ChavesSom`),
  `DXDraws` (virou `ChavesGfx`), `DXTexto` (a ferramenta `GeraFonte` mantem uma copia), `TDXTimer` (virou `QuadroAtivo`),
  `TDXBrush/TDXPen/TDXFont`, `DXHiResMs` e os codigos `VK_*`.
- Incorporados ao jogo (a pasta `source/legacy` deixou de existir): `DXTipos` -> `TColor`/`RGBToColor` em `ChavesConst`,
  `DXClass.DXResolvePath` -> `ResolverCaminho` em `ChavesDados` (a colecao por nome nao era usada), `DXBmp` -> leitor de BMP
  dentro de `ChavesGfx`, `DXFonte` -> `ChavesFonte`.
- `TTextoLista` (imitava o `TMemo`) virou `TStringList` direto: campos `TxtNomes`, `TxtGeral`, `TxtConfig`, `TxtFrases`,
  `TxtDialogo`, `TxtFinais`, `TxtCenarios`, recarregados por `TJogo.CarregarIdioma`.
- Constantes da luta (`ac*`, `cm*`, `pn*`, `ld*`, `fg*`, `pulo*`, `snd*`) em `ChavesTipos.pas` no lugar dos numeros.
- Comandos dos lutadores (`golpe` e `sequenciagolpe`, ~1.650 linhas) viraram dados: secoes `[Sequencias]` e `[Botoes]`
  de `Dados/Lutadores/CNN.ini`, interpretadas por `TJogo.RegraVale` (equivalencia conferida por simulacao).
- `AcaoJogador`, `AtualizaQuadro` e `cpu` reformatados a partir do codigo descompilado (6.851 -> 3.261 linhas):
  parenteses e `begin/end` desnecessarios removidos, condicoes simplificadas (`P.Acao in [...]`) e as variaveis
  `r7..r265` da IA eliminadas. Conferido por analise do codigo (mesmos comandos, na mesma ordem, inclusive os
  `Random`) e por tabela-verdade de cada condicao alterada.
- A LCL saiu tambem do `.lpr` e do `.lpi`; o UTF-8 como padrao (que a LCL ligava) ficou em `ChavesUTF8.pas`.

## Proximos passos
1. Remapeamento do controle na tela F2 e controles de toque (Android).
2. Build de teste em Linux e macOS (o codigo ja nao usa APIs do Windows; faltam as bibliotecas SDL2 de cada sistema).
3. Fidelidade/resolucao: desenho 3x (logica continua 400x300; so o desenho usa sprites 3x maiores).
4. Decisao de licenca do atlas da Comic Sans MS (distribuir ou trocar por fonte livre, ex.: Comic Neue, OFL).

## Pontos de atencao
- O buffer do jogo e ARGB 32 bits (0xAARRGGBB), o mesmo formato da textura SDL: nao ha conversao.
- Texto: diferencas minimas (1 a 3 pixels em poucos glifos nos tamanhos 7, 8, 16 e 36) em relacao ao original, aceitas.
- Regressao: antes de grandes trocas, comparar quadros de referencia com o comportamento anterior.
