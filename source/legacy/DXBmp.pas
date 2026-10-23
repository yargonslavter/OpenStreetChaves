unit DXBmp;

{ DXBmp.pas - imagem em memoria (ARGB 32 bits) com leitor de BMP proprio, sem LCL.

  TDXPicture faz o papel que TPicture/TBitmap tinham no jogo: LoadFromFile, Assign, Empty,
  Width/Height e Graphic (devolve ele mesmo, para manter a sintaxe do codigo original).
  Le BMP de 1, 4, 8, 16, 24 e 32 bits, sem compressao, RLE4/RLE8 e BITFIELDS, com cabecalhos
  OS/2 (12) e Windows (40..124). O canal alfa de 32 bits e ignorado (pixels opacos), como era
  no carregamento anterior. Pixel = $FFRRGGBB. }

{$mode delphi}{$H+}
{$POINTERMATH ON}

interface

uses
  Classes, SysUtils;

type
  EDXBmp = class(Exception);

  TDXPicture = class(TPersistent)
  private
    FWidth, FHeight: Integer;
    FPix: array of Cardinal;
    FOnChange: TNotifyEvent;
    function GetGraphic: TDXPicture;
    function GetEmpty: Boolean;
    procedure Changed;
  public
    procedure Assign(Source: TPersistent); override;
    procedure Clear;
    procedure SetSize(AWidth, AHeight: Integer);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    function ScanLine(Y: Integer): PCardinal;
    property Graphic: TDXPicture read GetGraphic;
    property Empty: Boolean read GetEmpty;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

function TDXPicture.GetGraphic: TDXPicture;
begin
  Result := Self;
end;

function TDXPicture.GetEmpty: Boolean;
begin
  Result := (FWidth = 0) or (FHeight = 0);
end;

procedure TDXPicture.Changed;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TDXPicture.Clear;
begin
  FWidth := 0;
  FHeight := 0;
  FPix := nil;
  Changed;
end;

procedure TDXPicture.SetSize(AWidth, AHeight: Integer);
begin
  if AWidth < 0 then AWidth := 0;
  if AHeight < 0 then AHeight := 0;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPix, FWidth * FHeight);
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), $FF000000);
end;

function TDXPicture.ScanLine(Y: Integer): PCardinal;
begin
  Result := @FPix[Y * FWidth];
end;

procedure TDXPicture.Assign(Source: TPersistent);
var
  S: TDXPicture;
begin
  if Source is TDXPicture then
  begin
    S := TDXPicture(Source);
    FWidth := S.FWidth;
    FHeight := S.FHeight;
    FPix := Copy(S.FPix);
    Changed;
  end
  else if Source = nil then
    Clear
  else
    inherited Assign(Source);
end;

