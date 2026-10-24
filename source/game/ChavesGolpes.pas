unit ChavesGolpes;

{ Logica dos lutadores durante a luta: acoes (pular, golpear, defender...), escolha do
  quadro de animacao, caixas de colisao, danos e efeitos.
  Recuperado do executavel original (unidades Unit29/Unit30 do projeto Delphi): as rotinas
  AcaoJogador e AtualizaQuadro foram convertidas automaticamente do codigo de maquina e
  depois revisadas; os nomes de campos estao em ChavesTipos.pas / NOMES.md.
  O centro do sprite e as caixas de colisao de cada quadro vem de Dados/Lutadores/Cnn.ini
  (secoes [CentroX], [Corpo] e [Ataque]). AcaoJogador e AtualizaQuadro executam os roteiros
  Dados/Lutadores/Comum.rot e CNN.rot (interpretados por ChavesRoteiro). }

{$mode delphi}{$H+}
{$POINTERMATH ON}

interface

uses
  Classes, SysUtils, Math, IniFiles, ChavesConst, ChavesTipos, ChavesDados;

const
  MaxQuadroLutador = 74;   // quadros por jogador na lista de imagens (1..74; o jogador 2 soma 50)

type
  { caixa x1,y1,x2,y2 relativa aos pes (y a partir do topo do sprite) }
  TCaixa = record
    Definida: Boolean;
    X1, Y1, X2, Y2: Integer;
  end;

  { caixa de ataque da acao Acao no quadro de acao QuadroAcao; CondForca <> 0 = so com essa ForcaGolpe }
  TCaixaAtaque = record
    Acao, QuadroAcao, CondForca: Integer;
    X1, Y1, X2, Y2: Integer;
    Ativo, Forca, Dano, DanoDefesa: Integer;
  end;

  { dados de quadros de um personagem (Dados/Lutadores/Cnn.ini) }
  TQuadrosLutador = record
    CentroX: array[0..MaxQuadroLutador] of Integer;
    Corpo: array[0..MaxQuadroLutador] of TCaixa;
    Ataques: array of TCaixaAtaque;      // na ordem do arquivo
  end;

  { campo de TEfeito que um tipo de efeito define ao ser criado }
  TCampoEfeito = (cfDuracao, cfVelY, cfFlag50, cfFlag51, cfFlag52, cfPodeAcertar, cfTerminando,
    cfVariante, cfLado, cfVel, cfDano, cfDanoDefesa, cfLimiteContagem, cfSprite, cfCaixa);

  { uma atribuicao feita ao criar o efeito (na ordem do arquivo) }
  TOpEfeito = record
    Campo: TCampoEfeito;
    Texto: string;          // '' = sempre; senao so quando o efeito e criado com esse texto
    DoDono: Boolean;        // valor = lado do lutador dono
    Chance: Integer;        // > 0: so atribui em 1 de cada Chance vezes (Sortear(Chance) = 0)
    Base, Passo, Sorteio: Integer;   // valor = Base + Passo * Sortear(Sorteio) (Sorteio = 0: Base)
    Caixa: array[0..3] of Integer;
  end;

  { termo de uma condicao de animacao: Variavel (Q quadro, C contagem) Op (Ref - K | K) }
  TTermoEfeito = record
    Variavel: Char;
    Op: string;
    Ref: Char;              // ' ' = numero; 'D' = Duracao - K; 'L' = LimiteContagem - K
    K: Integer;
  end;

  { regra de animacao: se todos os termos valem, faz a Acao }
  TRegraEfeito = record
    Termos: array of TTermoEfeito;
    Acao: Char;             // 'S' sprite := Valor; 'Q' quadro := 0; 'E' estagio; 'Y' sobe 1 pixel
    Valor: Integer;
  end;

  TTipoEfeito = record
    Ops: array of TOpEfeito;
    Regras: array of TRegraEfeito;
  end;

var
  QuadrosLutador: array of TQuadrosLutador;   // indice 1..quantidade de personagens
  TiposEfeito: array of TTipoEfeito;          // indice = tipo do efeito (1..)

