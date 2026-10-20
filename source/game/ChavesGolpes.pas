unit ChavesGolpes;

{ Logica dos lutadores durante a luta: acoes (pular, golpear, defender...), escolha do
  quadro de animacao, caixas de colisao, danos e efeitos.
  Recuperado do executavel original (unidades Unit29/Unit30 do projeto Delphi): as rotinas
  AcaoJogador e AtualizaQuadro foram convertidas automaticamente do codigo de maquina e
  depois revisadas; os nomes de campos estao em ChavesTipos.pas / NOMES.md. }

{$mode delphi}{$H+}

interface

uses
  SysUtils, Math, ChavesConst, ChavesTipos;

{ Move o lutador Jog horizontalmente por Dx e o separa do oponente (nao deixa atravessar). }
procedure Empurra(Jog: Byte; Dx: Double);
{ Define a caixa de colisao do corpo quando o lutador esta no quadro (sprite) Quadro. }
procedure DefineCaixaCorpo(Jog, Quadro: Byte; X1, Y1, X2, Y2: Integer);
{ Define a caixa de ataque (e dano) quando o lutador esta na acao Acao, no quadro QuadroAcao. }
procedure DefineCaixaAtaque(Jog, Acao: Byte; QuadroAcao: Integer; X1, Y1, X2, Y2: Integer;
  Ativo, Forca, Dano, DanoDefesa: Byte);
procedure DefineCaixaEfeito(Slot, X1, Y1, X2, Y2: Integer);
{ 1 se ja existe um efeito deste Tipo criado por Dono (limita projeteis); sempre 0 com o truque Bruxa. }
function ExisteEfeito(Tipo, Dono: Byte): Byte;
{ Cria um efeito (fumaca, sangue, bola de fogo, texto...) na primeira posicao livre. }
procedure CriaEfeito(Tipo: Byte; const Texto: string; Dono: Byte; X, Y: Double);
{ Deslocamento horizontal do centro do sprite atual do lutador (para desenhar centralizado). }
function CentroX(Jog: Byte): Integer;
{ Executa uma acao pedida ao lutador (andar, pular, golpe...); Codigo = botao/direcao. }
procedure AcaoJogador(Jog, Codigo: Byte);
{ Avanca a animacao do lutador, escolhe o quadro, define as caixas e aplica os golpes. }
procedure AtualizaQuadro(Jog: Byte);

implementation

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
     (P.Acao <> 23) and (P.Acao <> 20) then
  begin
    if (P.X <= O.X) and (RelogioParado = 0) then
    begin
      O.X := O.X + 5;
      if O.X > CameraX + 370 then O.X := CameraX + 370;
      P.X := ((O.CorpoX1 + O.X) - P.CorpoX2) - 5;
    end;
    if (P.X > O.X) and (RelogioParado = 0) then
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
  if P.Lado = 2 then
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
  if P.Lado = 2 then
  begin
    P.AtaqueX1 := -X2;
    P.AtaqueX2 := -X1;
  end;
  P.GolpeAtivo := Ativo;
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

function ExisteEfeito(Tipo, Dono: Byte): Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to MaxEfeitos do
    if (Efeitos[I].Tipo = Tipo) and (CheatBruxa = 0) and (Efeitos[I].Dono = Dono) then
      Result := 1;
end;


procedure CriaEfeito(Tipo: Byte; const Texto: string; Dono: Byte; X, Y: Double);
var
  Slot, L_c: Integer;
  r34, r37, r45: Integer;
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
    E.Estagio := 0;
    E.Lado := 1;
    E.Vel := 0;
    E.PodeAcertar := 0;
    E.Variante := 0;
    E.CaixaX1 := 0;
    E.CaixaY1 := 0;
    E.CaixaX2 := 0;
    E.CaixaY2 := 0;
    E.Dono := Dono;
    E.Terminando := 0;
    E.Contagem := 0;
    E.LimiteContagem := 0;
    E.Flag50 := 0;
    E.Flag51 := 0;
    E.Flag52 := 0;
    E.Dano := 0;
    E.DanoDefesa := 0;
    if E.Tipo = 1 then
    begin
      E.Duracao := 3;
    end;
    if E.Tipo = 2 then
    begin
      E.Duracao := 15;
      E.Flag51 := 1;
    end;
    if (E.Tipo = 3) or ((E.Tipo) = 4) then
    begin
      E.Duracao := 80;
      E.VelY := -22;
      E.Flag52 := 1;
      DefineCaixaEfeito(Slot, -12, -8, 12, 10);
    end;
    if E.Tipo = 5 then
    begin
      E.Duracao := 20;
    end;
    if E.Tipo = 6 then
    begin
      E.Duracao := 99;
      E.VelY := -22;
      E.Flag52 := 1;
      E.Lado := Lutador[Dono].Lado;
      E.Vel := 5;
    end;
    if E.Tipo = 7 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      E.Flag51 := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -25, -38, 25, 0);
    end;
    if E.Tipo = 8 then
    begin
      E.Duracao := 23;
      E.PodeAcertar := 1;
      E.Flag51 := 1;
      E.Dano := 40;
      E.DanoDefesa := Round(E.Dano / 15);
      E.Variante := 1;
      E.Terminando := 1;
      E.Lado := Lutador[Dono].Lado;
      DefineCaixaEfeito(Slot, -30, -50, 30, 0);
    end;
    if E.Tipo = 9 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -20, -14, 20, 75);
    end;
    if E.Tipo = 10 then
    begin
      E.Duracao := 14;
    end;
    if E.Tipo = 11 then
    begin
      E.Duracao := 15;
    end;
    if E.Tipo = 12 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -20, -20, 20, 85);
    end;
    if E.Tipo = 13 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -25, -10, 25, 80);
    end;
    if E.Tipo = 14 then
    begin
      E.Duracao := 6;
    end;
    if E.Tipo = 15 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -25, -25, 25, 37);
    end;
    if E.Tipo = 16 then
    begin
      E.Duracao := 3;
      E.Lado := Lutador[Dono].Lado;
    end;
    if E.Tipo = 17 then
    begin
      E.Duracao := 10;
    end;
    if E.Tipo = 18 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -30, -10, 30, 80);
    end;
    if E.Tipo = 19 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 5;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 7;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -12, -10, 12, 20);
    end;
    if E.Tipo = 20 then
    begin
      E.Duracao := 5;
      E.PodeAcertar := 1;
      E.Lado := Lutador[Dono].Lado;
      E.Vel := Random(2)+10;
      E.Dano := 7;
      E.DanoDefesa := Round(E.Dano / 4);
      E.Variante := 1;
      DefineCaixaEfeito(Slot, -8, -5, 8, 5);
    end;
    if E.Tipo = 21 then
    begin
      E.Duracao := 23;
      r34 := Random(5);
      E.VelY := -23-(r34+(r34*4));
      E.Flag52 := 1;
      E.Lado := Random(2)+1;
      E.Vel := Random(10);
      r37 := Random(3);
      E.Sprite := r37+53;
    end;
    if E.Tipo = 22 then
    begin
      E.Duracao := 20;
      E.Sprite := 56;
      E.Flag52 := 1;
      if Texto = 'A' then
      begin
        E.VelY := -13;
      end;
      if Texto = 'B' then
      begin
        E.VelY := -17;
      end;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 10;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 13;
      end;
      E.Dano := 10;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -12, -5, 12, 5);
    end;
    if E.Tipo = 23 then
    begin
      E.Duracao := 26;
      E.PodeAcertar := 1;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      E.Lado := Lutador[Dono].Lado;
      E.Terminando := 1;
      E.Variante := 1;
      E.Flag51 := 1;
      DefineCaixaEfeito(Slot, -30, -145, 30, 0);
    end;
    if E.Tipo = 24 then
    begin
      r45 := Random(15);
      E.Duracao := r45+15;
    end;
    if E.Tipo = 25 then
    begin
      E.Duracao := 36;
    end;
    if E.Tipo = 26 then
    begin
      E.Duracao := 6;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -25, -25, 25, 70);
    end;
    if E.Tipo = 27 then
    begin
      E.Duracao := 6;
      E.Dano := 0;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 3;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 4;
      end;
      if Texto = 'A' then
      begin
        E.LimiteContagem := 22;
      end;
      if Texto = 'B' then
      begin
        E.LimiteContagem := 35;
      end;
    end;
    if E.Tipo = 28 then
    begin
      E.Duracao := 4;
      E.LimiteContagem := 20;
      E.PodeAcertar := 1;
      E.Terminando := 1;
      E.Dano := 2;
      E.DanoDefesa := Round(E.Dano / 4);
      E.Lado := Lutador[Dono].Lado;
      DefineCaixaEfeito(Slot, -40, -40, 40, 40);
    end;
    if E.Tipo = 29 then
    begin
      E.Duracao := 6;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -25, -25, 25, 70);
    end;
    if E.Tipo = 30 then
    begin
      E.Duracao := 5;
      E.LimiteContagem := 25;
      E.PodeAcertar := 1;
      E.Terminando := 1;
      E.Lado := Lutador[Dono].Lado;
      E.Variante := 1;
      E.Flag50 := 1;
      E.Vel := 0;
      E.Dano := 10;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -15, -30, 15, 30);
    end;
    if (E.Tipo = 31) or ((E.Tipo) = 32) then
    begin
      E.Duracao := 6;
      E.LimiteContagem := 70;
      E.PodeAcertar := 1;
      E.Terminando := 1;
      E.Variante := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      E.Dano := 35;
      E.DanoDefesa := Round(E.Dano / 15);
      DefineCaixaEfeito(Slot, -25, -25, 25, 70);
    end;
    if E.Tipo = 33 then
    begin
      E.Duracao := 6;
      E.PodeAcertar := 1;
      if Random(5) = 0 then
      begin
        E.Variante := 1;
      end;
      E.Lado := Lutador[Dono].Lado;
      if Texto = 'A' then
      begin
        E.Vel := 8;
      end;
      if Texto = 'B' then
      begin
        E.Vel := 11;
      end;
      E.Dano := 12;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -18, -15, 18, 70);
    end;
    if E.Tipo = 34 then
    begin
      E.Duracao := 20;
      E.PodeAcertar := 1;
      E.Flag51 := 1;
      E.Terminando := 1;
      E.Variante := 1;
      E.Lado := Lutador[Dono].Lado;
      E.Dano := 18;
      E.DanoDefesa := Round(E.Dano / 4);
      DefineCaixaEfeito(Slot, -45, -75, 45, 30);
    end;
    if E.Tipo = 35 then
    begin
      E.Duracao := 10;
      E.Lado := Lutador[Dono].Lado;
    end;
    if E.Tipo = 36 then
    begin
      E.Duracao := 10;
      E.Lado := Lutador[Dono].Lado;
    end;
    Exit;
  end;
end;

function CentroX(Jog: Byte): Integer;
var
  Desloc, Idx: Integer;
