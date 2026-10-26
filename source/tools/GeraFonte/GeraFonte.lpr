program GeraFonte;

{ GeraFonte - gera os atlas de glifos da fonte do jogo.

  Rode no Windows:
    GeraFonte.exe              Fontes/ComicSansMS.atlas (desenho 1x; precisa da Comic Sans MS
                               instalada, a mesma do jogo original)
    GeraFonte.exe --hd [regular]  Fontes/ComicNeue-3x.atlas (desenho em EscalaTela = 3) com a Comic Neue
                               (licenca OFL) de Fontes/ComicNeue/, sem precisar instala-la, em negrito
                               (o peso mais parecido com o da Comic Sans MS); regular = peso normal

  Ele desenha cada letra, em cada tamanho usado pelo jogo, com o proprio GDI/LCL (o mesmo
  caminho que o jogo usava), grava o atlas na raiz do jogo (pasta que tem o Chaves.exe) e
  confere o resultado: para todos os textos do jogo, compara o texto desenhado pelo sistema
  com o montado pelo atlas e escreve o relatorio em GeraFonte.log.

  No atlas 3x cada tamanho Tam do jogo vira o tamanho Tam * 3. Para nao mudar a diagramacao feita
  para a Comic Sans, a altura da Comic Neue em cada tamanho e escolhida para que a largura dos
  textos do jogo fique o mais perto possivel da largura da Comic Sans 3x, e os glifos sao
  deslocados para que a linha de base e a altura da celula sejam as da Comic Sans 3x (sem a
  Comic Sans instalada, usa o tamanho nominal e as medidas da propria Comic Neue).

  Esta e a unica ferramenta do projeto que usa a LCL; o jogo (StreetChaves) nao usa. }

{$mode delphi}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Windows, Classes, SysUtils, Math, ChavesFonte, DXTexto, ChavesTextos;

const
  FonteOriginal = 'Comic Sans MS';
  FonteHD = 'Comic Neue';
  EscalaHD = 3;
  FR_PRIVATE = $10;
  { tamanhos de fonte usados pelo jogo (chamadas de texto(...) com Tam fixo) }
  Tamanhos: array[0..20] of Integer = (7, 8, 9, 10, 11, 12, 14, 15, 16, 18, 20, 22, 25, 26, 27, 28,
    29, 35, 36, 70, 120);

type
  { como gerar um tamanho do atlas }
  TPlanoTamanho = record
    TamAtlas: Integer;     // chave no atlas (tamanho do jogo x escala)
    Tamanho: Integer;      // tamanho pedido ao sistema (negativo = altura em pixels)
    DY: Integer;           // deslocamento vertical dos glifos (alinha a linha de base)
    Altura: Integer;       // altura da celula
  end;

function AddFontResourceExW(Nome: PWideChar; Flags: DWORD; Reservado: Pointer): Integer; stdcall;
  external 'gdi32.dll';

var
  Log: TStringList;
  Raiz, Arquivo, NomeFonte: string;
  Estilo, Escala: Integer;
  Planos: array of TPlanoTamanho;

{ Mostra uma linha no console e guarda no relatorio (GeraFonte.log).
  @param(S a linha) }
procedure Escreve(const S: string);
begin
  WriteLn(S);
  Log.Add(S);
end;

{ Grava o relatorio e encerra com erro.
  @param(Msg a mensagem de erro)
  @param(Codigo codigo de saida) }
procedure Falha(const Msg: string; Codigo: Integer);
begin
  Escreve('ERRO: ' + Msg);
  Log.SaveToFile(Raiz + 'GeraFonte.log');
  Halt(Codigo);
end;

{ @returns(a pasta do jogo (a que tem o Chaves.exe, subindo ate 8 niveis a partir do executavel);
  sem achar, a pasta do executavel) }
function AcharRaiz: string;
var
  Dir: string;
  I: Integer;
begin
  Dir := ExtractFilePath(ParamStr(0));
  for I := 1 to 8 do
  begin
    if FileExists(Dir + 'Chaves.exe') then Exit(Dir);
    Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
    if Dir = '' then Break;
  end;
  Result := ExtractFilePath(ParamStr(0));
end;

{ @param(Fonte nome da fonte)
  @returns(True se o Windows tem a fonte (senao ele troca por outra e as larguras coincidem)) }
function FonteExiste(const Fonte: string): Boolean;
begin
  Result := DXTextoLargura(Fonte, 20, 0, 'Wiiiimmmm AaBbQq') <>
    DXTextoLargura('ZzFonteQueNaoExiste', 20, 0, 'Wiiiimmmm AaBbQq');
