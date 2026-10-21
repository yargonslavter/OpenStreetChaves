unit ChavesPrj;

{ Street Chaves - formulario principal (porte para Lazarus).

  Portado a partir do executavel original (Delphi 5 + DelphiX) usando a camada de
  compatibilidade DelphiX (pasta DelphiXShim). Os nomes dos metodos e os das
  variaveis globais (ChavesTipos) seguem o original.
}

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Math, Graphics, Controls, Forms, Dialogs, ExtCtrls, StdCtrls, LCLType,
  DXClass, DXDraws, DXInput, DXSounds, ChavesConst, ChavesTipos, ChavesTextos, ChavesGolpes;

type
  { TForm1 }
  TForm1 = class(TForm)
    ImageLutador: TImage;
    ImageRetrato: TImage;
    ImageRetratoInvert: TImage;
    ImageLutadorFrame: TImage;
    MemoNomes: TMemo;
    MemoTexto: TMemo;
    MemoConfig: TMemo;
    MemoFrases: TMemo;
    MemoDialogo: TMemo;
    MemoFinais: TMemo;
    MemoCenarios: TMemo;
    MemoConfigSalvo: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDeactivate(Sender: TObject);
  private
    { componentes DelphiX do shim: criados em codigo (ChavesDX.inc), fora do .lfm }
    DXDraw1: TDXDraw;
    DXTimer1: TDXTimer;
    DXImageListRetrato: TDXImageList;
    DXInput1: TDXInput;
    DXImageListEfeitos: TDXImageList;
    DXSound1: TDXSound;
    DXWaveListSnd: TDXWaveList;
    DXImageListCenario: TDXImageList;
    DXImageListIcone: TDXImageList;
    DXWaveListMusica: TDXWaveList;
    DXWaveListVitoria: TDXWaveList;
    DXImageListLutador: TDXImageList;
    DXImageListLutadorInvert: TDXImageList;
    DXImageListAbertura: TDXImageList;
    DXImageListFinal: TDXImageList;
    DXImageListAnimacao: TDXImageList;
    DXImageListEfeitosInvert: TDXImageList;
    procedure DXDraw1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DXTimer1Timer(Sender: TObject; LagCount: Integer);
    procedure CriaComponentesDX;
  private
    FFrameSheet: TDirectDrawSurface;     // folha de sprites em memoria (carregarlutador)
    FTick7: Integer;
    { --- primitivas de desenho (sobre DXDraw1.Surface) --- }
    procedure barra(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure retangulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure barraredonda(X1, Y1, X2, Y2, R: Integer; CorBorda, CorFundo: TColor);
    procedure circulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
    procedure circulopintado(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor);
    procedure texto(X, Y: Integer; const Texto: string; Alinh: Byte; Tam: Integer; Cor: TColor);
    { --- carga de recursos --- }
    procedure copiabmp(Indice, X1, Y1, X2, Y2: Integer);
    procedure carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
    procedure carregarcenario(const Nome: string);
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
    function TecP1: Byte;               // teclado: bits 1,2,4,8 = cima,baixo,esq,dir; 16..128 = botoes 1..4
    function TecP2: Byte;               // "joystick" (emulado pelo teclado)
    function Linha(Memo: TMemo; I: Integer): string;
    function NomeNN(const Prefixo, Sufixo: string; N: Integer): string;
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
    { --- luta (ChavesLuta.inc) --- }
    function seta(Jog: Byte; const Dir: string): Byte;
    procedure sequencia(Jog, De, Para: Byte);
    procedure golpe(Jog, Botao: Byte);
    procedure sequenciagolpe(Jog: Byte);
    procedure cpu(Jog: Byte);
    procedure defendergolpe(Jog: Byte);
    procedure desenhalutador(Jog: Byte; X, Y: Integer; Acao, QuadroAcao: Byte);
    procedure A_Desenha(Lista: TDXImageList; Idx, X, Y: Integer);
    procedure desenhaanimacoes;
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
    procedure F10_Fala(R: TRect; Img, X, Y: Integer);
    procedure F10_Explosao;
    procedure RodapeDoQuadro;
    procedure MemorizaTeclas;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function RGB(R, G, B: Integer): TColor;
begin
  Result := RGBToColor(R and $FF, G and $FF, B and $FF);
end;

function EstadosParaByte(const S: TDXInputStates): Byte;
begin
  Result := 0;
  if isUp in S then Result := Result or 1;
  if isDown in S then Result := Result or 2;
  if isLeft in S then Result := Result or 4;
  if isRight in S then Result := Result or 8;
  if isButton1 in S then Result := Result or 16;
  if isButton2 in S then Result := Result or 32;
  if isButton3 in S then Result := Result or 64;
  if isButton4 in S then Result := Result or 128;
end;

{ ===================================================================== }
{ Utilidades                                                            }
{ ===================================================================== }

function TForm1.TecP1: Byte;
begin
  Result := EstadosParaByte(DXInput1.Keyboard.States);
end;

function TForm1.TecP2: Byte;
begin
  Result := EstadosParaByte(DXInput1.Joystick.States);
end;

function TForm1.Linha(Memo: TMemo; I: Integer): string;
begin
  if (I >= 0) and (I < Memo.Lines.Count) then Result := Memo.Lines[I] else Result := '';
end;

{ nome com N em 2 digitos (<10 ganha zero a esquerda), como as montagens do original }
function TForm1.NomeNN(const Prefixo, Sufixo: string; N: Integer): string;
begin
  if N < 10 then
    Result := Prefixo + '0' + IntToStr(N) + Sufixo
  else
    Result := Prefixo + IntToStr(N) + Sufixo;
end;

procedure TForm1.TocarSom(Indice: Integer);
begin
  if (Indice >= 0) and (Indice < DXWaveListSnd.Items.Count) then
    DXWaveListSnd.Items[Indice].Play(False);
end;

{ ===================================================================== }
{ Primitivas de desenho                                                 }
{ ===================================================================== }

procedure TForm1.barra(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Brush.Color := Cor;
    FillRect(Rect(X1, Y1, X2, Y2));
    Release;
  end;
end;

procedure TForm1.retangulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Brush.Color := Cor;
    FrameRect(Rect(X1, Y1, X2, Y2));
    Release;
  end;
end;

procedure TForm1.barraredonda(X1, Y1, X2, Y2, R: Integer; CorBorda, CorFundo: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Pen.Color := CorBorda;
    Brush.Color := CorFundo;
    RoundRect(X1, Y1, X2, Y2, R, R);
    Release;
  end;
end;

procedure TForm1.circulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Pen.Color := Cor;
    Brush.Style := bsClear;
    Ellipse(X1, Y1, X2, Y2);
    Brush.Style := bsSolid;
    Release;
  end;
end;

procedure TForm1.circulopintado(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Pen.Color := CorBorda;
    Brush.Color := CorFundo;
    Ellipse(X1, Y1, X2, Y2);
    Release;
  end;
end;

{ Alinh: 99 = centralizado em X, 101 = alinhado a direita em X, outro = a esquerda.
  Desenha uma sombra preta deslocada de (+1,+1) antes do texto colorido. }
procedure TForm1.texto(X, Y: Integer; const Texto: string; Alinh: Byte; Tam: Integer; Cor: TColor);
var
  D: Integer;
begin
  with DXDraw1.Surface.Canvas do
  begin
    Brush.Style := bsClear;
    Font.Size := Tam;
    Font.Color := Preto;
    Font.Name := 'Comic Sans MS';
    D := 0;
    if Alinh = ACentro then D := Round(TextWidth(Texto) / 2);
    if Alinh = ADir then D := TextWidth(Texto);
    TextOut(X - D + 1, Y + 1, Texto);
    Font.Color := Cor;
    TextOut(X - D, Y, Texto);
    Release;
  end;
end;

{ ===================================================================== }
{ Carga de recursos                                                     }
{ ===================================================================== }

{ Copia o quadro [X1,X2) x [Y1,Y2) da folha FFrameSheet para Indice das listas
  DXImageListLutador (normal) e DXImageListLutadorInvert (espelhado). }
procedure TForm1.copiabmp(Indice, X1, Y1, X2, Y2: Integer);
var
  Item: TPictureCollectionItem;
begin
  Item := DXImageListLutador.Items[Indice];
  Item.AssignRegion(FFrameSheet, X1, Y1, X2, Y2, False);
  Item.Name := 'Lutador';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;

  Item := DXImageListLutadorInvert.Items[Indice];
  Item.AssignRegion(FFrameSheet, X1, Y1, X2, Y2, True);
  Item.Name := 'Lutador';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;
end;

{ Carrega a folha de sprites do lutador. Os quadros sao separados por colunas
  "escuras" (R,G,B <= 100 no topo e na base). Jogador 1 ocupa os indices 1.. e
  jogador 2 os indices 51.. das listas. }
procedure TForm1.carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
var
  Desloc, Cont, Ini, Col, W, H: Integer;
  C1, C2: TColor;

  function Escuro(C: TColor): Boolean;
  begin
    Result := ((C and $FF) <= 100) and (((C shr 8) and $FF) <= 100) and (((C shr 16) and $FF) <= 100);
  end;

begin
  if not FileExists(Nome) then
  begin
    DXTimer1.Enabled := True;
    Exit;
  end;
  ImageLutador.Picture.LoadFromFile(Nome);
  if FFrameSheet = nil then FFrameSheet := TDirectDrawSurface.Create;
  FFrameSheet.LoadFromGraphic(ImageLutador.Picture.Graphic);
  Desloc := 0;
  if Jogador = 1 then Desloc := 0;
  if Jogador = 2 then Desloc := 50;

  Lutador[Jogador].Personagem := Personagem;
  case Personagem of
    1: Lutador[Jogador].AlturaSprite := 156;
    2: Lutador[Jogador].AlturaSprite := 162;
    3: Lutador[Jogador].AlturaSprite := 147;
    4: Lutador[Jogador].AlturaSprite := 149;
    5: Lutador[Jogador].AlturaSprite := 144;
    6: Lutador[Jogador].AlturaSprite := 190;
    7: Lutador[Jogador].AlturaSprite := 160;
    8: Lutador[Jogador].AlturaSprite := 160;
    9: Lutador[Jogador].AlturaSprite := 150;
    10: Lutador[Jogador].AlturaSprite := 155;
    11: Lutador[Jogador].AlturaSprite := 155;
    12: Lutador[Jogador].AlturaSprite := 165;
    13: Lutador[Jogador].AlturaSprite := 155;
    14: Lutador[Jogador].AlturaSprite := 160;
    15: Lutador[Jogador].AlturaSprite := 165;
  end;

  W := FFrameSheet.Width;
  H := FFrameSheet.Height;
  Ini := 0;
  Cont := 1;
  for Col := 0 to W - 1 do
  begin
    C1 := FFrameSheet.Pixels[Col, 0];
    C2 := FFrameSheet.Pixels[Col, H - 1];
    if Escuro(C1) and Escuro(C2) then
    begin
      copiabmp(Cont + Desloc, Ini, 0, Col - 1, H - 1);
      Inc(Cont);
      Ini := Col + 1;
    end;
  end;
  DXTimer1.Enabled := True;
end;

procedure TForm1.carregarcenario(const Nome: string);
var
  Item: TPictureCollectionItem;
begin
  DXTimer1.Enabled := False;
  if FileExists(Nome) then
  begin
    Item := DXImageListCenario.Items[0];
    Item.Picture.LoadFromFile(Nome);
    Item.Name := 'Cenario';
    Item.SystemMemory := False;
    Item.Transparent := False;
    Item.TransparentColor := CorTransparente;
    Item.Restore;
  end;
  ItemBonus.Icone := 0;
  if CenarioAtual = 2 then
  begin
    ItemBonus.X := 395;
    ItemBonus.Y := 195;
    ItemBonus.Dx1 := 25;
    ItemBonus.Dy1 := 25;
    ItemBonus.Dx2 := 110;
    ItemBonus.Dy2 := 90;
    ItemBonus.Icone := 6;
  end;
  DXTimer1.Enabled := True;
end;

{ Variante 1 = imagem normal, 2 = espelhada na horizontal }
procedure TForm1.carregarosto(const Nome: string; Variante: Byte);
var
  Item: TPictureCollectionItem;
  Folha: TDirectDrawSurface;
begin
  DXImageListRetrato.Items.Add;
  if not FileExists(Nome) then Exit;
  Item := DXImageListRetrato.Items[DXImageListRetrato.Items.Count - 1];
  ImageRetrato.Picture.LoadFromFile(Nome);
  Item.Name := 'Rosto';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;
  if Variante = 1 then
  begin
    Item.Picture.Assign(ImageRetrato.Picture);
    Item.Restore;
  end
  else
  begin
    Folha := TDirectDrawSurface.Create;
    try
      Folha.LoadFromGraphic(ImageRetrato.Picture.Graphic);
      Item.AssignRegion(Folha, 0, 0, Folha.Width, Folha.Height, True);
    finally
      Folha.Free;
    end;
  end;
end;

procedure TForm1.carregarfala(const Nome: string);
var
  N: Integer;
begin
  DXWaveListVitoria.Items.Add;
  N := DXWaveListVitoria.Items.Count;
  if FileExists(Nome) then DXWaveListVitoria.Items[N - 1].Wave.LoadFromFile(Nome);
end;

procedure TForm1.carregaranimacao(const Nome: string);
var
  Item: TPictureCollectionItem;
begin
  DXImageListAnimacao.Items.Add;
  if not FileExists(Nome) then Exit;
  Item := DXImageListAnimacao.Items[DXImageListAnimacao.Items.Count - 1];
  ImageRetrato.Picture.LoadFromFile(Nome);
  Item.Picture.Assign(ImageRetrato.Picture);
  Item.Name := 'Animacao';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;
  Item.Restore;
end;

procedure TForm1.carregareftsonoro(const Nome: string);
var
  N: Integer;
begin
  DXWaveListSnd.Items.Add;
  N := DXWaveListSnd.Items.Count;
  if FileExists(Nome) then DXWaveListSnd.Items[N - 1].Wave.LoadFromFile(Nome);
end;

procedure TForm1.carregarmusica(Numero: Byte);
var
  Nome: string;
begin
  Nome := '';
  if Numero < 10 then Nome := 'Musicas/Musica-0' + IntToStr(Numero) + '.wav';
  if Numero >= 10 then Nome := 'Musicas/Musica-' + IntToStr(Numero) + '.wav';
  if FileExists(Nome) then
  begin
    DXWaveListMusica.Items[0].Wave.LoadFromFile(Nome);
    DXSound1.Initialize;
    MusicaAtual := Numero;
  end;
end;

{ Efeitos: uma imagem normal e uma espelhada, em listas separadas }
procedure TForm1.carregarefeitos(const Nome: string);
var
  Item: TPictureCollectionItem;
  Folha: TDirectDrawSurface;
begin
  DXImageListEfeitos.Items.Add;
  DXImageListEfeitosInvert.Items.Add;
  if not FileExists(Nome) then Exit;

  Item := DXImageListEfeitos.Items[DXImageListEfeitos.Items.Count - 1];
  ImageRetrato.Picture.LoadFromFile(Nome);
  Item.Picture.Assign(ImageRetrato.Picture);
  Item.Name := 'Efeitos';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;
  Item.Restore;

  Item := DXImageListEfeitosInvert.Items[DXImageListEfeitosInvert.Items.Count - 1];
  Folha := TDirectDrawSurface.Create;
  try
    Folha.LoadFromGraphic(ImageRetrato.Picture.Graphic);
    Item.AssignRegion(Folha, 0, 0, Folha.Width, Folha.Height, True);
  finally
    Folha.Free;
  end;
  Item.Name := 'Efeitos';
  Item.SystemMemory := False;
  Item.Transparent := True;
  Item.TransparentColor := CorTransparente;
end;

{ ===================================================================== }
{ Recordes e dados                                                      }
{ ===================================================================== }

procedure TForm1.criarecorde(Posicao: Integer; const Nome: string; Personagem: Byte; Pontos: Integer);
begin
  Recordes[Posicao].Nome := Copy(Nome, 1, 3);
  Recordes[Posicao].Personagem := Personagem;
  Recordes[Posicao].Pontos := Cardinal(Pontos);
end;

{ ordena em ordem decrescente de pontos }
procedure TForm1.ordenarecordista;
var
  I, J: Integer;
  T: TRecorde;
begin
  for I := 1 to 9 do
    for J := I + 1 to 10 do
      if Recordes[I].Pontos < Recordes[J].Pontos then
      begin
        T := Recordes[I];
        Recordes[I] := Recordes[J];
        Recordes[J] := T;
      end;
end;

procedure TForm1.zerardados(Jogador: Integer);
var
  I: Integer;
begin
  with Lutador[Jogador] do
  begin
    Vida := VidaMax;
    VidaBarra := VidaMax;
    Acao := 1;
    VelY := 0;
    Vencedor := 0;
    Acertos := 0;
    TempoAcertos := 0;
    GolpeAtivo := 0;
    AtrasoBarra := 0;
    NoAr := 0;
  end;
  Lutador[1].X := 220.0;
  Lutador[2].X := 380.0;
  ChaoY := 300;
  Lutador[Jogador].Y := ChaoY;
  Lutador[1].Lado := 1;
  Lutador[2].Lado := 2;
  Lutador[1].DesenhaPorCima := 1;
  Lutador[2].DesenhaPorCima := 0;
  with Lutador[Jogador] do
  begin
    Velocidade := 8.0;
    case Personagem of
      3, 9: Velocidade := 8.5;
      6, 7, 10, 13, 14: Velocidade := 7.5;
    end;
  end;
  DeslocHudTopo := 0;
  DeslocHudBase := 0;
  PrimeiroAtaque := 0;
  CameraX := Round((Lutador[1].X + Lutador[2].X) / 2) - 200;
  CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  for I := 1 to MaxEfeitos do Efeitos[I].Tipo := 0;
end;

{ ===================================================================== }
{ Configuracao                                                          }
{ ===================================================================== }

procedure TForm1.SalvarConfiguracao;
begin
  with MemoConfigSalvo.Lines do
  begin
    Clear;
    Add(IntToStr(NivelJogo));
    if TempoRound = 1 then Add('1');
    if TempoRound = 2 then Add('2');
    if TempoRound = 3 then Add('3');
    if TempoRound = 4 then Add('4');
    Add(IntToStr(ModoPoder));
    Add(FloatToStr(NivelDano));
    if Sangue = 0 then Add('0');
    if Sangue = 1 then Add('1');
    Add(IntToStr(NumRounds));
    Add(IntToStr(Idioma));
    if Flash = 0 then Add('0');
    if Flash = 1 then Add('1');
    if MostrarNivel = 0 then Add('0');
    if MostrarNivel = 1 then Add('1');
    if MostrarCreditos = 0 then Add('0');
    if MostrarCreditos = 1 then Add('1');
  end;
  try
    MemoConfigSalvo.Lines.SaveToFile('Chaves.dat');
  except
    // pasta somente leitura: ignora (o original tambem nao tratava)
  end;
end;

{ Modo 1 = janela 400x300; 2 = tela cheia mantendo proporcao; 3 = tela cheia esticada.
  (O original trocava o modo de video do DirectDraw.) }
procedure TForm1.AplicarResolucao(Modo: Integer);
var
  SW, SH, W, H: Integer;
begin
  if Modo = 1 then
  begin
    BorderStyle := bsNone;
    WindowState := wsNormal;
    ClientWidth := LarguraTela;
    ClientHeight := AlturaTela;
    DXDraw1.SetBounds(0, 0, LarguraTela, AlturaTela);
    Position := poScreenCenter;
    Exit;
  end;
  SW := Screen.Width;
  SH := Screen.Height;
  BorderStyle := bsNone;
  SetBounds(0, 0, SW, SH);
  Color := clBlack;
  if Modo = 2 then
  begin
    H := SH;
    W := (SH * 4) div 3;
    if W > SW then
    begin
      W := SW;
      H := (SW * 3) div 4;
    end;
    DXDraw1.SetBounds((SW - W) div 2, (SH - H) div 2, W, H);
  end
  else
    DXDraw1.SetBounds(0, 0, SW, SH);
end;

{ ===================================================================== }
{ Eventos do formulario                                                 }
{ ===================================================================== }

procedure TForm1.FormCreate(Sender: TObject);
var
  I, K: Integer;
  Nome: string;
  Ok: Boolean;
begin
  CriaComponentesDX;
  KeyPreview := True;
  OnKeyUp := FormKeyUp;               // entrada de teclado portavel (DXInput)
  OnDeactivate := FormDeactivate;
  FFrameSheet := nil;
  { o original procurava os arquivos na pasta corrente: vamos para a pasta do jogo }
  Nome := DXResolvePath('Cenarios/Cenario-01.bmp');
  if FileExists(Nome) then SetCurrentDir(ExtractFilePath(ExtractFileDir(Nome)));

  Randomize;
  CheatChurros := 0;
  CheatGentalha := 0;
  CheatSatanas := 0;
  BonusEnergeticos := 0;
  CheatFadiga := 0;
  CheatMentecapto := 0;
  CheatBruxa := 0;
  CenarioSecreto := 0;
  { "truques" liberados pela simples existencia de arquivos .dat na pasta do jogo }
  if FileExists('Churros.dat') then CheatChurros := 1;
  if FileExists('Gentalha.dat') then CheatGentalha := 1;
  if FileExists('Energeticos.dat') then BonusEnergeticos := 0.15;
  if FileExists('Satanas.dat') then CheatSatanas := 1;
  if FileExists('Fadiga.dat') then CheatFadiga := 1;
  if FileExists('Mentecapto.dat') then CheatMentecapto := 1;
  if FileExists('Bruxa.dat') then CheatBruxa := 1;
  for I := 1 to 12 do
  begin
    if I < 10 then
      if FileExists('SC0' + IntToStr(I) + '.dat') then CenarioSecreto := I;
    if I >= 10 then
      if FileExists('SC' + IntToStr(I) + '.dat') then CenarioSecreto := I;
  end;

  Versao := 'V1.5A';
  Indef_4488 := 0;
  Indef_448C := 0;
  Indef_4490 := 0;
  LogoMeiaAltura := 0;
  Estado := CHS_RESOLUCAO;
  ContPisca := 0;
  TempoEstado := 0;
  CameraX := 0;
  CameraY := 0;
  FaseSelecao := 1;
  CursorMenu := 1;
  ContagemSeg := 30;
  ContagemTick := 25;
  TempoDialogo := 0;
  Depurar := 0;
  MostrarCaixas := 0;
  PassoAPasso := 0;
  Pausado := 0;
  TempoDemo := 0;
  Voador.Alcance := 330;
  GanhoCarga := 2.0;
  MusicaPendente := 0;
  RoundAtual := 1;
  Fase := 1;
  FaseIntro := 0;
  FaseFim := 0;
  RelogioParado := 1;
  for I := 1 to 2 do
    with Lutador[I] do
    begin
      CargaPoder := 0;
      Poder := 0;
      RoundsVencidos := 0;
      Pontos := 0;
      for K := 1 to 8 do Adversarios[K] := 1;
    end;
  IntervaloTimer := 28;
  Gravidade := 4;
  ModoPoder := 1;
  NivelJogo := 4;
  NivelDano := 0.9;
  Sangue := 1;
  NumRounds := 2;
  TempoRound := 3;
  Idioma := 1;
  Flash := 1;
  MostrarNivel := 1;
  MostrarCreditos := 1;

  { configuracao salva (Chaves.dat) }
  if FileExists('Chaves.dat') then
  begin
    MemoConfigSalvo.Lines.Clear;
    MemoConfigSalvo.Lines.LoadFromFile('Chaves.dat');
    with MemoConfigSalvo.Lines do
    begin
      if Count >= 1 then NivelJogo := StrToIntDef(Strings[0], NivelJogo);
      if Count >= 2 then
      begin
        if Strings[1] = '1' then TempoRound := 1;
        if Strings[1] = '2' then TempoRound := 2;
        if Strings[1] = '3' then TempoRound := 3;
        if Strings[1] = '4' then TempoRound := 4;
      end;
      if Count >= 3 then ModoPoder := StrToIntDef(Strings[2], ModoPoder);
      if Count >= 4 then NivelDano := StrToFloatDef(Strings[3], NivelDano);
      if Count >= 5 then
      begin
        if Strings[4] = '0' then Sangue := 0;
        if Strings[4] = '1' then Sangue := 1;
      end;
      if Count >= 6 then NumRounds := StrToIntDef(Strings[5], NumRounds);
      if Count >= 7 then Idioma := StrToIntDef(Strings[6], Idioma);
      if Count >= 8 then
      begin
        if Strings[7] = '0' then Flash := 0;
        if Strings[7] = '1' then Flash := 1;
      end;
      if Count >= 9 then
      begin
        if Strings[8] = '0' then MostrarNivel := 0;
        if Strings[8] = '1' then MostrarNivel := 1;
      end;
      if Count >= 10 then
      begin
        if Strings[9] = '0' then MostrarCreditos := 0;
        if Strings[9] = '1' then MostrarCreditos := 1;
      end;
    end;
  end;
  if NivelJogo < 1 then NivelJogo := 1;
  if NivelJogo > 8 then NivelJogo := 8;
  if TempoRound < 1 then TempoRound := 1;
  if TempoRound > 4 then TempoRound := 4;
  if ModoPoder < 1 then ModoPoder := 1;
  if ModoPoder > 4 then ModoPoder := 4;
  if NivelDano < 0.3 then NivelDano := 0.3;
  if NivelDano > 2 then NivelDano := 2.0;
  if NumRounds < 1 then NumRounds := 1;
  if NumRounds > 3 then NumRounds := 3;
  if Idioma < 1 then Idioma := 1;
  if Idioma > 2 then Idioma := 2;

  { textos no idioma escolhido }
  CarregarTextos(Idioma, MemoNomes.Lines, MemoTexto.Lines, MemoConfig.Lines,
    MemoFrases.Lines, MemoDialogo.Lines, MemoFinais.Lines, MemoCenarios.Lines);

  Fichas := 0;                    // fichas (creditos)
  Lutador[1].Personagem := 1;
  Lutador[2].Personagem := 2;
  Lutador[1].Ativo := 0;
  Lutador[2].Ativo := 0;
  Lutador[1].Escolheu := 0;
  Lutador[2].Escolheu := 0;
  zerardados(1);
  zerardados(2);
  criarecorde(1, 'CHV', 1, 10000);
  criarecorde(2, 'SMD', 2, 8000);
  criarecorde(3, 'CHQ', 3, 7500);
  criarecorde(4, 'QUI', 4, 7000);
  criarecorde(5, 'DFL', 5, 6500);
  criarecorde(6, 'PGR', 6, 6000);
  criarecorde(7, 'SBR', 7, 5500);
  criarecorde(8, 'B71', 8, 5000);
  criarecorde(9, 'PTY', 9, 4500);
  criarecorde(10, 'NHO', 10, 4000);
  ordenarecordista;

  { janela e superficie de desenho 400x300 }
  Color := clBlack;
  DXDraw1.SurfaceWidth := LarguraTela;
  DXDraw1.SurfaceHeight := AlturaTela;
  DXDraw1.Display.Width := LarguraTela;
  DXDraw1.Display.Height := AlturaTela;
  if not DXDraw1.Initialized then DXDraw1.Initialize;
  AplicarResolucao(1);

  { recursos externos }
  for I := 1 to 78 do
    carregaranimacao(NomeNN('Animacoes/Anim-', '.bmp', I));
  for I := 1 to 102 do
  begin
    if I < 10 then carregarefeitos('Efeitos/Efeito-00' + IntToStr(I) + '.bmp');
    if (I >= 10) and (I < 100) then carregarefeitos('Efeitos/Efeito-0' + IntToStr(I) + '.bmp');
    if I >= 100 then carregarefeitos('Efeitos/Efeito-' + IntToStr(I) + '.bmp');
  end;

  { efeitos sonoros: Som-01.wav, Som-02.wav ... (o original carrega ate o primeiro faltante) }
  I := 1;
  Nome := NomeNN('Sons/Som-', '.wav', I);
  while FileExists(Nome) do
  begin
    Nome := NomeNN('Sons/Som-', '.wav', I);
    carregareftsonoro(Nome);
    Inc(I);
  end;
  QtdSons := I;
  if QtdSons > 3 then QtdSons := QtdSons - 2;

  { musicas: so conta quantas existem (Musica-01.wav ...) }
  I := 1;
  Nome := NomeNN('Musicas/Musica-', '.wav', I);
  while FileExists(Nome) do
  begin
    Nome := NomeNN('Musicas/Musica-', '.wav', I);
    Inc(I);
  end;
  QtdMusicas := I;
  if QtdMusicas > 3 then QtdMusicas := QtdMusicas - 2;

  for I := 1 to 15 do
  begin
    carregarfala(NomeNN('Falas/Fala-', '-a.wav', I));
    carregarfala(NomeNN('Falas/Fala-', '-b.wav', I));
  end;

  { rostos: a, a(espelhado), b, b(espelhado), c }
  for I := 1 to 15 do
  begin
    carregarosto(NomeNN('Rostos/R', '-a.bmp', I), 1);
    carregarosto(NomeNN('Rostos/R', '-a.bmp', I), 2);
    carregarosto(NomeNN('Rostos/R', '-b.bmp', I), 1);
    carregarosto(NomeNN('Rostos/R', '-b.bmp', I), 2);
    carregarosto(NomeNN('Rostos/R', '-c.bmp', I), 1);
  end;

  { quadros dos lutadores: 150 posicoes (2 jogadores x 75) em cada lista }
  for I := 1 to 150 do
  begin
    DXImageListLutador.Items.Add;
    DXImageListLutadorInvert.Items.Add;
  end;

  DXSound1.Initialize;
  Ok := True;
  if Ok then DXTimer1.Enabled := True;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Application.Terminate;
  FreeAndNil(FFrameSheet);
end;

procedure TForm1.DXDraw1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  MouseX := X;
  MouseY := Y;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Tk: Word;
begin
  DXKeyDown(Key);
  { teclado numerico vale como 1, 2 e 5 nas fichas/entradas }
  Tk := Key;
  if (Key = VK_NUMPAD1) or (Key = VK_NUMPAD2) or (Key = VK_NUMPAD5) then Tk := Key - 48;
  if Key = VK_ESCAPE then Application.Terminate;
  { - e = : velocidade do jogo }
  if (Key = VK_OEM_MINUS) and (IntervaloTimer < 80) then Inc(IntervaloTimer);
  if (Key = VK_OEM_PLUS) and (IntervaloTimer >= 1) then Dec(IntervaloTimer);
  if (Key = VK_OEM_MINUS) or (Key = VK_OEM_PLUS) then AvisoVelocidade := 30;
  { , e . : desloca a imagem }
  if (Key = VK_OEM_COMMA) and (DXDraw1.Left > -40) then DXDraw1.Left := DXDraw1.Left - 1;
  if (Key = VK_OEM_PERIOD) and (DXDraw1.Left < 40) then DXDraw1.Left := DXDraw1.Left + 1;
  { P = pausa }
  if Key = Ord('P') then
  begin
    if Pausado = 0 then
      Pausado := 1
    else
    begin
      DXTimer1.Enabled := True;
      Pausado := 0;
      PassoAPasso := 0;
    end;
  end;
  { G = pausa quadro a quadro durante a luta }
  if (Key = Ord('G')) and (Estado = CHS_LUTA) then
  begin
    if Pausado = 0 then
    begin
      Pausado := 1;
      PassoAPasso := 1;
    end
    else
    begin
      DXTimer1.Enabled := True;
      Pausado := 0;
      PassoAPasso := 0;
    end;
  end;
  { F1 = configuracoes }
  if (Key = VK_F1) and (Estado = CHS_ABERTURA) then
  begin
    Estado := CHS_CONFIG;
    CursorMenu := 1;
    SomPendente := 1;
    MusicaAtual := 1;
  end
  else if (Key = VK_F1) and (Estado = CHS_CONFIG) then
  begin
    Estado := CHS_ABERTURA;
    SalvarConfiguracao;
    if DXWaveListSnd.Items.Count > SomPendente then DXWaveListSnd.Items[SomPendente].Stop;
    if DXWaveListMusica.Items.Count > 0 then DXWaveListMusica.Items[0].Stop;
    SomPendente := 0;
    MusicaAtual := 0;
  end;
  { F2 = configuracao de teclas }
  if (Key = VK_F2) and (Estado = CHS_ABERTURA) then
  begin
    Estado := CHS_TECLAS;
    CursorMenu := 1;
  end
  else if (Key = VK_F2) and (Estado = CHS_TECLAS) then
    Estado := CHS_ABERTURA;
  { estado 3: captura a tecla para a acao CursorMenu (1..8) }
  if Estado = CHS_TECLAS then
  begin
    if ((Key >= 65) and (Key <= 90)) or ((Key >= 48) and (Key <= 57)) or
       ((Key >= 37) and (Key <= 40)) or ((Key >= 96) and (Key <= 105)) then
    begin
      if (CursorMenu >= 1) and (CursorMenu <= 8) then
        DXInput1.Keyboard.SetKey(TDXInputState(CursorMenu - 1), Key);
      Inc(CursorMenu);
    end;
  end;
  { tecla 1 = ficha/entrada do jogador 1; tecla 2 = jogador 2 }
  if (Estado = CHS_ABERTURA) and (Fichas > 0) then
  begin
    if (Tk = Ord('1')) and (Lutador[1].Ativo = 0) then
    begin
      Lutador[1].Ativo := 1;
      Lutador[1].Escolheu := 0;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Lutador[1].Personagem := 1;
      Dec(Fichas);
      Estado := CHS_SELECAO;
      FaseSelecao := 1;
      Fase := 1;
      if CheatGentalha = 1 then Fase := 8;
      ContagemSeg := 30;
      ContagemTick := 25;
      TempoEstado := 0;
    end;
    if (Tk = Ord('2')) and (Lutador[2].Ativo = 0) then
    begin
      Lutador[2].Ativo := 1;
      Lutador[2].Escolheu := 0;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Lutador[2].Personagem := 2;
      Dec(Fichas);
      Estado := CHS_SELECAO;
      FaseSelecao := 1;
      Fase := 1;
      if CheatGentalha = 1 then Fase := 8;
      ContagemSeg := 30;
      ContagemTick := 25;
      TempoEstado := 0;
    end;
  end;
  if (Estado = CHS_SELECAO) and (Fichas > 0) and (RelogioParado = 0) then
  begin
    if (Tk = Ord('1')) and (Lutador[1].Ativo = 0) then
    begin
      Lutador[1].Ativo := 1;
      Lutador[1].Escolheu := 0;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
    if (Tk = Ord('2')) and (Lutador[2].Ativo = 0) then
    begin
      Lutador[2].Ativo := 1;
      Lutador[2].Escolheu := 0;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
  end;
  if (Estado = CHS_LUTA) and (Fichas > 0) and (RelogioParado = 0) then
  begin
    if (Tk = Ord('1')) and (Lutador[1].Ativo = 0) then
    begin
      Lutador[1].Ativo := 1;
      Lutador[1].Escolheu := 0;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      AvisoEntrada := 100;
    end;
    if (Tk = Ord('2')) and (Lutador[2].Ativo = 0) then
    begin
      Lutador[2].Ativo := 1;
      Lutador[2].Escolheu := 0;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      AvisoEntrada := 100;
    end;
  end;
  if (Estado = CHS_CONTINUAR) and (Fichas > 0) and (ContagemSeg > 0) and (ContagemTick > 0) then
  begin
    if (Tk = Ord('1')) and (Lutador[1].Ativo = 0) then
    begin
      Lutador[1].Ativo := 1;
      Lutador[1].Escolheu := 0;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      if Lutador[1].Adversarios[1] = 0 then Estado := CHS_SELECAO else Estado := CHS_ADVERSARIOS;
      ContagemSeg := 30;
      ContagemTick := 25;
      ContPisca := 0;
      TempoEstado := 0;
    end;
    if (Tk = Ord('2')) and (Lutador[2].Ativo = 0) then
    begin
      Lutador[2].Ativo := 1;
      Lutador[2].Escolheu := 0;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      if Lutador[2].Adversarios[1] = 0 then Estado := CHS_SELECAO else Estado := CHS_ADVERSARIOS;
      ContagemSeg := 30;
      ContagemTick := 25;
      ContPisca := 0;
      TempoEstado := 0;
    end;
  end;
  { tecla 5 = insere ficha }
  if Tk = Ord('5') then
  begin
    if Fichas < 99 then
    begin
      Inc(Fichas);
      TocarSom(0);
      if (TempoDemo > 0) or (Estado = CHS_RECORDES) then
        if Fichas > 0 then
        begin
          Estado := CHS_ABERTURA;
          TempoEstado := 500;
          ContPisca := 0;
          CameraY := -200;
          TempoDemo := 0;
        end;
    end;
  end;
end;

{ ===================================================================== }

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  DXKeyUp(Key);
end;

procedure TForm1.FormDeactivate(Sender: TObject);
begin
  DXKeyReset;
end;

{ ===================================================================== }
{ Laco principal                                                        }
{ ===================================================================== }

{ Estado 0: escolha da resolucao }
procedure TForm1.Estado0_Resolucao;
var
  Cor: TColor;
  K1, K2: Byte;
begin
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 10, 'STREET CHAVES - O LUTADOR DA VILA', ACentro, 10, RGB(100, 100, 255));
  texto(200, 25, Versao, ACentro, 9, RGB(100, 100, 255));
  if ContPisca < 12 then
    texto(200, 100, 'SELECIONE A RESOLUÇÃO', ACentro, 10, Branco);
  texto(200, 130, '400x300', ACentro, 10, CinzaMedio);
  texto(200, 150, 'TELA CHEIA (1)', ACentro, 10, CinzaMedio);
  texto(200, 170, 'TELA CHEIA (2)', ACentro, 10, CinzaMedio);
  Cor := Branco;
  if ContPisca <= 5 then Cor := Branco;
  if (ContPisca > 5) and (ContPisca <= 10) then Cor := RGB(225, 225, 225);
  if ContPisca > 10 then Cor := RGB(195, 195, 195);
  if CursorMenu = 1 then texto(200, 130, '400x300', ACentro, 10, Cor);
  if CursorMenu = 2 then texto(200, 150, 'TELA CHEIA (1)', ACentro, 10, Cor);
  if CursorMenu = 3 then texto(200, 170, 'TELA CHEIA (2)', ACentro, 10, Cor);
  DXImageListIcone.Items[0].Draw(DXDraw1.Surface, 150, 220, 0);
  DXImageListIcone.Items[1].Draw(DXDraw1.Surface, 165, 220, 0);
  texto(200, 220, '      - SELECIONA', ACentro, 7, Branco);
  texto(200, 230, 'Z - CONFIRMA', ACentro, 7, Branco);
  Cor := Rosa;
  if ContPisca <= 8 then Cor := RGB(255, 150, 150);
  texto(200, 270, 'ESTE JOGO É FREEWARE - PROIBIDO COMERCIALIZAR', ACentro, 8, Cor);

  DXInput1.Update;
  K1 := TecP1;
  K2 := TecP2;
  if ((K1 and 1) <> 0) and (Lutador[1].AntCima = 0) then Dec(CursorMenu);
  if ((K1 and 2) <> 0) and (Lutador[1].AntBaixo = 0) then Inc(CursorMenu);
  if ((K2 and 1) <> 0) and (Lutador[2].AntCima = 0) then Dec(CursorMenu);
  if ((K2 and 2) <> 0) and (Lutador[2].AntBaixo = 0) then Inc(CursorMenu);
  if CursorMenu < 1 then CursorMenu := 1;
  if CursorMenu > 3 then CursorMenu := 3;

  if isButton1 in DXInput1.States then
  begin
    AplicarResolucao(CursorMenu);
    Estado := CHS_ABERTURA;
    CameraY := 0;
    ContPisca := 0;
    TempoEstado := 0;
  end;
  Inc(ContPisca);
  if ContPisca > 15 then ContPisca := 0;
end;

{ Estado 1: abertura (predio, vila, logo) e modo "attract" }
procedure TForm1.Estado1_Abertura;
var
  Ab: TDXImageList;
  Sup: TDirectDrawSurface;
  I, J, L, L14: Integer;
  R: TRect;
  N: Integer;
  //Cor: TColor;
  S: string;
begin
  Ab := DXImageListAbertura;
  Sup := DXDraw1.Surface;
  barra(0, 0, LarguraTela, AlturaTela, Preto);

  if TempoEstado < 100 then
  begin
    barra(0, 0, LarguraTela, AlturaTela, RGB(120, 120, 250));
    Ab.Items[14].Draw(Sup, 110, 10, 0);
    texto(200, 210, Linha(MemoTexto, 13), ACentro, 16, RGB(250, 200, 0));
  end;

  if (TempoEstado >= 100) and (TempoEstado <= 370) then
  begin
    if TempoEstado = 100 then CameraY := 0;
    { ceu em faixas }
    for I := 0 to 20 do
      barra(0, I * 15, 400, I * 15 + 15, RGB(I * 2 + 120, I * 2 + 120, 200));
    { nuvens e folhagens }
    N := Round(CameraY / 2);
    Ab.Items[2].Draw(Sup, 50, 50 - N, 0);
    Ab.Items[2].Draw(Sup, 350, 150 - N, 0);
    Ab.Items[2].Draw(Sup, 300, 180 - N, 0);
    for J := 0 to 4 do
    begin
      Ab.Items[3].Draw(Sup, 50, J * 47 + 73 - N, 0);
      Ab.Items[3].Draw(Sup, 350, J * 47 + 173 - N, 0);
      Ab.Items[3].Draw(Sup, 300, J * 47 + 203 - N, 0);
    end;
    { predio (esquerda e direita) }
    for J := 0 to 6 do
    begin
      Ab.Items[0].Draw(Sup, 100, J * 80 - 200 - CameraY, 0);
      Ab.Items[0].Draw(Sup, 305, J * 80 - 200 - CameraY, 0);
    end;
    for L := 0 to 4 do
      for J := 0 to 15 do
        Ab.Items[1].Draw(Sup, L * 39 + 113, J * 32 - 200 - CameraY, 0);
    barra(147, -155 - CameraY, 270, -48 - CameraY, Preto);
    retangulo(149, -153 - CameraY, 268, -50 - CameraY, Branco);
    for L := 0 to 7 do
      Ab.Items[4].Draw(Sup, L * 50, 220 - CameraY, 0);
    for L := 0 to 8 do
    begin
      L14 := 0;
      if ContPisca < 10 then L14 := 4;
      Ab.Items[7].Draw(Sup, L * 50, 245 - CameraY + L14, 0);
      Ab.Items[5].Draw(Sup, L * 50 - 15, 245 - CameraY + L14, 0);
      Ab.Items[6].Draw(Sup, L * 50 + 15, 245 - CameraY + L14, 0);
    end;
    L14 := 0;
    if ContPisca > 10 then L14 := 5;
    if TempoEstado < 200 then
    begin
      Ab.Items[8].Draw(Sup, 210, L14 + 185 - CameraY, 0);
      Ab.Items[9].Draw(Sup, 50, L14 + 178 - CameraY, 0);
    end;
    if TempoEstado = 200 then TocarSom(9);
    if TempoEstado >= 200 then
    begin
      Ab.Items[11].Draw(Sup, 60 - ((TempoEstado - 200) shl 2),
        (TempoEstado - 200) * 2 + 180 - CameraY, 0);
      Ab.Items[10].Draw(Sup, 100, 190 - CameraY, 0);
    end;
  end;

  { logo que se expande: largura/altura do retangulo variam com TempoEstado }
  L := 0;
  if TempoEstado < 400 then L := 4;
  if (TempoEstado >= 400) and (TempoEstado <= 420) then L := TempoEstado - $18C;
  if (TempoEstado >= 420) and (TempoEstado <= 438) then L := 440 - TempoEstado;
  if TempoEstado >= 438 then L := 2;
  L14 := 0;
  if L <> 0 then
  begin
    L14 := Round(223 / L);
    LogoMeiaAltura := Round(117 / L);
  end;
  if Idioma = 1 then
  begin
    R := Rect(205 - L14, (-100 - CameraY) - LogoMeiaAltura, L14 + 205, (-100 - CameraY) + LogoMeiaAltura);
    Ab.Items[12].DrawAlpha(Sup, R, 0, 255);
  end;
  if Idioma = 2 then
  begin
    R := Rect(205 - L14, (-100 - CameraY) - LogoMeiaAltura, L14 + 205, (-100 - CameraY) + LogoMeiaAltura);
    Ab.Items[13].DrawAlpha(Sup, R, 0, 255);
  end;

  if TempoEstado > 440 then
    texto(320, 140, Versao, AEsq, 8, Branco);
  if TempoEstado > 440 then
  begin
    S := Linha(MemoTexto, 22);
    if TempoEstado < 500 then
    begin
      if Odd(TempoEstado) then
        texto(200 - ((500 - TempoEstado) shl 2), 170, S, ACentro, 12, AzulTitulo)
      else
        texto(((500 - TempoEstado) shl 2) + 200, 170, S, ACentro, 12, AzulTitulo);
    end;
    if TempoEstado >= 500 then
      texto(200, 170, S, ACentro, 12, AzulTitulo);
    Ab.Items[15].Draw(Sup, 5, 280, 0);
    texto(200, 253, Linha(MemoTexto, 26), ACentro, 8, Branco);
    texto(200, 267, Linha(MemoTexto, 31), ACentro, 8, Branco);
  end;

  if Fichas > 0 then
  begin
    TempoEstado := 500;
    CameraY := -200;
  end;
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  if TempoEstado < 1000 then Inc(TempoEstado);
  if TempoEstado > 235 then Dec(CameraY, 2);
  if CameraY < -200 then CameraY := -200;

  { fim da abertura: luta de demonstracao com 2 lutadores aleatorios }
  if TempoEstado > 650 then
  begin
    Estado := CHS_LUTA;
    FTick7 := 0;
    TempoDemo := 600;
    RelogioParado := 0;
    ContagemSeg := 99;
    ContagemTick := 25;
    FaseIntro := 72;
    FaseFim := 0;
    Lutador[1].Ativo := 0;
    Lutador[1].Acao := 1;
    Lutador[2].Ativo := 0;
    Lutador[2].Acao := 1;
    zerardados(1);
    zerardados(2);
    PausaImpacto := 0;
    FlashTela := 0;
    FlashVermelho := 0;
    TremorTela := 0;
    DeslocHudTopo := -120;
    DeslocHudBase := 60;
    CameraX := 100;
    PrimeiroAtaque := 1;
    L := Round(Random(120) / 10) + 1;
    if L < 1 then L := 1;
    if L > 12 then L := 12;
    CenarioAtual := L;
    carregarcenario(NomeNN('Cenarios/Cenario-', '.bmp', CenarioAtual));
    for L := 1 to 2 do
    begin
      I := Round(Random(150) / 10) + 1;
      if I < 1 then I := 1;
      if I > 15 then I := 15;
      Lutador[L].Personagem := I;
      carregarlutador(NomeNN('Lutadores/C', '.bmp', I), I, L);
    end;
  end;

  if (ContPisca < 12) and (Fichas = 0) then
    texto(200, 235, Linha(MemoTexto, 6), ACentro, 10, Branco);
  if (ContPisca < 12) and (Fichas > 0) then
    texto(200, 235, Linha(MemoTexto, 7), ACentro, 10, Branco);
  //Cor := 0;
  //if Cor = 1 then Y0 := 0;
end;

{ bits que acabaram de ser pressionados (P1 ou P2) neste quadro }
function TForm1.BordaTeclas: Byte;
var
  K1, K2, A1, A2: Byte;
  function Prev(const L: TLutador): Byte;
  begin
    Result := 0;
    if L.AntCima <> 0 then Result := Result or 1;
    if L.AntBaixo <> 0 then Result := Result or 2;
    if L.AntEsq <> 0 then Result := Result or 4;
    if L.AntDir <> 0 then Result := Result or 8;
    if L.AntSocoFraco <> 0 then Result := Result or 16;
    if L.AntChuteFraco <> 0 then Result := Result or 32;
    if L.AntSocoForte <> 0 then Result := Result or 64;
    if L.AntChuteForte <> 0 then Result := Result or 128;
  end;
begin
  K1 := TecP1;
  K2 := TecP2;
  A1 := Prev(Lutador[1]);
  A2 := Prev(Lutador[2]);
  Result := Byte((K1 and (not A1)) or (K2 and (not A2)));
end;

{ Estado 2: tela de configuracoes (F1) }
procedure TForm1.Estado2_Config;
const
  Rotulo: array[1..12] of Integer = (2, 3, 6, 11, 12, 13, 14, 17, 18, 19, 20, 21);
var
  Sel: TColor;
  I, Y, E: Integer;

  procedure Rot(R: Integer; Cor: TColor);
  begin
    texto(10, 45 + 15 * R, Linha(MemoConfig, Rotulo[R]), AEsq, 11, Cor);
  end;

  procedure Val(X, R, Idx: Integer; Cor: TColor);
  begin
    texto(X, 45 + 15 * R, Linha(MemoConfig, Idx), AEsq, 11, Cor);
  end;

begin
  Sel := AzulSelecao;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 5, Linha(MemoConfig, 1), ACentro, 15, Branco);
  for I := 1 to 12 do Rot(I, Branco);
  for I := 1 to 8 do texto((I - 1) * 10 + 140, 60, IntToStr(I), AEsq, 11, Branco);
  texto(140, 75, '30', AEsq, 11, Branco);
  texto(190, 75, '60', AEsq, 11, Branco);
  texto(240, 75, '90', AEsq, 11, Branco);
  texto(290, 75, '--', AEsq, 11, Branco);
  Val(140, 3, 7, Branco);
  Val(215, 3, 8, Branco);
  Val(280, 3, 9, Branco);
  Val(345, 3, 10, Branco);
  barraredonda(140, 110, 300, 121, 5, Branco, Preto);
  barra(142, 112, Round(78 * NivelDano) + 142, 119, Vermelho);
  barra(142, 113, Round(78 * NivelDano) + 142, 114, Rosa);
  texto(310, 105, IntToStr(Round(NivelDano * 100)) + '%', AEsq, 11, Branco);
  Val(140, 5, 4, Branco);
  Val(230, 5, 5, Branco);
  for I := 1 to 3 do texto((I - 1) * 30 + 140, 135, IntToStr(I), AEsq, 11, Branco);
  Val(140, 7, 15, Branco);
  Val(230, 7, 16, Branco);
  texto(140, 165, IntToStr(SomPendente) + ' / ' + IntToStr(QtdSons), AEsq, 11, Branco);
  texto(140, 180, IntToStr(MusicaAtual) + ' / ' + IntToStr(QtdMusicas), AEsq, 11, Branco);
  Val(140, 10, 4, Branco);
  Val(230, 10, 5, Branco);
  Val(140, 11, 4, Branco);
  Val(230, 11, 5, Branco);
  Val(140, 12, 4, Branco);
  Val(230, 12, 5, Branco);
  texto(200, 280, Linha(MemoConfig, 22), ACentro, 11, Branco);

  { destaque da linha selecionada e dos valores atuais }
  if (CursorMenu >= 1) and (CursorMenu <= 12) then Rot(CursorMenu, Sel);
  texto((NivelJogo - 1) * 10 + 140, 60, IntToStr(NivelJogo), AEsq, 11, Sel);
  case TempoRound of
    1: texto(140, 75, '30', AEsq, 11, Sel);
    2: texto(190, 75, '60', AEsq, 11, Sel);
    3: texto(240, 75, '90', AEsq, 11, Sel);
    4: texto(290, 75, '--', AEsq, 11, Sel);
  end;
  case ModoPoder of
    1: Val(140, 3, 7, Sel);
    2: Val(215, 3, 8, Sel);
    3: Val(280, 3, 9, Sel);
    4: Val(345, 3, 10, Sel);
  end;
  if Sangue = 1 then Val(140, 5, 4, Sel);
  if Sangue = 0 then Val(230, 5, 5, Sel);
  texto((NumRounds - 1) * 30 + 140, 135, IntToStr(NumRounds), AEsq, 11, Sel);
  if Idioma = 1 then Val(140, 7, 15, Sel);
  if Idioma = 2 then Val(230, 7, 16, Sel);
  if Flash = 1 then Val(140, 10, 4, Sel);
  if Flash = 0 then Val(230, 10, 5, Sel);
  if MostrarNivel = 1 then Val(140, 11, 4, Sel);
  if MostrarNivel = 0 then Val(230, 11, 5, Sel);
  if MostrarCreditos = 1 then Val(140, 12, 4, Sel);
  if MostrarCreditos = 0 then Val(230, 12, 5, Sel);

  { entrada }
  DXInput1.Update;
  E := BordaTeclas;
  if (E and 1) <> 0 then Dec(CursorMenu);
  if (E and 2) <> 0 then Inc(CursorMenu);
  if (E and 4) <> 0 then
  begin
    case CursorMenu of
      1: Dec(NivelJogo);
      2: Dec(TempoRound);
      3: Dec(ModoPoder);
      4: NivelDano := NivelDano - 0.1;
      5: Sangue := 1;
      6: Dec(NumRounds);
      7: if Idioma = 2 then
         begin
           Idioma := 1;
           CarregarTextos(Idioma, MemoNomes.Lines, MemoTexto.Lines, MemoConfig.Lines,
             MemoFrases.Lines, MemoDialogo.Lines, MemoFinais.Lines, MemoCenarios.Lines);
         end;
      8: if SomPendente > 1 then Dec(SomPendente);
      9: if MusicaAtual > 1 then Dec(MusicaAtual);
      10: Flash := 1;
      11: MostrarNivel := 1;
      12: MostrarCreditos := 1;
    end;
  end;
  if (E and 8) <> 0 then
  begin
    case CursorMenu of
      1: Inc(NivelJogo);
      2: Inc(TempoRound);
      3: Inc(ModoPoder);
      4: NivelDano := NivelDano + 0.1;
      5: Sangue := 0;
      6: Inc(NumRounds);
      7: if Idioma = 1 then
         begin
           Idioma := 2;
           CarregarTextos(Idioma, MemoNomes.Lines, MemoTexto.Lines, MemoConfig.Lines,
             MemoFrases.Lines, MemoDialogo.Lines, MemoFinais.Lines, MemoCenarios.Lines);
         end;
      8: if SomPendente < QtdSons then Inc(SomPendente);
      9: if MusicaAtual < QtdMusicas then Inc(MusicaAtual);
      10: Flash := 0;
      11: MostrarNivel := 0;
      12: MostrarCreditos := 0;
    end;
  end;
  if (E and 16) <> 0 then
  begin
    if CursorMenu = 8 then TocarSom(SomPendente - 1);
    if CursorMenu = 9 then
    begin
      carregarmusica(MusicaAtual);
      if (MusicaAtual <> 0) and (DXWaveListMusica.Items.Count > 0) then
        DXWaveListMusica.Items[0].Play(False);
    end;
  end;
  if (E and 32) <> 0 then
    if DXWaveListMusica.Items.Count > 0 then DXWaveListMusica.Items[0].Stop;

  { limites }
  if CursorMenu < 1 then CursorMenu := 12;
  if CursorMenu > 12 then CursorMenu := 1;
  if TempoRound < 1 then TempoRound := 1;
  if TempoRound > 4 then TempoRound := 4;
  if NivelJogo < 1 then NivelJogo := 1;
  if NivelJogo > 8 then NivelJogo := 8;
  if ModoPoder < 1 then ModoPoder := 1;
  if ModoPoder > 4 then ModoPoder := 4;
  if NivelDano < 0.3 then NivelDano := 0.3;
  if NivelDano > 2 then NivelDano := 2.0;
  if NumRounds < 1 then NumRounds := 1;
  if NumRounds > 3 then NumRounds := 3;
  if SomPendente < 1 then SomPendente := 1;
  if SomPendente > QtdSons then SomPendente := QtdSons;
  Y := 0;
  if Y = 1 then Y := 0;
end;

{ Estado 3: configuracao das teclas do jogador 1 (F2) }
procedure TForm1.Estado3_Teclas;
var
  Sel: TColor;
  I, K, Y: Integer;
begin
  Sel := AzulSelecao;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 5, Linha(MemoConfig, 23), ACentro, 15, Branco);
  for I := 1 to 8 do texto(50, 60 + 20 * I, Linha(MemoConfig, 23 + I), AEsq, 11, Branco);
  for I := 1 to 8 do
  begin
    K := DXInput1.Keyboard.GetKey(TDXInputState(I - 1));
    Y := (I - 1) * 20;
    case K of
      38: DXImageListIcone.Items[0].Draw(DXDraw1.Surface, 200, Y + 85, 0);
      40: DXImageListIcone.Items[1].Draw(DXDraw1.Surface, 200, Y + 85, 0);
      39: DXImageListIcone.Items[2].Draw(DXDraw1.Surface, 200, Y + 85, 0);
      37: DXImageListIcone.Items[3].Draw(DXDraw1.Surface, 200, Y + 85, 0);
    else
      if (K >= 96) and (K <= 105) then
        texto(200, Y + 80, 'Num' + IntToStr(K - 96), AEsq, 11, Branco)
      else
        texto(200, Y + 80, Chr(K and $FF), AEsq, 11, Branco);
    end;
  end;
  if (CursorMenu >= 1) and (CursorMenu <= 8) then
    texto(50, 60 + 20 * CursorMenu, Linha(MemoConfig, 23 + CursorMenu), AEsq, 11, Sel);
  DXInput1.Update;
  if CursorMenu < 1 then CursorMenu := 1;
  if CursorMenu > 9 then CursorMenu := 9;
  texto(200, 280, Linha(MemoConfig, 32), ACentro, 11, Branco);
end;

{ Sorteia a ordem dos 7 adversarios do jogador Jog (Adversarios[1..7]); o 8o e o chefe fixo. }
procedure TForm1.criaadversario(Jog, Pers: Integer);
const
  Chefe: array[1..15] of Byte = (2, 5, 9, 1, 2, 7, 2, 5, 3, 1, 3, 1, 5, 5, 3);
  { adversarios que nao podem aparecer para cada lutador (0 = fim da lista) }
  Excl: array[1..15, 0..4] of Byte = (
    (3, 9, 0, 0, 0), (3, 8, 9, 14, 15), (1, 2, 14, 0, 0), (5, 6, 0, 0, 0), (4, 6, 0, 0, 0),
    (4, 5, 15, 0, 0), (10, 8, 0, 0, 0), (2, 7, 0, 0, 0), (1, 2, 15, 0, 0), (7, 9, 0, 0, 0),
    (1, 9, 0, 0, 0), (5, 8, 0, 0, 0), (1, 8, 14, 0, 0), (2, 3, 13, 0, 0), (1, 2, 9, 0, 0));
var
  Disp: array[1..15] of Byte;
  I, K, R, Tent: Integer;

begin
  if (Pers < 1) or (Pers > 15) then Exit;
  for K := 1 to 8 do Lutador[Jog].Adversarios[K] := 1;
  Lutador[Jog].Adversarios[8] := Chefe[Pers];
  for I := 1 to 15 do Disp[I] := 1;
  Disp[Chefe[Pers]] := 0;
  for K := 0 to 4 do
    if Excl[Pers, K] <> 0 then Disp[Excl[Pers, K]] := 0;
  for K := 1 to 7 do
  begin
    Tent := 0;
    repeat
      R := Random(15) + 1;
      Inc(Tent);
    until ((Disp[R] <> 0) and (R <> Pers)) or (Tent > 2000);
    Lutador[Jog].Adversarios[K] := R;
    Disp[R] := 0;
  end;
end;

{ Estado 4: selecao de lutador }
procedure TForm1.Estado4_Selecao;
var
  I, J, C, X, Y, Ch, N: Integer;
  Cor, Cor2: TColor;
  K1, K2, E1, E2: Byte;
  R: TRect;

  procedure Som(Idx: Integer);
  begin
    TocarSom(Idx);
  end;

  procedure Retrato(Indice, PX, PY: Integer);
  begin
    if Indice < DXImageListRetrato.Items.Count then
      DXImageListRetrato.Items[Indice].Draw(DXDraw1.Surface, PX, PY, 0);
  end;

begin
  RelogioParado := 0;
  if (MusicaAtual <> 0) and (DXWaveListMusica.Items.Count > 0) then DXWaveListMusica.Items[0].Stop;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  barra(0, 300 - TempoEstado, 200, 600 - TempoEstado, RGB(120, 120, 255));
  barra(200, TempoEstado - 300, 400, TempoEstado, Rosa);
  { bandeiras repetidas ao fundo }
  for I := 0 to 3 do
    for J := 0 to 1 do
    begin
      N := 11;
      if Idioma = 2 then N := 12;
      DXImageListIcone.Items[N].Draw(DXDraw1.Surface, I * 145 - 67, (J * 200 - 200) + (ContagemTick shl 3), 0);
      DXImageListIcone.Items[N].Draw(DXDraw1.Surface, I * 145, (J * 200 - 100) + (ContagemTick shl 3), 0);
    end;
  { faixa com os retratos }
  X := Round(TempoEstado * 1.35);
  barra(X - 410, 156, X, 290, RGB(30, 50, 70));
  barra(X - 410, 158, X, 160, Branco);
  barra(X - 410, 286, X, 288, Branco);
  for C := 0 to 14 do
  begin
    if C < 8 then Ch := X + (C * 49 - 402) else Ch := X + ((C - 8) * 49 - 402);
    if C + C * 4 < DXImageListRetrato.Items.Count then
    begin
      if C < 8 then R := Rect(Ch, 163, Ch + 50, 223) else R := Rect(Ch, 223, Ch + 50, 283);
      DXImageListRetrato.Items[C + C * 4].DrawAlpha(DXDraw1.Surface, R, 0, 60);
    end;
  end;
  if FaseSelecao = 1 then
  begin
    Inc(TempoEstado, 20);
    if TempoEstado >= 300 then
    begin
      TempoEstado := 300;
      FaseSelecao := 2;
    end;
  end;
  if FaseSelecao = 2 then
  begin
    for J := 1 to 2 do
    begin
      if Lutador[J].Ativo = 1 then
      begin
        Ch := Lutador[J].Personagem;
        if J = 1 then X := 52 else X := 252;
        Retrato((Ch - 1) * 5 + 4, X, 25);
        if Lutador[J].Escolheu = 0 then
        begin
          if Ch <= 8 then
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 1) * 49 - 402), 163)
          else
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 9) * 49 - 402), 223);
        end;
        if J = 1 then X := 100 else X := 300;
        texto(X, 130 - Round(Cos(ContPisca / 4.3) * 4), Linha(MemoNomes, Ch), ACentro, 12, RGB(180, 220, 160));
      end;
    end;
    N := Round(Cos(ContagemTick / 4) * 20);
    Cor := RGB(N + 230, N + 230, 255);
    texto(200, Round(TempoEstado * 0.3) - 96, Linha(MemoTexto, 8), ACentro, 18, Cor);
    Cor := RGB(250, 150, 150);
    if (ContagemSeg <= 5) and (not Odd(ContagemTick)) then Cor := RGB(250, 220, 220);
    texto(200, 15, IntToStr(ContagemSeg), ACentro, 22, Cor);
    if ContagemSeg >= 1 then
    begin
      Dec(ContagemTick);
      if ContagemTick = 0 then
      begin
        Dec(ContagemSeg);
        ContagemTick := 25;
      end;
    end;
    Inc(ContPisca);
    if ContPisca >= 25 then ContPisca := 0;
    { marcadores 1P / 2P sobre o retrato escolhido }
    for J := 1 to 2 do
      if (Lutador[J].Ativo = 1) and (Lutador[J].Escolheu = 0) then
      begin
        X := 10;
        Y := 20;
        Ch := Lutador[J].Personagem;
        if Ch <= 8 then
        begin
          X := (Ch - 1) * 49 + 3;
          Y := 160;
        end
        else
        begin
          X := (Ch - 9) * 49 + 3;
          Y := 220;
        end;
        if not Odd(ContPisca) then Cor2 := RGB(50, 50, 50) else Cor2 := Preto;
        if J = 1 then
          texto(X, Y, '1P', AEsq, 10, RGB(100, 100, 200) + Cor2)
        else
          texto(X + 35, Y, '2P', AEsq, 10, RGB(200, 50, 50) + Cor2);
      end;

    DXInput1.Update;
    K1 := TecP1;
    K2 := TecP2;
    { jogador 1 (teclado) }
    if (Lutador[1].Escolheu = 0) and (Lutador[1].Ativo = 1) then
    begin
      if ((K1 and 4) <> 0) and (Lutador[1].AntEsq = 0) then
      begin
        Dec(Lutador[1].Personagem);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K1 and 8) <> 0) and (Lutador[1].AntDir = 0) then
      begin
        Inc(Lutador[1].Personagem);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K1 and 1) <> 0) and (Lutador[1].AntCima = 0) and (Lutador[1].Personagem > 8) then
      begin
        Dec(Lutador[1].Personagem, 8);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K1 and 2) <> 0) and (Lutador[1].AntBaixo = 0) and (Lutador[1].Personagem <= 8) then
      begin
        Inc(Lutador[1].Personagem, 8);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K1 and 16) <> 0) and (Lutador[1].AntSocoFraco = 0) then
      begin
        Lutador[1].Escolheu := 1;
        criaadversario(1, Lutador[1].Personagem);
        Som(2);
      end;
    end;
    { jogador 2 (joystick emulado) }
    if (Lutador[2].Escolheu = 0) and (Lutador[2].Ativo = 1) then
    begin
      if ((K2 and 4) <> 0) and (Lutador[2].AntEsq = 0) then
      begin
        Dec(Lutador[2].Personagem);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K2 and 8) <> 0) and (Lutador[2].AntDir = 0) then
      begin
        Inc(Lutador[2].Personagem);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K2 and 1) <> 0) and (Lutador[2].AntCima = 0) and (Lutador[2].Personagem > 8) then
      begin
        Dec(Lutador[2].Personagem, 8);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K2 and 2) <> 0) and (Lutador[2].AntBaixo = 0) and (Lutador[2].Personagem <= 8) then
      begin
        Inc(Lutador[2].Personagem, 8);
        if DXWaveListSnd.Items.Count > 1 then Som(1);
      end;
      if ((K2 and 16) <> 0) and (Lutador[2].AntSocoFraco = 0) then
      begin
        Lutador[2].Escolheu := 1;
        criaadversario(2, Lutador[2].Personagem);
        Som(2);
      end;
    end;
    for J := 1 to 2 do
    begin
      if Lutador[J].Personagem < 1 then Lutador[J].Personagem := 15;
      if Lutador[J].Personagem > 15 then Lutador[J].Personagem := 1;
    end;
    if Lutador[1].Ativo = 0 then Lutador[1].Escolheu := 1;
    if Lutador[2].Ativo = 0 then Lutador[2].Escolheu := 1;
    { tempo esgotado: confirma automaticamente }
    if ContagemSeg = 0 then
    begin
      Lutador[1].Escolheu := 1;
      if Lutador[1].Ativo = 1 then criaadversario(1, Lutador[1].Personagem);
      Lutador[2].Escolheu := 1;
      if Lutador[2].Ativo = 1 then criaadversario(2, Lutador[2].Personagem);
      Som(2);
    end;
    if (Lutador[1].Escolheu = 1) and (Lutador[2].Escolheu = 1) then
    begin
      Estado := CHS_ADVERSARIOS;
      ContPisca := 0;
      TempoEstado := 0;
      Lutador[1].RoundsVencidos := 0;
      Lutador[2].RoundsVencidos := 0;
      RoundAtual := 1;
      if (Lutador[1].Ativo = 1) and (Lutador[2].Ativo = 1) then Estado := CHS_PREPARALUTA;
    end;
  end;
  E1 := 0;
  E2 := 0;
  if E1 = E2 then N := 0;
