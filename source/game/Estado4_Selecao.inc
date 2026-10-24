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

{ Estado 4: selecao de lutador }
procedure TJogo.Estado4_Selecao;
var
  I, J, C, X, Y, Ch, N: Integer;
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

begin
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
  for C := 0 to 14 do
  begin
    if C < 8 then Ch := X + (C * 49 - 402) else Ch := X + ((C - 8) * 49 - 402);
    if C + C * 4 < ImgRetrato.Count then
    begin
      if C < 8 then R := Rect(Ch, 163, Ch + 50, 223) else R := Rect(Ch, 223, Ch + 50, 283);
      ImgRetrato[C + C * 4].DrawAlpha(Tela, R, 0, 60);
    end;
  end;
  if FaseSelecao = 1 then
  begin
    Inc(TempoEstado, 20);
    if TempoEstado >= 300 then
    begin
      TempoEstado := 300;
      FaseSelecao := 2;
    end;
  end;
  if FaseSelecao = 2 then
  begin
    for J := 1 to 2 do
    begin
      if Lutador[J].Ativo then
      begin
        Ch := Lutador[J].Personagem;
        if J = 1 then X := 52 else X := 252;
        Retrato((Ch - 1) * 5 + 4, X, 25);
        if not Lutador[J].Escolheu then
        begin
          if Ch <= 8 then
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 1) * 49 - 402), 163)
          else
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 9) * 49 - 402), 223);
        end;
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
      if Lutador[J].Ativo and not Lutador[J].Escolheu then
      begin
        X := 10;
        Y := 20;
        Ch := Lutador[J].Personagem;
        if Ch <= 8 then
        begin
          X := (Ch - 1) * 49 + 3;
          Y := 160;
        end
        else
        begin
          X := (Ch - 9) * 49 + 3;
          Y := 220;
        end;
        if not Odd(ContPisca) then Cor2 := RGB(50, 50, 50) else Cor2 := Preto;
        if J = 1 then
          texto(X, Y, '1P', AEsq, 10, RGB(100, 100, 200) + Cor2)
        else
          texto(X + 35, Y, '2P', AEsq, 10, RGB(200, 50, 50) + Cor2);
      end;

    K1 := TecP1;
    K2 := TecP2;
    { jogador 1 (teclado) }
    if not Lutador[1].Escolheu and Lutador[1].Ativo then
    begin
      if ((K1 and 4) <> 0) and not Lutador[1].AntEsq then
      begin
        Dec(Lutador[1].Personagem);
        SomEfeitos.Tocar(1);
      end;
      if ((K1 and 8) <> 0) and not Lutador[1].AntDir then
      begin
        Inc(Lutador[1].Personagem);
        SomEfeitos.Tocar(1);
      end;
      if ((K1 and 1) <> 0) and not Lutador[1].AntCima and (Lutador[1].Personagem > 8) then
      begin
        Dec(Lutador[1].Personagem, 8);
        SomEfeitos.Tocar(1);
      end;
      if ((K1 and 2) <> 0) and not Lutador[1].AntBaixo and (Lutador[1].Personagem <= 8) then
      begin
        Inc(Lutador[1].Personagem, 8);
        SomEfeitos.Tocar(1);
      end;
      if ((K1 and 16) <> 0) and not Lutador[1].AntSocoFraco then
      begin
        Lutador[1].Escolheu := True;
        criaadversario(1, Lutador[1].Personagem);
        SomEfeitos.Tocar(2);
      end;
    end;
    { jogador 2 (joystick emulado) }
    if not Lutador[2].Escolheu and Lutador[2].Ativo then
    begin
      if ((K2 and 4) <> 0) and not Lutador[2].AntEsq then
      begin
        Dec(Lutador[2].Personagem);
        SomEfeitos.Tocar(1);
      end;
      if ((K2 and 8) <> 0) and not Lutador[2].AntDir then
      begin
        Inc(Lutador[2].Personagem);
        SomEfeitos.Tocar(1);
      end;
      if ((K2 and 1) <> 0) and not Lutador[2].AntCima and (Lutador[2].Personagem > 8) then
      begin
        Dec(Lutador[2].Personagem, 8);
        SomEfeitos.Tocar(1);
      end;
      if ((K2 and 2) <> 0) and not Lutador[2].AntBaixo and (Lutador[2].Personagem <= 8) then
      begin
        Inc(Lutador[2].Personagem, 8);
        SomEfeitos.Tocar(1);
      end;
      if ((K2 and 16) <> 0) and not Lutador[2].AntSocoFraco then
      begin
        Lutador[2].Escolheu := True;
        criaadversario(2, Lutador[2].Personagem);
        SomEfeitos.Tocar(2);
      end;
    end;
    for J := 1 to 2 do
    begin
      if Lutador[J].Personagem < 1 then Lutador[J].Personagem := FQtdLutadores;
      if Lutador[J].Personagem > FQtdLutadores then Lutador[J].Personagem := pnChaves;
    end;
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
