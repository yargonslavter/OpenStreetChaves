unit ChavesGfx;

{ ChavesGfx.pas - graficos do jogo em software (substitui o DXDraws da camada DelphiX).

  Tudo e desenhado num buffer ARGB (0xAARRGGBB) na memoria; quem apresenta o quadro na tela e o
  ChavesSDL (textura SDL). Nao ha canvas, pincel ou caneta: cada primitiva recebe suas cores.

    TSuperficie    buffer de pixels + copias (normal, esticada, alfa, soma, subtracao, rotacao)
                   + retangulos, elipses, retangulos redondos e texto (fonte do atlas)
    TImagem        imagem com cor transparente e "padroes" (grade de quadros de uma folha)
    TListaImagens  lista numerada de imagens (ImgX[i].Draw(Tela, X, Y, Quadro)), com busca
                   opcional por nome (ImgX.PorNome('Mesa'); nomes vem de Dados/Recursos.ini)

  Cor "TColor" = 0x00BBGGRR (como no Delphi); pixel = 0xAARRGGBB. }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, DXTipos, DXBmp, DXFonte, DXClass;

type
  TBlendMode = (bmCopy, bmAlpha, bmAdd, bmSub);

  TSuperficie = class
  private
    FWidth, FHeight: Integer;
    FPix: array of Cardinal;
    FTransparentColor: TColor;
    FMap: array of Integer;           // buffer reutilizavel p/ mapeamento de colunas
    function GetPixel(X, Y: Integer): TColor;
    procedure SetPixel(X, Y: Integer; Value: TColor);
    function DoBlit(Mode: TBlendMode; const DestRect, SrcRect: TRect;
      Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
    function DoRotate(Mode: TBlendMode; X, Y, W, H: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    procedure Forma(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor;
      Preencher: Boolean);
  public
    constructor Create;
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Fill(Color: TColor);
    { carrega um BMP (1/4/8/16/24/32 bits) para a superficie; False se o arquivo nao existe/invalido }
    function CarregarBMP(const Arquivo: string): Boolean;
    function ScanLine(Y: Integer): PCardinal;
    { Draw: copia SrcRect de Image para (X,Y) }
    function Draw(X, Y: Integer; const SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean): Boolean; overload;
    function Draw(X, Y: Integer; Image: TSuperficie; Transparent: Boolean): Boolean; overload;
    function StretchDraw(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean): Boolean;
    { Alpha: 0..255 }
    function DrawAlpha(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean; Alpha: Integer): Boolean;
    function DrawAdd(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean; Alpha: Integer): Boolean;
    function DrawSub(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean; Alpha: Integer): Boolean;
    { Angle: 0..255 = 0..360 graus. CenterX/CenterY: pivo como fracao do retangulo (0.5 = centro). }
    function DrawRotate(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle: Integer): Boolean;
    function DrawRotateAlpha(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    function DrawRotateAdd(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    function DrawRotateSub(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    { primitivas (X2/Y2 exclusivos, como no Delphi) }
    procedure PreencherRect(const R: TRect; Cor: TColor);
    procedure Moldura(const R: TRect; Cor: TColor);
    procedure RoundRect(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor);
    procedure Elipse(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor; Preencher: Boolean);
    { texto da fonte do atlas (sombra e feita por quem chama); Tam = tamanho em pontos }
    procedure Texto(X, Y: Integer; const S: string; Tam: Integer; Cor: TColor);
    function LarguraTexto(const S: string; Tam: Integer): Integer;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Pixels[X, Y: Integer]: TColor read GetPixel write SetPixel;
    property TransparentColor: TColor read FTransparentColor write FTransparentColor;
  end;

  TImagem = class
  private
    FSurface: TSuperficie;
    FTransparent: Boolean;
    FTransparentColor: TColor;
    FPatternWidth, FPatternHeight: Integer;
    FPatterns: array of TRect;
    procedure SetTransparentColor(Value: TColor);
    procedure MontarPadroes;
    function GetPatternCount: Integer;
    function GetPatternRect(I: Integer): TRect;
    function GetWidth: Integer;
    function GetHeight: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    { carrega um BMP; PW/PH = tamanho de cada quadro da folha (0 = imagem inteira) }
    procedure CarregarArquivo(const Arquivo: string; Transparente: Boolean; CorTransp: TColor;
      PW: Integer = 0; PH: Integer = 0);
    { preenche com a regiao [X1,X2) x [Y1,Y2) de Src, opcionalmente espelhada na horizontal }
    procedure AtribuirRegiao(Src: TSuperficie; X1, Y1, X2, Y2: Integer; Mirror: Boolean;
      Transparente: Boolean; CorTransp: TColor);
    procedure Draw(Surface: TSuperficie; X, Y, PatternIndex: Integer);
    procedure StretchDraw(Surface: TSuperficie; const DestRect: TRect; PatternIndex: Integer);
    procedure DrawAlpha(Surface: TSuperficie; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawAdd(Surface: TSuperficie; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawSub(Surface: TSuperficie; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawRotate(Surface: TSuperficie; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle: Integer);
    procedure DrawRotateAlpha(Surface: TSuperficie; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    procedure DrawRotateAdd(Surface: TSuperficie; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    procedure DrawRotateSub(Surface: TSuperficie; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    property Surface: TSuperficie read FSurface;
    property PatternCount: Integer read GetPatternCount;
    property PatternRects[I: Integer]: TRect read GetPatternRect;
    property Width: Integer read GetWidth;     // largura de um padrao
    property Height: Integer read GetHeight;   // altura de um padrao
    property Transparent: Boolean read FTransparent write FTransparent;
    property TransparentColor: TColor read FTransparentColor write SetTransparentColor;
  end;

  { lista numerada de imagens: Img[i]; cada imagem pode ter um ou mais nomes }
  TListaImagens = class
  private
    FLista: TList;
    FNomes: TStringList;     // nome -> indice (em Objects), ordenada, sem diferenciar maiusculas
    FVazia: TImagem;         // devolvida por PorNome quando o nome nao existe (nao desenha nada)
    function GetItem(Indice: Integer): TImagem;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Adicionar(const Nome: string = ''): TImagem;
    { da mais um nome a imagem Indice }
    procedure Apelidar(const Nome: string; Indice: Integer);
    { indice da imagem com esse nome; -1 se nao existir }
    function IndiceDe(const Nome: string): Integer;
    { imagem com esse nome; se nao existir, uma imagem vazia (desenhar nao faz nada) }
    function PorNome(const Nome: string): TImagem;
    property Count: Integer read GetCount;
    property Items[Indice: Integer]: TImagem read GetItem; default;
  end;

{ Conversoes de cor }
function DXColorToPix(C: TColor): Cardinal;
function DXPixToColor(P: Cardinal): TColor;

implementation

{ ======================= utilitarios ======================= }

function DXColorToPix(C: TColor): Cardinal;
var
  RGB: Cardinal;
begin
  RGB := Cardinal(ColorToRGB(C));          // 0x00BBGGRR
  Result := $FF000000 or ((RGB and $FF) shl 16) or (RGB and $FF00) or ((RGB shr 16) and $FF);
end;

function DXPixToColor(P: Cardinal): TColor;
begin
  Result := TColor(((P shr 16) and $FF) or (P and $FF00) or ((P and $FF) shl 16));
end;

{ ---- cache de mascaras de texto ---- }

type
  TTextMask = class
  public
    W, H: Integer;
    Data: TDXMascara;
  end;

var
  GMaskCache: TStringList = nil;

function ChaveTexto(Tam: Integer; const S: string): string;
begin
  Result := IntToStr(Tam) + '|' + S;
end;

function GetTextMask(Tam: Integer; const S: string): TTextMask;
var
  Key: string;
  Idx: Integer;
  M: TTextMask;
begin
  if GMaskCache = nil then
  begin
    GMaskCache := TStringList.Create;
    GMaskCache.Sorted := True;
    GMaskCache.CaseSensitive := True;
    GMaskCache.OwnsObjects := True;
  end;
  Key := ChaveTexto(Tam, S);
  Idx := GMaskCache.IndexOf(Key);
  if Idx >= 0 then
  begin
    Result := TTextMask(GMaskCache.Objects[Idx]);
    Exit;
  end;
  if GMaskCache.Count > 600 then GMaskCache.Clear;

  M := TTextMask.Create;
  DXFonteMascara(Tam, S, M.W, M.H, M.Data);
  GMaskCache.AddObject(Key, M);
  Result := M;
end;

{ ======================= TSuperficie ======================= }

constructor TSuperficie.Create;
begin
  inherited Create;
  FTransparentColor := clBlack;
end;

procedure TSuperficie.SetSize(AWidth, AHeight: Integer);
begin
  if AWidth < 0 then AWidth := 0;
  if AHeight < 0 then AHeight := 0;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPix, FWidth * FHeight);
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), $FF000000);
end;

function TSuperficie.ScanLine(Y: Integer): PCardinal;
begin
  Result := @FPix[Y * FWidth];
end;

function TSuperficie.GetPixel(X, Y: Integer): TColor;
begin
  if (X < 0) or (Y < 0) or (X >= FWidth) or (Y >= FHeight) then
    Result := clBlack
  else
    Result := DXPixToColor(FPix[Y * FWidth + X]);
end;

procedure TSuperficie.SetPixel(X, Y: Integer; Value: TColor);
begin
  if (X < 0) or (Y < 0) or (X >= FWidth) or (Y >= FHeight) then Exit;
  FPix[Y * FWidth + X] := DXColorToPix(Value);
end;

procedure TSuperficie.Fill(Color: TColor);
begin
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), DXColorToPix(Color));
end;

function TSuperficie.CarregarBMP(const Arquivo: string): Boolean;
var
  Pic: TDXPicture;
  Nome: string;
  Y: Integer;
begin
  Result := False;
  SetSize(0, 0);
  Nome := DXResolvePath(Arquivo);
  if (Arquivo = '') or not FileExists(Nome) then Exit;
  Pic := TDXPicture.Create;
  try
    Pic.LoadFromFile(Nome);
    if Pic.Empty then Exit;
    SetSize(Pic.Width, Pic.Height);
    for Y := 0 to FHeight - 1 do
      Move(Pic.ScanLine(Y)^, FPix[Y * FWidth], FWidth * SizeOf(Cardinal));
    Result := True;
  finally
    Pic.Free;
  end;
end;

{ ---- copias ---- }

function TSuperficie.DoBlit(Mode: TBlendMode; const DestRect, SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
var
  SW, SH, DW, DH, ADW, ADH: Integer;
  L, T: Integer;
  FlipX, FlipY: Boolean;
  I, J, I0, I1, J0, J1: Integer;
  DX, DY, SX, SY: Integer;
  Key: Cardinal;
  SP, DP: Cardinal;
  SRow: PCardinal;
  DRow: PCardinal;
  Straight: Boolean;
  A, IA: Integer;
  SR, SG, SB, DR, DG, DB: Integer;
begin
  Result := False;
  if (Image = nil) or (Image.FWidth = 0) or (Image.FHeight = 0) or (FWidth = 0) then Exit;
  SW := SrcRect.Right - SrcRect.Left;
  SH := SrcRect.Bottom - SrcRect.Top;
  DW := DestRect.Right - DestRect.Left;
  DH := DestRect.Bottom - DestRect.Top;
  if (SW <= 0) or (SH <= 0) or (DW = 0) or (DH = 0) then Exit;
  FlipX := DW < 0;
  FlipY := DH < 0;
  ADW := Abs(DW);
  ADH := Abs(DH);
  L := Min(DestRect.Left, DestRect.Right);
  T := Min(DestRect.Top, DestRect.Bottom);
  I0 := Max(0, -L);
  I1 := Min(ADW - 1, FWidth - 1 - L);
  J0 := Max(0, -T);
  J1 := Min(ADH - 1, FHeight - 1 - T);
  if (I1 < I0) or (J1 < J0) then Exit;
  Key := DXColorToPix(Image.FTransparentColor) and $FFFFFF;
  if Alpha < 0 then Alpha := 0;
  if Alpha > 255 then Alpha := 255;
  A := Alpha;
  IA := 255 - A;
  Straight := (SW = ADW) and (not FlipX);

  // mapa de colunas (origem) para cada coluna de destino
  if Length(FMap) < ADW then SetLength(FMap, ADW);
  for I := I0 to I1 do
  begin
    if FlipX then SX := (ADW - 1 - I) * SW div ADW else SX := I * SW div ADW;
    SX := SrcRect.Left + SX;
    if SX < 0 then SX := 0;
    if SX >= Image.FWidth then SX := Image.FWidth - 1;
    FMap[I] := SX;
  end;

  for J := J0 to J1 do
  begin
    if FlipY then SY := (ADH - 1 - J) * SH div ADH else SY := J * SH div ADH;
    SY := SrcRect.Top + SY;
    if SY < 0 then SY := 0;
    if SY >= Image.FHeight then SY := Image.FHeight - 1;
    DY := T + J;
    SRow := @Image.FPix[SY * Image.FWidth];
    DRow := @FPix[DY * FWidth];
    for I := I0 to I1 do
    begin
      DX := L + I;
      SP := SRow[FMap[I]];
      if Transparent and ((SP and $FFFFFF) = Key) then Continue;
      case Mode of
        bmCopy:
          DRow[DX] := SP or $FF000000;
        bmAlpha:
          begin
            DP := DRow[DX];
            SR := (SP shr 16) and $FF; SG := (SP shr 8) and $FF; SB := SP and $FF;
            DR := (DP shr 16) and $FF; DG := (DP shr 8) and $FF; DB := DP and $FF;
            DR := (DR * IA + SR * A) div 255;
            DG := (DG * IA + SG * A) div 255;
            DB := (DB * IA + SB * A) div 255;
            DRow[DX] := $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
          end;
        bmAdd:
          begin
            DP := DRow[DX];
            SR := (SP shr 16) and $FF; SG := (SP shr 8) and $FF; SB := SP and $FF;
            DR := ((DP shr 16) and $FF) + SR * A div 255;
            DG := ((DP shr 8) and $FF) + SG * A div 255;
            DB := (DP and $FF) + SB * A div 255;
            if DR > 255 then DR := 255;
            if DG > 255 then DG := 255;
            if DB > 255 then DB := 255;
            DRow[DX] := $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
          end;
        bmSub:
          begin
            DP := DRow[DX];
            SR := (SP shr 16) and $FF; SG := (SP shr 8) and $FF; SB := SP and $FF;
            DR := ((DP shr 16) and $FF) - SR * A div 255;
            DG := ((DP shr 8) and $FF) - SG * A div 255;
            DB := (DP and $FF) - SB * A div 255;
            if DR < 0 then DR := 0;
            if DG < 0 then DG := 0;
            if DB < 0 then DB := 0;
            DRow[DX] := $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
          end;
      end;
    end;
  end;
  Result := True;
end;

function TSuperficie.Draw(X, Y: Integer; const SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean): Boolean;
begin
  Result := DoBlit(bmCopy, Rect(X, Y, X + (SrcRect.Right - SrcRect.Left),
    Y + (SrcRect.Bottom - SrcRect.Top)), SrcRect, Image, Transparent, 255);
end;

function TSuperficie.Draw(X, Y: Integer; Image: TSuperficie;
  Transparent: Boolean): Boolean;
begin
  if Image = nil then begin Result := False; Exit; end;
  Result := Draw(X, Y, Rect(0, 0, Image.FWidth, Image.FHeight), Image, Transparent);
end;

function TSuperficie.StretchDraw(const DestRect, SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean): Boolean;
begin
  Result := DoBlit(bmCopy, DestRect, SrcRect, Image, Transparent, 255);
end;

function TSuperficie.DrawAlpha(const DestRect, SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmAlpha, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TSuperficie.DrawAdd(const DestRect, SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmAdd, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TSuperficie.DrawSub(const DestRect, SrcRect: TRect;
  Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmSub, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TSuperficie.DoRotate(Mode: TBlendMode; X, Y, W, H: Integer;
  const SrcRect: TRect; Image: TSuperficie; CenterX, CenterY: Double;
  Transparent: Boolean; Angle, Alpha: Integer): Boolean;
var
  Rad, CosA, SinA: Double;
  PX, PY: Double;           // pivo em coordenadas de destino
  Corners: array[0..3] of TPoint;
  K: Integer;
  MinX, MaxX, MinY, MaxY: Integer;
  PXi, PYi: Integer;
  DXp, DYp: Double;
  U, V: Double;
  SX, SY: Integer;
  SW, SH: Integer;
  Key: Cardinal;
  SP, DP: Cardinal;
  A, IA: Integer;
  SR, SG, SB, DR, DG, DB: Integer;
  CX, CY: Double;
begin
  Result := False;
  if (Image = nil) or (Image.FWidth = 0) or (FWidth = 0) or (W = 0) or (H = 0) then Exit;
  SW := SrcRect.Right - SrcRect.Left;
  SH := SrcRect.Bottom - SrcRect.Top;
  if (SW <= 0) or (SH <= 0) then Exit;
  Key := DXColorToPix(Image.FTransparentColor) and $FFFFFF;
  if Alpha < 0 then Alpha := 0;
  if Alpha > 255 then Alpha := 255;
  A := Alpha; IA := 255 - A;
  Rad := (Angle mod 256) * 2 * Pi / 256;
  CosA := Cos(Rad);
  SinA := Sin(Rad);
  PX := X + W * CenterX;
  PY := Y + H * CenterY;
  // bounding box do retangulo rotacionado
  CX := X; CY := Y;
  for K := 0 to 3 do
  begin
    case K of
      0: begin DXp := X - PX;     DYp := Y - PY; end;
      1: begin DXp := X + W - PX; DYp := Y - PY; end;
      2: begin DXp := X + W - PX; DYp := Y + H - PY; end;
    else begin DXp := X - PX;     DYp := Y + H - PY; end;
    end;
    Corners[K].X := Round(PX + DXp * CosA - DYp * SinA);
    Corners[K].Y := Round(PY + DXp * SinA + DYp * CosA);
  end;
  MinX := Corners[0].X; MaxX := MinX; MinY := Corners[0].Y; MaxY := MinY;
  for K := 1 to 3 do
  begin
    MinX := Min(MinX, Corners[K].X); MaxX := Max(MaxX, Corners[K].X);
    MinY := Min(MinY, Corners[K].Y); MaxY := Max(MaxY, Corners[K].Y);
  end;
  MinX := Max(MinX, 0); MinY := Max(MinY, 0);
  MaxX := Min(MaxX, FWidth - 1); MaxY := Min(MaxY, FHeight - 1);
  for PYi := MinY to MaxY do
    for PXi := MinX to MaxX do
    begin
      // mapeamento inverso: destino -> retangulo original (nao rotacionado)
      DXp := (PXi + 0.5) - PX;
      DYp := (PYi + 0.5) - PY;
      U := PX + DXp * CosA + DYp * SinA;     // rotacao inversa
      V := PY - DXp * SinA + DYp * CosA;
      U := (U - X) / W;
      V := (V - Y) / H;
      if (U < 0) or (U >= 1) or (V < 0) or (V >= 1) then Continue;
      SX := SrcRect.Left + Trunc(U * SW);
      SY := SrcRect.Top + Trunc(V * SH);
      if (SX < 0) or (SY < 0) or (SX >= Image.FWidth) or (SY >= Image.FHeight) then Continue;
      SP := Image.FPix[SY * Image.FWidth + SX];
      if Transparent and ((SP and $FFFFFF) = Key) then Continue;
      DP := FPix[PYi * FWidth + PXi];
      SR := (SP shr 16) and $FF; SG := (SP shr 8) and $FF; SB := SP and $FF;
      DR := (DP shr 16) and $FF; DG := (DP shr 8) and $FF; DB := DP and $FF;
      case Mode of
        bmCopy:  begin DR := SR; DG := SG; DB := SB; end;
        bmAlpha: begin DR := (DR * IA + SR * A) div 255; DG := (DG * IA + SG * A) div 255; DB := (DB * IA + SB * A) div 255; end;
        bmAdd:   begin DR := Min(255, DR + SR * A div 255); DG := Min(255, DG + SG * A div 255); DB := Min(255, DB + SB * A div 255); end;
        bmSub:   begin DR := Max(0, DR - SR * A div 255); DG := Max(0, DG - SG * A div 255); DB := Max(0, DB - SB * A div 255); end;
      end;
      FPix[PYi * FWidth + PXi] := $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
    end;
  Result := True;
end;

function TSuperficie.DrawRotate(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean; Angle: Integer): Boolean;
begin
  Result := DoRotate(bmCopy, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, 255);
end;

function TSuperficie.DrawRotateAlpha(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmAlpha, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

function TSuperficie.DrawRotateAdd(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmAdd, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

function TSuperficie.DrawRotateSub(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmSub, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

procedure TSuperficie.PreencherRect(const R: TRect; Cor: TColor);
var
  X1, Y1, X2, Y2, Y: Integer;
  C: Cardinal;
begin
  X1 := Max(0, Min(R.Left, R.Right));
  X2 := Min(FWidth, Max(R.Left, R.Right));
  Y1 := Max(0, Min(R.Top, R.Bottom));
  Y2 := Min(FHeight, Max(R.Top, R.Bottom));
  if (X2 <= X1) or (Y2 <= Y1) then Exit;
  C := DXColorToPix(Cor);
  for Y := Y1 to Y2 - 1 do
    FillDWord(FPix[Y * FWidth + X1], X2 - X1, C);
end;

procedure TSuperficie.Moldura(const R: TRect; Cor: TColor);
var
  C: Cardinal;
  X, Y, L, T, RR, B: Integer;
begin
  L := Min(R.Left, R.Right); RR := Max(R.Left, R.Right) - 1;
  T := Min(R.Top, R.Bottom); B := Max(R.Top, R.Bottom) - 1;
  C := DXColorToPix(Cor);
  for X := L to RR do
  begin
    if (X >= 0) and (X < FWidth) then
    begin
      if (T >= 0) and (T < FHeight) then FPix[T * FWidth + X] := C;
      if (B >= 0) and (B < FHeight) then FPix[B * FWidth + X] := C;
    end;
  end;
  for Y := T to B do
  begin
    if (Y >= 0) and (Y < FHeight) then
    begin
      if (L >= 0) and (L < FWidth) then FPix[Y * FWidth + L] := C;
      if (RR >= 0) and (RR < FWidth) then FPix[Y * FWidth + RR] := C;
    end;
  end;
end;

procedure TSuperficie.Forma(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor;
  Preencher: Boolean);
var
  L, T, R, B, W, H, Y, XL, XR, PrevXL, PrevXR, X: Integer;
  HX, HY: Double;
  CY, DYf, Ins: Double;
  FC, PC: Cardinal;

  procedure Put(PX, PY: Integer; C: Cardinal);
  begin
    if (PX >= 0) and (PY >= 0) and (PX < FWidth) and (PY < FHeight) then
      FPix[PY * FWidth + PX] := C;
  end;

begin
  L := Min(X1, X2); R := Max(X1, X2);
  T := Min(Y1, Y2); B := Max(Y1, Y2);
  W := R - L; H := B - T;
  if (W <= 0) or (H <= 0) then Exit;
  RX := Min(Abs(RX), W); RY := Min(Abs(RY), H);
  HX := RX / 2.0; HY := RY / 2.0;
  FC := DXColorToPix(CorFundo);
  PC := DXColorToPix(CorBorda);
  PrevXL := -1; PrevXR := -1;
  for Y := T to B - 1 do
  begin
    // distancia vertical ate o centro do canto (se estiver na zona do canto)
    Ins := 0;
    if HY > 0 then
    begin
      if (Y + 0.5) < T + HY then
        CY := T + HY
      else if (Y + 0.5) > B - HY then
        CY := B - HY
      else
        CY := -1;
      if CY >= 0 then
      begin
        DYf := Abs((Y + 0.5) - CY) / HY;
        if DYf > 1 then DYf := 1;
        Ins := HX - HX * Sqrt(1 - DYf * DYf);
      end;
    end;
    XL := L + Round(Ins);
    XR := R - Round(Ins);       // exclusivo
    if XR <= XL then XR := XL + 1;
    if Preencher then
      for X := XL to XR - 1 do Put(X, Y, FC);
    begin
      if (Y = T) or (Y = B - 1) then
        for X := XL to XR - 1 do Put(X, Y, PC)
      else
      begin
        // liga os extremos desta linha aos da anterior (evita buracos nos cantos)
        if PrevXL < 0 then begin PrevXL := XL; PrevXR := XR; end;
        for X := Min(XL, PrevXL) to Max(XL, PrevXL) do Put(X, Y, PC);
        for X := Min(XR, PrevXR) - 1 to Max(XR, PrevXR) - 1 do Put(X, Y, PC);
      end;
    end;
    PrevXL := XL; PrevXR := XR;
  end;
end;

procedure TSuperficie.RoundRect(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor);
begin
  Forma(X1, Y1, X2, Y2, RX, RY, CorBorda, CorFundo, True);
end;

procedure TSuperficie.Elipse(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor; Preencher: Boolean);
begin
  Forma(X1, Y1, X2, Y2, Abs(X2 - X1), Abs(Y2 - Y1), CorBorda, CorFundo, Preencher);
end;

function TSuperficie.LarguraTexto(const S: string; Tam: Integer): Integer;
begin
  Result := DXFonteLargura(Tam, S);
end;

procedure TSuperficie.Texto(X, Y: Integer; const S: string; Tam: Integer; Cor: TColor);
var
  M: TTextMask;
  I, J, DX, DY, Cov, IC: Integer;
  FCol, DP: Cardinal;
  FR, FG, FB, DR, DG, DB: Integer;
begin
  if S = '' then Exit;
  M := GetTextMask(Tam, S);
  FCol := DXColorToPix(Cor);
  FR := (FCol shr 16) and $FF; FG := (FCol shr 8) and $FF; FB := FCol and $FF;
  for J := 0 to M.H - 1 do
  begin
    DY := Y + J;
    if (DY < 0) or (DY >= FHeight) then Continue;
    for I := 0 to M.W - 1 do
    begin
      Cov := M.Data[J * M.W + I];
      if Cov = 0 then Continue;
      DX := X + I;
      if (DX < 0) or (DX >= FWidth) then Continue;
      DP := FPix[DY * FWidth + DX];
      IC := 255 - Cov;
      DR := (((DP shr 16) and $FF) * IC + FR * Cov) div 255;
      DG := (((DP shr 8) and $FF) * IC + FG * Cov) div 255;
      DB := ((DP and $FF) * IC + FB * Cov) div 255;
      FPix[DY * FWidth + DX] :=
        $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
    end;
  end;
end;

{ ======================= TImagem ======================= }

constructor TImagem.Create;
begin
  inherited Create;
  FSurface := TSuperficie.Create;
  FTransparent := True;
  FTransparentColor := clWhite;
end;

destructor TImagem.Destroy;
begin
  FSurface.Free;
  inherited Destroy;
end;

procedure TImagem.SetTransparentColor(Value: TColor);
begin
  FTransparentColor := Value;
  FSurface.TransparentColor := Value;
end;

{ padroes (folha de sprites): grade PatternWidth x PatternHeight }
procedure TImagem.MontarPadroes;
var
  PW, PH, X, Y, N: Integer;
begin
  PW := FPatternWidth; PH := FPatternHeight;
  if PW <= 0 then PW := FSurface.Width;
  if PH <= 0 then PH := FSurface.Height;
  SetLength(FPatterns, 0);
  if (PW > 0) and (PH > 0) then
  begin
    N := 0;
    SetLength(FPatterns, (FSurface.Width div PW) * (FSurface.Height div PH));
    for Y := 0 to (FSurface.Height div PH) - 1 do
      for X := 0 to (FSurface.Width div PW) - 1 do
      begin
        FPatterns[N] := Rect(X * PW, Y * PH, X * PW + PW, Y * PH + PH);
        Inc(N);
      end;
  end;
end;

procedure TImagem.CarregarArquivo(const Arquivo: string; Transparente: Boolean; CorTransp: TColor;
  PW: Integer; PH: Integer);
begin
  FTransparent := Transparente;
  TransparentColor := CorTransp;
  FPatternWidth := Max(0, PW);
  FPatternHeight := Max(0, PH);
  FSurface.CarregarBMP(Arquivo);
  FSurface.TransparentColor := FTransparentColor;
  MontarPadroes;
end;

procedure TImagem.AtribuirRegiao(Src: TSuperficie; X1, Y1, X2, Y2: Integer; Mirror: Boolean;
  Transparente: Boolean; CorTransp: TColor);
var
  W, H, X, Y, SX: Integer;
begin
  FTransparent := Transparente;
  TransparentColor := CorTransp;
  W := X2 - X1;
  H := Y2 - Y1;
  if W < 0 then W := 0;
  if H < 0 then H := 0;
  FSurface.SetSize(W, H);
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      if Mirror then SX := X2 - 1 - X else SX := X1 + X;
      if (SX >= 0) and (SX < Src.FWidth) and (Y1 + Y >= 0) and (Y1 + Y < Src.FHeight) then
        FSurface.FPix[Y * W + X] := Src.FPix[(Y1 + Y) * Src.FWidth + SX]
      else
        FSurface.FPix[Y * W + X] := $FF000000;
    end;
  FSurface.TransparentColor := FTransparentColor;
  FPatternWidth := 0;
  FPatternHeight := 0;
  SetLength(FPatterns, 1);
  FPatterns[0] := Rect(0, 0, W, H);
end;

function TImagem.GetPatternCount: Integer;
begin
  Result := Length(FPatterns);
end;

function TImagem.GetPatternRect(I: Integer): TRect;
begin
  if (I >= 0) and (I < Length(FPatterns)) then
    Result := FPatterns[I]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TImagem.GetWidth: Integer;
begin
  if FPatternWidth > 0 then Result := FPatternWidth else Result := FSurface.Width;
end;

function TImagem.GetHeight: Integer;
begin
  if FPatternHeight > 0 then Result := FPatternHeight else Result := FSurface.Height;
end;

procedure TImagem.Draw(Surface: TSuperficie; X, Y, PatternIndex: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.Draw(X, Y, FPatterns[PatternIndex], FSurface, FTransparent);
end;

procedure TImagem.StretchDraw(Surface: TSuperficie;
  const DestRect: TRect; PatternIndex: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.StretchDraw(DestRect, FPatterns[PatternIndex], FSurface, FTransparent);
end;

procedure TImagem.DrawAlpha(Surface: TSuperficie;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawAlpha(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TImagem.DrawAdd(Surface: TSuperficie;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawAdd(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TImagem.DrawSub(Surface: TSuperficie;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawSub(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TImagem.DrawRotate(Surface: TSuperficie; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotate(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle);
end;

procedure TImagem.DrawRotateAlpha(Surface: TSuperficie; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateAlpha(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

procedure TImagem.DrawRotateAdd(Surface: TSuperficie; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateAdd(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

procedure TImagem.DrawRotateSub(Surface: TSuperficie; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateSub(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

{ ======================= TListaImagens ======================= }

constructor TListaImagens.Create;
begin
  inherited Create;
  FLista := TList.Create;
  FNomes := TStringList.Create;
  FNomes.CaseSensitive := False;
  FNomes.Sorted := True;
  FNomes.Duplicates := dupIgnore;
  FVazia := TImagem.Create;
end;

destructor TListaImagens.Destroy;
var
  I: Integer;
begin
  for I := 0 to FLista.Count - 1 do TImagem(FLista[I]).Free;
  FLista.Free;
  FNomes.Free;
  FVazia.Free;
  inherited Destroy;
end;

procedure TListaImagens.Apelidar(const Nome: string; Indice: Integer);
begin
  if (Nome <> '') and (Indice >= 0) and (Indice < FLista.Count) then
    FNomes.AddObject(Nome, TObject(PtrInt(Indice)));
end;

function TListaImagens.IndiceDe(const Nome: string): Integer;
var
  I: Integer;
begin
  if FNomes.Find(Nome, I) then
    Result := Integer(PtrInt(FNomes.Objects[I]))
  else
    Result := -1;
end;

function TListaImagens.PorNome(const Nome: string): TImagem;
var
  I: Integer;
begin
  I := IndiceDe(Nome);
  if I >= 0 then Result := TImagem(FLista[I]) else Result := FVazia;
end;

function TListaImagens.GetCount: Integer;
begin
  Result := FLista.Count;
end;

function TListaImagens.GetItem(Indice: Integer): TImagem;
begin
  Result := TImagem(FLista[Indice]);
end;

function TListaImagens.Adicionar(const Nome: string): TImagem;
begin
  Result := TImagem.Create;
  FLista.Add(Result);
  Apelidar(Nome, FLista.Count - 1);
end;

initialization
  DXFonteCarregar(DXResolvePath('Fontes/ComicSansMS.atlas'));   // gerado por tools/GeraFonte

finalization
  GMaskCache.Free;

end.
