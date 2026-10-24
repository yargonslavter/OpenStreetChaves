{ Estado7_Golpes.inc - Estado CHS_LUTA: golpes, sequencias, CPU e defesa (seta, sequencia, golpe, sequenciagolpe, cpu, defendergolpe). Gerado a partir do codigo de maquina e revisado a mao. }

function TJogo.seta(Jog: Byte; const Dir: string): Boolean;
{ Responde True se o jogador esta segurando a direcao pedida:
  'CIMA', 'BAIXO', 'FRENTE' (para onde esta virado) ou 'TRAS'. Jogador 1 = teclado, 2 = "joystick". }
var
  K: Byte;
begin
  Result := False;
  if Jog = 1 then K := TecP1 else K := TecP2;
  if ((K and 2) <> 0) and (Dir = 'BAIXO') then Result := True;
  if ((K and 1) <> 0) and (Dir = 'CIMA') then Result := True;
  if (K and 4) <> 0 then      // esquerda
  begin
    if (Lutador[Jog].Lado = ldDireita) and (Dir = 'TRAS') then Result := True;
    if (Lutador[Jog].Lado = ldEsquerda) and (Dir = 'FRENTE') then Result := True;
  end;
  if (K and 8) <> 0 then      // direita
  begin
    if (Lutador[Jog].Lado = ldEsquerda) and (Dir = 'TRAS') then Result := True;
    if (Lutador[Jog].Lado = ldDireita) and (Dir = 'FRENTE') then Result := True;
  end;
end;

procedure TJogo.sequencia(Jog, De, Para: Byte);
{ avanca a sequencia de teclas de um golpe especial: se esta no passo De, vai para o passo Para }
begin
  if Lutador[Jog].SeqEstado = De then
  begin
    Lutador[Jog].SeqEstado := Para;
    Lutador[Jog].SeqTempo := 9;
  end;
end;

{ Vale se todos os termos da regra valem agora (Dados/Lutadores/CNN.ini, [Sequencias] e [Botoes]). }
function TJogo.RegraVale(Jog: Byte; const R: TRegraComando): Boolean;
var
  P: PLutador;
  I: Integer;
  V: Boolean;
begin
  P := @Lutador[Jog];
  Result := True;
  for I := 0 to High(R.Termos) do
  begin
    case R.Termos[I].Tipo of
      'B': V := seta(Jog, 'BAIXO');
      'F': V := seta(Jog, 'FRENTE');
      'T': V := seta(Jog, 'TRAS');
      'C': V := seta(Jog, 'CIMA');
      'b': V := P.TempoBaixo >= R.Termos[I].Valor;
      't': V := P.TempoTras >= R.Termos[I].Valor;
      'H': V := ChaoY = P.Y;
      'P': V := P.SeqEstado = R.Termos[I].Valor;
      'A': V := P.VelY <> 0;
      's': V := P.CargaSoco >= R.Termos[I].Valor;
      'k': V := P.CargaChute >= R.Termos[I].Valor;
    else
      V := False;
    end;
    if R.Termos[I].Nega then V := not V;
    if not V then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

{ Botao apertado (1 soco fraco, 2 chute fraco, 3 soco forte, 4 chute forte): executa, em ordem, os
  comandos das regras [Botoes] do personagem que valem agora. }
procedure TJogo.golpe(Jog, Botao: Byte);
var
  P: PLutador;
  I: Integer;
begin
  P := @Lutador[Jog];
  if FlashTela <> 0 then Exit;
  if (P.Personagem < 1) or (P.Personagem > High(FLutadores)) then Exit;
  with FLutadores[P.Personagem] do
    for I := 0 to High(Botoes) do
      if (Botoes[I].Botao = Botao) and RegraVale(Jog, Botoes[I]) then
        AcaoJogador(Jog, Botoes[I].Comando);
end;

procedure TJogo.sequenciagolpe(Jog: Byte);
var
  P: PLutador;
  I: Integer;
begin
  P := @Lutador[Jog];
  if seta(Jog, 'BAIXO') then
  begin
    P.TempoBaixo := (P.TempoBaixo)+1;
  end;
  if (P.TempoBaixo) > 18 then
  begin
    P.TempoBaixo := 18;
  end;
  if not seta(Jog, 'BAIXO') and ((P.TempoBaixo) > 1) then
  begin
    P.TempoBaixo := (P.TempoBaixo)-1;
  end;
  if seta(Jog, 'TRAS') then
  begin
    P.TempoTras := (P.TempoTras)+1;
  end;
  if (P.TempoTras) > 18 then
  begin
    P.TempoTras := 18;
  end;
  if not seta(Jog, 'TRAS') and ((P.TempoTras) > 1) then
  begin
    P.TempoTras := (P.TempoTras)-1;
  end;
  { regras [Sequencias] do personagem, em ordem }
  if (P.Personagem >= 1) and (P.Personagem <= High(FLutadores)) then
    with FLutadores[P.Personagem] do
      for I := 0 to High(Sequencias) do
        if RegraVale(Jog, Sequencias[I]) then
          sequencia(Jog, Sequencias[I].De, Sequencias[I].Para);
  if ((P.SeqTempo) > 0) and (PausaImpacto = 0) and (FlashTela = 0) then
  begin
    P.SeqTempo := (P.SeqTempo)-1;
    if (P.SeqTempo) = 0 then
    begin
      P.SeqEstado := 0;
    end;
  end;
