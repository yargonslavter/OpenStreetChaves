{ DXTexto.pas - texto desenhado com a fonte do sistema (Graphics/LCL), usado so pela ferramenta
  GeraFonte para montar e conferir o atlas de glifos (o jogo nao usa esta unit).
  Entrega o texto como mascara de cobertura 8 bits (0..255), W x H. }

unit DXTexto;

{$mode delphi}{$H+}

interface

uses
  ChavesFonte;

{ Desenha um texto com a fonte do sistema (GDI/LCL) e devolve a cobertura.
  @param(FontName nome da fonte do sistema)
  @param(Size tamanho em pontos)
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado)
  @param(S texto em UTF-8)
  @param(W recebe a largura (a largura de avanco do texto))
  @param(H recebe a altura)
  @param(Dados recebe W*H bytes, 0 = fundo, 255 = tinta cheia) }
procedure DXTextoMascara(const FontName: string; Size, Style: Integer; const S: string;
  out W, H: Integer; out Dados: TMascara);
{ Igual a DXTextoMascara, com Margem pixels extras de cada lado (o texto sai em (Margem, 0)),
  para capturar as partes do glifo que passam da largura de avanco.
  @param(FontName nome da fonte do sistema)
  @param(Size tamanho em pontos)
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado)
  @param(S texto em UTF-8)
  @param(Margem pixels extras em cada lado)
  @param(W recebe a largura (avanco + 2 * Margem))
  @param(H recebe a altura)
  @param(Dados recebe W*H bytes de cobertura) }
procedure DXTextoMascaraMargem(const FontName: string; Size, Style: Integer; const S: string;
  Margem: Integer; out W, H: Integer; out Dados: TMascara);
{ Largura de avanco de um texto na fonte do sistema.
  @param(FontName nome da fonte do sistema)
  @param(Size tamanho em pontos)
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado)
  @param(S texto em UTF-8)
  @returns(a largura em pixels) }
function DXTextoLargura(const FontName: string; Size, Style: Integer; const S: string): Integer;
{ Altura de um texto na fonte do sistema.
  @param(FontName nome da fonte do sistema)
  @param(Size tamanho em pontos)
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado)
  @param(S texto em UTF-8)
  @returns(a altura em pixels) }
function DXTextoAltura(const FontName: string; Size, Style: Integer; const S: string): Integer;
{ Ascendente da fonte (distancia do topo da celula ate a linha de base), como no GDI.
  @param(FontName nome da fonte do sistema)
  @param(Size tamanho em pontos (negativo = altura do caractere em pixels))
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado)
  @returns(o ascendente em pixels) }
function DXTextoAscendente(const FontName: string; Size, Style: Integer): Integer;

implementation

uses
  Classes, SysUtils, Math, Graphics, GraphType, IntfGraphics, FPImage, LCLType, LCLIntf;

var
  GScratch: TBitmap = nil;

{ @returns(o bitmap de rascunho (criado na primeira chamada, 32 bits)) }
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

{ Configura a fonte do canvas (branca, com anti-serrilhado).
  @param(B bitmap)
  @param(FontName nome da fonte)
  @param(Size tamanho em pontos (negativo = altura do caractere em pixels, como TFont.Height))
  @param(Style bits: 1 negrito, 2 italico, 4 sublinhado, 8 riscado) }
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
  if Size < 0 then B.Canvas.Font.Height := Size else B.Canvas.Font.Size := Size;
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

function DXTextoAscendente(const FontName: string; Size, Style: Integer): Integer;
var
  TM: TTextMetric;
begin
  AjustaFonte(Scratch, FontName, Size, Style);
  Scratch.Canvas.TextWidth('H');           // garante a fonte selecionada no DC
  if GetTextMetrics(Scratch.Canvas.Handle, TM) then Result := TM.tmAscent else Result := 0;
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