begin
  Result := 0;
  Desloc := 0;
  if Jog = 2 then Desloc := 50;
  Idx := Lutador[Jog].Quadro - Desloc;
  case Lutador[Jog].Personagem of
    1:
      case Idx of
        1: Result := 33;
        2, 3: Result := 27;
        4, 19, 24, 26, 48, 49: Result := 30;
        5: Result := 28;
        6: Result := 22;
        7: Result := 21;
        8: Result := 29;
        9, 20: Result := 25;
        10: Result := 18;
        11: Result := 8;
        12, 21, 22, 25, 27, 28, 32, 33, 39, 42, 47: Result := 40;
        13: Result := 39;
        14, 38: Result := 38;
        15, 17, 41: Result := 42;
        16: Result := 43;
        18: Result := 41;
        23, 46: Result := 50;
        29, 40: Result := 55;
        30: Result := 35;
        31: Result := 20;
        34: Result := 15;
        35, 37: Result := 48;
        36: Result := 80;
        43, 44, 45: Result := 60;
      end;
    2:
      case Idx of
        1, 4, 5, 6, 37: Result := 32;
        2: Result := 22;
        3: Result := 23;
        7: Result := 15;
        8, 9, 23, 31: Result := 30;
        10: Result := 55;
        11: Result := 17;
        12, 13, 14, 15, 16, 17, 18, 27, 28, 30, 32: Result := 44;
        19, 45: Result := 58;
        20, 38, 41, 42, 43: Result := 38;
        21, 22, 26: Result := 35;
        24: Result := 40;
        25: Result := 49;
        29: Result := 62;
        33, 34: Result := 27;
        35, 39: Result := 20;
        36: Result := 43;
        40: Result := 48;
        44: Result := 34;
      end;
    3:
      case Idx of
        1, 2, 3, 4, 7: Result := 22;
        5, 10, 49, 50: Result := 20;
        6, 31: Result := 28;
        8, 44: Result := 27;
        9: Result := 25;
        11, 12, 30: Result := 45;
        13, 14: Result := 41;
        15, 16, 22, 23, 24: Result := 34;
        17, 18, 34: Result := 38;
        19, 25: Result := 42;
        20: Result := 46;
        21: Result := 18;
        26, 27, 37, 39, 40, 41, 45: Result := 23;
        28, 29: Result := 50;
        32, 38: Result := 32;
        33: Result := 29;
        35: Result := 31;
        36: Result := 26;
        42: Result := 40;
        43: Result := 33;
        46: Result := 17;
        47: Result := 60;
        48: Result := 30;
      end;
    4:
      case Idx of
        1, 2, 6: Result := 22;
        3, 4: Result := 26;
        5: Result := 23;
        7: Result := 18;
        8, 11, 19, 20, 24, 25, 26, 27, 28: Result := 40;
        9: Result := 15;
        10, 21: Result := 30;
        12, 13, 14, 34: Result := 50;
        15, 16, 17, 31, 32, 35, 36, 37: Result := 45;
        18: Result := 42;
        22, 23: Result := 25;
        29, 33: Result := 55;
        30: Result := 35;
        38, 41: Result := 75;
        39, 40: Result := 85;
        42, 43, 44, 45: Result := 48;
      end;
    5:
      case Idx of
        1, 2, 3, 4, 5, 9, 10, 11: Result := 16;
        6, 7: Result := 18;
        8, 12, 13, 15, 17: Result := 37;
        14, 16, 18: Result := 36;
        19, 20, 21: Result := 22;
        22, 23: Result := 38;
        24, 25, 26, 28, 30, 32, 36, 37, 47: Result := 33;
        27: Result := 23;
        29: Result := 58;
        31: Result := 20;
        33, 35: Result := 19;
        34: Result := 43;
        38: Result := 15;
        39, 41: Result := 55;
        40, 45: Result := 35;
        42: Result := 50;
        43: Result := 65;
        44: Result := 76;
        46: Result := 34;
      end;
    6:
      case Idx of
        1, 26, 27, 40, 42: Result := 30;
        2: Result := 16;
        3, 33, 34: Result := 20;
        4: Result := 27;
        5, 6, 7, 8, 9: Result := 26;
        10: Result := 8;
        11, 36: Result := 25;
        12, 13, 14, 15, 16, 17, 18, 19, 21, 39: Result := 32;
        20: Result := 62;
        22: Result := 42;
        23: Result := 52;
        24, 43: Result := 45;
        25, 30, 31: Result := 40;
        28, 38: Result := 60;
        29, 44: Result := 70;
        32: Result := 35;
        35: Result := 47;
        37: Result := 23;
        41: Result := 50;
      end;
    7:
      case Idx of
        1, 2, 3, 26, 37: Result := 25;
        4, 18: Result := 32;
        5, 6, 7, 20, 35: Result := 28;
        8, 10: Result := 20;
        9, 11, 23, 24, 25, 27, 31: Result := 18;
        12, 21, 28, 30, 32, 38, 39, 40, 41, 42, 43, 44, 45, 46: Result := 35;
        13, 15, 17: Result := 34;
        14, 16: Result := 33;
        19: Result := 30;
        22: Result := 22;
        29: Result := 60;
        33: Result := 40;
        34: Result := 41;
        36: Result := 23;
      end;
    8:
      case Idx of
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 31, 32, 35, 36, 37, 38, 40: Result := 25;
        28: Result := 50;
        29, 34: Result := 60;
        30: Result := 28;
        33, 39: Result := 35;
        41: Result := 22;
        42, 43: Result := 72;
      end;
    9:
      case Idx of
        1, 2, 3, 4, 5, 6, 7, 8, 31, 33, 34: Result := 18;
        9: Result := 11;
        10, 11, 21, 22, 23, 24, 25, 26: Result := 32;
        12, 13, 14, 15, 16, 17, 18, 19, 20, 32: Result := 42;
        27: Result := 22;
        28: Result := 38;
        29, 37: Result := 45;
        30, 40: Result := 30;
        35, 36, 39: Result := 55;
        38: Result := 50;
        41: Result := 28;
        42: Result := 26;
        43: Result := 15;
        44: Result := 20;
      end;
    10:
      case Idx of
        1, 4, 5, 6, 7, 20: Result := 23;
        2, 19: Result := 27;
        3, 12, 13, 14, 15, 16, 17: Result := 32;
        8, 18, 30, 32, 35, 36, 37, 38: Result := 30;
        9: Result := 21;
        10, 28: Result := 35;
        11: Result := 0;
        21, 22, 23, 24, 25, 31, 33, 34, 39: Result := 20;
        26, 27: Result := 28;
        29: Result := 55;
        40: Result := 80;
        41: Result := 50;
        42: Result := 40;
        43: Result := 45;
        44: Result := 25;
      end;
    11:
      case Idx of
        1: Result := 23;
        2, 8: Result := 18;
        3, 9: Result := 16;
        4, 5, 6, 7: Result := 20;
        10, 41: Result := 30;
        11: Result := 5;
        12, 34: Result := 45;
        13, 15: Result := 44;
        14, 16, 17, 18: Result := 43;
        19, 24, 35, 36, 37, 38, 40: Result := 25;
        20, 21, 22, 23, 25, 26, 27, 31: Result := 32;
        28, 39: Result := 40;
        29: Result := 55;
        30: Result := 36;
        32: Result := 42;
        33: Result := 15;
        42: Result := 70;
      end;
    12:
      case Idx of
        1, 2, 21: Result := 25;
        3, 4, 5, 22, 23: Result := 30;
        6, 11: Result := 17;
        7, 9: Result := 16;
        8: Result := 20;
        10: Result := 22;
        12: Result := 48;
        13: Result := 46;
        14, 15, 16, 17, 18, 20: Result := 44;
        19, 36: Result := 42;
        24, 37, 38, 39, 40, 41, 42, 43, 44: Result := 35;
        25: Result := 40;
        26, 27: Result := 38;
        28: Result := 60;
        29: Result := 70;
        30, 32, 33, 34, 35: Result := 45;
        31: Result := 28;
      end;
    13:
      case Idx of
        1, 5, 6, 7: Result := 28;
        2, 4, 26, 27: Result := 30;
        3, 37, 38, 39, 40, 41: Result := 32;
        8, 34, 35, 36: Result := 22;
        9: Result := 18;
        10: Result := 25;
        11: Result := 10;
        12, 13, 14, 15, 16: Result := 50;
        17, 18, 19: Result := 46;
        20: Result := 52;
        21, 22, 23, 30, 32: Result := 40;
        24, 25: Result := 70;
        28, 29: Result := 65;
        31: Result := 35;
        33: Result := 17;
        42, 43: Result := 38;
        44, 45: Result := 80;
      end;
    14:
      case Idx of
        1, 2, 3, 4, 5, 21, 31, 32, 36, 37, 38, 39, 40, 42: Result := 25;
        6, 20, 27, 30: Result := 35;
        7: Result := 38;
        8: Result := 18;
        9: Result := 16;
        10: Result := 50;
        11: Result := 56;
        12, 15, 16, 44, 45: Result := 28;
        13: Result := 27;
        14: Result := 26;
        17: Result := 24;
        18, 46: Result := 22;
        19, 22, 23: Result := 30;
        24, 26: Result := 40;
        25: Result := 45;
        28, 29, 35: Result := 55;
        33, 34: Result := 32;
        41, 43: Result := 42;
        47: Result := 58;
        48: Result := 60;
      end;
    15:
      case Idx of
        1, 3, 11, 31: Result := 25;
        2: Result := 20;
        4: Result := 12;
        5: Result := 14;
        6, 7: Result := 21;
        8: Result := 23;
        9: Result := 9;
        10, 32, 39, 41: Result := 35;
        12, 13, 14, 15, 16, 17, 18, 19, 20, 24, 25, 28, 35, 40, 47: Result := 45;
        21, 22, 23, 26, 27, 44: Result := 30;
        29: Result := 70;
        30, 48: Result := 50;
        33: Result := 33;
        34, 36, 38: Result := 32;
        37: Result := 28;
        42, 45, 46: Result := 55;
        43: Result := 40;
        49, 50: Result := 60;
      end;
  end;
end;

