unit DXDraws;

{ Camada de compatibilidade DelphiX -> Lazarus (LCL), sem componentes de terceiros.

  Ideia: TDirectDrawSurface e um buffer de pixels em MEMORIA (32 bits, 0xAARRGGBB).
  Todos os "blits" (Draw, StretchDraw, DrawAlpha, DrawAdd, DrawSub, DrawRotate...) sao
  feitos por software, entao o resultado e igual em qualquer plataforma.
  Surface.Canvas devolve um TDirectDrawSurfaceCanvas com a MESMA sintaxe do codigo
  original (Brush, Pen, Font, FillRect, FrameRect, RoundRect, Ellipse, TextOut,
  TextWidth, Pixels, Release) e tambem desenha no buffer em memoria.
  TDXDraw e um controle que apresenta (Flip) o buffer na tela.

  Nomes mantidos do DelphiX: TDXDraw, TDirectDrawSurface, TDirectDrawSurfaceCanvas,
  TDXImageList, TPictureCollection, TPictureCollectionItem, TDXDrawOption(s),
  TDXDrawDisplay.

  Diferencas conhecidas (ver LEIAME):
   - Display.* e doFullScreen sao aceitos e ignorados (janela/escala sao do Lazarus).
   - TPictureCollectionItem tem a propriedade extra FileName (carrega o bitmap de um arquivo).
   - O color key compara RGB de 24 bits (o original comparava em 16 bits). }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Graphics, Controls, GraphType, IntfGraphics,
  LCLType, FPImage, DXClass;

