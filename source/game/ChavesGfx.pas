{ ChavesGfx.pas - graficos do jogo em software (substitui o DXDraws da camada DelphiX).

  Tudo e desenhado num buffer ARGB (0xAARRGGBB) na memoria; quem apresenta o quadro na tela e o
  ChavesSDL (textura SDL). Nao ha canvas, pincel ou caneta: cada primitiva recebe suas cores.

    TSuperficie    buffer de pixels + copias (normal, esticada, alfa, rotacao)
                   + retangulos, elipses, retangulos redondos e texto (fonte do atlas)
    TImagem        imagem com cor transparente e "padroes" (grade de quadros de uma folha)
    TListaImagens  lista numerada de imagens (ImgX[i].Draw(Tela, X, Y, Quadro)), com busca
                   opcional por nome (ImgX.PorNome('Mesa'); nomes vem de Dados/Recursos.ini)

  Cor "TColor" = 0x00BBGGRR (como no Delphi); pixel = 0xAARRGGBB. }

unit ChavesGfx;

{$mode delphi}{$H+}
{$POINTERMATH ON}

interface

uses
  Classes, SysUtils, Types, Math, ChavesConst, ChavesFonte, ChavesDados;

type
  TBlendMode = (bmCopy, bmAlpha);

  TSuperficie = class
  private
    FWidth, FHeight: Integer;
    FPix: array of Cardinal;
    FTransparentColor: TColor;
    FMap: array of Integer;           // buffer reutilizavel p/ mapeamento de colunas
    { @param(X coluna)
      @param(Y linha)
      @returns(a cor do pixel; Preto fora da superficie) }
    function GetPixel(X, Y: Integer): TColor;
    { @param(X coluna)
      @param(Y linha)
      @param(Value cor (fora da superficie = ignora)) }
    procedure SetPixel(X, Y: Integer; Value: TColor);
    { Copia com mistura: base de Draw, StretchDraw e DrawAlpha. Estica por
      vizinho mais proximo e recorta nas bordas.
      @param(Mode bmCopy ou bmAlpha)
      @param(DestRect retangulo de destino (largura ou altura negativa espelha))
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @param(Alpha intensidade, 0..255 (ignorada em bmCopy))
      @returns(False se nada foi desenhado) }
    function DoBlit(Mode: TBlendMode; const DestRect, SrcRect: TRect;
      Image: TSuperficie; Transparent: Boolean; Alpha: Integer): Boolean;
    { Copia girada com mistura: base de DrawRotate (mapeamento inverso, vizinho mais
      proximo).
      @param(Mode bmCopy ou bmAlpha)
      @param(X esquerda do retangulo de destino (antes de girar))
      @param(Y topo)
      @param(W largura do destino)
      @param(H altura do destino)
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(CenterX pivo horizontal como fracao do retangulo)
      @param(CenterY pivo vertical como fracao do retangulo)
      @param(Transparent True = pula os pixels da cor transparente)
      @param(Angle angulo, 0..255 = 0..360 graus)
      @param(Alpha intensidade, 0..255)
      @returns(False se nada foi desenhado) }
    function DoRotate(Mode: TBlendMode; X, Y, W, H: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle, Alpha: Integer): Boolean;
    { Desenha um retangulo de cantos arredondados (com RX/RY do tamanho do retangulo vira elipse),
      como o RoundRect do GDI.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(RX largura da elipse dos cantos)
      @param(RY altura da elipse dos cantos)
      @param(CorBorda cor do contorno)
      @param(CorFundo cor do preenchimento)
      @param(Preencher False = so o contorno) }
    procedure Forma(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor;
      Preencher: Boolean);
  public
    { Cria uma superficie vazia (0 x 0) com cor transparente Preto. }
    constructor Create;
    { Muda o tamanho e pinta tudo de preto.
      @param(AWidth largura (negativo = 0))
      @param(AHeight altura (negativo = 0)) }
    procedure SetSize(AWidth, AHeight: Integer);
    { Carrega um BMP (1/4/8/16/24/32 bits, RLE e BITFIELDS) para a superficie, trocando o tamanho.
      @param(Arquivo caminho do BMP (resolvido por ResolverCaminho))
      @returns(False se o arquivo nao existe ou e invalido (a superficie fica 0 x 0))
      @raises(Exception BMP corrompido ou num formato nao suportado) }
    function CarregarBMP(const Arquivo: string): Boolean;
    { @param(Y linha (sem conferencia de faixa))
      @returns(o endereco do primeiro pixel da linha (ARGB)) }
    function ScanLine(Y: Integer): PCardinal;
    { Copia uma regiao de outra superficie para (X, Y), no mesmo tamanho.
      @param(X esquerda do destino)
      @param(Y topo do destino)
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @returns(False se nada foi desenhado) }
    function Draw(X, Y: Integer; const SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean): Boolean; overload;
    { Copia outra superficie inteira para (X, Y).
      @param(X esquerda do destino)
      @param(Y topo do destino)
      @param(Image superficie de origem (nil = nada))
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @returns(False se nada foi desenhado) }
    function Draw(X, Y: Integer; Image: TSuperficie; Transparent: Boolean): Boolean; overload;
    { Copia uma regiao de outra superficie esticando para o retangulo de destino.
      @param(DestRect retangulo de destino (largura ou altura negativa espelha))
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @returns(False se nada foi desenhado) }
    function StretchDraw(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean): Boolean;
    { Copia uma regiao de outra superficie para um retangulo desta (esticando se os tamanhos
      forem diferentes), misturando com o fundo pela opacidade Alpha.
      @param(DestRect retangulo de destino (largura ou altura negativa espelha))
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @param(Alpha intensidade, 0..255)
      @returns(False se nada foi desenhado (imagem vazia ou fora da tela)) }
    function DrawAlpha(const DestRect, SrcRect: TRect; Image: TSuperficie;
      Transparent: Boolean; Alpha: Integer): Boolean;
    { Desenha uma regiao de outra superficie girada em torno de um pivo, copiando.
      @param(X esquerda do retangulo de destino (antes de girar))
      @param(Y topo do retangulo de destino)
      @param(Width largura do destino)
      @param(Height altura do destino)
      @param(SrcRect regiao de Image)
      @param(Image superficie de origem)
      @param(CenterX pivo horizontal como fracao do retangulo (0.5 = centro))
      @param(CenterY pivo vertical como fracao do retangulo)
      @param(Transparent True = pula os pixels da cor transparente de Image)
      @param(Angle angulo, 0..255 = 0..360 graus)
      @returns(False se nada foi desenhado) }
    function DrawRotate(X, Y, Width, Height: Integer; const SrcRect: TRect;
      Image: TSuperficie; CenterX, CenterY: Double; Transparent: Boolean;
      Angle: Integer): Boolean;
    { primitivas (X2/Y2 exclusivos, como no Delphi) }

    { Pinta um retangulo (recortado nas bordas).
      @param(R retangulo (Right e Bottom exclusivos, como no Delphi))
      @param(Cor a cor) }
    procedure PreencherRect(const R: TRect; Cor: TColor);
    { Desenha o contorno de um retangulo, com 1 pixel de espessura.
      @param(R retangulo (Right e Bottom exclusivos))
      @param(Cor a cor) }
    procedure Moldura(const R: TRect; Cor: TColor);
    { Retangulo de cantos arredondados, preenchido, como o RoundRect do GDI.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(RX largura da elipse dos cantos)
      @param(RY altura da elipse dos cantos)
      @param(CorBorda cor do contorno)
      @param(CorFundo cor do preenchimento) }
    procedure RoundRect(X1, Y1, X2, Y2, RX, RY: Integer; CorBorda, CorFundo: TColor);
    { Elipse inscrita no retangulo.
      @param(X1 esquerda)
      @param(Y1 topo)
      @param(X2 direita (exclusiva))
      @param(Y2 base (exclusiva))
      @param(CorBorda cor do contorno)
      @param(CorFundo cor do preenchimento)
      @param(Preencher False = so o contorno) }
    procedure Elipse(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor; Preencher: Boolean);
    { Escreve um texto com a fonte do atlas, com anti-serrilhado (a sombra e feita por quem chama).
      @param(X esquerda)
      @param(Y topo da celula do texto)
      @param(S texto em UTF-8)
      @param(Tam tamanho da fonte em pontos)
      @param(Cor cor do texto) }
    procedure Texto(X, Y: Integer; const S: string; Tam: Integer; Cor: TColor);
    { @param(S texto em UTF-8)
      @param(Tam tamanho da fonte)
      @returns(a largura do texto em pixels) }
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
    { @param(Value nova cor transparente (vale tambem para a superficie interna)) }
    procedure SetTransparentColor(Value: TColor);
    { Divide a superficie numa grade de padroes (quadros) de FPatternWidth x FPatternHeight,
      da esquerda para a direita e de cima para baixo (0 = a imagem inteira). }
    procedure MontarPadroes;
    { @returns(quantos padroes (quadros) a imagem tem) }
    function GetPatternCount: Integer;
    { @param(I numero do padrao)
      @returns(o retangulo do padrao na superficie; vazio fora da faixa) }
    function GetPatternRect(I: Integer): TRect;
    { @returns(a largura de um padrao (ou da imagem inteira)) }
    function GetWidth: Integer;
    { @returns(a altura de um padrao (ou da imagem inteira)) }
    function GetHeight: Integer;
  public
    { Cria uma imagem vazia, transparente, com cor transparente Branco. }
    constructor Create;
    { Libera a superficie interna. }
    destructor Destroy; override;
    { Carrega um BMP e divide em padroes (quadros).
      @param(Arquivo caminho do BMP)
      @param(Transparente True = a cor CorTransp nao e desenhada)
      @param(CorTransp cor transparente)
      @param(PW largura de cada quadro da folha (0 = imagem inteira))
      @param(PH altura de cada quadro da folha (0 = imagem inteira)) }
    procedure CarregarArquivo(const Arquivo: string; Transparente: Boolean; CorTransp: TColor;
      PW: Integer = 0; PH: Integer = 0);
    { Preenche a imagem com uma regiao de outra superficie (um unico padrao).
      @param(Src superficie de origem)
      @param(X1 esquerda da regiao)
      @param(Y1 topo da regiao)
      @param(X2 direita da regiao (exclusiva))
      @param(Y2 base da regiao (exclusiva))
      @param(Mirror True = espelha na horizontal)
      @param(Transparente True = a cor CorTransp nao e desenhada)
      @param(CorTransp cor transparente) }
    procedure AtribuirRegiao(Src: TSuperficie; X1, Y1, X2, Y2: Integer; Mirror: Boolean;
      Transparente: Boolean; CorTransp: TColor);
    { Desenha um padrao (quadro) da imagem em (X, Y).
      @param(Surface superficie de destino)
      @param(X esquerda)
      @param(Y topo)
      @param(PatternIndex numero do padrao (fora da faixa = nada)) }
    procedure Draw(Surface: TSuperficie; X, Y, PatternIndex: Integer);
    { Desenha um padrao (quadro) da imagem esticado no retangulo.
      @param(Surface superficie de destino)
      @param(DestRect retangulo de destino)
      @param(PatternIndex numero do padrao (fora da faixa = nada)) }
    procedure StretchDraw(Surface: TSuperficie; const DestRect: TRect; PatternIndex: Integer);
    { Desenha um padrao (quadro) da imagem esticado no retangulo, misturando com o fundo pela opacidade Alpha.
      @param(Surface superficie de destino)
      @param(DestRect retangulo de destino)
      @param(PatternIndex numero do padrao (fora da faixa = nada))
      @param(Alpha intensidade, 0..255) }
    procedure DrawAlpha(Surface: TSuperficie; const DestRect: TRect; PatternIndex, Alpha: Integer);
    { Desenha um padrao (quadro) da imagem girado em torno de um pivo, copiando.
      @param(Surface superficie de destino)
      @param(X esquerda do retangulo de destino (antes de girar))
      @param(Y topo)
      @param(Width largura do destino)
      @param(Height altura do destino)
      @param(PatternIndex numero do padrao (fora da faixa = nada))
      @param(CenterX pivo horizontal como fracao do retangulo (0.5 = centro))
      @param(CenterY pivo vertical)
      @param(Angle angulo, 0..255 = 0..360 graus) }
    procedure DrawRotate(Surface: TSuperficie; X, Y, Width, Height, PatternIndex: Integer;
      CenterX, CenterY: Double; Angle: Integer);
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
    { @param(Indice numero da imagem (sem conferencia de faixa))
      @returns(a imagem) }
    function GetItem(Indice: Integer): TImagem;
    { @returns(quantas imagens a lista tem) }
    function GetCount: Integer;
  public
    { Cria uma lista vazia. }
    constructor Create;
    { Libera todas as imagens da lista. }
    destructor Destroy; override;
    { Acrescenta uma imagem vazia ao fim da lista.
      @param(Nome nome para PorNome ('' = sem nome))
      @returns(a imagem nova (a lista e a dona)) }
    function Adicionar(const Nome: string = ''): TImagem;
    { Da mais um nome a uma imagem (um nome repetido e ignorado).
      @param(Nome nome ('' = ignora))
      @param(Indice numero da imagem (fora da faixa = ignora)) }
    procedure Apelidar(const Nome: string; Indice: Integer);
    { @param(Nome nome da imagem (sem diferenciar maiusculas))
      @returns(o numero da imagem, ou -1 se nao existir) }
    function IndiceDe(const Nome: string): Integer;
    { @param(Nome nome da imagem (sem diferenciar maiusculas))
      @returns(a imagem; se nao existir, uma imagem vazia (desenhar nao faz nada)) }
    function PorNome(const Nome: string): TImagem;
    property Count: Integer read GetCount;
    property Items[Indice: Integer]: TImagem read GetItem; default;
  end;

