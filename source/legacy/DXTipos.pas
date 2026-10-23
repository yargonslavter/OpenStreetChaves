unit DXTipos;

{ DXTipos.pas - tipos basicos independentes de LCL (cor, pincel, caneta, fonte).

  Substitui o que o jogo usava de Graphics (TColor, clWhite, bsClear...).
  Cor = $00BBGGRR (mesmo formato do Delphi/Lazarus). }

{$mode delphi}{$H+}

interface

type
  TColor = type Longint;

  { cobertura de um texto: W x H bytes, 0 = fundo, 255 = tinta cheia }
  TDXMascara = array of Byte;

  TBrushStyle = (bsSolid, bsClear);

  { Pincel / caneta / fonte do TDirectDrawSurfaceCanvas (so o que o jogo usa) }
  TDXBrush = class
  public
    Color: TColor;
    Style: TBrushStyle;
    constructor Create;
  end;

  TDXPen = class
  public
    Color: TColor;
    constructor Create;
  end;

  TDXFont = class
  public
    Name: string;
    Size: Integer;
    Style: Integer;     // reservado (0 = normal)
    Color: TColor;
    constructor Create;
  end;

const
  clBlack = TColor($000000);
  clWhite = TColor($FFFFFF);
  clRed = TColor($0000FF);
  clGreen = TColor($008000);
  clBlue = TColor($FF0000);
  clYellow = TColor($00FFFF);
  clGray = TColor($808080);

function RGBToColor(R, G, B: Byte): TColor; inline;
function ColorToRGB(C: TColor): TColor; inline;

implementation

constructor TDXBrush.Create;
begin
  inherited Create;
  Color := clWhite;
  Style := bsSolid;
end;

constructor TDXPen.Create;
begin
  inherited Create;
  Color := clBlack;
end;

constructor TDXFont.Create;
begin
  inherited Create;
  Name := 'Arial';
  Size := 10;
  Color := clBlack;
end;

function RGBToColor(R, G, B: Byte): TColor;
begin
  Result := TColor(R or (G shl 8) or (B shl 16));
end;

function ColorToRGB(C: TColor): TColor;
begin
  Result := C;
end;

end.
