unit ChavesTipos;

{ Tipos e variaveis globais do Street Chaves.
  Recuperado por engenharia reversa do executavel original (Delphi 5).
  Os nomes foram dados pelo uso no codigo original; o endereco original de cada um
  esta no arquivo NOMES.md. Nomes "Indef_XXXX" / "Campo_N" ainda nao tem significado
  confirmado (XXXX = fim do endereco original, N = deslocamento no registro). }

{$mode delphi}{$H+}

interface

uses
  ChavesConst;

const
  { ---- Acao do lutador (TLutador.Acao) ----
    Ar = no ar (pulando); Ag = agachado. As acoes acEspecial1..7 sao os golpes especiais e mudam
    de sentido conforme o personagem (o roteiro de cada uma fica em AtualizaQuadro). }
  acParado = 1;
  acAndando = 2;
  acSocoFraco = 3;
  acChuteFraco = 4;
  acSocoForte = 5;
  acChuteForte = 6;
  acAgachado = 7;
  acAgSocoFraco = 8;
  acAgChuteFraco = 9;
  acAgSocoForte = 10;
  acAgChuteForte = 11;
  acPulo = 12;
  acArSocoFraco = 13;
  acArChuteFraco = 14;
  acArSocoForte = 15;
  acArChuteForte = 16;
  acApanhaAlto = 17;      // levou golpe alto (recua)
  acApanhaBaixo = 18;     // levou golpe baixo (recua)
  acDerrubado = 19;       // voando para tras depois de um golpe forte
  acQuicando = 20;        // bateu no chao e quica antes de levantar
  acDefesa = 21;          // defesa em pe (perde para golpe baixo)
  acDefesaBaixa = 22;     // defesa agachado (perde para golpe no ar)
  acVitoria = 23;         // pose de vitoria
  acPose = 24;            // pose do comando cmPose (nenhuma parte do jogo pede esse comando)
  acEspecial1 = 25;       // em geral: comandos cmEsp1Fraco/Forte
  acEspecial2 = 26;       // em geral: cmEsp2Fraco/Forte
  acEspecial3 = 27;       // em geral: cmEsp3Fraco/Forte
  acEspecial4 = 28;       // em geral: cmEsp4Fraco/Forte
  acEspecial5 = 29;       // em geral: especial final (cmEspFinal)
  acEspecial6 = 30;       // continuacao ou especial final de alguns personagens
  acEspecial7 = 31;       // continuacao (Seu Madruga)

  { ---- Comandos de AcaoJogador (o que o jogador, a IA ou a luta pedem) ----
    Os especiais seguem o padrao 16/17 = especial 1 fraco/forte ... 22/23 = especial 4, 24 = final.
    Excecoes: Seu Madruga usa 23 para o final; Jaiminho usa 22..25 no especial 4 e 26 no final. }
  cmEsquerda = 1;
  cmDireita = 2;
  cmSocoFraco = 3;
  cmChuteFraco = 4;
  cmSocoForte = 5;
  cmChuteForte = 6;
  cmAgachar = 7;
  cmApanharAlto = 8;
  cmApanharBaixo = 9;
  cmDerrubar = 10;
  cmBaterNoChao = 11;
  cmDefender = 12;
  cmDefenderBaixo = 13;
  cmVitoria = 14;
  cmPose = 15;
  cmEsp1Fraco = 16;
  cmEsp1Forte = 17;
  cmEsp2Fraco = 18;
  cmEsp2Forte = 19;
  cmEsp3Fraco = 20;
  cmEsp3Forte = 21;
  cmEsp4Fraco = 22;
  cmEsp4Forte = 23;
  cmEspFinal = 24;
  cmEspExtra1 = 25;
  cmEspExtra2 = 26;
  MaxComando = 26;
  { nomes usados nos arquivos de dados (secao [Botoes] de Dados/Lutadores/CNN.ini) }
  NomesComando: array[1..MaxComando] of string = (
    'Esquerda', 'Direita', 'SocoFraco', 'ChuteFraco', 'SocoForte', 'ChuteForte', 'Agachar',
    'ApanharAlto', 'ApanharBaixo', 'Derrubar', 'BaterNoChao', 'Defender', 'DefenderBaixo',
    'Vitoria', 'Pose', 'Esp1Fraco', 'Esp1Forte', 'Esp2Fraco', 'Esp2Forte', 'Esp3Fraco',
    'Esp3Forte', 'Esp4Fraco', 'Esp4Forte', 'EspFinal', 'EspExtra1', 'EspExtra2');

  { ---- Personagens (TLutador.Personagem; mesma ordem de Dados/Lutadores/CNN.ini) ---- }
  pnChaves = 1;
  pnSeuMadruga = 2;
  pnChiquinha = 3;
  pnQuico = 4;
  pnDonaFlorinda = 5;
  pnProfGirafales = 6;
  pnSrBarriga = 7;
  pnBruxa = 8;
  pnPaty = 9;
  pnNhonho = 10;
  pnGodines = 11;
  pnSrFurtado = 12;
  pnJaiminho = 13;
  pnDonaNeves = 14;
  pnGloria = 15;

  { ---- Lado (para onde o lutador ou efeito esta virado) ---- }
  ldDireita = 1;
  ldEsquerda = 2;

  { ---- Forca do golpe (TLutador.ForcaGolpe; nos especiais escolhe a versao do golpe) ---- }
  fgNenhum = 0;
  fgFraco = 1;
  fgForte = 2;
  fgEspecial = 3;         // especial final (alguns personagens usam 3 e 4 como versoes de um especial)

  { ---- Direcao do pulo (TLutador.DirPulo) ---- }
  puloNenhum = 0;
  puloReto = 1;
  puloEsquerda = 2;
  puloDireita = 3;

  { ---- Sons da luta (indice em SomEfeitos: N = Sons/Som-(N+1).wav; SomPendente := N toca) ----
    So os de uso geral; os demais (vozes e sons de cada especial) continuam com o numero. }
  sndTempoEsgotado = 4;
  sndGolpeFraco = 5;      // golpe fraco saindo
  sndGolpeForte = 6;      // golpe forte saindo
  sndAcertoFraco = 7;
  sndAcertoForte = 8;
  sndAcertoEspecial = 9;  // tambem ao pegar o item bonus
  sndDefesa = 10;
  sndItem = 11;           // comida que recupera energia
  sndQueda = 12;          // lutador bate no chao
  sndPoder = 13;          // ganhou um estoque de golpe especial
  sndEspFinal = 19;       // inicio do especial final

