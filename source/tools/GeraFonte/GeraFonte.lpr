program GeraFonte;

{ GeraFonte - gera o atlas de glifos da fonte do jogo (Fontes/ComicSansMS.atlas).

  Rode UMA vez, no Windows com a Comic Sans MS instalada (a mesma do jogo original):
    GeraFonte.exe
  Ele desenha cada letra, em cada tamanho usado pelo jogo, com o proprio GDI/LCL (o mesmo
  caminho que o jogo usava), grava o atlas na raiz do jogo (pasta que tem o Chaves.exe) e
  confere o resultado: para todos os textos do jogo, compara o texto desenhado pelo sistema
  com o montado pelo atlas e escreve o relatorio em GeraFonte.log.

  Esta e a unica ferramenta do projeto que usa a LCL; o jogo (StreetChaves) nao usa. }

{$mode delphi}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, ChavesFonte, DXTexto, ChavesTextos;

const
  NomeFonte = 'Comic Sans MS';
  { tamanhos de fonte usados pelo jogo (chamadas de texto(...) com Tam fixo) }
  Tamanhos: array[0..20] of Integer = (7, 8, 9, 10, 11, 12, 14, 15, 16, 18, 20, 22, 25, 26, 27, 28,
    29, 35, 36, 70, 120);

var
  Log: TStringList;
  Raiz, Arquivo: string;

procedure Escreve(const S: string);
begin
  WriteLn(S);
  Log.Add(S);
end;

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

function Utf8De(Codigo: Cardinal): string;
begin
  Result := UTF8Encode(UnicodeString(WideChar(Codigo)));
end;

procedure GeraTamanho(Tam: Integer);
var
  Cod: Cardinal;
  S: string;
  W, H, X, Y, Margem, X0, X1, Y0, Y1, Avanco, Alt: Integer;
  Dados: TMascara;
  G: TGlifo;
begin
  Alt := DXTextoAltura(NomeFonte, Tam, 0, 'Hg');
  Margem := Tam * 2 + 8;
  for Cod := 32 to 255 do
  begin
    if (Cod > 126) and (Cod < 160) then Continue;
    S := Utf8De(Cod);
    Avanco := DXTextoLargura(NomeFonte, Tam, 0, S);
    DXTextoMascaraMargem(NomeFonte, Tam, 0, S, Margem, W, H, Dados);
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
      G.YOff := Y0;
      G.W := X1 - X0 + 1;
      G.H := Y1 - Y0 + 1;
      SetLength(G.Dados, G.W * G.H);
      for Y := 0 to G.H - 1 do
        for X := 0 to G.W - 1 do
          G.Dados[Y * G.W + X] := Dados[(Y0 + Y) * W + X0 + X];
    end;
    FonteAdicionar(Tam, Alt, G);
  end;
end;

{ compara, para todos os textos do jogo, o desenho do sistema com o do atlas }
procedure Confere(Textos: TStringList);
var
  T, I, Dif, MaxDif, Erros, Total, WA, HA, WB, HB, J, D, Maior: Integer;
  A, B: TMascara;
  S: string;
  Pior: string;
begin
  for T := 0 to High(Tamanhos) do
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
      DXTextoMascara(NomeFonte, Tamanhos[T], 0, S, WA, HA, A);
      FonteMascara(Tamanhos[T], S, WB, HB, B);
      if (WA <> WB) or (HA <> HB) then
      begin
        Inc(Erros);
        if Erros <= 3 then
          Escreve(Format('  tam %d: tamanho diferente em "%s": sistema %dx%d, atlas %dx%d',
            [Tamanhos[T], S, WA, HA, WB, HB]));
        Continue;
      end;
      Dif := 0;
      MaxDif := 0;
      for J := 0 to WA * HA - 1 do
      begin
        D := Abs(Integer(A[J]) - Integer(B[J]));
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
            [Tamanhos[T], S, Dif, MaxDif]));
      end;
    end;
    if Erros = 0 then
      Escreve(Format('tamanho %d: OK (%d textos identicos)', [Tamanhos[T], Total]))
    else
      Escreve(Format('tamanho %d: %d de %d textos com diferenca (maior diferenca %d em "%s")',
        [Tamanhos[T], Erros, Total, Maior, Pior]));
  end;