{ Conversoes de cor }
{ @param(C cor TColor ($00BBGGRR))
  @returns(o pixel opaco $FFRRGGBB) }
function CorParaPixel(C: TColor): Cardinal;
{ @param(P pixel $AARRGGBB)
  @returns(a cor TColor ($00BBGGRR), sem o alfa) }
function PixelParaCor(P: Cardinal): TColor;

implementation

{ ---- leitor de BMP (antes legacy/DXBmp.pas): imagem em memoria (ARGB 32 bits) com leitor de BMP proprio, sem LCL.

  TLeitorBMP faz o papel que TPicture/TBitmap tinham no jogo: LoadFromFile, Empty e
  Width/Height.
  Le BMP de 1, 4, 8, 16, 24 e 32 bits, sem compressao, RLE4/RLE8 e BITFIELDS, com cabecalhos
  OS/2 (12) e Windows (40..124). O canal alfa de 32 bits e ignorado (pixels opacos), como era
  no carregamento anterior. Pixel = $FFRRGGBB. }

type
  ELeitorBMP = class(Exception);

  TLeitorBMP = class(TPersistent)
  private
    FWidth, FHeight: Integer;
    FPix: array of Cardinal;
    FOnChange: TNotifyEvent;
    { @returns(True se a imagem nao tem pixels) }
    function GetEmpty: Boolean;
    { Avisa OnChange, se houver. }
    procedure Changed;
  public
    { Esvazia a imagem. }
    procedure Clear;
    { Muda o tamanho e pinta tudo de preto.
      @param(AWidth largura)
      @param(AHeight altura) }
    procedure SetSize(AWidth, AHeight: Integer);
    { Le um arquivo BMP.
      @param(FileName caminho do arquivo)
      @raises(Exception arquivo inexistente, corrompido ou num formato nao suportado) }
    procedure LoadFromFile(const FileName: string);
    { Le um BMP de 1, 4, 8, 16, 24 ou 32 bits (sem compressao, RLE4/RLE8 ou BITFIELDS, cabecalho
      OS/2 ou Windows) da posicao atual ate o fim do stream. O alfa de 32 bits e ignorado.
      @param(Stream origem)
      @raises(ELeitorBMP arquivo invalido ou formato nao suportado) }
    procedure LoadFromStream(Stream: TStream);
    { @param(Y linha (0 = topo; sem conferencia de faixa))
      @returns(o endereco do primeiro pixel da linha) }
    function ScanLine(Y: Integer): PCardinal;
    property Empty: Boolean read GetEmpty;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;