end;

{ Estado 5: mostra a ordem dos adversarios e o cenario do proximo combate }
procedure TForm1.Estado5_Adversarios;
const
  CenPrimeiro: array[1..15] of Byte = (1, 2, 2, 3, 3, 4, 11, 1, 1, 11, 6, 1, 1, 2, 1);
  CenAlt: array[1..15] of Byte = (0, 7, 10, 10, 8, 8, 5, 9, 10, 10, 5, 9, 5, 1, 6);
var
  C, J, K, Ch, X, Y, N: Integer;
  K1, K2: Byte;

  procedure Retrato(Indice, PX, PY: Integer);
  begin
    if Indice < DXImageListRetrato.Items.Count then
      DXImageListRetrato.Items[Indice].Draw(DXDraw1.Surface, PX, PY, 0);
  end;

begin
  for C := 0 to 60 do
    barra(0, C * 10, 400, C * 10 + 10, RGB(C * 2 + 10, C * 3 + 20, C * 4 + 30));
  if Fase < 1 then Fase := 1;
  if Fase > 8 then Fase := 8;
  if (MusicaAtual <> 0) and (DXWaveListMusica.Items.Count > 0) then DXWaveListMusica.Items[0].Stop;
  for J := 1 to 2 do
  begin
    Lutador[J].RoundsVencidos := 0;
    Lutador[J].CargaPoder := 0;
    Lutador[J].Poder := 0;
    Lutador[J].MaxAcertos := 0;
  end;

  for J := 1 to 2 do
    if Lutador[J].Ativo = 1 then
    begin
      Lutador[J].Escolheu := 1;
      Ch := TempoEstado;
      if Ch < 30 then
        texto(200 - (Ch - 30) * 20, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      if (Ch >= 30) and (Ch <= 100) then
        texto(200, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      if Ch > 100 then
        texto(200 - (Ch - 100) * 20, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      { o oponente da rodada atual vai para o outro lutador }
      Lutador[3 - J].Personagem := Lutador[J].Adversarios[Fase];
      if TempoEstado > 40 then
        texto(200, 180, Linha(MemoNomes, Lutador[3 - J].Personagem), ACentro, 15, Branco);
      for K := 1 to 8 do
      begin
        Ch := Lutador[J].Adversarios[K];
        N := 470 - TempoEstado * 5;
        Y := 220;
        if TempoEstado < 50 then Y := N;
        X := 48 * K - 40;
        if (Ch * 5 - 4 < DXImageListRetrato.Items.Count) and (Fase >= K) then
          Retrato(Ch * 5 - 5 + 1, X, Y);
        if (Ch * 5 - 4 < DXImageListRetrato.Items.Count) and (Fase > K) then
        begin
          if TempoEstado < 50 then
            DXImageListIcone.Items[10].Draw(DXDraw1.Surface, 48 * K - 35, 485 - TempoEstado * 5, 0)
          else
            DXImageListIcone.Items[10].Draw(DXDraw1.Surface, 48 * K - 35, 235, 0);
        end;
        if CheatChurros = 0 then
        begin
          if Fase < K then DXImageListIcone.Items[9].Draw(DXDraw1.Surface, X, Y, 0);
        end
        else if Fase < K then
          Retrato(Ch * 5 - 5 + 1, X, Y);
      end;
    end;

  if (TempoEstado >= 50) and (ContPisca <= 10) then
    DXImageListIcone.Items[8].Draw(DXDraw1.Surface, Fase * 48 - 20, 215, 0);
  if (TempoEstado > 60) and (DXImageListCenario.Items.Count > 0) then
  begin
    DXImageListCenario.Items[0].StretchDraw(DXDraw1.Surface, Rect(80, 6, 320, 134), 0);
    texto(200, 115, Linha(MemoCenarios, CenarioAtual - 1), ACentro, 9, Branco);
  end;

  { no primeiro quadro: escolhe e carrega o cenario do adversario }
  if TempoEstado = 0 then
    for J := 1 to 2 do
      if Lutador[J].Ativo = 0 then
      begin
        Ch := Lutador[J].Personagem;
        if (Ch >= 1) and (Ch <= 15) then
        begin
          CenarioAtual := CenPrimeiro[Ch];
          if (Random(5) <= 1) and (Fase < 8) and (CenAlt[Ch] <> 0) then CenarioAtual := CenAlt[Ch];
          if (Random(6) <= 1) and (Fase < 8) and (Ch in [3, 4, 9, 10, 11, 14]) then CenarioAtual := 12;
          if (CenarioSecreto <> 0) and (Fase < 8) then
          begin
            if CenarioSecreto < 1 then CenarioSecreto := 1;
            if CenarioSecreto > 12 then CenarioSecreto := 12;
            CenarioAtual := CenarioSecreto;
          end;
          carregarcenario(NomeNN('Cenarios/Cenario-', '.bmp', CenarioAtual));
        end;
      end;

  Inc(ContPisca);
  if ContPisca > 15 then ContPisca := 0;
  if TempoEstado < 1000 then Inc(TempoEstado);
  DXInput1.Update;
  K1 := TecP1;
  K2 := TecP2;
  if ((((K1 and 16) <> 0) and (Lutador[1].Ativo = 1)) or (((K2 and 16) <> 0) and (Lutador[2].Ativo = 1))) and
     (TempoEstado > 0) then
    Inc(TempoEstado, 5);
  if TempoEstado > 120 then
  begin
    for C := 0 to 15 do
      barra(0, C * 20, 400, C * 20 + (TempoEstado - 120), Preto);
    if TempoEstado > 150 then Estado := CHS_PREPARALUTA;
  end;
  if CheatFadiga = 1 then
  begin
    Estado := CHS_FINAL;
    ContPisca := 0;
    TempoEstado := 0;
  end;
end;

{ Estado 6: prepara a luta (carrega lutadores, cenario e musica) e passa ao estado 7 }
procedure TForm1.Estado6_PreparaLuta;
var
  J, L: Integer;
begin
  Estado := CHS_LUTA;
  FTick7 := 0;
  ContPisca := 0;
  TempoEstado := 0;
  MusicaPendente := 1;
  RelogioParado := 1;
  TempoDialogo := 0;
  case TempoRound of
    1: ContagemSeg := 30;
    2: ContagemSeg := 60;
    3: ContagemSeg := 90;
    4: ContagemSeg := 99;
  end;
  ContagemTick := 25;
  FaseIntro := 0;
  FaseFim := 0;
  CameraX := 100;
  TremorTela := 0;
  FlashTela := 0;
  PausaImpacto := 0;
  PrimeiroAtaque := 0;
  zerardados(1);
  zerardados(2);
  Lutador[1].CargaPoder := 0;
  Lutador[1].Poder := 0;
  Lutador[2].CargaPoder := 0;
  Lutador[2].Poder := 0;
  for L := 1 to MaxEfeitos do Efeitos[L].Tipo := 0;
  DXTimer1.Enabled := False;
  for J := 1 to 2 do
    if (Lutador[J].Personagem >= 1) and (Lutador[J].Personagem <= 15) then
      carregarlutador(NomeNN('Lutadores/C', '.bmp', Lutador[J].Personagem), Lutador[J].Personagem, J);
  if (Lutador[1].Ativo = 1) and (Lutador[2].Ativo = 1) then
  begin
    L := Round(Random(120) / 10) + 1;
    if L < 1 then L := 1;
    if L > 12 then L := 12;
    CenarioAtual := L;
    if CenarioSecreto <> 0 then
    begin
      if CenarioSecreto < 1 then CenarioSecreto := 1;
      if CenarioSecreto > 12 then CenarioSecreto := 12;
      CenarioAtual := CenarioSecreto;
    end;
    carregarcenario(NomeNN('Cenarios/Cenario-', '.bmp', CenarioAtual));
  end;
  MusicaAtual := 0;
  for J := 1 to 2 do
  begin
    if (Lutador[J].Personagem = 1) and (Lutador[J].Ativo = 0) then MusicaAtual := 4;
    if (Lutador[J].Personagem = 4) and (Lutador[J].Ativo = 0) then MusicaAtual := 2;
    if (Lutador[J].Personagem = 2) and (Lutador[J].Ativo = 0) then MusicaAtual := 3;
    if CenarioAtual = 12 then MusicaAtual := 6;
  end;
  if MusicaAtual = 0 then MusicaAtual := Round(Random(QtdMusicas * 10) / 10) + 1;
  if MusicaAtual < 1 then MusicaAtual := 1;
  if MusicaAtual > QtdMusicas then MusicaAtual := QtdMusicas;
  if (MusicaAtual = 6) and (CenarioAtual <> 12) then MusicaAtual := 1;
  carregarmusica(MusicaAtual);
  DXTimer1.Enabled := True;
end;

{$I ChavesLuta.inc}
{$I ChavesLuta7.inc}
{$I ChavesFim.inc}
{$I ChavesDX.inc}


{ Memoriza o estado das teclas deste quadro (deteccao de borda) e contadores de golpe }
procedure TForm1.MemorizaTeclas;
var
  K1, K2: Byte;
  I: Integer;
begin
  K1 := TecP1;
  K2 := TecP2;
  if ((K1 and 16) <> 0) and (Lutador[1].AntSocoFraco = 0) then Inc(Lutador[1].CargaSoco, 6)
  else if ((K1 and 64) <> 0) and (Lutador[1].AntSocoForte = 0) then Inc(Lutador[1].CargaSoco, 6);
  if ((K2 and 16) <> 0) and (Lutador[2].AntSocoFraco = 0) then Inc(Lutador[2].CargaSoco, 6)
  else if ((K2 and 64) <> 0) and (Lutador[2].AntSocoForte = 0) then Inc(Lutador[2].CargaSoco, 6);
  if ((K1 and 32) <> 0) and (Lutador[1].AntChuteFraco = 0) then Inc(Lutador[1].CargaChute, 6)
  else if ((K1 and 128) <> 0) and (Lutador[1].AntChuteForte = 0) then Inc(Lutador[1].CargaChute, 6);
  if ((K2 and 32) <> 0) and (Lutador[2].AntChuteFraco = 0) then Inc(Lutador[2].CargaChute, 6)
  else if ((K2 and 128) <> 0) and (Lutador[2].AntChuteForte = 0) then Inc(Lutador[2].CargaChute, 6);

  for I := 1 to 2 do
  begin
    if (Lutador[I].CargaSoco > 0) and (FlashTela = 0) and (PausaImpacto = 0) then Dec(Lutador[I].CargaSoco);
    if (Lutador[I].CargaChute > 0) and (FlashTela = 0) and (PausaImpacto = 0) then Dec(Lutador[I].CargaChute);
    if Lutador[I].CargaSoco > 15 then Lutador[I].CargaSoco := 15;
    if Lutador[I].CargaChute > 15 then Lutador[I].CargaChute := 15;
  end;

  { estado anterior das teclas (para deteccao de borda no proximo quadro) }
  Lutador[1].AntCima := Ord((K1 and 1) <> 0);
  Lutador[1].AntBaixo := Ord((K1 and 2) <> 0);
  Lutador[1].AntEsq := Ord((K1 and 4) <> 0);
  Lutador[1].AntDir := Ord((K1 and 8) <> 0);
  Lutador[1].AntSocoFraco := Ord((K1 and 16) <> 0);
  Lutador[1].AntChuteFraco := Ord((K1 and 32) <> 0);
  Lutador[1].AntSocoForte := Ord((K1 and 64) <> 0);
  Lutador[1].AntChuteForte := Ord((K1 and 128) <> 0);
  Lutador[2].AntCima := Ord((K2 and 1) <> 0);
  Lutador[2].AntBaixo := Ord((K2 and 2) <> 0);
  Lutador[2].AntEsq := Ord((K2 and 4) <> 0);
  Lutador[2].AntDir := Ord((K2 and 8) <> 0);
  Lutador[2].AntSocoFraco := Ord((K2 and 16) <> 0);
  Lutador[2].AntChuteFraco := Ord((K2 and 32) <> 0);
  Lutador[2].AntSocoForte := Ord((K2 and 64) <> 0);
  Lutador[2].AntChuteForte := Ord((K2 and 128) <> 0);
end;

{ Sobreposicoes comuns a quase todos os estados + apresentacao do quadro }
procedure TForm1.RodapeDoQuadro;
var
  L: Integer;
begin
  if (Estado <> CHS_CONFIG) and (Estado <> CHS_TECLAS) then
  begin
    if AvisoVelocidade > 0 then
    begin
      texto(200, 260, 'VELOCIDADE', ACentro, 8, Branco);
      L := 238 - Round(IntervaloTimer / 1.05);
      barra(160, 278, 240, 280, Branco);
      barra(L, 275, L + 2, 283, VermelhoAlerta);
      Dec(AvisoVelocidade);
    end;
    if MostrarNivel = 1 then
      texto(200, 285, Linha(MemoTexto, 18) + IntToStr(NivelJogo), ACentro, 10, Branco);
    if MostrarCreditos = 1 then
    begin
      texto(300, 285, Linha(MemoTexto, 19), AEsq, 10, Branco);
      texto(395, 285, IntToStr(Fichas), ADir, 10, Branco);
    end;
    { aviso "alguem entrou no combate" durante a demonstracao }
    if (AvisoEntrada > 0) and (Estado = CHS_LUTA) then
    begin
      barraredonda(80, 100, 320, 170, 10, Branco, Preto);
      texto(200, 100, Linha(MemoTexto, 10), ACentro, 15, RosaClaro);
      texto(200, 120, Linha(MemoTexto, 11), ACentro, 15, RosaClaro);
      texto(200, 140, Linha(MemoTexto, 12), ACentro, 15, RosaClaro);
      RelogioParado := 1;
      Dec(AvisoEntrada);
      if AvisoEntrada = 0 then
      begin
        Estado := CHS_SELECAO;
        FaseSelecao := 1;
        ContagemSeg := 20;
        ContagemTick := 25;
      end;
    end;
  end;
  DXDraw1.Surface.Canvas.Release;
  DXDraw1.Flip;
  if Pausado = 1 then DXTimer1.Enabled := False;
  MemorizaTeclas;
end;

procedure TForm1.DXTimer1Timer(Sender: TObject; LagCount: Integer);
begin
  DXDraw1.Surface.Canvas.Release;
  if CheatMentecapto = 1 then
  begin
    DeslocHudTopo := -90;
    DeslocHudBase := 40;
  end;
  DXTimer1.Interval := IntervaloTimer;

  { cada estado e testado em sequencia: uma transicao ja executa o proximo no mesmo quadro }
  if Estado = CHS_RESOLUCAO then Estado0_Resolucao;
  if Estado = CHS_ABERTURA then Estado1_Abertura;
  if Estado = CHS_CONFIG then Estado2_Config;
  if Estado = CHS_TECLAS then Estado3_Teclas;
  if Estado = CHS_SELECAO then Estado4_Selecao;
  if Estado = CHS_ADVERSARIOS then Estado5_Adversarios;
  if Estado = CHS_PREPARALUTA then Estado6_PreparaLuta;
  if Estado = CHS_LUTA then Estado7_Luta;
  if Estado = CHS_RECORDES then Estado8_Recordes;
  if Estado = CHS_CONTINUAR then Estado9_Continuar;
  if Estado = CHS_FINAL then Estado10_Final;
  if Estado = CHS_AVISO then Estado11_Aviso;
  if Estado = CHS_INICIAIS then Estado12_Iniciais;
  RodapeDoQuadro;
end;

end.
