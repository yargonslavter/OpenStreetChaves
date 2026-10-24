unit ChavesGolpes;

{ Logica dos lutadores durante a luta: acoes (pular, golpear, defender...), escolha do
  quadro de animacao, caixas de colisao, danos e efeitos.
  Recuperado do executavel original (unidades Unit29/Unit30 do projeto Delphi): as rotinas
  AcaoJogador e AtualizaQuadro foram convertidas automaticamente do codigo de maquina e
  depois revisadas; os nomes de campos estao em ChavesTipos.pas / NOMES.md.
  O centro do sprite e as caixas de colisao de cada quadro vem de Dados/Lutadores/Cnn.ini
  (secoes [CentroX], [Corpo] e [Ataque]). }

{$mode delphi}{$H+}

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
    Chance: Integer;        // > 0: so atribui em 1 de cada Chance vezes (Random(Chance) = 0)
    Base, Passo, Sorteio: Integer;   // valor = Base + Passo * Random(Sorteio) (Sorteio = 0: Base)
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
{ Executa uma acao pedida ao lutador (andar, pular, golpe...); Codigo = botao/direcao. }
procedure AcaoJogador(Jog, Codigo: Byte);
{ Avanca a animacao do lutador, escolhe o quadro, define as caixas e aplica os golpes. }
procedure AtualizaQuadro(Jog: Byte);

implementation


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
      if Random(Op.Chance) <> 0 then Continue;
      V := Op.Base;
    end
    else if Op.Sorteio > 0 then
      V := Op.Base + Op.Passo * Random(Op.Sorteio)
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

