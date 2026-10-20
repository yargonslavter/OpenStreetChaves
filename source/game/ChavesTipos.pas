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
    GolpeAtivo: Byte;  // 1 = o golpe atual ainda pode acertar
    EhChute: Byte;  // 1 = o golpe atual e um chute
    NoAr: Byte;  // 1 = esta pulando/no ar
    Acao: Byte;  // acao atual (1 parado, 2 andando, 3.. golpes, 12 pulo, 17/18 apanhando, 19.. etc.)
    Quadro: Byte;  // indice do sprite atual (P1 1..49, P2 51..99)
    Lado: Byte;  // 1 = virado para a direita, 2 = para a esquerda
    DirPulo: Byte;  // direcao do pulo (1 parado, 2 esquerda, 3 direita)
    ForcaGolpe: Byte;  // forca do golpe atual (1 fraco, 2 forte, 3 especial) - escolhe o som/efeito
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
    DesenhaPorCima: Byte;  // 1 = este lutador e desenhado por cima do outro
    Vencedor: Byte;  // 1 = venceu o round
    Defendendo: Byte;  // 1 = esta defendendo
    Campo_148: Byte;
    Acertos: Byte;  // combo: acertos seguidos
    TempoAcertos: Byte;  // quadros restantes do combo
    MaxAcertos: Byte;  // maior combo da luta
    SeqEstado: Byte;  // passo atual da sequencia de teclas de um golpe especial (0 = nenhuma)
    SeqTempo: Byte;  // quadros restantes para o proximo passo da sequencia (9 ao avancar)
    TempoBaixo: Byte;  // quadros seguidos com a tecla de baixo (maximo 18; sobe/desce 1 por quadro)
    TempoTras: Byte;  // quadros seguidos segurando para tras (maximo 18)
    CargaSoco: Byte;  // contador decrescente (botoes 1/3)
    CargaChute: Byte;  // contador decrescente (botoes 2/4)
    Ativo: Byte;  // 1 = jogador humano ativo (entrou com ficha)
    Escolheu: Byte;  // ja confirmou o personagem
    Adversarios: array[1..8] of Byte;  // ordem dos 8 adversarios da campanha (o 8o e o chefe)
    AntSocoFraco: Byte;  // estado anterior (borda): botao 1
    AntChuteFraco: Byte;
    AntSocoForte: Byte;
    AntChuteForte: Byte;
    AntCima: Byte;
    AntBaixo: Byte;
    AntEsq: Byte;
    AntDir: Byte;
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
    Estagio: Byte;                 // 40: (prov.) 0/1 alterna entre duas animacoes/textos
    Variante: Byte;                // 41: (prov.)
    Terminando: Byte;              // 42: (prov.)
    Tipo: Byte;                    // 43: tipo do efeito (1..36); 0 = livre
    Quadro: Byte;                  // 44: contador de animacao
    Duracao: Byte;                 // 45: quadros de vida (99 = ate mudar)
    Sprite: Byte;                  // 46: indice do sprite desenhado
    Contagem: Byte;                // 47: (prov.)
    LimiteContagem: Byte;          // 48: (prov.)
    PodeAcertar: Byte;             // 49: (prov.) 1 = ainda pode ferir
    Flag50: Byte;                  // 50: (prov.)
    Flag51: Byte;                  // 51: (prov.)
    Flag52: Byte;                  // 52: (prov.) 1 = sofre gravidade
    _p53: array[0..2] of Byte;
  end;
  PEfeito = ^TEfeito;

  { Objeto voador (passaro/aviao do cenario): 16 bytes @ 4B57C8 }
  TVoador = packed record
    X, Y: Integer;
    Vel: Byte;
    Tipo: Byte;
    Alcance: Word;
    Ativo: Byte;
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
  Pausado: Byte;                 // 1 = jogo pausado (tecla P)
  PassoAPasso: Byte;             // 1 = pausa quadro a quadro (tecla G durante a luta)
  PrimeiroAtaque: Byte;          // 1 = o primeiro ataque do round ja aconteceu (concede bonus)
  TempoDemo: SmallInt;           // contagem da luta de demonstracao (600 ao iniciar)
  RelogioParado: Byte;           // 1 = relogio/contagem do round parado (luta ainda nao comecou); 0 = luta rolando
  Fichas: Byte;                  // creditos inseridos (tecla 5)
  Fase: Byte;                    // adversario atual da campanha (1..8)
  ContagemSeg, ContagemTick: Byte;  // contagem regressiva (segundos / quadros) da selecao e do round
  AvisoEntrada: Word;            // quadros do aviso "alguem entrou no combate"
  MusicaPendente: Byte;          // 1 = tocar a musica no proximo quadro da luta
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

  { --- configuracoes (tela F1; salvas em Chaves.dat) --- }
  NivelJogo: Byte;               // "Nivel do Jogo" 1..8 (dificuldade)
  TempoRound: Byte;              // "Tempo do Round": 1 = 30s, 2 = 60s, 3 = 90s, 4 = sem limite
  ModoPoder: Byte;               // "Poder": 1 normal, 2 = 1P max, 3 = 2P max, 4 = max
  NivelDano: Double;             // "Nivel de Dano" 0.3 .. 2.0
  Sangue: Byte;                  // "Sangue": 1 = sim, 0 = nao
  NumRounds: Byte;               // "Rounds" 1..3
  Idioma: Byte;                  // 1 = Portugues, 2 = Espanhol
  Flash: Byte;                   // "Flash": 1 = sim
  MostrarNivel: Byte;            // "Mostrar Nivel"
  MostrarCreditos: Byte;         // "Mostrar Creditos"
  SomPendente: Byte;             // som a tocar no proximo quadro (0 = nenhum); tambem usado no "Teste de Som"
  QtdSons: Byte;                 // quantidade de sons carregados (Sons/Som-NN.wav)
  MusicaAtual: Byte;             // musica em uso / selecionada no "Teste de Musica"
  QtdMusicas: Byte;              // quantidade de musicas (Musicas/Musica-NN.wav)

  { --- truques liberados por arquivos .dat na pasta do jogo --- }
  CheatChurros: Byte;            // Churros.dat: mostra os proximos adversarios
  CheatGentalha: Byte;           // Gentalha.dat: comeca na fase 8
  CheatSatanas: Byte;            // Satanas.dat
  CheatFadiga: Byte;             // Fadiga.dat: pula para o estado 10
  CheatMentecapto: Byte;         // Mentecapto.dat: camera afastada
  CheatBruxa: Byte;              // Bruxa.dat
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
  Depurar: Byte;                 // (prov.) 1 = mostra informacoes de depuracao
  FinalId: Byte;                 // personagem cujo final esta sendo exibido (estado 10)
  Tmp4494: Integer;              // temporario compartilhado (pulso do HUD, fase do dialogo)
  MostrarCaixas: Byte;           // 1 = desenha as caixas de colisao e a cruz de posicao (depuracao)

implementation

end.