end;

{ Carrega (so para este processo) os .ttf de uma pasta.
  @param(Pasta pasta com os arquivos .ttf)
  @returns(quantos arquivos foram carregados) }
function CarregarTTFs(const Pasta: string): Integer;
var
  SR: TSearchRec;
begin
  Result := 0;
  if FindFirst(Pasta + '*.ttf', faAnyFile, SR) = 0 then
  try
    repeat
      if AddFontResourceExW(PWideChar(UnicodeString(Pasta + SR.Name)), FR_PRIVATE, nil) > 0 then
        Inc(Result);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

{ @param(Codigo codigo Unicode (ate $FFFF))
  @returns(o caractere em UTF-8) }
function Utf8De(Codigo: Cardinal): string;
begin
  Result := UTF8Encode(UnicodeString(WideChar(Codigo)));
end;

{ @param(Fonte nome da fonte)
  @param(Tamanho tamanho (negativo = altura em pixels))
  @param(Textos textos do jogo)
  @returns(a soma das larguras dos textos) }
function SomaLarguras(const Fonte: string; Tamanho: Integer; Textos: TStringList): Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Textos.Count - 1 do
    Inc(Result, DXTextoLargura(Fonte, Tamanho, Estilo, Textos[I]));
end;

{ Monta os planos: 1x (fonte original, tamanhos do jogo) ou 3x (Comic Neue com a altura que
  mais se aproxima da largura da Comic Sans 3x, alinhada pela linha de base dela).
  @param(Textos textos do jogo (para medir as larguras)) }
procedure MontarPlanos(Textos: TStringList);
var
  T, H, Nominal, Melhor, Lo, Hi: Integer;
  Alvo, Soma, DMelhor: Int64;
  Referencia: Boolean;
  P: ^TPlanoTamanho;
begin
  SetLength(Planos, Length(Tamanhos));
  Referencia := (Escala > 1) and FonteExiste(FonteOriginal);
  if (Escala > 1) and not Referencia then
    Escreve('Aviso: sem a ' + FonteOriginal + ' instalada, uso o tamanho nominal da ' + NomeFonte + '.');
  for T := 0 to High(Tamanhos) do
  begin
    P := @Planos[T];
    P.TamAtlas := Tamanhos[T] * Escala;
    P.DY := 0;
    if Escala = 1 then
    begin
      P.Tamanho := Tamanhos[T];
      P.Altura := DXTextoAltura(NomeFonte, P.Tamanho, Estilo, 'Hg');
      Continue;
    end;
    { altura em pixels de um tamanho em pontos a 96 dpi }
    Nominal := Round(P.TamAtlas * 96 / 72);
    Melhor := Nominal;
    if Referencia then
    begin
      Alvo := 0;
      for H := 0 to Textos.Count - 1 do
        Inc(Alvo, DXTextoLargura(FonteOriginal, P.TamAtlas, 0, Textos[H]));
      { a largura cresce com a altura: busca binaria do primeiro H com Soma >= Alvo e
        escolhe entre ele e o anterior }
      Lo := Round(Nominal * 0.6);
      Hi := Round(Nominal * 1.6);
      while Lo < Hi do
      begin
        H := (Lo + Hi) div 2;
        if SomaLarguras(NomeFonte, -H, Textos) >= Alvo then Hi := H else Lo := H + 1;
      end;
      DMelhor := High(Int64);
      for H := Lo - 1 to Lo do
      begin
        Soma := SomaLarguras(NomeFonte, -H, Textos);
        if Abs(Soma - Alvo) < DMelhor then
        begin
          DMelhor := Abs(Soma - Alvo);
          Melhor := H;
        end;
      end;
    end;
    P.Tamanho := -Melhor;
    if Referencia then
    begin
      P.DY := DXTextoAscendente(FonteOriginal, P.TamAtlas, 0) -
        DXTextoAscendente(NomeFonte, P.Tamanho, Estilo);
      P.Altura := DXTextoAltura(FonteOriginal, P.TamAtlas, 0, 'Hg');
    end
    else
      P.Altura := DXTextoAltura(NomeFonte, P.Tamanho, Estilo, 'Hg');
    Escreve(Format('tamanho %d -> atlas %d: altura %d px (nominal %d, %.0f%%), deslocamento %d, celula %d',
      [Tamanhos[T], P.TamAtlas, Melhor, Nominal, Melhor * 100 / Nominal, P.DY, P.Altura]));
  end;
end;