procedure AcaoJogador(Jog, Codigo: Byte);
var
  P, O: PLutador;
  Desloc, Cont: Integer;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  if Jog = 1 then
  begin
    Desloc := 0;
  end;
  if Jog = 2 then
  begin
    Desloc := 50;
  end;
  P.Defendendo := 0;
  if (Codigo = 1) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
  begin
    Empurra(Jog, -(P.Velocidade));
    P.Acao := 2;
    P.DuracaoAcao := 99;
    P.Campo_148 := 0;
    if (P.Lado) = 2 then
    begin
      P.Campo_148 := 1;
    end;
  end;
  if (Codigo = 2) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
  begin
    Empurra(Jog, P.Velocidade);
    P.Acao := 2;
    P.DuracaoAcao := 99;
    P.Campo_148 := 0;
    if (P.Lado) = 1 then
    begin
      P.Campo_148 := 1;
    end;
  end;
  if (Codigo = 3) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21)) and ((P.VelY) = 0) then
  begin
    P.Acao := 3;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 4) and (((P.Acao) = 1) or ((P.Acao) = 2) or (((P.Acao) <> 3) and ((P.Acao) = 21)) or (((P.Acao) = 3) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 21)))) and ((P.VelY) = 0) then
  begin
    P.Acao := 4;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 5) and (((P.Acao) = 1) or ((P.Acao) = 2) or (((P.Acao) <> 3) and ((((P.Acao) <> 4) and ((P.Acao) = 21)) or (((P.Acao) = 4) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 21))))) or (((P.Acao) = 3) and (((P.QuadroAcao) >= 2) or (((P.Acao) <> 4) and ((P.Acao) = 21)) or (((P.Acao) = 4) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 21)))))) and ((P.VelY) = 0) then
  begin
    P.Acao := 5;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
  end;
  if (Codigo = 6) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21)) and ((P.VelY) = 0) and ((P.NoAr) = 0) then
  begin
    P.Acao := 6;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
  end;
  if (Codigo = 7) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
  begin
    P.Acao := 7;
    P.DuracaoAcao := 99;
  end;
  if (Codigo = 3) and (((P.Acao) = 7) or ((P.Acao) = 22)) then
  begin
    P.Acao := 8;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 4) and (((P.Acao) = 7) or (((P.Acao) <> 8) and ((P.Acao) = 22)) or (((P.Acao) = 8) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 22)))) then
  begin
    P.Acao := 9;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 6;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 5) and (((P.Acao) = 7) or (((P.Acao) <> 8) and ((((P.Acao) <> 9) and ((P.Acao) = 22)) or (((P.Acao) = 9) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 22))))) or (((P.Acao) = 8) and (((P.QuadroAcao) >= 2) or (((P.Acao) <> 9) and ((P.Acao) = 22)) or (((P.Acao) = 9) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 22)))))) then
  begin
    P.Acao := 10;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
  end;
  if (Codigo = 6) and (((P.Acao) = 7) or (((P.Acao) <> 9) and ((P.Acao) = 22)) or (((P.Acao) = 9) and (((P.QuadroAcao) >= 2) or ((P.Acao) = 22)))) then
  begin
    P.Acao := 11;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.EhChute := 1;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
    if (P.Personagem) = 13 then
    begin
      P.DuracaoAcao := 18;
    end;
  end;
  if (Codigo = 3) and ((P.Acao) = 12) then
  begin
    P.Acao := 13;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 15;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 4) and ((P.Acao) = 12) then
  begin
    P.Acao := 14;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 15;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (1 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 5;
  end;
  if (Codigo = 5) and ((P.Acao) = 12) then
  begin
    P.Acao := 15;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
  end;
  if (Codigo = 6) and ((P.Acao) = 12) then
  begin
    P.Acao := 16;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    if (P.CargaPoder) < CargaMax then
    begin
      P.CargaPoder := (2 * GanhoCarga) + (P.CargaPoder);
    end;
    SomPendente := 6;
  end;
  if (Codigo = 8) and ((P.VelY) = 0) then
  begin
    P.Acao := 17;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 8;
  end;
  if (Codigo = 9) and ((P.VelY) = 0) then
  begin
    P.Acao := 18;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 8;
  end;
  if Codigo = 10 then
  begin
    P.Acao := 19;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 50;
    P.VelY := -19;
    P.NoAr := 1;
    P.DirPulo := 0;
    P.Vencedor := 1;
    P.GolpeAtivo := 0;
  end;
  if Codigo = 11 then
  begin
    P.Acao := 20;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 25;
    P.VelY := -13;
    P.NoAr := 1;
    P.Vencedor := 1;
  end;
  if (Codigo = 12) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 20) and (((P.QuadroAcao)) >= ((P.DuracaoAcao))-3)) then
  begin
    P.Acao := 21;
    P.Vencedor := 0;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.Defendendo := 1;
    P.Quadro := Desloc+31;
  end;
  if (Codigo = 13) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 20) and (((P.QuadroAcao)) >= ((P.DuracaoAcao))-3)) then
  begin
    P.Acao := 22;
    P.Vencedor := 0;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 11;
    P.Defendendo := 1;
    P.Quadro := Desloc+32;
  end;
  if (P.Personagem) = 1 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(7, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.DuracaoAcao := 16;
      end;
      if Codigo = 19 then
      begin
        P.DuracaoAcao := 27;
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 22) or ((P.Acao) = 26)) then
    begin
      if (((((ChaoY))-90))) <= P.Y then
      begin
        P.Acao := 27;
        if (P.CargaPoder) < CargaMax then
        begin
          P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
        end;
        P.Y := (ChaoY);
        P.NoAr := 0;
        P.QuadroAcao := 0;
        P.VelY := 0;
        P.DirPulo := 0;
        P.TempoBaixo := 0;
        P.SeqEstado := 0;
        if Codigo = 20 then
        begin
          P.DuracaoAcao := 10;
        end;
        if Codigo = 21 then
        begin
          P.DuracaoAcao := 16;
        end;
        if Codigo = 20 then
        begin
          P.ForcaGolpe := 1;
        end;
        if Codigo = 21 then
        begin
          P.ForcaGolpe := 2;
        end;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      P.DuracaoAcao := 22;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 5) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 38;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+36;
      P.ForcaGolpe := 3;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 2 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(9, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or (((P.Acao) <> 3) and ((((P.Acao) <> 5) and (((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 30) and ((P.QuadroAcao) > 10))) or (((P.Acao) = 5) and (((P.QuadroAcao) >= 5) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 30) and ((P.QuadroAcao) > 10))))) or (((P.Acao) = 3) and (((P.QuadroAcao) >= 4) or (((P.Acao) <> 5) and (((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 30) and ((P.QuadroAcao) > 10))) or (((P.Acao) = 5) and (((P.QuadroAcao) >= 5) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 30) and ((P.QuadroAcao) > 10)))))) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 12) or ((P.Acao) = 14)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      P.EhChute := 1;
      P.NoAr := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 21;
    end;
    if (Codigo = 22) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 45;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (7 * GanhoCarga) + (P.CargaPoder);
      end;
    end;
    if (Codigo = 23) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 5) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 25) and ((P.QuadroAcao) > 12)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 30;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      P.ForcaGolpe := 2;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+44;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 3 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(9, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 23;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.EhChute := 1;
      if Codigo = 18 then
      begin
        P.VelY := -23;
      end;
      if Codigo = 19 then
      begin
        P.VelY := -29;
      end;
      P.NoAr := 1;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 24;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.EhChute := 1;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 14;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 19;
      end;
      SomPendente := 24;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if Codigo = 22 then
      begin
        P.VelY := -22;
      end;
      if Codigo = 23 then
      begin
        P.VelY := -23;
      end;
      P.NoAr := 1;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 6) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.Quadro := Desloc+48;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 4 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(12, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 25;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.EhChute := 1;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 13;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 16;
      end;
      SomPendente := 26;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.EhChute := 1;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.VelY := -26;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.VelY := -32;
      end;
      P.NoAr := 1;
      SomPendente := 27;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 26)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      P.ForcaGolpe := 2;
      P.EhChute := 1;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+12;
      O.Vencedor := 0;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 5 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(13, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 29;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 23;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 30;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 22)) then
    begin
      if (((((ChaoY))-90))) <= P.Y then
      begin
        P.Acao := 27;
        P.Y := (ChaoY);
        P.VelY := 0;
        P.NoAr := 0;
        P.TempoBaixo := 0;
        P.QuadroAcao := 0;
        if (P.CargaPoder) < CargaMax then
        begin
          P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
        end;
        if Codigo = 20 then
        begin
          P.ForcaGolpe := 1;
        end;
        if Codigo = 21 then
        begin
          P.ForcaGolpe := 2;
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.DuracaoAcao := 38;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.DuracaoAcao := 40;
        end;
        SomPendente := 31;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.CargaChute := 0;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 32;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 28)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+6;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 6 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(15, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 33;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(15, Jog) = 0) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 33;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      P.NoAr := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 34;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 35;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 5)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 50;
      P.VelY := -18;
      P.NoAr := 1;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+41;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 7 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.CargaSoco := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 17;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 20;
      end;
      SomPendente := 36;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.CargaSoco := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 37;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 22)) then
    begin
      if (((((ChaoY))-90))) <= P.Y then
      begin
        P.Acao := 27;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        P.NoAr := 1;
        P.DirPulo := 0;
        P.TempoBaixo := 0;
        P.Y := (ChaoY);
        if (P.CargaPoder) < CargaMax then
        begin
          P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
        end;
        if Codigo = 20 then
        begin
          P.ForcaGolpe := 1;
        end;
        if Codigo = 21 then
        begin
          P.ForcaGolpe := 2;
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.VelY := -27;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.VelY := -32;
        end;
        SomPendente := 38;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 22)) then
    begin
      if (((((ChaoY))-90))) <= P.Y then
      begin
        P.Acao := 28;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        P.NoAr := 1;
        P.DirPulo := 0;
        P.TempoBaixo := 0;
        P.Y := (ChaoY);
        if (P.CargaPoder) < CargaMax then
        begin
          P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
        end;
        if Codigo = 22 then
        begin
          P.ForcaGolpe := 1;
        end;
        if Codigo = 23 then
        begin
          P.ForcaGolpe := 2;
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.VelY := -27;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.VelY := -30;
        end;
        SomPendente := 37;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 5) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 12;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+38;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 8 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(18, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 39;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and ((P.Acao) = 12) and (ExisteEfeito(19, Jog) = 0) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 39;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 40;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 41;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+33;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 9 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 14;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 23;
      end;
      SomPendente := 43;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 44;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 45;
      for Cont := 1 to 5 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and ((P.Acao) = 12) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 15;
      P.NoAr := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 45;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 27)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 40;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+19;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 10 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.CargaSoco := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
      P.DuracaoAcao := 20;
      SomPendente := 47;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 11;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 20;
      end;
      SomPendente := 48;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 22)) then
    begin
      if (((((ChaoY))-90))) <= P.Y then
      begin
        P.Acao := 27;
        P.QuadroAcao := 0;
        P.Y := ((((ChaoY))-50));
        P.NoAr := 1;
        P.DuracaoAcao := 20;
        if (P.CargaPoder) < CargaMax then
        begin
          P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
        end;
        if Codigo = 20 then
        begin
          P.ForcaGolpe := 1;
        end;
        if Codigo = 21 then
        begin
          P.ForcaGolpe := 2;
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.VelY := -25;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.VelY := -28;
        end;
        SomPendente := 49;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 5)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 13;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      SomPendente := 49;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 25)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 40;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+38;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 11 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(22, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.DuracaoAcao := 9;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.DuracaoAcao := 15;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 29) and ((P.QuadroAcao) >= 27)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 12;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 27)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 45;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+6;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 12 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
      if ((P.X) - ((CameraX))) < 200 then
      begin
        P.Lado := 1;
      end;
      if ((P.X) - ((CameraX))) >= 200 then
      begin
        P.Lado := 2;
      end;
    end;
    if (Codigo = 15) and (((P.Acao) = 1) or ((P.Acao) = 2)) then
    begin
      P.Acao := 24;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(9, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 30) and ((P.GolpeAtivo) = 0)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 20;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (6 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 12) or ((P.Acao) = 5)) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      P.VelY := 0;
      P.NoAr := 0;
      P.DirPulo := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 22) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 32;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+38;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 13 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(26, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or (((P.Acao) <> 5) and (((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22))) or (((P.Acao) = 5) and (((P.QuadroAcao) >= 3) or ((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22)))) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 16;
      if (P.VelY) <> 0 then
      begin
        P.VelY := -10;
      end;
      P.DirPulo := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(28, Jog) = 0) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23) or (Codigo = 24) or (Codigo = 25)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
      if Codigo = 24 then
      begin
        P.ForcaGolpe := 3;
      end;
      if Codigo = 25 then
      begin
        P.ForcaGolpe := 4;
      end;
    end;
    if (Codigo = 26) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22) or ((P.Acao) = 27)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      P.NoAr := 0;
      P.DirPulo := 0;
      P.VelY := 0;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+37;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 14 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(29, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and ((P.Acao) = 12) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      P.NoAr := 0;
      P.VelY := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 12) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 35;
      P.NoAr := 0;
      P.VelY := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 70;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+37;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Personagem) = 15 then
  begin
    if (Codigo = 14) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7)) then
    begin
      P.Acao := 23;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 250;
    end;
    if ((Codigo = 16) or (Codigo = 17)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) and (ExisteEfeito(33, Jog) = 0) then
    begin
      P.Acao := 25;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 28;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 16 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 17 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 18) or (Codigo = 19)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 26;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 22;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 18 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 19 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 20) or (Codigo = 21)) and (((P.Acao) = 1) or ((P.Acao) = 2) or (((P.Acao) <> 6) and (((P.Acao) = 21) or ((P.Acao) = 22))) or (((P.Acao) = 6) and (((P.QuadroAcao) >= 6) or ((P.Acao) = 21) or ((P.Acao) = 22)))) then
    begin
      P.Acao := 27;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 25;
      P.NoAr := 0;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 20 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 21 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if ((Codigo = 22) or (Codigo = 23)) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 21) or ((P.Acao) = 22)) then
    begin
      P.Acao := 28;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 18;
      if (P.CargaPoder) < CargaMax then
      begin
        P.CargaPoder := (5 * GanhoCarga) + (P.CargaPoder);
      end;
      if Codigo = 22 then
      begin
        P.ForcaGolpe := 1;
      end;
      if Codigo = 23 then
      begin
        P.ForcaGolpe := 2;
      end;
    end;
    if (Codigo = 24) and (((P.Acao) = 1) or ((P.Acao) = 2) or ((P.Acao) = 7) or (((P.Acao) <> 25) and (((P.Acao) = 21) or ((P.Acao) = 22))) or (((P.Acao) = 25) and (((P.QuadroAcao) >= 24) or ((P.Acao) = 21) or ((P.Acao) = 22)))) and (((P.Vida) <= 15) or ((P.Poder) > 0)) then
    begin
      P.Acao := 29;
      P.QuadroAcao := 0;
      P.DuracaoAcao := 30;
      if (P.Poder) = 3 then
      begin
        P.CargaPoder := 0;
      end;
      P.Poder := (P.Poder)-1;
      P.Quadro := Desloc+12;
      FlashTela := 22;
      SomPendente := 19;
    end;
  end;
  if (P.Acao) = 2 then
  begin
    P.QuadroAcao := (P.QuadroAcao)+1;
    if (P.QuadroAcao) > 16 then
    begin
      P.QuadroAcao := 0;
    end;
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
  if Jog = 1 then
  begin
    Desloc := 0;
  end;
  if Jog = 2 then
  begin
    Desloc := 50;
  end;
  if (P.Acao) = 1 then
  begin
    P.Quadro := Desloc+1;
    P.Vencedor := 0;
  end;
  if ((P.Acao) = 2) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+2;
  end;
  if ((P.Acao) = 2) and ((P.QuadroAcao) = 4) then
  begin
    P.Quadro := Desloc+3;
  end;
  if ((P.Acao) = 2) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+2;
  end;
  if ((P.Acao) = 2) and ((P.QuadroAcao) = 12) then
  begin
    P.Quadro := Desloc+1;
  end;
  if ((P.Personagem) = 8) and ((P.Acao) = 2) then
  begin
    if (P.Campo_148) = 1 then
    begin
      P.Quadro := Desloc+2;
    end;
    if (P.Campo_148) = 0 then
    begin
      P.Quadro := Desloc+3;
    end;
    CriaEfeito(2, '', 0, Random(20) + (P.X - 10), Random(10) + P.Y);
  end;
  if ((P.Acao) = 3) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+4;
  end;
  if ((P.Acao) = 3) and ((P.QuadroAcao) = 2) then
  begin
    P.Quadro := Desloc+5;
  end;
  if ((P.Acao) = 3) and ((P.QuadroAcao) = 4) then
  begin
    P.Quadro := Desloc+4;
  end;
  if ((P.Acao) = 4) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+6;
  end;
  if ((P.Acao) = 4) and ((P.QuadroAcao) = 2) then
  begin
    P.Quadro := Desloc+7;
  end;
  if ((P.Acao) = 4) and ((P.QuadroAcao) = 4) then
  begin
    P.Quadro := Desloc+6;
  end;
  if ((P.Acao) = 5) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+8;
  end;
  if ((P.Acao) = 5) and ((P.QuadroAcao) = 5) then
  begin
    P.Quadro := Desloc+9;
  end;
  if ((P.Acao) = 5) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+8;
  end;
  if ((P.Acao) = 6) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+10;
  end;
  if ((P.Acao) = 6) and ((P.QuadroAcao) = 5) then
  begin
    P.Quadro := Desloc+11;
  end;
  if ((P.Acao) = 6) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+10;
  end;
  if (P.Acao) = 7 then
  begin
    P.Quadro := Desloc+12;
  end;
  if ((P.Acao) = 8) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+13;
  end;
  if ((P.Acao) = 8) and ((P.QuadroAcao) = 2) then
  begin
    P.Quadro := Desloc+14;
  end;
  if ((P.Acao) = 8) and ((P.QuadroAcao) = 4) then
  begin
    P.Quadro := Desloc+13;
  end;
  if ((P.Acao) = 9) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+15;
  end;
  if ((P.Acao) = 9) and ((P.QuadroAcao) = 2) then
  begin
    P.Quadro := Desloc+16;
  end;
  if ((P.Acao) = 9) and ((P.QuadroAcao) = 4) then
  begin
    P.Quadro := Desloc+15;
  end;
  if ((P.Acao) = 10) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+17;
  end;
  if ((P.Acao) = 10) and ((P.QuadroAcao) = 5) then
  begin
    P.Quadro := Desloc+18;
  end;
  if ((P.Acao) = 10) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+17;
  end;
  if (P.Personagem) <> 13 then
  begin
    if ((P.Acao) = 11) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+19;
    end;
    if ((P.Acao) = 11) and ((P.QuadroAcao) = 5) then
    begin
      P.Quadro := Desloc+20;
    end;
    if ((P.Acao) = 11) and ((P.QuadroAcao) = 8) then
    begin
      P.Quadro := Desloc+19;
    end;
  end
  else
  begin
    if ((P.Personagem) = 13) and ((P.Acao) = 11) then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+19;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+20;
      end;
      if (P.QuadroAcao) = 16 then
      begin
        P.Quadro := Desloc+19;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 9);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -9);
      end;
      CriaEfeito(2, '', 0, Random(40) + (Round(P.X) - 20), Round(P.Y) - Random(5));
    end;
  end;
  if (P.Acao) = 12 then
  begin
    P.Quadro := Desloc+21;
  end;
  if ((P.Acao) = 13) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+22;
  end;
  if ((P.Acao) = 13) and ((P.QuadroAcao) = 3) then
  begin
    P.Quadro := Desloc+23;
  end;
  if ((P.Acao) = 14) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+24;
  end;
  if ((P.Acao) = 14) and ((P.QuadroAcao) = 3) then
  begin
    P.Quadro := Desloc+25;
  end;
  if ((P.Acao) = 15) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+22;
  end;
  if ((P.Acao) = 15) and ((P.QuadroAcao) = 5) then
  begin
    P.Quadro := Desloc+23;
  end;
  if ((P.Acao) = 15) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+22;
  end;
  if ((P.Acao) = 16) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+24;
  end;
  if ((P.Acao) = 16) and ((P.QuadroAcao) = 5) then
  begin
    P.Quadro := Desloc+25;
  end;
  if ((P.Acao) = 16) and ((P.QuadroAcao) = 8) then
  begin
    P.Quadro := Desloc+24;
  end;
  if ((P.Acao) = 17) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+26;
  end;
  if ((P.Acao) = 18) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+27;
  end;
  if ((P.Acao) = 18) and ((P.QuadroAcao) = 1) then
  begin
    P.Quadro := Desloc+27;
  end;
  if (P.Acao) = 19 then
  begin
    P.Quadro := Desloc+28;
  end;
  if ((P.Acao) = 20) and ((P.QuadroAcao) = 0) then
  begin
    P.Quadro := Desloc+29;
  end;
  if ((P.Acao) = 20) and ((P.QuadroAcao) = 18) then
  begin
    P.Quadro := Desloc+30;
  end;
  if ((P.Acao) = 20) and ((P.VelY) = 0) and ((P.Vida) <= 0) then
  begin
    P.QuadroAcao := 0;
    P.Y := (ChaoY);
  end;
  if (P.Acao) = 21 then
  begin
    P.Quadro := Desloc+31;
  end;
  if (P.Acao) = 22 then
  begin
    P.Quadro := Desloc+32;
  end;
  if ((P.Acao) = 21) or ((P.Acao) = 22) then
  begin
    P.Defendendo := 1;
  end;
  if (P.Personagem) = 1 then
  begin
    if (P.Acao) = 23 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+33;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 21 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 28 then
      begin
        P.Quadro := Desloc+33;
      end;
      if (P.QuadroAcao) = 28 then
      begin
        P.QuadroAcao := 0;
      end;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+39;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(7, 'A', Jog, (P.X) + 45, P.Y);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(7, 'A', Jog, (P.X) - 45, P.Y);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(7, 'B', Jog, (P.X) + 45, P.Y);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(7, 'B', Jog, (P.X) - 45, P.Y);
        end;
        SomPendente := 14;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 15;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+40;
      end;
      if ((P.QuadroAcao) = 6) and ((P.ForcaGolpe) = 1) then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.QuadroAcao) = 10) and ((P.ForcaGolpe) = 2) then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.QuadroAcao) = 12) and ((P.ForcaGolpe) = 1) then
      begin
        P.Quadro := Desloc+42;
      end;
      if ((P.QuadroAcao) = 19) and ((P.ForcaGolpe) = 2) then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.Quadro) = Desloc+41 then
      begin
        for Cont := 1 to 3 do
        begin
          CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 19);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -19);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 21);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -21);
        end;
      end;
      if ((P.Lado) = 1) and ((P.QuadroAcao) >= 9) then
      begin
        CriaEfeito(16, '', Jog, (P.X) + 60, (P.Y) - 85);
      end;
      if ((P.Lado) = 2) and ((P.QuadroAcao) >= 9) then
      begin
        CriaEfeito(16, '', Jog, (P.X) - 60, (P.Y) - 85);
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.Acertos) >= 1 then
      begin
        O.Vencedor := 0;
      end;
      if (P.Acertos) >= 4 then
      begin
        O.Vencedor := 1;
      end;
      if (P.QuadroAcao) > 7 then
      begin
        O.Vencedor := 1;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 16;
      end;
      if (P.QuadroAcao mod 3 = 0) then
      begin
        if (P.Quadro) = Desloc+43 then
        begin
          P.Quadro := Desloc+44;
        end
        else
        begin
          P.Quadro := Desloc+43;
        end;
      end;
      P.Y := (P.Y) - 10;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 5);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -5);
      end;
      if (P.QuadroAcao) = 20 then
      begin
        P.NoAr := 1;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 17;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+45;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+46;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+47;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+48;
      end;
      if (P.QuadroAcao) = 15 then
      begin
        P.Quadro := Desloc+49;
      end;
      if (P.QuadroAcao) = 18 then
      begin
        P.Quadro := Desloc+12;
      end;
      if ((P.QuadroAcao) >= 4) and ((P.QuadroAcao) <= 13) then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 17);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -17);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 21);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -21);
        end;
      end;
      if (P.QuadroAcao) >= 12 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        SomPendente := 18;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+39;
        if (P.Lado) = 1 then
        begin
          CriaEfeito(8, 'A', Jog, (P.X) + 110, P.Y);
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(8, 'A', Jog, (P.X) - 110, P.Y);
        end;
        TremorTela := 20;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+2, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+3, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+4, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+6, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+8, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+10, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+12, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+13, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+15, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+17, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+19, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+21, -13, 40, 19, 120);
    DefineCaixaCorpo(Jog, Desloc+28, -20, 70, 32, 120);
    DefineCaixaCorpo(Jog, Desloc+29, -20, 110, 32, 150);
    DefineCaixaCorpo(Jog, Desloc+31, -13, 35, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+32, -13, 65, 19, 164);
    DefineCaixaCorpo(Jog, Desloc+35, -20, 40, 12, 164);
    DefineCaixaCorpo(Jog, Desloc+37, -10, 80, 45, 164);
    DefineCaixaCorpo(Jog, Desloc+39, -30, 70, 40, 164);
    DefineCaixaCorpo(Jog, Desloc+41, 0, 50, 35, 150);
    DefineCaixaCorpo(Jog, Desloc+43, -15, 50, 22, 125);
    DefineCaixaCorpo(Jog, Desloc+45, -15, 50, 22, 110);
    DefineCaixaAtaque(Jog, 3, 2, 15, 47, 63, 57, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 25, 84, 84, 124, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 25, 46, 65, 58, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 25, 82, 83, 107, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 67, 75, 82, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 10, 115, 70, 155, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 67, 70, 82, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 5, 95, 98, 113, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 15, 60, 80, 94, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 10, 75, 75, 97, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 15, 60, 80, 94, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 10, 75, 75, 97, 1, 2, 14, 0);
    if (P.ForcaGolpe) = 1 then
    begin
      DefineCaixaAtaque(Jog, 26, 6, 40, 73, 100, 86, 1, 0, 16, 2);
    end;
    if (P.ForcaGolpe) = 2 then
    begin
      DefineCaixaAtaque(Jog, 26, 10, 40, 73, 100, 86, 1, 0, 20, 3);
    end;
    DefineCaixaAtaque(Jog, 27, 0, -32, 5, 32, 125, 1, 0, 10, 2);
    DefineCaixaAtaque(Jog, 27, 2, -32, 5, 32, 125, 1, 0, 6, 2);
    DefineCaixaAtaque(Jog, 27, 4, -32, 5, 32, 125, 1, 0, 4, 2);
    DefineCaixaAtaque(Jog, 27, 7, -32, 5, 32, 125, 1, 0, 2, 2);
    DefineCaixaAtaque(Jog, 28, 6, -30, 10, 35, 70, 1, 0, 10, 3);
    DefineCaixaAtaque(Jog, 28, 9, -30, 10, 35, 70, 1, 0, 7, 2);
    DefineCaixaAtaque(Jog, 28, 12, -10, 50, 45, 100, 1, 0, 5, 1);
  end;
  if (P.Personagem) = 2 then
  begin
    if (P.Acao) = 23 then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and (Random(2) = 0) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) + 55, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) - 55, (P.Y) - 100);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) + 55, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) - 55, (P.Y) - 100);
        end;
        SomPendente := 20;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (((P.QuadroAcao) <> 11) and ((P.QuadroAcao) = 15) and ((P.ForcaGolpe) = 2)) or (((P.QuadroAcao) = 11) and (((P.ForcaGolpe) = 1) or ((P.QuadroAcao) = 15) and ((P.ForcaGolpe) = 2))) then
      begin
        P.Quadro := Desloc+40;
        P.NoAr := 1;
        P.VelY := -6;
      end;
      if (P.Quadro) = Desloc+39 then
      begin
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 11;
          if (P.Lado) = 1 then
          begin
            Empurra(Jog, 4);
          end;
          if (P.Lado) = 2 then
          begin
            Empurra(Jog, -4);
          end;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 12;
          if (P.QuadroAcao) < 10 then
          begin
            if (P.Lado) = 1 then
            begin
              Empurra(Jog, 9);
            end;
            if (P.Lado) = 2 then
            begin
              Empurra(Jog, -9);
            end;
          end;
          if (P.QuadroAcao) >= 10 then
          begin
            if (P.Lado) = 1 then
            begin
              Empurra(Jog, 3);
            end;
            if (P.Lado) = 2 then
            begin
              Empurra(Jog, -3);
            end;
          end;
        end;
      end;
      if (P.Quadro) = Desloc+40 then
      begin
        P.NoAr := 1;
      end;
      if (P.QuadroAcao) >= 5 then
      begin
        P.EhChute := 1;
      end;
      if (P.Acertos) = 1 then
      begin
        O.Vencedor := 0;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+24;
        P.VelY := 0;
        P.DirPulo := 0;
      end;
      if ((P.Acao) = 27) and ((P.QuadroAcao) >= 3) then
      begin
        P.Quadro := Desloc+25;
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) + 20;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) + 13;
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 11);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -11);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 15);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -15);
        end;
        if (P.Y) > 270 then
        begin
          P.VelY := 2;
        end;
      end;
    end;
    if (((P.Acao) = 28) or ((P.Acao) = 29)) and ((P.QuadroAcao) >= 0) then
    begin
      if ((P.Acao) = 28) and ((P.QuadroAcao) = 0) then
      begin
        SomPendente := 22;
      end;
      repeat
        S_0 := Random(3)+(Desloc+41);
      until (P.Quadro) <> S_0;
      P.Quadro := S_0;
      if Random(2) = 0 then
      begin
        SomPendente := 5;
      end;
      if Random(2) = 0 then
      begin
        SomPendente := 6;
      end;
      if Random(2) = 0 then
      begin
        SomPendente := 5;
      end;
      if Random(2) = 0 then
      begin
        SomPendente := 6;
      end;
      if (P.Acao) = 29 then
      begin
        if (Flash = 1) and (Random(6) = 0) then
        begin
          FlashVermelho := 3;
        end;
        P.Recuo := 0;
        O.Quadro := (Random(2)+26)+(50-Desloc);
        O.QuadroAcao := 0;
        O.DuracaoAcao := 5;
        O.VelY := 0;
        O.Y := (O.Y) + 10;
        if ((ChaoY)) < O.Y then
        begin
          O.Y := (ChaoY);
        end;
        if (P.Lado) = 1 then
        begin
          O.X := (((Random(2) shl 3))) + ((P.X) + 40);
        end;
        if (P.Lado) = 2 then
        begin
          O.X := ((P.X) - 40) - (((Random(2) shl 3)));
        end;
        P.Acertos := (P.Acertos)+1;
        P.TempoAcertos := 20;
        if Random(4) = 0 then
        begin
          SomPendente := 7;
        end;
        if Random(4) = 0 then
        begin
          SomPendente := 8;
        end;
        if Random(4) = 0 then
        begin
          SomPendente := 9;
        end;
        CriaEfeito(1, '', 0, Random(20) + (O.X - 30), Random(120) + (O.Y - 150));
        if ((P.QuadroAcao)) > ((P.DuracaoAcao))-2 then
        begin
          P.DanoGolpe := 20;
          O.Vida := (O.Vida) - ((((P.DanoGolpe))) * NivelDano);
          AcaoJogador(3-Jog, 10);
          O.Recuo := 30;
        end;
      end;
    end;
    if ((P.Acao) = 30) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+44;
    end;
    if ((P.Acao) = 30) and ((P.QuadroAcao) > 2) then
    begin
      for Cont := 1 to 8 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
      P.Quadro := Desloc+45;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 23);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -23);
      end;
    end;
    if (P.Acao) = 31 then
    begin
      P.Recuo := 0;
      P.Quadro := (Random(45)+1)+Desloc;
      if (Flash = 1) and (Random(5) = 0) then
      begin
        FlashVermelho := 3;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 3);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -3);
      end;
      O.Quadro := (Random(2)+26)+(50-Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := (O.Y) + 10;
      if ((ChaoY)) < O.Y then
      begin
        O.Y := (ChaoY);
      end;
      if (P.Lado) = 1 then
      begin
        O.X := (((Random(2) shl 3))) + ((P.X) + 40);
      end;
      if (P.Lado) = 2 then
      begin
        O.X := ((P.X) - 40) - (((Random(2) shl 3)));
      end;
      P.Acertos := (P.Acertos)+2;
      P.TempoAcertos := 43;
      if (Random(30) = 0) and ((O.Vida) > 0) then
      begin
        PausaImpacto := 5;
      end;
      if Random(4) = 0 then
      begin
        SomPendente := 7;
      end;
      if Random(4) = 0 then
      begin
        SomPendente := 8;
      end;
      if Random(4) = 0 then
      begin
        SomPendente := 9;
      end;
      CriaEfeito(1, '', 0, Random(20) + (O.X - 10), Random(100) + (O.Y - 130));
      if ((P.QuadroAcao)) > ((P.DuracaoAcao))-2 then
      begin
        P.DanoGolpe := 47;
        O.Vida := (O.Vida) - ((((P.DanoGolpe))) * NivelDano);
        P.Acao := 1;
        P.Quadro := Desloc+38;
        PausaImpacto := 5;
        AcaoJogador(Jog, 19);
        AcaoJogador(3-Jog, 10);
        P.GolpeAtivo := 0;
        O.Recuo := 28;
        O.VelY := -30;
        if (O.Lado) = 1 then
        begin
          O.VelAngular := -25;
        end;
        if (O.Lado) = 2 then
        begin
          O.VelAngular := 25;
        end;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -18, 30, 13, 170);
    DefineCaixaCorpo(Jog, Desloc+2, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+3, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+4, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+6, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+8, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+10, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+12, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+13, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+15, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+17, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+19, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -12, 40, 20, 140);
    DefineCaixaCorpo(Jog, Desloc+28, -22, 60, 30, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -22, 115, 30, 170);
    DefineCaixaCorpo(Jog, Desloc+31, -12, 40, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -12, 70, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+35, -12, 30, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+39, -12, 40, 15, 140);
    DefineCaixaCorpo(Jog, Desloc+41, -18, 30, 13, 170);
    DefineCaixaCorpo(Jog, Desloc+45, -12, 40, 40, 170);
    DefineCaixaAtaque(Jog, 3, 2, 20, 50, 67, 60, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 25, 95, 70, 133, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 5, 5, 68, 58, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 18, 55, 92, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 20, 82, 67, 94, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 20, 145, 70, 165, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 35, 45, 92, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 30, 115, 90, 138, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 50, 40, 85, 78, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 0, 115, 55, 145, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 50, 40, 85, 78, 1, 1, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 0, 115, 55, 145, 1, 2, 14, 0);
    if (P.ForcaGolpe) = 2 then
    begin
      DefineCaixaAtaque(Jog, 26, 3, 10, -5, 50, 90, 1, 0, 3, 1);
    end;
    DefineCaixaAtaque(Jog, 26, 5, 10, -5, 50, 90, 1, 0, 18, 4);
    DefineCaixaAtaque(Jog, 26, 9, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 3, 0, 115, 55, 145, 1, 0, 18, 2);
    DefineCaixaAtaque(Jog, 28, 1, 20, 40, 60, 160, 1, 0, 0, 2);
    DefineCaixaAtaque(Jog, 28, 5, 20, 40, 60, 160, 1, 0, 0, 1);
    DefineCaixaAtaque(Jog, 28, 9, 20, 40, 60, 160, 1, 0, 0, 1);
    DefineCaixaAtaque(Jog, 28, 13, 20, 40, 60, 160, 1, 0, 0, 2);
    DefineCaixaAtaque(Jog, 30, 3, 20, 80, 60, 160, 1, 0, 0, 0);
  end;
  if (P.Personagem) = 3 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao) < 5) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 5) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 10) then
    begin
      P.Quadro := Desloc+35;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 15) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 20) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 25) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 30) then
    begin
      P.Quadro := Desloc+35;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 35) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) + 40, (P.Y) - 80);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) - 40, (P.Y) - 80);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) + 40, (P.Y) - 80);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) - 40, (P.Y) - 80);
        end;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+42;
      end;
      if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
      begin
        Empurra(Jog, 6);
      end;
      if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
      begin
        Empurra(Jog, -6);
      end;
      if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
      begin
        Empurra(Jog, 8);
      end;
      if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
      begin
        Empurra(Jog, -8);
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) >= 5 then
      begin
        for Cont := 1 to 5 do
        begin
          CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        end;
        P.Quadro := Desloc+45;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 17);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -17);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 16);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -16);
        end;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+46;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+47;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+46;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+47;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+46;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 10);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -10);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 14);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -14);
      end;
      if (P.QuadroAcao) >= 5 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      for Cont := 1 to 3 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
      P.Quadro := Desloc+48;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 17);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -17);
      end;
    end;
    if (P.Acao) = 30 then
    begin
      P.Recuo := 0;
      if (ContPisca mod 4 = 0) then
      begin
        P.Quadro := Desloc+49;
      end
      else
      begin
        P.Quadro := Desloc+50;
      end;
      P.Y := (P.Y) - 3;
      if (Flash = 1) and (Random(5) = 0) then
      begin
        FlashVermelho := 3;
      end;
      O.Quadro := (Random(2)+26)+(50-Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := (O.Y) + 10;
      if ((ChaoY)) < O.Y then
      begin
        O.Y := (ChaoY);
      end;
      if (P.Lado) = 1 then
      begin
        r194 := Random(3);
        O.X := (((r194+(r194*4)))) + ((P.X) + 65);
      end;
      if (P.Lado) = 2 then
      begin
        r195 := Random(3);
        O.X := ((P.X) - 65) - (((r195+(r195*4))));
      end;
      P.Acertos := (P.Acertos)+1;
      P.TempoAcertos := 43;
      if (Random(20) = 0) and ((O.Vida) > 0) then
      begin
        PausaImpacto := 5;
      end;
      if Random(6) = 0 then
      begin
        SomPendente := 7;
      end;
      if Random(6) = 0 then
      begin
        SomPendente := 8;
      end;
      if Random(6) = 0 then
      begin
        SomPendente := 9;
      end;
      if (P.Lado) = 1 then
      begin
        CriaEfeito(1, '', 0, Random(10) + (P.X + 40), Random(30) + (P.Y - 30));
      end;
      if (P.Lado) = 2 then
      begin
        CriaEfeito(1, '', 0, Random(10) + (P.X - 50), Random(30) + (P.Y - 30));
      end;
      if ((P.QuadroAcao)) > ((P.DuracaoAcao))-2 then
      begin
        P.DanoGolpe := 36;
        O.Vida := (O.Vida) - ((((P.DanoGolpe))) * NivelDano);
        P.VelY := -28;
        P.NoAr := 1;
        P.Acao := 12;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 99;
        AcaoJogador(3-Jog, 10);
        O.Recuo := 30;
        if (O.Lado) = 1 then
        begin
          O.VelAngular := -15;
        end;
        if (O.Lado) = 2 then
        begin
          O.VelAngular := 15;
        end;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+2, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+3, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+4, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+6, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+8, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+10, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+12, -17, 65, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+13, -17, 65, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+15, -17, 65, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+17, -17, 65, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+19, -17, 65, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 30, 14, 110);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 70, 24, 115);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 115, 24, 155);
    DefineCaixaCorpo(Jog, Desloc+31, -17, 40, 25, 155);
    DefineCaixaCorpo(Jog, Desloc+32, -12, 65, 30, 155);
    DefineCaixaCorpo(Jog, Desloc+35, -17, 30, 14, 155);
    DefineCaixaCorpo(Jog, Desloc+38, -7, 30, 24, 140);
    DefineCaixaCorpo(Jog, Desloc+39, -17, 30, 14, 110);
    DefineCaixaCorpo(Jog, Desloc+41, 0, 50, 28, 140);
    DefineCaixaCorpo(Jog, Desloc+43, -7, 30, 24, 140);
    DefineCaixaCorpo(Jog, Desloc+45, 10, 40, 50, 140);
    DefineCaixaAtaque(Jog, 3, 2, 20, 45, 60, 55, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 15, 100, 48, 140, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 15, 45, 55, 58, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 10, 60, 60, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 80, 70, 90, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 20, 127, 70, 143, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 80, 60, 95, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 17, 102, 80, 123, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 17, 75, 68, 105, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 10, 80, 80, 105, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 17, 75, 68, 105, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 10, 80, 80, 105, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 26, 2, 10, 5, 50, 95, 1, 0, 20, 3);
    DefineCaixaAtaque(Jog, 26, 7, 10, 5, 50, 95, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 5, 10, 68, 100, 82, 1, 0, 16, 4);
    DefineCaixaAtaque(Jog, 28, 1, 20, 80, 70, 110, 1, 0, 12, 1);
    DefineCaixaAtaque(Jog, 28, 3, -70, 80, 5, 110, 1, 0, 12, 1);
    DefineCaixaAtaque(Jog, 28, 5, 20, 80, 70, 110, 1, 0, 8, 1);
    DefineCaixaAtaque(Jog, 28, 7, -70, 80, 5, 110, 1, 0, 8, 1);
    DefineCaixaAtaque(Jog, 28, 9, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 29, 1, 40, 45, 70, 130, 1, 0, 5, 0);
  end;
  if (P.Personagem) = 4 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao) < 13) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 13) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(12, 'A', Jog, (P.X) + 40, (P.Y) - 110);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(12, 'A', Jog, (P.X) - 40, (P.Y) - 110);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(12, 'B', Jog, (P.X) + 40, (P.Y) - 110);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(12, 'B', Jog, (P.X) - 40, (P.Y) - 110);
        end;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) >= 7 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 26);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -26);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 25);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -25);
        end;
      end;
      for Cont := 1 to 3 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+12;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 10);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -10);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 13);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -13);
      end;
      if (P.QuadroAcao) >= 6 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+45;
      end;
      if ((P.QuadroAcao) >= 2) and ((P.QuadroAcao) < 6) then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 9);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -9);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 18);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -18);
        end;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+12;
        SomPendente := 28;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 17);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -17);
      end;
      if ((P.QuadroAcao) > 1) and ((P.QuadroAcao) < 10) then
      begin
        for Cont := 1 to 3 do
        begin
          if (P.Lado) = 1 then
          begin
            CriaEfeito(11, '', 0, Random(30) + (P.X + 20), Random(40) + (P.Y - 110));
          end;
          if (P.Lado) = 2 then
          begin
            CriaEfeito(11, '', 0, (P.X - 20) - Random(30), Random(40) + (P.Y - 110));
          end;
        end;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+2, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+3, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+4, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+6, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+8, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+10, -17, 60, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+12, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+13, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+15, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+17, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+19, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 25, 14, 120);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 50, 24, 100);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 110, 24, 160);
    DefineCaixaCorpo(Jog, Desloc+31, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+32, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+35, -17, 20, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+38, -10, 40, 55, 160);
    DefineCaixaCorpo(Jog, Desloc+39, -40, 50, 25, 70);
    DefineCaixaCorpo(Jog, Desloc+43, -12, 20, 20, 150);
    DefineCaixaAtaque(Jog, 3, 2, 18, 35, 60, 48, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 50, 80, 80, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 20, 35, 70, 45, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 20, 110, 80, 150, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 80, 50, 90, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 20, 135, 75, 150, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 80, 67, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 15, 110, 85, 125, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 20, 65, 50, 97, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 20, 90, 75, 115, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 20, 65, 50, 97, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 20, 90, 75, 115, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 26, 3, 30, 55, 90, 85, 1, 0, 20, 3);
    DefineCaixaAtaque(Jog, 27, 4, 20, 30, 75, 70, 1, 0, 5, 1);
    DefineCaixaAtaque(Jog, 27, 5, 10, 30, 75, 70, 1, 0, 9, 1);
    DefineCaixaAtaque(Jog, 27, 6, 10, 30, 75, 70, 1, 0, 7, 2);
    DefineCaixaAtaque(Jog, 28, 2, 20, 0, 55, 95, 1, 0, 22, 3);
    DefineCaixaAtaque(Jog, 28, 7, 20, 0, 55, 95, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 29, 2, 10, 30, 75, 70, 1, 2, 40, 8);
  end;
  if (P.Personagem) = 5 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao) < 5) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 9) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 13) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 17) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 21) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 25) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 29) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 33) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 37) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 41) then
    begin
      P.Quadro := Desloc+35;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(13, 'A', Jog, (P.X) + 40, (P.Y) - 103);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(13, 'A', Jog, (P.X) - 40, (P.Y) - 103);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(13, 'B', Jog, (P.X) + 40, (P.Y) - 103);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(13, 'B', Jog, (P.X) - 40, (P.Y) - 103);
        end;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 15 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 20 then
      begin
        P.Quadro := Desloc+12;
      end;
      if (P.QuadroAcao) < 13 then
      begin
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 6);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -6);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 10);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -10);
        end;
      end;
      if (P.QuadroAcao) >= 15 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao mod 2 <> 0) then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 35 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 38 then
      begin
        P.Quadro := Desloc+39;
      end;
      if ((P.QuadroAcao) >= 4) and ((P.QuadroAcao) < 35) then
      begin
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 7);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -7);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 9);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -9);
        end;
      end;
      if (P.QuadroAcao) >= 26 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      repeat
        S_0 := Random(3)+(Desloc+45);
      until (P.Quadro) <> S_0;
      P.Quadro := S_0;
      if Random(5) = 0 then
      begin
        SomPendente := 32;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+10;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+11;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+6;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+10;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+11;
      end;
      if ((P.QuadroAcao) >= 8) and ((P.QuadroAcao) < 28) then
      begin
        P.Quadro := Random(3)+(Desloc+45);
      end;
      if (P.QuadroAcao) = 28 then
      begin
        P.Quadro := Desloc+6;
      end;
      if (P.QuadroAcao) >= 15 then
      begin
        P.EhChute := 1;
      end;
      if ((P.QuadroAcao) = 1) or ((P.QuadroAcao) = 8) or ((P.QuadroAcao) = 12) then
      begin
        SomPendente := 32;
      end;
      if ((P.Lado) = 1) and ((P.QuadroAcao) < 8) then
      begin
        Empurra(Jog, 5);
      end;
      if ((P.Lado) = 1) and ((P.QuadroAcao) >= 8) and ((P.QuadroAcao) < 28) then
      begin
        Empurra(Jog, 10);
      end;
      if ((P.Lado) = 2) and ((P.QuadroAcao) < 8) then
      begin
        Empurra(Jog, -5);
      end;
      if ((P.Lado) = 2) and ((P.QuadroAcao) >= 8) and ((P.QuadroAcao) < 28) then
      begin
        Empurra(Jog, -10);
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+2, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+3, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+4, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+6, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+8, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+10, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+12, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+13, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+15, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+17, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+19, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+21, -7, 25, 24, 120);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 60, 24, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 105, 24, 140);
    DefineCaixaCorpo(Jog, Desloc+31, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+32, -17, 65, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+36, -17, 20, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+42, -17, 70, 14, 150);
    DefineCaixaCorpo(Jog, Desloc+43, -17, 60, 14, 140);
    DefineCaixaCorpo(Jog, Desloc+45, -17, 20, 14, 150);
    DefineCaixaAtaque(Jog, 3, 2, 20, 32, 58, 42, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 95, 75, 118, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 20, 28, 63, 40, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 25, 22, 63, 60, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 20, 82, 58, 92, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 20, 130, 67, 142, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 20, 77, 60, 87, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 20, 115, 77, 133, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 25, 45, 67, 80, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 25, 96, 67, 113, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 25, 45, 67, 80, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 25, 96, 67, 113, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 26, 10, 20, 20, 70, 145, 1, 2, 10, 1);
    DefineCaixaAtaque(Jog, 26, 15, 20, 120, 70, 145, 1, 2, 15, 2);
    DefineCaixaAtaque(Jog, 27, 3, -60, 50, 70, 75, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 27, 7, -60, 50, 70, 75, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 27, 11, -60, 50, 70, 75, 1, 0, 4, 0);
    DefineCaixaAtaque(Jog, 27, 15, -60, 50, 70, 75, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 27, 19, -60, 50, 70, 75, 1, 0, 4, 2);
    DefineCaixaAtaque(Jog, 27, 23, -60, 50, 70, 75, 1, 0, 3, 2);
    DefineCaixaAtaque(Jog, 27, 27, -60, 50, 70, 75, 1, 0, 4, 2);
    DefineCaixaAtaque(Jog, 28, 1, 18, 28, 70, 110, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 28, 3, 18, 28, 70, 110, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 28, 5, 18, 28, 70, 110, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 28, 7, 18, 28, 70, 110, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 28, 9, 18, 28, 70, 110, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 28, 11, 18, 28, 70, 110, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 28, 13, 18, 28, 70, 110, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 29, 1, 18, 28, 70, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 3, 18, 28, 70, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 5, 18, 28, 70, 110, 1, 2, 5, 0);
    DefineCaixaAtaque(Jog, 29, 7, 18, 28, 70, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 9, 18, 28, 70, 110, 1, 2, 5, 2);
    DefineCaixaAtaque(Jog, 29, 11, 18, 28, 70, 110, 1, 2, 5, 0);
    DefineCaixaAtaque(Jog, 29, 13, 18, 28, 70, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 15, 18, 28, 70, 110, 1, 2, 10, 3);
  end;
  if (P.Personagem) = 6 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao mod 4 = 0)) then
    begin
      if (P.Quadro) = Desloc+33 then
      begin
        P.Quadro := Desloc+34;
      end
      else
      begin
        P.Quadro := Desloc+33;
      end;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(15, 'A', Jog, (P.X) + 50, (P.Y) - 130);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(15, 'A', Jog, (P.X) - 50, (P.Y) - 130);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(15, 'B', Jog, (P.X) + 50, (P.Y) - 130);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(15, 'B', Jog, (P.X) - 50, (P.Y) - 130);
        end;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+40;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(15, 'A', Jog, (P.X) + 50, (P.Y) - 75);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(15, 'A', Jog, (P.X) - 50, (P.Y) - 75);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(15, 'B', Jog, (P.X) + 50, (P.Y) - 75);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(15, 'B', Jog, (P.X) - 50, (P.Y) - 75);
        end;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+43;
      end;
      if ((P.QuadroAcao) >= 3) and ((P.QuadroAcao) <= 12) then
      begin
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 6);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -6);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 9);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -9);
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 10;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 13;
        end;
      end;
      if (P.QuadroAcao) = 13 then
      begin
        if (P.ForcaGolpe) = 1 then
        begin
          P.VelY := -3;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.VelY := -6;
        end;
        P.NoAr := 1;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 2);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -2);
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.QuadroAcao) >= 2) and ((P.QuadroAcao) <= 5) then
      begin
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 20);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -20);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 27);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -27);
        end;
        P.Y := (P.Y) - 15;
      end;
      if (P.QuadroAcao) >= 3 then
      begin
        P.EhChute := 1;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.NoAr := 1;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) <= 8 then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 1);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -1);
        end;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.QuadroAcao) >= 3) and ((P.QuadroAcao) <= 6) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 21);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -21);
        end;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.NoAr := 0;
        P.Y := (ChaoY);
      end;
      if (P.QuadroAcao) = 8 then
      begin
        SomPendente := 34;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 25 then
      begin
        P.Quadro := Desloc+43;
      end;
      if ((P.QuadroAcao) >= 9) and ((P.QuadroAcao) <= 25) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 9);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -9);
        end;
        P.Y := (P.Y) - 10;
      end;
      if (P.QuadroAcao) = 26 then
      begin
        P.NoAr := 1;
        P.VelY := -5;
      end;
      if ((P.QuadroAcao) >= 9) and (((O.Acao) = 17) or ((O.Acao) = 19)) then
      begin
        P.EhChute := 1;
        O.Vencedor := 0;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+2, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+3, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+4, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+6, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+8, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+10, -5, 40, 30, 200);
    DefineCaixaCorpo(Jog, Desloc+12, -10, 97, 20, 200);
    DefineCaixaCorpo(Jog, Desloc+13, -10, 97, 20, 200);
    DefineCaixaCorpo(Jog, Desloc+15, -10, 97, 20, 200);
    DefineCaixaCorpo(Jog, Desloc+17, -10, 97, 20, 200);
    DefineCaixaCorpo(Jog, Desloc+19, -10, 97, 20, 200);
    DefineCaixaCorpo(Jog, Desloc+21, -18, 35, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+28, -40, 100, 35, 140);
    DefineCaixaCorpo(Jog, Desloc+29, -40, 145, 35, 180);
    DefineCaixaCorpo(Jog, Desloc+31, -5, 40, 35, 190);
    DefineCaixaCorpo(Jog, Desloc+32, -17, 97, 14, 190);
    DefineCaixaCorpo(Jog, Desloc+35, -12, 40, 20, 190);
    DefineCaixaCorpo(Jog, Desloc+38, -17, 78, 14, 190);
    DefineCaixaCorpo(Jog, Desloc+41, -17, 78, 44, 190);
    DefineCaixaCorpo(Jog, Desloc+42, -15, 40, 25, 180);
    DefineCaixaCorpo(Jog, Desloc+44, -10, 30, 35, 150);
    DefineCaixaAtaque(Jog, 3, 2, 20, 55, 68, 82, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 95, 108, 145, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 4, 30, 58, 77, 90, 1, 2, 4, 0);
    DefineCaixaAtaque(Jog, 5, 6, 40, 23, 73, 80, 1, 2, 10, 0);
    DefineCaixaAtaque(Jog, 6, 5, 25, 40, 105, 100, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 110, 80, 125, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 18, 160, 93, 190, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 102, 74, 120, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 15, 135, 110, 155, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 38, 100, 85, 140, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 18, 110, 108, 143, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 38, 100, 85, 140, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 18, 110, 108, 143, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 27, 2, 8, 0, 50, 170, 1, 0, 22, 2);
    DefineCaixaAtaque(Jog, 27, 13, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 28, 1, 0, 70, 75, 130, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 28, 3, 0, 70, 75, 130, 1, 0, 18, 1);
    DefineCaixaAtaque(Jog, 28, 5, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 29, 1, 0, 70, 70, 155, 1, 2, 2, 1);
    DefineCaixaAtaque(Jog, 29, 3, 0, 70, 70, 155, 1, 1, 1, 1);
    DefineCaixaAtaque(Jog, 29, 6, 0, 70, 70, 155, 1, 2, 2, 1);
    DefineCaixaAtaque(Jog, 29, 8, 8, 40, 55, 165, 1, 1, 3, 2);
    DefineCaixaAtaque(Jog, 29, 10, 8, 40, 55, 165, 1, 2, 2, 1);
    DefineCaixaAtaque(Jog, 29, 12, 8, 40, 55, 165, 1, 2, 4, 1);
    DefineCaixaAtaque(Jog, 29, 14, 8, 40, 55, 165, 1, 1, 3, 2);
    DefineCaixaAtaque(Jog, 29, 16, 8, 40, 55, 165, 1, 2, 6, 1);
    DefineCaixaAtaque(Jog, 29, 18, 8, 40, 55, 165, 1, 2, 5, 2);
    DefineCaixaAtaque(Jog, 29, 20, 8, 40, 55, 165, 1, 3, 6, 1);
    DefineCaixaAtaque(Jog, 29, 22, 8, 40, 55, 165, 1, 3, 9, 1);
    DefineCaixaAtaque(Jog, 29, 25, 0, 0, 0, 0, 0, 0, 0, 0);
  end;
  if (P.Personagem) = 7 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao mod 2 = 0)) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao mod 2 <> 0)) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 16 then
      begin
        P.Quadro := Desloc+37;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 2);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -2);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 4);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -4);
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) >= 5 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+44;
      end;
      if ((P.QuadroAcao) > 0) and ((P.QuadroAcao) < 5) then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 7);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -7);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 12);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -12);
        end;
      end;
      if (P.QuadroAcao) >= 3 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+45;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+46;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 6);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -6);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 11);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -11);
      end;
      P.EhChute := 1;
    end;
    if ((P.Acao) = 29) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+38;
    end;
    if ((P.Acao) = 29) and ((P.QuadroAcao) > 2) then
    begin
      P.Quadro := Desloc+38;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 25);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -25);
      end;
      for Cont := 1 to 3 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
      end;
    end;
    if (P.Acao) = 30 then
    begin
      P.Recuo := 0;
      P.Quadro := (Random(46)+1)+Desloc;
      if (Flash = 1) and (Random(5) = 0) then
      begin
        FlashVermelho := 3;
      end;
      if Random(3) = 0 then
      begin
        PausaImpacto := Random(3)+3;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 3);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -3);
      end;
      O.Quadro := (Random(2)+26)+(50-Desloc);
      O.QuadroAcao := 0;
      O.DuracaoAcao := 5;
      O.VelY := 0;
      O.Y := (O.Y) + 10;
      if ((ChaoY)) < O.Y then
      begin
        O.Y := (ChaoY);
      end;
      if (P.Lado) = 1 then
      begin
        O.X := (((Random(2) shl 3))) + ((P.X) + 40);
      end;
      if (P.Lado) = 2 then
      begin
        O.X := ((P.X) - 40) - (((Random(2) shl 3)));
      end;
      P.Acertos := (P.Acertos)+1;
      P.TempoAcertos := 43;
      if Random(4) = 0 then
      begin
        SomPendente := 7;
      end;
      if Random(4) = 0 then
      begin
        SomPendente := 8;
      end;
      if Random(4) = 0 then
      begin
        SomPendente := 9;
      end;
      CriaEfeito(1, '', 0, Random(40) + (O.X - 20), Random(100) + (O.Y - 150));
      if ((P.QuadroAcao)) > ((P.DuracaoAcao))-2 then
      begin
        P.DanoGolpe := 36;
        O.Vida := (O.Vida) - ((((P.DanoGolpe))) * NivelDano);
        P.Acao := 1;
        P.Quadro := Desloc+12;
        if (O.Vida) > 0 then
        begin
          PausaImpacto := 5;
        end;
        P.QuadroAcao := 0;
        P.VelY := -48;
        P.NoAr := 1;
        AcaoJogador(Jog, 21);
        AcaoJogador(3-Jog, 10);
        O.Recuo := 30;
        O.VelY := -35;
        if (O.Lado) = 1 then
        begin
          O.VelAngular := -25;
        end;
        if (O.Lado) = 2 then
        begin
          O.VelAngular := 25;
        end;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+2, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+3, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+4, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+6, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+8, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+10, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+12, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+13, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+15, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+17, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+19, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -18, 35, 25, 130);
    DefineCaixaCorpo(Jog, Desloc+28, -28, 80, 40, 120);
    DefineCaixaCorpo(Jog, Desloc+29, -28, 120, 40, 160);
    DefineCaixaCorpo(Jog, Desloc+31, -12, 35, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -18, 73, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+38, -12, 35, 20, 170);
    DefineCaixaAtaque(Jog, 3, 2, 20, 45, 60, 60, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 110, 70, 140, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 25, 62, 72, 95, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 20, 90, 85, 105, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 20, 80, 60, 95, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 30, 142, 74, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 25, 88, 72, 120, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 25, 118, 82, 135, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 27, 80, 70, 115, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 30, 82, 83, 108, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 27, 80, 70, 115, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 30, 82, 83, 108, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 25, 2, -30, 10, 55, 95, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 25, 5, -30, 10, 55, 95, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 25, 8, -30, 10, 55, 95, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 25, 11, -30, 10, 55, 95, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 25, 14, -30, 10, 55, 95, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 26, 3, 20, 65, 90, 90, 1, 0, 12, 2);
    DefineCaixaAtaque(Jog, 26, 5, 20, 65, 123, 90, 1, 0, 12, 2);
    DefineCaixaAtaque(Jog, 26, 8, 20, 65, 120, 90, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 1, 5, 35, 80, 120, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 27, 3, 5, 35, 80, 120, 1, 0, 14, 2);
    DefineCaixaAtaque(Jog, 27, 6, 5, 35, 80, 120, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 28, 1, 5, 20, 65, 120, 1, 0, 22, 3);
    DefineCaixaAtaque(Jog, 29, 2, 20, 35, 65, 125, 1, 0, 5, 2);
  end;
  if (P.Personagem) = 8 then
  begin
    if (P.Acao) = 23 then
    begin
      P.Quadro := Desloc+33;
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Y := (P.Y) - 4;
      end;
      if (P.QuadroAcao mod 2 <> 0) then
      begin
        P.Y := (P.Y) + 4;
      end;
      if ((ChaoY)) < P.Y then
      begin
        P.Y := (ChaoY);
      end;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+36;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(18, 'A', Jog, (P.X) + 40, (P.Y) - 90);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(18, 'A', Jog, (P.X) - 40, (P.Y) - 90);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(18, 'B', Jog, (P.X) + 40, (P.Y) - 90);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(18, 'B', Jog, (P.X) - 60, (P.Y) - 90);
        end;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.VelY := 0;
        P.NoAr := 0;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(19, 'A', Jog, (P.X) + 35, (P.Y) - 48);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(19, 'A', Jog, (P.X) - 35, (P.Y) - 48);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(19, 'B', Jog, (P.X) + 35, (P.Y) - 48);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(19, 'B', Jog, (P.X) - 35, (P.Y) - 48);
        end;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.VelY := 0;
        P.NoAr := 0;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+40;
      end;
      if ((P.QuadroAcao) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        P.VelY := -25;
      end;
      if ((P.QuadroAcao) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        P.VelY := -32;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.DirPulo := 0;
        P.NoAr := 1;
      end;
      if ((P.QuadroAcao) > 2) and ((P.QuadroAcao) < 8) then
      begin
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 5);
        end;
        if ((P.ForcaGolpe) = 1) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -5);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 1) then
        begin
          Empurra(Jog, 12);
        end;
        if ((P.ForcaGolpe) = 2) and ((P.Lado) = 2) then
        begin
          Empurra(Jog, -12);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        CriaEfeito(17, '', Jog, (P.Y) - 90, P.X);
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.VelY := 0;
        P.NoAr := 0;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Vencedor := 1;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Vencedor := 0;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          P.X := (P.X) + 80;
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          P.X := (P.X) + 150;
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          P.X := (P.X) - 80;
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          P.X := (P.X) - 150;
        end;
        P.Y := 50;
        P.VelY := 0;
        P.DirPulo := 0;
        P.NoAr := 1;
        CriaEfeito(24, '', Jog, (P.X) - 37, (P.Y) - 80);
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 11 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 13 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 15 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 17 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) >= 8 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 5);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 8);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -5);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -8);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 42;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+33;
      end;
      if ((P.QuadroAcao mod 2 = 0)) and ((P.QuadroAcao) < 15) then
      begin
        if (P.Lado) = 1 then
        begin
          CriaEfeito(20, 'A', Jog, (P.X) + 20, (P.Y) - 90);
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(20, 'A', Jog, (P.X) - 20, (P.Y) - 90);
        end;
      end;
      O.Vencedor := 0;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+2, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+3, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+4, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+6, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+8, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+10, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+12, -17, 67, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+13, -17, 67, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+15, -17, 67, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+17, -17, 67, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+19, -17, 67, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 30, 14, 140);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 80, 34, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 120, 34, 140);
    DefineCaixaCorpo(Jog, Desloc+31, -17, 30, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -17, 67, 14, 170);
    DefineCaixaCorpo(Jog, Desloc+34, -17, 30, 14, 170);
    DefineCaixaAtaque(Jog, 3, 2, 20, 48, 62, 74, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 108, 45, 144, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 20, 48, 65, 74, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 20, 108, 60, 144, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 20, 73, 62, 99, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 30, 103, 62, 150, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 20, 73, 70, 99, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 40, 103, 78, 150, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 30, 73, 68, 120, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 30, 113, 68, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 30, 73, 68, 120, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 30, 113, 68, 160, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 27, 2, -30, 10, 45, 150, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 27, 7, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 28, 9, -10, 60, 45, 160, 1, 0, 18, 3);
  end;
  if (P.Personagem) = 9 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao mod 3 = 0)) then
    begin
      if (P.Quadro) = Desloc+33 then
      begin
        P.Quadro := Desloc+34;
      end
      else
      begin
        P.Quadro := Desloc+33;
      end;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Quadro := Desloc+35;
      end
      else
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) < 2 then
      begin
        P.Quadro := Desloc+19;
      end;
      if ((P.QuadroAcao) >= 10) and ((P.ForcaGolpe) = 1) then
      begin
        P.Quadro := Desloc+12;
      end;
      if ((P.QuadroAcao) >= 18) and ((P.ForcaGolpe) = 2) then
      begin
        P.Quadro := Desloc+12;
      end;
      if ((P.QuadroAcao) < 10) and ((P.ForcaGolpe) = 1) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 14);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -14);
        end;
      end;
      if ((P.QuadroAcao) < 18) and ((P.ForcaGolpe) = 2) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 13);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -13);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 26 then
    begin
      P.DirPulo := 0;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.VelY := -10;
        P.NoAr := 1;
      end;
      if (P.QuadroAcao) < 8 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 6);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -6);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 12);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -12);
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 9;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 15;
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) < 3 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 20);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 25);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -20);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -25);
        end;
      end;
      if ((P.QuadroAcao) >= 6) and ((P.ForcaGolpe) = 2) then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+24;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        P.VelY := 0;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) >= 3 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 4);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -4);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 12);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -12);
        end;
        P.Y := (P.Y) + 15;
        if ((ChaoY)) <= P.Y then
        begin
          P.Acao := 1;
          P.QuadroAcao := 0;
          P.GolpeAtivo := 0;
          P.Y := (ChaoY);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 46;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.Quadro := Desloc+36;
      end;
      if ((P.QuadroAcao) >= 0) and ((P.QuadroAcao) <= 10) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 12);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -12);
        end;
      end;
      if (P.QuadroAcao) = 11 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+38;
      end;
      if ((P.QuadroAcao) >= 12) and ((P.QuadroAcao) <= 18) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 15);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -15);
        end;
        P.Y := (P.Y) - 18;
        P.EhChute := 1;
        O.Vencedor := 0;
      end;
      if (P.QuadroAcao) = 22 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 22 then
      begin
        P.VelY := -14;
        P.NoAr := 1;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+2, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+3, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+4, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+6, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+8, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+10, -17, 70, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+12, -17, 70, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+13, -17, 70, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+15, -17, 70, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+17, -17, 70, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+19, -17, 85, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 30, 14, 130);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 80, 34, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 120, 34, 140);
    DefineCaixaCorpo(Jog, Desloc+31, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+32, -17, 65, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+35, -27, 110, 40, 140);
    DefineCaixaCorpo(Jog, Desloc+37, -17, 10, 14, 130);
    DefineCaixaCorpo(Jog, Desloc+40, -17, 30, 14, 120);
    DefineCaixaCorpo(Jog, Desloc+42, -17, 30, 14, 160);
    DefineCaixaCorpo(Jog, Desloc+44, 10, 30, 40, 160);
    DefineCaixaAtaque(Jog, 3, 2, 10, 55, 50, 65, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 30, 48, 60, 85, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 10, 50, 55, 60, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 20, 48, 70, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 10, 88, 45, 98, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 20, 135, 50, 150, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 10, 88, 45, 98, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 20, 115, 67, 135, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 20, 80, 67, 100, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 20, 90, 69, 110, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 20, 80, 67, 100, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 20, 90, 69, 110, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 25, 2, 20, 110, 85, 130, 1, 0, 18, 3);
    if (P.ForcaGolpe) = 1 then
    begin
      DefineCaixaAtaque(Jog, 25, 10, 0, 0, 0, 0, 0, 0, 0, 0);
    end;
    if (P.ForcaGolpe) = 2 then
    begin
      DefineCaixaAtaque(Jog, 25, 15, 0, 0, 0, 0, 0, 0, 0, 0);
    end;
    DefineCaixaAtaque(Jog, 26, 2, 10, -30, 38, 120, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 26, 6, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 4, 10, 60, 38, 80, 1, 0, 10, 2);
    DefineCaixaAtaque(Jog, 27, 6, 10, 60, 70, 80, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 28, 3, 20, 110, 75, 162, 1, 0, 16, 2);
    DefineCaixaAtaque(Jog, 29, 1, 20, 110, 85, 130, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 29, 3, 20, 110, 85, 130, 1, 2, 5, 0);
    DefineCaixaAtaque(Jog, 29, 5, 20, 110, 85, 130, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 7, 20, 110, 85, 130, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 9, 20, 110, 85, 130, 1, 2, 5, 0);
    DefineCaixaAtaque(Jog, 29, 10, 10, -30, 50, 120, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 11, 10, -30, 50, 120, 1, 2, 4, 1);
    DefineCaixaAtaque(Jog, 29, 12, 10, -30, 50, 120, 1, 2, 3, 0);
    DefineCaixaAtaque(Jog, 29, 13, 10, -30, 50, 120, 1, 2, 4, 1);
    DefineCaixaAtaque(Jog, 29, 14, 10, -30, 50, 120, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 15, 10, -30, 50, 120, 1, 2, 4, 0);
    DefineCaixaAtaque(Jog, 29, 16, 10, -30, 50, 120, 1, 2, 2, 1);
    DefineCaixaAtaque(Jog, 29, 17, 10, -30, 50, 120, 0, 0, 0, 0);
  end;
  if (P.Personagem) = 10 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao) < 12) then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 23) and ((P.QuadroAcao) = 12) then
    begin
      P.Quadro := Desloc+34;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      repeat
        S_0 := Random(3)+(Desloc+35);
      until (P.Quadro) <> S_0;
      P.Quadro := S_0;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 2);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -2);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 3);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -3);
      end;
      if Random(5) = 0 then
      begin
        SomPendente := 47;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+40;
      end;
      if ((P.QuadroAcao) = 10) and ((P.ForcaGolpe) = 1) then
      begin
        P.Quadro := Desloc+12;
      end;
      if ((P.QuadroAcao) = 16) and ((P.ForcaGolpe) = 2) then
      begin
        P.Quadro := Desloc+12;
      end;
      if ((P.QuadroAcao) >= 4) and ((P.ForcaGolpe) = 1) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 19);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -19);
        end;
      end;
      if ((P.QuadroAcao) >= 4) and ((P.QuadroAcao) < 16) and ((P.ForcaGolpe) = 2) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 17);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -17);
        end;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        for Cont := 1 to 3 do
        begin
          CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 27 then
    begin
      P.DirPulo := 0;
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) <= 4 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 16);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -16);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 20);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -20);
        end;
      end;
      if (P.QuadroAcao) >= 5 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) >= 6 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 16);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -16);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 20);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -20);
        end;
        for Cont := 1 to 3 do
        begin
          CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        end;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 15 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 15 then
      begin
        P.VelY := -35;
        P.NoAr := 1;
      end;
      if (P.QuadroAcao) = 20 then
      begin
        P.Quadro := Desloc+42;
        P.VelY := 10;
      end;
      if ((P.QuadroAcao) >= 3) and ((P.QuadroAcao) < 15) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 13);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -13);
        end;
      end;
      if ((P.QuadroAcao) >= 15) and ((P.QuadroAcao) < 20) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 23);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -23);
        end;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.EhChute := 1;
      end;
      if (P.QuadroAcao) > 14 then
      begin
        O.Vencedor := 0;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+2, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+3, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+4, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+6, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+8, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+10, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+12, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+13, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+15, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+17, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+19, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -20, 28, 19, 140);
    DefineCaixaCorpo(Jog, Desloc+28, -28, 68, 36, 112);
    DefineCaixaCorpo(Jog, Desloc+29, -28, 118, 36, 152);
    DefineCaixaCorpo(Jog, Desloc+31, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -20, 65, 20, 170);
    DefineCaixaCorpo(Jog, Desloc+40, -30, 85, 40, 120);
    DefineCaixaAtaque(Jog, 3, 2, 10, 52, 55, 68, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 122, 55, 145, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 20, 52, 60, 68, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 30, 60, 85, 85, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 10, 88, 55, 104, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 10, 140, 63, 154, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 10, 88, 65, 104, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 135, 74, 153, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 20, 60, 80, 102, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 10, 65, 75, 110, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 20, 60, 80, 102, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 10, 65, 75, 110, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 25, 1, 10, 45, 70, 105, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 25, 3, 10, 45, 70, 105, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 25, 5, 10, 45, 70, 105, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 25, 7, 10, 45, 70, 105, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 25, 9, 10, 45, 70, 105, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 25, 12, 0, 0, 0, 0, 0, 0, 4, 1);
    DefineCaixaAtaque(Jog, 26, 3, 40, 85, 75, 115, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 26, 15, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 1, -30, 30, 50, 110, 1, 0, 5, 2);
    DefineCaixaAtaque(Jog, 27, 5, -30, 100, 50, 140, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 28, 6, 20, 35, 45, 132, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 29, 3, 40, 85, 75, 115, 1, 0, 4, 3);
    DefineCaixaAtaque(Jog, 29, 5, 40, 85, 75, 115, 1, 2, 6, 2);
    DefineCaixaAtaque(Jog, 29, 7, 40, 85, 75, 115, 1, 2, 8, 2);
    DefineCaixaAtaque(Jog, 29, 9, 40, 85, 75, 115, 1, 2, 6, 2);
    DefineCaixaAtaque(Jog, 29, 11, 40, 85, 75, 115, 1, 2, 8, 1);
    DefineCaixaAtaque(Jog, 29, 13, 40, 85, 75, 115, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 15, 40, 85, 75, 115, 1, 2, 6, 1);
    DefineCaixaAtaque(Jog, 29, 17, 40, 85, 75, 115, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 19, 40, 85, 75, 115, 1, 2, 6, 1);
    DefineCaixaAtaque(Jog, 29, 23, -38, 100, 58, 138, 1, 2, 3, 3);
  end;
  if (P.Personagem) = 11 then
  begin
    if (P.Acao) = 23 then
    begin
      P.Quadro := Desloc+33;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+36;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(22, 'A', Jog, (P.X) + 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(22, 'A', Jog, (P.X) - 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(22, 'B', Jog, (P.X) + 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(22, 'B', Jog, (P.X) - 30, (P.Y) - 100);
        end;
        SomPendente := 50;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(23, 'A', Jog, (P.X) + 50, P.Y);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(23, 'A', Jog, (P.X) - 50, P.Y);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(23, 'B', Jog, (P.X) + 50, P.Y);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(23, 'B', Jog, (P.X) - 50, P.Y);
        end;
        SomPendente := 51;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if ((P.ForcaGolpe) = 1) and ((P.QuadroAcao) < 1) then
      begin
        P.Quadro := Desloc+15;
      end;
      if ((P.ForcaGolpe) = 2) and ((P.QuadroAcao) < 1) then
      begin
        P.Quadro := Desloc+6;
      end;
      if ((P.ForcaGolpe) = 1) and ((P.QuadroAcao) >= 1) then
      begin
        P.Quadro := Desloc+39;
      end;
      if ((P.ForcaGolpe) = 2) and ((P.QuadroAcao) >= 1) then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        SomPendente := 52;
      end;
      if (P.QuadroAcao) >= 1 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 19);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -19);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 16);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -16);
        end;
        for Cont := 1 to 8 do
        begin
          CriaEfeito(2, '', 0, Random(40) + (P.X - 20), Random(10) + P.Y);
        end;
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.EhChute := 0;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 7);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -7);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 12);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -12);
      end;
      if (P.ForcaGolpe) = 1 then
      begin
        P.Y := (P.Y) - 6;
      end;
      if (P.ForcaGolpe) = 2 then
      begin
        P.Y := (P.Y) - 8;
      end;
      P.EhChute := 1;
      if ((P.Acertos) >= 1) and ((O.Acao) = 19) then
      begin
        if (P.TempoAcertos) > 19 then
        begin
          O.Vencedor := 0;
        end;
        if (P.TempoAcertos) < 17 then
        begin
          O.Vencedor := 1;
        end;
      end;
      if (P.QuadroAcao) = 11 then
      begin
        P.VelY := -10;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+5;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+5;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.Quadro := Desloc+5;
      end;
      if (P.QuadroAcao) = 16 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 18 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 20 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 22 then
      begin
        P.Quadro := Desloc+7;
      end;
      if (P.QuadroAcao) = 24 then
      begin
        P.Quadro := Desloc+5;
      end;
      if (P.QuadroAcao) = 26 then
      begin
        P.Quadro := Desloc+9;
      end;
      if (P.QuadroAcao) = 28 then
      begin
        P.Quadro := Desloc+11;
      end;
      if (P.QuadroAcao) < 27 then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 7);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -7);
        end;
      end;
      if (P.QuadroAcao) >= 27 then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 12);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -12);
        end;
      end;
      if ((P.Acertos) >= 3) and ((P.TempoAcertos) >= 18) then
      begin
        O.Vencedor := 0;
      end;
      if (P.QuadroAcao) >= 28 then
      begin
        P.EhChute := 1;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+2, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+3, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+4, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+6, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+8, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+10, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+12, -9, 68, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -15, 28, 19, 140);
    DefineCaixaCorpo(Jog, Desloc+28, -28, 78, 36, 112);
    DefineCaixaCorpo(Jog, Desloc+29, -28, 118, 36, 152);
    DefineCaixaCorpo(Jog, Desloc+31, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -9, 68, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+34, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+39, -14, 75, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+41, -14, 10, 19, 150);
    DefineCaixaAtaque(Jog, 3, 2, 10, 58, 55, 68, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 20, 60, 68, 85, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 20, 58, 73, 70, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 20, 48, 85, 85, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 10, 88, 58, 102, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 10, 135, 65, 156, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 10, 89, 68, 102, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 126, 73, 147, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 20, 70, 50, 115, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 10, 85, 68, 103, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 20, 70, 50, 115, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 10, 85, 68, 103, 1, 2, 14, 0);
    if (P.ForcaGolpe) = 1 then
    begin
      DefineCaixaAtaque(Jog, 27, 1, 10, 130, 82, 158, 1, 0, 18, 3);
    end;
    if (P.ForcaGolpe) = 2 then
    begin
      DefineCaixaAtaque(Jog, 27, 1, 10, 25, 70, 55, 1, 0, 18, 3);
    end;
    DefineCaixaAtaque(Jog, 28, 0, 10, 65, 75, 83, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 28, 2, -60, 65, -10, 83, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 28, 4, 10, 65, 75, 83, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 28, 6, -60, 65, -10, 83, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 28, 8, 10, 65, 75, 83, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 29, 0, 10, 40, 70, 90, 1, 2, 2, 2);
    DefineCaixaAtaque(Jog, 29, 2, 10, 40, 70, 90, 1, 2, 1, 1);
    DefineCaixaAtaque(Jog, 29, 4, 10, 40, 70, 90, 1, 1, 1, 0);
    DefineCaixaAtaque(Jog, 29, 6, 10, 40, 70, 90, 1, 2, 1, 1);
    DefineCaixaAtaque(Jog, 29, 8, 10, 40, 70, 90, 1, 1, 1, 0);
    DefineCaixaAtaque(Jog, 29, 10, 10, 40, 70, 90, 1, 1, 2, 1);
    DefineCaixaAtaque(Jog, 29, 12, 10, 40, 70, 90, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 14, 10, 40, 70, 90, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 16, 10, 40, 70, 90, 1, 1, 3, 1);
    DefineCaixaAtaque(Jog, 29, 18, 10, 40, 70, 90, 1, 1, 6, 0);
    DefineCaixaAtaque(Jog, 29, 20, 10, 40, 70, 90, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 22, 10, 40, 70, 90, 1, 1, 4, 0);
    DefineCaixaAtaque(Jog, 29, 24, 10, 40, 70, 90, 1, 2, 3, 1);
    DefineCaixaAtaque(Jog, 29, 26, 10, 40, 70, 90, 1, 1, 5, 1);
    DefineCaixaAtaque(Jog, 29, 28, 10, 40, 70, 90, 1, 2, 6, 2);
  end;
  if (P.Personagem) = 12 then
  begin
    if (P.Acao) = 23 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Quadro := Desloc+33;
      end
      else
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.Lado) = 1 then
      begin
        P.X := (P.X) + 12;
      end;
      if (P.Lado) = 2 then
      begin
        P.X := (P.X) - 12;
      end;
      if ((P.X) - ((CameraX))) <= 100 then
      begin
        P.Lado := 1;
      end;
      if ((P.X) - ((CameraX))) >= 300 then
      begin
        P.Lado := 2;
      end;
      if ((P.QuadroAcao mod 8 = 0)) and (Random(2) = 0) then
      begin
        if (P.Lado) = 1 then
        begin
          P.Lado := 2;
        end
        else
        begin
          if (P.Lado) = 2 then
          begin
            P.Lado := 1;
          end;
        end;
      end;
      for Cont := 1 to 5 do
      begin
        CriaEfeito(2, '', 0, Random(40) + (P.X - 30), Random(10) + P.Y);
      end;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 0) then
    begin
      P.Quadro := Desloc+12;
    end;
    if ((P.Acao) = 24) and ((P.QuadroAcao) = 2) then
    begin
      P.Quadro := Desloc+30;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) + 35, (P.Y) - 105);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(9, 'A', Jog, (P.X) - 35, (P.Y) - 105);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) + 35, (P.Y) - 105);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(9, 'B', Jog, (P.X) - 35, (P.Y) - 105);
        end;
        SomPendente := 53;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
        SomPendente := 54;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (((P.QuadroAcao) <> 8) and ((P.QuadroAcao) = 10) and ((P.ForcaGolpe) = 2)) or (((P.QuadroAcao) = 8) and (((P.ForcaGolpe) = 1) or ((P.QuadroAcao) = 10) and ((P.ForcaGolpe) = 2))) then
      begin
        P.Quadro := Desloc+40;
        P.NoAr := 1;
        P.VelY := -6;
      end;
      if (P.Quadro) = Desloc+39 then
      begin
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 15;
          if (P.Lado) = 1 then
          begin
            Empurra(Jog, 4);
          end;
          if (P.Lado) = 2 then
          begin
            Empurra(Jog, -4);
          end;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 17;
          if (P.Lado) = 1 then
          begin
            Empurra(Jog, 8);
          end;
          if (P.Lado) = 2 then
          begin
            Empurra(Jog, -8);
          end;
        end;
      end;
      if (P.Quadro) = Desloc+40 then
      begin
        P.NoAr := 1;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 6 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 16 then
      begin
        P.Quadro := Desloc+41;
      end;
      P.Y := (P.Y) - 11;
      P.Y := ((P.QuadroAcao)) + (P.Y);
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 10);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -10);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 15);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -15);
      end;
      if (P.QuadroAcao) = 2 then
      begin
        SomPendente := 55;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        SomPendente := 55;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        SomPendente := 56;
      end;
      if ((P.QuadroAcao) >= 6) and ((P.QuadroAcao) <= 16) then
      begin
        O.Vencedor := 0;
      end;
      if (P.QuadroAcao) >= 10 then
      begin
        P.EhChute := 1;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 13 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 25 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) <= 8 then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 15);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -15);
        end;
      end;
      if ((P.QuadroAcao) >= 13) and ((P.QuadroAcao) < 25) then
      begin
        P.Y := (P.Y) - 12;
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 4);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -4);
        end;
      end;
      if (P.QuadroAcao) = 25 then
      begin
        P.NoAr := 1;
        P.DirPulo := 0;
        P.VelY := -8;
      end;
      O.Recuo := 0;
      if (P.QuadroAcao) >= 13 then
      begin
        P.EhChute := 1;
        O.Vencedor := 0;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+2, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+3, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+4, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+6, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+8, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+10, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+12, -9, 72, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+13, -9, 72, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+15, -9, 72, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+17, -9, 72, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+19, -9, 90, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+21, -15, 28, 19, 140);
    DefineCaixaCorpo(Jog, Desloc+28, -28, 78, 36, 112);
    DefineCaixaCorpo(Jog, Desloc+29, -28, 118, 36, 152);
    DefineCaixaCorpo(Jog, Desloc+31, -14, 30, 19, 170);
    DefineCaixaCorpo(Jog, Desloc+32, -9, 72, 24, 170);
    DefineCaixaCorpo(Jog, Desloc+35, -8, 30, 26, 175);
    DefineCaixaCorpo(Jog, Desloc+39, -14, 30, 25, 170);
    DefineCaixaCorpo(Jog, Desloc+41, -14, 70, 19, 150);
    DefineCaixaAtaque(Jog, 3, 2, 15, 60, 80, 70, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 15, 110, 58, 145, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 2, 15, 10, 60, 60, 1, 2, 5, 0);
    DefineCaixaAtaque(Jog, 5, 5, 15, 10, 60, 60, 1, 2, 10, 0);
    DefineCaixaAtaque(Jog, 6, 5, 15, 60, 97, 80, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 83, 70, 93, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 15, 138, 75, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 10, 35, 42, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 130, 90, 160, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 35, 70, 75, 110, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 20, 80, 90, 135, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 35, 70, 75, 110, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 20, 80, 90, 135, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 26, 3, 5, -8, 45, 110, 1, 0, 20, 4);
    DefineCaixaAtaque(Jog, 26, 9, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 27, 2, 5, 104, 90, 132, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 27, 8, 5, 104, 90, 132, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 27, 12, 5, 104, 90, 132, 1, 0, 8, 2);
    DefineCaixaAtaque(Jog, 27, 17, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 28, 1, 5, -2, 45, 110, 1, 2, 1, 1);
    DefineCaixaAtaque(Jog, 28, 5, 5, -2, 45, 110, 1, 2, 2, 2);
    DefineCaixaAtaque(Jog, 28, 9, 5, -2, 45, 110, 1, 2, 1, 3);
    DefineCaixaAtaque(Jog, 28, 13, 5, -2, 45, 110, 1, 2, 5, 2);
    DefineCaixaAtaque(Jog, 28, 15, 5, -2, 45, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 28, 17, 5, -2, 45, 110, 1, 2, 7, 2);
    DefineCaixaAtaque(Jog, 28, 19, 5, -2, 45, 110, 1, 2, 7, 1);
    DefineCaixaAtaque(Jog, 28, 21, 5, -2, 45, 110, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 28, 23, 5, -2, 45, 110, 1, 2, 9, 1);
    DefineCaixaAtaque(Jog, 28, 25, 0, 0, 0, 0, 0, 0, 0, 0);
  end;
  if (P.Personagem) = 13 then
  begin
    if (P.Acao) = 23 then
    begin
      P.Quadro := Desloc+33;
      P.Y := (P.Y) - (((Round((Cos(((P.QuadroAcao)) / 3)) * 6))));
      if (((((ChaoY))-10))) < P.Y then
      begin
        P.Y := ((((ChaoY))-10));
      end;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+36;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(26, 'A', Jog, (P.X) + 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(26, 'A', Jog, (P.X) - 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(26, 'B', Jog, (P.X) + 30, (P.Y) - 100);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(26, 'B', Jog, (P.X) - 30, (P.Y) - 100);
        end;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        SomPendente := 57;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 11 then
      begin
        P.Quadro := Desloc+41;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 8);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -8);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 13);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -13);
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Quadro := Desloc+42;
      end
      else
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(27, 'A', Jog, (P.X) + 45, (P.Y) - 78);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(27, 'A', Jog, (P.X) - 45, (P.Y) - 78);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(27, 'B', Jog, (P.X) + 45, (P.Y) - 78);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(27, 'B', Jog, (P.X) - 45, (P.Y) - 78);
        end;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        SomPendente := 58;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+33;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        CriaEfeito(17, '', Jog, (P.Y) - 90, P.X);
        CriaEfeito(17, '', Jog, ((CameraX+80)), ((CameraY+110)));
        CriaEfeito(17, '', Jog, ((CameraX+160)), ((CameraY+110)));
        CriaEfeito(17, '', Jog, ((CameraX+240)), ((CameraY+110)));
        CriaEfeito(17, '', Jog, ((CameraX+$140)), ((CameraY+110)));
        if (P.ForcaGolpe) = 1 then
        begin
          P.X := ((CameraX+80));
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.X := ((CameraX+160));
        end;
        if (P.ForcaGolpe) = 3 then
        begin
          P.X := ((CameraX+240));
        end;
        if (P.ForcaGolpe) = 4 then
        begin
          P.X := ((CameraX+$140));
        end;
        P.Y := ((CameraY+150));
        P.NoAr := 1;
        P.VelY := 0;
        SomPendente := 41;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        P.Quadro := Desloc+44;
      end
      else
      begin
        P.Quadro := Desloc+45;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, 14);
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, -14);
      end;
      if (P.Acertos) > 1 then
      begin
        O.Vencedor := 0;
      end;
      if (P.QuadroAcao) >= 15 then
      begin
        P.EhChute := 1;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        SomPendente := 59;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+2, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+3, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+4, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+6, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+8, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+10, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+12, -12, 55, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+13, -12, 55, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+15, -12, 55, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+17, -12, 55, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+19, -12, 55, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 30, 17, 120);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 60, 27, 120);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 100, 27, 130);
    DefineCaixaCorpo(Jog, Desloc+31, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+32, -12, 62, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+33, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+34, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+37, -8, 45, 45, 120);
    DefineCaixaCorpo(Jog, Desloc+42, -12, 25, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+44, -12, 50, 12, 100);
    DefineCaixaAtaque(Jog, 3, 2, 15, 38, 87, 52, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 15, 95, 75, 130, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 15, 38, 90, 52, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 15, 55, 100, 75, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 63, 65, 78, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 15, 138, 68, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 20, 75, 75, 90, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 130, 50, 160, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 35, 70, 90, 107, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, -70, 90, 83, 120, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 35, 70, 90, 107, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, -70, 90, 83, 120, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 26, 5, 30, 40, 75, 90, 1, 2, 10, 2);
    DefineCaixaAtaque(Jog, 26, 8, 30, 45, 90, 120, 1, 1, 8, 1);
    DefineCaixaAtaque(Jog, 26, 11, 30, 80, 70, 120, 1, 2, 3, 0);
    DefineCaixaAtaque(Jog, 29, 1, -60, 45, 90, 105, 1, 2, 3, 2);
    DefineCaixaAtaque(Jog, 29, 3, -60, 45, 90, 105, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 5, -60, 45, 90, 105, 1, 2, 3, 2);
    DefineCaixaAtaque(Jog, 29, 7, -60, 45, 90, 105, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 9, -60, 45, 90, 105, 1, 2, 3, 3);
    DefineCaixaAtaque(Jog, 29, 11, -60, 45, 90, 105, 1, 2, 4, 2);
    DefineCaixaAtaque(Jog, 29, 13, -60, 45, 90, 105, 1, 2, 3, 2);
    DefineCaixaAtaque(Jog, 29, 15, -60, 45, 90, 105, 1, 2, 18, 3);
  end;
  if (P.Personagem) = 14 then
  begin
    if ((P.Acao) = 23) and ((P.QuadroAcao mod 3 = 0)) then
    begin
      if (P.Quadro) = Desloc+33 then
      begin
        P.Quadro := Desloc+34;
      end
      else
      begin
        P.Quadro := Desloc+33;
      end;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+35;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+37;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(29, 'A', Jog, (P.X) + 30, (P.Y) - 85);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(29, 'A', Jog, (P.X) - 30, (P.Y) - 85);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(29, 'B', Jog, (P.X) + 30, (P.Y) - 85);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(29, 'B', Jog, (P.X) - 30, (P.Y) - 85);
        end;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        SomPendente := 60;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+39;
        if (P.Lado) = 1 then
        begin
          CriaEfeito(30, 'A', Jog, (P.X) + 42, (P.Y) - 93);
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(30, 'A', Jog, (P.X) - 42, (P.Y) - 93);
        end;
      end;
      if (P.QuadroAcao) = 32 then
      begin
        P.Quadro := Desloc+38;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        SomPendente := 61;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+42;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.QuadroAcao := 1;
      end;
      if (P.QuadroAcao) = 0 then
      begin
        SomPendente := 62;
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, 6);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, -6);
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, 9);
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -9);
      end;
      P.Y := (P.Y) + 8;
    end;
    if (P.Acao) = 28 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        P.Quadro := Desloc+45;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        P.Quadro := Desloc+46;
      end;
      if ((P.QuadroAcao) >= 4) and ((P.QuadroAcao) <= 15) then
      begin
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, 4);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          Empurra(Jog, -4);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, 8);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          Empurra(Jog, -8);
        end;
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 6;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 9;
        end;
      end;
      if (P.QuadroAcao) = 17 then
      begin
        P.NoAr := 1;
        P.DirPulo := 0;
        P.VelY := -2;
        P.Quadro := Desloc+21;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        SomPendente := 60;
      end;
      P.EhChute := 1;
    end;
    if (P.Acao) = 29 then
    begin
      if (P.QuadroAcao mod 2 = 0) then
      begin
        if (P.Quadro) = Desloc+47 then
        begin
          P.Quadro := Desloc+48;
        end
        else
        begin
          P.Quadro := Desloc+47;
        end;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        CriaEfeito(31, 'A', Jog, (P.Y) - 80, P.X);
        CriaEfeito(32, 'A', Jog, (P.Y) - 80, P.X);
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+2, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+3, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+4, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+6, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+8, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+10, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+12, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+13, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+15, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+17, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+19, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+21, -17, 42, 17, 130);
    DefineCaixaCorpo(Jog, Desloc+28, -27, 70, 35, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -27, 120, 35, 135);
    DefineCaixaCorpo(Jog, Desloc+31, -12, 42, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+32, -12, 85, 18, 160);
    DefineCaixaCorpo(Jog, Desloc+40, -17, 62, 17, 110);
    DefineCaixaAtaque(Jog, 3, 2, 15, 53, 65, 67, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 15, 120, 47, 150, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 15, 58, 62, 72, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 15, 98, 72, 155, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 95, 62, 107, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 15, 138, 58, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 93, 54, 106, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 130, 74, 160, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 35, 60, 80, 100, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 15, 86, 77, 130, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 35, 60, 80, 100, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 15, 86, 77, 130, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 27, 1, -23, 56, 23, 116, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 27, 3, -23, 56, 23, 116, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 27, 5, -23, 56, 23, 116, 1, 0, 4, 1);
    DefineCaixaAtaque(Jog, 27, 7, -23, 56, 23, 116, 1, 0, 3, 1);
    DefineCaixaAtaque(Jog, 28, 3, 10, 10, 40, 90, 1, 2, 18, 3);
    DefineCaixaAtaque(Jog, 28, 20, 0, 0, 0, 0, 0, 0, 0, 0);
  end;
  if (P.Personagem) = 15 then
  begin
    if (P.Acao) = 23 then
    begin
      if (P.QuadroAcao) <= 10 then
      begin
        P.Quadro := Desloc+33;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+34;
      end;
      if (P.QuadroAcao) = 14 then
      begin
        P.Quadro := Desloc+35;
      end;
    end;
    if (P.Acao) = 25 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+36;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+37;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+38;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(33, 'A', Jog, (P.X) + 60, (P.Y) - 92);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
        begin
          CriaEfeito(33, 'A', Jog, (P.X) - 60, (P.Y) - 92);
        end;
        if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(33, 'B', Jog, (P.X) + 60, (P.Y) - 92);
        end;
        if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
        begin
          CriaEfeito(33, 'B', Jog, (P.X) - 60, (P.Y) - 92);
        end;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        SomPendente := 63;
      end;
    end;
    if (P.Acao) = 26 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+39;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+40;
      end;
      if (P.QuadroAcao) = 8 then
      begin
        P.Quadro := Desloc+41;
      end;
      if (P.QuadroAcao) = 12 then
      begin
        P.Quadro := Desloc+42;
      end;
      if ((P.QuadroAcao) >= 2) and ((P.QuadroAcao) <= 4) and ((P.ForcaGolpe) = 2) then
      begin
        if (P.Lado) = 1 then
        begin
          Empurra(Jog, 15);
        end;
        if (P.Lado) = 2 then
        begin
          Empurra(Jog, -15);
        end;
      end;
      if (P.QuadroAcao) = 3 then
      begin
        if (P.Lado) = 1 then
        begin
          CriaEfeito(34, 'A', Jog, (P.X) + 65, (P.Y) - 30);
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(34, 'A', Jog, (P.X) - 65, (P.Y) - 30);
        end;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        SomPendente := 64;
      end;
    end;
    if (P.Acao) = 27 then
    begin
      if (P.QuadroAcao) = 0 then
      begin
        P.Quadro := Desloc+43;
      end;
      if (P.QuadroAcao) = 2 then
      begin
        P.Quadro := Desloc+44;
      end;
      if (P.QuadroAcao) = 4 then
      begin
        P.Quadro := Desloc+45;
      end;
      if (P.QuadroAcao) = 7 then
      begin
        P.Quadro := Desloc+46;
      end;
      if (P.QuadroAcao) = 10 then
      begin
        P.Quadro := Desloc+47;
      end;
      if (P.QuadroAcao) = 13 then
      begin
        P.Quadro := Desloc+48;
      end;
      if (P.QuadroAcao) = 16 then
      begin
        P.Quadro := Desloc+12;
      end;
      if (P.QuadroAcao) = 5 then
      begin
        if (P.Lado) = 1 then
        begin
          CriaEfeito(35, 'A', Jog, (P.X) + 40, (P.Y) - 160);
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(35, 'A', Jog, (P.X) - 40, (P.Y) - 160);
        end;
      end;
      if ((P.QuadroAcao) >= 0) and ((P.QuadroAcao) <= 8) then
      begin
        if (P.ForcaGolpe) = 1 then
        begin
          P.Y := (P.Y) - 6;
        end;
        if (P.ForcaGolpe) = 2 then
        begin
          P.Y := (P.Y) - 10;
          if (P.QuadroAcao) <= 2 then
          begin
            if (P.Lado) = 1 then
            begin
              Empurra(Jog, 10);
            end;
            if (P.Lado) = 2 then
            begin
              Empurra(Jog, -10);
            end;
          end;
          if (P.QuadroAcao) >= 3 then
          begin
            if (P.Lado) = 1 then
            begin
              Empurra(Jog, 3);
            end;
            if (P.Lado) = 2 then
            begin
              Empurra(Jog, -3);
            end;
          end;
        end;
      end;
      if (P.QuadroAcao) = 9 then
      begin
        P.NoAr := 1;
        P.VelY := -5;
      end;
      if (P.QuadroAcao) = 1 then
      begin
        SomPendente := 65;
      end;
      P.EhChute := 1;
      if (P.QuadroAcao) <= 3 then
      begin
        O.Vencedor := 0;
      end;
    end;
    if (P.Acao) = 28 then
    begin
      P.Quadro := Desloc+49;
      S_2 := 18-(P.QuadroAcao);
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, ((S_2)));
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 1) then
      begin
        Empurra(Jog, ((-((S_2)))));
      end;
      if ((P.Lado) = 1) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, (((S_2))) * (1.3));
      end;
      if ((P.Lado) = 2) and ((P.ForcaGolpe) = 2) then
      begin
        Empurra(Jog, -((((S_2))) * (1.3)));
      end;
      S_2 := ShortInt(P.QuadroAcao + 248);
      P.Y := (((S_2))) + (P.Y);
      if (P.QuadroAcao) = 1 then
      begin
        SomPendente := 66;
      end;
      P.EhChute := 1;
      if (P.QuadroAcao) <= 3 then
      begin
        O.Vencedor := 0;
      end;
    end;
    if (P.Acao) = 29 then
    begin
      P.Quadro := Desloc+50;
      S_2 := 22-(P.QuadroAcao);
      if S_2 < 1 then
      begin
        S_2 := 1;
      end;
      if (P.Lado) = 1 then
      begin
        Empurra(Jog, ((S_2)));
      end;
      if (P.Lado) = 2 then
      begin
        Empurra(Jog, ((-((S_2)))));
      end;
      if (P.QuadroAcao) < 20 then
      begin
        if (P.Lado) = 1 then
        begin
          CriaEfeito(36, 'A', Jog, P.X - 30, Random(20) + (P.Y - 110));
        end;
        if (P.Lado) = 2 then
        begin
          CriaEfeito(36, 'A', Jog, P.X + 30, Random(20) + (P.Y - 110));
        end;
      end;
      S_2 := ShortInt(Round(P.QuadroAcao * 0.4) + 251);
      P.Y := (((S_2))) + (P.Y);
      if (P.QuadroAcao) = 1 then
      begin
        SomPendente := 66;
      end;
      if (P.QuadroAcao) >= 15 then
      begin
        P.EhChute := 1;
      end;
      if (P.QuadroAcao) <= 15 then
      begin
        O.Vencedor := 0;
      end;
    end;
    DefineCaixaCorpo(Jog, Desloc+1, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+2, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+3, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+4, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+6, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+8, 5, 28, 35, 160);
    DefineCaixaCorpo(Jog, Desloc+10, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+12, -12, 64, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+13, -12, 64, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+15, -12, 64, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+17, -12, 64, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+19, -20, 85, 25, 160);
    DefineCaixaCorpo(Jog, Desloc+21, -8, 28, 23, 120);
    DefineCaixaCorpo(Jog, Desloc+28, -30, 70, 38, 110);
    DefineCaixaCorpo(Jog, Desloc+29, -30, 120, 38, 135);
    DefineCaixaCorpo(Jog, Desloc+31, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+32, -12, 64, 20, 160);
    DefineCaixaCorpo(Jog, Desloc+36, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+39, -8, 40, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+43, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+49, -8, 28, 23, 160);
    DefineCaixaCorpo(Jog, Desloc+50, -8, 28, 23, 160);
    DefineCaixaAtaque(Jog, 3, 2, 15, 45, 73, 53, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 4, 2, 15, 110, 69, 150, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 5, 5, 15, 45, 83, 53, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 6, 5, 15, 20, 75, 80, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 8, 2, 15, 82, 75, 91, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 9, 2, 15, 130, 73, 160, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 10, 5, 15, 74, 68, 83, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 11, 5, 10, 110, 94, 160, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 13, 2, 25, 60, 70, 105, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 14, 2, 10, 90, 80, 120, 1, 1, 7, 0);
    DefineCaixaAtaque(Jog, 15, 5, 25, 60, 70, 105, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 16, 5, 10, 90, 80, 120, 1, 2, 14, 0);
    DefineCaixaAtaque(Jog, 27, 5, -40, -30, 75, 110, 1, 0, 18, 3);
    DefineCaixaAtaque(Jog, 27, 10, 0, 0, 0, 0, 0, 0, 0, 0);
    DefineCaixaAtaque(Jog, 28, 2, 10, 54, 68, 90, 1, 0, 15, 3);
    DefineCaixaAtaque(Jog, 29, 2, 10, 54, 68, 90, 1, 2, 9, 2);
    DefineCaixaAtaque(Jog, 29, 5, 10, 54, 68, 90, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 7, 10, 54, 68, 90, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 10, 10, 54, 68, 90, 1, 2, 7, 2);
    DefineCaixaAtaque(Jog, 29, 13, 10, 54, 68, 90, 1, 2, 5, 1);
    DefineCaixaAtaque(Jog, 29, 15, 10, 54, 68, 90, 1, 2, 12, 2);
  end;
end;

end.