function TLeitorBMP.GetEmpty: Boolean;
begin
  Result := (FWidth = 0) or (FHeight = 0);
end;

procedure TLeitorBMP.Changed;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TLeitorBMP.Clear;
begin
  FWidth := 0;
  FHeight := 0;
  FPix := nil;
  Changed;
end;

procedure TLeitorBMP.SetSize(AWidth, AHeight: Integer);
begin
  if AWidth < 0 then AWidth := 0;
  if AHeight < 0 then AHeight := 0;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FPix, FWidth * FHeight);
  if Length(FPix) > 0 then FillDWord(FPix[0], Length(FPix), $FF000000);
end;

function TLeitorBMP.ScanLine(Y: Integer): PCardinal;
begin
  Result := @FPix[Y * FWidth];
end;

procedure TLeitorBMP.LoadFromFile(const FileName: string);
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

{ @param(P endereco)
  @returns(o word little-endian em P) }
function Le16(P: PByte): Integer; inline;
begin
  Result := P[0] or (P[1] shl 8);
end;

{ @param(P endereco)
  @returns(o inteiro de 32 bits little-endian em P) }
function Le32(P: PByte): Integer; inline;
begin
  Result := Integer(Cardinal(P[0]) or (Cardinal(P[1]) shl 8) or (Cardinal(P[2]) shl 16) or (Cardinal(P[3]) shl 24));
