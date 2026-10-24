# Glossario de nomes (original -> porte)

O executavel original nao tem nomes (so enderecos). Os nomes abaixo foram dados pelo
significado observado no codigo. **Confirmado** = visto nos textos ou no uso;
**(prov.)** = deduzido, ainda nao verificado; `Indef_XXXX` / `Campo_N` = sem significado ainda.

## Variaveis globais (`ChavesTipos.pas`)

| Endereco | Nome | Tipo |
|---|---|---|
| 4B4494 | `Tmp4494` | Integer |
| 4B4498 | `ChaoY` | Word |
| 4B449A | `TremorTela` | Byte |
| 4B449B | `FlashVermelho` | Byte |
| 4B449C | `Gravidade` | Byte |
| 4B449D | `EfeitoCortina` | Byte |
| 4B449E | `CursorMenu` | Byte |
| 4B44C0 | `ContPisca` | Byte |
| 4B44C1 | `AvisoVelocidade` | Byte |
| 4B44C4 | `TempoEstado` | SmallInt |
| 4B44C8 | `CameraX` | Integer |
| 4B44CC | `CameraY` | Integer |
| 4B44D0 | `IntervaloTimer` | Word |
| 4B44D2 | `DeslocHudTopo` | SmallInt |
| 4B44D4 | `DeslocHudBase` | SmallInt |
| 4B44D6 | `Estado` | Byte |
| 4B44D7 | `FaseSelecao` | Byte |
| 4B44D8 | `CenarioAtual` | Byte |
| 4B44D9 | `NivelJogo` | Byte |
| 4B44DA | `Fichas` | Byte |
| 4B44DB | `RoundAtual` | Byte |
| 4B44DC | `NumRounds` | Byte |
| 4B44DD | `Fase` | Byte |
| 4B44DE | `FaseIntro` | Byte |
| 4B44DF | `FaseFim` | Byte |
| 4B44E0 | `RelogioParado` | Boolean |
| 4B44E1 | `Sangue` | Boolean |
| 4B44E2 | `ModoPoder` | Byte |
| 4B44E3 | `ContagemSeg` | Byte |
| 4B44E4 | `ContagemTick` | Byte |
| 4B57F4 | `PrimeiroAtaque` | Boolean |
| 4B57F6 | `TempoDialogo` | Word |
| 4B57F8 | `FlashTela` | Byte |
| 4B57F9 | `PausaImpacto` | Byte |
| 4B57FA | `AvisoEntrada` | Word |
| 4B5800 | `MouseX` | Integer |
| 4B5804 | `MouseY` | Integer |
| 4B5808 | `MusicaPendente` | Boolean |
| 4B5809 | `SomPendente` | Byte |
| 4B580A | `MusicaAtual` | Byte |
| 4B580C | `TempoDemo` | SmallInt |
| 4B5888 | `NivelDano` | Double |
| 4B5890 | `GanhoCarga` | Double |
| 4B5898 | `BonusEnergeticos` | Double |
| 4B58A0 | `TempoRound` | Byte |
| 4B58A1 | `Idioma` | Byte |
| 4B58A2 | `QtdSons` | Byte |
| 4B58A3 | `QtdMusicas` | Byte |
| 4B58A4 | `Depurar` | Boolean |
| 4B58A5 | `MostrarCaixas` | Boolean |
| 4B58A6 | `PassoAPasso` | Boolean |
| 4B58A7 | `Pausado` | Boolean |
| 4B58A8 | `Flash` | Boolean |
| 4B58A9 | `MostrarNivel` | Boolean |
| 4B58AA | `MostrarCreditos` | Boolean |
| 4B58AB | `CheatChurros` | Boolean |
| 4B58AC | `CheatGentalha` | Boolean |
| 4B58AD | `CheatSatanas` | Boolean |
| 4B58AE | `CheatFadiga` | Boolean |
| 4B58AF | `CheatMentecapto` | Boolean |
| 4B58B0 | `CheatBruxa` | Boolean |
| 4B58B1 | `CenarioSecreto` | Byte |

Truques (arquivos `.dat` na pasta do jogo): `CheatBruxa` (Bruxa.dat) tira o limite de projeteis simultaneos
(a funcao `ExisteEfeito` passa a responder sempre "nao"). Os outros truques estao descritos em `ChavesTipos.pas`.

## Campos do registro `TLutador` (176 bytes)

Os campos que no original eram Byte com valor 0/1 agora sao Boolean (tambem 1 byte: o tamanho
e os deslocamentos do registro nao mudam).

