{ Textos do jogo, lidos de Dados/Textos/<idioma>.ini (PT.ini = idioma 1, ES.ini = idioma 2).

  Formato (UTF-8, sem BOM de preferencia):
    [Secao]          Nomes, Texto, Config, Frases, Dialogo, Finais, Cenarios (listas numeradas)
                     ou Interface (textos com nome)
    8=SELECIONE ...  numero (ou nome) = texto, copiado exatamente como esta depois do '='
    14="VULGAR ... " aspas no comeco e no fim protegem espacos nas pontas (as aspas saem)
    ; comentario    linha ignorada
  Nas listas numeradas, a posicao e o numero da chave; numero que faltar fica vazio.

  O arquivo e lido sem o TIniFile de proposito: o TIniFile apara espacos nas pontas e o
  jogo depende deles para alinhar alguns textos. }

unit ChavesTextos;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ChavesDados;

{ Le Dados/Textos/PT.ini ou ES.ini e substitui o conteudo das listas pelos textos
  do idioma. A secao [Interface] fica guardada para TextoInterface.
  @param(Idioma 1 = portugues, 2 = espanhol)
  @param(Nomes recebe a secao [Nomes] (nomes dos lutadores))
  @param(Texto recebe a secao [Texto] (textos gerais das telas))
  @param(Config recebe a secao [Config] (tela de configuracao))
  @param(Frases recebe a secao [Frases] (frases da abertura e de vitoria))
  @param(Dialogo recebe a secao [Dialogo] (falas antes da luta))
  @param(Finais recebe a secao [Finais] (textos dos finais))
  @param(Cenarios recebe a secao [Cenarios] (nomes dos cenarios)) }
procedure CarregarTextos(Idioma: Integer; Nomes, Texto, Config, Frases, Dialogo,
  Finais, Cenarios: TStrings);

{ Texto da secao [Interface] do idioma carregado por ultimo.
  @param(Chave nome do texto)
  @returns(o texto, ou '' se nao existir) }
function TextoInterface(const Chave: string): string;

{ Acrescenta a Dest todos os textos da secao [Interface] (usado pela ferramenta
  GeraFonte para saber quais letras gerar).
  @param(Dest lista que recebe os textos (o conteudo anterior e mantido)) }
procedure ListarInterface(Dest: TStrings);

implementation

var
  Interface_: TStringList;     // Chave=Texto da secao [Interface]

{ Separa uma linha "chave=valor": a chave sem espacos nas pontas e o valor exatamente
  como esta, tirando um par de aspas que envolva o valor inteiro.
  @param(L linha do arquivo)
  @param(Chave recebe a chave)
  @param(Valor recebe o valor)
  @returns(False se a linha nao tem '=' depois de pelo menos um caractere) }
function SepararLinha(const L: string; out Chave, Valor: string): Boolean;
var
  P: Integer;
begin
  P := Pos('=', L);
  Result := P > 1;
  if not Result then Exit;
  Chave := Trim(Copy(L, 1, P - 1));
  Valor := Copy(L, P + 1, MaxInt);
  if (Length(Valor) >= 2) and (Valor[1] = '"') and (Valor[Length(Valor)] = '"') then
    Valor := Copy(Valor, 2, Length(Valor) - 2);
end;

{ Coloca um texto na posicao Indice da lista, criando linhas vazias ate la.
  @param(Dest lista de destino (nil = ignora))
  @param(Indice posicao (negativo = ignora))
  @param(Valor texto) }
procedure Guardar(Dest: TStrings; Indice: Integer; const Valor: string);
begin
  if (Dest = nil) or (Indice < 0) then Exit;
  while Dest.Count <= Indice do Dest.Add('');
  Dest[Indice] := Valor;
end;

procedure CarregarTextos(Idioma: Integer; Nomes, Texto, Config, Frases, Dialogo,
  Finais, Cenarios: TStrings);
var
  Arquivo: TStringList;
  Listas: array[0..6] of TStrings;
  Atual: TStrings;
  NaInterface: Boolean;
  I, K: Integer;
  L, Chave, Valor: string;
const
  NomesSecao: array[0..6] of string =
    ('Nomes', 'Texto', 'Config', 'Frases', 'Dialogo', 'Finais', 'Cenarios');
begin
  Listas[0] := Nomes;
  Listas[1] := Texto;
  Listas[2] := Config;
  Listas[3] := Frases;
  Listas[4] := Dialogo;
  Listas[5] := Finais;
  Listas[6] := Cenarios;
  for K := 0 to High(Listas) do Listas[K].Clear;
  Interface_.Clear;

  Arquivo := TStringList.Create;
  try
    L := ResolverCaminho(PastaDados + 'Textos/' + CodigoIdioma(Idioma) + '.ini');
    if FileExists(L) then Arquivo.LoadFromFile(L);
    Atual := nil;
    NaInterface := False;
    for I := 0 to Arquivo.Count - 1 do
    begin
      L := Arquivo[I];
      if (I = 0) and (Copy(L, 1, 3) = #$EF#$BB#$BF) then Delete(L, 1, 3);   // BOM do UTF-8
      if (Trim(L) = '') or (L[1] = ';') then Continue;
      if L[1] = '[' then
      begin
        L := Trim(L);
        L := Copy(L, 2, Length(L) - 2);
        Atual := nil;
        NaInterface := SameText(L, 'Interface');
        for K := 0 to High(NomesSecao) do
          if SameText(L, NomesSecao[K]) then Atual := Listas[K];
        Continue;
      end;
      if not SepararLinha(L, Chave, Valor) then Continue;
      if NaInterface then
        Interface_.Values[Chave] := Valor
      else
        Guardar(Atual, StrToIntDef(Chave, -1), Valor);
    end;
  finally
    Arquivo.Free;
  end;
end;

function TextoInterface(const Chave: string): string;
var
  I: Integer;
begin
  I := Interface_.IndexOfName(Chave);
  if I >= 0 then Result := Interface_.ValueFromIndex[I] else Result := '';
end;

procedure ListarInterface(Dest: TStrings);
var
  I: Integer;
begin
  for I := 0 to Interface_.Count - 1 do
    Dest.Add(Interface_.ValueFromIndex[I]);
end;

initialization
  Interface_ := TStringList.Create;

finalization
  Interface_.Free;

end.