end;

{ Amplia um campo de mascara de bits (ex.: 5 bits do RGB565) para 0..255.
  @param(V pixel lido)
  @param(Mascara mascara do campo (0 = sempre 0))
  @returns(o componente em 8 bits) }
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

procedure TLeitorBMP.LoadFromStream(Stream: TStream);
var
  Dados: array of Byte;
  Tam, Off, HdrSize, W, H, Planes, Bpp, Comp, ClrUsed, I, X, Y, Stride, NPal, PalOff, PalSize: Integer;
  TopDown: Boolean;
  Pal: array[0..255] of Cardinal;
  MR, MG, MB: Cardinal;
  P: PByte;
  Linha: PCardinal;
  V: Cardinal;

  { @param(R vermelho)
    @param(G verde)
    @param(B azul)
    @returns(o pixel opaco $FFRRGGBB) }
  function Pix(R, G, B: Cardinal): Cardinal;
  begin
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
  end;

  { Descompacta os pixels RLE do BMP (de baixo para cima) usando a paleta.
    @param(Is4 True = RLE4; False = RLE8) }
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
  if Tam < 26 then raise ELeitorBMP.Create('BMP invalido (arquivo muito pequeno)');
  SetLength(Dados, Tam);
  Stream.ReadBuffer(Dados[0], Tam);
  if (Dados[0] <> Ord('B')) or (Dados[1] <> Ord('M')) then raise ELeitorBMP.Create('Nao e um arquivo BMP');
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
  else raise ELeitorBMP.Create('Cabecalho de BMP nao suportado');
  if Planes <> 1 then raise ELeitorBMP.Create('BMP com planos <> 1');
  TopDown := H < 0;
  if TopDown then H := -H;
  if (W <= 0) or (H <= 0) or (W > 16384) or (H > 16384) then raise ELeitorBMP.Create('Dimensoes de BMP invalidas');

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
      raise ELeitorBMP.Create('BMP truncado');
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
        raise ELeitorBMP.Create('Profundidade de cor de BMP nao suportada');
      end;
    end;
  end
  else raise ELeitorBMP.Create('Compressao de BMP nao suportada');
  Changed;