end;

{ IA do computador: calcula a distancia entre os lutadores, a ameaca de projetil inimigo e o
  fator de dificuldade e roda os roteiros [IA] (ExecutarIA), que decidem os comandos.
  @param(Jog lutador controlado pelo computador, 1 ou 2) }
procedure CpuNovo(Jog: Byte);
var
  P, O: PLutador;
  E: PEfeito;
  Dist, DistProj, OppY, I: Integer;
  Ameaca: Byte;
  Fator: Double;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  Dist := Abs(Round(Lutador[1].X) - Round(Lutador[2].X));
  OppY := Round(O.Y);
  Ameaca := 0;
  DistProj := 0;
  for I := 1 to MaxEfeitos do
  begin
    E := @Efeitos[I];
    if E.PodeAcertar and (E.Dono <> Jog) and (E.Tipo <> 0) then
    begin
      Ameaca := 1;
      DistProj := Abs(Round(P.X) - Round(E.X));
    end;
  end;
  Fator := (8 - NivelJogo) * 0.6 + 1.3 - Fase * 0.1;
  ExecutarIA(Jog, Dist, DistProj, OppY, Ameaca, Fator);
end;

procedure TJogo.cpu(Jog: Byte);
{ IA do computador: decide os comandos do lutador Jog (equivale a apertar teclas) }
begin
  CpuNovo(Jog);
end;

procedure TJogo.defendergolpe(Jog: Byte);
{ Defesa automatica. Jogador humano: segurar "para tras" (em pe ou agachado) defende de golpes e projeteis.
  Computador: decide defender/pular conforme a distancia e o nivel de dificuldade. }
var
  P, O: PLutador;
  E: PEfeito;
  I: Integer;
  Dist, DistProj, Ameaca: Integer;
  Terminando: Boolean;
  ProjY: Double;
  Fator: Double;

  { Jogador humano segurando "para tras": defende em pe ou agachado. }
  procedure DefesaHumana;
  begin
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then AcaoJogador(Jog, cmDefender);
    if seta(Jog, 'TRAS') and seta(Jog, 'BAIXO') then AcaoJogador(Jog, cmDefenderBaixo);
  end;

  { Computador: pula para frente (ou, 1 vez em 8, reto). }
  procedure Pular;
  begin
    P.VelY := -32;
    P.NoAr := True;
    P.Acao := acPulo;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 99;
    P.Defendendo := False;
    if P.Lado = ldDireita then P.DirPulo := puloDireita;
    if P.Lado = ldEsquerda then P.DirPulo := puloEsquerda;
    if Random(8) = 0 then P.DirPulo := puloReto;
  end;

begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  if P.Ativo then
  begin
    if O.GolpeAtivo then DefesaHumana;
    for I := 1 to MaxEfeitos do
    begin
      E := @Efeitos[I];
      if (E.Tipo <> 0) and E.PodeAcertar and (E.Dono <> Jog) then DefesaHumana;
    end;
  end;
  if not P.Ativo then
  begin
    Dist := Abs(Round(Lutador[Jog].X) - Round(O.X));
    Ameaca := 0;
    DistProj := 0;
    Terminando := False;
    ProjY := 0;
    for I := 1 to MaxEfeitos do
    begin
      E := @Efeitos[I];
      if E.PodeAcertar and (E.Dono <> Jog) and (E.Tipo <> 0) then
      begin
        Ameaca := 1;
        DistProj := Abs(Round(P.X) - Round(E.X));
        if E.Terminando then Terminando := True;
        ProjY := E.Y;
      end;
    end;
    Fator := (8 - NivelJogo) * 0.9 + 1.2 - Fase * 0.1;
    if Fator < 0 then Fator := 0;
    // golpe do adversario chegando
    if O.GolpeAtivo and (Dist <= 160) then
    begin
      if (ChaoY - 30) >= O.Y then
        if Random(Round(0.5 * Fator)) = 0 then AcaoJogador(Jog, cmDefender);
      if (ChaoY - 30) <= O.Y then
        if Random(Round(0.5 * Fator)) = 0 then AcaoJogador(Jog, cmDefenderBaixo);
      if P.Acao = acDefesa then AcaoJogador(Jog, cmDefender);
      if P.Acao = acDefesaBaixa then AcaoJogador(Jog, cmDefenderBaixo);
    end;
    // pulo (parado ou andando)
    if (P.Acao = acParado) or (P.Acao = acAndando) then
    begin
      if (Ameaca = 1) and (DistProj <= 130) and ((P.Y - 120) < ProjY) and (Random(Round(5 * Fator)) <= 3) then
        Pular
      else if (Ameaca = 0) and (Random(Round(45 * Fator)) = 0) and not P.NoAr and not Terminando then
        Pular;
    end;
    // projetil chegando
    if (Ameaca = 1) and (DistProj <= 120) and ((P.Y - 120) < ProjY) then
      if Random(Round(0.4 * Fator)) = 0 then AcaoJogador(Jog, cmDefender);
    if (Ameaca = 1) and (DistProj <= 100) and ((P.Y - 120) >= ProjY) then
      if Random(Round(2.5 * Fator)) = 0 then AcaoJogador(Jog, cmDefenderBaixo);
  end;
end;
