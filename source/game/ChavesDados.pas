{ ChavesDados.pas - leitura dos arquivos de dados do jogo (pasta Dados/ na raiz do jogo).

  Os arquivos sao INI simples (TMemIniFile do FCL, sem LCL):
    - linhas que comecam com ; sao comentarios (nao use comentario no fim de uma linha de valor);
    - numeros decimais usam ponto (0.9), em qualquer idioma do sistema;
    - listas usam virgula (CHV,1,10000).

  Arquivos:
    Dados/Jogo.ini      valores do jogo e padroes da configuracao
    Dados/Recursos.ini  imagens e sons carregados pelo jogo (nomes, arquivos e quantidades)
    Dados/Textos/*.ini  textos de cada idioma (lidos por ChavesTextos)
    Chaves.ini          configuracao salva pelo jogador (tela F1), na raiz do jogo }

unit ChavesDados;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

const
  PastaDados = 'Dados/';
  ArqJogo = 'Jogo.ini';
  ArqRecursos = 'Recursos.ini';
  ArqConfiguracao = 'Chaves.ini';

{ Resolve um caminho relativo de recurso: tenta a pasta atual e depois sobe a partir da
  pasta do executavel (ate 8 niveis). Caminhos absolutos voltam como estao.
  @param(Arquivo caminho relativo, por exemplo 'Dados/Jogo.ini')
  @returns(o caminho onde o arquivo existe, ou o proprio Arquivo se nao achar) }
function ResolverCaminho(const Arquivo: string): string;

{ Abre um arquivo INI da pasta Dados/ (procurando a partir da pasta do jogo).
  Sempre devolve um objeto: se o arquivo nao existir o INI fica vazio e cada leitura devolve
  o valor padrao pedido.
  @param(Nome nome do arquivo dentro de Dados/, por exemplo 'Jogo.ini' ou 'Lutadores/C01.ini')
  @returns(o INI carregado; quem chama libera) }
function AbrirDados(const Nome: string): TMemIniFile;

{ Le um numero decimal escrito com ponto (aceita virgula tambem), independente do
  idioma do sistema.
  @param(Ini arquivo aberto)
  @param(Secao nome da secao, sem colchetes)
  @param(Chave nome da chave)
  @param(Padrao valor devolvido se a chave faltar ou nao for um numero)
  @returns(o valor lido) }
function LerDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Padrao: Double): Double;
{ Grava um numero decimal sempre com ponto como separador.
  @param(Ini arquivo aberto)
  @param(Secao nome da secao)
  @param(Chave nome da chave)
  @param(Valor numero a gravar) }
procedure GravarDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Valor: Double);

{ Monta um nome de arquivo trocando a sequencia de '#' por N com zeros a esquerda
  ('Efeitos/Efeito-###.bmp', 7 -> 'Efeitos/Efeito-007.bmp'; 'C##.bmp', 12 -> 'C12.bmp').
  @param(Padrao nome com uma sequencia de '#'; sem '#' volta como esta)
  @param(N numero a colocar no lugar dos '#')
  @returns(o nome montado) }
function ArquivoNN(const Padrao: string; N: Integer): string;

{ Codigo do idioma usado em nomes de arquivo e de imagem.
  @param(Idioma 1 = portugues, 2 = espanhol (outro valor vale como portugues))
  @returns('PT' ou 'ES') }
function CodigoIdioma(Idioma: Integer): string;

{ Separa uma lista "a,b,c" em partes, tirando os espacos nas pontas de cada uma.
  Uma lista vazia gera uma parte vazia.
  @param(S texto com os itens separados por virgula)
  @param(Partes recebe os itens (o conteudo anterior e apagado)) }
procedure SepararLista(const S: string; Partes: TStrings);

{ Compara dois inteiros pelo operador escrito num arquivo de dados.
  @param(A valor da esquerda)
  @param(Op operador: '=', '<', '>', '<=', '>=' ou '<>')
  @param(B valor da direita)
  @returns(o resultado da comparacao; False para operador desconhecido) }
function CompararInt(A: Integer; const Op: string; B: Integer): Boolean;

implementation

var
  FmtPonto: TFormatSettings;

function ResolverCaminho(const Arquivo: string): string;
var
  Dir: string;
  I: Integer;
begin
  Result := Arquivo;
  if Arquivo = '' then Exit;
  if FileExists(Arquivo) then Exit;
  if (ExtractFileDrive(Arquivo) <> '') or (Arquivo[1] in ['/', '\']) then Exit;
  Dir := ExtractFilePath(ParamStr(0));
  for I := 1 to 8 do
  begin
    if FileExists(Dir + Arquivo) then
    begin
      Result := Dir + Arquivo;
      Exit;
    end;
    Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
    if Dir = '' then Break;
  end;
end;

function AbrirDados(const Nome: string): TMemIniFile;
begin
  Result := TMemIniFile.Create(ResolverCaminho(PastaDados + Nome));
end;

function LerDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Padrao: Double): Double;
var
  S: string;
begin
  S := Trim(Ini.ReadString(Secao, Chave, ''));
  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(S, Padrao, FmtPonto);
end;

procedure GravarDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Valor: Double);
begin
  Ini.WriteString(Secao, Chave, FloatToStr(Valor, FmtPonto));
end;

function ArquivoNN(const Padrao: string; N: Integer): string;
var
  Ini, Qtd: Integer;
  Num: string;
begin
  Ini := Pos('#', Padrao);
  if Ini = 0 then
  begin
    Result := Padrao;
    Exit;
  end;
  Qtd := 0;
  while (Ini + Qtd <= Length(Padrao)) and (Padrao[Ini + Qtd] = '#') do Inc(Qtd);
  Num := IntToStr(N);
  while Length(Num) < Qtd do Num := '0' + Num;
  Result := Copy(Padrao, 1, Ini - 1) + Num + Copy(Padrao, Ini + Qtd, MaxInt);
end;

function CodigoIdioma(Idioma: Integer): string;
begin
  if Idioma = 2 then Result := 'ES' else Result := 'PT';
end;

function CompararInt(A: Integer; const Op: string; B: Integer): Boolean;
begin
  if Op = '=' then Result := A = B
  else if Op = '<' then Result := A < B
  else if Op = '>' then Result := A > B
  else if Op = '<=' then Result := A <= B
  else if Op = '>=' then Result := A >= B
  else if Op = '<>' then Result := A <> B
  else Result := False;
end;

procedure SepararLista(const S: string; Partes: TStrings);
var
  I, Ini: Integer;
begin
  Partes.Clear;
  Ini := 1;
  for I := 1 to Length(S) + 1 do
    if (I > Length(S)) or (S[I] = ',') then
    begin
      Partes.Add(Trim(Copy(S, Ini, I - Ini)));
      Ini := I + 1;
    end;
end;

initialization
  FmtPonto := DefaultFormatSettings;
  FmtPonto.DecimalSeparator := '.';
  FmtPonto.ThousandSeparator := #0;

end.
