unit DXTexto;

{ DXTexto.pas - renderizacao de texto (TEMPORARIA, usa a fonte do sistema via LCL).

  Esta e a UNICA unit do jogo que ainda depende de Graphics/LCL. Ela existe isolada para que
  a Fase 4 a troque por um atlas de glifos proprio (sem fonte do sistema), sem mexer no resto.
  Entrega o texto como mascara de cobertura 8 bits (0..255), W x H. }

{$mode delphi}{$H+}

interface

uses
  ChavesFonte;

{ Desenha S com a fonte dada e devolve a cobertura (0 = fundo, 255 = tinta cheia) }
procedure DXTextoMascara(const FontName: string; Size, Style: Integer; const S: string;
  out W, H: Integer; out Dados: TMascara);
{ Igual, mas com Margem pixels extras de cada lado (o texto sai em (Margem, 0)); serve para
  capturar partes do glifo que passam da largura de avanco. Usada so pela ferramenta GeraFonte. }
procedure DXTextoMascaraMargem(const FontName: string; Size, Style: Integer; const S: string;
  Margem: Integer; out W, H: Integer; out Dados: TMascara);
function DXTextoLargura(const FontName: string; Size, Style: Integer; const S: string): Integer;
function DXTextoAltura(const FontName: string; Size, Style: Integer; const S: string): Integer;

implementation

uses
  Classes, SysUtils, Math, Graphics, GraphType, IntfGraphics, FPImage;

var
  GScratch: TBitmap = nil;

function Scratch: TBitmap;
begin
  if GScratch = nil then
  begin
    GScratch := TBitmap.Create;
    GScratch.PixelFormat := pf32bit;
    GScratch.SetSize(8, 8);
  end;
  Result := GScratch;
end;

procedure AjustaFonte(B: TBitmap; const FontName: string; Size, Style: Integer);
var
  Est: TFontStyles;
begin
  Est := [];                                   // bits de Style: 1 negrito, 2 italico, 4 sublinhado, 8 riscado
  if (Style and 1) <> 0 then Include(Est, fsBold);
  if (Style and 2) <> 0 then Include(Est, fsItalic);
  if (Style and 4) <> 0 then Include(Est, fsUnderline);
  if (Style and 8) <> 0 then Include(Est, fsStrikeOut);
  B.Canvas.Font.Name := FontName;
  B.Canvas.Font.Size := Size;
  B.Canvas.Font.Style := Est;
  B.Canvas.Font.Color := clWhite;
  B.Canvas.Font.Quality := fqAntialiased;
end;

function DXTextoLargura(const FontName: string; Size, Style: Integer; const S: string): Integer;
begin
  AjustaFonte(Scratch, FontName, Size, Style);
  Result := Scratch.Canvas.TextWidth(S);
end;

function DXTextoAltura(const FontName: string; Size, Style: Integer; const S: string): Integer;
begin
  AjustaFonte(Scratch, FontName, Size, Style);
  Result := Scratch.Canvas.TextHeight(S);
end;

procedure DXTextoMascaraMargem(const FontName: string; Size, Style: Integer; const S: string;
  Margem: Integer; out W, H: Integer; out Dados: TMascara);
var
  B: TBitmap;
  Intf: TLazIntfImage;
  X, Y, TW: Integer;
begin
  B := Scratch;
  AjustaFonte(B, FontName, Size, Style);
  TW := Max(1, B.Canvas.TextWidth(S));
  W := TW + 2 * Margem;
  H := Max(1, B.Canvas.TextHeight(S));
  B.SetSize(W, H);
  B.Canvas.Brush.Style := bsSolid;
  B.Canvas.Brush.Color := clBlack;
  B.Canvas.FillRect(0, 0, W, H);
  B.Canvas.Brush.Style := bsClear;
  AjustaFonte(B, FontName, Size, Style);
  B.Canvas.TextOut(Margem, 0, S);

  SetLength(Dados, W * H);
  Intf := TLazIntfImage.Create(0, 0);
  try
    Intf.LoadFromBitmap(B.Handle, B.MaskHandle);
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
        Dados[Y * W + X] := Intf.Colors[X, Y].Green shr 8;
  finally
    Intf.Free;
  end;
end;

procedure DXTextoMascara(const FontName: string; Size, Style: Integer; const S: string;
  out W, H: Integer; out Dados: TMascara);
begin
  DXTextoMascaraMargem(FontName, Size, Style, S, 0, W, H, Dados);
end;

finalization
  GScratch.Free;

end.
