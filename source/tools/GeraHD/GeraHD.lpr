program GeraHD;

{ GeraHD - gera as imagens em alta resolucao do jogo (pasta HD/) a partir dos BMP originais.

  Uso (na pasta do jogo, ou de qualquer lugar: a pasta do jogo e a que tem o Chaves.exe):
    GeraHD.exe [opcoes] [pastas ou arquivos .bmp]
  Sem pastas, processa Lutadores, Efeitos, Animacoes, Rostos, Embutidos e Cenarios.
  Opcoes:
    --filtro=lanczos   filtro da ampliacao: lanczos (padrao, mais nitido), bicubico (mais macio)
                       ou vizinho (pixels repetidos, igual ao jogo sem HD)
    --refazer          regrava os PNG que ja existem (sem ela, um PNG existente, talvez retocado
                       a mao, e mantido)

  Para cada Pasta/Nome.bmp grava HD/Pasta/Nome.png, exatamente EscalaTela (3) vezes maior:
  - imagens desenhadas com transparencia: o branco puro vira alfa 0 e a ampliacao e feita com
    alfa pre-multiplicado (sem franja branca); a borda do alfa e reforcada para ficar nitida;
  - imagens opacas (Cenarios e as marcadas com ",0" em Dados/Recursos.ini): sem alfa;
  - folhas de lutadores (Lutadores): cada quadro (entre as colunas separadoras escuras, como o
    jogo as procura) e ampliado sozinho, e as colunas separadoras sao so repetidas, para nada
    vazar de um quadro para o outro. O jogo continua achando os cortes na folha original.
  O relatorio vai para GeraHD.log. }