{ Reserva os dados de Qtd personagens. }
procedure PrepararQuadrosLutadores(Qtd: Integer);
{ Le [CentroX], [Corpo] e [Ataque] do personagem Pers. }
procedure LerQuadrosLutador(Pers: Integer; Ini: TCustomIniFile);
{ Le os tipos de efeito (Dados/Efeitos.ini). }
procedure LerEfeitos(const Arquivo: string);
{ Regras de animacao do tipo do efeito (sprite, volta ao quadro 0, estagio...), a cada quadro. }
procedure AnimarEfeito(E: PEfeito);

{ Move o lutador Jog horizontalmente por Dx e o separa do oponente (nao deixa atravessar). }
procedure Empurra(Jog: Byte; Dx: Double);
{ Define a caixa de colisao do corpo quando o lutador esta no quadro (sprite) Quadro. }
procedure DefineCaixaCorpo(Jog, Quadro: Byte; X1, Y1, X2, Y2: Integer);
{ Define a caixa de ataque (e dano) quando o lutador esta na acao Acao, no quadro QuadroAcao. }
procedure DefineCaixaAtaque(Jog, Acao: Byte; QuadroAcao: Integer; X1, Y1, X2, Y2: Integer;
  Ativo, Forca, Dano, DanoDefesa: Byte);
procedure DefineCaixaEfeito(Slot, X1, Y1, X2, Y2: Integer);
{ True se ja existe um efeito deste Tipo criado por Dono (limita projeteis); sempre False com o truque Bruxa. }
function ExisteEfeito(Tipo, Dono: Byte): Boolean;
{ Cria um efeito (fumaca, sangue, bola de fogo, texto...) na primeira posicao livre. }
procedure CriaEfeito(Tipo: Byte; const Texto: string; Dono: Byte; X, Y: Double);
{ Deslocamento horizontal do centro do sprite atual do lutador (para desenhar centralizado). }
function CentroX(Jog: Byte): Integer;
{ Define as caixas de corpo e de ataque do quadro atual do lutador (antes: fim de AtualizaQuadro). }
procedure AplicarCaixas(Jog: Byte);
{ Le os roteiros dos lutadores: Comum (Dados/Lutadores/Comum.rot) e PadraoLutador com '##' (CNN.rot).
  Um erro de escrita num roteiro gera ERoteiro com o arquivo e a linha. }
procedure CarregarRoteiros(const PadraoLutador, Comum: string; Qtd: Integer);
{ Executa uma acao pedida ao lutador (andar, pular, golpe...); Codigo = comando (cm*).
  Roda o [Acao] de Comum.rot, o [Acao] do personagem e o [AcaoFim] de Comum.rot. }
procedure AcaoJogador(Jog, Codigo: Byte);
{ Avanca a animacao do lutador, escolhe o quadro e cria os efeitos de cada golpe: roda o [Quadro] de
  Comum.rot e o [Quadro] do personagem; depois aplica as caixas de colisao (AplicarCaixas). }
procedure AtualizaQuadro(Jog: Byte);

implementation

uses
  ChavesRoteiro;

{ Os sorteios desta unidade usam Sortear (ChavesRoteiro) no lugar de Random: e o mesmo Random do
  Pascal, mas pode gravar e repetir a sequencia no modo de conferencia. }

procedure PrepararQuadrosLutadores(Qtd: Integer);
begin
  SetLength(QuadrosLutador, 0);
  SetLength(QuadrosLutador, Qtd + 1);
end;

procedure LerQuadrosLutador(Pers: Integer; Ini: TCustomIniFile);
var
  Linhas, Partes, Chave: TStringList;
  I, Q: Integer;
  A: TCaixaAtaque;

  function Parte(K: Integer): Integer;
  begin
    if K < Partes.Count then Result := StrToIntDef(Partes[K], 0) else Result := 0;
  end;