end;


{ ======================= utilitarios ======================= }

function CorParaPixel(C: TColor): Cardinal;
var
  RGB: Cardinal;
begin
  RGB := Cardinal(C);          // 0x00BBGGRR
  Result := $FF000000 or ((RGB and $FF) shl 16) or (RGB and $FF00) or ((RGB shr 16) and $FF);
end;

function PixelParaCor(P: Cardinal): TColor;
begin
  Result := TColor(((P shr 16) and $FF) or (P and $FF00) or ((P and $FF) shl 16));
end;

{ ---- cache de mascaras de texto ---- }

type
  TTextMask = class
  public
    W, H: Integer;
    Data: TMascara;
  end;

var
  GMaskCache: TStringList = nil;

{ @param(Tam tamanho da fonte)
  @param(S texto)
  @returns(a chave do cache de mascaras) }
function ChaveTexto(Tam: Integer; const S: string): string;
begin
  Result := IntToStr(Tam) + '|' + S;
end;

{ Mascara de um texto, guardada num cache (limpo ao passar de 600 textos).
  @param(Tam tamanho da fonte)
  @param(S texto em UTF-8)
  @returns(a mascara (o cache e o dono)) }
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
  FonteMascara(Tam, S, M.W, M.H, M.Data);
  GMaskCache.AddObject(Key, M);
  Result := M;