| Deslocamento | Nome | Tipo | Significado |
|---|---|---|---|
| 0 | `X` | Double | posicao X (Double) |
| 8 | `Y` | Double | posicao Y (Double); o chao fica em ChaoY (Y cresce para baixo) |
| 16 | `Personagem` | Byte | personagem (1..15) |
| 17 | `Iniciais` | string[3] | iniciais do recorde (string[3]) |
| 22 | `Angulo` | SmallInt | angulo de giro do sprite; zerado ao pousar |
| 24 | `VelAngular` | SmallInt | velocidade de giro do sprite (golpe forte derruba girando) |
| 28 | `DistanciaIA` | Integer | distancia desejada do oponente (usado pela IA) |
| 32 | `CorpoX1` | Integer | caixa de colisao do corpo (relativa a posicao; espelhada se Lado=2) |
| 36 | `CorpoY1` | Integer |  |
| 40 | `CorpoX2` | Integer |  |
| 44 | `CorpoY2` | Integer |  |
| 48 | `AtaqueX1` | Integer | caixa de colisao do golpe (ativa se GolpeAtivo=1) |
| 52 | `AtaqueY1` | Integer |  |
| 56 | `AtaqueX2` | Integer |  |
| 60 | `AtaqueY2` | Integer |  |
| 64 | `Vida` | Double | energia atual (0..125) |
| 72 | `VidaBarra` | Double | energia exibida na barra vermelha (segue Vida com atraso) |
| 80 | `AtrasoBarra` | Double | contagem antes da barra vermelha comecar a baixar |
| 88 | `Poder` | Word | estoques de golpe especial (0..3) |
| 96 | `CargaPoder` | Double | carga para o proximo estoque (0..102; 102 = cheio) |
| 104 | `GolpeAtivo` | Boolean | True = o golpe atual ainda pode acertar |
| 105 | `EhChute` | Boolean | True = o golpe atual e um chute |
| 106 | `NoAr` | Boolean | True = esta pulando/no ar |
| 107 | `Acao` | Byte | acao atual (1 parado, 2 andando, 3.. golpes, 12 pulo, 17/18 apanhando, 19.. etc.) |
| 108 | `Quadro` | Byte | indice do sprite atual (P1 1..49, P2 51..99) |
| 109 | `Lado` | Byte | 1 = virado para a direita, 2 = para a esquerda |
| 110 | `DirPulo` | Byte | direcao do pulo (1 parado, 2 esquerda, 3 direita) |
| 111 | `ForcaGolpe` | Byte | forca do golpe atual (1 fraco, 2 forte, 3 especial) - escolhe o som/efeito |
| 112 | `DanoGolpe` | Byte | dano do golpe atual |
| 113 | `DanoDefesa` | Byte | dano se o oponente estiver defendendo |
| 114 | `Recuo` | Byte | velocidade de empurrao ao apanhar |
| 116 | `QuadroAcao` | SmallInt | contador de quadros dentro da acao |
| 118 | `DuracaoAcao` | SmallInt | duracao da acao em quadros (99 = ate mudar) |
| 120 | `VelY` | ShortInt | velocidade vertical (negativo = subindo; soma Gravidade a cada quadro) |
| 122 | `AlturaSprite` | Word | altura do sprite do personagem |
| 128 | `Velocidade` | Double | velocidade de caminhada |
| 136 | `Pontos` | Integer | pontuacao |
| 140 | `RoundsVencidos` | Byte | rounds ganhos na luta atual |
| 141 | `FraseVitoria` | Byte | frase de vitoria sorteada (1..3) |
| 142 | `CursorIni` | Byte | posicao do cursor ao digitar iniciais |
| 143 | `MsgBonus` | Byte | mensagem de bonus (1 = Primeiro Ataque, 2 = Bonus) |
| 144 | `TempoMsgBonus` | Byte | quadros restantes da mensagem |
| 145 | `DesenhaPorCima` | Boolean | True = este lutador e desenhado por cima do outro |
| 146 | `Vencedor` | Boolean | True = venceu o round |
| 147 | `Defendendo` | Boolean | True = esta defendendo |
| 148 | `Campo_148` | Boolean |  |
| 149 | `Acertos` | Byte | combo: acertos seguidos |
| 150 | `TempoAcertos` | Byte | quadros restantes do combo |
| 151 | `MaxAcertos` | Byte | maior combo da luta |
| 152 | `Campo_152` | Byte |  |
| 154 | `Campo_154` | Word |  |
| 156 | `CargaSoco` | Byte | contador decrescente (botoes 1/3) |
| 157 | `CargaChute` | Byte | contador decrescente (botoes 2/4) |
| 158 | `Ativo` | Boolean | True = jogador humano ativo (entrou com ficha) |
| 159 | `Escolheu` | Boolean | ja confirmou o personagem |
| 160 | `Adversarios` | array[1..8] of Byte | ordem dos 8 adversarios da campanha (o 8o e o chefe) |
| 168 | `AntSocoFraco` | Boolean | estado anterior (borda): botao 1 |
| 169 | `AntChuteFraco` | Boolean |  |
| 170 | `AntSocoForte` | Boolean |  |
| 171 | `AntChuteForte` | Boolean |  |
| 172 | `AntCima` | Boolean |  |
| 173 | `AntBaixo` | Boolean |  |
| 174 | `AntEsq` | Boolean |  |
| 175 | `AntDir` | Boolean |  |

## Registro `TEfeito` (56 bytes, 80 posicoes em `Efeitos`)

Veja o comentario do tipo em `ChavesTipos.pas`.

## Arquivos

- `ChavesGolpes.pas`: acoes, quadros de animacao, caixas de colisao, dano e efeitos dos lutadores
  (convertido do codigo de maquina e revisado).