begin
  if (Pers < 1) or (Pers > High(QuadrosLutador)) then Exit;
  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Chave := TStringList.Create;
  try
    with QuadrosLutador[Pers] do
    begin
      FillChar(CentroX, SizeOf(CentroX), 0);
      FillChar(Corpo, SizeOf(Corpo), 0);
      SetLength(Ataques, 0);
      { [CentroX] quadro=deslocamento }
      Ini.ReadSectionValues('CentroX', Linhas);
      for I := 0 to Linhas.Count - 1 do
      begin
        Q := StrToIntDef(Trim(Linhas.Names[I]), -1);
        if (Q >= 0) and (Q <= MaxQuadroLutador) then
          CentroX[Q] := StrToIntDef(Trim(Linhas.ValueFromIndex[I]), 0);
      end;
      { [Corpo] quadro=x1,y1,x2,y2 }
      Linhas.Clear;
      Ini.ReadSectionValues('Corpo', Linhas);
      for I := 0 to Linhas.Count - 1 do
      begin
        Q := StrToIntDef(Trim(Linhas.Names[I]), -1);
        if (Q < 0) or (Q > MaxQuadroLutador) then Continue;
        SepararLista(Linhas.ValueFromIndex[I], Partes);
        Corpo[Q].Definida := True;
        Corpo[Q].X1 := Parte(0);
        Corpo[Q].Y1 := Parte(1);
        Corpo[Q].X2 := Parte(2);
        Corpo[Q].Y2 := Parte(3);
      end;
      { [Ataque] acao.quadroAcao[.fN]=x1,y1,x2,y2,ativo,forca,dano,danoDefesa }
      Linhas.Clear;
      Ini.ReadSectionValues('Ataque', Linhas);
      Chave.Delimiter := '.';
      Chave.StrictDelimiter := True;
      for I := 0 to Linhas.Count - 1 do
      begin
        Chave.DelimitedText := Trim(Linhas.Names[I]);
        if Chave.Count < 2 then Continue;
        A.Acao := StrToIntDef(Chave[0], -1);
        A.QuadroAcao := StrToIntDef(Chave[1], -1);
        A.CondForca := 0;
        if (Chave.Count >= 3) and (Length(Chave[2]) >= 2) and (UpCase(Chave[2][1]) = 'F') then
          A.CondForca := StrToIntDef(Copy(Chave[2], 2, MaxInt), 0);
        SepararLista(Linhas.ValueFromIndex[I], Partes);
        A.X1 := Parte(0);
        A.Y1 := Parte(1);
        A.X2 := Parte(2);
        A.Y2 := Parte(3);
        A.Ativo := Parte(4);
        A.Forca := Parte(5);
        A.Dano := Parte(6);
        A.DanoDefesa := Parte(7);
        SetLength(Ataques, Length(Ataques) + 1);
        Ataques[High(Ataques)] := A;
      end;
    end;
  finally
    Chave.Free;
    Partes.Free;
    Linhas.Free;
  end;
end;

procedure LerEfeitos(const Arquivo: string);
const
  NomesCampo: array[TCampoEfeito] of string = ('Duracao', 'VelY', 'Flag50', 'Flag51', 'Flag52',
    'PodeAcertar', 'Terminando', 'Variante', 'Lado', 'Vel', 'Dano', 'DanoDefesa', 'LimiteContagem',
    'Sprite', 'Caixa');
var
  Ini: TMemIniFile;
  Linhas, Partes: TStringList;
  T, I, K, P: Integer;
  Secao, Chave, Valor, Esq, Termo: string;
  Op: TOpEfeito;
  Regra: TRegraEfeito;
  Campo: TCampoEfeito;
  Achou: Boolean;

  { "10", "10+R2", "-23-5*R5", "0+R10" }
  procedure LerValor(const S: string);
  var
    PR, PS: Integer;
  begin
    Op.Base := 0;
    Op.Passo := 0;
    Op.Sorteio := 0;
    PR := Pos('R', S);
    if PR = 0 then
    begin
      Op.Base := StrToIntDef(S, 0);
      Exit;
    end;
    Op.Sorteio := StrToIntDef(Copy(S, PR + 1, MaxInt), 0);
    Esq := Copy(S, 1, PR - 1);                // "10+", "-23-5*"
    Op.Passo := 1;
    if (Esq <> '') and (Esq[Length(Esq)] = '*') then
    begin
      Delete(Esq, Length(Esq), 1);            // "-23-5"
      PS := Length(Esq);
      while (PS > 1) and not (Esq[PS] in ['+', '-']) do Dec(PS);
      Op.Passo := StrToIntDef(Copy(Esq, PS, MaxInt), 1);   // "-5"
      Esq := Copy(Esq, 1, PS - 1);
    end
    else if Esq <> '' then
    begin
      if Esq[Length(Esq)] = '-' then Op.Passo := -1;
      Delete(Esq, Length(Esq), 1);
    end;
    Op.Base := StrToIntDef(Esq, 0);
  end;

  { "Q=2", "Q>=D-20", "C>=L-10" }
  function LerTermo(const S: string; out R: TTermoEfeito): Boolean;
  var
    N: Integer;
    Resto: string;
  begin
    Result := Length(S) >= 3;
    if not Result then Exit;
    R.Variavel := UpCase(S[1]);
    if S[3] = '=' then N := 2 else N := 1;
    R.Op := Copy(S, 2, N);
    Resto := Copy(S, 2 + N, MaxInt);
    R.Ref := ' ';
    if (Length(Resto) >= 2) and (UpCase(Resto[1]) in ['D', 'L']) and (Resto[2] = '-') then
    begin
      R.Ref := UpCase(Resto[1]);
      Resto := Copy(Resto, 3, MaxInt);
    end;
    R.K := StrToIntDef(Resto, 0);
  end;

