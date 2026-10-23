unit DXFonte;

{ DXFonte.pas - texto a partir de um ATLAS de glifos pre-renderizados (sem fonte do sistema, sem LCL).

  O original desenhava com a fonte "Comic Sans MS" do Windows. Aqui cada letra, em cada um dos
  tamanhos usados pelo jogo, ja vem desenhada (cobertura de 8 bits) num arquivo gerado uma unica
  vez pela ferramenta tools/GeraFonte. O texto e montado somando as larguras de avanco, o mesmo
  que o GDI faz (sem kerning), entao o resultado e igual ao do original.

  Arquivo: 'CHFNT1' + dados compactados (zlib):
    nome da fonte (1 byte de tamanho + texto), numero de tamanhos (word) e, para cada tamanho:
    tamanho (word), altura da celula (word), numero de glifos (word) e por glifo:
    codigo Unicode (dword), avanco, xoff, yoff (smallint), largura, altura (word), cobertura (w*h bytes). }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, DXTipos;

type
  TDXGlifo = record
    Codigo: Cardinal;
    Avanco, XOff, YOff, W, H: Integer;
    Dados: TDXMascara;
  end;

{ leitura }
function DXFonteCarregar(const Arquivo: string): Boolean;
function DXFonteDisponivel: Boolean;
{ True se o atlas carregado e da fonte pedida (comparacao sem diferenciar maiusculas) }
function DXFonteServe(const NomeFonte: string): Boolean;
procedure DXFonteMascara(Tam: Integer; const S: string; out W, H: Integer; out Dados: TDXMascara);
function DXFonteLargura(Tam: Integer; const S: string): Integer;
function DXFonteAltura(Tam: Integer): Integer;

{ gravacao (usada so pela ferramenta GeraFonte) }
procedure DXFonteIniciar(const NomeFonte: string);
procedure DXFonteAdicionar(Tam, AlturaCelula: Integer; const G: TDXGlifo);
procedure DXFonteSalvar(const Arquivo: string);

implementation

uses
  zstream;

type
  TTamanho = record
    Tam, Altura: Integer;
    Glifos: array of TDXGlifo;      // ordenados por Codigo
  end;

var
  GNome: string = '';
  GTam: array of TTamanho;

function DXFonteDisponivel: Boolean;
begin
  Result := Length(GTam) > 0;
end;

function DXFonteServe(const NomeFonte: string): Boolean;
begin
  Result := (Length(GTam) > 0) and SameText(NomeFonte, GNome);
end;

function AcharTamanho(Tam: Integer): Integer;
var
  I, Melhor, D, DMelhor: Integer;
begin
  Result := -1;
  DMelhor := MaxInt;
  Melhor := -1;
  for I := 0 to High(GTam) do
  begin
    D := Abs(GTam[I].Tam - Tam);
    if D < DMelhor then
    begin
      DMelhor := D;
      Melhor := I;
    end;
  end;
  Result := Melhor;        // tamanho exato, ou o mais proximo
end;

function AcharGlifo(const T: TTamanho; Codigo: Cardinal): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := High(T.Glifos);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if T.Glifos[Mid].Codigo = Codigo then Exit(Mid);
    if T.Glifos[Mid].Codigo < Codigo then Lo := Mid + 1 else Hi := Mid - 1;
  end;
  Result := -1;
end;

{ proximo codigo Unicode de uma string UTF-8 (byte invalido vale como Latin-1) }
function ProximoCodigo(const S: string; var I: Integer): Cardinal;
var
  B: Byte;
  N, K: Integer;
  C: Cardinal;
begin
  B := Byte(S[I]);
  Inc(I);
  if B < $80 then Exit(B);
  if (B and $E0) = $C0 then begin N := 1; C := B and $1F; end
  else if (B and $F0) = $E0 then begin N := 2; C := B and $0F; end
  else if (B and $F8) = $F0 then begin N := 3; C := B and $07; end
  else Exit(B);
  for K := 1 to N do
  begin
    if (I > Length(S)) or ((Byte(S[I]) and $C0) <> $80) then Exit(B);
    C := (C shl 6) or (Byte(S[I]) and $3F);
    Inc(I);
  end;
  Result := C;