end;

var
  T, I, Idioma: Integer;
  Textos, Nomes, Texto, Config, Frases, Dialogo, Finais, Cenarios: TStringList;
  W0, W1: Integer;
begin
  Log := TStringList.Create;
  Raiz := AcharRaiz;
  Arquivo := Raiz + 'Fontes' + PathDelim + 'ComicSansMS.atlas';
  Escreve('GeraFonte - atlas da fonte ' + NomeFonte);
  Escreve('Raiz do jogo: ' + Raiz);

  { a fonte precisa estar instalada: se nao estiver, o Windows troca por outra e as larguras coincidem }
  W0 := DXTextoLargura(NomeFonte, 20, 0, 'Wiiiimmmm AaBbQq');
  W1 := DXTextoLargura('ZzFonteQueNaoExiste', 20, 0, 'Wiiiimmmm AaBbQq');
  if W0 = W1 then
  begin
    Escreve('ERRO: a fonte "' + NomeFonte + '" nao parece estar instalada neste Windows. Nada foi gerado.');
    Log.SaveToFile(Raiz + 'GeraFonte.log');
    Halt(1);
  end;

  FonteIniciar(NomeFonte);
  for T := 0 to High(Tamanhos) do
  begin
    Escreve('gerando tamanho ' + IntToStr(Tamanhos[T]) + ' ...');
    GeraTamanho(Tamanhos[T]);
  end;
  FonteSalvar(Arquivo);
  with TFileStream.Create(Arquivo, fmOpenRead) do
  try
    Escreve(Format('Atlas gravado: %s (%d KB)', [Arquivo, Size div 1024]));
  finally
    Free;
  end;

  { le de volta (caminho do jogo) e confere }
  if not FonteCarregar(Arquivo) then
  begin
    Escreve('ERRO: nao consegui ler o atlas de volta.');
    Log.SaveToFile(Raiz + 'GeraFonte.log');
    Halt(2);
  end;

  Textos := TStringList.Create;
  Nomes := TStringList.Create; Texto := TStringList.Create; Config := TStringList.Create;
  Frases := TStringList.Create; Dialogo := TStringList.Create; Finais := TStringList.Create;
  Cenarios := TStringList.Create;
  for Idioma := 1 to 2 do
  begin
    CarregarTextos(Idioma, Nomes, Texto, Config, Frases, Dialogo, Finais, Cenarios);
    Textos.AddStrings(Nomes); Textos.AddStrings(Texto); Textos.AddStrings(Config);
    Textos.AddStrings(Frases); Textos.AddStrings(Dialogo); Textos.AddStrings(Finais);
    Textos.AddStrings(Cenarios);
    ListarInterface(Textos);
  end;
  { textos montados em tempo de execucao: numeros, pontos, relogio, iniciais }
  for I := 0 to 99 do
  begin
    Textos.Add(IntToStr(I));
    Textos.Add(Format('%.2d', [I]));
  end;
  Textos.Add('0123456789');
  Textos.Add('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  Textos.Add('abcdefghijklmnopqrstuvwxyz');
  Textos.Add('Pontos: 1234567 - 100%  (x2) [A/B] 12:34');
  Textos.Add('AAA');
  Textos.Add('CHV');
  Textos.Sorted := True;
  Textos.Duplicates := dupIgnore;
  Textos.Sorted := False;
  Escreve(Format('Conferindo %d textos em %d tamanhos...', [Textos.Count, Length(Tamanhos)]));
  Confere(Textos);
  Escreve('Fim. Mande o conteudo de GeraFonte.log se algum tamanho nao deu OK.');
  Log.SaveToFile(Raiz + 'GeraFonte.log');
  Textos.Free;
  Nomes.Free; Texto.Free; Config.Free; Frases.Free; Dialogo.Free; Finais.Free; Cenarios.Free;
  Log.Free;
end.