begin
  SetLength(TiposEfeito, 1);
  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Ini := TMemIniFile.Create(Arquivo);
  try
    T := 1;
    while Ini.SectionExists('Efeito' + IntToStr(T)) do
    begin
      SetLength(TiposEfeito, T + 1);
      Secao := 'Efeito' + IntToStr(T);
      Linhas.Clear;
      Ini.ReadSectionValues(Secao, Linhas);
      for I := 0 to Linhas.Count - 1 do
      begin
        Chave := Trim(Linhas.Names[I]);
        Valor := Trim(Linhas.ValueFromIndex[I]);
        P := Pos('#', Chave);                  // Campo#2 = mesmo campo outra vez
        if P > 0 then Chave := Copy(Chave, 1, P - 1);
        { regra de animacao: AnimN=condicao:acao }
        if SameText(Copy(Chave, 1, 4), 'Anim') then
        begin
          P := Pos(':', Valor);
          if P = 0 then Continue;
          SetLength(Regra.Termos, 0);
          Esq := Copy(Valor, 1, P - 1);
          if Esq <> '*' then
          begin
            Esq := StringReplace(Esq, '&', ',', [rfReplaceAll]);
            SepararLista(Esq, Partes);
            for K := 0 to Partes.Count - 1 do
            begin
              Termo := Partes[K];
              SetLength(Regra.Termos, Length(Regra.Termos) + 1);
              LerTermo(Termo, Regra.Termos[High(Regra.Termos)]);
            end;
          end;
          Esq := UpperCase(Trim(Copy(Valor, P + 1, MaxInt)));
          Regra.Valor := 0;
          if Esq = 'SOBE' then Regra.Acao := 'Y'
          else
          begin
            Regra.Acao := Esq[1];
            Regra.Valor := StrToIntDef(Copy(Esq, 2, MaxInt), 0);
          end;
          with TiposEfeito[T] do
          begin
            SetLength(Regras, Length(Regras) + 1);
            Regras[High(Regras)] := Regra;
          end;
          Continue;
        end;
        { atribuicao ao criar: Campo[.Texto]=valor }
        Op.Texto := '';
        P := Pos('.', Chave);
        if P > 0 then
        begin
          Op.Texto := Copy(Chave, P + 1, MaxInt);
          Chave := Copy(Chave, 1, P - 1);
        end;
        Achou := False;
        for Campo := Low(TCampoEfeito) to High(TCampoEfeito) do
          if SameText(Chave, NomesCampo[Campo]) then
          begin
            Op.Campo := Campo;
            Achou := True;
          end;
        if not Achou then Continue;
        Op.DoDono := SameText(Valor, 'dono');
        Op.Chance := 0;
        FillChar(Op.Caixa, SizeOf(Op.Caixa), 0);
        if Op.Campo = cfCaixa then
        begin
          SepararLista(Valor, Partes);
          for K := 0 to 3 do
            if K < Partes.Count then Op.Caixa[K] := StrToIntDef(Partes[K], 0);
        end
        else if Pos(' em ', Valor) > 0 then
        begin
          P := Pos(' em ', Valor);
          Op.Base := StrToIntDef(Trim(Copy(Valor, 1, P - 1)), 0);
          Op.Chance := StrToIntDef(Trim(Copy(Valor, P + 4, MaxInt)), 0);
          Op.Passo := 0;
          Op.Sorteio := 0;
        end
        else if not Op.DoDono then
          LerValor(Valor);
        with TiposEfeito[T] do
        begin
          SetLength(Ops, Length(Ops) + 1);
          Ops[High(Ops)] := Op;
        end;
      end;
      Inc(T);
    end;
  finally
    Ini.Free;
    Partes.Free;
    Linhas.Free;
  end;