type
  { Lutador: 176 bytes, indices 1..2 (jogador 1 e 2). Offsets conforme o original. }
  TLutador = packed record
    X: Double;  // posicao X (Double)
    Y: Double;  // posicao Y (Double); o chao fica em ChaoY (Y cresce para baixo)
    Personagem: Byte;  // personagem (1..15)
    Iniciais: string[3];  // iniciais do recorde (string[3])
    _p21: array[0..0] of Byte;
    Angulo: SmallInt;  // angulo de giro do sprite (0..255 = 0..360 graus); zerado ao pousar
    VelAngular: SmallInt;  // velocidade de giro do sprite (golpe forte derruba girando: +-25 ou +-15; 0 = nao gira)
    _p26: array[0..1] of Byte;
    DistanciaIA: Integer;  // distancia desejada do oponente (usado pela IA)
    CorpoX1: Integer;  // caixa de colisao do corpo (relativa a posicao; espelhada se Lado=2)
    CorpoY1: Integer;
    CorpoX2: Integer;
    CorpoY2: Integer;
    AtaqueX1: Integer;  // caixa de colisao do golpe (ativa se GolpeAtivo=1)
    AtaqueY1: Integer;
    AtaqueX2: Integer;
    AtaqueY2: Integer;
    Vida: Double;  // energia atual (0..125)
    VidaBarra: Double;  // energia exibida na barra vermelha (segue Vida com atraso)
    AtrasoBarra: Double;  // contagem antes da barra vermelha comecar a baixar
    Poder: Word;  // estoques de golpe especial (0..3)
    _p90: array[0..5] of Byte;
    CargaPoder: Double;  // carga para o proximo estoque (0..102; 102 = cheio)
    GolpeAtivo: Boolean;  // True = o golpe atual ainda pode acertar
    EhChute: Boolean;  // True = o golpe atual e um chute
    NoAr: Boolean;  // True = esta pulando/no ar
    Acao: Byte;  // acao atual (constantes ac*)
    Quadro: Byte;  // indice do sprite atual (P1 1..49, P2 51..99)
    Lado: Byte;  // ldDireita ou ldEsquerda
    DirPulo: Byte;  // direcao do pulo (constantes pulo*)
    ForcaGolpe: Byte;  // forca do golpe atual (constantes fg*) - escolhe o som/efeito
    DanoGolpe: Byte;  // dano do golpe atual
    DanoDefesa: Byte;  // dano se o oponente estiver defendendo
    Recuo: Byte;  // velocidade de empurrao ao apanhar
    _p115: array[0..0] of Byte;
    QuadroAcao: SmallInt;  // contador de quadros dentro da acao
    DuracaoAcao: SmallInt;  // duracao da acao em quadros (99 = ate mudar)
    VelY: ShortInt;  // velocidade vertical (negativo = subindo; soma Gravidade a cada quadro)
    _p121: array[0..0] of Byte;
    AlturaSprite: Word;  // altura do sprite do personagem
    _p124: array[0..3] of Byte;
    Velocidade: Double;  // velocidade de caminhada
    Pontos: Integer;  // pontuacao
    RoundsVencidos: Byte;  // rounds ganhos na luta atual
    FraseVitoria: Byte;  // frase de vitoria sorteada (1..3)
    CursorIni: Byte;  // posicao do cursor ao digitar iniciais
    MsgBonus: Byte;  // mensagem de bonus (1 = Primeiro Ataque, 2 = Bonus)
    TempoMsgBonus: Byte;  // quadros restantes da mensagem
    DesenhaPorCima: Boolean;  // True = este lutador e desenhado por cima do outro
    Invulneravel: Boolean;  // True = golpes nao pegam (caindo/levantando; o vencedor do round tambem fica assim)
    Defendendo: Boolean;  // True = esta defendendo
    AndandoFrente: Boolean;  // True = andando para o lado do oponente (False = recuando)
    Acertos: Byte;  // combo: acertos seguidos
    TempoAcertos: Byte;  // quadros restantes do combo
    MaxAcertos: Byte;  // maior combo da luta
    SeqEstado: Byte;  // passo atual da sequencia de teclas de um golpe especial (0 = nenhuma)
    SeqTempo: Byte;  // quadros restantes para o proximo passo da sequencia (9 ao avancar)
    TempoBaixo: Byte;  // quadros seguidos com a tecla de baixo (maximo 18; sobe/desce 1 por quadro)
    TempoTras: Byte;  // quadros seguidos segurando para tras (maximo 18)
    CargaSoco: Byte;  // contador decrescente (botoes 1/3)
    CargaChute: Byte;  // contador decrescente (botoes 2/4)
    Ativo: Boolean;  // True = jogador humano ativo (entrou com ficha)
    Escolheu: Boolean;  // ja confirmou o personagem
    Adversarios: array[1..8] of Byte;  // ordem dos 8 adversarios da campanha (o 8o e o chefe)
    AntSocoFraco: Boolean;  // estado anterior (borda): botao 1
    AntChuteFraco: Boolean;
    AntSocoForte: Boolean;
    AntChuteForte: Boolean;
    AntCima: Boolean;
    AntBaixo: Boolean;
    AntEsq: Boolean;
    AntDir: Boolean;
  end;
  PLutador = ^TLutador;

  { Efeito: 56 bytes, indices 1..80 @ 4B4648. Sao as fumacas, poeiras, sangue, faiscas,
    bolas de fogo, textos e demais objetos temporarios da luta (Tipo 0 = posicao livre).
    Nomes marcados "(prov.)" sao deduzidos pelo uso e podem mudar. }
  TEfeito = packed record
    X, Y: Double;                  // 0, 8: posicao
    CaixaX1, CaixaY1, CaixaX2, CaixaY2: Integer;  // 16..28: caixa de colisao relativa (espelhada pelo Lado)
    Lado: Byte;                    // 32: 1 = para a direita, 2 = para a esquerda (copiado do dono)
    Vel: Byte;                     // 33: (prov.) velocidade horizontal
    Dano: Byte;                    // 34: (prov.) dano ao acertar (0 = inofensivo)
    DanoDefesa: Byte;              // 35: (prov.) dano se o oponente defender (Dano/4 ou /15)
    Dono: Byte;                    // 36: jogador que criou (0 = ninguem)
    _p37: Byte;
    VelY: SmallInt;                // 38: (prov.) velocidade vertical
    Estagio: Boolean;                 // 40: (prov.) alterna entre duas animacoes/textos
    Variante: Boolean;                // 41: (prov.)
    Terminando: Boolean;              // 42: (prov.)
    Tipo: Byte;                    // 43: tipo do efeito (1..36); 0 = livre
    Quadro: Byte;                  // 44: contador de animacao
    Duracao: Byte;                 // 45: quadros de vida (99 = ate mudar)
    Sprite: Byte;                  // 46: indice do sprite desenhado
    Contagem: Byte;                // 47: (prov.)
    LimiteContagem: Byte;          // 48: (prov.)
    PodeAcertar: Boolean;             // 49: (prov.) True = ainda pode ferir
    Flag50: Boolean;                  // 50: (prov.)
    Flag51: Boolean;                  // 51: (prov.)
    Flag52: Boolean;                  // 52: (prov.) True = sofre gravidade
    _p53: array[0..2] of Byte;
  end;
  PEfeito = ^TEfeito;

  { Objeto voador (passaro/aviao do cenario): 16 bytes @ 4B57C8 }
  TVoador = packed record
    X, Y: Integer;
    Vel: Byte;
    Tipo: Byte;
    Alcance: Word;
    Ativo: Boolean;
    _p13: array[0..2] of Byte;
  end;

  { Item/bonus no cenario: 28 bytes @ 4B57D8 }
  TItem = packed record
    X, Y: Integer;
    Dx1, Dy1, Dx2, Dy2: Integer;   // caixa de colisao relativa
    Icone: Byte;                   // indice na lista de icones (0 = nenhum)
    _p25: array[0..2] of Byte;
  end;

  { Recorde: 12 bytes (3 letras string[3]? + personagem + pontos) }
  TRecorde = packed record
    Nome: string[3];
    Personagem: Byte;
    _p5: array[0..2] of Byte;
    Pontos: Cardinal;
  end;

