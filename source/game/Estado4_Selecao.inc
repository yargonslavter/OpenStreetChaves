{ Estado4_Selecao.inc - Estado CHS_SELECAO: selecao de lutador. }

{ Sorteia a ordem dos 7 adversarios do jogador Jog (Adversarios[1..7]); o 8o e o chefe do personagem.
  Chefe e personagens que nunca aparecem vem de Dados/Lutadores/Cnn.ini. }
procedure TJogo.criaadversario(Jog, Pers: Integer);
var
  Disp: array of Byte;      // 1 = ainda pode ser sorteado
  I, K, R, Tent: Integer;
begin
  if (Pers < 1) or (Pers > FQtdLutadores) then Exit;
  for K := 1 to 8 do Lutador[Jog].Adversarios[K] := 1;
  Lutador[Jog].Adversarios[8] := FLutadores[Pers].Chefe;
  SetLength(Disp, FQtdLutadores + 1);
  for I := 1 to FQtdLutadores do
    if I in FLutadores[Pers].NaoEnfrenta then Disp[I] := 0 else Disp[I] := 1;
  if (FLutadores[Pers].Chefe >= 1) and (FLutadores[Pers].Chefe <= FQtdLutadores) then
    Disp[FLutadores[Pers].Chefe] := 0;
  for K := 1 to 7 do
  begin
    Tent := 0;
    repeat
      R := Random(FQtdLutadores) + 1;
      Inc(Tent);
    until ((Disp[R] <> 0) and (R <> Pers)) or (Tent > 2000);
    Lutador[Jog].Adversarios[K] := R;
    Disp[R] := 0;
  end;
end;

{ Estado 4: selecao de lutador. Os retratos ficam numa grade de ColunasGrade colunas; quando ha
  mais de LinhasVisiveis linhas, a grade rola para mostrar o lutador de quem mexeu por ultimo. }
procedure TJogo.Estado4_Selecao;
const
  ColunasGrade = 8;
  LinhasVisiveis = 2;
var
  I, J, C, X, Y, Ch, N, QtdLinhas: Integer;
  Cor, Cor2: TColor;
  K1, K2, E1, E2: Byte;
  R: TRect;

  { Desenha um retrato, se existir.
    @param(Indice numero em ImgRetrato)
    @param(PX esquerda)
    @param(PY topo) }
  procedure Retrato(Indice, PX, PY: Integer);
  begin
    if Indice < ImgRetrato.Count then
      ImgRetrato[Indice].Draw(Tela, PX, PY, 0);
  end;

  { Posicao de um personagem na grade, se a linha dele esta visivel.
    @param(Pers personagem (1..FQtdLutadores))
    @param(PX recebe a esquerda, sem o deslocamento da faixa (0 = primeira coluna))
    @param(PY recebe o topo)
    @returns(True se a linha do personagem esta na parte visivel da grade) }
  function NaGrade(Pers: Integer; out PX, PY: Integer): Boolean;
  var
    L: Integer;
  begin
    L := (Pers - 1) div ColunasGrade - LinhaSelecao;
    PX := ((Pers - 1) mod ColunasGrade) * 49;
    PY := 163 + L * 60;
    Result := (L >= 0) and (L < LinhasVisiveis);
  end;

  { Rola a grade ate a linha do personagem do jogador ficar visivel.
    @param(Jog jogador (1 ou 2)) }
  procedure Seguir(Jog: Integer);
  var
    L: Integer;
  begin
    L := (Lutador[Jog].Personagem - 1) div ColunasGrade;
    if L < LinhaSelecao then LinhaSelecao := L;
    if L >= LinhaSelecao + LinhasVisiveis then LinhaSelecao := L - LinhasVisiveis + 1;
  end;

  { Proximo liberado andando de um em um (dando a volta na lista).
    @param(P ponto de partida)
    @param(Passo 1 = para a direita, -1 = para a esquerda)
    @returns(o proximo liberado; P se nenhum outro estiver liberado) }
  function Vizinho(P, Passo: Integer): Integer;
  var
    T: Integer;
  begin
    Result := P;
    for T := 1 to FQtdLutadores do
    begin
      Result := Result + Passo;
      if Result < 1 then Result := FQtdLutadores;
      if Result > FQtdLutadores then Result := 1;
      if Liberado(Result) then Exit;
    end;
    Result := P;
  end;

  { Liberado mais perto da mesma coluna, na primeira linha acima ou abaixo que tiver algum.
    @param(P ponto de partida)
    @param(Passo -1 = linhas de cima, 1 = linhas de baixo)
    @returns(o liberado encontrado; P se nao houver) }
  function OutraLinha(P, Passo: Integer): Integer;
  var
    L, Col, D, Q: Integer;
  begin
    Result := P;
    Col := (P - 1) mod ColunasGrade;
    L := (P - 1) div ColunasGrade + Passo;
    while (L >= 0) and (L < QtdLinhas) do
    begin
      for D := 0 to ColunasGrade - 1 do
      begin
        Q := L * ColunasGrade + Col - D + 1;
        if (Col - D >= 0) and Liberado(Q) then Exit(Q);
        Q := L * ColunasGrade + Col + D + 1;
        if (Col + D < ColunasGrade) and Liberado(Q) then Exit(Q);
      end;
      L := L + Passo;
    end;
  end;

  { Setas e botao 1 de um jogador que ainda nao escolheu: esquerda/direita andam um (dando a
    volta na lista), cima/baixo andam uma linha; os bloqueados ("?") sao pulados; o botao confirma.
    @param(Jog jogador (1 ou 2))
    @param(K teclas do jogador (1 cima, 2 baixo, 4 esquerda, 8 direita, 16 botao 1)) }
  procedure Navegar(Jog: Integer; K: Byte);
  var
    P: Integer;
  begin
    if Lutador[Jog].Escolheu or not Lutador[Jog].Ativo then Exit;
    P := Lutador[Jog].Personagem;
    if ((K and 4) <> 0) and not Lutador[Jog].AntEsq then P := Vizinho(P, -1);
    if ((K and 8) <> 0) and not Lutador[Jog].AntDir then P := Vizinho(P, 1);
    if ((K and 1) <> 0) and not Lutador[Jog].AntCima then P := OutraLinha(P, -1);
    if ((K and 2) <> 0) and not Lutador[Jog].AntBaixo then P := OutraLinha(P, 1);
    if P <> Lutador[Jog].Personagem then
    begin
      Lutador[Jog].Personagem := P;
      SomEfeitos.Tocar(1);
      Seguir(Jog);
    end;
    if ((K and 16) <> 0) and not Lutador[Jog].AntSocoFraco then
    begin
      Lutador[Jog].Escolheu := True;
      criaadversario(Jog, P);
      SomEfeitos.Tocar(2);
    end;
  end;

