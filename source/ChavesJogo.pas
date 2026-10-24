unit ChavesJogo;

{ ChavesJogo.pas - o jogo Street Chaves (porte para Lazarus).

  Portado a partir do executavel original (Delphi 5 + DelphiX). Os nomes dos metodos e os das variaveis globais
  (ChavesTipos) seguem o original. TJogo nao e um formulario: quem abre a janela, conduz o
  tempo e entrega o teclado e o ChavesSDL.pas. O codigo esta dividido por estado (pasta game).
}

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, IniFiles, DXTipos,
  sdl2, DXClass, ChavesGfx, ChavesSom, ChavesConst, ChavesTipos, ChavesTextos, ChavesGolpes, ChavesDados;

type
  { Lista de linhas com a mesma interface do antigo TMemo (propriedade Lines) }
  TTextoLista = class(TStringList)
  private
    function GetLines: TStrings;
  public
    property Lines: TStrings read GetLines;
  end;

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

  { Golpe da lista da tecla G }
  TGolpeInfo = record
    N: string;     // nome ('*' no comeco = golpe especial final)
    S: string;     // sequencia de teclas (letras explicadas em Dados/Lutadores/Cnn.ini)
  end;

  { Dados de cada personagem (Dados/Lutadores/Cnn.ini, secoes [Geral] e [Golpes]) }
  TDadosLutador = record
    AlturaSprite: Integer;
    Velocidade: Double;                 // velocidade de caminhada
    Chefe: Integer;                     // ultimo adversario da campanha
    NaoEnfrenta: set of Byte;           // nunca aparecem como adversarios
    Cenario, CenarioAlternativo, CenarioRaro: Integer;   // cenario quando e o adversario
    MusicaCPU: Integer;                 // musica quando controlado pelo computador (0 = sorteada)
    Golpes: array[1..5] of TGolpeInfo;
  end;

  { TJogo }
  TJogo = class(TComponent)
  private
    MemoNomes: TTextoLista;
    MemoTexto: TTextoLista;
    MemoConfig: TTextoLista;
    MemoFrases: TTextoLista;
    MemoDialogo: TTextoLista;
    MemoFinais: TTextoLista;
    MemoCenarios: TTextoLista;
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
    procedure ExecutarQuadro;
    procedure CriaComponentes;
    procedure CarregarRecursos;
    procedure LerConfiguracao(Ini: TCustomIniFile; const Secao: string);
  private
    FFrameSheet: TSuperficie;     // folha de sprites em memoria (carregarlutador)
    FTick7: Integer;
    FPadraoLutador, FPadraoCenario, FPadraoMusica: string;   // nomes de arquivo (Dados/Recursos.ini)
    FPadraoDadosCenario: string;  // Dados/Cenarios/Cenario-##.ini
    FQtdCenarios: Integer;        // cenarios existentes (1..FQtdCenarios)
    FMusicaCenario: array of Integer;   // musica propria de cada cenario (0 = nenhuma)
    FQtdLutadores: Integer;       // personagens existentes (1..FQtdLutadores)
    FLutadores: array of TDadosLutador; // dados de cada personagem (indice 1..FQtdLutadores)
    FVolumes: TStringList;        // Chave=volume: Dados/Som.ini e, por cima, Chaves.ini ([Volume])
    { cenario carregado (carregarcenario) }
    FDesenhos: array of TDesenhoCenario;   // animacoes, na ordem de desenho
    FCameraXMax, FCameraYMax: Integer;     // limite da camera (tamanho da imagem - tela)
    FVoadorModo: Integer;                  // 0 = sem voador, 1 = sempre, 2 = so com o relogio andando
    FVoadorY: Integer;
    { --- primitivas de desenho (sobre Tela) --- }
    procedure barra(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure retangulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure barraredonda(X1, Y1, X2, Y2, R: Integer; CorBorda, CorFundo: TColor);
    procedure circulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure circulopintado(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor);
    procedure texto(X, Y: Integer; const Texto: string; Alinh: Byte; Tam: Integer; Cor: TColor);
    { --- carga de recursos --- }
    procedure copiabmp(Indice, X1, Y1, X2, Y2: Integer);
    procedure carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
    procedure carregarcenario(Numero: Integer);
    procedure LerDadosCenario(Numero: Integer);
    procedure LerDadosLutadores(const Padrao: string);
    procedure LerVolumes;
    function VolumeDe(const Arquivo: string): Integer;
    function MusicaDeCenario(Musica: Integer): Boolean;
    procedure carregarosto(const Nome: string; Variante: Byte);
    procedure carregarfala(const Nome: string);
    procedure carregaranimacao(const Nome: string);
    procedure carregareftsonoro(const Nome: string);
    procedure carregarmusica(Numero: Byte);
    procedure carregarefeitos(const Nome: string);
    { --- dados --- }
    procedure criarecorde(Posicao: Integer; const Nome: string; Personagem: Byte; Pontos: Integer);
    procedure ordenarecordista;
    procedure zerardados(Jogador: Integer);
    { --- utilidades do porte --- }
    function TecP1: Byte;               // jogador 1: bits 1,2,4,8 = cima,baixo,esq,dir; 16..128 = botoes 1..4
    function TecP2: Byte;               // jogador 2 (mesmos bits)
    function BitsTeclado(const Mapa: array of Integer): Byte;
    procedure IniciarEntrada;
    function NomeTecla(Scan: Integer): string;
    function Linha(Memo: TTextoLista; I: Integer): string;
    function ArqLutador(N: Integer): string;      // folha de sprites do personagem N
    function ArqCenario(N: Integer): string;      // imagem do cenario N
    function SufixoIdioma: string;                // '-PT' ou '-ES' (imagens com versao por idioma)
    procedure AplicarResolucao(Modo: Integer);
    procedure SalvarConfiguracao;
    procedure TocarSom(Indice: Integer);
    procedure Estado0_Resolucao;
    procedure Estado1_Abertura;
    procedure Estado2_Config;
    procedure Estado3_Teclas;
    function BordaTeclas: Byte;
    procedure criaadversario(Jog, Pers: Integer);
    procedure Estado4_Selecao;
    procedure Estado5_Adversarios;
    procedure Estado6_PreparaLuta;
    { --- luta (Estado7_Golpes.inc e Estado7_Luta.inc) --- }
    function seta(Jog: Byte; const Dir: string): Boolean;
    procedure sequencia(Jog, De, Para: Byte);
    procedure golpe(Jog, Botao: Byte);
    procedure sequenciagolpe(Jog: Byte);
    procedure cpu(Jog: Byte);
    procedure defendergolpe(Jog: Byte);
    procedure desenhalutador(Jog: Byte; X, Y: Integer; Acao, QuadroAcao: Byte);
    procedure A_Desenha(Lista: TListaImagens; Idx, X, Y: Integer);
    procedure desenhaanimacoes;
    procedure AnimacaoEspecial(const Nome: string);
    procedure desenhaefeitos;
    procedure mostrasequencia(X, Y: Integer; const Nome, Seq: string);
    procedure mostragolpe;
    procedure L7_Prepara;
    procedure L7_CenarioECamera;
    procedure L7_Relogio;
    procedure L7_HudCima(Jog: Byte);
    procedure L7_Entrada(Jog, K: Byte);
    procedure L7_Voador;
    procedure L7_ItemBonus;
    procedure L7_HudBaixo(Jog: Byte);
    procedure L7_TempoEsgotado;
    procedure L7_IntroRound;
    procedure L7_FimRound;
    procedure L7_Acertos(Jog: Byte);
    procedure L7_Fisica;
    procedure L7_Dialogo;
    procedure L7_Demo;
    procedure Estado7_Luta;
    procedure Estado8_Recordes;
    procedure Estado9_Continuar;
    procedure Estado10_Final;
    procedure Estado11_Aviso;
    procedure Estado12_Iniciais;
    procedure F10_Fala(R: TRect; const Img: string; X, Y: Integer);
    procedure F10_Explosao;
    procedure RodapeDoQuadro;
    procedure MemorizaTeclas;
    procedure TeclaAbaixo(Key: Integer);
    { --- teclado de cada estado (no .inc do estado; despacho em Comum_Teclado.inc) --- }
    procedure Teclado_Abertura(Key, Tk: Integer);
    procedure Teclado_Config(Key: Integer);
    procedure Teclado_Teclas(Key: Integer);
    procedure Teclado_Selecao(Tk: Integer);
    procedure Teclado_Luta(Key, Tk: Integer);
    procedure Teclado_Continuar(Tk: Integer);
  public
    Sair: Boolean;                     // o jogo pediu para fechar (ESC)
    ModoTela: Integer;                 // ultimo modo de resolucao pedido (1, 2 ou 3)
    AoMudarTela: TNotifyEvent;         // chamado quando o jogo troca o modo de tela
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Iniciar;                 // prepara o jogo (cria componentes, carrega recursos)
    procedure PassoSDL;                // executa 1 quadro da logica (se o timer estiver ligado)
    function TimerLigado: Boolean;
    function PixelsSDL: Pointer;       // buffer ARGB 400x300 desenhado pelo jogo
    function DeslocamentoX: Integer;   // deslocamento horizontal (teclas , e .)
    procedure TeclaSDL(Scan: Integer; Baixo: Boolean);   // Scan = SDL_SCANCODE_*
    procedure EntradaControle(Jogador: Integer; Bits: Byte);   // gamepad do jogador 1 ou 2
    procedure SoltarTeclas;
  end;

implementation

function TTextoLista.GetLines: TStrings;
begin
  Result := Self;
end;

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
