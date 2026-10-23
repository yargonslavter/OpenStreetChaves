{ Estado4_Selecao.inc - Estado CHS_SELECAO: selecao de lutador. }

{ Sorteia a ordem dos 7 adversarios do jogador Jog (Adversarios[1..7]); o 8o e o chefe fixo. }
procedure TJogo.criaadversario(Jog, Pers: Integer);
const
  Chefe: array[1..15] of Byte = (2, 5, 9, 1, 2, 7, 2, 5, 3, 1, 3, 1, 5, 5, 3);
  { adversarios que nao podem aparecer para cada lutador (0 = fim da lista) }
  Excl: array[1..15, 0..4] of Byte = (
    (3, 9, 0, 0, 0), (3, 8, 9, 14, 15), (1, 2, 14, 0, 0), (5, 6, 0, 0, 0), (4, 6, 0, 0, 0),
    (4, 5, 15, 0, 0), (10, 8, 0, 0, 0), (2, 7, 0, 0, 0), (1, 2, 15, 0, 0), (7, 9, 0, 0, 0),
    (1, 9, 0, 0, 0), (5, 8, 0, 0, 0), (1, 8, 14, 0, 0), (2, 3, 13, 0, 0), (1, 2, 9, 0, 0));
var
  Disp: array[1..15] of Byte;
  I, K, R, Tent: Integer;

begin
  if (Pers < 1) or (Pers > 15) then Exit;
  for K := 1 to 8 do Lutador[Jog].Adversarios[K] := 1;
  Lutador[Jog].Adversarios[8] := Chefe[Pers];
  for I := 1 to 15 do Disp[I] := 1;
  Disp[Chefe[Pers]] := 0;
  for K := 0 to 4 do
    if Excl[Pers, K] <> 0 then Disp[Excl[Pers, K]] := 0;
  for K := 1 to 7 do
  begin
    Tent := 0;
    repeat
      R := Random(15) + 1;
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

  procedure Som(Idx: Integer);
  begin
    TocarSom(Idx);
  end;

  procedure Retrato(Indice, PX, PY: Integer);
  begin
    if Indice < ImgRetrato.Count then
      ImgRetrato[Indice].Draw(Tela, PX, PY, 0);
  end;