end;

function GlifoDe(const T: TTamanho; Codigo: Cardinal): Integer;
begin
  Result := AcharGlifo(T, Codigo);
  if Result < 0 then Result := AcharGlifo(T, Ord('?'));
end;

function DXFonteAltura(Tam: Integer): Integer;
var
  K: Integer;
begin
  K := AcharTamanho(Tam);
  if K < 0 then Exit(0);
  Result := GTam[K].Altura;
end;

function DXFonteLargura(Tam: Integer; const S: string): Integer;
var
  K, I, G: Integer;
begin
  Result := 0;
  K := AcharTamanho(Tam);
  if K < 0 then Exit;
  I := 1;
  while I <= Length(S) do
  begin
    G := GlifoDe(GTam[K], ProximoCodigo(S, I));
    if G >= 0 then Inc(Result, GTam[K].Glifos[G].Avanco);
  end;
end;

procedure DXFonteMascara(Tam: Integer; const S: string; out W, H: Integer; out Dados: TDXMascara);
var
  K, I, G, Pen, X, Y, TX, TY: Integer;
  P: ^TDXGlifo;
  V: Byte;
begin
  Dados := nil;
  W := 1;
  H := 1;
  K := AcharTamanho(Tam);
  if K < 0 then
  begin
    SetLength(Dados, 1);
    Exit;
  end;
  W := DXFonteLargura(Tam, S);
  if W < 1 then W := 1;
  H := GTam[K].Altura;
  if H < 1 then H := 1;
  SetLength(Dados, W * H);
  FillChar(Dados[0], W * H, 0);
  Pen := 0;
  I := 1;
  while I <= Length(S) do
  begin
    G := GlifoDe(GTam[K], ProximoCodigo(S, I));
    if G < 0 then Continue;
    P := @GTam[K].Glifos[G];
    for Y := 0 to P.H - 1 do
    begin
      TY := P.YOff + Y;
      if (TY < 0) or (TY >= H) then Continue;
      for X := 0 to P.W - 1 do
      begin
        TX := Pen + P.XOff + X;
        if (TX < 0) or (TX >= W) then Continue;
        V := P.Dados[Y * P.W + X];
        if V > Dados[TY * W + TX] then Dados[TY * W + TX] := V;
      end;
    end;
    Inc(Pen, P.Avanco);
  end;
end;

{ ---- arquivo ---- }

function DXFonteCarregar(const Arquivo: string): Boolean;
var
  F: TFileStream;
  Magic: array[0..5] of AnsiChar;
  D: TDecompressionStream;
  M: TMemoryStream;
  NTam, NGl, T, K, L, N: Integer;
  Buf: array[0..65535] of Byte;
  Nome: AnsiString;
  G: ^TDXGlifo;
begin
  Result := False;
  GTam := nil;
  GNome := '';
  if not FileExists(Arquivo) then Exit;
  try
    F := TFileStream.Create(Arquivo, fmOpenRead or fmShareDenyWrite);
    try
      F.ReadBuffer(Magic, 6);
      if CompareByte(Magic[0], 'CHFNT1'[1], 6) <> 0 then Exit;
      M := TMemoryStream.Create;
      D := TDecompressionStream.Create(F);
      try
        repeat
          N := D.Read(Buf, SizeOf(Buf));
          if N > 0 then M.WriteBuffer(Buf, N);
        until N <= 0;
      finally
        D.Free;
      end;
    finally
      F.Free;
    end;
    try
      M.Position := 0;
      L := M.ReadByte;
      SetLength(Nome, L);
      if L > 0 then M.ReadBuffer(Nome[1], L);
      GNome := string(Nome);
      NTam := M.ReadWord;
      SetLength(GTam, NTam);
      for T := 0 to NTam - 1 do
      begin
        GTam[T].Tam := M.ReadWord;
        GTam[T].Altura := M.ReadWord;
        NGl := M.ReadWord;
        SetLength(GTam[T].Glifos, NGl);
        for K := 0 to NGl - 1 do
        begin
          G := @GTam[T].Glifos[K];
          G.Codigo := M.ReadDWord;
          G.Avanco := SmallInt(M.ReadWord);
          G.XOff := SmallInt(M.ReadWord);
          G.YOff := SmallInt(M.ReadWord);
          G.W := M.ReadWord;
          G.H := M.ReadWord;
          SetLength(G.Dados, G.W * G.H);
          if Length(G.Dados) > 0 then M.ReadBuffer(G.Dados[0], Length(G.Dados));
        end;
      end;
    finally
      M.Free;
    end;
    Result := Length(GTam) > 0;
  except
    GTam := nil;
    GNome := '';
    Result := False;
  end;