end;

{ Aplica ao efeito novo E (na posicao Slot) as atribuicoes do seu tipo, na ordem do arquivo.
  Os sorteios (Random) acontecem na mesma ordem do jogo original. }
procedure AplicarTipoEfeito(Slot: Integer; E: PEfeito; const Texto: string; Dono: Byte);
var
  I, V: Integer;
  Op: ^TOpEfeito;
begin
  if (E.Tipo < 1) or (E.Tipo > High(TiposEfeito)) then Exit;
  for I := 0 to High(TiposEfeito[E.Tipo].Ops) do
  begin
    Op := @TiposEfeito[E.Tipo].Ops[I];
    if (Op.Texto <> '') and (Op.Texto <> Texto) then Continue;
    if Op.Campo = cfCaixa then
    begin
      DefineCaixaEfeito(Slot, Op.Caixa[0], Op.Caixa[1], Op.Caixa[2], Op.Caixa[3]);
      Continue;
    end;
    if Op.DoDono then
      V := Lutador[Dono].Lado
    else if Op.Chance > 0 then
    begin
      if Sortear(Op.Chance) <> 0 then Continue;
      V := Op.Base;
    end
    else if Op.Sorteio > 0 then
      V := Op.Base + Op.Passo * Sortear(Op.Sorteio)
    else
      V := Op.Base;
    case Op.Campo of
      cfDuracao: E.Duracao := V;
      cfVelY: E.VelY := V;
      cfFlag50: E.Flag50 := V <> 0;
      cfFlag51: E.Flag51 := V <> 0;
      cfFlag52: E.Flag52 := V <> 0;
      cfPodeAcertar: E.PodeAcertar := V <> 0;
      cfTerminando: E.Terminando := V <> 0;
      cfVariante: E.Variante := V <> 0;
      cfLado: E.Lado := V;
      cfVel: E.Vel := V;
      cfDano: E.Dano := V;
      cfDanoDefesa: E.DanoDefesa := V;
      cfLimiteContagem: E.LimiteContagem := V;
      cfSprite: E.Sprite := V;
    end;
  end;
end;

procedure AnimarEfeito(E: PEfeito);
var
  I, T, X, R: Integer;
  Vale: Boolean;
  Regra: ^TRegraEfeito;
begin
  if (E.Tipo < 1) or (E.Tipo > High(TiposEfeito)) then Exit;
  for I := 0 to High(TiposEfeito[E.Tipo].Regras) do
  begin
    Regra := @TiposEfeito[E.Tipo].Regras[I];
    Vale := True;
    for T := 0 to High(Regra.Termos) do
      with Regra.Termos[T] do
      begin
        if Variavel = 'C' then X := E.Contagem else X := E.Quadro;
        case Ref of
          'D': R := E.Duracao - K;
          'L': R := E.LimiteContagem - K;
        else
          R := K;
        end;
        if Op = '=' then Vale := Vale and (X = R)
        else if Op = '<' then Vale := Vale and (X < R)
        else if Op = '>' then Vale := Vale and (X > R)
        else if Op = '<=' then Vale := Vale and (X <= R)
        else if Op = '>=' then Vale := Vale and (X >= R)
        else Vale := False;
      end;
    if not Vale then Continue;
    case Regra.Acao of
      'S': E.Sprite := Regra.Valor;
      'Q': E.Quadro := 0;
      'E': E.Estagio := True;
      'Y': if (FlashTela = 0) and (PausaImpacto = 0) then E.Y := E.Y - 1;
    end;
  end;
end;

procedure AplicarCaixas(Jog: Byte);
var
  P: PLutador;
  Idx, I: Integer;