var
  Lutador: array[1..2] of TLutador;
  Efeitos: array[1..MaxEfeitos] of TEfeito;

  { Convencao: nomes com sufixo "_XXXX" ou prefixo "Indef_" ainda NAO tem significado confirmado;
    o numero e o ultimo trecho do endereco original (ver NOMES.md).
    "(prov.)" = significado provavel, nao confirmado. }

  { --- controle do jogo / maquina de estados --- }
  Estado: Byte;                  // 0 resolucao, 1 abertura, 2 config, 3 teclas, 4 selecao, 5 adversarios,
                                 // 6 prepara luta, 7 luta, 8 fim, 9 continue, 10, 11, 12 nome do recorde
  TempoEstado: SmallInt;         // contador de quadros do estado atual
  ContPisca: Byte;               // contador ciclico para efeitos que piscam
  CursorMenu: Byte;              // opcao selecionada (resolucao / linha da config / tecla)
  FaseSelecao: Byte;             // selecao de lutador: 1 = entrando, 2 = interativa
  IntervaloTimer: Word;          // intervalo do timer em ms (velocidade do jogo), padrao 28
  AvisoVelocidade: Byte;         // quadros restantes mostrando a barra de velocidade
  Pausado: Boolean;                 // True = jogo pausado (tecla P)
  PassoAPasso: Boolean;             // True = pausa quadro a quadro (tecla G durante a luta)
  PrimeiroAtaque: Boolean;          // True = o primeiro ataque do round ja aconteceu (concede bonus)
  TempoDemo: SmallInt;           // contagem da luta de demonstracao (600 ao iniciar)
  RelogioParado: Boolean;           // True = relogio/contagem do round parado (luta ainda nao comecou); False = luta rolando
  Fichas: Byte;                  // creditos inseridos (tecla 5)
  Fase: Byte;                    // adversario atual da campanha (1..8)
  ContagemSeg, ContagemTick: Byte;  // contagem regressiva (segundos / quadros) da selecao e do round
  AvisoEntrada: Word;            // quadros do aviso "alguem entrou no combate"
  MusicaPendente: Boolean;          // True = tocar a musica no proximo quadro da luta
  FlashTela: Byte;               // quadros restantes do efeito de tela piscando
  TremorTela: Byte;              // quadros restantes de tremor da camera

  { --- cenario / camera --- }
  CenarioAtual: Byte;            // numero do cenario carregado (1..12)
  CameraX, CameraY: Integer;     // deslocamento da camera
  DeslocHudTopo, DeslocHudBase: SmallInt;  // deslocamento da barra de energia de cima / da de baixo (animacao de entrada)
  ChaoY: Word;                   // Y do chao (300)
  LogoMeiaAltura: Integer;       // abertura: metade da altura do logo animado

  Voador: TVoador;               // objeto voador do cenario
  ItemBonus: TItem;              // item bonus no cenario
  MouseX, MouseY: Integer;       // posicao do mouse sobre a tela de jogo
  Versao: string;                // 'V1.5A'

  { --- configuracoes (tela F1; salvas em Chaves.ini) --- }
  NivelJogo: Byte;               // "Nivel do Jogo" 1..8 (dificuldade)
  TempoRound: Byte;              // "Tempo do Round": 1 = 30s, 2 = 60s, 3 = 90s, 4 = sem limite
  ModoPoder: Byte;               // "Poder": 1 normal, 2 = 1P max, 3 = 2P max, 4 = max
  NivelDano: Double;             // "Nivel de Dano" 0.3 .. 2.0
  Sangue: Boolean;                  // "Sangue": liga/desliga
  NumRounds: Byte;               // "Rounds" 1..3
  Idioma: Byte;                  // 1 = Portugues, 2 = Espanhol
  Flash: Boolean;                   // "Flash": liga/desliga
  MostrarNivel: Boolean;            // "Mostrar Nivel"
  MostrarCreditos: Boolean;         // "Mostrar Creditos"
  SomPendente: Byte;             // som a tocar no proximo quadro (0 = nenhum); tambem usado no "Teste de Som"
  QtdSons: Byte;                 // quantidade de sons carregados (Sons/Som-NN.wav)
  MusicaAtual: Byte;             // musica em uso / selecionada no "Teste de Musica"
  QtdMusicas: Byte;              // quantidade de musicas (Musicas/Musica-NN.wav)

  { --- truques liberados por arquivos .dat na pasta do jogo --- }
  CheatChurros: Boolean;            // Churros.dat: mostra os proximos adversarios
  CheatGentalha: Boolean;           // Gentalha.dat: comeca na fase 8
  CheatSatanas: Boolean;            // Satanas.dat
  CheatFadiga: Boolean;             // Fadiga.dat: pula para o estado 10
  CheatMentecapto: Boolean;         // Mentecapto.dat: camera afastada
  CheatBruxa: Boolean;              // Bruxa.dat
  CenarioSecreto: Byte;          // SC01..SC12.dat: forca o cenario
  BonusEnergeticos: Double;      // Energeticos.dat: 0.15

  Recordes: array[1..10] of TRecorde;

  { --- ainda sem significado confirmado --- }
  Indef_4488, Indef_448C, Indef_4490: Integer;
  FlashVermelho: Byte;           // (prov.) quadros de flash vermelho na tela
  Gravidade: Byte;               // gravidade (soma na velocidade vertical a cada quadro; 4 no inicio da luta)
  EfeitoCortina: Byte;           // (prov.)
  AlvoX1, AlvoY1, AlvoX2, AlvoY2: Integer;
  AtqX1, AtqY1, AtqX2, AtqY2: Integer;
  Indef_44C2: Word;
  RoundAtual: Byte;              // numero do round em andamento
  FaseIntro, FaseFim: Byte;      // (prov.) etapas da animacao de abertura e de encerramento do round
  TempoDialogo: Word;            // (prov.) quadros do dialogo/frase de vitoria
  PausaImpacto: Byte;            // quadros de congelamento ao acertar um golpe forte
  GanhoCarga: Double;            // multiplicador do ganho de carga do poder (2.0 padrao)
  Depurar: Boolean;                 // (prov.) True = mostra informacoes de depuracao
  FinalId: Byte;                 // personagem cujo final esta sendo exibido (estado 10)
  Tmp4494: Integer;              // temporario compartilhado (pulso do HUD, fase do dialogo)
  MostrarCaixas: Boolean;           // True = desenha as caixas de colisao e a cruz de posicao (depuracao)

implementation

end.
