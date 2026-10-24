{ ChavesConferencia.pas - conferencia de codigo antigo x roteiro novo.

  Conferir(Nome, Jog, Antigo, Novo) tira uma foto do estado da luta (os dois lutadores, os efeitos
  e algumas variaveis do jogo), roda Antigo gravando os sorteios, volta a foto, roda Novo repetindo
  os mesmos sorteios e compara o resultado. As diferencas (campo a campo, com os dois valores) vao
  para conferencia.log, gravado ao fechar o jogo. O jogo continua com o resultado de Novo.

  So e usado enquanto uma parte do codigo esta sendo passada para roteiro (diretiva
  CONFERIR_ROTEIRO); fora disso esta unidade nao faz nada. }

unit ChavesConferencia;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ChavesConst, ChavesTipos, ChavesRoteiro;

type
  TProcJogador = procedure(Jog: Byte);
  TMetodoJogador = procedure(Jog: Byte) of object;

{ Confere um trecho de codigo antigo contra o novo (procedimentos comuns): tira uma foto
  do estado da luta, roda Antigo gravando os sorteios, volta a foto, roda Novo repetindo os
  mesmos sorteios e anota as diferencas em conferencia.log. O jogo segue com o resultado de Novo.
  @param(Nome nome da rotina conferida (aparece no log))
  @param(Jog numero do lutador, 1 ou 2)
  @param(Antigo codigo original)
  @param(Novo codigo novo (roteiro)) }
procedure Conferir(const Nome: string; Jog: Byte; Antigo, Novo: TProcJogador);
{ O mesmo que Conferir, para metodos de TJogo. Uma conferencia dentro de outra roda so
  o caminho novo. Se Novo levantar excecao, o erro e anotado e o estado fica o de Antigo.
  @param(Nome nome da rotina conferida (aparece no log))
  @param(Jog numero do lutador, 1 ou 2)
  @param(Antigo codigo original)
  @param(Novo codigo novo (roteiro)) }
procedure ConferirMetodo(const Nome: string; Jog: Byte; Antigo, Novo: TMetodoJogador);

implementation

type
  { o que uma rotina da luta pode mudar }
  TFoto = record
    L: array[1..2] of TLutador;
    E: array[1..MaxEfeitos] of TEfeito;
    SomPendente, FlashTela, FlashVermelho, TremorTela, PausaImpacto: Byte;
    CameraX, CameraY: Integer;
    PrimeiroAtaque: Boolean;
  end;

var
  ConfVezes, ConfDiferencas: Integer;
  ConfNomes: string;
  ConfLog: TStringList;
  ConfDentro: Integer;

{ Conta uma diferenca e guarda a mensagem (no maximo 2000 linhas).
  @param(Msg linha do log) }
procedure Anotar(const Msg: string);
begin
  Inc(ConfDiferencas);
  if ConfLog = nil then ConfLog := TStringList.Create;
  if ConfLog.Count < 2000 then ConfLog.Add(Msg);
end;

{ Copia o estado que uma rotina da luta pode mudar (lutadores, efeitos, sons, flashes,
  camera...).
  @param(F recebe a foto) }
procedure TirarFoto(out F: TFoto);
begin
  Move(Lutador, F.L, SizeOf(Lutador));
  Move(Efeitos, F.E, SizeOf(Efeitos));
  F.SomPendente := SomPendente;
  F.FlashTela := FlashTela;
  F.FlashVermelho := FlashVermelho;
  F.TremorTela := TremorTela;
  F.PausaImpacto := PausaImpacto;
  F.CameraX := CameraX;
  F.CameraY := CameraY;
  F.PrimeiroAtaque := PrimeiroAtaque;
end;

{ Volta o estado da luta para o de uma foto.
  @param(F foto tirada por TirarFoto) }
procedure ReporFoto(const F: TFoto);
begin
  Move(F.L, Lutador, SizeOf(Lutador));
  Move(F.E, Efeitos, SizeOf(Efeitos));
  SomPendente := F.SomPendente;
  FlashTela := F.FlashTela;
  FlashVermelho := F.FlashVermelho;
  TremorTela := F.TremorTela;
  PausaImpacto := F.PausaImpacto;
  CameraX := F.CameraX;
  CameraY := F.CameraY;
  PrimeiroAtaque := F.PrimeiroAtaque;
end;

{ Compara duas fotos campo a campo.
  @param(A foto do caminho antigo)
  @param(B foto do caminho novo)
  @returns(as diferencas em texto; '' se forem iguais) }
function CompararFotos(const A, B: TFoto): string;
var
  J, I: Integer;
  D: string;