begin
  RelogioParado := 0;
  if (MusicaAtual <> 0) and (SomMusica.Count > 0) then SomMusica.Parar(0);
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  barra(0, 300 - TempoEstado, 200, 600 - TempoEstado, RGB(120, 120, 255));
  barra(200, TempoEstado - 300, 400, TempoEstado, Rosa);
  { bandeiras repetidas ao fundo }
  for I := 0 to 3 do
    for J := 0 to 1 do
    begin
      N := 11;
      if Idioma = 2 then N := 12;
      ImgIcone[N].Draw(Tela, I * 145 - 67, (J * 200 - 200) + (ContagemTick shl 3), 0);
      ImgIcone[N].Draw(Tela, I * 145, (J * 200 - 100) + (ContagemTick shl 3), 0);
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
      if Lutador[J].Ativo = 1 then
      begin
        Ch := Lutador[J].Personagem;
        if J = 1 then X := 52 else X := 252;
        Retrato((Ch - 1) * 5 + 4, X, 25);
        if Lutador[J].Escolheu = 0 then
        begin
          if Ch <= 8 then
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 1) * 49 - 402), 163)
          else
            Retrato((Ch - 1) * 5, Round(TempoEstado * 1.35) + ((Ch - 9) * 49 - 402), 223);
        end;
        if J = 1 then X := 100 else X := 300;
        texto(X, 130 - Round(Cos(ContPisca / 4.3) * 4), Linha(MemoNomes, Ch), ACentro, 12, RGB(180, 220, 160));
      end;
    end;
    N := Round(Cos(ContagemTick / 4) * 20);
    Cor := RGB(N + 230, N + 230, 255);
    texto(200, Round(TempoEstado * 0.3) - 96, Linha(MemoTexto, 8), ACentro, 18, Cor);
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
      if (Lutador[J].Ativo = 1) and (Lutador[J].Escolheu = 0) then
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
    if (Lutador[1].Escolheu = 0) and (Lutador[1].Ativo = 1) then
    begin
      if ((K1 and 4) <> 0) and (Lutador[1].AntEsq = 0) then
      begin
        Dec(Lutador[1].Personagem);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K1 and 8) <> 0) and (Lutador[1].AntDir = 0) then
      begin
        Inc(Lutador[1].Personagem);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K1 and 1) <> 0) and (Lutador[1].AntCima = 0) and (Lutador[1].Personagem > 8) then
      begin
        Dec(Lutador[1].Personagem, 8);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K1 and 2) <> 0) and (Lutador[1].AntBaixo = 0) and (Lutador[1].Personagem <= 8) then
      begin
        Inc(Lutador[1].Personagem, 8);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K1 and 16) <> 0) and (Lutador[1].AntSocoFraco = 0) then
      begin
        Lutador[1].Escolheu := 1;
        criaadversario(1, Lutador[1].Personagem);
        Som(2);
      end;
    end;
    { jogador 2 (joystick emulado) }
    if (Lutador[2].Escolheu = 0) and (Lutador[2].Ativo = 1) then
    begin
      if ((K2 and 4) <> 0) and (Lutador[2].AntEsq = 0) then
      begin
        Dec(Lutador[2].Personagem);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K2 and 8) <> 0) and (Lutador[2].AntDir = 0) then
      begin
        Inc(Lutador[2].Personagem);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K2 and 1) <> 0) and (Lutador[2].AntCima = 0) and (Lutador[2].Personagem > 8) then
      begin
        Dec(Lutador[2].Personagem, 8);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K2 and 2) <> 0) and (Lutador[2].AntBaixo = 0) and (Lutador[2].Personagem <= 8) then
      begin
        Inc(Lutador[2].Personagem, 8);
        if SomEfeitos.Count > 1 then Som(1);
      end;
      if ((K2 and 16) <> 0) and (Lutador[2].AntSocoFraco = 0) then
      begin
        Lutador[2].Escolheu := 1;
        criaadversario(2, Lutador[2].Personagem);
        Som(2);
      end;
    end;
    for J := 1 to 2 do
    begin
      if Lutador[J].Personagem < 1 then Lutador[J].Personagem := 15;
      if Lutador[J].Personagem > 15 then Lutador[J].Personagem := 1;
    end;
    if Lutador[1].Ativo = 0 then Lutador[1].Escolheu := 1;
    if Lutador[2].Ativo = 0 then Lutador[2].Escolheu := 1;
    { tempo esgotado: confirma automaticamente }
    if ContagemSeg = 0 then
    begin
      Lutador[1].Escolheu := 1;
      if Lutador[1].Ativo = 1 then criaadversario(1, Lutador[1].Personagem);
      Lutador[2].Escolheu := 1;
      if Lutador[2].Ativo = 1 then criaadversario(2, Lutador[2].Personagem);
      Som(2);
    end;
    if (Lutador[1].Escolheu = 1) and (Lutador[2].Escolheu = 1) then
    begin
      Estado := CHS_ADVERSARIOS;
      ContPisca := 0;
      TempoEstado := 0;
      Lutador[1].RoundsVencidos := 0;
      Lutador[2].RoundsVencidos := 0;
      RoundAtual := 1;
      if (Lutador[1].Ativo = 1) and (Lutador[2].Ativo = 1) then Estado := CHS_PREPARALUTA;
    end;
  end;
  E1 := 0;
  E2 := 0;
  if E1 = E2 then N := 0;
end;

{ Teclado do estado SELECAO: 1/2 = entrada do jogador }
procedure TJogo.Teclado_Selecao(Tk: Integer);
begin
  if (Estado = CHS_SELECAO) and (Fichas > 0) and (RelogioParado = 0) then
  begin
    if (Tk = Integer(SDL_SCANCODE_1)) and (Lutador[1].Ativo = 0) then
    begin
      Lutador[1].Ativo := 1;
      Lutador[1].Escolheu := 0;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
    if (Tk = Integer(SDL_SCANCODE_2)) and (Lutador[2].Ativo = 0) then
    begin
      Lutador[2].Ativo := 1;
      Lutador[2].Escolheu := 0;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      ContagemSeg := 30;
      ContagemTick := 25;
    end;
  end;
end;