begin
  QtdLinhas := (FQtdLutadores + ColunasGrade - 1) div ColunasGrade;
  RelogioParado := False;
  if (MusicaAtual <> 0) and (SomMusica.Count > 0) then SomMusica.Parar(0);
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  barra(0, 300 - TempoEstado, 200, 600 - TempoEstado, RGB(120, 120, 255));
  barra(200, TempoEstado - 300, 400, TempoEstado, Rosa);
  { bandeiras repetidas ao fundo }
  for I := 0 to 3 do
    for J := 0 to 1 do
    begin
      ImgIcone.PorNome('LogoFundo-' + CodigoIdioma(Idioma)).Draw(Tela, I * 145 - 67, (J * 200 - 200) + (ContagemTick shl 3), 0);
      ImgIcone.PorNome('LogoFundo-' + CodigoIdioma(Idioma)).Draw(Tela, I * 145, (J * 200 - 100) + (ContagemTick shl 3), 0);
    end;
  { faixa com os retratos }
  X := Round(TempoEstado * 1.35);
  barra(X - 410, 156, X, 290, RGB(30, 50, 70));
  barra(X - 410, 158, X, 160, Branco);
  barra(X - 410, 286, X, 288, Branco);
  if LinhaSelecao > QtdLinhas - LinhasVisiveis then LinhaSelecao := QtdLinhas - LinhasVisiveis;
  if LinhaSelecao < 0 then LinhaSelecao := 0;
  for C := 1 to FQtdLutadores do
    if NaGrade(C, Ch, Y) then
    begin
      R := Rect(X - 402 + Ch, Y, X - 402 + Ch + 50, Y + 60);
      if not Liberado(C) then
        ImgIcone.PorNome('RostoSecreto').DrawAlpha(Tela, R, 0, 60)
      else if (C - 1) * 5 < ImgRetrato.Count then
        ImgRetrato[(C - 1) * 5].DrawAlpha(Tela, R, 0, 60);
    end;
  { setas piscando quando ha linhas escondidas acima ou abaixo }
  if (FaseSelecao = 2) and (ContPisca < 13) then
  begin
    if LinhaSelecao > 0 then ImgIcone.PorNome('Cima').Draw(Tela, 194, 144, 0);
    if LinhaSelecao + LinhasVisiveis < QtdLinhas then ImgIcone.PorNome('Baixo').Draw(Tela, 194, 288, 0);
  end;
  if FaseSelecao = 1 then
  begin
    { entrando: comeca mostrando a linha de quem ja esta jogando }
    if Lutador[2].Ativo then Seguir(2);
    if Lutador[1].Ativo then Seguir(1);
    Inc(TempoEstado, 20);
    if TempoEstado >= 300 then
    begin
      TempoEstado := 300;
      FaseSelecao := 2;
    end;
  end;
  if FaseSelecao = 2 then
  begin
    { personagem fora da lista ou bloqueado: vai para o proximo liberado }
    for J := 1 to 2 do
    begin
      if (Lutador[J].Personagem < 1) or (Lutador[J].Personagem > FQtdLutadores) then Lutador[J].Personagem := pnChaves;
      if not Liberado(Lutador[J].Personagem) then Lutador[J].Personagem := Vizinho(Lutador[J].Personagem, 1);
    end;
    for J := 1 to 2 do
    begin
      if Lutador[J].Ativo then
      begin
        Ch := Lutador[J].Personagem;
        if J = 1 then X := 52 else X := 252;
        Retrato((Ch - 1) * 5 + 4, X, 25);
        if not Lutador[J].Escolheu and NaGrade(Ch, X, Y) then
          Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + X - 402, Y);
        if J = 1 then X := 100 else X := 300;
        texto(X, 130 - Round(Cos(ContPisca / 4.3) * 4), Linha(TxtNomes, Ch), ACentro, 12, RGB(180, 220, 160));
      end;
    end;
    N := Round(Cos(ContagemTick / 4) * 20);
    Cor := RGB(N + 230, N + 230, 255);
    texto(200, Round(TempoEstado * 0.3) - 96, Linha(TxtGeral, 8), ACentro, 18, Cor);
    Cor := RGB(250, 150, 150);
    if (ContagemSeg <= 5) and (not Odd(ContagemTick)) then Cor := RGB(250, 220, 220);
    texto(200, 15, IntToStr(ContagemSeg), ACentro, 22, Cor);
    if ContagemSeg >= 1 then
    begin
      Dec(ContagemTick);
      if ContagemTick = 0 then
      begin
        Dec(ContagemSeg);
        ContagemTick := 25;
      end;
    end;
    Inc(ContPisca);
    if ContPisca >= 25 then ContPisca := 0;
    { marcadores 1P / 2P sobre o retrato escolhido }
    for J := 1 to 2 do
      if Lutador[J].Ativo and not Lutador[J].Escolheu and NaGrade(Lutador[J].Personagem, X, Y) then
      begin
        Inc(X, 3);
        Dec(Y, 3);
        if not Odd(ContPisca) then Cor2 := RGB(50, 50, 50) else Cor2 := Preto;
        if J = 1 then
          texto(X, Y, '1P', AEsq, 10, RGB(100, 100, 200) + Cor2)
        else
          texto(X + 35, Y, '2P', AEsq, 10, RGB(200, 50, 50) + Cor2);
      end;

    K1 := TecP1;
    K2 := TecP2;
    Navegar(1, K1);  // jogador 1 (teclado)
    Navegar(2, K2);  // jogador 2 (joystick emulado)
    if not Lutador[1].Ativo then Lutador[1].Escolheu := True;
    if not Lutador[2].Ativo then Lutador[2].Escolheu := True;
    { tempo esgotado: confirma automaticamente }
    if ContagemSeg = 0 then
    begin
      Lutador[1].Escolheu := True;
      if Lutador[1].Ativo then criaadversario(1, Lutador[1].Personagem);
      Lutador[2].Escolheu := True;
      if Lutador[2].Ativo then criaadversario(2, Lutador[2].Personagem);
      SomEfeitos.Tocar(2);
    end;
    if Lutador[1].Escolheu and Lutador[2].Escolheu then
    begin
      Estado := CHS_ADVERSARIOS;
      ContPisca := 0;
      TempoEstado := 0;
      Lutador[1].RoundsVencidos := 0;
      Lutador[2].RoundsVencidos := 0;
      RoundAtual := 1;
      if Lutador[1].Ativo and Lutador[2].Ativo then Estado := CHS_PREPARALUTA;
    end;
  end;
  E1 := 0;
  E2 := 0;
  if E1 = E2 then N := 0;
end;

{ Teclado do estado SELECAO: 1/2 = entrada do jogador }
procedure TJogo.Teclado_Selecao(Tk: Integer);
begin
  if (Estado = CHS_SELECAO) and (Fichas > 0) and not RelogioParado then
  begin
    if (Tk = Integer(SDL_SCANCODE_1)) and not Lutador[1].Ativo then
    begin
      Lutador[1].Ativo := True;
      Lutador[1].Escolheu := False;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
    if (Tk = Integer(SDL_SCANCODE_2)) and not Lutador[2].Ativo then
    begin
      Lutador[2].Ativo := True;
      Lutador[2].Escolheu := False;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
  end;
end;