procedure TDXPicture.LoadFromFile(const FileName: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

{ ---- leitor de BMP ---- }

function Le16(P: PByte): Integer; inline;
begin
  Result := P[0] or (P[1] shl 8);
end;

function Le32(P: PByte): Integer; inline;
begin
  Result := Integer(Cardinal(P[0]) or (Cardinal(P[1]) shl 8) or (Cardinal(P[2]) shl 16) or (Cardinal(P[3]) shl 24));
end;

{ amplia um campo de mascara (ex.: 5 bits) para 8 bits }
function CampoPara8(V: Cardinal; Mascara: Cardinal): Cardinal;
var
  Sh, Bits: Integer;
  Max: Cardinal;
begin
  if Mascara = 0 then Exit(0);
  Sh := 0;
  while (Mascara and 1) = 0 do
  begin
    Mascara := Mascara shr 1;
    Inc(Sh);
  end;
  Bits := 0;
  Max := Mascara;
  while Max <> 0 do
  begin
    Inc(Bits);
    Max := Max shr 1;
  end;
  V := (V shr Sh) and Mascara;
  if Bits >= 8 then Result := V shr (Bits - 8)
  else Result := (V * 255) div Mascara;
end;

procedure TDXPicture.LoadFromStream(Stream: TStream);
var
  Dados: array of Byte;
  Tam, Off, HdrSize, W, H, Planes, Bpp, Comp, ClrUsed, I, X, Y, Stride, NPal, PalOff, PalSize: Integer;
  TopDown: Boolean;
  Pal: array[0..255] of Cardinal;
  MR, MG, MB: Cardinal;
  P: PByte;
  Linha: PCardinal;
  V: Cardinal;

  function Pix(R, G, B: Cardinal): Cardinal;
  begin
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
  end;

  procedure DecodificaRLE(Is4: Boolean);
  var
    Pos, Px, Py, N, B1, B2, J, Dx, Dy, Idx: Integer;
    Fim: Boolean;
  begin
    Pos := Off;
    Px := 0;
    Py := 0;
    Fim := False;
    while (not Fim) and (Pos + 1 < Tam) do
    begin
      B1 := Dados[Pos]; B2 := Dados[Pos + 1];
      Inc(Pos, 2);
      if B1 > 0 then
      begin
        { repete B1 pixels }
        for J := 0 to B1 - 1 do
        begin
          if Is4 then
          begin
            if (J and 1) = 0 then Idx := B2 shr 4 else Idx := B2 and 15;
          end
          else Idx := B2;
          if (Px < W) and (Py < H) then
            FPix[(H - 1 - Py) * W + Px] := Pal[Idx and 255];
          Inc(Px);
        end;
      end
      else
        case B2 of
          0: begin Px := 0; Inc(Py); end;
          1: Fim := True;
          2: begin
               if Pos + 1 >= Tam then Break;
               Dx := Dados[Pos]; Dy := Dados[Pos + 1]; Inc(Pos, 2);
               Inc(Px, Dx); Inc(Py, Dy);
             end;
        else
          begin
            N := B2;
            for J := 0 to N - 1 do
            begin
              if Is4 then
              begin
                if Pos + (J div 2) >= Tam then Break;
                if (J and 1) = 0 then Idx := Dados[Pos + (J div 2)] shr 4
                else Idx := Dados[Pos + (J div 2)] and 15;
              end
              else
              begin
                if Pos + J >= Tam then Break;
                Idx := Dados[Pos + J];
              end;
              if (Px < W) and (Py < H) then
                FPix[(H - 1 - Py) * W + Px] := Pal[Idx and 255];
              Inc(Px);
            end;
            if Is4 then Inc(Pos, (N + 1) div 2) else Inc(Pos, N);
            if Pos and 1 = 1 then Inc(Pos);      // alinha em 16 bits
          end;
        end;
    end;
  end;

begin
  Tam := Stream.Size - Stream.Position;
  if Tam < 26 then raise EDXBmp.Create('BMP invalido (arquivo muito pequeno)');
  SetLength(Dados, Tam);
  Stream.ReadBuffer(Dados[0], Tam);
  if (Dados[0] <> Ord('B')) or (Dados[1] <> Ord('M')) then raise EDXBmp.Create('Nao e um arquivo BMP');
  Off := Le32(@Dados[10]);
  HdrSize := Le32(@Dados[14]);
  if HdrSize = 12 then
  begin
    W := Le16(@Dados[18]);
    H := Le16(@Dados[20]);
    Planes := Le16(@Dados[22]);
    Bpp := Le16(@Dados[24]);
    Comp := 0;
    ClrUsed := 0;
    PalSize := 3;
  end
  else if HdrSize >= 40 then
  begin
    W := Le32(@Dados[18]);
    H := Le32(@Dados[22]);
    Planes := Le16(@Dados[26]);
    Bpp := Le16(@Dados[28]);
    Comp := Le32(@Dados[30]);
    ClrUsed := Le32(@Dados[46]);
    PalSize := 4;
  end
  else raise EDXBmp.Create('Cabecalho de BMP nao suportado');
  if Planes <> 1 then raise EDXBmp.Create('BMP com planos <> 1');
  TopDown := H < 0;
  if TopDown then H := -H;
  if (W <= 0) or (H <= 0) or (W > 16384) or (H > 16384) then raise EDXBmp.Create('Dimensoes de BMP invalidas');

  { paleta }
  FillChar(Pal, SizeOf(Pal), 0);
  if Bpp <= 8 then
  begin
    NPal := ClrUsed;
    if (NPal = 0) or (NPal > (1 shl Bpp)) then NPal := 1 shl Bpp;
    PalOff := 14 + HdrSize;
    for I := 0 to NPal - 1 do
      if PalOff + I * PalSize + 2 < Tam then
        Pal[I] := Pix(Dados[PalOff + I * PalSize + 2], Dados[PalOff + I * PalSize + 1], Dados[PalOff + I * PalSize]);
  end;

  { mascaras }
  MR := 0; MG := 0; MB := 0;
  if (Bpp = 16) or (Bpp = 32) then
  begin
    if (Comp = 3) or (Comp = 6) then
    begin
      if HdrSize >= 52 then
      begin
        MR := Cardinal(Le32(@Dados[54])); MG := Cardinal(Le32(@Dados[58])); MB := Cardinal(Le32(@Dados[62]));
      end
      else
      begin
        MR := Cardinal(Le32(@Dados[14 + HdrSize])); MG := Cardinal(Le32(@Dados[18 + HdrSize]));
        MB := Cardinal(Le32(@Dados[22 + HdrSize]));
      end;
    end
    else if Bpp = 16 then
    begin
      MR := $7C00; MG := $03E0; MB := $001F;
    end
    else
    begin
      MR := $00FF0000; MG := $0000FF00; MB := $000000FF;
    end;
  end;

  SetSize(W, H);

  if (Comp = 1) and (Bpp = 8) then DecodificaRLE(False)
  else if (Comp = 2) and (Bpp = 4) then DecodificaRLE(True)
  else if (Comp = 0) or (Comp = 3) or (Comp = 6) then
  begin
    Stride := ((W * Bpp + 31) div 32) * 4;
    { alguns arquivos tem o ultimo trecho truncado: aceita se a ultima linha tiver os pixels }
    if Off + Stride * (H - 1) + ((W * Bpp + 7) div 8) > Tam then
      raise EDXBmp.Create('BMP truncado');
    SetLength(Dados, Tam + Stride + 8);      // folga (zeros) para a ultima linha truncada
    for Y := 0 to H - 1 do
    begin
      if TopDown then Linha := @FPix[Y * W] else Linha := @FPix[(H - 1 - Y) * W];
      P := @Dados[Off + Y * Stride];
      case Bpp of
        1: for X := 0 to W - 1 do
             Linha[X] := Pal[(P[X shr 3] shr (7 - (X and 7))) and 1];
        4: for X := 0 to W - 1 do
             if (X and 1) = 0 then Linha[X] := Pal[P[X shr 1] shr 4]
             else Linha[X] := Pal[P[X shr 1] and 15];
        8: for X := 0 to W - 1 do
             Linha[X] := Pal[P[X]];
        16: for X := 0 to W - 1 do
            begin
              V := Cardinal(Le16(@P[X * 2]));
              Linha[X] := Pix(CampoPara8(V, MR), CampoPara8(V, MG), CampoPara8(V, MB));
            end;
        24: for X := 0 to W - 1 do
              Linha[X] := Pix(P[X * 3 + 2], P[X * 3 + 1], P[X * 3]);
        32: for X := 0 to W - 1 do
            begin
              V := Cardinal(Le32(@P[X * 4]));
              Linha[X] := Pix(CampoPara8(V, MR), CampoPara8(V, MG), CampoPara8(V, MB));
            end;
      else
        raise EDXBmp.Create('Profundidade de cor de BMP nao suportada');
      end;
    end;
  end
  else raise EDXBmp.Create('Compressao de BMP nao suportada');
  Changed;
end;

end.