begin
  Result := '';
  for J := 1 to 2 do
    if not CompareMem(@A.L[J], @B.L[J], SizeOf(TLutador)) then
    begin
      D := DiferencasLutador(A.L[J], B.L[J]);
      if D = '' then D := ' (campo sem nome)';
      Result := Result + Format(' [lutador %d:%s]', [J, D]);
    end;
  for I := 1 to MaxEfeitos do
    if not CompareMem(@A.E[I], @B.E[I], SizeOf(TEfeito)) then
      Result := Result + Format(' [efeito %d: tipo %d/%d X %s/%s Y %s/%s]', [I, A.E[I].Tipo, B.E[I].Tipo,
        FloatToStr(A.E[I].X), FloatToStr(B.E[I].X), FloatToStr(A.E[I].Y), FloatToStr(B.E[I].Y)]);
  if A.SomPendente <> B.SomPendente then
    Result := Result + Format(' SomPendente %d -> %d;', [A.SomPendente, B.SomPendente]);
  if A.FlashTela <> B.FlashTela then Result := Result + ' FlashTela;';
  if A.FlashVermelho <> B.FlashVermelho then Result := Result + ' FlashVermelho;';
  if A.TremorTela <> B.TremorTela then Result := Result + ' TremorTela;';
  if A.PausaImpacto <> B.PausaImpacto then Result := Result + ' PausaImpacto;';
  if (A.CameraX <> B.CameraX) or (A.CameraY <> B.CameraY) then Result := Result + ' Camera;';
  if A.PrimeiroAtaque <> B.PrimeiroAtaque then Result := Result + ' PrimeiroAtaque;';
end;

procedure ConferirMetodo(const Nome: string; Jog: Byte; Antigo, Novo: TMetodoJogador);
var
  Antes, PeloAntigo, PeloNovo: TFoto;
  Msg: string;
begin
  { uma conferencia dentro da outra: so o caminho novo }
  if ConfDentro > 0 then
  begin
    Novo(Jog);
    Exit;
  end;
  Inc(ConfDentro);
  try
    if System.Pos(Nome, ConfNomes) = 0 then ConfNomes := ConfNomes + ' ' + Nome;
    TirarFoto(Antes);
    ModoDeSorteio(msGravar);
    Antigo(Jog);
    ModoDeSorteio(msNormal);
    TirarFoto(PeloAntigo);
    ReporFoto(Antes);
    ModoDeSorteio(msRepetir);
    Msg := '';
    try
      Novo(Jog);
    except
      on E: Exception do
      begin
        Msg := ' ERRO: ' + E.Message + ';';
        ReporFoto(PeloAntigo);
      end;
    end;
    if SorteiosRestantes > 0 then SorteioDivergiu := True;
    if SorteioDivergiu then Msg := Msg + ' sorteios diferentes;';
    ModoDeSorteio(msNormal);
    TirarFoto(PeloNovo);
    Inc(ConfVezes);
    Msg := Msg + CompararFotos(PeloAntigo, PeloNovo);
    if Msg <> '' then
      Anotar(Format('%s(%d), personagem %d; antes:%s; antigo -> novo:%s',
        [Nome, Jog, Antes.L[Jog].Personagem, ResumoLutador(Antes.L[Jog]), Msg]));
  finally
    Dec(ConfDentro);
  end;
end;

{ procedimentos comuns viram metodos de um objeto auxiliar }
type
  TAdaptador = class
    A, N: TProcJogador;
    { Chama o procedimento antigo guardado em A.
      @param(Jog numero do lutador) }
    procedure RodarAntigo(Jog: Byte);
    { Chama o procedimento novo guardado em N.
      @param(Jog numero do lutador) }
    procedure RodarNovo(Jog: Byte);
  end;

procedure TAdaptador.RodarAntigo(Jog: Byte);
begin
  A(Jog);
end;

procedure TAdaptador.RodarNovo(Jog: Byte);
begin
  N(Jog);
end;

procedure Conferir(const Nome: string; Jog: Byte; Antigo, Novo: TProcJogador);
var
  Ad: TAdaptador;
begin
  Ad := TAdaptador.Create;
  try
    Ad.A := Antigo;
    Ad.N := Novo;
    ConferirMetodo(Nome, Jog, Ad.RodarAntigo, Ad.RodarNovo);
  finally
    Ad.Free;
  end;
end;

initialization

finalization
  if ConfVezes > 0 then
  begin
    if ConfLog = nil then ConfLog := TStringList.Create;
    ConfLog.Insert(0, Format('Conferencia dos roteiros (%s): %d chamadas conferidas, %d diferencas.',
      [Trim(ConfNomes), ConfVezes, ConfDiferencas]));
    try
      ConfLog.SaveToFile('conferencia.log');
    except
    end;
  end;
  ConfLog.Free;

end.
