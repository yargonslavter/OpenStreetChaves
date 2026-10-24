unit ChavesDados;

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

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, DXClass;

const
  PastaDados = 'Dados/';
  ArqJogo = 'Jogo.ini';
  ArqRecursos = 'Recursos.ini';
  ArqConfiguracao = 'Chaves.ini';

{ Abre Dados/Nome (procurando a partir da pasta do jogo). Sempre devolve um objeto: se o arquivo
  nao existir, o INI fica vazio e cada leitura devolve o valor padrao pedido. Quem chama libera. }
function AbrirDados(const Nome: string): TMemIniFile;

{ Le um numero decimal escrito com ponto (aceita virgula tambem). }
function LerDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Padrao: Double): Double;
procedure GravarDecimal(Ini: TCustomIniFile; const Secao, Chave: string; Valor: Double);

{ Monta um nome de arquivo trocando a sequencia de '#' por N com zeros a esquerda
  ('Efeitos/Efeito-###.bmp', 7 -> 'Efeitos/Efeito-007.bmp'; 'C##.bmp', 12 -> 'C12.bmp'). }
function ArquivoNN(const Padrao: string; N: Integer): string;

{ Codigo do idioma, usado em nomes de arquivo e de imagem: 1 = 'PT', 2 = 'ES'. }
function CodigoIdioma(Idioma: Integer): string;

{ Separa "a,b,c" em partes (sem espacos nas pontas). }
procedure SepararLista(const S: string; Partes: TStrings);

implementation

var
  FmtPonto: TFormatSettings;

function AbrirDados(const Nome: string): TMemIniFile;
begin
  Result := TMemIniFile.Create(DXResolvePath(PastaDados + Nome));
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