end;

{ ======================= TSuperficie ======================= }

constructor TSuperficie.Create;
begin
  inherited Create;
  FTransparentColor := Preto;
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
    Result := Preto
  else
    Result := PixelParaCor(FPix[Y * FWidth + X]);
end;

procedure TSuperficie.SetPixel(X, Y: Integer; Value: TColor);
begin
  if (X < 0) or (Y < 0) or (X >= FWidth) or (Y >= FHeight) then Exit;
  FPix[Y * FWidth + X] := CorParaPixel(Value);
end;

function TSuperficie.CarregarBMP(const Arquivo: string): Boolean;
var
  Pic: TLeitorBMP;
  Nome: string;
  Y: Integer;
begin
  Result := False;
  SetSize(0, 0);
  Nome := ResolverCaminho(Arquivo);
  if (Arquivo = '') or not FileExists(Nome) then Exit;
  Pic := TLeitorBMP.Create;
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
  Key := CorParaPixel(Image.FTransparentColor) and $FFFFFF;
  if Alpha < 0 then Alpha := 0;
  if Alpha > 255 then Alpha := 255;
  A := Alpha;
  IA := 255 - A;
  //Straight := (SW = ADW) and (not FlipX);

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
begin
  Result := False;
  if (Image = nil) or (Image.FWidth = 0) or (FWidth = 0) or (W = 0) or (H = 0) then Exit;
  SW := SrcRect.Right - SrcRect.Left;
  SH := SrcRect.Bottom - SrcRect.Top;
  if (SW <= 0) or (SH <= 0) then Exit;
  Key := CorParaPixel(Image.FTransparentColor) and $FFFFFF;
  if Alpha < 0 then Alpha := 0;
  if Alpha > 255 then Alpha := 255;
  A := Alpha; IA := 255 - A;
  Rad := (Angle mod 256) * 2 * Pi / 256;
  CosA := Cos(Rad);
  SinA := Sin(Rad);
  PX := X + W * CenterX;
  PY := Y + H * CenterY;
  // bounding box do retangulo rotacionado
  //CX := X; CY := Y;
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
  C := CorParaPixel(Cor);
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
  C := CorParaPixel(Cor);
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

  { Pinta um pixel, se estiver dentro da superficie.
    @param(PX coluna)
    @param(PY linha)
    @param(C pixel ARGB) }
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
  FC := CorParaPixel(CorFundo);
  PC := CorParaPixel(CorBorda);
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
  Result := FonteLargura(Tam, S);
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
  FCol := CorParaPixel(Cor);
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
  FTransparentColor := Branco;
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

procedure TImagem.DrawRotate(Surface: TSuperficie; X, Y, Width, Height,
  PatternIndex: Integer; CenterX, CenterY: Double; Angle: Integer);
begin
  if (PatternIndex < 0) or (PatternIndex >= Length(FPatterns)) then Exit;
  Surface.DrawRotate(X, Y, Width, Height, FPatterns[PatternIndex], FSurface,
    CenterX, CenterY, FTransparent, Angle);
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
  FonteCarregar(ResolverCaminho('Fontes/ComicSansMS.atlas'));   // gerado por tools/GeraFonte

finalization
  GMaskCache.Free;

end.