{$mode delphi}{$H+}
{$POINTERMATH ON}
{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, Math, FPImage, FPWritePNG, ChavesConst, ChavesGfx, ChavesDados;

type
  TFiltro = (fLanczos, fBicubico, fVizinho);

  { imagem em ponto flutuante, alfa pre-multiplicado (R, G e B ja multiplicados por A) }
  TImagemF = record
    W, H: Integer;
    R, G, B, A: array of Single;
  end;

const
  PastasPadrao: array[0..5] of string = ('Lutadores', 'Efeitos', 'Animacoes', 'Rostos', 'Embutidos',
    'Cenarios');
  { reforco da borda do alfa: (alfa - 0.5) * Contraste + 0.5 }
  ContrasteAlfa = 2.0;
  NomesFiltro: array[TFiltro] of string = ('lanczos', 'bicubico', 'vizinho');

var
  Log: TStringList;
  Raiz: string;
  Filtro: TFiltro = fLanczos;
  Refazer: Boolean = False;
  Opacos: TStringList;          // caminhos (relativos, minusculos, com /) das imagens opacas
  Gerados, Mantidos, Falhas: Integer;

{ Mostra uma linha no console e guarda no relatorio.
  @param(S a linha) }
procedure Escreve(const S: string);
begin
  WriteLn(S);
  Log.Add(S);
end;

{ @returns(a pasta do jogo (a que tem o Chaves.exe, subindo a partir do executavel e da pasta
  atual); sem achar, a pasta atual) }
function AcharRaiz: string;
var
  Dir: string;
  I, K: Integer;
begin
  for K := 0 to 1 do
  begin
    if K = 0 then Dir := IncludeTrailingPathDelimiter(GetCurrentDir)
    else Dir := ExtractFilePath(ParamStr(0));
    for I := 1 to 8 do
    begin
      if FileExists(Dir + 'Chaves.exe') then Exit(Dir);
      Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
      if Dir = '' then Break;
    end;
  end;
  Result := IncludeTrailingPathDelimiter(GetCurrentDir);
end;

{ @param(Caminho caminho relativo a pasta do jogo)
  @returns(o caminho normalizado para comparar: minusculo, com /) }
function Chave(const Caminho: string): string;
begin
  Result := LowerCase(StringReplace(Caminho, '\', '/', [rfReplaceAll]));
end;

{ Le de Dados/Recursos.ini as imagens marcadas como opacas (Nome=arquivo,0). }
procedure LerOpacos;
var
  L: TStringList;
  I, P: Integer;
  S, Valor: string;
begin
  L := TStringList.Create;
  try
    if FileExists(Raiz + 'Dados' + PathDelim + 'Recursos.ini') then
      L.LoadFromFile(Raiz + 'Dados' + PathDelim + 'Recursos.ini');
    for I := 0 to L.Count - 1 do
    begin
      S := Trim(L[I]);
      if (S = '') or (S[1] = ';') then Continue;
      P := Pos('=', S);
      if P = 0 then Continue;
      Valor := Trim(Copy(S, P + 1, MaxInt));
      P := LastDelimiter(',', Valor);
      if (P > 0) and (Trim(Copy(Valor, P + 1, MaxInt)) = '0') then
        Opacos.Add(Chave(Trim(Copy(Valor, 1, P - 1))));
    end;
  finally
    L.Free;
  end;
end;

{ ---- filtros ---- }

{ @param(X distancia ao centro do pixel de origem)
  @returns(o peso do filtro) }
function Peso(X: Single): Single;
const
  A = -0.5;     // Catmull-Rom
begin
  X := Abs(X);
  case Filtro of
    fLanczos:
      if X < 1e-6 then Result := 1
      else if X < 3 then Result := 3 * Sin(Pi * X) * Sin(Pi * X / 3) / (Pi * Pi * X * X)
      else Result := 0;
  else
    if X < 1 then Result := (A + 2) * X * X * X - (A + 3) * X * X + 1
    else if X < 2 then Result := A * X * X * X - 5 * A * X * X + 8 * A * X - 4 * A
    else Result := 0;
  end;
end;

{ @returns(o raio do filtro em pixels de origem) }
function Raio: Integer;
begin
  if Filtro = fLanczos then Result := 3 else Result := 2;
end;

{ Amplia uma linha (ou coluna) de N amostras para N * Escala, com o filtro escolhido e as
  bordas repetidas.
  @param(Src amostras de origem (Passo entre elas))
  @param(N quantas amostras)
  @param(Dst destino (Passo entre elas))
  @param(Escala fator de ampliacao) }
procedure Ampliar1D(Src: PSingle; PassoSrc, N: Integer; Dst: PSingle; PassoDst, Escala: Integer);
var
  O, Q, F, K, Idx, NP: Integer;
  C, Soma, SomaP: Single;
  { os pesos so dependem da fase (O mod Escala): Desl[F] = primeira amostra (relativa a
    O div Escala) e Pesos[F] = pesos normalizados das 2 * Raio amostras }
  Desl: array of Integer;
  Pesos: array of array of Single;
begin
  if Filtro = fVizinho then
  begin
    for O := 0 to N * Escala - 1 do
      Dst[O * PassoDst] := Src[(O div Escala) * PassoSrc];
    Exit;
  end;
  NP := 2 * Raio;
  SetLength(Desl, Escala);
  SetLength(Pesos, Escala, NP);
  for F := 0 to Escala - 1 do
  begin
    C := (F + 0.5) / Escala - 0.5;          // centro na origem, relativo a O div Escala
    Desl[F] := Floor(C) - Raio + 1;
    SomaP := 0;
    for K := 0 to NP - 1 do
    begin
      Pesos[F][K] := Peso(C - (Desl[F] + K));
      SomaP := SomaP + Pesos[F][K];
    end;
    if SomaP <> 0 then
      for K := 0 to NP - 1 do Pesos[F][K] := Pesos[F][K] / SomaP;
  end;
  for O := 0 to N * Escala - 1 do
  begin
    Q := O div Escala;
    F := O mod Escala;
    Soma := 0;
    for K := 0 to NP - 1 do
    begin
      Idx := EnsureRange(Q + Desl[F] + K, 0, N - 1);
      Soma := Soma + Src[Idx * PassoSrc] * Pesos[F][K];
    end;
    Dst[O * PassoDst] := Soma;
  end;
end;

{ Amplia um canal inteiro (primeiro as linhas, depois as colunas).
  @param(Src canal W x H)
  @param(W largura)
  @param(H altura)
  @param(Escala fator)
  @param(Dst recebe o canal (W * Escala) x (H * Escala)) }
procedure AmpliarCanal(const Src: array of Single; W, H, Escala: Integer; var Dst: array of Single);
var
  Tmp: array of Single;
  Y, X, W2: Integer;
begin
  W2 := W * Escala;
  SetLength(Tmp, W2 * H);
  for Y := 0 to H - 1 do
    Ampliar1D(@Src[Y * W], 1, W, @Tmp[Y * W2], 1, Escala);
  for X := 0 to W2 - 1 do
    Ampliar1D(@Tmp[X], W2, H, @Dst[X], W2, Escala);
end;

{ Amplia uma imagem com alfa pre-multiplicado.
  @param(Src imagem de origem)
  @param(Escala fator)
  @returns(a imagem ampliada (ainda pre-multiplicada)) }
function AmpliarImagem(const Src: TImagemF; Escala: Integer): TImagemF;
var
  N: Integer;
begin
  Result.W := Src.W * Escala;
  Result.H := Src.H * Escala;
  N := Result.W * Result.H;
  SetLength(Result.R, N);
  SetLength(Result.G, N);
  SetLength(Result.B, N);
  SetLength(Result.A, N);
  AmpliarCanal(Src.R, Src.W, Src.H, Escala, Result.R);
  AmpliarCanal(Src.G, Src.W, Src.H, Escala, Result.G);
  AmpliarCanal(Src.B, Src.W, Src.H, Escala, Result.B);
  AmpliarCanal(Src.A, Src.W, Src.H, Escala, Result.A);
end;

{ ---- uma imagem ---- }

{ @param(P pixel ARGB)
  @returns(True se R, G e B sao todos <= 100 (coluna separadora de quadros, como no jogo)) }
function Escuro(P: Cardinal): Boolean;
begin
  Result := ((P and $FF) <= 100) and (((P shr 8) and $FF) <= 100) and (((P shr 16) and $FF) <= 100);
end;

{ Converte as colunas [X0, X1) da superficie em imagem pre-multiplicada.
  @param(Sup superficie (escala 1))
  @param(X0 primeira coluna)
  @param(X1 coluna final (exclusiva))
  @param(Transparente True = branco puro vira alfa 0)
  @returns(a imagem) }
function Extrair(Sup: TSuperficie; X0, X1: Integer; Transparente: Boolean): TImagemF;
var
  X, Y, I: Integer;
  P: Cardinal;
  A: Single;
begin
  Result.W := X1 - X0;
  Result.H := Sup.AlturaFisica;
  SetLength(Result.R, Result.W * Result.H);
  SetLength(Result.G, Result.W * Result.H);
  SetLength(Result.B, Result.W * Result.H);
  SetLength(Result.A, Result.W * Result.H);
  for Y := 0 to Result.H - 1 do
    for X := 0 to Result.W - 1 do
    begin
      P := Sup.ScanLine(Y)[X0 + X];
      if Transparente and ((P and $FFFFFF) = $FFFFFF) then A := 0 else A := 1;
      I := Y * Result.W + X;
      Result.R[I] := ((P shr 16) and $FF) * A;
      Result.G[I] := ((P shr 8) and $FF) * A;
      Result.B[I] := (P and $FF) * A;
      Result.A[I] := A;
    end;
end;

{ Escreve uma imagem ampliada (pre-multiplicada) na imagem de saida, a partir da coluna X0.
  @param(Img imagem ampliada)
  @param(Saida imagem PNG de saida)
  @param(X0 primeira coluna na saida)
  @param(Transparente True = reforca a borda do alfa; False = opaca) }
procedure Colar(const Img: TImagemF; Saida: TFPMemoryImage; X0: Integer; Transparente: Boolean);
var
  X, Y, I: Integer;
  A, R, G, B: Single;
  C: TFPColor;
begin
  for Y := 0 to Img.H - 1 do
    for X := 0 to Img.W - 1 do
    begin
      I := Y * Img.W + X;
      A := Img.A[I];
      if A > 1e-4 then
      begin
        R := Img.R[I] / A;
        G := Img.G[I] / A;
        B := Img.B[I] / A;
      end
      else
      begin
        R := 0; G := 0; B := 0;
      end;
      if Transparente then
      begin
        if Filtro <> fVizinho then A := (A - 0.5) * ContrasteAlfa + 0.5;
        A := EnsureRange(A, 0, 1);
      end
      else
        A := 1;
      C.Red := Round(EnsureRange(R, 0, 255)) * 257;
      C.Green := Round(EnsureRange(G, 0, 255)) * 257;
      C.Blue := Round(EnsureRange(B, 0, 255)) * 257;
      C.Alpha := Round(A * 255) * 257;
      Saida.Colors[X0 + X, Y] := C;
    end;
end;

{ Gera o PNG em alta resolucao de um BMP.
  @param(Relativo caminho do BMP relativo a pasta do jogo) }
procedure Processar(const Relativo: string);
var
  Sup: TSuperficie;
  Saida: TFPMemoryImage;
  Escritor: TFPWriterPNG;
  Destino, Pasta: string;
  Transparente, Folha: Boolean;
  W, H, X, Y, K, Ini, Quadros: Integer;
  P: Cardinal;
  C: TFPColor;
  Img: TImagemF;
begin
  Destino := Raiz + 'HD' + PathDelim + ChangeFileExt(SetDirSeparators(Relativo), '.png');
  if FileExists(Destino) and not Refazer then
  begin
    Inc(Mantidos);
    Exit;
  end;
  Pasta := LowerCase(ExtractFileDir(Chave(Relativo)));
  Transparente := (Pasta <> 'cenarios') and (Opacos.IndexOf(Chave(Relativo)) < 0);
  Folha := Pasta = 'lutadores';

  Sup := TSuperficie.Create;
  Saida := nil;
  try
    if not Sup.CarregarBMP(Raiz + Relativo, False) then
    begin
      Escreve('  ERRO: nao consegui ler ' + Relativo);
      Inc(Falhas);
      Exit;
    end;
    W := Sup.LarguraFisica;
    H := Sup.AlturaFisica;
    Saida := TFPMemoryImage.Create(W * EscalaTela, H * EscalaTela);
    Saida.UsePalette := False;
    Quadros := 0;
    if Folha then
    begin
      { cada quadro sozinho; as colunas separadoras sao so repetidas (opacas) }
      Ini := 0;
      for X := 0 to W do
        if (X = W) or (Escuro(Sup.ScanLine(0)[X]) and Escuro(Sup.ScanLine(H - 1)[X])) then
        begin
          if X > Ini then
          begin
            Img := AmpliarImagem(Extrair(Sup, Ini, X, Transparente), EscalaTela);
            Colar(Img, Saida, Ini * EscalaTela, Transparente);
            Inc(Quadros);
          end;
          if X < W then
            for Y := 0 to H * EscalaTela - 1 do
            begin
              P := Sup.ScanLine(Y div EscalaTela)[X];
              C.Red := ((P shr 16) and $FF) * 257;
              C.Green := ((P shr 8) and $FF) * 257;
              C.Blue := (P and $FF) * 257;
              C.Alpha := $FFFF;
              for K := X * EscalaTela to X * EscalaTela + EscalaTela - 1 do
                Saida.Colors[K, Y] := C;
            end;
          Ini := X + 1;
        end;
    end
    else
    begin
      Img := AmpliarImagem(Extrair(Sup, 0, W, Transparente), EscalaTela);
      Colar(Img, Saida, 0, Transparente);
    end;

    ForceDirectories(ExtractFileDir(Destino));
    Escritor := TFPWriterPNG.Create;
    try
      Escritor.UseAlpha := Transparente;
      Escritor.WordSized := False;
      Escritor.Indexed := False;
      Saida.SaveToFile(Destino, Escritor);
    finally
      Escritor.Free;
    end;
    Inc(Gerados);
    if Folha then
      Escreve(Format('  %s -> %dx%d (%d quadros)', [Relativo, W * EscalaTela, H * EscalaTela, Quadros]))
    else if Transparente then
      Escreve(Format('  %s -> %dx%d', [Relativo, W * EscalaTela, H * EscalaTela]))
    else
      Escreve(Format('  %s -> %dx%d (opaca)', [Relativo, W * EscalaTela, H * EscalaTela]));
  finally
    Saida.Free;
    Sup.Free;
  end;
end;

{ Processa todos os .bmp de uma pasta (relativa a pasta do jogo).
  @param(Pasta nome da pasta) }
procedure ProcessarPasta(const Pasta: string);
var
  SR: TSearchRec;
  Nomes: TStringList;
  I: Integer;
begin
  Nomes := TStringList.Create;
  try
    if FindFirst(Raiz + Pasta + PathDelim + '*.bmp', faAnyFile, SR) = 0 then
    try
      repeat
        Nomes.Add(SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    Nomes.Sort;
    Escreve(Format('%s: %d imagens', [Pasta, Nomes.Count]));
    for I := 0 to Nomes.Count - 1 do
      Processar(Pasta + '/' + Nomes[I]);
  finally
    Nomes.Free;
  end;
end;

var
  I: Integer;
  Arg: string;
  Alvos: TStringList;
  Inicio: TDateTime;
begin
  Log := TStringList.Create;
  Opacos := TStringList.Create;
  Alvos := TStringList.Create;
  try
    Raiz := AcharRaiz;
    for I := 1 to ParamCount do
    begin
      Arg := ParamStr(I);
      if SameText(Arg, '--refazer') then Refazer := True
      else if SameText(Arg, '--filtro=lanczos') then Filtro := fLanczos
      else if SameText(Arg, '--filtro=bicubico') then Filtro := fBicubico
      else if SameText(Arg, '--filtro=vizinho') then Filtro := fVizinho
      else if Copy(Arg, 1, 2) = '--' then
      begin
        WriteLn('Opcao desconhecida: ', Arg);
        Halt(1);
      end
      else
        Alvos.Add(ExcludeTrailingPathDelimiter(StringReplace(Arg, '\', '/', [rfReplaceAll])));
    end;
    if Alvos.Count = 0 then
      for I := 0 to High(PastasPadrao) do Alvos.Add(PastasPadrao[I]);

    Escreve(Format('GeraHD - imagens %dx em HD/ (filtro %s)', [EscalaTela, NomesFiltro[Filtro]]));
    if Refazer then Escreve('Refazendo os PNG que ja existem.');
    Escreve('Pasta do jogo: ' + Raiz);
    LerOpacos;
    Inicio := Now;
    for I := 0 to Alvos.Count - 1 do
      if SameText(ExtractFileExt(Alvos[I]), '.bmp') then Processar(Alvos[I])
      else if DirectoryExists(Raiz + Alvos[I]) then ProcessarPasta(Alvos[I])
      else Escreve('  ERRO: pasta ou arquivo nao encontrado: ' + Alvos[I]);
    Escreve(Format('Fim: %d gerados, %d mantidos (ja existiam), %d com erro, em %.1f s',
      [Gerados, Mantidos, Falhas, (Now - Inicio) * 86400]));
    Log.SaveToFile(Raiz + 'GeraHD.log');
  finally
    Alvos.Free;
    Opacos.Free;
    Log.Free;
  end;
  if Falhas > 0 then Halt(2);
end.