begin
  P := @Lutador[Jog];
  if (P.Personagem < 1) or (P.Personagem > High(QuadrosLutador)) then Exit;
  with QuadrosLutador[P.Personagem] do
  begin
    { corpo: a caixa do quadro (sprite) atual }
    Idx := P.Quadro;
    if Jog = 2 then Idx := Idx - 50;
    if (Idx >= 0) and (Idx <= MaxQuadroLutador) and Corpo[Idx].Definida then
      DefineCaixaCorpo(Jog, P.Quadro, Corpo[Idx].X1, Corpo[Idx].Y1, Corpo[Idx].X2, Corpo[Idx].Y2);
    { ataque: em ordem, como no original (a forca pode mudar no meio) }
    for I := 0 to High(Ataques) do
      with Ataques[I] do
        if (CondForca = 0) or (P.ForcaGolpe = CondForca) then
          DefineCaixaAtaque(Jog, Acao, QuadroAcao, X1, Y1, X2, Y2, Ativo, Forca, Dano, DanoDefesa);
  end;
end;

procedure Empurra(Jog: Byte; Dx: Double);
var
  P, O: PLutador;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  P.X := P.X + Dx;
  // se as caixas do corpo se sobrepoem, separa os dois lutadores
  if (O.CorpoX2 + O.X > P.CorpoX1 + P.X) and (O.CorpoX1 + O.X < P.CorpoX2 + P.X) and
     (O.CorpoY2 + O.Y > P.CorpoY1 + P.Y) and (O.CorpoY1 + O.Y < P.CorpoY2 + P.Y) and
     (P.Acao <> acVitoria) and (P.Acao <> acQuicando) then
  begin
    if (P.X <= O.X) and not RelogioParado then
    begin
      O.X := O.X + 5;
      if O.X > CameraX + 370 then O.X := CameraX + 370;
      P.X := ((O.CorpoX1 + O.X) - P.CorpoX2) - 5;
    end;
    if (P.X > O.X) and not RelogioParado then
    begin
      O.X := O.X - 5;
      if O.X < CameraX + 30 then O.X := CameraX + 30;
      P.X := ((O.CorpoX2 + O.X) - P.CorpoX1) + 5;
    end;
  end;
  // lutador vivo nao sai da tela
  if P.Vida > 0 then
  begin
    if P.X < CameraX + 30 then P.X := CameraX + 30;
    if P.X > CameraX + 370 then P.X := CameraX + 370;
  end;
end;

procedure DefineCaixaCorpo(Jog, Quadro: Byte; X1, Y1, X2, Y2: Integer);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if P.Quadro <> Quadro then Exit;
  P.CorpoX1 := X1;
  P.CorpoY1 := Y1;
  P.CorpoX2 := X2;
  P.CorpoY2 := Y2;
  if P.Lado = ldEsquerda then
  begin
    // espelha para quem olha para a esquerda
    P.CorpoX1 := -X2;
    P.CorpoX2 := -X1;
  end;
end;

