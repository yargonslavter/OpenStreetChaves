# Migracao para SDL2 (plano em fases)

Objetivo: o jogo rodar so com SDL2 (janela, desenho, som, entrada), sem LCL/formulario, para
facilitar Linux, macOS e Android. Cada fase terminou com o jogo jogavel.

## Requisitos
- `SDL2.dll` (x64, versao 2.28 ou mais nova) ao lado do `StreetChaves.exe` (raiz do projeto).
  As units em `3party/SDL2` ligam a DLL ao abrir o programa (sem carga dinamica): **sem a DLL o programa nao abre**.
  O Git ignora `*.dll`: cada clone precisa baixar a DLL em https://github.com/libsdl-org/SDL/releases .
- `Fontes/ComicNeue-3x.atlas` ou `Fontes/ComicSansMS.atlas` (gerados por `tools/GeraFonte`; veja o README da raiz).
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
- `AcaoJogador` e `AtualizaQuadro` viraram roteiro: `Dados/Lutadores/Comum.rot` (`[Acao]`, `[AcaoFim]`, `[Quadro]`)
  e `CNN.rot` (`[Acao]`, `[Quadro]`), executados por `ChavesRoteiro`; `ChavesGolpes.pas` caiu de 6.696 para ~840 linhas.
  Com `CONFERIR_ROTEIRO` (em `ChavesGolpes.pas`) o jogo roda tambem o codigo antigo (`ChavesGolpesAntigo.inc`), com
  os mesmos sorteios, e anota as diferencas em `conferencia.log`.
- A IA (`TJogo.cpu`) virou roteiro `[IA]` (`Comum.rot` e `CNN.rot`); o jogo so calcula as entradas (distancias,
  ameaca de projetil, dificuldade). A conferencia virou a unidade `ChavesConferencia` (reaproveitavel).
- As regras de personagem de `L7_Acertos` viraram a secao `[Acerto]` dos `CNN.rot`, e o tremor ao cair (Sr. Barriga e
  Nhonho) virou `[Geral] TremeAoCair` no `CNN.ini`: o codigo da luta nao cita mais nenhum personagem.
- A LCL saiu tambem do `.lpr` e do `.lpi`; o UTF-8 como padrao (que a LCL ligava) ficou em `ChavesUTF8.pas`.

## Proximos passos
1. Remapeamento do controle na tela F2 e controles de toque (Android).
2. Build de teste em Linux e macOS (o codigo ja nao usa APIs do Windows; faltam as bibliotecas SDL2 de cada sistema).
3. Graficos em alta resolucao (3x): ver a secao abaixo.

## Graficos em alta resolucao (3x)
A logica continua em 400x300 (coordenadas, caixas, camera, roteiros); so o desenho fica 3x maior.
A escala mora inteira no `ChavesGfx`: toda a API recebe coordenadas logicas e cada superficie
tem a sua `Escala` (pixels fisicos por pixel logico). Assim os `Estado*.inc` nao mudam, e a ordem
das chamadas de desenho (que tambem rodam `AtualizaQuadro` e `Random`) fica a mesma.

Decisoes: assets HD em PNG com canal alfa, em pastas paralelas `HD/` (ex.: `HD/Lutadores/C01.png`),
com volta para o 1x quando o HD nao existe; arte gerada por uma ferramenta de upscale (mesmo
layout das folhas, exatamente 3x); linhas e sombra do texto escalam junto (3 px); fonte do atlas
3x = Comic Neue (OFL).

| # | Fase | Situacao |
|---|------|----------|
| 1 | Escala no `ChavesGfx` (`EscalaTela` em `ChavesConst`), buffer e textura SDL de 1200x900 | Feita |
| 2 | Atlas de fonte 3x (Comic Neue) e texto alinhado em pixels fisicos | Feita |
| 3 | Leitor de PNG com alfa, busca em `HD/` com volta ao 1x, mistura por alfa no `DoBlit`/`DoRotate` | Feita |
| 4 | Folha HD do lutador recortada pelos cortes calculados na folha 1x (x3) | Feita |
| 5 | Ferramenta de ampliacao em lote (`tools/GeraHD`: BMP 1x -> PNG 3x, Lanczos com alfa pre-multiplicado) | Feita |
| 6 | Medir e otimizar o desenho (~3,8 ms por passo em 3x sem HD e ~4,6 ms com HD, contra ~0,75 ms em 1x; carga dos PNG no inicio de cada luta) | A fazer |

Conferencia da fase 1 (`--gravar`, 4000 passos, 80 quadros): com `EscalaTela = 1` os quadros sao
identicos aos de antes; com 3 cada bloco 3x3 e igual ao pixel do 1x, exceto nas imagens esticadas
(retratos, logo, miniatura do cenario), que agora sao amostradas com mais precisao.

Fase 2: `Fontes/ComicNeue-3x.atlas` (gerado por `GeraFonte --hd`) guarda cada tamanho Tam do jogo
como Tam x 3, desenhado com a Comic Neue Bold (o peso normal ficou fino demais perto da Comic Sans).
Em cada tamanho a altura da letra e a que deixa a soma das larguras dos textos do jogo igual a da
Comic Sans 3x (deu ~81% do tamanho nominal), e a linha de base e a altura da celula sao as da
Comic Sans 3x: a diagramacao das telas nao muda. `TSuperficie.Texto` recebe o alinhamento e o
calcula em pixels fisicos; `LarguraTexto` continua logica (arredondada). Sem o atlas 3x (ou com
`EscalaTela = 1`) o jogo usa o `ComicSansMS.atlas` ampliado em blocos. Conferido com `--gravar`:
`EscalaTela = 1` igual ao original; 3x sem o atlas HD igual a fase 1; custo por passo inalterado.

Fases 3 a 5: `TSuperficie.CarregarBMP` procura `HD/Pasta/Nome.png` (exatamente 3x o BMP; senao
volta ao BMP e anota em `HD.log`); o PNG e lido pelo `fcl-image` (FPReadPNG) e, com transparencia,
a superficie guarda o alfa de cada pixel (`TemAlfa`): `DoBlit` e `DoRotate` misturam por ele no
lugar da cor-chave (e respeitam o Alpha de `DrawAlpha`); `AtribuirRegiao` leva o alfa junto (quadros
e espelhos). `carregarlutador` acha os cortes na folha BMP (`FFolha1x`) e copia os quadros da folha
carregada (HD, se houver). `tools/GeraHD` gera os 326 PNG (113 MB) em ~30 s. Conferido com
`--gravar`: `logica.txt` (resumo dos lutadores e dos efeitos a cada quadro gravado) igual com e sem
`HD/`; com `--sem-hd` os quadros sao iguais aos da fase 2.

## Pontos de atencao
- O buffer do jogo e ARGB 32 bits (0xAARRGGBB), o mesmo formato da textura SDL: nao ha conversao.
- Texto: diferencas minimas (1 a 3 pixels em poucos glifos nos tamanhos 7, 8, 16 e 36) em relacao ao original, aceitas.
- Regressao: antes de grandes trocas, comparar quadros de referencia com o comportamento anterior.