type
  TDXDrawOption = (doFullScreen, doNoWindowChange, doAllowReboot, doWaitVBlank,
    doAllowModeX, doSystemMemory, doHardware, doSelectDriver, doCenter, do3D,
    doDirectX7Mode, doStencil, doRetainedMode, doZBuffer, doFlip);
  TDXDrawOptions = set of TDXDrawOption;

  TDirectDrawSurface = class;
  TCustomDXDraw = class;

  { Pixel: 0xAARRGGBB. Cor "RGB" de 24 bits = 0x00RRGGBB. }

  { TDXDrawDisplay: aceita e ignora (modo de video e responsabilidade do Lazarus) }
  TDXDrawDisplay = class(TPersistent)
  private
    FBitCount, FWidth, FHeight: Integer;
    FFixedBitCount, FFixedRatio, FFixedSize: Boolean;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property BitCount: Integer read FBitCount write FBitCount default 8;
    property FixedBitCount: Boolean read FFixedBitCount write FFixedBitCount default False;
    property FixedRatio: Boolean read FFixedRatio write FFixedRatio default True;
    property FixedSize: Boolean read FFixedSize write FFixedSize default False;
    property Height: Integer read FHeight write FHeight default 480;
    property Width: Integer read FWidth write FWidth default 640;
  end;

  { TDirectDrawSurfaceCanvas: mesma sintaxe de TCanvas para o que o jogo usa }
  TDirectDrawSurfaceCanvas = class
  private
    FSurface: TDirectDrawSurface;
    FBrush: TBrush;
    FPen: TPen;
    FFont: TFont;
    function GetPixel(X, Y: Integer): TColor;
    procedure SetPixel(X, Y: Integer; Value: TColor);
    procedure FillRound(X1, Y1, X2, Y2, RX, RY: Integer; DoFill, DoOutline: Boolean);
  public
    constructor Create(ASurface: TDirectDrawSurface);
    destructor Destroy; override;
    procedure Release;
    procedure FillRect(const R: TRect);
    procedure FrameRect(const R: TRect);
    procedure Rectangle(X1, Y1, X2, Y2: Integer);
    procedure RoundRect(X1, Y1, X2, Y2, RX, RY: Integer);
    procedure Ellipse(X1, Y1, X2, Y2: Integer);
    procedure TextOut(X, Y: Integer; const S: string);
    function TextWidth(const S: string): Integer;
    function TextHeight(const S: string): Integer;
    property Brush: TBrush read FBrush;
    property Pen: TPen read FPen;
    property Font: TFont read FFont;
    property Pixels[X, Y: Integer]: TColor read GetPixel write SetPixel;
    property Surface: TDirectDrawSurface read FSurface;
  end;

  TBlendMode = (bmCopy, bmAlpha, bmAdd, bmSub);

  { TDirectDrawSurface }
  TDirectDrawSurface = class(TPersistent)
  private
    FWidth, FHeight: Integer;
    FPix: array of Cardinal;
    FTransparentColor: TColor;
    FCanvas: TDirectDrawSurfaceCanvas;
    FMap: array of Integer;           // buffer reutilizavel p/ mapeamento de colunas
    function GetCanvas: TDirectDrawSurfaceCanvas;
    function GetPixel(X, Y: Integer): TColor;
    procedure SetPixel(X, Y: Integer; Value: TColor);
    function DoBlit(Mode: TBlendMode; const DestRect, SrcRect: TRect;
      Image: TDirectDrawSurface; Transparent: Boolean; Alpha: Integer): Boolean;
    function DoRotate(Mode: TBlendMode; X, Y, W, H: Integer; const SrcRect: TRect;
      Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetSize(AWidth, AHeight: Integer);
    procedure Fill(Color: TColor);
    procedure LoadFromGraphic(Graphic: TGraphic);
    function ScanLine(Y: Integer): PCardinal;
    { Draw: copia SrcRect de Image para (X,Y) }
    function Draw(X, Y: Integer; const SrcRect: TRect; Image: TDirectDrawSurface;
      Transparent: Boolean): Boolean; overload;
    function Draw(X, Y: Integer; Image: TDirectDrawSurface; Transparent: Boolean): Boolean; overload;
    function StretchDraw(const DestRect, SrcRect: TRect; Image: TDirectDrawSurface;
      Transparent: Boolean): Boolean;
    { Alpha: 0..255 }
    function DrawAlpha(const DestRect, SrcRect: TRect; Image: TDirectDrawSurface;
      Transparent: Boolean; Alpha: Integer): Boolean;
    function DrawAdd(const DestRect, SrcRect: TRect; Image: TDirectDrawSurface;
      Transparent: Boolean; Alpha: Integer): Boolean;
    function DrawSub(const DestRect, SrcRect: TRect; Image: TDirectDrawSurface;
      Transparent: Boolean; Alpha: Integer): Boolean;
    { Angle: 0..255 = 0..360 graus. CenterX/CenterY: pivo como fracao do retangulo (0.5 = centro). }
    function DrawRotate(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean;
      Angle: Integer): Boolean;
    function DrawRotateAlpha(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    function DrawRotateAdd(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    function DrawRotateSub(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Canvas: TDirectDrawSurfaceCanvas read GetCanvas;
    property Pixels[X, Y: Integer]: TColor read GetPixel write SetPixel;
    property TransparentColor: TColor read FTransparentColor write FTransparentColor;
  end;

  { ---- Colecao de imagens ---- }

  TPictureCollection = class;

  TPictureCollectionItem = class(THashCollectionItem)
  private
    FPicture: TPicture;
    FFileName: string;
    FPatternWidth, FPatternHeight: Integer;
    FTransparent, FSystemMemory: Boolean;
    FTransparentColor: TColor;
    FSurface: TDirectDrawSurface;
    FPatterns: array of TRect;
    FDirty: Boolean;
    FLoading: Boolean;
    FFromSurface: Boolean;            // conteudo veio de AssignRegion (nao de FPicture)
    procedure SetPicture(Value: TPicture);
    procedure SetFileName(const Value: string);
    procedure SetPatternWidth(Value: Integer);
    procedure SetPatternHeight(Value: Integer);
    procedure SetTransparent(Value: Boolean);
    procedure SetTransparentColor(Value: TColor);
    procedure PictureChanged(Sender: TObject);
    procedure Ensure;
    function GetSurface: TDirectDrawSurface;
    function GetPatternCount: Integer;
    function GetPatternRect(I: Integer): TRect;
    function GetWidth: Integer;
    function GetHeight: Integer;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Restore;
    { Extra (nao existe no DelphiX): preenche o item com a regiao [X1,X2) x [Y1,Y2) de Src,
      opcionalmente espelhada na horizontal. Substitui o par CopyRect+SetPicture do original. }
    procedure AssignRegion(Src: TDirectDrawSurface; X1, Y1, X2, Y2: Integer; Mirror: Boolean);
    procedure Draw(Surface: TDirectDrawSurface; X, Y, PatternIndex: Integer);
    procedure StretchDraw(Surface: TDirectDrawSurface; const DestRect: TRect; PatternIndex: Integer);
    procedure DrawAlpha(Surface: TDirectDrawSurface; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawAdd(Surface: TDirectDrawSurface; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawSub(Surface: TDirectDrawSurface; const DestRect: TRect; PatternIndex, Alpha: Integer);
    procedure DrawRotate(Surface: TDirectDrawSurface; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle: Integer);
    procedure DrawRotateAlpha(Surface: TDirectDrawSurface; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    procedure DrawRotateAdd(Surface: TDirectDrawSurface; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    procedure DrawRotateSub(Surface: TDirectDrawSurface; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle, Alpha: Integer);
    property Surface: TDirectDrawSurface read GetSurface;
    property PatternCount: Integer read GetPatternCount;
    property PatternRects[I: Integer]: TRect read GetPatternRect;
    property Width: Integer read GetWidth;     // largura de um padrao
    property Height: Integer read GetHeight;   // altura de um padrao
  published
    property FileName: string read FFileName write SetFileName;   // extra (nao existe no DelphiX)
    property PatternHeight: Integer read FPatternHeight write SetPatternHeight default 0;
    property PatternWidth: Integer read FPatternWidth write SetPatternWidth default 0;
    property Picture: TPicture read FPicture write SetPicture;
    property SystemMemory: Boolean read FSystemMemory write FSystemMemory default False;
    property Transparent: Boolean read FTransparent write SetTransparent default True;
    property TransparentColor: TColor read FTransparentColor write SetTransparentColor default clWhite;
  end;

  TPictureCollection = class(THashCollection)
  private
    function GetItem(Index: Integer): TPictureCollectionItem;
  public
    constructor Create;
    function Add: TPictureCollectionItem;
    function Find(const Name: string): TPictureCollectionItem;
    procedure Restore;
    property Items[Index: Integer]: TPictureCollectionItem read GetItem; default;
  end;

  TCustomDXImageList = class(TComponent)
  private
    FDXDraw: TCustomDXDraw;
    FItems: TPictureCollection;
    procedure SetDXDraw(Value: TCustomDXDraw);
    procedure SetItems(Value: TPictureCollection);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Restore;
    property DXDraw: TCustomDXDraw read FDXDraw write SetDXDraw;
    property Items: TPictureCollection read FItems write SetItems;
  end;

  TDXImageList = class(TCustomDXImageList)
  published
    property DXDraw;
    property Items;
  end;

  { ---- Controle de video ---- }

  TCustomDXDraw = class(TCustomControl)
  private
    FSurface: TDirectDrawSurface;
    FDisplay: TDXDrawDisplay;
    FOptions: TDXDrawOptions;
    FAutoInitialize: Boolean;
    FInitialized: Boolean;
    FSurfaceWidth, FSurfaceHeight: Integer;
    FPresent: TBitmap;
    FLastPaintMs: Double;
    FOnInitialize: TNotifyEvent;
    FOnFinalize: TNotifyEvent;
    procedure SetSurfaceWidth(Value: Integer);
    procedure SetSurfaceHeight(Value: Integer);
    procedure SetDisplay(Value: TDXDrawDisplay);
    procedure UpdatePresent;
  protected
    procedure Paint; override;
    procedure EraseBackground(DC: HDC); override;
    procedure Loaded; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
      WithThemeSpace: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize;
    procedure Finalize;
    { Flip: apresenta o buffer na tela }
    procedure Flip;
    property LastPaintMs: Double read FLastPaintMs;
    property Surface: TDirectDrawSurface read FSurface;
    property Initialized: Boolean read FInitialized;
    property AutoInitialize: Boolean read FAutoInitialize write FAutoInitialize default True;
    property Display: TDXDrawDisplay read FDisplay write SetDisplay;
    property Options: TDXDrawOptions read FOptions write FOptions;
    property SurfaceWidth: Integer read FSurfaceWidth write SetSurfaceWidth default 640;
    property SurfaceHeight: Integer read FSurfaceHeight write SetSurfaceHeight default 480;
    property OnInitialize: TNotifyEvent read FOnInitialize write FOnInitialize;
    property OnFinalize: TNotifyEvent read FOnFinalize write FOnFinalize;
  end;

  TDXDraw = class(TCustomDXDraw)
  published
    property AutoInitialize;
    property AutoSize;
    property Color;
    property Display;
    property Height;
    property Left;
    property Options;
    property SurfaceHeight;
    property SurfaceWidth;
    property TabOrder;
    property TabStop;
    property Top;
    property Visible;
    property Width;
    property OnInitialize;
    property OnFinalize;
    property OnClick;
    property OnDblClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
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
    Data: array of Byte;
  end;

var
  GScratch: TBitmap = nil;
  GMaskCache: TStringList = nil;

function ScratchBitmap: TBitmap;
begin
  if GScratch = nil then
  begin
    GScratch := TBitmap.Create;
    GScratch.PixelFormat := pf32bit;
    GScratch.SetSize(8, 8);
  end;
  Result := GScratch;
end;

function FontKey(F: TFont; const S: string): string;
begin
  Result := F.Name + '|' + IntToStr(F.Size) + '|' + IntToStr(Integer(F.Style)) + '|' + S;
end;

function GetTextMask(F: TFont; const S: string): TTextMask;
var
  Key: string;
  Idx, X, Y, W, H: Integer;
  B: TBitmap;
  Intf: TLazIntfImage;
  M: TTextMask;
begin
  if GMaskCache = nil then
  begin
    GMaskCache := TStringList.Create;
    GMaskCache.Sorted := True;
    GMaskCache.CaseSensitive := True;
    GMaskCache.OwnsObjects := True;
  end;
  Key := FontKey(F, S);
  Idx := GMaskCache.IndexOf(Key);
  if Idx >= 0 then
  begin
    Result := TTextMask(GMaskCache.Objects[Idx]);
    Exit;
  end;
  if GMaskCache.Count > 600 then GMaskCache.Clear;

  B := ScratchBitmap;
  B.Canvas.Font.Assign(F);
  B.Canvas.Font.Color := clWhite;
  B.Canvas.Font.Quality := fqAntialiased;
  W := Max(1, B.Canvas.TextWidth(S));
  H := Max(1, B.Canvas.TextHeight(S));
  B.SetSize(W, H);
  B.Canvas.Brush.Style := bsSolid;
  B.Canvas.Brush.Color := clBlack;
  B.Canvas.FillRect(0, 0, W, H);
  B.Canvas.Brush.Style := bsClear;
  B.Canvas.Font.Assign(F);
  B.Canvas.Font.Color := clWhite;
  B.Canvas.Font.Quality := fqAntialiased;
  B.Canvas.TextOut(0, 0, S);

  M := TTextMask.Create;
  M.W := W;
  M.H := H;
  SetLength(M.Data, W * H);
  Intf := TLazIntfImage.Create(0, 0);
  try
    Intf.LoadFromBitmap(B.Handle, B.MaskHandle);
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
        M.Data[Y * W + X] := Intf.Colors[X, Y].Green shr 8;
  finally
    Intf.Free;
  end;
  GMaskCache.AddObject(Key, M);
  Result := M;
end;

{ ======================= TDXDrawDisplay ======================= }

constructor TDXDrawDisplay.Create;
begin
  inherited Create;
  FBitCount := 8;
  FWidth := 640;
  FHeight := 480;
  FFixedRatio := True;
end;

procedure TDXDrawDisplay.Assign(Source: TPersistent);
begin
  if Source is TDXDrawDisplay then
  begin
    FBitCount := TDXDrawDisplay(Source).FBitCount;
    FWidth := TDXDrawDisplay(Source).FWidth;
    FHeight := TDXDrawDisplay(Source).FHeight;
    FFixedBitCount := TDXDrawDisplay(Source).FFixedBitCount;
    FFixedRatio := TDXDrawDisplay(Source).FFixedRatio;
    FFixedSize := TDXDrawDisplay(Source).FFixedSize;
  end
  else
    inherited Assign(Source);
end;

{ ======================= TDirectDrawSurface ======================= }

constructor TDirectDrawSurface.Create;
begin
  inherited Create;
  FTransparentColor := clBlack;
end;

destructor TDirectDrawSurface.Destroy;
begin
  FCanvas.Free;
  inherited Destroy;
end;

procedure TDirectDrawSurface.SetSize(AWidth, AHeight: Integer);
begin
  if AWidth < 0 then AWidth := 0;
  if AHeight < 0 then AHeight := 0;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPix, FWidth * FHeight);
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), $FF000000);
end;

function TDirectDrawSurface.GetCanvas: TDirectDrawSurfaceCanvas;
begin
  if FCanvas = nil then FCanvas := TDirectDrawSurfaceCanvas.Create(Self);
  Result := FCanvas;
end;

function TDirectDrawSurface.ScanLine(Y: Integer): PCardinal;
begin
  Result := @FPix[Y * FWidth];
end;

function TDirectDrawSurface.GetPixel(X, Y: Integer): TColor;
begin
  if (X < 0) or (Y < 0) or (X >= FWidth) or (Y >= FHeight) then
    Result := clBlack
  else
    Result := DXPixToColor(FPix[Y * FWidth + X]);
end;

procedure TDirectDrawSurface.SetPixel(X, Y: Integer; Value: TColor);
begin
  if (X < 0) or (Y < 0) or (X >= FWidth) or (Y >= FHeight) then Exit;
  FPix[Y * FWidth + X] := DXColorToPix(Value);
end;

procedure TDirectDrawSurface.Fill(Color: TColor);
begin
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), DXColorToPix(Color));
end;

procedure TDirectDrawSurface.LoadFromGraphic(Graphic: TGraphic);
var
  Bmp: TBitmap;
  Tmp: TBitmap;
  Intf: TLazIntfImage;
  Desc: TRawImageDescription;
  X, Y: Integer;
  P: PByte;
  V: Cardinal;
  C: TFPColor;
  RS, GS, BS: Integer;
begin
  Tmp := nil;
  if Graphic is TBitmap then
    Bmp := TBitmap(Graphic)
  else
  begin
    Tmp := TBitmap.Create;
    Tmp.Assign(Graphic);
    Bmp := Tmp;
  end;
  Intf := TLazIntfImage.Create(0, 0);
  try
    Intf.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);
    SetSize(Intf.Width, Intf.Height);
    Desc := Intf.DataDescription;
    if (Desc.BitsPerPixel = 32) and (Desc.ByteOrder = riboLSBFirst) then
    begin
      RS := Desc.RedShift; GS := Desc.GreenShift; BS := Desc.BlueShift;
      for Y := 0 to FHeight - 1 do
      begin
        P := PByte(Intf.GetDataLineStart(Y));
        for X := 0 to FWidth - 1 do
        begin
          V := PCardinal(P)^;
          FPix[Y * FWidth + X] := $FF000000 or (((V shr RS) and $FF) shl 16) or
            (((V shr GS) and $FF) shl 8) or ((V shr BS) and $FF);
          Inc(P, 4);
        end;
      end;
    end
    else
      for Y := 0 to FHeight - 1 do
        for X := 0 to FWidth - 1 do
        begin
          C := Intf.Colors[X, Y];
          FPix[Y * FWidth + X] := $FF000000 or (Cardinal(C.Red shr 8) shl 16) or
            (Cardinal(C.Green shr 8) shl 8) or Cardinal(C.Blue shr 8);
        end;
  finally
    Intf.Free;
    Tmp.Free;
  end;
end;

{ ---- blits ---- }

function TDirectDrawSurface.DoBlit(Mode: TBlendMode; const DestRect, SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean; Alpha: Integer): Boolean;
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

function TDirectDrawSurface.Draw(X, Y: Integer; const SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean): Boolean;
begin
  Result := DoBlit(bmCopy, Rect(X, Y, X + (SrcRect.Right - SrcRect.Left),
    Y + (SrcRect.Bottom - SrcRect.Top)), SrcRect, Image, Transparent, 255);
end;

function TDirectDrawSurface.Draw(X, Y: Integer; Image: TDirectDrawSurface;
  Transparent: Boolean): Boolean;
begin
  if Image = nil then begin Result := False; Exit; end;
  Result := Draw(X, Y, Rect(0, 0, Image.FWidth, Image.FHeight), Image, Transparent);
end;

function TDirectDrawSurface.StretchDraw(const DestRect, SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean): Boolean;
begin
  Result := DoBlit(bmCopy, DestRect, SrcRect, Image, Transparent, 255);
end;

function TDirectDrawSurface.DrawAlpha(const DestRect, SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmAlpha, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TDirectDrawSurface.DrawAdd(const DestRect, SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmAdd, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TDirectDrawSurface.DrawSub(const DestRect, SrcRect: TRect;
  Image: TDirectDrawSurface; Transparent: Boolean; Alpha: Integer): Boolean;
begin
  Result := DoBlit(bmSub, DestRect, SrcRect, Image, Transparent, Alpha);
end;

function TDirectDrawSurface.DoRotate(Mode: TBlendMode; X, Y, W, H: Integer;
  const SrcRect: TRect; Image: TDirectDrawSurface; CenterX, CenterY: Double;
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

function TDirectDrawSurface.DrawRotate(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean; Angle: Integer): Boolean;
begin
  Result := DoRotate(bmCopy, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, 255);
end;

function TDirectDrawSurface.DrawRotateAlpha(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmAlpha, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

function TDirectDrawSurface.DrawRotateAdd(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmAdd, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

function TDirectDrawSurface.DrawRotateSub(X, Y, Width, Height: Integer; const SrcRect: TRect;
  Image: TDirectDrawSurface; CenterX, CenterY: Double; Transparent: Boolean; Angle, Alpha: Integer): Boolean;
begin
  Result := DoRotate(bmSub, X, Y, Width, Height, SrcRect, Image, CenterX, CenterY, Transparent, Angle, Alpha);
end;

{ ======================= TDirectDrawSurfaceCanvas ======================= }

constructor TDirectDrawSurfaceCanvas.Create(ASurface: TDirectDrawSurface);
begin
  inherited Create;
  FSurface := ASurface;
  FBrush := TBrush.Create;
  FPen := TPen.Create;
  FFont := TFont.Create;
  FBrush.Color := clWhite;
  FFont.Color := clBlack;
end;

destructor TDirectDrawSurfaceCanvas.Destroy;
begin
  FBrush.Free;
  FPen.Free;
  FFont.Free;
  inherited Destroy;
end;

procedure TDirectDrawSurfaceCanvas.Release;
begin
  // nada a liberar: o buffer ja e a propria memoria
end;

function TDirectDrawSurfaceCanvas.GetPixel(X, Y: Integer): TColor;
begin
  Result := FSurface.GetPixel(X, Y);
end;

procedure TDirectDrawSurfaceCanvas.SetPixel(X, Y: Integer; Value: TColor);
begin
  FSurface.SetPixel(X, Y, Value);
end;

procedure TDirectDrawSurfaceCanvas.FillRect(const R: TRect);
var
  X1, Y1, X2, Y2, Y: Integer;
  C: Cardinal;
begin
  X1 := Max(0, Min(R.Left, R.Right));
  X2 := Min(FSurface.FWidth, Max(R.Left, R.Right));
  Y1 := Max(0, Min(R.Top, R.Bottom));
  Y2 := Min(FSurface.FHeight, Max(R.Top, R.Bottom));
  if (X2 <= X1) or (Y2 <= Y1) then Exit;
  C := DXColorToPix(FBrush.Color);
  for Y := Y1 to Y2 - 1 do
    FillDWord(FSurface.FPix[Y * FSurface.FWidth + X1], X2 - X1, C);
end;

procedure TDirectDrawSurfaceCanvas.FrameRect(const R: TRect);
var
  C: Cardinal;
  X, Y, L, T, RR, B: Integer;
begin
  L := Min(R.Left, R.Right); RR := Max(R.Left, R.Right) - 1;
  T := Min(R.Top, R.Bottom); B := Max(R.Top, R.Bottom) - 1;
  C := DXColorToPix(FBrush.Color);
  for X := L to RR do
  begin
    if (X >= 0) and (X < FSurface.FWidth) then
    begin
      if (T >= 0) and (T < FSurface.FHeight) then FSurface.FPix[T * FSurface.FWidth + X] := C;
      if (B >= 0) and (B < FSurface.FHeight) then FSurface.FPix[B * FSurface.FWidth + X] := C;
    end;
  end;
  for Y := T to B do
  begin
    if (Y >= 0) and (Y < FSurface.FHeight) then
    begin
      if (L >= 0) and (L < FSurface.FWidth) then FSurface.FPix[Y * FSurface.FWidth + L] := C;
      if (RR >= 0) and (RR < FSurface.FWidth) then FSurface.FPix[Y * FSurface.FWidth + RR] := C;
    end;
  end;
end;

procedure TDirectDrawSurfaceCanvas.Rectangle(X1, Y1, X2, Y2: Integer);
var
  OldBrush: TColor;
begin
  if FBrush.Style <> bsClear then FillRect(Rect(X1, Y1, X2, Y2));
  OldBrush := FBrush.Color;
  FBrush.Color := FPen.Color;
  FrameRect(Rect(X1, Y1, X2, Y2));
  FBrush.Color := OldBrush;
end;

procedure TDirectDrawSurfaceCanvas.FillRound(X1, Y1, X2, Y2, RX, RY: Integer;
  DoFill, DoOutline: Boolean);
var
  L, T, R, B, W, H, Y, XL, XR, PrevXL, PrevXR, X: Integer;
  HX, HY: Double;
  CY, DYf, Ins: Double;
  FC, PC: Cardinal;
  Surf: TDirectDrawSurface;

  procedure Put(PX, PY: Integer; C: Cardinal);
  begin
    if (PX >= 0) and (PY >= 0) and (PX < Surf.FWidth) and (PY < Surf.FHeight) then
      Surf.FPix[PY * Surf.FWidth + PX] := C;
  end;

begin
  Surf := FSurface;
  L := Min(X1, X2); R := Max(X1, X2);
  T := Min(Y1, Y2); B := Max(Y1, Y2);
  W := R - L; H := B - T;
  if (W <= 0) or (H <= 0) then Exit;
  RX := Min(Abs(RX), W); RY := Min(Abs(RY), H);
  HX := RX / 2.0; HY := RY / 2.0;
  FC := DXColorToPix(FBrush.Color);
  PC := DXColorToPix(FPen.Color);
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
    if DoFill and (FBrush.Style <> bsClear) then
      for X := XL to XR - 1 do Put(X, Y, FC);
    if DoOutline then
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

procedure TDirectDrawSurfaceCanvas.RoundRect(X1, Y1, X2, Y2, RX, RY: Integer);
begin
  FillRound(X1, Y1, X2, Y2, RX, RY, True, True);
end;

procedure TDirectDrawSurfaceCanvas.Ellipse(X1, Y1, X2, Y2: Integer);
begin
  FillRound(X1, Y1, X2, Y2, Abs(X2 - X1), Abs(Y2 - Y1), True, True);
end;

function TDirectDrawSurfaceCanvas.TextWidth(const S: string): Integer;
begin
  ScratchBitmap.Canvas.Font.Assign(FFont);
  Result := ScratchBitmap.Canvas.TextWidth(S);
end;

function TDirectDrawSurfaceCanvas.TextHeight(const S: string): Integer;
begin
  ScratchBitmap.Canvas.Font.Assign(FFont);
  Result := ScratchBitmap.Canvas.TextHeight(S);
end;

procedure TDirectDrawSurfaceCanvas.TextOut(X, Y: Integer; const S: string);
var
  M: TTextMask;
  I, J, DX, DY, Cov, IC: Integer;
  FCol, DP: Cardinal;
  FR, FG, FB, DR, DG, DB: Integer;
begin
  if S = '' then Exit;
  M := GetTextMask(FFont, S);
  if FBrush.Style <> bsClear then
    FillRect(Rect(X, Y, X + M.W, Y + M.H));
  FCol := DXColorToPix(FFont.Color);
  FR := (FCol shr 16) and $FF; FG := (FCol shr 8) and $FF; FB := FCol and $FF;
  for J := 0 to M.H - 1 do
  begin
    DY := Y + J;
    if (DY < 0) or (DY >= FSurface.FHeight) then Continue;
    for I := 0 to M.W - 1 do
    begin
      Cov := M.Data[J * M.W + I];
      if Cov = 0 then Continue;
      DX := X + I;
      if (DX < 0) or (DX >= FSurface.FWidth) then Continue;
      DP := FSurface.FPix[DY * FSurface.FWidth + DX];
      IC := 255 - Cov;
      DR := (((DP shr 16) and $FF) * IC + FR * Cov) div 255;
      DG := (((DP shr 8) and $FF) * IC + FG * Cov) div 255;
      DB := ((DP and $FF) * IC + FB * Cov) div 255;
      FSurface.FPix[DY * FSurface.FWidth + DX] :=
        $FF000000 or (Cardinal(DR) shl 16) or (Cardinal(DG) shl 8) or Cardinal(DB);
    end;
  end;
end;

{ ======================= TPictureCollectionItem ======================= }

constructor TPictureCollectionItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChanged;
  FSurface := TDirectDrawSurface.Create;
  FTransparent := True;
  FTransparentColor := clWhite;
  FDirty := True;
end;

destructor TPictureCollectionItem.Destroy;
begin
  FSurface.Free;
  FPicture.Free;
  inherited Destroy;
end;

procedure TPictureCollectionItem.PictureChanged(Sender: TObject);
begin
  if not FLoading then FDirty := True;
end;

procedure TPictureCollectionItem.SetPicture(Value: TPicture);
begin
  FFromSurface := False;
  FPicture.Assign(Value);
  FDirty := True;
end;

procedure TPictureCollectionItem.SetFileName(const Value: string);
begin
  if FFileName = Value then Exit;
  FFileName := Value;
  FFromSurface := False;
  FDirty := True;
end;

procedure TPictureCollectionItem.SetPatternWidth(Value: Integer);
begin
  if Value < 0 then Value := 0;
  FPatternWidth := Value;
  FDirty := True;
end;

procedure TPictureCollectionItem.SetPatternHeight(Value: Integer);
begin
  if Value < 0 then Value := 0;
  FPatternHeight := Value;
  FDirty := True;
end;

procedure TPictureCollectionItem.SetTransparent(Value: Boolean);
begin
  FTransparent := Value;
end;

procedure TPictureCollectionItem.SetTransparentColor(Value: TColor);
begin
  FTransparentColor := Value;
  FSurface.TransparentColor := Value;
end;

procedure TPictureCollectionItem.Restore;
var
  PW, PH, X, Y, N: Integer;
begin
  if FFromSurface then
  begin
    FDirty := False;
    Exit;
  end;
  FLoading := True;
  try
    if ((FPicture.Graphic = nil) or FPicture.Graphic.Empty) and (FFileName <> '') then
      if FileExists(DXResolvePath(FFileName)) then FPicture.LoadFromFile(DXResolvePath(FFileName));
    if (FPicture.Graphic <> nil) and (not FPicture.Graphic.Empty) then
      FSurface.LoadFromGraphic(FPicture.Graphic)
    else
      FSurface.SetSize(0, 0);
  finally
    FLoading := False;
  end;
  FSurface.TransparentColor := FTransparentColor;
  // padroes (sprite sheet): grade PatternWidth x PatternHeight
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
  FDirty := False;
end;

procedure TPictureCollectionItem.AssignRegion(Src: TDirectDrawSurface; X1, Y1, X2, Y2: Integer;
  Mirror: Boolean);
var
  W, H, X, Y, SX: Integer;
begin
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
  SetLength(FPatterns, 1);
  FPatterns[0] := Rect(0, 0, W, H);
  FFromSurface := True;
  FDirty := False;
end;

procedure TPictureCollectionItem.Ensure;
begin
  if FDirty then Restore;
end;

function TPictureCollectionItem.GetSurface: TDirectDrawSurface;
begin
  Ensure;
  Result := FSurface;
end;

function TPictureCollectionItem.GetPatternCount: Integer;
begin
  Ensure;
  Result := Length(FPatterns);
end;

function TPictureCollectionItem.GetPatternRect(I: Integer): TRect;
begin
  Ensure;
  if (I >= 0) and (I < Length(FPatterns)) then
    Result := FPatterns[I]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPictureCollectionItem.GetWidth: Integer;
begin
  Ensure;
  if FPatternWidth > 0 then Result := FPatternWidth else Result := FSurface.Width;
end;

function TPictureCollectionItem.GetHeight: Integer;
begin
  Ensure;
  if FPatternHeight > 0 then Result := FPatternHeight else Result := FSurface.Height;
end;

procedure TPictureCollectionItem.Draw(Surface: TDirectDrawSurface; X, Y, PatternIndex: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.Draw(X, Y, FPatterns[PatternIndex], FSurface, FTransparent);
end;

procedure TPictureCollectionItem.StretchDraw(Surface: TDirectDrawSurface;
  const DestRect: TRect; PatternIndex: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.StretchDraw(DestRect, FPatterns[PatternIndex], FSurface, FTransparent);
end;

procedure TPictureCollectionItem.DrawAlpha(Surface: TDirectDrawSurface;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawAlpha(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TPictureCollectionItem.DrawAdd(Surface: TDirectDrawSurface;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawAdd(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TPictureCollectionItem.DrawSub(Surface: TDirectDrawSurface;
  const DestRect: TRect; PatternIndex, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawSub(DestRect, FPatterns[PatternIndex], FSurface, FTransparent, Alpha);
end;

procedure TPictureCollectionItem.DrawRotate(Surface: TDirectDrawSurface; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotate(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle);
end;

procedure TPictureCollectionItem.DrawRotateAlpha(Surface: TDirectDrawSurface; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateAlpha(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

procedure TPictureCollectionItem.DrawRotateAdd(Surface: TDirectDrawSurface; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateAdd(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

procedure TPictureCollectionItem.DrawRotateSub(Surface: TDirectDrawSurface; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle, Alpha: Integer);
begin
  Ensure;
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotateSub(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle, Alpha);
end;

{ ======================= TPictureCollection ======================= }

constructor TPictureCollection.Create;
begin
  inherited Create(TPictureCollectionItem);
end;

function TPictureCollection.GetItem(Index: Integer): TPictureCollectionItem;
begin
  Result := TPictureCollectionItem(inherited Items[Index]);
end;

function TPictureCollection.Add: TPictureCollectionItem;
begin
  Result := TPictureCollectionItem(inherited Add);
end;

function TPictureCollection.Find(const Name: string): TPictureCollectionItem;
begin
  Result := TPictureCollectionItem(inherited Find(Name));
end;

procedure TPictureCollection.Restore;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do GetItem(I).Restore;
end;

{ ======================= TCustomDXImageList ======================= }

constructor TCustomDXImageList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TPictureCollection.Create;
end;

destructor TCustomDXImageList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TCustomDXImageList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDXDraw) then FDXDraw := nil;
end;

procedure TCustomDXImageList.SetDXDraw(Value: TCustomDXDraw);
begin
  if FDXDraw = Value then Exit;
  FDXDraw := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;

procedure TCustomDXImageList.SetItems(Value: TPictureCollection);
begin
  FItems.Assign(Value);
end;

procedure TCustomDXImageList.Restore;
begin
  FItems.Restore;
end;

{ ======================= TCustomDXDraw ======================= }

constructor TCustomDXDraw.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSurface := TDirectDrawSurface.Create;
  FDisplay := TDXDrawDisplay.Create;
  FPresent := TBitmap.Create;
  FAutoInitialize := True;
  FSurfaceWidth := 640;
  FSurfaceHeight := 480;
  Width := 100;
  Height := 100;
  DoubleBuffered := True;
  ControlStyle := ControlStyle + [csOpaque];
end;

destructor TCustomDXDraw.Destroy;
begin
  FPresent.Free;
  FDisplay.Free;
  FSurface.Free;
  inherited Destroy;
end;

procedure TCustomDXDraw.Loaded;
begin
  inherited Loaded;
  if FAutoInitialize and not (csDesigning in ComponentState) then Initialize;
end;

procedure TCustomDXDraw.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer;
  WithThemeSpace: Boolean);
begin
  PreferredWidth := FSurfaceWidth;
  PreferredHeight := FSurfaceHeight;
end;

procedure TCustomDXDraw.SetDisplay(Value: TDXDrawDisplay);
begin
  FDisplay.Assign(Value);
end;

procedure TCustomDXDraw.SetSurfaceWidth(Value: Integer);
begin
  if Value < 1 then Value := 1;
  FSurfaceWidth := Value;
  if FInitialized then FSurface.SetSize(FSurfaceWidth, FSurfaceHeight);
  if AutoSize then InvalidatePreferredSize;
end;

procedure TCustomDXDraw.SetSurfaceHeight(Value: Integer);
begin
  if Value < 1 then Value := 1;
  FSurfaceHeight := Value;
  if FInitialized then FSurface.SetSize(FSurfaceWidth, FSurfaceHeight);
  if AutoSize then InvalidatePreferredSize;
end;

procedure TCustomDXDraw.Initialize;
begin
  FSurface.SetSize(FSurfaceWidth, FSurfaceHeight);
  FInitialized := True;
  if AutoSize then
  begin
    InvalidatePreferredSize;
    AdjustSize;
  end;
  if Assigned(FOnInitialize) then FOnInitialize(Self);
end;

procedure TCustomDXDraw.Finalize;
begin
  if Assigned(FOnFinalize) then FOnFinalize(Self);
  FInitialized := False;
end;

procedure TCustomDXDraw.UpdatePresent;
var
  Raw: TRawImage;
  Intf: TLazIntfImage;
  W, H: Integer;
begin
  W := FSurface.Width;
  H := FSurface.Height;
  if (W = 0) or (H = 0) then Exit;
  Raw.Init;
  Raw.Description.Init_BPP32_B8G8R8_BIO_TTB(W, H);
  Raw.CreateData(False);
  Move(FSurface.FPix[0], Raw.Data^, W * H * 4);
  Intf := TLazIntfImage.Create(Raw, True);     // Intf passa a ser dono dos dados
  try
    FPresent.LoadFromIntfImage(Intf);
  finally
    Intf.Free;
  end;
end;

procedure TCustomDXDraw.Flip;
begin
  if not FInitialized then Exit;
  UpdatePresent;
  Invalidate;
  Update;
end;

procedure TCustomDXDraw.EraseBackground(DC: HDC);
begin
  // sem apagar o fundo: evita piscar (o Paint cobre toda a area)
end;

procedure TCustomDXDraw.Paint;
var
  T0: Double;
begin
  T0 := DXHiResMs;
  if (FPresent.Width > 0) and (FPresent.Height > 0) then
    Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), FPresent)
  else
  begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(0, 0, ClientWidth, ClientHeight);
  end;
  FLastPaintMs := DXHiResMs - T0;
end;

initialization
  RegisterClasses([TDXDraw, TDXImageList]);

finalization
  GMaskCache.Free;
  GScratch.Free;

end.