procedure DefineCaixaAtaque(Jog, Acao: Byte; QuadroAcao: Integer; X1, Y1, X2, Y2: Integer;
  Ativo, Forca, Dano, DanoDefesa: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if (P.Acao <> Acao) or (P.QuadroAcao <> QuadroAcao) then Exit;
  P.AtaqueX1 := X1;
  P.AtaqueY1 := Y1;
  P.AtaqueX2 := X2;
  P.AtaqueY2 := Y2;
  if P.Lado = ldEsquerda then
  begin
    P.AtaqueX1 := -X2;
    P.AtaqueX2 := -X1;
  end;
  P.GolpeAtivo := Ativo <> 0;
  if Forca <> 0 then P.ForcaGolpe := Forca;
  P.DanoGolpe := Dano;
  P.DanoDefesa := DanoDefesa;
end;

procedure DefineCaixaEfeito(Slot, X1, Y1, X2, Y2: Integer);
begin
  Efeitos[Slot].CaixaX1 := X1;
  Efeitos[Slot].CaixaY1 := Y1;
  Efeitos[Slot].CaixaX2 := X2;
  Efeitos[Slot].CaixaY2 := Y2;
end;

function ExisteEfeito(Tipo, Dono: Byte): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to MaxEfeitos do
    if (Efeitos[I].Tipo = Tipo) and not CheatBruxa and (Efeitos[I].Dono = Dono) then
      Result := True;
end;


procedure CriaEfeito(Tipo: Byte; const Texto: string; Dono: Byte; X, Y: Double);
var
  Slot: Integer;
  E: PEfeito;
begin
  for Slot := 1 to MaxEfeitos do
  begin
    E := @Efeitos[Slot];
    if E.Tipo <> 0 then Continue;
    E.X := X;
    E.Y := Y;
    E.Tipo := Tipo;
    E.Quadro := 0;
    E.VelY := 0;
    E.Estagio := False;
    E.Lado := ldDireita;
    E.Vel := 0;
    E.PodeAcertar := False;
    E.Variante := False;
    E.CaixaX1 := 0;
    E.CaixaY1 := 0;
    E.CaixaX2 := 0;
    E.CaixaY2 := 0;
    E.Dono := Dono;
    E.Terminando := False;
    E.Contagem := 0;
    E.LimiteContagem := 0;
    E.Flag50 := False;
    E.Flag51 := False;
    E.Flag52 := False;
    E.Dano := 0;
    E.DanoDefesa := 0;
    { valores do tipo (Dados/Efeitos.ini) }
    AplicarTipoEfeito(Slot, E, Texto, Dono);
    Exit;
  end;
end;

function CentroX(Jog: Byte): Integer;
var
  Idx: Integer;
begin
  Result := 0;
  Idx := Lutador[Jog].Quadro;
  if Jog = 2 then Idx := Idx - 50;
  if (Lutador[Jog].Personagem >= 1) and (Lutador[Jog].Personagem <= High(QuadrosLutador)) and
     (Idx >= 0) and (Idx <= MaxQuadroLutador) then
    Result := QuadrosLutador[Lutador[Jog].Personagem].CentroX[Idx];
end;

{ ---- AcaoJogador e AtualizaQuadro pelos roteiros (Dados/Lutadores/Comum.rot e CNN.rot) ---- }

var
  RotAcaoComum, RotAcaoFim, RotQuadroComum: TRoteiro;   // Comum.rot [Acao], [AcaoFim] e [Quadro]
  RotAcao, RotQuadro: array of TRoteiro;   // CNN.rot [Acao] e [Quadro], indice = personagem (nil = sem)

procedure LiberarRoteiros;
var
  I: Integer;
begin
  FreeAndNil(RotAcaoComum);
  FreeAndNil(RotAcaoFim);
  FreeAndNil(RotQuadroComum);
  for I := 0 to High(RotAcao) do FreeAndNil(RotAcao[I]);
  for I := 0 to High(RotQuadro) do FreeAndNil(RotQuadro[I]);
  RotAcao := nil;
  RotQuadro := nil;
end;

procedure CarregarRoteiros(const PadraoLutador, Comum: string; Qtd: Integer);
var
  I: Integer;
  Arq: string;
begin
  LiberarRoteiros;
  Arq := ResolverCaminho(Comum);
  if not FileExists(Arq) then
    raise ERoteiro.Create('Arquivo ' + Comum + ' nao encontrado (roteiro comum dos lutadores).');
  RotAcaoComum := CarregarRoteiro(Arq, 'Acao');
  RotAcaoFim := CarregarRoteiro(Arq, 'AcaoFim');
  RotQuadroComum := CarregarRoteiro(Arq, 'Quadro');
  SetLength(RotAcao, Qtd + 1);
  SetLength(RotQuadro, Qtd + 1);
  for I := 1 to Qtd do
  begin
    Arq := ResolverCaminho(ArquivoNN(PadraoLutador, I));
    RotAcao[I] := CarregarRoteiro(Arq, 'Acao');
    RotQuadro[I] := CarregarRoteiro(Arq, 'Quadro');
  end;
end;

procedure AcaoJogador(Jog, Codigo: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if RotAcaoComum <> nil then RotAcaoComum.Executar(Jog, Codigo);
  if (P.Personagem < Length(RotAcao)) and (RotAcao[P.Personagem] <> nil) then
    RotAcao[P.Personagem].Executar(Jog, Codigo);
  if RotAcaoFim <> nil then RotAcaoFim.Executar(Jog, Codigo);
end;

procedure AtualizaQuadroNovo(Jog: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if RotQuadroComum <> nil then RotQuadroComum.Executar(Jog, 0);
  if (P.Personagem < Length(RotQuadro)) and (RotQuadro[P.Personagem] <> nil) then
    RotQuadro[P.Personagem].Executar(Jog, 0);
  { caixas de colisao do quadro atual (Dados/Lutadores/Cnn.ini) }
  AplicarCaixas(Jog);
end;

procedure AtualizaQuadro(Jog: Byte);
begin
  AtualizaQuadroNovo(Jog);
end;

initialization

finalization
  LiberarRoteiros;

end.
