{ ChavesJogo.pas - o jogo Street Chaves (porte para Lazarus).

  Portado a partir do executavel original (Delphi 5 + DelphiX). Os nomes dos metodos e os das variaveis globais
  (ChavesTipos) seguem o original. TJogo nao e um formulario: quem abre a janela, conduz o
  tempo e entrega o teclado e o ChavesSDL.pas. O codigo esta dividido por estado (pasta game).
}

unit ChavesJogo;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, IniFiles,
  sdl2, ChavesGfx, ChavesSom, ChavesConst, ChavesTipos, ChavesTextos, ChavesGolpes, ChavesDados;

type
  { Um desenho das animacoes do cenario (Dados/Cenarios/Cenario-NN.ini, secoes [AnimacaoN]) }
  TDesenhoCenario = record
    De, Ate: Integer;          // faixa de ContPisca em que aparece; De = -1: sempre; Ate = -1: sem fim
    Lista: TListaImagens;      // lista da imagem; nil = desenho especial (feito em AnimacaoEspecial)
    Indice, X, Y: Integer;
    TremorX: Integer;          // soma Random(TremorX) ao X
    TremorY, PassoY: Integer;  // sobe PassoY * Random(TremorY)
    Especial: string;
    Esconde: set of Byte;      // personagens que, lutando, fazem o desenho sumir
  end;

  { Objeto do cenario que quebra com golpes, projeteis e lutadores derrubados em cima
    ([Objeto1], [Objeto2]... de Dados/Cenarios/Cenario-NN.ini) }
  TObjetoCenario = record
    Inteiro, Quebrado: Integer;      // indices em ImgAnimacao (-1 = nada)
    X, Y: Integer;                   // canto de cima a esquerda, no cenario
    X1, Y1, X2, Y2: Integer;         // caixa de colisao, relativa a X,Y
    Resistencia, ResistenciaMax: Integer; // golpes que aguenta
    Pedacos, QtdPedacos: Integer;    // tipo de efeito dos pedacos (Dados/Efeitos.ini) e quantos
    Pontos: Integer;                 // pontos para quem quebra
    Som: Integer;                    // som ao quebrar
    Frente: Boolean;                 // desenhado na frente dos lutadores
    Espera: Integer;                 // quadros ate aceitar outro golpe
    Tremor: Integer;                 // quadros tremendo depois de um golpe
  end;

  { Golpe da lista da tecla G }
  TGolpeInfo = record
    N: string;     // nome ('*' no comeco = golpe especial final)
    S: string;     // sequencia de teclas (letras explicadas em Dados/Lutadores/Cnn.ini)
  end;

  { Termo de uma regra de comando (Dados/Lutadores/Cnn.ini, secoes [Sequencias] e [Botoes]) }
  TTermoComando = record
    Tipo: Char;      // 'B','F','T','C' seta (baixo, frente, tras, cima); 'b'/'t' TempoBaixo/TempoTras >= Valor;
                     // 'H' no chao; 'P' passo da sequencia = Valor; 'A' no ar; 's'/'k' CargaSoco/CargaChute >= Valor
    Nega: Boolean;   // '!' na frente: o termo vale quando a condicao e falsa
    Valor: Integer;
  end;
  { Regra: todos os termos valem -> avanca a sequencia (De>Para) ou executa o comando do botao }
  TRegraComando = record
    Termos: array of TTermoComando;
    Botao: Byte;           // [Botoes]: 1 soco fraco, 2 chute fraco, 3 soco forte, 4 chute forte
    Comando: Byte;         // [Botoes]: comando de AcaoJogador (cm*)
    De, Para: Byte;        // [Sequencias]: passos da sequencia de teclas
  end;
  TRegrasComando = array of TRegraComando;

  { Dados de cada personagem (Dados/Lutadores/Cnn.ini, secoes [Geral], [Golpes], [Sequencias] e [Botoes]) }
  TDadosLutador = record
    AlturaSprite: Integer;
    Velocidade: Double;                 // velocidade de caminhada
    Chefe: Integer;                     // ultimo adversario da campanha
    NaoEnfrenta: set of Byte;           // nunca aparecem como adversarios
    Cenario, CenarioAlternativo, CenarioRaro: Integer;   // cenario quando e o adversario
    MusicaCPU: Integer;                 // musica quando controlado pelo computador (0 = sorteada)
    TremeAoCair: Boolean;               // a tela treme e levanta poeira quando ele cai no chao
    Golpes: array[1..5] of TGolpeInfo;
    Sequencias: TRegrasComando;         // teclas dos especiais (lidas por sequenciagolpe)
    Botoes: TRegrasComando;             // botao -> comando (lidas por golpe)
  end;

  { Final de personagem (Dados/Finais.ini): comandos com condicao de tempo, executados a cada quadro }
  TTermoFinal = record
    Tipo: Char;                 // 'T' = tempo da cena; 'R' = sorteio (Random(K) = 0)
    Op: string;
    K: Integer;
  end;
  TComandoFinal = record
    Grupos: array of array of TTermoFinal;   // vale se algum grupo tiver todos os termos; vazio = sempre
    Nome: string;                            // cenario, lutador, desenha, fala, imagem, preto, explosao, efeito
    Args: array of string;
  end;
  TFinal = record
    Legenda: Integer;           // primeira linha das legendas em [Finais] dos textos
    Comandos: array of TComandoFinal;
  end;

  { TJogo }
  TJogo = class(TComponent)
  private
    { textos do idioma atual (Dados/Textos/XX.ini), lidos por CarregarIdioma; acesso por Linha() }
    TxtNomes: TStringList;
    TxtGeral: TStringList;
    TxtConfig: TStringList;
    TxtFrases: TStringList;
    TxtDialogo: TStringList;
    TxtFinais: TStringList;
    TxtCenarios: TStringList;
    { tela, imagens e sons: criados em CriaComponentes e preenchidos por CarregarRecursos (Comum_Recursos.inc) }
    Tela: TSuperficie;                 // buffer 400x300 onde o jogo desenha cada quadro
    DeslocX: Integer;                  // deslocamento horizontal da imagem na janela (teclas , e .)
    QuadroAtivo: Boolean;              // False = jogo pausado (antes: DXTimer1.Enabled)
    ImgRetrato: TListaImagens;
    FTeclas: array[0..511] of Boolean;   // teclas SDL (scancode) pressionadas agora
    MapaP1: array[0..7] of Integer;      // scancode de cada acao do jogador 1 (cima, baixo, esq, dir, botoes 1..4)
    MapaP2: array[0..7] of Integer;      // idem, jogador 2
    ControleP: array[1..2] of Byte;      // estado dos controles (gamepads), mesmos bits de TecP1
    ImgEfeitos: TListaImagens;
    SomEfeitos: TBancoSom;
    ImgCenario: TListaImagens;
    ImgIcone: TListaImagens;
    SomMusica: TBancoSom;
    SomVitoria: TBancoSom;
    ImgLutador: TListaImagens;
    ImgLutadorInvert: TListaImagens;
    ImgAbertura: TListaImagens;
    ImgFinal: TListaImagens;
    ImgAnimacao: TListaImagens;
    ImgEfeitosInvert: TListaImagens;
    { Um quadro do jogo: roda o estado atual (uma transicao ja executa o proximo estado no mesmo
      quadro) e depois o rodape comum (RodapeDoQuadro). }
    procedure ExecutarQuadro;
    { Cria a tela de 400x300, as listas de imagens e os bancos de som (vazios). }
    procedure CriaComponentes;
    { Carrega tudo o que Dados/Recursos.ini lista: icones, abertura, final, musicas, dados e
      roteiros dos lutadores, animacoes, efeitos, finais, sons, falas e rostos. A ordem das cargas e
      a do jogo original (os numeros das imagens e dos sons dependem dela).
      @raises(ERoteiro erro de escrita num roteiro dos lutadores) }
    procedure CarregarRecursos;
    { Le a configuracao da tela F1 de uma secao; valores ausentes ou invalidos mantem os atuais.
      @param(Ini arquivo aberto (Dados/Jogo.ini ou Chaves.ini))
      @param(Secao 'Padroes' ou 'Configuracao') }
    procedure LerConfiguracao(Ini: TCustomIniFile; const Secao: string);
  private
    FFrameSheet: TSuperficie;     // folha de sprites em memoria (carregarlutador; HD, se houver)
    FFolha1x: TSuperficie;        // a mesma folha sempre no BMP original: dela saem os cortes dos quadros
    FTick7: Integer;
    FPadraoLutador, FPadraoCenario, FPadraoMusica: string;   // nomes de arquivo (Dados/Recursos.ini)
    FPadraoDadosCenario: string;  // Dados/Cenarios/Cenario-##.ini
    FQtdCenarios: Integer;        // cenarios existentes (1..FQtdCenarios)
    FMusicaCenario: array of Integer;   // musica propria de cada cenario (0 = nenhuma)
    FQtdLutadores: Integer;       // personagens existentes (1..FQtdLutadores)
    FLutadores: array of TDadosLutador; // dados de cada personagem (indice 1..FQtdLutadores)
    FLiberado: array of Boolean;  // personagem liberado na selecao (indice 1..FQtdLutadores)
    FIniciaisLib, FOrdemLib: string; // [Liberacao] Iniciais e Ordem do Dados/Jogo.ini
    FFinais: array of TFinal;     // finais de cada personagem (indice 1..)
    FVolumes: TStringList;        // Chave=volume: Dados/Som.ini e, por cima, Chaves.ini ([Volume])
    { cenario carregado (carregarcenario) }
    FDesenhos: array of TDesenhoCenario;   // animacoes, na ordem de desenho
    FObjetos: array of TObjetoCenario;     // objetos que quebram (zerados a cada carga do cenario)
    FCameraXMax, FCameraYMax: Integer;     // limite da camera (tamanho da imagem - tela)
    FVoadorModo: Integer;                  // 0 = sem voador, 1 = sempre, 2 = so com o relogio andando
    FVoadorY: Integer;
    { --- primitivas de desenho (sobre Tela) --- }

    { Retangulo preenchido na tela.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(Cor a cor) }
    procedure barra(X1, Y1, X2, Y2: Integer; Cor: TColor);
    { Contorno de retangulo na tela.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(Cor a cor) }
    procedure retangulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
    { Retangulo de cantos arredondados, preenchido.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(R tamanho da elipse dos cantos)
      @param(CorBorda cor do contorno)
      @param(CorFundo cor do preenchimento) }
    procedure barraredonda(X1, Y1, X2, Y2, R: Integer; CorBorda, CorFundo: TColor);
    { Elipse preenchida.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(CorBorda cor do contorno)
      @param(CorFundo cor do preenchimento) }
    procedure circulopintado(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor);
    { Escreve um texto com sombra preta deslocada de (+1, +1).
      @param(X posicao horizontal (o ponto de alinhamento))
      @param(Y topo)
      @param(Texto o texto (UTF-8))
      @param(Alinh ACentro (centralizado em X), ADir (termina em X) ou outro valor (comeca em X))
      @param(Tam tamanho da fonte)
      @param(Cor cor do texto) }
    procedure texto(X, Y: Integer; const Texto: string; Alinh: Byte; Tam: Integer; Cor: TColor);
    { --- carga de recursos --- }

    { Copia um quadro da folha de sprites carregada (FFrameSheet) para as listas ImgLutador (normal)
      e ImgLutadorInvert (espelhado).
      @param(Indice posicao nas listas)
      @param(X1 esquerda do quadro na folha)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva)) }
    procedure copiabmp(Indice, X1, Y1, X2, Y2: Integer);
    { Carrega a folha de sprites de um lutador e separa os quadros pelas colunas escuras
      (R, G, B <= 100 no topo e na base). Arquivo inexistente nao muda nada.
      @param(Nome caminho da folha de sprites)
      @param(Personagem numero do personagem (pn*))
      @param(Jogador 1 (quadros 1..) ou 2 (quadros 51..)) }
    procedure carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
    { Carrega a imagem do cenario, calcula os limites da camera e le os dados do cenario.
      @param(Numero numero do cenario (1..FQtdCenarios)) }
    procedure carregarcenario(Numero: Integer);
    { Le Dados/Cenarios/Cenario-NN.ini: item que quebra ([Item]), voador ([Voador]) e
      animacoes ([Animacao1], [Animacao2]...).
      @param(Numero numero do cenario) }
    procedure LerDadosCenario(Numero: Integer);
    { Le o arquivo de dados de cada personagem: [Geral], [Golpes], [Sequencias], [Botoes] e os
      quadros ([CentroX], [Corpo], [Ataque]).
      @param(Padrao nome dos arquivos com '##' ('Dados/Lutadores/C##.ini')) }
    procedure LerDadosLutadores(const Padrao: string);
    { Le as regras 1=, 2=... de [Sequencias] ("termos: De>Para") ou [Botoes]
      ("botao, termos: Comando"), ate o primeiro numero que faltar. Uma regra com termo desconhecido e
      ignorada inteira, para um erro de digitacao nao disparar golpes a toa.
      @param(Ini arquivo do personagem)
      @param(Secao 'Sequencias' ou 'Botoes')
      @param(Regras recebe as regras validas, na ordem) }
    procedure LerRegrasComando(Ini: TCustomIniFile; const Secao: string; out Regras: TRegrasComando);
    { Le os volumes dos sons: Dados/Som.ini e, por cima, a secao [Volume] de Chaves.ini. }
    procedure LerVolumes;
    { Volume de um som: procura o nome do arquivo sem extensao (Som-05), depois a pasta (Sons,
      Falas, Musicas...), depois 'Padrao'.
      @param(Arquivo caminho do som)
      @returns(o volume em % do arquivo, 0..400 (100 se nao houver nada)) }
    function VolumeDe(const Arquivo: string): Integer;
    { @param(Musica numero da musica)
      @returns(True se ela e a musica propria de algum cenario (so toca nele)) }
    function MusicaDeCenario(Musica: Integer): Boolean;
    { Acrescenta um retrato a ImgRetrato (a posicao e reservada mesmo sem arquivo).
      @param(Nome caminho da imagem)
      @param(Variante 1 = normal, 2 = espelhada na horizontal) }
    procedure carregarosto(const Nome: string; Variante: Byte);
    { Acrescenta uma fala de vitoria ao banco SomVitoria.
      @param(Nome caminho do WAV) }
    procedure carregarfala(const Nome: string);
    { Acrescenta uma imagem de animacao de cenario a ImgAnimacao.
      @param(Nome caminho da imagem) }
    procedure carregaranimacao(const Nome: string);
    { Acrescenta um efeito sonoro ao banco SomEfeitos.
      @param(Nome caminho do WAV) }
    procedure carregareftsonoro(const Nome: string);
    { Troca a musica do banco SomMusica (posicao 0) e anota MusicaAtual. Arquivo inexistente
      nao muda nada.
      @param(Numero numero da musica (Musica-NN.wav)) }
    procedure carregarmusica(Numero: Byte);
    { Acrescenta uma imagem de efeito a ImgEfeitos e a versao espelhada a ImgEfeitosInvert.
      @param(Nome caminho da imagem) }
    procedure carregarefeitos(const Nome: string);
    { --- dados --- }
    { Grava uma posicao da tabela de recordes.
      @param(Posicao posicao, 1..10)
      @param(Nome iniciais (no maximo 3 letras))
      @param(Personagem numero do personagem)
      @param(Pontos pontuacao) }
    procedure criarecorde(Posicao: Integer; const Nome: string; Personagem: Byte; Pontos: Integer);
    { Ordena a tabela de recordes por pontos, do maior para o menor. }
    procedure ordenarecordista;
    { Prepara um lutador para o round: energia cheia, parado, no chao, velocidade do personagem;
      reposiciona os dois lutadores e a camera e apaga os efeitos.
      @param(Jogador lutador, 1 ou 2) }
    procedure zerardados(Jogador: Integer);
    { --- utilidades do porte --- }

    { @returns(teclas do jogador 1 (teclado + controle): bits 1, 2, 4, 8 = cima, baixo, esquerda,
      direita; 16, 32, 64, 128 = botoes 1 a 4) }
    function TecP1: Byte;
    { @returns(teclas do jogador 2, com os mesmos bits de TecP1) }
    function TecP2: Byte;
    { @param(Mapa scancode SDL de cada acao (cima, baixo, esquerda, direita, botoes 1..4))
      @returns(os bits das teclas apertadas agora (bit I = Mapa[I])) }
    function BitsTeclado(const Mapa: array of Integer): Byte;
    { Teclas padrao dos dois jogadores (teclas fisicas, independem do layout do teclado). }
    procedure IniciarEntrada;
    { @param(Scan scancode SDL)
      @returns(o nome da tecla para a tela de configuracao (teclado numerico: NumN, como no original)) }
    function NomeTecla(Scan: Integer): string;
    { @param(Lista lista de textos)
      @param(I posicao)
      @returns(o texto, ou '' fora da faixa) }
    function Linha(Lista: TStrings; I: Integer): string;
    { (Re)carrega os textos do idioma atual (Idioma: 1 = PT, 2 = ES). }
    procedure CarregarIdioma;
    { Guarda o modo de tela e avisa o ChavesSDL (AoMudarTela), que muda a janela.
      @param(Modo 1 = janela, 2 = tela cheia mantendo a proporcao, 3 = tela cheia esticada) }
    procedure AplicarResolucao(Modo: Integer);
    { Grava a configuracao da tela F1 em Chaves.ini (pasta somente leitura: ignora). }
    procedure SalvarConfiguracao;
    { Monta a lista de lutadores liberados: os bloqueados sao os de [Liberacao] Ordem do
      Dados/Jogo.ini que nao estao em Iniciais nem ja foram liberados ([Progresso] do Chaves.ini).
      Liberados.dat na pasta do jogo libera todos. Chamado depois de CarregarRecursos. }
    procedure CarregarLiberacao;
    { O lutador pode ser escolhido na selecao?
      @param(Pers personagem (1..FQtdLutadores))
      @returns(True se esta liberado) }
    function Liberado(Pers: Integer): Boolean;
    { Campanha terminada: libera o proximo lutador de [Liberacao] Ordem e grava o progresso
      no Chaves.ini (pasta somente leitura: ignora). }
    procedure LiberarProximo;
    { Estado 0: escolha da resolucao (janela, tela cheia ou tela cheia esticada). }
    procedure Estado0_Resolucao;
    { Estado 1: abertura (predio, vila, logo) e modo de demonstracao; com fichas, os botoes 1 e 2
      levam a selecao. }
    procedure Estado1_Abertura;
    { Estado 2: tela de configuracoes (F1). }
    procedure Estado2_Config;
    { Estado 3: configuracao das teclas do jogador 1 (F2). }
    procedure Estado3_Teclas;
    { @returns(os bits (P1 ou P2) que acabaram de ser apertados neste quadro) }
    function BordaTeclas: Byte;
    { Sorteia a ordem dos 7 adversarios do jogador (Adversarios[1..7]); o 8o e o chefe do
      personagem. Chefe e personagens que nunca aparecem vem do arquivo do personagem.
      @param(Jog jogador, 1 ou 2)
      @param(Pers personagem escolhido (fora de 1..FQtdLutadores = nada)) }
    procedure criaadversario(Jog, Pers: Integer);
    { Estado 4: selecao de lutador. }
    procedure Estado4_Selecao;
    { Estado 5: mostra a ordem dos adversarios e o cenario do proximo combate (ou vai ao final
      depois do 8o). }
    procedure Estado5_Adversarios;
    { Estado 6: prepara a luta (lutadores, cenario, musica, tempo do round) e passa ao estado 7. }
    procedure Estado6_PreparaLuta;
    { --- luta (Estado7_Golpes.inc e Estado7_Luta.inc) --- }

    { Diz se o jogador esta segurando uma direcao, relativa para onde ele olha.
      @param(Jog jogador, 1 ou 2)
      @param(Dir 'CIMA', 'BAIXO', 'FRENTE' ou 'TRAS')
      @returns(True se esta segurando) }
    function seta(Jog: Byte; const Dir: string): Boolean;
    { Avanca a sequencia de teclas de um golpe especial: se esta no passo De, vai para Para e
      renova o prazo (SeqTempo).
      @param(Jog jogador, 1 ou 2)
      @param(De passo atual exigido)
      @param(Para passo seguinte) }
    procedure sequencia(Jog, De, Para: Byte);
    { Diz se todos os termos de uma regra de [Sequencias] ou [Botoes] valem agora.
      @param(Jog jogador, 1 ou 2)
      @param(R a regra)
      @returns(True se valem (regra sem termos vale sempre)) }
    function RegraVale(Jog: Byte; const R: TRegraComando): Boolean;
    { Botao apertado: executa, em ordem, os comandos das regras [Botoes] do personagem que valem
      agora. Nada durante o flash da tela.
      @param(Jog jogador, 1 ou 2)
      @param(Botao 1 soco fraco, 2 chute fraco, 3 soco forte, 4 chute forte) }
    procedure golpe(Jog, Botao: Byte);
    { Atualiza os tempos segurando baixo/tras, avanca as sequencias de golpes especiais pelas
      regras [Sequencias] do personagem e desfaz a sequencia quando o prazo acaba.
      @param(Jog jogador, 1 ou 2) }
    procedure sequenciagolpe(Jog: Byte);
    { IA do computador: decide os comandos do lutador (equivale a apertar teclas), pelos roteiros
      [IA] (ver CpuNovo).
      @param(Jog lutador controlado pelo computador, 1 ou 2) }
    procedure cpu(Jog: Byte);
    { Defesa automatica. Jogador humano: segurar "para tras" (em pe ou agachado) defende golpes e
      projeteis. Computador: decide defender ou pular conforme a distancia e a dificuldade.
      @param(Jog lutador, 1 ou 2) }
    procedure defendergolpe(Jog: Byte);
    { Desenha o lutador com os pes em (X, Y), na acao e quadro pedidos. Tambem avanca a animacao
      (AtualizaQuadro) e desenha sombra, caixas de depuracao e o giro do sprite.
      @param(Jog lutador, 1 ou 2)
      @param(X posicao horizontal na tela)
      @param(Y posicao dos pes na tela)
      @param(Acao acao (ac*), gravada no lutador)
      @param(QuadroAcao quadro da acao, gravado no lutador) }
    procedure desenhalutador(Jog: Byte; X, Y: Integer; Acao, QuadroAcao: Byte);
    { Desenha o primeiro quadro de uma imagem da lista, se ela existir.
      @param(Lista lista de imagens)
      @param(Idx posicao da imagem)
      @param(X esquerda na tela)
      @param(Y topo na tela) }
    procedure A_Desenha(Lista: TListaImagens; Idx, X, Y: Integer);
    { Desenha as animacoes do cenario (bandeiras, torcida, fogueira...) lidas do arquivo do cenario:
      cada desenho aparece numa faixa de ContPisca e some quando um dos lutadores e o personagem da
      animacao. A ordem dos desenhos (e dos sorteios) e a do arquivo. }
    procedure desenhaanimacoes;
    { Desenhos de cenario que dependem de conta e nao cabem numa linha do .ini.
      @param(Nome 'Vaivem', 'Torcida', 'TesteDeForca'...) }
    procedure AnimacaoEspecial(const Nome: string);
    { Processa e desenha os efeitos (fagulhas, sangue, projeteis, textos, itens...): escolhe o
      sprite, move, desenha, testa colisao com outros efeitos e com os lutadores e controla a vida util. }
    procedure desenhaefeitos;
    { Escreve o nome do golpe e os icones (e textos) da sequencia de teclas.
      @param(X esquerda)
      @param(Y topo)
      @param(Nome nome do golpe ('*' no comeco = destacado))
      @param(Seq sequencia em codigo (cada letra e uma seta, botao ou texto)) }
    procedure mostrasequencia(X, Y: Integer; const Nome, Seq: string);
    { Modo passo a passo: mostra, para cada jogador, os golpes do personagem escolhido. }
    procedure mostragolpe;
    { Luta: posicao inicial do round 1 (os lutadores entram pulando pelos lados). }
    procedure L7_Prepara;
    { Luta: toca musica e som pendentes, pisca a tela, move a camera e desenha o cenario. }
    procedure L7_CenarioECamera;
    { Luta: cabecalho "FASE n", relogio e contagem regressiva do round. }
    procedure L7_Relogio;
    { Luta: barra de energia, retrato, nome, rounds ganhos e placar de um lutador (parte de cima).
      @param(Jog lutador, 1 ou 2) }
    procedure L7_HudCima(Jog: Byte);
    { Luta: transforma as teclas do jogador humano em comandos (andar, agachar, pular, golpes).
      @param(Jog jogador, 1 ou 2)
      @param(K teclas (bits de TecP1)) }
    procedure L7_Entrada(Jog, K: Byte);
    { Luta: passaro/aviao que cruza o cenario e solta objetos. }
    procedure L7_Voador;
    { Luta: desenha o item do cenario e o quebra quando um lutador cai sobre ele. }
    procedure L7_ItemBonus;
    { Luta: desenha os objetos do cenario de uma camada e, na de tras, confere quem os acerta.
      @param(Frente True = objetos na frente dos lutadores; False = os de tras (e as colisoes)) }
    procedure L7_Objetos(Frente: Boolean);
    { Um golpe acertou o objeto: tira resistencia e, se acabou, quebra (pedacos, som e pontos).
      @param(I indice em FObjetos)
      @param(Jog lutador que acertou (0 = ninguem))
      @param(Quebra True = quebra de uma vez (lutador derrubado em cima)) }
    procedure AcertaObjeto(I, Jog: Integer; Quebra: Boolean);
    { Luta: mensagens de bonus/combo e indicador de poder (estoques e carga) de um lutador.
      @param(Jog lutador, 1 ou 2) }
    procedure L7_HudBaixo(Jog: Byte);
    { Luta: tempo esgotado: perde o de menor energia; empate perde os dois. }
    procedure L7_TempoEsgotado;
    { Luta: abertura do round (barras enchendo, "ROUND n", "FIGHT!"). }
    procedure L7_IntroRound;
    { Luta: fim do round ("KO", vencedor, bonus, cortina, proximo round ou fim da luta). }
    procedure L7_FimRound;
    { Luta: resolve se o golpe do lutador acertou (ou foi defendido pelo) oponente: dano, efeitos,
      sons, pontos e o roteiro [Acerto] (ExecutarAcerto).
      @param(Jog lutador que golpeia, 1 ou 2) }
    procedure L7_Acertos(Jog: Byte);
    { Luta: fim das acoes, queda ao chao, fisica do pulo e da queda e limites da tela. }
    procedure L7_Fisica;
    { Luta: dialogo com o chefe (fase 8), antes da luta. }
    procedure L7_Dialogo;
    { Luta de demonstracao (sem jogador): cortina, "INSERT COIN" e logo; ao acabar volta a abertura. }
    procedure L7_Demo;
    { Estado 7: a luta (um quadro: cenario, HUD, entrada, IA, lutadores, efeitos, acertos, fisica
      e fim do round). }
    procedure Estado7_Luta;
    { Estado 8: tabela de recordes; depois de um tempo volta a abertura. }
    procedure Estado8_Recordes;
    { Estado 9: "continuar?" com contagem regressiva; sem ficha vai aos recordes. }
    procedure Estado9_Continuar;
    { Estado 10: final do personagem vencedor (cenas temporizadas de Dados/Finais.ini). }
    procedure Estado10_Final;
    { Estado 11: aviso final ("obrigado por jogar"). }
    procedure Estado11_Aviso;
    { Estado 12: digitacao das iniciais de quem entrou nos recordes. }
    procedure Estado12_Iniciais;
    { Final: sombra translucida sob o balao e a figura do final.
      @param(R retangulo da sombra)
      @param(Img nome da imagem em ImgFinal)
      @param(X esquerda da figura)
      @param(Y topo da figura) }
    procedure F10_Fala(R: TRect; const Img: string; X, Y: Integer);
    { Final: retangulo de cor aleatoria com duas fagulhas (explosao). }
    procedure F10_Explosao;
    { Le Dados/Finais.ini: [FinalN] com Legenda= e linhas N=condicao: comando args.
      @param(Arquivo caminho do arquivo dos finais) }
    procedure LerFinais(const Arquivo: string);
    { Executa, em ordem, os comandos do final cuja condicao vale no tempo T.
      @param(F o final)
      @param(T tempo desde o comeco do final (TempoEstado)) }
    procedure ExecutarFinal(const F: TFinal; T: Integer);
    { Sobreposicoes comuns a quase todos os estados (velocidade, nivel, creditos, aviso de entrada
      na demonstracao), pausa e memoria das teclas. }
    procedure RodapeDoQuadro;
    { Guarda as teclas deste quadro (deteccao de borda no proximo) e atualiza as cargas de soco e
      chute (apertos repetidos). }
    procedure MemorizaTeclas;
    { Tecla apertada: teclas globais (ESC, velocidade, deslocamento da imagem, pausa, ficha) e o
      teclado do estado atual.
      @param(Key scancode SDL) }
    procedure TeclaAbaixo(Key: Integer);
    { --- teclado de cada estado (no .inc do estado; despacho em Comum_Teclado.inc) --- }

    { Teclado da abertura: F1 = configuracoes, F2 = teclas, 1/2 = entrada do jogador.
      @param(Key scancode SDL)
      @param(Tk scancode com o teclado numerico valendo como 1, 2 e 5) }
    procedure Teclado_Abertura(Key, Tk: Integer);
    { Teclado da configuracao: F1 volta a abertura salvando a configuracao.
      @param(Key scancode SDL) }
    procedure Teclado_Config(Key: Integer);
    { Teclado da tela de teclas: F2 volta a abertura; as demais teclas sao gravadas na acao
      selecionada (CursorMenu 1..8).
      @param(Key scancode SDL) }
    procedure Teclado_Teclas(Key: Integer);
    { Teclado da selecao: 1/2 = entrada do jogador (gasta uma ficha).
      @param(Tk scancode com o teclado numerico valendo como 1, 2 e 5) }
    procedure Teclado_Selecao(Tk: Integer);
    { Teclado da luta: G = pausa quadro a quadro, 1/2 = entrada do jogador.
      @param(Key scancode SDL)
      @param(Tk scancode com o teclado numerico valendo como 1, 2 e 5) }
    procedure Teclado_Luta(Key, Tk: Integer);
    { Teclado do "continuar?": 1/2 = continua com o jogador (gasta uma ficha).
      @param(Tk scancode com o teclado numerico valendo como 1, 2 e 5) }
    procedure Teclado_Continuar(Tk: Integer);
  public
    Sair: Boolean;                     // o jogo pediu para fechar (ESC)
    ModoTela: Integer;                 // ultimo modo de resolucao pedido (1, 2 ou 3)
    AoMudarTela: TNotifyEvent;         // chamado quando o jogo troca o modo de tela
    { Cria o jogo (as imagens e os sons so sao carregados em Iniciar).
      @param(AOwner dono (pode ser nil)) }
    constructor Create(AOwner: TComponent); override;
    { Libera textos, imagens, sons e a tela. }
    destructor Destroy; override;
    { Prepara o jogo: cria os objetos, le Dados/Jogo.ini e a configuracao salva, carrega textos e
      recursos e liga os truques (arquivos .dat na pasta do jogo).
      @raises(ERoteiro erro de escrita num roteiro dos lutadores) }
    procedure Iniciar;
    { Executa um quadro da logica e do desenho (se o jogo nao estiver pausado). }
    procedure PassoSDL;
    { @returns(o buffer ARGB de 400x300 desenhado pelo jogo) }
    function PixelsSDL: Pointer;
    { @returns(o deslocamento horizontal da imagem na janela (teclas , e .)) }
    function DeslocamentoX: Integer;
    { Entrega ao jogo uma tecla vinda do SDL.
      @param(Scan codigo fisico SDL_SCANCODE_*)
      @param(Baixo True = apertou; False = soltou) }
    procedure TeclaSDL(Scan: Integer; Baixo: Boolean);
    { Estado do controle (gamepad) de um jogador, calculado pelo ChavesSDL a cada passo.
      @param(Jogador 1 ou 2 (outro valor = ignora))
      @param(Bits mesmos bits de TecP1) }
    procedure EntradaControle(Jogador: Integer; Bits: Byte);
    { Solta todas as teclas e controles (a janela perdeu o foco). }
    procedure SoltarTeclas;
  end;