procedure AcaoJogador(Jog, Codigo: Byte);
var
  P, O: PLutador;
  Desloc, Cont: Integer;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  if Jog = 1 then Desloc := 0;
  if Jog = 2 then Desloc := 50;
  P.Defendendo := False;
  if (Codigo = cmEsquerda) and (P.Acao in [acParado, acAndando]) then
  begin
    Empurra(Jog, -P.Velocidade);
    P.Acao := acAndando;
    P.DuracaoAcao := 99;
    P.AndandoFrente := False;
    if P.Lado = ldEsquerda then P.AndandoFrente := True;
  end;
  if (Codigo = cmDireita) and (P.Acao in [acParado, acAndando]) then
  begin
    Empurra(Jog, P.Velocidade);
    P.Acao := acAndando;
    P.DuracaoAcao := 99;
    P.AndandoFrente := False;
    if P.Lado = ldDireita then P.AndandoFrente := True;
  end;
  if (Codigo = cmSocoFraco) and (P.Acao in [acParado, acAndando, acDefesa]) and (P.VelY = 0) then
  begin
    P.Acao := acSocoFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmChuteFraco) and
     ((P.Acao in [acParado, acAndando, acDefesa]) or ((P.Acao = acSocoFraco) and (P.QuadroAcao >= 2))) and
     (P.VelY = 0) then
  begin
    P.Acao := acChuteFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmSocoForte) and
     ((P.Acao in [acParado, acAndando, acDefesa]) or ((P.Acao in [acSocoFraco, acChuteFraco]) and (P.QuadroAcao >= 2))) and
     (P.VelY = 0) then
  begin
    P.Acao := acSocoForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
  end;
  if (Codigo = cmChuteForte) and (P.Acao in [acParado, acAndando, acDefesa]) and (P.VelY = 0) and not P.NoAr then
  begin
    P.Acao := acChuteForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
  end;
  if (Codigo = cmAgachar) and (P.Acao in [acParado, acAndando]) then
  begin
    P.Acao := acAgachado;
    P.DuracaoAcao := 99;
  end;
  if (Codigo = cmSocoFraco) and (P.Acao in [acAgachado, acDefesaBaixa]) then
  begin
    P.Acao := acAgSocoFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmChuteFraco) and
     ((P.Acao in [acAgachado, acDefesaBaixa]) or ((P.Acao = acAgSocoFraco) and (P.QuadroAcao >= 2))) then
  begin
    P.Acao := acAgChuteFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmSocoForte) and
     ((P.Acao in [acAgachado, acDefesaBaixa]) or ((P.Acao in [acAgSocoFraco, acAgChuteFraco]) and (P.QuadroAcao >= 2))) then
  begin
    P.Acao := acAgSocoForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
  end;
  if (Codigo = cmChuteForte) and
     ((P.Acao in [acAgachado, acDefesaBaixa]) or ((P.Acao = acAgChuteFraco) and (P.QuadroAcao >= 2))) then
  begin
    P.Acao := acAgChuteForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.EhChute := True;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
    if P.Personagem = pnJaiminho then P.DuracaoAcao := 18;
  end;
  if (Codigo = cmSocoFraco) and (P.Acao = acPulo) then
  begin
    P.Acao := acArSocoFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 15;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmChuteFraco) and (P.Acao = acPulo) then
  begin
    P.Acao := acArChuteFraco;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 15;
    if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeFraco;
  end;
  if (Codigo = cmSocoForte) and (P.Acao = acPulo) then
  begin
    P.Acao := acArSocoForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
  end;
  if (Codigo = cmChuteForte) and (P.Acao = acPulo) then
  begin
    P.Acao := acArChuteForte;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if P.CargaPoder < CargaMax then P.CargaPoder := 2 * GanhoCarga + P.CargaPoder;
    SomPendente := sndGolpeForte;
  end;
  if (Codigo = cmApanharAlto) and (P.VelY = 0) then
  begin
    P.Acao := acApanhaAlto;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 8;
  end;
  if (Codigo = cmApanharBaixo) and (P.VelY = 0) then
  begin
    P.Acao := acApanhaBaixo;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 8;
  end;
  if Codigo = cmDerrubar then
  begin
    P.Acao := acDerrubado;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 50;
    P.VelY := -19;
    P.NoAr := True;
    P.DirPulo := puloNenhum;
    P.Invulneravel := True;
    P.GolpeAtivo := False;
  end;
  if Codigo = cmBaterNoChao then
  begin
    P.Acao := acQuicando;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 25;
    P.VelY := -13;
    P.NoAr := True;
    P.Invulneravel := True;
  end;
  if (Codigo = cmDefender) and
     ((P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acQuicando) and (P.QuadroAcao >= P.DuracaoAcao - 3))) then
  begin
    P.Acao := acDefesa;
    P.Invulneravel := False;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.Defendendo := True;
    P.Quadro := Desloc + 31;
  end;
  if (Codigo = cmDefenderBaixo) and
     ((P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acQuicando) and (P.QuadroAcao >= P.DuracaoAcao - 3))) then
  begin
    P.Acao := acDefesaBaixa;
    P.Invulneravel := False;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.Defendendo := True;
    P.Quadro := Desloc + 32;
  end;
  if P.Personagem = pnChaves then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(7, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.DuracaoAcao := 16;
      if Codigo = cmEsp2Forte then P.DuracaoAcao := 27;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       (P.Acao in [acParado, acAndando, acPulo, acDefesaBaixa, acEspecial2]) then
      if ChaoY - 90 <= P.Y then
      begin
        P.Acao := acEspecial3;
        if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
        P.Y := ChaoY;
        P.NoAr := False;
        P.QuadroAcao := 0;
        P.VelY := 0;
        P.DirPulo := puloNenhum;
        P.TempoBaixo := 0;
        P.SeqEstado := 0;
        if Codigo = cmEsp3Fraco then P.DuracaoAcao := 10;
        if Codigo = cmEsp3Forte then P.DuracaoAcao := 16;
        if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
        if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      P.DuracaoAcao := 22;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acSocoForte, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 38;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 36;
      P.ForcaGolpe := fgEspecial;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnSeuMadruga then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(9, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and
       ((P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acSocoFraco) and (P.QuadroAcao >= 4)) or ((P.Acao = acSocoForte) and (P.QuadroAcao >= 5)) or ((P.Acao = acEspecial6) and (P.QuadroAcao > 10))) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acPulo, acArChuteFraco]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      P.EhChute := True;
      P.NoAr := False;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      SomPendente := 21;
    end;
    if (Codigo = cmEsp4Fraco) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 45;
      if P.CargaPoder < CargaMax then P.CargaPoder := 7 * GanhoCarga + P.CargaPoder;
    end;
    if (Codigo = cmEsp4Forte) and
       ((P.Acao in [acParado, acAndando, acSocoForte, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acEspecial1) and (P.QuadroAcao > 12))) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial6;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      P.ForcaGolpe := fgForte;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 44;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnChiquinha then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(9, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      SomPendente := 23;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.EhChute := True;
      if Codigo = cmEsp2Fraco then P.VelY := -23;
      if Codigo = cmEsp2Forte then P.VelY := -29;
      P.NoAr := True;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 24;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.EhChute := True;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 14;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 19;
      SomPendente := 24;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if Codigo = cmEsp4Fraco then P.VelY := -22;
      if Codigo = cmEsp4Forte then P.VelY := -23;
      P.NoAr := True;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acChuteForte, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.Quadro := Desloc + 48;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnQuico then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(12, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      SomPendente := 25;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.EhChute := True;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 13;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 16;
      SomPendente := 26;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.EhChute := True;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.VelY := -26;
      if P.ForcaGolpe = fgForte then P.VelY := -32;
      P.NoAr := True;
      SomPendente := 27;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa, acEspecial2]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      P.ForcaGolpe := fgForte;
      P.EhChute := True;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 12;
      O.Invulneravel := False;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnDonaFlorinda then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(13, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      SomPendente := 29;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 23;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 30;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acPulo, acDefesaBaixa]) then
      if ChaoY - 90 <= P.Y then
      begin
        P.Acao := acEspecial3;
        P.Y := ChaoY;
        P.VelY := 0;
        P.NoAr := False;
        P.TempoBaixo := 0;
        P.QuadroAcao := 0;
        if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
        if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
        if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
        if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 38;
        if P.ForcaGolpe = fgForte then P.DuracaoAcao := 40;
        SomPendente := 31;
      end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.CargaChute := 0;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      SomPendente := 32;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa, acEspecial4]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 6;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnProfGirafales then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(15, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      SomPendente := 33;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(15, Jog) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 33;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      P.NoAr := False;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      SomPendente := 34;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      SomPendente := 35;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acSocoForte, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 50;
      P.VelY := -18;
      P.NoAr := True;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 41;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnSrBarriga then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.CargaSoco := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 17;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 20;
      SomPendente := 36;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.CargaSoco := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 37;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acPulo, acDefesaBaixa]) then
      if ChaoY - 90 <= P.Y then
      begin
        P.Acao := acEspecial3;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        P.NoAr := True;
        P.DirPulo := puloNenhum;
        P.TempoBaixo := 0;
        P.Y := ChaoY;
        if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
        if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
        if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
        if P.ForcaGolpe = fgFraco then P.VelY := -27;
        if P.ForcaGolpe = fgForte then P.VelY := -32;
        SomPendente := 38;
      end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao in [acParado, acAndando, acPulo, acDefesaBaixa]) then
      if ChaoY - 90 <= P.Y then
      begin
        P.Acao := acEspecial4;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        P.NoAr := True;
        P.DirPulo := puloNenhum;
        P.TempoBaixo := 0;
        P.Y := ChaoY;
        if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
        if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
        if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
        if P.ForcaGolpe = fgFraco then P.VelY := -27;
        if P.ForcaGolpe = fgForte then P.VelY := -30;
        SomPendente := 37;
      end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acSocoForte, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 12;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 38;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnBruxa then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(18, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      SomPendente := 39;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao = acPulo) and not ExisteEfeito(19, Jog) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 39;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      SomPendente := 40;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       (P.Acao in [acParado, acAndando, acAgachado, acPulo, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      SomPendente := 41;
    end;
    if (Codigo = cmEspFinal) and (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 33;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnPaty then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 14;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 23;
      SomPendente := 43;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      SomPendente := 44;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      SomPendente := 45;
      for Cont := 1 to 5 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao = acPulo) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.NoAr := False;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      SomPendente := 45;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa, acEspecial3]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 40;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 19;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnNhonho then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.CargaSoco := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
      P.DuracaoAcao := 20;
      SomPendente := 47;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 11;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 20;
      SomPendente := 48;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acPulo, acDefesaBaixa]) then
      if ChaoY - 90 <= P.Y then
      begin
        P.Acao := acEspecial3;
        P.QuadroAcao := 0;
        P.Y := ChaoY - 50;
        P.NoAr := True;
        P.DuracaoAcao := 20;
        if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
        if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
        if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
        if P.ForcaGolpe = fgFraco then P.VelY := -25;
        if P.ForcaGolpe = fgForte then P.VelY := -28;
        SomPendente := 49;
      end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       (P.Acao in [acParado, acAndando, acSocoForte, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      SomPendente := 49;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa, acEspecial1]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 40;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 38;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnGodines then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(22, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
      if P.ForcaGolpe = fgFraco then P.DuracaoAcao := 9;
      if P.ForcaGolpe = fgForte then P.DuracaoAcao := 15;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       ((P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) or ((P.Acao = acEspecial5) and (P.QuadroAcao >= 27))) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 12;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEspFinal) and
       (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa, acEspecial3]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 45;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 6;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnSrFurtado then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
      if P.X - CameraX < 200 then P.Lado := ldDireita;
      if P.X - CameraX >= 200 then P.Lado := ldEsquerda;
    end;
    if (Codigo = cmPose) and (P.Acao in [acParado, acAndando]) then
    begin
      P.Acao := acPose;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(9, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and
       ((P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acEspecial6) and not P.GolpeAtivo)) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if P.CargaPoder < CargaMax then P.CargaPoder := 6 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       (P.Acao in [acParado, acAndando, acSocoForte, acPulo, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      P.VelY := 0;
      P.NoAr := False;
      P.DirPulo := puloNenhum;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEsp4Fraco) and (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 32;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 38;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnJaiminho then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(26, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and
       ((P.Acao in [acParado, acAndando, acPulo, acDefesa, acDefesaBaixa]) or ((P.Acao = acSocoForte) and (P.QuadroAcao >= 3))) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 16;
      if P.VelY <> 0 then P.VelY := -10;
      P.DirPulo := puloNenhum;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(28, Jog) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte, cmEspFinal, cmEspExtra1]) and
       (P.Acao in [acParado, acAndando, acPulo, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
      if Codigo = cmEspFinal then P.ForcaGolpe := fgEspecial;
      if Codigo = cmEspExtra1 then P.ForcaGolpe := 4;
    end;
    if (Codigo = cmEspExtra2) and
       (P.Acao in [acParado, acAndando, acAgachado, acPulo, acDefesa, acDefesaBaixa, acEspecial3]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      P.NoAr := False;
      P.DirPulo := puloNenhum;
      P.VelY := 0;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 37;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnDonaNeves then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(29, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and (P.Acao = acPulo) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      P.NoAr := False;
      P.VelY := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and
       (P.Acao in [acParado, acAndando, acPulo, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      P.NoAr := False;
      P.VelY := 0;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEspFinal) and (P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 70;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 37;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Personagem = pnGloria then
  begin
    if (Codigo = cmVitoria) and (P.Acao in [acParado, acAndando, acAgachado]) then
    begin
      P.Acao := acVitoria;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo in [cmEsp1Fraco, cmEsp1Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) and
       not ExisteEfeito(33, Jog) then
    begin
      P.Acao := acEspecial1;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp1Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp1Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp2Fraco, cmEsp2Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial2;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 22;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp2Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp2Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp3Fraco, cmEsp3Forte]) and
       ((P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) or ((P.Acao = acChuteForte) and (P.QuadroAcao >= 6))) then
    begin
      P.Acao := acEspecial3;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      P.NoAr := False;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp3Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp3Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo in [cmEsp4Fraco, cmEsp4Forte]) and (P.Acao in [acParado, acAndando, acDefesa, acDefesaBaixa]) then
    begin
      P.Acao := acEspecial4;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 18;
      if P.CargaPoder < CargaMax then P.CargaPoder := 5 * GanhoCarga + P.CargaPoder;
      if Codigo = cmEsp4Fraco then P.ForcaGolpe := fgFraco;
      if Codigo = cmEsp4Forte then P.ForcaGolpe := fgForte;
    end;
    if (Codigo = cmEspFinal) and
       ((P.Acao in [acParado, acAndando, acAgachado, acDefesa, acDefesaBaixa]) or ((P.Acao = acEspecial1) and (P.QuadroAcao >= 24))) and
       ((P.Vida <= 15) or (P.Poder > 0)) then
    begin
      P.Acao := acEspecial5;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if P.Poder = 3 then P.CargaPoder := 0;
      P.Poder := P.Poder - 1;
      P.Quadro := Desloc + 12;
      FlashTela := 22;
      SomPendente := sndEspFinal;
    end;
  end;
  if P.Acao = acAndando then
  begin
    P.QuadroAcao := P.QuadroAcao + 1;
    if P.QuadroAcao > 16 then P.QuadroAcao := 0;
  end;
end;

procedure AtualizaQuadro(Jog: Byte);
var
  P, O: PLutador;
  Desloc, Cont, S_0: Integer;
  S_2: ShortInt;
  r194, r195: Integer;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  if Jog = 1 then Desloc := 0;
  if Jog = 2 then Desloc := 50;
  if P.Acao = acParado then
  begin
    P.Quadro := Desloc + 1;
    P.Invulneravel := False;
  end;
  if (P.Acao = acAndando) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 2;
  if (P.Acao = acAndando) and (P.QuadroAcao = 4) then P.Quadro := Desloc + 3;
  if (P.Acao = acAndando) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 2;
  if (P.Acao = acAndando) and (P.QuadroAcao = 12) then P.Quadro := Desloc + 1;
  if (P.Personagem = pnBruxa) and (P.Acao = acAndando) then
  begin
    if P.AndandoFrente then P.Quadro := Desloc + 2;
    if not P.AndandoFrente then P.Quadro := Desloc + 3;
    CriaEfeito(2, '', 0, Random(20) + (P.X - 10), Random(10) + P.Y);
  end;
  if (P.Acao = acSocoFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 4;
  if (P.Acao = acSocoFraco) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 5;
  if (P.Acao = acSocoFraco) and (P.QuadroAcao = 4) then P.Quadro := Desloc + 4;
  if (P.Acao = acChuteFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 6;
  if (P.Acao = acChuteFraco) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 7;
  if (P.Acao = acChuteFraco) and (P.QuadroAcao = 4) then P.Quadro := Desloc + 6;
  if (P.Acao = acSocoForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 8;
  if (P.Acao = acSocoForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 9;
  if (P.Acao = acSocoForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 8;
  if (P.Acao = acChuteForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 10;
  if (P.Acao = acChuteForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 11;
  if (P.Acao = acChuteForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 10;
  if P.Acao = acAgachado then P.Quadro := Desloc + 12;
  if (P.Acao = acAgSocoFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 13;
  if (P.Acao = acAgSocoFraco) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 14;
  if (P.Acao = acAgSocoFraco) and (P.QuadroAcao = 4) then P.Quadro := Desloc + 13;
  if (P.Acao = acAgChuteFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 15;
  if (P.Acao = acAgChuteFraco) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 16;
  if (P.Acao = acAgChuteFraco) and (P.QuadroAcao = 4) then P.Quadro := Desloc + 15;
  if (P.Acao = acAgSocoForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 17;
  if (P.Acao = acAgSocoForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 18;
  if (P.Acao = acAgSocoForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 17;
  if P.Personagem <> pnJaiminho then
  begin
    if (P.Acao = acAgChuteForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 19;
    if (P.Acao = acAgChuteForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 20;
    if (P.Acao = acAgChuteForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 19;
  end
  else if (P.Personagem = pnJaiminho) and (P.Acao = acAgChuteForte) then
  begin
    if P.QuadroAcao = 0 then P.Quadro := Desloc + 19;
    if P.QuadroAcao = 4 then P.Quadro := Desloc + 20;
    if P.QuadroAcao = 16 then P.Quadro := Desloc + 19;
    if P.Lado = ldDireita then Empurra(Jog, 9);
    if P.Lado = ldEsquerda then Empurra(Jog, -9);
    CriaEfeito(2, '', 0, Random(40) + (Round(P.X) - 20), Round(P.Y) - Random(5));
  end;
  if P.Acao = acPulo then P.Quadro := Desloc + 21;
  if (P.Acao = acArSocoFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 22;
  if (P.Acao = acArSocoFraco) and (P.QuadroAcao = 3) then P.Quadro := Desloc + 23;
  if (P.Acao = acArChuteFraco) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 24;
  if (P.Acao = acArChuteFraco) and (P.QuadroAcao = 3) then P.Quadro := Desloc + 25;
  if (P.Acao = acArSocoForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 22;
  if (P.Acao = acArSocoForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 23;
  if (P.Acao = acArSocoForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 22;
  if (P.Acao = acArChuteForte) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 24;
  if (P.Acao = acArChuteForte) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 25;
  if (P.Acao = acArChuteForte) and (P.QuadroAcao = 8) then P.Quadro := Desloc + 24;
  if (P.Acao = acApanhaAlto) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 26;
  if (P.Acao = acApanhaBaixo) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 27;
  if (P.Acao = acApanhaBaixo) and (P.QuadroAcao = 1) then P.Quadro := Desloc + 27;
  if P.Acao = acDerrubado then P.Quadro := Desloc + 28;
  if (P.Acao = acQuicando) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 29;
  if (P.Acao = acQuicando) and (P.QuadroAcao = 18) then P.Quadro := Desloc + 30;
  if (P.Acao = acQuicando) and (P.VelY = 0) and (P.Vida <= 0) then
  begin
    P.QuadroAcao := 0;
    P.Y := ChaoY;
  end;
  if P.Acao = acDefesa then P.Quadro := Desloc + 31;
  if P.Acao = acDefesaBaixa then P.Quadro := Desloc + 32;
  if P.Acao in [acDefesa, acDefesaBaixa] then P.Defendendo := True;
  if P.Personagem = pnChaves then
  begin
    if P.Acao = acVitoria then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 33;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 14 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 21 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 28 then P.Quadro := Desloc + 33;
      if P.QuadroAcao = 28 then P.QuadroAcao := 0;
    end;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 39;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(7, 'A', Jog, P.X + 45, P.Y);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then CriaEfeito(7, 'A', Jog, P.X - 45, P.Y);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(7, 'B', Jog, P.X + 45, P.Y);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then CriaEfeito(7, 'B', Jog, P.X - 45, P.Y);
        SomPendente := 14;
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then SomPendente := 15;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 40;
      if (P.QuadroAcao = 6) and (P.ForcaGolpe = fgFraco) then P.Quadro := Desloc + 41;
      if (P.QuadroAcao = 10) and (P.ForcaGolpe = fgForte) then P.Quadro := Desloc + 41;
      if (P.QuadroAcao = 12) and (P.ForcaGolpe = fgFraco) then P.Quadro := Desloc + 42;
      if (P.QuadroAcao = 19) and (P.ForcaGolpe = fgForte) then P.Quadro := Desloc + 42;
      if P.Quadro = Desloc + 41 then
      begin
        for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 19);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -19);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 21);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -21);
      end;
      if (P.Lado = ldDireita) and (P.QuadroAcao >= 9) then CriaEfeito(16, '', Jog, P.X + 60, P.Y - 85);
      if (P.Lado = ldEsquerda) and (P.QuadroAcao >= 9) then CriaEfeito(16, '', Jog, P.X - 60, P.Y - 85);
      P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.Acertos >= 1 then O.Invulneravel := False;
      if P.Acertos >= 4 then O.Invulneravel := True;
      if P.QuadroAcao > 7 then O.Invulneravel := True;
      if P.QuadroAcao = 0 then SomPendente := 16;
      if P.QuadroAcao mod 3 = 0 then
      begin
        if P.Quadro = Desloc + 43 then P.Quadro := Desloc + 44
        else P.Quadro := Desloc + 43;
      end;
      P.Y := P.Y - 10;
      if P.Lado = ldDireita then Empurra(Jog, 5);
      if P.Lado = ldEsquerda then Empurra(Jog, -5);
      if P.QuadroAcao = 20 then P.NoAr := True;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then SomPendente := 17;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 45;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 46;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 47;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 48;
      if P.QuadroAcao = 15 then P.Quadro := Desloc + 49;
      if P.QuadroAcao = 18 then P.Quadro := Desloc + 12;
      if (P.QuadroAcao >= 4) and (P.QuadroAcao <= 13) then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 17);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -17);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 21);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -21);
      end;
      if P.QuadroAcao >= 12 then P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 9 then SomPendente := 18;
      if P.QuadroAcao = 9 then
      begin
        P.Quadro := Desloc + 39;
        if P.Lado = ldDireita then CriaEfeito(8, 'A', Jog, P.X + 110, P.Y);
        if P.Lado = ldEsquerda then CriaEfeito(8, 'A', Jog, P.X - 110, P.Y);
        TremorTela := 20;
      end;
    end;
  end;
  if P.Personagem = pnSeuMadruga then
  begin
    if P.Acao = acVitoria then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (Random(2) = 0) then P.Quadro := Desloc + 34;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 37;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(9, 'A', Jog, P.X + 55, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(9, 'A', Jog, P.X - 55, P.Y - 100);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(9, 'B', Jog, P.X + 55, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(9, 'B', Jog, P.X - 55, P.Y - 100);
        SomPendente := 20;
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 39;
      if ((P.QuadroAcao = 11) and (P.ForcaGolpe = fgFraco)) or ((P.QuadroAcao = 15) and (P.ForcaGolpe = fgForte)) then
      begin
        P.Quadro := Desloc + 40;
        P.NoAr := True;
        P.VelY := -6;
      end;
      if P.Quadro = Desloc + 39 then
      begin
        if P.ForcaGolpe = fgFraco then
        begin
          P.Y := P.Y - 11;
          if P.Lado = ldDireita then Empurra(Jog, 4);
          if P.Lado = ldEsquerda then Empurra(Jog, -4);
        end;
        if P.ForcaGolpe = fgForte then
        begin
          P.Y := P.Y - 12;
          if P.QuadroAcao < 10 then
          begin
            if P.Lado = ldDireita then Empurra(Jog, 9);
            if P.Lado = ldEsquerda then Empurra(Jog, -9);
          end;
          if P.QuadroAcao >= 10 then
          begin
            if P.Lado = ldDireita then Empurra(Jog, 3);
            if P.Lado = ldEsquerda then Empurra(Jog, -3);
          end;
        end;
      end;
      if P.Quadro = Desloc + 40 then P.NoAr := True;
      if P.QuadroAcao >= 5 then P.EhChute := True;
      if P.Acertos = 1 then O.Invulneravel := False;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then
      begin
        P.Quadro := Desloc + 24;
        P.VelY := 0;
        P.DirPulo := puloNenhum;
      end;
      if (P.Acao = acEspecial3) and (P.QuadroAcao >= 3) then
      begin
        P.Quadro := Desloc + 25;
        if P.ForcaGolpe = fgFraco then P.Y := P.Y + 20;
        if P.ForcaGolpe = fgForte then P.Y := P.Y + 13;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 11);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -11);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 15);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -15);
        if P.Y > 270 then P.VelY := 2;
      end;
    end;
    if (P.Acao in [acEspecial4, acEspecial5]) and (P.QuadroAcao >= 0) then
    begin
      if (P.Acao = acEspecial4) and (P.QuadroAcao = 0) then SomPendente := 22;
      repeat
        S_0 := Random(3) + (Desloc + 41);
      until P.Quadro <> S_0;
      P.Quadro := S_0;
      if Random(2) = 0 then SomPendente := sndGolpeFraco;
      if Random(2) = 0 then SomPendente := sndGolpeForte;
      if Random(2) = 0 then SomPendente := sndGolpeFraco;
      if Random(2) = 0 then SomPendente := sndGolpeForte;
      if P.Acao = acEspecial5 then
      begin
        if Flash and (Random(6) = 0) then FlashVermelho := 3;
        P.Recuo := 0;
        O.Quadro := Random(2) + 26 + (50 - Desloc);
        O.QuadroAcao := 0;
        O.DuracaoAcao := 5;
        O.VelY := 0;
        O.Y := O.Y + 10;
        if ChaoY < O.Y then O.Y := ChaoY;
        if P.Lado = ldDireita then O.X := Random(2) shl 3 + (P.X + 40);
        if P.Lado = ldEsquerda then O.X := P.X - 40 - Random(2) shl 3;
        P.Acertos := P.Acertos + 1;
        P.TempoAcertos := 20;
        if Random(4) = 0 then SomPendente := sndAcertoFraco;
        if Random(4) = 0 then SomPendente := sndAcertoForte;
        if Random(4) = 0 then SomPendente := sndAcertoEspecial;
        CriaEfeito(1, '', 0, Random(20) + (O.X - 30), Random(120) + (O.Y - 150));
        if P.QuadroAcao > P.DuracaoAcao - 2 then
        begin
          P.DanoGolpe := 20;
          O.Vida := O.Vida - P.DanoGolpe * NivelDano;
          AcaoJogador(3 - Jog, cmDerrubar);
          O.Recuo := 30;
        end;
      end;
    end;
    if (P.Acao = acEspecial6) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 44;
    if (P.Acao = acEspecial6) and (P.QuadroAcao > 2) then
    begin
      for Cont := 1 to 8 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      P.Quadro := Desloc + 45;
      if P.Lado = ldDireita then Empurra(Jog, 23);
      if P.Lado = ldEsquerda then Empurra(Jog, -23);
    end;
    if P.Acao = acEspecial7 then
    begin
      P.Recuo := 0;
      P.Quadro := Random(45) + 1 + Desloc;
      if Flash and (Random(5) = 0) then FlashVermelho := 3;
      if P.Lado = ldDireita then Empurra(Jog, 3);
      if P.Lado = ldEsquerda then Empurra(Jog, -3);
      O.Quadro := Random(2) + 26 + (50 - Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := O.Y + 10;
      if ChaoY < O.Y then O.Y := ChaoY;
      if P.Lado = ldDireita then O.X := Random(2) shl 3 + (P.X + 40);
      if P.Lado = ldEsquerda then O.X := P.X - 40 - Random(2) shl 3;
      P.Acertos := P.Acertos + 2;
      P.TempoAcertos := 43;
      if (Random(30) = 0) and (O.Vida > 0) then PausaImpacto := 5;
      if Random(4) = 0 then SomPendente := sndAcertoFraco;
      if Random(4) = 0 then SomPendente := sndAcertoForte;
      if Random(4) = 0 then SomPendente := sndAcertoEspecial;
      CriaEfeito(1, '', 0, Random(20) + (O.X - 10), Random(100) + (O.Y - 130));
      if P.QuadroAcao > P.DuracaoAcao - 2 then
      begin
        P.DanoGolpe := 47;
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        P.Acao := acParado;
        P.Quadro := Desloc + 38;
        PausaImpacto := 5;
        AcaoJogador(Jog, cmEsp2Forte);
        AcaoJogador(3 - Jog, cmDerrubar);
        P.GolpeAtivo := False;
        O.Recuo := 28;
        O.VelY := -30;
        if O.Lado = ldDireita then O.VelAngular := -25;
        if O.Lado = ldEsquerda then O.VelAngular := 25;
      end;
    end;
  end;
  if P.Personagem = pnChiquinha then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao < 5) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 5) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 10) then P.Quadro := Desloc + 35;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 15) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 20) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 25) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 30) then P.Quadro := Desloc + 35;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 35) then P.Quadro := Desloc + 34;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(9, 'A', Jog, P.X + 40, P.Y - 80);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then CriaEfeito(9, 'A', Jog, P.X - 40, P.Y - 80);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(9, 'B', Jog, P.X + 40, P.Y - 80);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then CriaEfeito(9, 'B', Jog, P.X - 40, P.Y - 80);
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 42;
      if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 6);
      if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -6);
      if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 8);
      if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -8);
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 44;
      if P.QuadroAcao >= 5 then
      begin
        for Cont := 1 to 5 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        P.Quadro := Desloc + 45;
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 17);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -17);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 16);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -16);
      end;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 46;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 47;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 46;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 47;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 46;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 10);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -10);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 14);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -14);
      if P.QuadroAcao >= 5 then P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      P.Quadro := Desloc + 48;
      if P.Lado = ldDireita then Empurra(Jog, 17);
      if P.Lado = ldEsquerda then Empurra(Jog, -17);
    end;
    if P.Acao = acEspecial6 then
    begin
      P.Recuo := 0;
      if ContPisca mod 4 = 0 then P.Quadro := Desloc + 49
      else P.Quadro := Desloc + 50;
      P.Y := P.Y - 3;
      if Flash and (Random(5) = 0) then FlashVermelho := 3;
      O.Quadro := Random(2) + 26 + (50 - Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := O.Y + 10;
      if ChaoY < O.Y then O.Y := ChaoY;
      if P.Lado = ldDireita then
      begin
        r194 := Random(3);
        O.X := r194 + r194 * 4 + (P.X + 65);
      end;
      if P.Lado = ldEsquerda then
      begin
        r195 := Random(3);
        O.X := P.X - 65 - (r195 + r195 * 4);
      end;
      P.Acertos := P.Acertos + 1;
      P.TempoAcertos := 43;
      if (Random(20) = 0) and (O.Vida > 0) then PausaImpacto := 5;
      if Random(6) = 0 then SomPendente := sndAcertoFraco;
      if Random(6) = 0 then SomPendente := sndAcertoForte;
      if Random(6) = 0 then SomPendente := sndAcertoEspecial;
      if P.Lado = ldDireita then CriaEfeito(1, '', 0, Random(10) + (P.X + 40), Random(30) + (P.Y - 30));
      if P.Lado = ldEsquerda then CriaEfeito(1, '', 0, Random(10) + (P.X - 50), Random(30) + (P.Y - 30));
      if P.QuadroAcao > P.DuracaoAcao - 2 then
      begin
        P.DanoGolpe := 36;
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        P.VelY := -28;
        P.NoAr := True;
        P.Acao := acPulo;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 99;
        AcaoJogador(3 - Jog, cmDerrubar);
        O.Recuo := 30;
        if O.Lado = ldDireita then O.VelAngular := -15;
        if O.Lado = ldEsquerda then O.VelAngular := 15;
      end;
    end;
  end;
  if P.Personagem = pnQuico then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao < 13) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 13) then P.Quadro := Desloc + 34;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 37;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(12, 'A', Jog, P.X + 40, P.Y - 110);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(12, 'A', Jog, P.X - 40, P.Y - 110);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(12, 'B', Jog, P.X + 40, P.Y - 110);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(12, 'B', Jog, P.X - 40, P.Y - 110);
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 36;
      if P.QuadroAcao >= 7 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 26);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -26);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 25);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -25);
      end;
      for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 12;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 41;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 10);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -10);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 13);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -13);
      if P.QuadroAcao >= 6 then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 45;
      if (P.QuadroAcao >= 2) and (P.QuadroAcao < 6) then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 9);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -9);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 18);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -18);
      end;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then
      begin
        P.Quadro := Desloc + 12;
        SomPendente := 28;
      end;
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 41;
      if P.Lado = ldDireita then Empurra(Jog, 17);
      if P.Lado = ldEsquerda then Empurra(Jog, -17);
      if (P.QuadroAcao > 1) and (P.QuadroAcao < 10) then
        for Cont := 1 to 3 do
        begin
          if P.Lado = ldDireita then CriaEfeito(11, '', 0, Random(30) + (P.X + 20), Random(40) + (P.Y - 110));
          if P.Lado = ldEsquerda then CriaEfeito(11, '', 0, P.X - 20 - Random(30), Random(40) + (P.Y - 110));
        end;
    end;
  end;
  if P.Personagem = pnDonaFlorinda then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao < 5) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 9) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 13) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 17) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 21) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 25) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 29) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 33) then P.Quadro := Desloc + 34;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 37) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 41) then P.Quadro := Desloc + 35;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(13, 'A', Jog, P.X + 40, P.Y - 103);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(13, 'A', Jog, P.X - 40, P.Y - 103);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(13, 'B', Jog, P.X + 40, P.Y - 103);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(13, 'B', Jog, P.X - 40, P.Y - 103);
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 15 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 20 then P.Quadro := Desloc + 12;
      if P.QuadroAcao < 13 then
      begin
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 6);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -6);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 10);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -10);
      end;
      if P.QuadroAcao >= 15 then P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao mod 2 = 0 then P.Quadro := Desloc + 43;
      if P.QuadroAcao mod 2 <> 0 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 35 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 38 then P.Quadro := Desloc + 39;
      if (P.QuadroAcao >= 4) and (P.QuadroAcao < 35) then
      begin
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 7);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -7);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 9);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -9);
      end;
      if P.QuadroAcao >= 26 then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      repeat
        S_0 := Random(3) + (Desloc + 45);
      until P.Quadro <> S_0;
      P.Quadro := S_0;
      if Random(5) = 0 then SomPendente := 32;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 10;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 11;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 6;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 10;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 11;
      if (P.QuadroAcao >= 8) and (P.QuadroAcao < 28) then P.Quadro := Random(3) + (Desloc + 45);
      if P.QuadroAcao = 28 then P.Quadro := Desloc + 6;
      if P.QuadroAcao >= 15 then P.EhChute := True;
      if P.QuadroAcao in [1, 8, 12] then SomPendente := 32;
      if (P.Lado = ldDireita) and (P.QuadroAcao < 8) then Empurra(Jog, 5);
      if (P.Lado = ldDireita) and (P.QuadroAcao >= 8) and (P.QuadroAcao < 28) then Empurra(Jog, 10);
      if (P.Lado = ldEsquerda) and (P.QuadroAcao < 8) then Empurra(Jog, -5);
      if (P.Lado = ldEsquerda) and (P.QuadroAcao >= 8) and (P.QuadroAcao < 28) then Empurra(Jog, -10);
    end;
  end;
  if P.Personagem = pnProfGirafales then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao mod 4 = 0) then
    begin
      if P.Quadro = Desloc + 33 then P.Quadro := Desloc + 34
      else P.Quadro := Desloc + 33;
    end;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 37;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(15, 'A', Jog, P.X + 50, P.Y - 130);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(15, 'A', Jog, P.X - 50, P.Y - 130);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(15, 'B', Jog, P.X + 50, P.Y - 130);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(15, 'B', Jog, P.X - 50, P.Y - 130);
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 40;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(15, 'A', Jog, P.X + 50, P.Y - 75);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(15, 'A', Jog, P.X - 50, P.Y - 75);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(15, 'B', Jog, P.X + 50, P.Y - 75);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(15, 'B', Jog, P.X - 50, P.Y - 75);
      end;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 43;
      if (P.QuadroAcao >= 3) and (P.QuadroAcao <= 12) then
      begin
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 6);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -6);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 9);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -9);
        if P.ForcaGolpe = fgFraco then P.Y := P.Y - 10;
        if P.ForcaGolpe = fgForte then P.Y := P.Y - 13;
      end;
      if P.QuadroAcao = 13 then
      begin
        if P.ForcaGolpe = fgFraco then P.VelY := -3;
        if P.ForcaGolpe = fgForte then P.VelY := -6;
        P.NoAr := True;
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.Lado = ldDireita then Empurra(Jog, 2);
      if P.Lado = ldEsquerda then Empurra(Jog, -2);
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 41;
      if (P.QuadroAcao >= 2) and (P.QuadroAcao <= 5) then
      begin
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 20);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -20);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 27);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -27);
        P.Y := P.Y - 15;
      end;
      if P.QuadroAcao >= 3 then P.EhChute := True;
      if P.QuadroAcao = 6 then P.NoAr := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao <= 8 then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 1);
        if P.Lado = ldEsquerda then Empurra(Jog, -1);
      end;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 41;
      if (P.QuadroAcao >= 3) and (P.QuadroAcao <= 6) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 21);
        if P.Lado = ldEsquerda then Empurra(Jog, -21);
      end;
      if P.QuadroAcao = 8 then
      begin
        P.NoAr := False;
        P.Y := ChaoY;
      end;
      if P.QuadroAcao = 8 then SomPendente := 34;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 25 then P.Quadro := Desloc + 43;
      if (P.QuadroAcao >= 9) and (P.QuadroAcao <= 25) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 9);
        if P.Lado = ldEsquerda then Empurra(Jog, -9);
        P.Y := P.Y - 10;
      end;
      if P.QuadroAcao = 26 then
      begin
        P.NoAr := True;
        P.VelY := -5;
      end;
      if (P.QuadroAcao >= 9) and (O.Acao in [acApanhaAlto, acDerrubado]) then
      begin
        P.EhChute := True;
        O.Invulneravel := False;
      end;
    end;
  end;
  if P.Personagem = pnSrBarriga then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao mod 2 = 0) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao mod 2 <> 0) then P.Quadro := Desloc + 34;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 14 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 16 then P.Quadro := Desloc + 37;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 2);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -2);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 4);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -4);
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 39;
      if P.QuadroAcao >= 5 then P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 44;
      if (P.QuadroAcao > 0) and (P.QuadroAcao < 5) then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 7);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -7);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 12);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -12);
      end;
      if P.QuadroAcao >= 3 then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 45;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 46;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 6);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -6);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 11);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -11);
      P.EhChute := True;
    end;
    if (P.Acao = acEspecial5) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 38;
    if (P.Acao = acEspecial5) and (P.QuadroAcao > 2) then
    begin
      P.Quadro := Desloc + 38;
      if P.Lado = ldDireita then Empurra(Jog, 25);
      if P.Lado = ldEsquerda then Empurra(Jog, -25);
      for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
    end;
    if P.Acao = acEspecial6 then
    begin
      P.Recuo := 0;
      P.Quadro := Random(46) + 1 + Desloc;
      if Flash and (Random(5) = 0) then FlashVermelho := 3;
      if Random(3) = 0 then PausaImpacto := Random(3) + 3;
      if P.Lado = ldDireita then Empurra(Jog, 3);
      if P.Lado = ldEsquerda then Empurra(Jog, -3);
      O.Quadro := Random(2) + 26 + (50 - Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := O.Y + 10;
      if ChaoY < O.Y then O.Y := ChaoY;
      if P.Lado = ldDireita then O.X := Random(2) shl 3 + (P.X + 40);
      if P.Lado = ldEsquerda then O.X := P.X - 40 - Random(2) shl 3;
      P.Acertos := P.Acertos + 1;
      P.TempoAcertos := 43;
      if Random(4) = 0 then SomPendente := sndAcertoFraco;
      if Random(4) = 0 then SomPendente := sndAcertoForte;
      if Random(4) = 0 then SomPendente := sndAcertoEspecial;
      CriaEfeito(1, '', 0, Random(40) + (O.X - 20), Random(100) + (O.Y - 150));
      if P.QuadroAcao > P.DuracaoAcao - 2 then
      begin
        P.DanoGolpe := 36;
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        P.Acao := acParado;
        P.Quadro := Desloc + 12;
        if O.Vida > 0 then PausaImpacto := 5;
        P.QuadroAcao := 0;
        P.VelY := -48;
        P.NoAr := True;
        AcaoJogador(Jog, cmEsp3Forte);
        AcaoJogador(3 - Jog, cmDerrubar);
        O.Recuo := 30;
        O.VelY := -35;
        if O.Lado = ldDireita then O.VelAngular := -25;
        if O.Lado = ldEsquerda then O.VelAngular := 25;
      end;
    end;
  end;
  if P.Personagem = pnBruxa then
  begin
    if P.Acao = acVitoria then
    begin
      P.Quadro := Desloc + 33;
      if P.QuadroAcao mod 2 = 0 then P.Y := P.Y - 4;
      if P.QuadroAcao mod 2 <> 0 then P.Y := P.Y + 4;
      if ChaoY < P.Y then P.Y := ChaoY;
    end;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 36;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(18, 'A', Jog, P.X + 40, P.Y - 90);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(18, 'A', Jog, P.X - 40, P.Y - 90);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(18, 'B', Jog, P.X + 40, P.Y - 90);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(18, 'B', Jog, P.X - 60, P.Y - 90);
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then
      begin
        P.VelY := 0;
        P.NoAr := False;
      end;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(19, 'A', Jog, P.X + 35, P.Y - 48);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(19, 'A', Jog, P.X - 35, P.Y - 48);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(19, 'B', Jog, P.X + 35, P.Y - 48);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(19, 'B', Jog, P.X - 35, P.Y - 48);
      end;
      if P.QuadroAcao = 8 then
      begin
        P.VelY := 0;
        P.NoAr := False;
      end;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 40;
      if (P.QuadroAcao = 2) and (P.ForcaGolpe = fgFraco) then P.VelY := -25;
      if (P.QuadroAcao = 2) and (P.ForcaGolpe = fgForte) then P.VelY := -32;
      if P.QuadroAcao = 2 then
      begin
        P.DirPulo := puloNenhum;
        P.NoAr := True;
      end;
      if (P.QuadroAcao > 2) and (P.QuadroAcao < 8) then
      begin
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldDireita) then Empurra(Jog, 5);
        if (P.ForcaGolpe = fgFraco) and (P.Lado = ldEsquerda) then Empurra(Jog, -5);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldDireita) then Empurra(Jog, 12);
        if (P.ForcaGolpe = fgForte) and (P.Lado = ldEsquerda) then Empurra(Jog, -12);
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then CriaEfeito(17, '', Jog, P.Y - 90, P.X);
      if P.QuadroAcao = 0 then
      begin
        P.VelY := 0;
        P.NoAr := False;
      end;
      if P.QuadroAcao = 1 then P.Invulneravel := True;
      if P.QuadroAcao = 9 then P.Invulneravel := False;
      if P.QuadroAcao = 8 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then P.X := P.X + 80;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then P.X := P.X + 150;
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then P.X := P.X - 80;
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then P.X := P.X - 150;
        P.Y := 50;
        P.VelY := 0;
        P.DirPulo := puloNenhum;
        P.NoAr := True;
        CriaEfeito(24, '', Jog, P.X - 37, P.Y - 80);
      end;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 11 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 13 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 15 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 17 then P.Quadro := Desloc + 42;
      if P.QuadroAcao >= 8 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 5);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 8);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -5);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -8);
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then SomPendente := 42;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 33;
      if (P.QuadroAcao mod 2 = 0) and (P.QuadroAcao < 15) then
      begin
        if P.Lado = ldDireita then CriaEfeito(20, 'A', Jog, P.X + 20, P.Y - 90);
        if P.Lado = ldEsquerda then CriaEfeito(20, 'A', Jog, P.X - 20, P.Y - 90);
      end;
      O.Invulneravel := False;
    end;
  end;
  if P.Personagem = pnPaty then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao mod 3 = 0) then
    begin
      if P.Quadro = Desloc + 33 then P.Quadro := Desloc + 34
      else P.Quadro := Desloc + 33;
    end;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao mod 2 = 0 then P.Quadro := Desloc + 35
      else P.Quadro := Desloc + 36;
      if P.QuadroAcao < 2 then P.Quadro := Desloc + 19;
      if (P.QuadroAcao >= 10) and (P.ForcaGolpe = fgFraco) then P.Quadro := Desloc + 12;
      if (P.QuadroAcao >= 18) and (P.ForcaGolpe = fgForte) then P.Quadro := Desloc + 12;
      if (P.QuadroAcao < 10) and (P.ForcaGolpe = fgFraco) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 14);
        if P.Lado = ldEsquerda then Empurra(Jog, -14);
      end;
      if (P.QuadroAcao < 18) and (P.ForcaGolpe = fgForte) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 13);
        if P.Lado = ldEsquerda then Empurra(Jog, -13);
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial2 then
    begin
      P.DirPulo := puloNenhum;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 8 then
      begin
        P.VelY := -10;
        P.NoAr := True;
      end;
      if P.QuadroAcao < 8 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 6);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -6);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 12);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -12);
        if P.ForcaGolpe = fgFraco then P.Y := P.Y - 9;
        if P.ForcaGolpe = fgForte then P.Y := P.Y - 15;
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 43;
      if P.QuadroAcao < 3 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 20);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 25);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -20);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -25);
      end;
      if (P.QuadroAcao >= 6) and (P.ForcaGolpe = fgForte) then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 24;
      if P.QuadroAcao = 0 then P.VelY := 0;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 44;
      if P.QuadroAcao >= 3 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 4);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -4);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 12);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -12);
        P.Y := P.Y + 15;
        if ChaoY <= P.Y then
        begin
          P.Acao := acParado;
          P.QuadroAcao := 0;
          P.GolpeAtivo := False;
          P.Y := ChaoY;
        end;
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 0 then SomPendente := 46;
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 9 then P.Quadro := Desloc + 36;
      if (P.QuadroAcao >= 0) and (P.QuadroAcao <= 10) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 12);
        if P.Lado = ldEsquerda then Empurra(Jog, -12);
      end;
      if P.QuadroAcao = 11 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 38;
      if (P.QuadroAcao >= 12) and (P.QuadroAcao <= 18) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 15);
        if P.Lado = ldEsquerda then Empurra(Jog, -15);
        P.Y := P.Y - 18;
        P.EhChute := True;
        O.Invulneravel := False;
      end;
      if P.QuadroAcao = 22 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 22 then
      begin
        P.VelY := -14;
        P.NoAr := True;
      end;
    end;
  end;
  if P.Personagem = pnNhonho then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao < 12) then P.Quadro := Desloc + 33;
    if (P.Acao = acVitoria) and (P.QuadroAcao = 12) then P.Quadro := Desloc + 34;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      repeat
        S_0 := Random(3) + (Desloc + 35);
      until P.Quadro <> S_0;
      P.Quadro := S_0;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 2);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -2);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 3);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -3);
      if Random(5) = 0 then SomPendente := 47;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 40;
      if (P.QuadroAcao = 10) and (P.ForcaGolpe = fgFraco) then P.Quadro := Desloc + 12;
      if (P.QuadroAcao = 16) and (P.ForcaGolpe = fgForte) then P.Quadro := Desloc + 12;
      if (P.QuadroAcao >= 4) and (P.ForcaGolpe = fgFraco) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 19);
        if P.Lado = ldEsquerda then Empurra(Jog, -19);
      end;
      if (P.QuadroAcao >= 4) and (P.QuadroAcao < 16) and (P.ForcaGolpe = fgForte) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 17);
        if P.Lado = ldEsquerda then Empurra(Jog, -17);
      end;
      if P.QuadroAcao = 2 then
        for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      P.DirPulo := puloNenhum;
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 42;
      if P.QuadroAcao <= 4 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 16);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -16);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 20);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -20);
      end;
      if P.QuadroAcao >= 5 then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 44;
      if P.QuadroAcao >= 6 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 16);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -16);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 20);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -20);
        for Cont := 1 to 3 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 15 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 15 then
      begin
        P.VelY := -35;
        P.NoAr := True;
      end;
      if P.QuadroAcao = 20 then
      begin
        P.Quadro := Desloc + 42;
        P.VelY := 10;
      end;
      if (P.QuadroAcao >= 3) and (P.QuadroAcao < 15) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 13);
        if P.Lado = ldEsquerda then Empurra(Jog, -13);
      end;
      if (P.QuadroAcao >= 15) and (P.QuadroAcao < 20) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 23);
        if P.Lado = ldEsquerda then Empurra(Jog, -23);
      end;
      if P.QuadroAcao = 14 then P.EhChute := True;
      if P.QuadroAcao > 14 then O.Invulneravel := False;
    end;
  end;
  if P.Personagem = pnGodines then
  begin
    if P.Acao = acVitoria then P.Quadro := Desloc + 33;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 36;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(22, 'A', Jog, P.X + 30, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(22, 'A', Jog, P.X - 30, P.Y - 100);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(22, 'B', Jog, P.X + 30, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(22, 'B', Jog, P.X - 30, P.Y - 100);
        SomPendente := 50;
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 4 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(23, 'A', Jog, P.X + 50, P.Y);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then CriaEfeito(23, 'A', Jog, P.X - 50, P.Y);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(23, 'B', Jog, P.X + 50, P.Y);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then CriaEfeito(23, 'B', Jog, P.X - 50, P.Y);
        SomPendente := 51;
      end;
    end;
    if P.Acao = acEspecial3 then
    begin
      if (P.ForcaGolpe = fgFraco) and (P.QuadroAcao < 1) then P.Quadro := Desloc + 15;
      if (P.ForcaGolpe = fgForte) and (P.QuadroAcao < 1) then P.Quadro := Desloc + 6;
      if (P.ForcaGolpe = fgFraco) and (P.QuadroAcao >= 1) then P.Quadro := Desloc + 39;
      if (P.ForcaGolpe = fgForte) and (P.QuadroAcao >= 1) then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 1 then SomPendente := 52;
      if P.QuadroAcao >= 1 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 19);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -19);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 16);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -16);
        for Cont := 1 to 8 do CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
      if P.ForcaGolpe = fgFraco then P.EhChute := False;
      if P.ForcaGolpe = fgForte then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 41;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 7);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -7);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 12);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -12);
      if P.ForcaGolpe = fgFraco then P.Y := P.Y - 6;
      if P.ForcaGolpe = fgForte then P.Y := P.Y - 8;
      P.EhChute := True;
      if (P.Acertos >= 1) and (O.Acao = acDerrubado) then
      begin
        if P.TempoAcertos > 19 then O.Invulneravel := False;
        if P.TempoAcertos < 17 then O.Invulneravel := True;
      end;
      if P.QuadroAcao = 11 then P.VelY := -10;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 5;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 5;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 14 then P.Quadro := Desloc + 5;
      if P.QuadroAcao = 16 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 18 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 20 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 22 then P.Quadro := Desloc + 7;
      if P.QuadroAcao = 24 then P.Quadro := Desloc + 5;
      if P.QuadroAcao = 26 then P.Quadro := Desloc + 9;
      if P.QuadroAcao = 28 then P.Quadro := Desloc + 11;
      if P.QuadroAcao < 27 then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 7);
        if P.Lado = ldEsquerda then Empurra(Jog, -7);
      end;
      if P.QuadroAcao >= 27 then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 12);
        if P.Lado = ldEsquerda then Empurra(Jog, -12);
      end;
      if (P.Acertos >= 3) and (P.TempoAcertos >= 18) then O.Invulneravel := False;
      if P.QuadroAcao >= 28 then P.EhChute := True;
    end;
  end;
  if P.Personagem = pnSrFurtado then
  begin
    if P.Acao = acVitoria then
    begin
      if P.QuadroAcao mod 2 = 0 then P.Quadro := Desloc + 33
      else P.Quadro := Desloc + 34;
      if P.Lado = ldDireita then P.X := P.X + 12;
      if P.Lado = ldEsquerda then P.X := P.X - 12;
      if P.X - CameraX <= 100 then P.Lado := ldDireita;
      if P.X - CameraX >= 300 then P.Lado := ldEsquerda;
      if (P.QuadroAcao mod 8 = 0) and (Random(2) = 0) then
      begin
        if P.Lado = ldDireita then P.Lado := ldEsquerda
        else if P.Lado = ldEsquerda then P.Lado := ldDireita;
      end;
      for Cont := 1 to 5 do CriaEfeito(2, '', 0, Random(40) + (P.X - 30), Random(10) + P.Y);
    end;
    if (P.Acao = acPose) and (P.QuadroAcao = 0) then P.Quadro := Desloc + 12;
    if (P.Acao = acPose) and (P.QuadroAcao = 2) then P.Quadro := Desloc + 30;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 37;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(9, 'A', Jog, P.X + 35, P.Y - 105);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(9, 'A', Jog, P.X - 35, P.Y - 105);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(9, 'B', Jog, P.X + 35, P.Y - 105);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(9, 'B', Jog, P.X - 35, P.Y - 105);
        SomPendente := 53;
      end;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then
      begin
        P.Quadro := Desloc + 38;
        SomPendente := 54;
      end;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 39;
      if ((P.QuadroAcao = 8) and (P.ForcaGolpe = fgFraco)) or ((P.QuadroAcao = 10) and (P.ForcaGolpe = fgForte)) then
      begin
        P.Quadro := Desloc + 40;
        P.NoAr := True;
        P.VelY := -6;
      end;
      if P.Quadro = Desloc + 39 then
      begin
        if P.ForcaGolpe = fgFraco then
        begin
          P.Y := P.Y - 15;
          if P.Lado = ldDireita then Empurra(Jog, 4);
          if P.Lado = ldEsquerda then Empurra(Jog, -4);
        end;
        if P.ForcaGolpe = fgForte then
        begin
          P.Y := P.Y - 17;
          if P.Lado = ldDireita then Empurra(Jog, 8);
          if P.Lado = ldEsquerda then Empurra(Jog, -8);
        end;
      end;
      if P.Quadro = Desloc + 40 then P.NoAr := True;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 6 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 14 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 16 then P.Quadro := Desloc + 41;
      P.Y := P.Y - 11;
      P.Y := P.QuadroAcao + P.Y;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 10);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -10);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 15);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -15);
      if P.QuadroAcao = 2 then SomPendente := 55;
      if P.QuadroAcao = 8 then SomPendente := 55;
      if P.QuadroAcao = 14 then SomPendente := 56;
      if (P.QuadroAcao >= 6) and (P.QuadroAcao <= 16) then O.Invulneravel := False;
      if P.QuadroAcao >= 10 then P.EhChute := True;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 13 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 25 then P.Quadro := Desloc + 40;
      if P.QuadroAcao <= 8 then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 15);
        if P.Lado = ldEsquerda then Empurra(Jog, -15);
      end;
      if (P.QuadroAcao >= 13) and (P.QuadroAcao < 25) then
      begin
        P.Y := P.Y - 12;
        if P.Lado = ldDireita then Empurra(Jog, 4);
        if P.Lado = ldEsquerda then Empurra(Jog, -4);
      end;
      if P.QuadroAcao = 25 then
      begin
        P.NoAr := True;
        P.DirPulo := puloNenhum;
        P.VelY := -8;
      end;
      O.Recuo := 0;
      if P.QuadroAcao >= 13 then
      begin
        P.EhChute := True;
        O.Invulneravel := False;
      end;
    end;
  end;
  if P.Personagem = pnJaiminho then
  begin
    if P.Acao = acVitoria then
    begin
      P.Quadro := Desloc + 33;
      P.Y := P.Y - Round(Cos(P.QuadroAcao / 3) * 6);
      if ChaoY - 10 < P.Y then P.Y := ChaoY - 10;
    end;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 36;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(26, 'A', Jog, P.X + 30, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(26, 'A', Jog, P.X - 30, P.Y - 100);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(26, 'B', Jog, P.X + 30, P.Y - 100);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(26, 'B', Jog, P.X - 30, P.Y - 100);
      end;
      if P.QuadroAcao = 3 then SomPendente := 57;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 11 then P.Quadro := Desloc + 41;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 8);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -8);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 13);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -13);
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao mod 2 = 0 then P.Quadro := Desloc + 42
      else P.Quadro := Desloc + 43;
      if P.QuadroAcao = 3 then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(27, 'A', Jog, P.X + 45, P.Y - 78);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(27, 'A', Jog, P.X - 45, P.Y - 78);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(27, 'B', Jog, P.X + 45, P.Y - 78);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(27, 'B', Jog, P.X - 45, P.Y - 78);
      end;
      if P.QuadroAcao = 3 then SomPendente := 58;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 33;
      if P.QuadroAcao = 10 then
      begin
        CriaEfeito(17, '', Jog, P.Y - 90, P.X);
        CriaEfeito(17, '', Jog, CameraX + 80, CameraY + 110);
        CriaEfeito(17, '', Jog, CameraX + 160, CameraY + 110);
        CriaEfeito(17, '', Jog, CameraX + 240, CameraY + 110);
        CriaEfeito(17, '', Jog, CameraX + $140, CameraY + 110);
        if P.ForcaGolpe = fgFraco then P.X := CameraX + 80;
        if P.ForcaGolpe = fgForte then P.X := CameraX + 160;
        if P.ForcaGolpe = fgEspecial then P.X := CameraX + 240;
        if P.ForcaGolpe = 4 then P.X := CameraX + $140;
        P.Y := CameraY + 150;
        P.NoAr := True;
        P.VelY := 0;
        SomPendente := 41;
      end;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao mod 2 = 0 then P.Quadro := Desloc + 44
      else P.Quadro := Desloc + 45;
      if P.Lado = ldDireita then Empurra(Jog, 14);
      if P.Lado = ldEsquerda then Empurra(Jog, -14);
      if P.Acertos > 1 then O.Invulneravel := False;
      if P.QuadroAcao >= 15 then P.EhChute := True;
      if P.QuadroAcao = 2 then SomPendente := 59;
    end;
  end;
  if P.Personagem = pnDonaNeves then
  begin
    if (P.Acao = acVitoria) and (P.QuadroAcao mod 3 = 0) then
    begin
      if P.Quadro = Desloc + 33 then P.Quadro := Desloc + 34
      else P.Quadro := Desloc + 33;
    end;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 35;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 37;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(29, 'A', Jog, P.X + 30, P.Y - 85);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(29, 'A', Jog, P.X - 30, P.Y - 85);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(29, 'B', Jog, P.X + 30, P.Y - 85);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(29, 'B', Jog, P.X - 30, P.Y - 85);
      end;
      if P.QuadroAcao = 3 then SomPendente := 60;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 5 then
      begin
        P.Quadro := Desloc + 39;
        if P.Lado = ldDireita then CriaEfeito(30, 'A', Jog, P.X + 42, P.Y - 93);
        if P.Lado = ldEsquerda then CriaEfeito(30, 'A', Jog, P.X - 42, P.Y - 93);
      end;
      if P.QuadroAcao = 32 then P.Quadro := Desloc + 38;
      if P.QuadroAcao = 3 then SomPendente := 61;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 1 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 42;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 9 then P.QuadroAcao := 1;
      if P.QuadroAcao = 0 then SomPendente := 62;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 6);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -6);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 9);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -9);
      P.Y := P.Y + 8;
    end;
    if P.Acao = acEspecial4 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 3 then P.Quadro := Desloc + 45;
      if P.QuadroAcao = 5 then P.Quadro := Desloc + 46;
      if (P.QuadroAcao >= 4) and (P.QuadroAcao <= 15) then
      begin
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, 4);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -4);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, 8);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -8);
        if P.ForcaGolpe = fgFraco then P.Y := P.Y - 6;
        if P.ForcaGolpe = fgForte then P.Y := P.Y - 9;
      end;
      if P.QuadroAcao = 17 then
      begin
        P.NoAr := True;
        P.DirPulo := puloNenhum;
        P.VelY := -2;
        P.Quadro := Desloc + 21;
      end;
      if P.QuadroAcao = 2 then SomPendente := 60;
      P.EhChute := True;
    end;
    if P.Acao = acEspecial5 then
    begin
      if P.QuadroAcao mod 2 = 0 then
      begin
        if P.Quadro = Desloc + 47 then P.Quadro := Desloc + 48
        else P.Quadro := Desloc + 47;
      end;
      if P.QuadroAcao = 1 then
      begin
        CriaEfeito(31, 'A', Jog, P.Y - 80, P.X);
        CriaEfeito(32, 'A', Jog, P.Y - 80, P.X);
      end;
    end;
  end;
  if P.Personagem = pnGloria then
  begin
    if P.Acao = acVitoria then
    begin
      if P.QuadroAcao <= 10 then P.Quadro := Desloc + 33;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 34;
      if P.QuadroAcao = 14 then P.Quadro := Desloc + 35;
    end;
    if P.Acao = acEspecial1 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 36;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 37;
      if P.QuadroAcao = 10 then
      begin
        P.Quadro := Desloc + 38;
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then CriaEfeito(33, 'A', Jog, P.X + 60, P.Y - 92);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then
          CriaEfeito(33, 'A', Jog, P.X - 60, P.Y - 92);
        if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then CriaEfeito(33, 'B', Jog, P.X + 60, P.Y - 92);
        if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then
          CriaEfeito(33, 'B', Jog, P.X - 60, P.Y - 92);
      end;
      if P.QuadroAcao = 3 then SomPendente := 63;
    end;
    if P.Acao = acEspecial2 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 39;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 40;
      if P.QuadroAcao = 8 then P.Quadro := Desloc + 41;
      if P.QuadroAcao = 12 then P.Quadro := Desloc + 42;
      if (P.QuadroAcao >= 2) and (P.QuadroAcao <= 4) and (P.ForcaGolpe = fgForte) then
      begin
        if P.Lado = ldDireita then Empurra(Jog, 15);
        if P.Lado = ldEsquerda then Empurra(Jog, -15);
      end;
      if P.QuadroAcao = 3 then
      begin
        if P.Lado = ldDireita then CriaEfeito(34, 'A', Jog, P.X + 65, P.Y - 30);
        if P.Lado = ldEsquerda then CriaEfeito(34, 'A', Jog, P.X - 65, P.Y - 30);
      end;
      if P.QuadroAcao = 1 then SomPendente := 64;
    end;
    if P.Acao = acEspecial3 then
    begin
      if P.QuadroAcao = 0 then P.Quadro := Desloc + 43;
      if P.QuadroAcao = 2 then P.Quadro := Desloc + 44;
      if P.QuadroAcao = 4 then P.Quadro := Desloc + 45;
      if P.QuadroAcao = 7 then P.Quadro := Desloc + 46;
      if P.QuadroAcao = 10 then P.Quadro := Desloc + 47;
      if P.QuadroAcao = 13 then P.Quadro := Desloc + 48;
      if P.QuadroAcao = 16 then P.Quadro := Desloc + 12;
      if P.QuadroAcao = 5 then
      begin
        if P.Lado = ldDireita then CriaEfeito(35, 'A', Jog, P.X + 40, P.Y - 160);
        if P.Lado = ldEsquerda then CriaEfeito(35, 'A', Jog, P.X - 40, P.Y - 160);
      end;
      if (P.QuadroAcao >= 0) and (P.QuadroAcao <= 8) then
      begin
        if P.ForcaGolpe = fgFraco then P.Y := P.Y - 6;
        if P.ForcaGolpe = fgForte then
        begin
          P.Y := P.Y - 10;
          if P.QuadroAcao <= 2 then
          begin
            if P.Lado = ldDireita then Empurra(Jog, 10);
            if P.Lado = ldEsquerda then Empurra(Jog, -10);
          end;
          if P.QuadroAcao >= 3 then
          begin
            if P.Lado = ldDireita then Empurra(Jog, 3);
            if P.Lado = ldEsquerda then Empurra(Jog, -3);
          end;
        end;
      end;
      if P.QuadroAcao = 9 then
      begin
        P.NoAr := True;
        P.VelY := -5;
      end;
      if P.QuadroAcao = 1 then SomPendente := 65;
      P.EhChute := True;
      if P.QuadroAcao <= 3 then O.Invulneravel := False;
    end;
    if P.Acao = acEspecial4 then
    begin
      P.Quadro := Desloc + 49;
      S_2 := 18 - P.QuadroAcao;
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, S_2);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgFraco) then Empurra(Jog, -S_2);
      if (P.Lado = ldDireita) and (P.ForcaGolpe = fgForte) then Empurra(Jog, S_2 * 1.3);
      if (P.Lado = ldEsquerda) and (P.ForcaGolpe = fgForte) then Empurra(Jog, -(S_2 * 1.3));
      S_2 := ShortInt(P.QuadroAcao + 248);
      P.Y := S_2 + P.Y;
      if P.QuadroAcao = 1 then SomPendente := 66;
      P.EhChute := True;
      if P.QuadroAcao <= 3 then O.Invulneravel := False;
    end;
    if P.Acao = acEspecial5 then
    begin
      P.Quadro := Desloc + 50;
      S_2 := 22 - P.QuadroAcao;
      if S_2 < 1 then S_2 := 1;
      if P.Lado = ldDireita then Empurra(Jog, S_2);
      if P.Lado = ldEsquerda then Empurra(Jog, -S_2);
      if P.QuadroAcao < 20 then
      begin
        if P.Lado = ldDireita then CriaEfeito(36, 'A', Jog, P.X - 30, Random(20) + (P.Y - 110));
        if P.Lado = ldEsquerda then CriaEfeito(36, 'A', Jog, P.X + 30, Random(20) + (P.Y - 110));
      end;
      S_2 := ShortInt(Round(P.QuadroAcao * 0.4) + 251);
      P.Y := S_2 + P.Y;
      if P.QuadroAcao = 1 then SomPendente := 66;
      if P.QuadroAcao >= 15 then P.EhChute := True;
      if P.QuadroAcao <= 15 then O.Invulneravel := False;
    end;
  end;
  { caixas de colisao do quadro atual (Dados/Lutadores/Cnn.ini) }
  AplicarCaixas(Jog);
end;

end.