{ Desenha as letras 32..126 e 160..255 num tamanho de fonte e acrescenta ao atlas (avanco,
  deslocamento e cobertura recortada).
  @param(P plano do tamanho) }
procedure GeraTamanho(const P: TPlanoTamanho);
var
  Cod: Cardinal;
  S: string;
  W, H, X, Y, Margem, X0, X1, Y0, Y1, Avanco: Integer;
  Dados: TMascara;
  G: TGlifo;
begin
  Margem := Abs(P.Tamanho) * 2 + 8;
  for Cod := 32 to 255 do
  begin
    if (Cod > 126) and (Cod < 160) then Continue;
    S := Utf8De(Cod);
    Avanco := DXTextoLargura(NomeFonte, P.Tamanho, Estilo, S);
    DXTextoMascaraMargem(NomeFonte, P.Tamanho, Estilo, S, Margem, W, H, Dados);
    X0 := W; X1 := -1; Y0 := H; Y1 := -1;
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
        if Dados[Y * W + X] <> 0 then
        begin
          if X < X0 then X0 := X;
          if X > X1 then X1 := X;
          if Y < Y0 then Y0 := Y;
          if Y > Y1 then Y1 := Y;
        end;
    G.Codigo := Cod;
    G.Avanco := Avanco;
    if X1 < 0 then
    begin
      G.XOff := 0; G.YOff := 0; G.W := 0; G.H := 0;
      G.Dados := nil;
    end
    else
    begin
      G.XOff := X0 - Margem;
      G.YOff := Y0 + P.DY;
      G.W := X1 - X0 + 1;
      G.H := Y1 - Y0 + 1;
      SetLength(G.Dados, G.W * G.H);
      for Y := 0 to G.H - 1 do
        for X := 0 to G.W - 1 do
          G.Dados[Y * G.W + X] := Dados[(Y0 + Y) * W + X0 + X];
    end;
    FonteAdicionar(P.TamAtlas, P.Altura, G);
  end;
end;

{ Compara, para todos os textos e tamanhos, o desenho do sistema (deslocado e recortado como no
  atlas) com o montado pelo atlas e escreve o resultado no relatorio.
  @param(Textos textos a conferir) }
procedure Confere(Textos: TStringList);
var
  T, I, Dif, MaxDif, Erros, Total, WA, HA, WB, HB, J, D, Maior, X, Y, YA: Integer;
  A, B: TMascara;
  VA: Byte;
  S: string;
  Pior: string;
begin
  for T := 0 to High(Planos) do
  begin
    Erros := 0;
    Total := 0;
    Maior := 0;
    Pior := '';
    for I := 0 to Textos.Count - 1 do
    begin
      S := Textos[I];
      if S = '' then Continue;
      Inc(Total);
      DXTextoMascara(NomeFonte, Planos[T].Tamanho, Estilo, S, WA, HA, A);
      FonteMascara(Planos[T].TamAtlas, S, WB, HB, B);
      if (WA <> WB) or (HB <> Planos[T].Altura) then
      begin
        Inc(Erros);
        if Erros <= 3 then
          Escreve(Format('  tam %d: tamanho diferente em "%s": sistema %dx%d, atlas %dx%d',
            [Planos[T].TamAtlas, S, WA, Planos[T].Altura, WB, HB]));
        Continue;
      end;
      Dif := 0;
      MaxDif := 0;
      for Y := 0 to HB - 1 do
        for X := 0 to WB - 1 do
        begin
          YA := Y - Planos[T].DY;
          if (YA >= 0) and (YA < HA) then VA := A[YA * WA + X] else VA := 0;
          J := Y * WB + X;
          D := Abs(Integer(VA) - Integer(B[J]));
          if D > 0 then Inc(Dif);
          if D > MaxDif then MaxDif := D;
        end;
      if Dif > 0 then
      begin
        Inc(Erros);
        if MaxDif > Maior then
        begin
          Maior := MaxDif;
          Pior := S;
        end;
        if Erros <= 3 then
          Escreve(Format('  tam %d: "%s": %d pixels diferentes (diferenca maxima %d)',
            [Planos[T].TamAtlas, S, Dif, MaxDif]));
      end;
    end;
    if Erros = 0 then
      Escreve(Format('tamanho %d: OK (%d textos identicos)', [Planos[T].TamAtlas, Total]))
    else
      Escreve(Format('tamanho %d: %d de %d textos com diferenca (maior diferenca %d em "%s")',
        [Planos[T].TamAtlas, Erros, Total, Maior, Pior]));
  end;
