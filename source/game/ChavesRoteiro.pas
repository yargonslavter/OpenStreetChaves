unit ChavesRoteiro;

{ ChavesRoteiro.pas - interpretador dos roteiros dos lutadores (Dados/Lutadores/*.rot).

  Um roteiro e um trecho de Pascal simplificado, separado em secoes ([Acao], [AcaoFim]...).
  Tem o que o codigo original usa: if/then/else, begin/end, for/to/downto, repeat/until, while,
  case, atribuicao, operadores do Pascal (com a mesma precedencia), conjuntos (P.Acao in [...]),
  e uma lista fixa de nomes:
    P. e O.   campos do lutador e do oponente (P.Acao, O.Invulneravel...)
    Jog, Codigo, Desloc   jogador (1 ou 2), comando recebido por AcaoJogador e 0/50 do jogador
    variaveis do jogo (SomPendente, FlashTela, ChaoY...), constantes (acParado, cmEsp1Fraco...)
    funcoes: Random, Round, Trunc, Abs, Cos, Sin, ShortInt, ExisteEfeito, CriaEfeito, Empurra,
             AcaoJogador, AplicarCaixas
  Variaveis proprias: "var Nome: Tipo;" no comeco da secao (Byte, ShortInt, SmallInt, Word,
  Integer, Int64, Double, Boolean).

  As contas seguem as regras do Pascal: inteiro com inteiro da inteiro, "/" e qualquer conta com
  Double dao Double, gravar num Byte/ShortInt corta o valor, "and"/"or" param assim que o
  resultado e conhecido, e Random(Round(...)) usa o Random de 64 bits, como no codigo compilado.
  Todo sorteio passa por SortearValor, que pode gravar e repetir a sequencia (modo de conferencia). }

{$mode delphi}{$H+}
{$POINTERMATH ON}

interface

uses
  Classes, SysUtils, Math, ChavesConst, ChavesTipos;

type
  ERoteiro = class(Exception);

  TTipoDado = (tdNenhum, tdByte, tdShortInt, tdSmallInt, tdWord, tdInteger, tdInt64, tdDouble,
    tdBoolean, tdString);

  TClasseValor = (cvInt, cvReal, cvBool, cvStr);
  TValor = record
    C: TClasseValor;
    Largo: Boolean;      // inteiro de 64 bits (Int64), como o resultado de Round
    I: Int64;
    F: Extended;
    S: string;
  end;

  TTipoNo = (nConst, nLocal, nGlobal, nCampo, nUn, nBin, nFunc, nConj, nFaixa,
    cAtrib, cChamada, cSe, cBloco, cPara, cRepita, cEnquanto, cCaso, cRamo);

  TNo = record
    T: TTipoNo;
    Op: Integer;              // operador, funcao ou direcao do for (1 = to, -1 = downto)
    Ind: Integer;             // indice do local, global ou campo
    Base: Integer;            // campos: 0 = P, 1 = O
    A, B, C: Integer;         // filhos (-1 = nenhum)
    Lista: array of Integer;  // argumentos, comandos, elementos ou ramos
    V: TValor;                // valor (nConst)
    Linha: Integer;
  end;

  TRoteiro = class
  private
    FOrigem: string;
    FNos: array of TNo;
    FQtdNos: Integer;
    FRaiz: Integer;
    FNomesLocais: array of string;
    FTiposLocais: array of TTipoDado;
    function Novo(T: TTipoNo; Linha: Integer): Integer;
    procedure Falha(Linha: Integer; const Msg: string);
  public
    { Texto: o conteudo da secao; Origem e LinhaInicial: para as mensagens de erro. }
    constructor Create(const Texto, Origem: string; LinhaInicial: Integer);
    { Executa com P = Lutador[Jog], O = o outro, Codigo e Desloc (0 para o jogador 1, 50 para o 2). }
    procedure Executar(Jog: Byte; Codigo: Integer);
    property Origem: string read FOrigem;
  end;

{ Le a secao [Secao] do arquivo de roteiro; nil se o arquivo ou a secao nao existirem.
  Um erro no roteiro gera ERoteiro com o arquivo e a linha. }
function CarregarRoteiro(const Arquivo, Secao: string): TRoteiro;

{ ---- sorteios (Random) ---- }
type
  TModoSorteio = (msNormal, msGravar, msRepetir);

{ Random(N) do Pascal (32 e 64 bits). Em msGravar anota cada sorteio; em msRepetir devolve os
  anotados, na ordem (SorteioDivergiu = pediu algo diferente). }
function Sortear(N: LongInt): LongInt;
function Sortear64(N: Int64): Int64;
{ Nome do campo de TLutador que ocupa o byte Desl (para o relatorio da conferencia). }
function NomeCampoLutador(Desl: Integer): string;
{ Campos diferentes entre A e B, com os dois valores ('Y 300 -> 255; ...'); '' se iguais. }
function DiferencasLutador(const A, B: TLutador): string;
{ Resumo do lutador (acao, quadros, posicao, velocidade, vida...) para o relatorio. }
function ResumoLutador(const L: TLutador): string;
procedure ModoDeSorteio(Modo: TModoSorteio);
function SorteiosRestantes: Integer;   // em msRepetir: anotados que ainda nao foram usados

var
  SorteioDivergiu: Boolean;

implementation

uses
  ChavesGolpes;

type
  TConstanteRoteiro = record
    N: string;
    V: Integer;
  end;

const
  QtdConstantes = 98;
  Constantes: array[0..QtdConstantes - 1] of TConstanteRoteiro = (
    (N: 'acParado'; V: acParado),
    (N: 'acAndando'; V: acAndando),
    (N: 'acSocoFraco'; V: acSocoFraco),
    (N: 'acChuteFraco'; V: acChuteFraco),
    (N: 'acSocoForte'; V: acSocoForte),
    (N: 'acChuteForte'; V: acChuteForte),
    (N: 'acAgachado'; V: acAgachado),
    (N: 'acAgSocoFraco'; V: acAgSocoFraco),
    (N: 'acAgChuteFraco'; V: acAgChuteFraco),
    (N: 'acAgSocoForte'; V: acAgSocoForte),
    (N: 'acAgChuteForte'; V: acAgChuteForte),
    (N: 'acPulo'; V: acPulo),
    (N: 'acArSocoFraco'; V: acArSocoFraco),
    (N: 'acArChuteFraco'; V: acArChuteFraco),
    (N: 'acArSocoForte'; V: acArSocoForte),
    (N: 'acArChuteForte'; V: acArChuteForte),
    (N: 'acApanhaAlto'; V: acApanhaAlto),
    (N: 'acApanhaBaixo'; V: acApanhaBaixo),
    (N: 'acDerrubado'; V: acDerrubado),
    (N: 'acQuicando'; V: acQuicando),
    (N: 'acDefesa'; V: acDefesa),
    (N: 'acDefesaBaixa'; V: acDefesaBaixa),
    (N: 'acVitoria'; V: acVitoria),
    (N: 'acPose'; V: acPose),
    (N: 'acEspecial1'; V: acEspecial1),
    (N: 'acEspecial2'; V: acEspecial2),
    (N: 'acEspecial3'; V: acEspecial3),
    (N: 'acEspecial4'; V: acEspecial4),
    (N: 'acEspecial5'; V: acEspecial5),
    (N: 'acEspecial6'; V: acEspecial6),
    (N: 'acEspecial7'; V: acEspecial7),
    (N: 'cmEsquerda'; V: cmEsquerda),
    (N: 'cmDireita'; V: cmDireita),
    (N: 'cmSocoFraco'; V: cmSocoFraco),
    (N: 'cmChuteFraco'; V: cmChuteFraco),
    (N: 'cmSocoForte'; V: cmSocoForte),
    (N: 'cmChuteForte'; V: cmChuteForte),
    (N: 'cmAgachar'; V: cmAgachar),
    (N: 'cmApanharAlto'; V: cmApanharAlto),
    (N: 'cmApanharBaixo'; V: cmApanharBaixo),
    (N: 'cmDerrubar'; V: cmDerrubar),
    (N: 'cmBaterNoChao'; V: cmBaterNoChao),
    (N: 'cmDefender'; V: cmDefender),
    (N: 'cmDefenderBaixo'; V: cmDefenderBaixo),
    (N: 'cmVitoria'; V: cmVitoria),
    (N: 'cmPose'; V: cmPose),
    (N: 'cmEsp1Fraco'; V: cmEsp1Fraco),
    (N: 'cmEsp1Forte'; V: cmEsp1Forte),
    (N: 'cmEsp2Fraco'; V: cmEsp2Fraco),
    (N: 'cmEsp2Forte'; V: cmEsp2Forte),
    (N: 'cmEsp3Fraco'; V: cmEsp3Fraco),
    (N: 'cmEsp3Forte'; V: cmEsp3Forte),
    (N: 'cmEsp4Fraco'; V: cmEsp4Fraco),
    (N: 'cmEsp4Forte'; V: cmEsp4Forte),
    (N: 'cmEspFinal'; V: cmEspFinal),
    (N: 'cmEspExtra1'; V: cmEspExtra1),
    (N: 'cmEspExtra2'; V: cmEspExtra2),
    (N: 'pnChaves'; V: pnChaves),
    (N: 'pnSeuMadruga'; V: pnSeuMadruga),
    (N: 'pnChiquinha'; V: pnChiquinha),
    (N: 'pnQuico'; V: pnQuico),
    (N: 'pnDonaFlorinda'; V: pnDonaFlorinda),
    (N: 'pnProfGirafales'; V: pnProfGirafales),
    (N: 'pnSrBarriga'; V: pnSrBarriga),
    (N: 'pnBruxa'; V: pnBruxa),
    (N: 'pnPaty'; V: pnPaty),
    (N: 'pnNhonho'; V: pnNhonho),
    (N: 'pnGodines'; V: pnGodines),
    (N: 'pnSrFurtado'; V: pnSrFurtado),
    (N: 'pnJaiminho'; V: pnJaiminho),
    (N: 'pnDonaNeves'; V: pnDonaNeves),
    (N: 'pnGloria'; V: pnGloria),
    (N: 'ldDireita'; V: ldDireita),
    (N: 'ldEsquerda'; V: ldEsquerda),
    (N: 'fgNenhum'; V: fgNenhum),
    (N: 'fgFraco'; V: fgFraco),
    (N: 'fgForte'; V: fgForte),
    (N: 'fgEspecial'; V: fgEspecial),
    (N: 'puloNenhum'; V: puloNenhum),
    (N: 'puloReto'; V: puloReto),
    (N: 'puloEsquerda'; V: puloEsquerda),
    (N: 'puloDireita'; V: puloDireita),
    (N: 'sndTempoEsgotado'; V: sndTempoEsgotado),
    (N: 'sndGolpeFraco'; V: sndGolpeFraco),
    (N: 'sndGolpeForte'; V: sndGolpeForte),
    (N: 'sndAcertoFraco'; V: sndAcertoFraco),
    (N: 'sndAcertoForte'; V: sndAcertoForte),
    (N: 'sndAcertoEspecial'; V: sndAcertoEspecial),
    (N: 'sndDefesa'; V: sndDefesa),
    (N: 'sndItem'; V: sndItem),
    (N: 'sndQueda'; V: sndQueda),
    (N: 'sndPoder'; V: sndPoder),
    (N: 'sndEspFinal'; V: sndEspFinal),
    (N: 'LarguraTela'; V: LarguraTela),
    (N: 'AlturaTela'; V: AlturaTela),
    (N: 'VidaMax'; V: VidaMax),
    (N: 'CargaMax'; V: CargaMax),
    (N: 'MaxEfeitos'; V: MaxEfeitos));

  { operadores }
  opMais = 1; opMenos = 2; opVezes = 3; opBarra = 4; opDiv = 5; opMod = 6; opAnd = 7; opOr = 8;
  opXor = 9; opShl = 10; opShr = 11; opIgual = 12; opDif = 13; opMenor = 14; opMaior = 15;
  opMenorIg = 16; opMaiorIg = 17; opIn = 18; opNeg = 19; opNot = 20; opPos = 21;

  { funcoes }
  fRandom = 1; fRound = 2; fTrunc = 3; fAbs = 4; fCos = 5; fSin = 6; fShortInt = 7;
  fExisteEfeito = 8; fCriaEfeito = 9; fEmpurra = 10; fAcaoJogador = 11; fAplicarCaixas = 12;
  NomesFuncoes: array[1..12] of string = ('Random', 'Round', 'Trunc', 'Abs', 'Cos', 'Sin',
    'ShortInt', 'ExisteEfeito', 'CriaEfeito', 'Empurra', 'AcaoJogador', 'AplicarCaixas');
  ArgsFuncoes: array[1..12] of Integer = (1, 1, 1, 1, 1, 1, 1, 2, 5, 2, 2, 1);
  { procedimentos (nao devolvem valor) }
  ProcFuncoes: array[1..12] of Boolean = (False, False, False, False, False, False, False, False,
    True, True, True, True);

  { locais que todo roteiro tem }
  LocalJog = 0; LocalCodigo = 1; LocalDesloc = 2; QtdPredef = 3;

type
  TDescCampo = record
    Nome: string;
    Tipo: TTipoDado;
    Desl: PtrInt;
  end;
  TDescGlobal = record
    Nome: string;
    Tipo: TTipoDado;
    Ender: Pointer;
  end;

var
  Campos: array of TDescCampo;
  Globais: array of TDescGlobal;
  OrdemArgsInversa: Boolean;   // o compilador avalia os argumentos do ultimo para o primeiro

{ ================= valores ================= }

function VInt(I: Int64; Largo: Boolean): TValor;
begin
  Result.C := cvInt;
  Result.Largo := Largo;
  Result.I := I;
  Result.F := 0;
  Result.S := '';
end;

function VReal(F: Extended): TValor;
begin
  Result.C := cvReal;
  Result.Largo := False;
  Result.I := 0;
  Result.F := F;
  Result.S := '';
end;

function VBool(B: Boolean): TValor;
begin
  Result.C := cvBool;
  Result.Largo := False;
  Result.I := Ord(B);
  Result.F := 0;
  Result.S := '';
end;

function VStr(const S: string): TValor;
begin
  Result.C := cvStr;
  Result.Largo := False;
  Result.I := 0;
  Result.F := 0;
  Result.S := S;
end;

{ ================= sorteios ================= }

type
  TSorteioGravado = record
    N: Int64;
    Largo: Boolean;
    R: Int64;
  end;

var
  ModoSort: TModoSorteio = msNormal;
  Gravados: array of TSorteioGravado;
  QtdGravados, PosGravado: Integer;

function SortearValor(N: Int64; Largo: Boolean): Int64;
begin
  if ModoSort = msRepetir then
  begin
    if (PosGravado < QtdGravados) and (Gravados[PosGravado].N = N) and
       (Gravados[PosGravado].Largo = Largo) then
    begin
      Result := Gravados[PosGravado].R;
      Inc(PosGravado);
      Exit;
    end;
    SorteioDivergiu := True;
    ModoSort := msNormal;
  end;
  if Largo then
    Result := System.Random(N)
  else
    Result := System.Random(LongInt(N));
  if ModoSort = msGravar then
  begin
    if QtdGravados >= Length(Gravados) then SetLength(Gravados, QtdGravados * 2 + 16);
    Gravados[QtdGravados].N := N;
    Gravados[QtdGravados].Largo := Largo;
    Gravados[QtdGravados].R := Result;
    Inc(QtdGravados);
  end;
end;

function Sortear(N: LongInt): LongInt;
begin
  Result := SortearValor(N, False);
end;

function Sortear64(N: Int64): Int64;
begin
  Result := SortearValor(N, True);
end;

procedure ModoDeSorteio(Modo: TModoSorteio);
begin
  if Modo = msGravar then
  begin
    QtdGravados := 0;
    PosGravado := 0;
  end;
  if Modo = msRepetir then
  begin
    PosGravado := 0;
    SorteioDivergiu := False;
  end;
  ModoSort := Modo;
end;

function SorteiosRestantes: Integer;
begin
  Result := QtdGravados - PosGravado;
end;

{ ================= memoria (campos, globais, locais) ================= }

function LerMem(T: TTipoDado; P: Pointer): TValor;
begin
  case T of
    tdByte: Result := VInt(PByte(P)^, False);
    tdShortInt: Result := VInt(PShortInt(P)^, False);
    tdSmallInt: Result := VInt(PSmallInt(P)^, False);
    tdWord: Result := VInt(PWord(P)^, False);
    tdInteger: Result := VInt(PLongInt(P)^, False);
    tdInt64: Result := VInt(PInt64(P)^, True);
    tdDouble: Result := VReal(PDouble(P)^);
    tdBoolean: Result := VBool(PBoolean(P)^);
  else
    Result := VInt(0, False);
  end;
end;

{ converte V para o tipo T (como numa atribuicao do Pascal); False se nao combina }
function Converter(T: TTipoDado; const V: TValor; out R: TValor): Boolean;
var
  D: Double;
begin
  Result := True;
  case T of
    tdByte, tdShortInt, tdSmallInt, tdWord, tdInteger, tdInt64:
      begin
        if V.C <> cvInt then
        begin
          Result := False;
          Exit;
        end;
        case T of
          tdByte: R := VInt(Byte(V.I), False);
          tdShortInt: R := VInt(ShortInt(V.I), False);
          tdSmallInt: R := VInt(SmallInt(V.I), False);
          tdWord: R := VInt(Word(V.I), False);
          tdInteger: R := VInt(LongInt(V.I), False);
        else
          R := VInt(V.I, True);
        end;
      end;
    tdDouble:
      { conversao de valor (D := ...), nunca Double(...): Double(Int64) so reinterpretaria os bits }
      if V.C = cvReal then
      begin
        D := V.F;
        R := VReal(D);
      end
      else if V.C = cvInt then
      begin
        D := V.I;
        R := VReal(D);
      end
      else Result := False;
    tdBoolean:
      if V.C = cvBool then R := V else Result := False;
  else
    Result := False;
  end;
end;

procedure GravarMem(T: TTipoDado; P: Pointer; const V: TValor);
begin
  case T of
    tdByte: PByte(P)^ := Byte(V.I);
    tdShortInt: PShortInt(P)^ := ShortInt(V.I);
    tdSmallInt: PSmallInt(P)^ := SmallInt(V.I);
    tdWord: PWord(P)^ := Word(V.I);
    tdInteger: PLongInt(P)^ := LongInt(V.I);
    tdInt64: PInt64(P)^ := V.I;
    tdDouble: PDouble(P)^ := V.F;
    tdBoolean: PBoolean(P)^ := V.I <> 0;
  end;
end;

function TipoPorNome(const S: string): TTipoDado;
begin
  if SameText(S, 'Byte') then Result := tdByte
  else if SameText(S, 'ShortInt') then Result := tdShortInt
  else if SameText(S, 'SmallInt') then Result := tdSmallInt
  else if SameText(S, 'Word') then Result := tdWord
  else if SameText(S, 'Integer') or SameText(S, 'LongInt') then Result := tdInteger
  else if SameText(S, 'Int64') then Result := tdInt64
  else if SameText(S, 'Double') then Result := tdDouble
  else if SameText(S, 'Boolean') then Result := tdBoolean
  else Result := tdNenhum;
end;

{ ================= analise do texto ================= }

type
  TClasseTok = (tkId, tkInt, tkReal, tkStr, tkSim, tkFim);
  TTok = record
    K: TClasseTok;
    S: string;       // texto (identificador, simbolo, string sem aspas)
    Low: string;     // minusculo (para palavras reservadas)
    I: Int64;
    F: Extended;
    Linha: Integer;
  end;

  TAnalisador = class
    R: TRoteiro;
    Toks: array of TTok;
    Pos: Integer;
    constructor Create(ARoteiro: TRoteiro; const Texto: string; LinhaInicial: Integer);
    function Atual: TTok;
    function Eh(const S: string): Boolean;        // simbolo ou palavra reservada atual
    procedure Pegar(const S: string);
    function PegarId: string;
    function Expr: Integer;
    function Simples: Integer;
    function Termo: Integer;
    function Fator: Integer;
    function Comando: Integer;
    function ListaAte(const Fim1, Fim2: string): Integer;   // devolve um cBloco
    procedure Declaracoes;
    function BuscaLocal(const Nome: string): Integer;
  end;

var
  FmtPonto: TFormatSettings;

constructor TAnalisador.Create(ARoteiro: TRoteiro; const Texto: string; LinhaInicial: Integer);
var
  I, N, Ini, Linha: Integer;
  Ch: Char;
  T: TTok;
  S: string;

  procedure Add;
  begin
    if N >= Length(Toks) then SetLength(Toks, N * 2 + 64);
    Toks[N] := T;
    Inc(N);
  end;

begin
  R := ARoteiro;
  N := 0;
  I := 1;
  Linha := LinhaInicial;
  while I <= Length(Texto) do
  begin
    Ch := Texto[I];
    if Ch = #10 then
    begin
      Inc(Linha);
      Inc(I);
      Continue;
    end;
    if Ch <= ' ' then
    begin
      Inc(I);
      Continue;
    end;
    { comentarios }
    if (Ch = '/') and (I < Length(Texto)) and (Texto[I + 1] = '/') then
    begin
      while (I <= Length(Texto)) and (Texto[I] <> #10) do Inc(I);
      Continue;
    end;
    if Ch = '{' then
    begin
      while (I <= Length(Texto)) and (Texto[I] <> '}') do
      begin
        if Texto[I] = #10 then Inc(Linha);
        Inc(I);
      end;
      Inc(I);
      Continue;
    end;
    if (Ch = '(') and (I < Length(Texto)) and (Texto[I + 1] = '*') then
    begin
      Inc(I, 2);
      while (I < Length(Texto)) and not ((Texto[I] = '*') and (Texto[I + 1] = ')')) do
      begin
        if Texto[I] = #10 then Inc(Linha);
        Inc(I);
      end;
      Inc(I, 2);
      Continue;
    end;
    T.Linha := Linha;
    T.S := '';
    T.Low := '';
    T.I := 0;
    T.F := 0;
    if Ch in ['A'..'Z', 'a'..'z', '_'] then
    begin
      Ini := I;
      while (I <= Length(Texto)) and (Texto[I] in ['A'..'Z', 'a'..'z', '_', '0'..'9']) do Inc(I);
      T.K := tkId;
      T.S := Copy(Texto, Ini, I - Ini);
      T.Low := LowerCase(T.S);
      Add;
      Continue;
    end;
    if Ch in ['0'..'9'] then
    begin
      Ini := I;
      while (I <= Length(Texto)) and (Texto[I] in ['0'..'9']) do Inc(I);
      if (I < Length(Texto)) and (Texto[I] = '.') and (Texto[I + 1] in ['0'..'9']) then
      begin
        Inc(I);
        while (I <= Length(Texto)) and (Texto[I] in ['0'..'9']) do Inc(I);
        if (I <= Length(Texto)) and (Texto[I] in ['e', 'E']) then
        begin
          Inc(I);
          if (I <= Length(Texto)) and (Texto[I] in ['+', '-']) then Inc(I);
          while (I <= Length(Texto)) and (Texto[I] in ['0'..'9']) do Inc(I);
        end;
        T.K := tkReal;
        T.S := Copy(Texto, Ini, I - Ini);
        T.F := StrToFloat(T.S, FmtPonto);
      end
      else
      begin
        T.K := tkInt;
        T.S := Copy(Texto, Ini, I - Ini);
        T.I := StrToInt64(T.S);
      end;
      Add;
      Continue;
    end;
    if Ch = '$' then
    begin
      Ini := I;
      Inc(I);
      while (I <= Length(Texto)) and (Texto[I] in ['0'..'9', 'A'..'F', 'a'..'f']) do Inc(I);
      T.K := tkInt;
      T.S := Copy(Texto, Ini, I - Ini);
      T.I := StrToInt64(T.S);
      Add;
      Continue;
    end;
    if Ch = '''' then
    begin
      S := '';
      Inc(I);
      while I <= Length(Texto) do
      begin
        if Texto[I] = '''' then
        begin
          if (I < Length(Texto)) and (Texto[I + 1] = '''') then
          begin
            S := S + '''';
            Inc(I, 2);
            Continue;
          end;
          Break;
        end;
        S := S + Texto[I];
        Inc(I);
      end;
      Inc(I);
      T.K := tkStr;
      T.S := S;
      Add;
      Continue;
    end;
    { simbolos de dois caracteres }
    S := Copy(Texto, I, 2);
    if (S = ':=') or (S = '<=') or (S = '>=') or (S = '<>') or (S = '..') then
    begin
      T.K := tkSim;
      T.S := S;
      T.Low := S;
      Inc(I, 2);
      Add;
      Continue;
    end;
    if Ch in ['+', '-', '*', '/', '=', '<', '>', '(', ')', '[', ']', ',', ';', '.', ':'] then
    begin
      T.K := tkSim;
      T.S := Ch;
      T.Low := Ch;
      Inc(I);
      Add;
      Continue;
    end;
    R.Falha(Linha, 'caractere inesperado: ' + Ch);
  end;
  T.K := tkFim;
  T.S := '';
  T.Low := '';
  T.Linha := Linha;
  Add;
  SetLength(Toks, N);
  Pos := 0;
end;

function TAnalisador.Atual: TTok;
begin
  Result := Toks[Pos];
end;

function TAnalisador.Eh(const S: string): Boolean;
begin
  Result := (Toks[Pos].K in [tkId, tkSim]) and (Toks[Pos].Low = S);
end;

procedure TAnalisador.Pegar(const S: string);
begin
  if not Eh(S) then
    R.Falha(Atual.Linha, 'esperava "' + S + '" e encontrou "' + Atual.S + '"');
  Inc(Pos);
end;

function TAnalisador.PegarId: string;
begin
  if Atual.K <> tkId then R.Falha(Atual.Linha, 'esperava um nome e encontrou "' + Atual.S + '"');
  Result := Atual.S;
  Inc(Pos);
end;

function TAnalisador.BuscaLocal(const Nome: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(R.FNomesLocais) do
    if SameText(R.FNomesLocais[I], Nome) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

const
  Reservadas: array[0..20] of string = ('begin', 'end', 'if', 'then', 'else', 'for', 'to',
    'downto', 'do', 'case', 'of', 'not', 'and', 'or', 'xor', 'div', 'mod', 'shl', 'shr', 'in',
    'var');

function EhReservada(const S: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Reservadas) do
    if S = Reservadas[I] then
    begin
      Result := True;
      Exit;
    end;
  Result := (S = 'repeat') or (S = 'until') or (S = 'while');
end;

procedure TAnalisador.Declaracoes;
var
  Nomes: array of string;
  I, J: Integer;
  T: TTipoDado;
  Tipo: string;
begin
  while Eh('var') do
  begin
    Pegar('var');
    while (Atual.K = tkId) and not EhReservada(Atual.Low) and (Pos + 1 < Length(Toks)) and
          ((Toks[Pos + 1].S = ',') or (Toks[Pos + 1].S = ':')) do
    begin
      SetLength(Nomes, 0);
      repeat
        SetLength(Nomes, Length(Nomes) + 1);
        Nomes[High(Nomes)] := PegarId;
        if Eh(',') then Pegar(',') else Break;
      until False;
      Pegar(':');
      Tipo := PegarId;
      T := TipoPorNome(Tipo);
      if T = tdNenhum then R.Falha(Toks[Pos - 1].Linha, 'tipo desconhecido: ' + Tipo);
      Pegar(';');
      for I := 0 to High(Nomes) do
      begin
        if BuscaLocal(Nomes[I]) >= 0 then R.Falha(Toks[Pos - 1].Linha, 'variavel repetida: ' + Nomes[I]);
        J := Length(R.FNomesLocais);
        SetLength(R.FNomesLocais, J + 1);
        SetLength(R.FTiposLocais, J + 1);
        R.FNomesLocais[J] := Nomes[I];
        R.FTiposLocais[J] := T;
      end;
    end;
  end;
end;

function TAnalisador.Expr: Integer;
var
  Tmp: Integer;
  Op, N: Integer;
  L: Integer;
begin
  Result := Simples;
  while True do
  begin
    if Eh('=') then Op := opIgual
    else if Eh('<>') then Op := opDif
    else if Eh('<') then Op := opMenor
    else if Eh('>') then Op := opMaior
    else if Eh('<=') then Op := opMenorIg
    else if Eh('>=') then Op := opMaiorIg
    else if Eh('in') then Op := opIn
    else Break;
    L := Atual.Linha;
    Inc(Pos);
    N := R.Novo(nBin, L);
    R.FNos[N].Op := Op;
    R.FNos[N].A := Result;
    Tmp := Simples;
    R.FNos[N].B := Tmp;
    if (Op = opIn) and (R.FNos[R.FNos[N].B].T <> nConj) then
      R.Falha(L, 'depois de "in" vem um conjunto: [a, b, ...]');
    Result := N;
  end;
end;

function TAnalisador.Simples: Integer;
var
  Tmp: Integer;
  Op, N, L: Integer;
begin
  Result := Termo;
  while True do
  begin
    if Eh('+') then Op := opMais
    else if Eh('-') then Op := opMenos
    else if Eh('or') then Op := opOr
    else if Eh('xor') then Op := opXor
    else Break;
    L := Atual.Linha;
    Inc(Pos);
    N := R.Novo(nBin, L);
    R.FNos[N].Op := Op;
    R.FNos[N].A := Result;
    Tmp := Termo;
    R.FNos[N].B := Tmp;
    Result := N;
  end;
end;

function TAnalisador.Termo: Integer;
var
  Tmp: Integer;
  Op, N, L: Integer;
begin
  Result := Fator;
  while True do
  begin
    if Eh('*') then Op := opVezes
    else if Eh('/') then Op := opBarra
    else if Eh('div') then Op := opDiv
    else if Eh('mod') then Op := opMod
    else if Eh('and') then Op := opAnd
    else if Eh('shl') then Op := opShl
    else if Eh('shr') then Op := opShr
    else Break;
    L := Atual.Linha;
    Inc(Pos);
    N := R.Novo(nBin, L);
    R.FNos[N].Op := Op;
    R.FNos[N].A := Result;
    Tmp := Fator;
    R.FNos[N].B := Tmp;
    Result := N;
  end;
end;

function TAnalisador.Fator: Integer;
var
  Tmp: Integer;
  T: TTok;
  N, I, K, L, E: Integer;
  Nome: string;
  Achou: Boolean;
begin
  T := Atual;
  L := T.Linha;
  if Eh('(') then
  begin
    Pegar('(');
    Result := Expr;
    Pegar(')');
    Exit;
  end;
  if Eh('-') or Eh('+') or Eh('not') then
  begin
    Inc(Pos);
    N := R.Novo(nUn, L);
    if T.Low = '-' then R.FNos[N].Op := opNeg
    else if T.Low = '+' then R.FNos[N].Op := opPos
    else R.FNos[N].Op := opNot;
    Tmp := Fator;
    R.FNos[N].A := Tmp;
    Result := N;
    Exit;
  end;
  if T.K = tkInt then
  begin
    Inc(Pos);
    N := R.Novo(nConst, L);
    R.FNos[N].V := VInt(T.I, (T.I > High(LongInt)) or (T.I < Low(LongInt)));
    Result := N;
    Exit;
  end;
  if T.K = tkReal then
  begin
    Inc(Pos);
    N := R.Novo(nConst, L);
    R.FNos[N].V := VReal(T.F);
    Result := N;
    Exit;
  end;
  if T.K = tkStr then
  begin
    Inc(Pos);
    N := R.Novo(nConst, L);
    R.FNos[N].V := VStr(T.S);
    Result := N;
    Exit;
  end;
  if Eh('[') then
  begin
    Pegar('[');
    N := R.Novo(nConj, L);
    if not Eh(']') then
      repeat
        E := Expr;
        if Eh('..') then
        begin
          Pegar('..');
          K := R.Novo(nFaixa, L);
          R.FNos[K].A := E;
          Tmp := Expr;
          R.FNos[K].B := Tmp;
          E := K;
        end;
        SetLength(R.FNos[N].Lista, Length(R.FNos[N].Lista) + 1);
        R.FNos[N].Lista[High(R.FNos[N].Lista)] := E;
        if Eh(',') then Pegar(',') else Break;
      until False;
    Pegar(']');
    Result := N;
    Exit;
  end;
  if (T.K <> tkId) or EhReservada(T.Low) then
    R.Falha(L, 'expressao inesperada: "' + T.S + '"');
  Nome := PegarId;
  { campo do lutador ou do oponente }
  if (SameText(Nome, 'P') or SameText(Nome, 'O')) and Eh('.') then
  begin
    Pegar('.');
    Nome := PegarId;
    N := R.Novo(nCampo, L);
    if SameText(T.S, 'O') then R.FNos[N].Base := 1 else R.FNos[N].Base := 0;
    R.FNos[N].Ind := -1;
    for I := 0 to High(Campos) do
      if SameText(Campos[I].Nome, Nome) then R.FNos[N].Ind := I;
    if R.FNos[N].Ind < 0 then R.Falha(L, 'campo desconhecido: ' + T.S + '.' + Nome);
    Result := N;
    Exit;
  end;
  { funcao }
  if Eh('(') then
  begin
    N := R.Novo(nFunc, L);
    R.FNos[N].Op := 0;
    for I := 1 to High(NomesFuncoes) do
      if SameText(NomesFuncoes[I], Nome) then R.FNos[N].Op := I;
    if R.FNos[N].Op = 0 then R.Falha(L, 'funcao desconhecida: ' + Nome);
    Pegar('(');
    if not Eh(')') then
      repeat
        E := Expr;
        SetLength(R.FNos[N].Lista, Length(R.FNos[N].Lista) + 1);
        R.FNos[N].Lista[High(R.FNos[N].Lista)] := E;
        if Eh(',') then Pegar(',') else Break;
      until False;
    Pegar(')');
    if Length(R.FNos[N].Lista) <> ArgsFuncoes[R.FNos[N].Op] then
      R.Falha(L, Format('%s pede %d argumento(s)', [Nome, ArgsFuncoes[R.FNos[N].Op]]));
    Result := N;
    Exit;
  end;
  { True/False }
  if SameText(Nome, 'True') or SameText(Nome, 'False') then
  begin
    N := R.Novo(nConst, L);
    R.FNos[N].V := VBool(SameText(Nome, 'True'));
    Result := N;
    Exit;
  end;
  { variavel local }
  I := BuscaLocal(Nome);
  if I >= 0 then
  begin
    N := R.Novo(nLocal, L);
    R.FNos[N].Ind := I;
    Result := N;
    Exit;
  end;
  { variavel do jogo }
  for I := 0 to High(Globais) do
    if SameText(Globais[I].Nome, Nome) then
    begin
      N := R.Novo(nGlobal, L);
      R.FNos[N].Ind := I;
      Result := N;
      Exit;
    end;
  { constante }
  Achou := False;
  N := -1;
  for I := 0 to QtdConstantes - 1 do
    if SameText(Constantes[I].N, Nome) then
    begin
      N := R.Novo(nConst, L);
      R.FNos[N].V := VInt(Constantes[I].V, False);
      Achou := True;
      Break;
    end;
  if not Achou then R.Falha(L, 'nome desconhecido: ' + Nome);
  Result := N;
end;

function TAnalisador.ListaAte(const Fim1, Fim2: string): Integer;
var
  N, C: Integer;
begin
  N := R.Novo(cBloco, Atual.Linha);
  while True do
  begin
    if Eh(Fim1) or ((Fim2 <> '') and Eh(Fim2)) or (Atual.K = tkFim) then Break;
    if Eh(';') then
    begin
      Pegar(';');
      Continue;
    end;
    C := Comando;
    SetLength(R.FNos[N].Lista, Length(R.FNos[N].Lista) + 1);
    R.FNos[N].Lista[High(R.FNos[N].Lista)] := C;
    if Eh(';') then
      Pegar(';')
    else if not (Eh(Fim1) or ((Fim2 <> '') and Eh(Fim2)) or (Atual.K = tkFim)) then
      R.Falha(Atual.Linha, 'esperava ";" e encontrou "' + Atual.S + '"');
  end;
  Result := N;
end;

function TAnalisador.Comando: Integer;
var
  Tmp: Integer;
  N, L, Alvo, I, Ramo, E: Integer;
  Nome: string;
begin
  L := Atual.Linha;
  if Eh('begin') then
  begin
    Pegar('begin');
    Result := ListaAte('end', '');
    Pegar('end');
    Exit;
  end;
  if Eh('if') then
  begin
    Pegar('if');
    N := R.Novo(cSe, L);
    Tmp := Expr;
    R.FNos[N].A := Tmp;
    Pegar('then');
    if Eh('else') or Eh(';') or Eh('end') then
      Tmp := R.Novo(cBloco, L)
    else
      Tmp := Comando;
    R.FNos[N].B := Tmp;
    R.FNos[N].C := -1;
    if Eh('else') then
    begin
      Pegar('else');
      Tmp := Comando;
      R.FNos[N].C := Tmp;
    end;
    Result := N;
    Exit;
  end;
  if Eh('for') then
  begin
    Pegar('for');
    Nome := PegarId;
    I := BuscaLocal(Nome);
    if I < 0 then R.Falha(L, 'a variavel do for precisa ser declarada com var: ' + Nome);
    N := R.Novo(cPara, L);
    R.FNos[N].Ind := I;
    Pegar(':=');
    Tmp := Expr;
    R.FNos[N].A := Tmp;
    if Eh('to') then
    begin
      Pegar('to');
      R.FNos[N].Op := 1;
    end
    else
    begin
      Pegar('downto');
      R.FNos[N].Op := -1;
    end;
    Tmp := Expr;
    R.FNos[N].B := Tmp;
    Pegar('do');
    Tmp := Comando;
    R.FNos[N].C := Tmp;
    Result := N;
    Exit;
  end;
  if Eh('repeat') then
  begin
    Pegar('repeat');
    N := R.Novo(cRepita, L);
    Tmp := ListaAte('until', '');
    R.FNos[N].B := Tmp;
    Pegar('until');
    Tmp := Expr;
    R.FNos[N].A := Tmp;
    Result := N;
    Exit;
  end;
  if Eh('while') then
  begin
    Pegar('while');
    N := R.Novo(cEnquanto, L);
    Tmp := Expr;
    R.FNos[N].A := Tmp;
    Pegar('do');
    Tmp := Comando;
    R.FNos[N].B := Tmp;
    Result := N;
    Exit;
  end;
  if Eh('case') then
  begin
    Pegar('case');
    N := R.Novo(cCaso, L);
    Tmp := Expr;
    R.FNos[N].A := Tmp;
    R.FNos[N].B := -1;
    Pegar('of');
    while not Eh('end') do
    begin
      if Eh('else') then
      begin
        Pegar('else');
        Tmp := ListaAte('end', '');
        R.FNos[N].B := Tmp;
        Break;
      end;
      Ramo := R.Novo(cRamo, Atual.Linha);
      repeat
        E := Expr;
        if Eh('..') then
        begin
          Pegar('..');
          I := R.Novo(nFaixa, L);
          R.FNos[I].A := E;
          Tmp := Expr;
          R.FNos[I].B := Tmp;
          E := I;
        end;
        SetLength(R.FNos[Ramo].Lista, Length(R.FNos[Ramo].Lista) + 1);
        R.FNos[Ramo].Lista[High(R.FNos[Ramo].Lista)] := E;
        if Eh(',') then Pegar(',') else Break;
      until False;
      Pegar(':');
      Tmp := Comando;
      R.FNos[Ramo].A := Tmp;
      SetLength(R.FNos[N].Lista, Length(R.FNos[N].Lista) + 1);
      R.FNos[N].Lista[High(R.FNos[N].Lista)] := Ramo;
      if Eh(';') then Pegar(';');
    end;
    Pegar('end');
    Result := N;
    Exit;
  end;
  { atribuicao ou chamada }
  Alvo := Fator;
  if Eh(':=') then
  begin
    if not (R.FNos[Alvo].T in [nLocal, nGlobal, nCampo]) then
      R.Falha(L, 'so da para atribuir a variaveis e campos');
    Pegar(':=');
    N := R.Novo(cAtrib, L);
    R.FNos[N].A := Alvo;
    Tmp := Expr;
    R.FNos[N].B := Tmp;
    Result := N;
    Exit;
  end;
  if R.FNos[Alvo].T <> nFunc then R.Falha(L, 'comando invalido');
  N := R.Novo(cChamada, L);
  R.FNos[N].A := Alvo;
  Result := N;
end;

{ ================= TRoteiro ================= }

function TRoteiro.Novo(T: TTipoNo; Linha: Integer): Integer;
begin
  Result := FQtdNos;
  if FQtdNos >= Length(FNos) then SetLength(FNos, FQtdNos * 2 + 64);
  Inc(FQtdNos);
  FNos[Result].T := T;
  FNos[Result].Op := 0;
  FNos[Result].Ind := 0;
  FNos[Result].Base := 0;
  FNos[Result].A := -1;
  FNos[Result].B := -1;
  FNos[Result].C := -1;
  FNos[Result].Lista := nil;
  FNos[Result].V := VInt(0, False);
  FNos[Result].Linha := Linha;
end;

procedure TRoteiro.Falha(Linha: Integer; const Msg: string);
begin
  raise ERoteiro.CreateFmt('%s, linha %d: %s', [FOrigem, Linha, Msg]);
end;

constructor TRoteiro.Create(const Texto, Origem: string; LinhaInicial: Integer);
var
  A: TAnalisador;
begin
  inherited Create;
  FOrigem := Origem;
  SetLength(FNomesLocais, QtdPredef);
  SetLength(FTiposLocais, QtdPredef);
  FNomesLocais[LocalJog] := 'Jog';
  FTiposLocais[LocalJog] := tdByte;
  FNomesLocais[LocalCodigo] := 'Codigo';
  FTiposLocais[LocalCodigo] := tdByte;
  FNomesLocais[LocalDesloc] := 'Desloc';
  FTiposLocais[LocalDesloc] := tdInteger;
  A := TAnalisador.Create(Self, Texto, LinhaInicial);
  try
    A.Declaracoes;
    FRaiz := A.ListaAte('', '');
    if A.Atual.K <> tkFim then Falha(A.Atual.Linha, 'texto sobrando: "' + A.Atual.S + '"');
  finally
    A.Free;
  end;
end;

{ ================= execucao ================= }

type
  TExecucao = record
    R: TRoteiro;
    P, O: PLutador;
    Locais: array of TValor;
  end;

procedure ErroExec(var X: TExecucao; No: Integer; const Msg: string);
begin
  raise ERoteiro.CreateFmt('%s, linha %d: %s', [X.R.FOrigem, X.R.FNos[No].Linha, Msg]);
end;

function Avaliar(var X: TExecucao; No: Integer): TValor; forward;
procedure Executar1(var X: TExecucao; No: Integer); forward;

function ComoReal(var X: TExecucao; No: Integer; const V: TValor): Extended;
begin
  if V.C = cvReal then Result := V.F
  else if V.C = cvInt then Result := V.I
  else
  begin
    Result := 0;
    ErroExec(X, No, 'esperava um numero');
  end;
end;

function ComoInt(var X: TExecucao; No: Integer; const V: TValor): Int64;
begin
  if V.C = cvInt then Result := V.I
  else
  begin
    Result := 0;
    ErroExec(X, No, 'esperava um numero inteiro');
  end;
end;

function ComoBool(var X: TExecucao; No: Integer; const V: TValor): Boolean;
begin
  if V.C = cvBool then Result := V.I <> 0
  else
  begin
    Result := False;
    ErroExec(X, No, 'esperava uma condicao (verdadeiro/falso)');
  end;
end;

function PtrCampo(var X: TExecucao; No: Integer): Pointer;
var
  Base: PLutador;
begin
  if X.R.FNos[No].Base = 1 then Base := X.O else Base := X.P;
  Result := PByte(Base) + Campos[X.R.FNos[No].Ind].Desl;
end;

function Comparar(var X: TExecucao; No: Integer; Op: Integer; const A, B: TValor): Boolean;
var
  FA, FB: Extended;
  IA, IB: Int64;
begin
  if (A.C = cvStr) or (B.C = cvStr) then
  begin
    if (A.C <> cvStr) or (B.C <> cvStr) then ErroExec(X, No, 'comparacao de texto com numero');
    case Op of
      opIgual: Result := A.S = B.S;
      opDif: Result := A.S <> B.S;
    else
      Result := False;
      ErroExec(X, No, 'textos so comparam com = e <>');
    end;
    Exit;
  end;
  if (A.C = cvBool) or (B.C = cvBool) then
  begin
    if (A.C <> cvBool) or (B.C <> cvBool) then ErroExec(X, No, 'comparacao de condicao com numero');
    IA := A.I;
    IB := B.I;
  end
  else if (A.C = cvReal) or (B.C = cvReal) then
  begin
    FA := ComoReal(X, No, A);
    FB := ComoReal(X, No, B);
    case Op of
      opIgual: Result := FA = FB;
      opDif: Result := FA <> FB;
      opMenor: Result := FA < FB;
      opMaior: Result := FA > FB;
      opMenorIg: Result := FA <= FB;
      opMaiorIg: Result := FA >= FB;
    else
      Result := False;
    end;
    Exit;
  end
  else
  begin
    IA := A.I;
    IB := B.I;
  end;
  case Op of
    opIgual: Result := IA = IB;
    opDif: Result := IA <> IB;
    opMenor: Result := IA < IB;
    opMaior: Result := IA > IB;
    opMenorIg: Result := IA <= IB;
    opMaiorIg: Result := IA >= IB;
  else
    Result := False;
  end;
end;

function NoConjunto(var X: TExecucao; Conj: Integer; const V: TValor): Boolean;
var
  I, E: Integer;
  A, B: TValor;
begin
  Result := False;
  for I := 0 to High(X.R.FNos[Conj].Lista) do
  begin
    E := X.R.FNos[Conj].Lista[I];
    if X.R.FNos[E].T = nFaixa then
    begin
      A := Avaliar(X, X.R.FNos[E].A);
      B := Avaliar(X, X.R.FNos[E].B);
      if (ComoInt(X, E, V) >= ComoInt(X, E, A)) and (ComoInt(X, E, V) <= ComoInt(X, E, B)) then
      begin
        Result := True;
        Exit;
      end;
    end
    else
    begin
      A := Avaliar(X, E);
      if ComoInt(X, E, V) = ComoInt(X, E, A) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function AvaliarBin(var X: TExecucao; No: Integer): TValor;
var
  Op: Integer;
  A, B: TValor;
  FA, FB: Extended;
begin
  Op := X.R.FNos[No].Op;
  A := Avaliar(X, X.R.FNos[No].A);
  { and/or com condicoes: param assim que o resultado e conhecido }
  if (Op in [opAnd, opOr]) and (A.C = cvBool) then
  begin
    if (Op = opAnd) and (A.I = 0) then
    begin
      Result := VBool(False);
      Exit;
    end;
    if (Op = opOr) and (A.I <> 0) then
    begin
      Result := VBool(True);
      Exit;
    end;
    B := Avaliar(X, X.R.FNos[No].B);
    Result := VBool(ComoBool(X, No, B));
    Exit;
  end;
  if Op = opIn then
  begin
    Result := VBool(NoConjunto(X, X.R.FNos[No].B, A));
    Exit;
  end;
  B := Avaliar(X, X.R.FNos[No].B);
  if Op in [opIgual, opDif, opMenor, opMaior, opMenorIg, opMaiorIg] then
  begin
    Result := VBool(Comparar(X, No, Op, A, B));
    Exit;
  end;
  if Op in [opAnd, opOr, opXor] then
  begin
    if B.C = cvBool then
    begin
      if Op = opXor then Result := VBool((A.I <> 0) xor (ComoBool(X, No, B)))
      else ErroExec(X, No, 'and/or misturando condicao e numero');
      Exit;
    end;
    case Op of
      opAnd: Result := VInt(ComoInt(X, No, A) and ComoInt(X, No, B), A.Largo or B.Largo);
      opOr: Result := VInt(ComoInt(X, No, A) or ComoInt(X, No, B), A.Largo or B.Largo);
    else
      Result := VInt(ComoInt(X, No, A) xor ComoInt(X, No, B), A.Largo or B.Largo);
    end;
    Exit;
  end;
  if (Op = opBarra) or (A.C = cvReal) or (B.C = cvReal) then
  begin
    if Op in [opDiv, opMod, opShl, opShr] then ErroExec(X, No, 'div, mod, shl e shr sao so para inteiros');
    FA := ComoReal(X, No, A);
    FB := ComoReal(X, No, B);
    case Op of
      opMais: Result := VReal(FA + FB);
      opMenos: Result := VReal(FA - FB);
      opVezes: Result := VReal(FA * FB);
    else
      Result := VReal(FA / FB);
    end;
    Exit;
  end;
  case Op of
    opMais: Result := VInt(ComoInt(X, No, A) + ComoInt(X, No, B), A.Largo or B.Largo);
    opMenos: Result := VInt(ComoInt(X, No, A) - ComoInt(X, No, B), A.Largo or B.Largo);
    opVezes: Result := VInt(ComoInt(X, No, A) * ComoInt(X, No, B), A.Largo or B.Largo);
    opDiv: Result := VInt(ComoInt(X, No, A) div ComoInt(X, No, B), A.Largo or B.Largo);
    opMod: Result := VInt(ComoInt(X, No, A) mod ComoInt(X, No, B), A.Largo or B.Largo);
    opShl: Result := VInt(ComoInt(X, No, A) shl ComoInt(X, No, B), A.Largo);
    opShr: Result := VInt(ComoInt(X, No, A) shr ComoInt(X, No, B), A.Largo);
  else
    Result := VInt(0, False);
    ErroExec(X, No, 'operador invalido');
  end;
end;

function Chamar(var X: TExecucao; No: Integer): TValor;
var
  F, I, N: Integer;
  Args: array[0..4] of TValor;
begin
  F := X.R.FNos[No].Op;
  N := Length(X.R.FNos[No].Lista);
  { argumentos na mesma ordem em que o compilador os avalia }
  if OrdemArgsInversa then
    for I := N - 1 downto 0 do Args[I] := Avaliar(X, X.R.FNos[No].Lista[I])
  else
    for I := 0 to N - 1 do Args[I] := Avaliar(X, X.R.FNos[No].Lista[I]);
  Result := VInt(0, False);
  case F of
    fRandom: Result := VInt(SortearValor(ComoInt(X, No, Args[0]), Args[0].Largo), Args[0].Largo);
    fRound: Result := VInt(Round(ComoReal(X, No, Args[0])), True);
    fTrunc: Result := VInt(Trunc(ComoReal(X, No, Args[0])), True);
    fAbs:
      if Args[0].C = cvInt then Result := VInt(Abs(Args[0].I), Args[0].Largo)
      else Result := VReal(Abs(ComoReal(X, No, Args[0])));
    fCos: Result := VReal(Cos(ComoReal(X, No, Args[0])));
    fSin: Result := VReal(Sin(ComoReal(X, No, Args[0])));
    fShortInt: Result := VInt(ShortInt(ComoInt(X, No, Args[0])), False);
    fExisteEfeito:
      Result := VBool(ExisteEfeito(Byte(ComoInt(X, No, Args[0])), Byte(ComoInt(X, No, Args[1]))));
    fCriaEfeito:
      begin
        if Args[1].C <> cvStr then ErroExec(X, No, 'o 2o argumento de CriaEfeito e um texto');
        CriaEfeito(Byte(ComoInt(X, No, Args[0])), Args[1].S, Byte(ComoInt(X, No, Args[2])),
          ComoReal(X, No, Args[3]), ComoReal(X, No, Args[4]));
      end;
    fEmpurra: Empurra(Byte(ComoInt(X, No, Args[0])), ComoReal(X, No, Args[1]));
    fAcaoJogador: AcaoJogador(Byte(ComoInt(X, No, Args[0])), Byte(ComoInt(X, No, Args[1])));
    fAplicarCaixas: AplicarCaixas(Byte(ComoInt(X, No, Args[0])));
  end;
end;

function Avaliar(var X: TExecucao; No: Integer): TValor;
var
  V: TValor;
begin
  case X.R.FNos[No].T of
    nConst: Result := X.R.FNos[No].V;
    nLocal: Result := X.Locais[X.R.FNos[No].Ind];
    nGlobal: Result := LerMem(Globais[X.R.FNos[No].Ind].Tipo, Globais[X.R.FNos[No].Ind].Ender);
    nCampo: Result := LerMem(Campos[X.R.FNos[No].Ind].Tipo, PtrCampo(X, No));
    nUn:
      begin
        V := Avaliar(X, X.R.FNos[No].A);
        case X.R.FNos[No].Op of
          opNeg:
            if V.C = cvReal then Result := VReal(-V.F)
            else Result := VInt(-ComoInt(X, No, V), V.Largo);
          opPos:
            begin
              if not (V.C in [cvInt, cvReal]) then ErroExec(X, No, 'esperava um numero');
              Result := V;
            end;
        else
          if V.C = cvBool then Result := VBool(V.I = 0)
          else Result := VInt(not ComoInt(X, No, V), V.Largo);
        end;
      end;
    nBin: Result := AvaliarBin(X, No);
    nFunc:
      begin
        if ProcFuncoes[X.R.FNos[No].Op] then
          ErroExec(X, No, NomesFuncoes[X.R.FNos[No].Op] + ' nao devolve valor');
        Result := Chamar(X, No);
      end;
  else
    Result := VInt(0, False);
    ErroExec(X, No, 'expressao invalida');
  end;
end;

procedure Atribuir(var X: TExecucao; No: Integer; const V: TValor);
var
  Alvo: Integer;
  R: TValor;
  T: TTipoDado;
begin
  Alvo := X.R.FNos[No].A;
  case X.R.FNos[Alvo].T of
    nLocal: T := X.R.FTiposLocais[X.R.FNos[Alvo].Ind];
    nGlobal: T := Globais[X.R.FNos[Alvo].Ind].Tipo;
  else
    T := Campos[X.R.FNos[Alvo].Ind].Tipo;
  end;
  if not Converter(T, V, R) then ErroExec(X, No, 'valor nao combina com o tipo da variavel');
  case X.R.FNos[Alvo].T of
    nLocal: X.Locais[X.R.FNos[Alvo].Ind] := R;
    nGlobal: GravarMem(T, Globais[X.R.FNos[Alvo].Ind].Ender, R);
  else
    GravarMem(T, PtrCampo(X, Alvo), R);
  end;
end;

procedure Executar1(var X: TExecucao; No: Integer);
var
  I: Integer;
  K, Ini, Fim: Int64;
  V: TValor;
  Achou: Boolean;
  Ramo, E: Integer;
begin
  case X.R.FNos[No].T of
    cBloco:
      for I := 0 to High(X.R.FNos[No].Lista) do Executar1(X, X.R.FNos[No].Lista[I]);
    cAtrib:
      Atribuir(X, No, Avaliar(X, X.R.FNos[No].B));
    cChamada:
      Chamar(X, X.R.FNos[No].A);
    cSe:
      if ComoBool(X, No, Avaliar(X, X.R.FNos[No].A)) then
        Executar1(X, X.R.FNos[No].B)
      else if X.R.FNos[No].C >= 0 then
        Executar1(X, X.R.FNos[No].C);
    cPara:
      begin
        Ini := ComoInt(X, No, Avaliar(X, X.R.FNos[No].A));
        Fim := ComoInt(X, No, Avaliar(X, X.R.FNos[No].B));
        if X.R.FNos[No].Op > 0 then
        begin
          K := Ini;
          while K <= Fim do
          begin
            if not Converter(X.R.FTiposLocais[X.R.FNos[No].Ind], VInt(K, False), V) then
              ErroExec(X, No, 'a variavel do for precisa ser inteira');
            X.Locais[X.R.FNos[No].Ind] := V;
            Executar1(X, X.R.FNos[No].C);
            Inc(K);
          end;
        end
        else
        begin
          K := Ini;
          while K >= Fim do
          begin
            if not Converter(X.R.FTiposLocais[X.R.FNos[No].Ind], VInt(K, False), V) then
              ErroExec(X, No, 'a variavel do for precisa ser inteira');
            X.Locais[X.R.FNos[No].Ind] := V;
            Executar1(X, X.R.FNos[No].C);
            Dec(K);
          end;
        end;
      end;
    cRepita:
      repeat
        Executar1(X, X.R.FNos[No].B);
      until ComoBool(X, No, Avaliar(X, X.R.FNos[No].A));
    cEnquanto:
      while ComoBool(X, No, Avaliar(X, X.R.FNos[No].A)) do
        Executar1(X, X.R.FNos[No].B);
    cCaso:
      begin
        V := Avaliar(X, X.R.FNos[No].A);
        K := ComoInt(X, No, V);
        Achou := False;
        for I := 0 to High(X.R.FNos[No].Lista) do
        begin
          Ramo := X.R.FNos[No].Lista[I];
          for E := 0 to High(X.R.FNos[Ramo].Lista) do
            if X.R.FNos[X.R.FNos[Ramo].Lista[E]].T = nFaixa then
            begin
              if (K >= ComoInt(X, No, Avaliar(X, X.R.FNos[X.R.FNos[Ramo].Lista[E]].A))) and
                 (K <= ComoInt(X, No, Avaliar(X, X.R.FNos[X.R.FNos[Ramo].Lista[E]].B))) then Achou := True;
            end
            else if K = ComoInt(X, No, Avaliar(X, X.R.FNos[Ramo].Lista[E])) then
              Achou := True;
          if Achou then
          begin
            Executar1(X, X.R.FNos[Ramo].A);
            Break;
          end;
        end;
        if not Achou and (X.R.FNos[No].B >= 0) then Executar1(X, X.R.FNos[No].B);
      end;
  else
    ErroExec(X, No, 'comando invalido');
  end;
end;

procedure TRoteiro.Executar(Jog: Byte; Codigo: Integer);
var
  X: TExecucao;
  I: Integer;
begin
  X.R := Self;
  X.P := @Lutador[Jog];
  X.O := @Lutador[3 - Jog];
  SetLength(X.Locais, Length(FNomesLocais));
  for I := 0 to High(X.Locais) do
    if FTiposLocais[I] = tdDouble then X.Locais[I] := VReal(0)
    else if FTiposLocais[I] = tdBoolean then X.Locais[I] := VBool(False)
    else X.Locais[I] := VInt(0, FTiposLocais[I] = tdInt64);
  X.Locais[LocalJog] := VInt(Jog, False);
  X.Locais[LocalCodigo] := VInt(Byte(Codigo), False);
  if Jog = 2 then X.Locais[LocalDesloc] := VInt(50, False) else X.Locais[LocalDesloc] := VInt(0, False);
  Executar1(X, FRaiz);
end;

{ ================= arquivo de roteiro ================= }

function CarregarRoteiro(const Arquivo, Secao: string): TRoteiro;
var
  L: TStringList;
  I, Ini: Integer;
  S, Texto: string;
begin
  Result := nil;
  if not FileExists(Arquivo) then Exit;
  L := TStringList.Create;
  try
    L.LoadFromFile(Arquivo);
    Ini := -1;
    for I := 0 to L.Count - 1 do
    begin
      S := TrimRight(L[I]);
      if (Length(S) > 2) and (S[1] = '[') and (S[Length(S)] = ']') then
      begin
        if Ini >= 0 then Break;
        if SameText(Copy(S, 2, Length(S) - 2), Secao) then Ini := I + 1;
        Continue;
      end;
      { linha comecando com ; e comentario (como nos .ini) }
      if (Ini >= 0) and (Copy(TrimLeft(S), 1, 1) = ';') then
        Texto := Texto + #10
      else if Ini >= 0 then
        Texto := Texto + L[I] + #10;
    end;
    if Ini < 0 then Exit;
    Result := TRoteiro.Create(Texto, ExtractFileName(Arquivo) + ' [' + Secao + ']', Ini + 1);
  finally
    L.Free;
  end;
end;

{ ================= tabelas ================= }

function NomeCampoLutador(Desl: Integer): string;
var
  I: Integer;
  Melhor: PtrInt;
begin
  Result := Format('(byte %d)', [Desl]);
  Melhor := -1;
  for I := 0 to High(Campos) do
    if (Campos[I].Desl <= Desl) and (Campos[I].Desl > Melhor) then
    begin
      Melhor := Campos[I].Desl;
      Result := Campos[I].Nome;
    end;
end;

function TextoValor(const V: TValor): string;
begin
  case V.C of
    cvInt: Result := IntToStr(V.I);
    cvReal: Result := FloatToStr(V.F, FmtPonto);
    cvBool: Result := BoolToStr(V.I <> 0, 'True', 'False');
  else
    Result := V.S;
  end;
end;

function DiferencasLutador(const A, B: TLutador): string;
var
  I: Integer;
  VA, VB: string;
begin
  Result := '';
  for I := 0 to High(Campos) do
  begin
    VA := TextoValor(LerMem(Campos[I].Tipo, PByte(@A) + Campos[I].Desl));
    VB := TextoValor(LerMem(Campos[I].Tipo, PByte(@B) + Campos[I].Desl));
    if VA <> VB then Result := Result + ' ' + Campos[I].Nome + ' ' + VA + ' -> ' + VB + ';';
  end;
end;

function ResumoLutador(const L: TLutador): string;
var
  I: Integer;
const
  Nomes: array[0..10] of string = ('Acao', 'QuadroAcao', 'DuracaoAcao', 'Quadro', 'X', 'Y', 'VelY',
    'NoAr', 'Vida', 'ForcaGolpe', 'Lado');
var
  K: Integer;
begin
  Result := '';
  for K := 0 to High(Nomes) do
    for I := 0 to High(Campos) do
      if Campos[I].Nome = Nomes[K] then
        Result := Result + ' ' + Nomes[K] + '=' + TextoValor(LerMem(Campos[I].Tipo, PByte(@L) + Campos[I].Desl));
end;

var
  ModeloLutador: TLutador;

procedure Campo(const Nome: string; T: TTipoDado; Ender: Pointer);
var
  N: Integer;
begin
  N := Length(Campos);
  SetLength(Campos, N + 1);
  Campos[N].Nome := Nome;
  Campos[N].Tipo := T;
  Campos[N].Desl := PByte(Ender) - PByte(@ModeloLutador);
end;

procedure Global(const Nome: string; T: TTipoDado; Ender: Pointer);
var
  N: Integer;
begin
  N := Length(Globais);
  SetLength(Globais, N + 1);
  Globais[N].Nome := Nome;
  Globais[N].Tipo := T;
  Globais[N].Ender := Ender;
end;

var
  OrdemTeste: string;

function MarcaB(C: Char): Byte;
begin
  OrdemTeste := OrdemTeste + C;
  Result := 0;
end;

function MarcaD(C: Char): Double;
begin
  OrdemTeste := OrdemTeste + C;
  Result := Length(OrdemTeste);
end;

var
  SomaTeste: Double;

{ mesma assinatura de CriaEfeito: descobre em que ordem o compilador avalia os argumentos }
procedure TesteArgs(Tipo: Byte; const Texto: string; Dono: Byte; X, Y: Double);
begin
  SomaTeste := Tipo + Dono + X + Y + Length(Texto);
end;

procedure MontarTabelas;
var
  L: TLutador absolute ModeloLutador;
begin
  Campo('X', tdDouble, @L.X);
  Campo('Y', tdDouble, @L.Y);
  Campo('Personagem', tdByte, @L.Personagem);
  Campo('Angulo', tdSmallInt, @L.Angulo);
  Campo('VelAngular', tdSmallInt, @L.VelAngular);
  Campo('DistanciaIA', tdInteger, @L.DistanciaIA);
  Campo('CorpoX1', tdInteger, @L.CorpoX1);
  Campo('CorpoY1', tdInteger, @L.CorpoY1);
  Campo('CorpoX2', tdInteger, @L.CorpoX2);
  Campo('CorpoY2', tdInteger, @L.CorpoY2);
  Campo('AtaqueX1', tdInteger, @L.AtaqueX1);
  Campo('AtaqueY1', tdInteger, @L.AtaqueY1);
  Campo('AtaqueX2', tdInteger, @L.AtaqueX2);
  Campo('AtaqueY2', tdInteger, @L.AtaqueY2);
  Campo('Vida', tdDouble, @L.Vida);
  Campo('VidaBarra', tdDouble, @L.VidaBarra);
  Campo('AtrasoBarra', tdDouble, @L.AtrasoBarra);
  Campo('Poder', tdWord, @L.Poder);
  Campo('CargaPoder', tdDouble, @L.CargaPoder);
  Campo('GolpeAtivo', tdBoolean, @L.GolpeAtivo);
  Campo('EhChute', tdBoolean, @L.EhChute);
  Campo('NoAr', tdBoolean, @L.NoAr);
  Campo('Acao', tdByte, @L.Acao);
  Campo('Quadro', tdByte, @L.Quadro);
  Campo('Lado', tdByte, @L.Lado);
  Campo('DirPulo', tdByte, @L.DirPulo);
  Campo('ForcaGolpe', tdByte, @L.ForcaGolpe);
  Campo('DanoGolpe', tdByte, @L.DanoGolpe);
  Campo('DanoDefesa', tdByte, @L.DanoDefesa);
  Campo('Recuo', tdByte, @L.Recuo);
  Campo('QuadroAcao', tdSmallInt, @L.QuadroAcao);
  Campo('DuracaoAcao', tdSmallInt, @L.DuracaoAcao);
  Campo('VelY', tdShortInt, @L.VelY);
  Campo('AlturaSprite', tdWord, @L.AlturaSprite);
  Campo('Velocidade', tdDouble, @L.Velocidade);
  Campo('Pontos', tdInteger, @L.Pontos);
  Campo('RoundsVencidos', tdByte, @L.RoundsVencidos);
  Campo('FraseVitoria', tdByte, @L.FraseVitoria);
  Campo('MsgBonus', tdByte, @L.MsgBonus);
  Campo('TempoMsgBonus', tdByte, @L.TempoMsgBonus);
  Campo('DesenhaPorCima', tdBoolean, @L.DesenhaPorCima);
  Campo('Invulneravel', tdBoolean, @L.Invulneravel);
  Campo('Defendendo', tdBoolean, @L.Defendendo);
  Campo('AndandoFrente', tdBoolean, @L.AndandoFrente);
  Campo('Acertos', tdByte, @L.Acertos);
  Campo('TempoAcertos', tdByte, @L.TempoAcertos);
  Campo('MaxAcertos', tdByte, @L.MaxAcertos);
  Campo('SeqEstado', tdByte, @L.SeqEstado);
  Campo('SeqTempo', tdByte, @L.SeqTempo);
  Campo('TempoBaixo', tdByte, @L.TempoBaixo);
  Campo('TempoTras', tdByte, @L.TempoTras);
  Campo('CargaSoco', tdByte, @L.CargaSoco);
  Campo('CargaChute', tdByte, @L.CargaChute);
  Campo('Ativo', tdBoolean, @L.Ativo);

  Global('CameraX', tdInteger, @CameraX);
  Global('CameraY', tdInteger, @CameraY);
  Global('ChaoY', tdWord, @ChaoY);
  Global('ContPisca', tdByte, @ContPisca);
  Global('Flash', tdBoolean, @Flash);
  Global('FlashTela', tdByte, @FlashTela);
  Global('FlashVermelho', tdByte, @FlashVermelho);
  Global('GanhoCarga', tdDouble, @GanhoCarga);
  Global('NivelDano', tdDouble, @NivelDano);
  Global('PausaImpacto', tdByte, @PausaImpacto);
  Global('SomPendente', tdByte, @SomPendente);
  Global('TremorTela', tdByte, @TremorTela);
  Global('Gravidade', tdByte, @Gravidade);
  Global('NivelJogo', tdByte, @NivelJogo);
  Global('Fase', tdByte, @Fase);
  Global('Sangue', tdBoolean, @Sangue);
end;

initialization
  FmtPonto := DefaultFormatSettings;
  FmtPonto.DecimalSeparator := '.';
  MontarTabelas;
  OrdemTeste := '';
  TesteArgs(MarcaB('1'), '', MarcaB('3'), MarcaD('4'), MarcaD('5'));
  OrdemArgsInversa := System.Pos('5', OrdemTeste) < System.Pos('4', OrdemTeste);

end.