end;

procedure DXFonteIniciar(const NomeFonte: string);
begin
  GNome := NomeFonte;
  GTam := nil;
end;

procedure DXFonteAdicionar(Tam, AlturaCelula: Integer; const G: TDXGlifo);
var
  K, N: Integer;
begin
  K := -1;
  for N := 0 to High(GTam) do
    if GTam[N].Tam = Tam then K := N;
  if K < 0 then
  begin
    K := Length(GTam);
    SetLength(GTam, K + 1);
    GTam[K].Tam := Tam;
    GTam[K].Altura := AlturaCelula;
  end;
  N := Length(GTam[K].Glifos);
  SetLength(GTam[K].Glifos, N + 1);
  GTam[K].Glifos[N] := G;
end;

procedure DXFonteSalvar(const Arquivo: string);
var
  F: TFileStream;
  M: TMemoryStream;
  C: TCompressionStream;
  T, K, I, J: Integer;
  Tmp: TDXGlifo;
  Nome: AnsiString;
  G: ^TDXGlifo;
begin
  M := TMemoryStream.Create;
  try
    Nome := AnsiString(GNome);
    M.WriteByte(Length(Nome));
    if Length(Nome) > 0 then M.WriteBuffer(Nome[1], Length(Nome));
    M.WriteWord(Length(GTam));
    for T := 0 to High(GTam) do
    begin
      { ordena os glifos por codigo (para a busca binaria) }
      for I := 1 to High(GTam[T].Glifos) do
      begin
        Tmp := GTam[T].Glifos[I];
        J := I - 1;
        while (J >= 0) and (GTam[T].Glifos[J].Codigo > Tmp.Codigo) do
        begin
          GTam[T].Glifos[J + 1] := GTam[T].Glifos[J];
          Dec(J);
        end;
        GTam[T].Glifos[J + 1] := Tmp;
      end;
      M.WriteWord(GTam[T].Tam);
      M.WriteWord(GTam[T].Altura);
      M.WriteWord(Length(GTam[T].Glifos));
      for K := 0 to High(GTam[T].Glifos) do
      begin
        G := @GTam[T].Glifos[K];
        M.WriteDWord(G.Codigo);
        M.WriteWord(Word(SmallInt(G.Avanco)));
        M.WriteWord(Word(SmallInt(G.XOff)));
        M.WriteWord(Word(SmallInt(G.YOff)));
        M.WriteWord(G.W);
        M.WriteWord(G.H);
        if Length(G.Dados) > 0 then M.WriteBuffer(G.Dados[0], Length(G.Dados));
      end;
    end;
    ForceDirectories(ExtractFilePath(ExpandFileName(Arquivo)));
    F := TFileStream.Create(Arquivo, fmCreate);
    try
      F.WriteBuffer('CHFNT1', 6);
      C := TCompressionStream.Create(clmax, F);
      try
        M.Position := 0;
        C.CopyFrom(M, M.Size);
      finally
        C.Free;
      end;
    finally
      F.Free;
    end;
  finally
    M.Free;
  end;
end;

end.