end;

{ @returns(os textos do jogo, nos dois idiomas, mais os montados em tempo de execucao) }
function ListarTextos: TStringList;
var
  I, Idioma: Integer;
  Nomes, Texto, Config, Frases, Dialogo, Finais, Cenarios: TStringList;
begin
  Result := TStringList.Create;
  Nomes := TStringList.Create; Texto := TStringList.Create; Config := TStringList.Create;
  Frases := TStringList.Create; Dialogo := TStringList.Create; Finais := TStringList.Create;
  Cenarios := TStringList.Create;
  for Idioma := 1 to 2 do
  begin
    CarregarTextos(Idioma, Nomes, Texto, Config, Frases, Dialogo, Finais, Cenarios);
    Result.AddStrings(Nomes); Result.AddStrings(Texto); Result.AddStrings(Config);
    Result.AddStrings(Frases); Result.AddStrings(Dialogo); Result.AddStrings(Finais);
    Result.AddStrings(Cenarios);
    ListarInterface(Result);
  end;
  Nomes.Free; Texto.Free; Config.Free; Frases.Free; Dialogo.Free; Finais.Free; Cenarios.Free;
  { textos montados em tempo de execucao: numeros, pontos, relogio, iniciais }
  for I := 0 to 99 do
  begin
    Result.Add(IntToStr(I));
    Result.Add(Format('%.2d', [I]));
  end;
  Result.Add('0123456789');
  Result.Add('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  Result.Add('abcdefghijklmnopqrstuvwxyz');
  Result.Add('Pontos: 1234567 - 100%  (x2) [A/B] 12:34');
  Result.Add('AAA');
  Result.Add('CHV');
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  Result.Sorted := False;
  for I := Result.Count - 1 downto 0 do
    if Result[I] = '' then Result.Delete(I);
end;

var
  T: Integer;
  Textos: TStringList;
begin
  Log := TStringList.Create;
  Raiz := AcharRaiz;
  Estilo := 0;
  if (ParamCount > 0) and SameText(ParamStr(1), '--hd') then
  begin
    NomeFonte := FonteHD;
    Escala := EscalaHD;
    Estilo := 1;
    if (ParamCount > 1) and SameText(ParamStr(2), 'regular') then Estilo := 0;
    Arquivo := Raiz + 'Fontes' + PathDelim + 'ComicNeue-3x.atlas';
  end
  else
  begin
    NomeFonte := FonteOriginal;
    Escala := 1;
    Arquivo := Raiz + 'Fontes' + PathDelim + 'ComicSansMS.atlas';
  end;
  if Estilo = 1 then
    Escreve(Format('GeraFonte - atlas da fonte %s (escala %d, negrito)', [NomeFonte, Escala]))
  else
    Escreve(Format('GeraFonte - atlas da fonte %s (escala %d)', [NomeFonte, Escala]));
  Escreve('Raiz do jogo: ' + Raiz);

  if Escala > 1 then
    Escreve(Format('%d arquivo(s) .ttf carregado(s) de Fontes\ComicNeue',
      [CarregarTTFs(Raiz + 'Fontes' + PathDelim + 'ComicNeue' + PathDelim)]));
  { a fonte precisa estar disponivel: se nao estiver, o Windows troca por outra }
  if not FonteExiste(NomeFonte) then
    Falha('a fonte "' + NomeFonte + '" nao parece estar disponivel neste Windows. Nada foi gerado.', 1);

  Textos := ListarTextos;
  MontarPlanos(Textos);
  FonteIniciar(NomeFonte);
  for T := 0 to High(Planos) do
  begin
    Escreve('gerando tamanho ' + IntToStr(Planos[T].TamAtlas) + ' ...');
    GeraTamanho(Planos[T]);
  end;
  FonteSalvar(Arquivo);
  with TFileStream.Create(Arquivo, fmOpenRead) do
  try
    Escreve(Format('Atlas gravado: %s (%d KB)', [Arquivo, Size div 1024]));
  finally
    Free;
  end;

  { le de volta (caminho do jogo) e confere }
  if not FonteCarregar(Arquivo) then Falha('nao consegui ler o atlas de volta.', 2);

  Escreve(Format('Conferindo %d textos em %d tamanhos...', [Textos.Count, Length(Planos)]));
  Confere(Textos);
  Escreve('Fim. Mande o conteudo de GeraFonte.log se algum tamanho nao deu OK.');
  Log.SaveToFile(Raiz + 'GeraFonte.log');
  Textos.Free;
  Log.Free;
end.