implementation

uses
  ChavesRoteiro, ChavesConferencia;

{ Monta uma cor, mascarando cada componente para 0..255 (cores calculadas, que podem passar
  de 255).
  @param(R vermelho)
  @param(G verde)
  @param(B azul)
  @returns(a cor TColor) }
function RGB(R, G, B: Integer): TColor;
begin
  Result := RGBToColor(R and $FF, G and $FF, B and $FF);
end;

{ ===================================================================== }
{ Codigo do jogo, dividido por estado (ver pasta game\).                }
{ Cada EstadoN_*.inc tem tudo o que e exclusivo daquele estado:         }
{ desenho, logica e teclado. O que e compartilhado fica em Comum_*.inc. }
{ ===================================================================== }

{ --- comum --- }
{$I Comum_Util.inc}
{$I Comum_Desenho.inc}
{$I Comum_Recursos.inc}
{$I Comum_Sprites.inc}
{$I Comum_Inicio.inc}
{$I Comum_SDL.inc}
{$I Comum_Teclado.inc}
{$I Comum_Quadro.inc}

{ --- estados (a numeracao segue as constantes CHS_* de ChavesConst.pas) --- }
{$I Estado0_Resolucao.inc}
{$I Estado1_Abertura.inc}
{$I Estado2_Config.inc}
{$I Estado3_Teclas.inc}
{$I Estado4_Selecao.inc}
{$I Estado5_Adversarios.inc}
{$I Estado6_PreparaLuta.inc}
{$I Estado7_Golpes.inc}
{$I Estado7_Luta.inc}
{$I Estado8_Recordes.inc}
{$I Estado9_Continuar.inc}
{$I Estado10_Final.inc}
{$I Estado11_Aviso.inc}
{$I Estado12_Iniciais.inc}

end.
