{ Estado9_Continuar.inc - Estado CHS_CONTINUAR: "continuar?" com contagem regressiva. }

procedure TJogo.Estado9_Continuar;
var
  L: Integer;
  Cor: TColor;
begin
  for L := 0 to 60 do
    barra(0, L * 5, LarguraTela, L * 5 + 5, RGB(L * 3 + 10, L * 3 + 50, L * 3 + 30));
  if (ContagemSeg > 0) or (ContagemTick > 0) then
  begin
    texto(200, 20, Linha(MemoTexto, 24), ACentro, 35, RGB(255, 120, 120));
    Cor := RGB(255, ContagemSeg * 25, ContagemSeg * 25);
    if ContagemSeg > 3 then texto(320, 70, IntToStr(ContagemSeg), ACentro, 120, Cor);
    if (ContagemSeg <= 3) and (ContPisca < 8) then texto(320, 70, IntToStr(ContagemSeg), ACentro, 120, Cor);
    Inc(ContPisca);
    if ContPisca > 10 then ContPisca := 0;
  end;
  if ContagemTick > 0 then Dec(ContagemTick);
  if (ContagemTick = 0) and (ContagemSeg > 0) then
  begin
    Dec(ContagemSeg);
    ContagemTick := 25;
  end;
  if (ContagemSeg = 0) and (ContagemTick = 0) then
  begin
    // fim de jogo
    texto(200, 110, Linha(MemoTexto, 23), ACentro, 36, Vermelho);
    if ContPisca < 15 then barra(0, ContPisca * 10, LarguraTela, AlturaTela - ContPisca * 10, Branco);
    Inc(ContPisca);
    if ContPisca > 150 then
    begin
      Estado := CHS_RECORDES;
      CameraY := 0;
      ContPisca := 0;
      TempoEstado := 0;
      Lutador[1].Ativo := False;
      Lutador[2].Ativo := False;
    end;
  end;
end;

{ Teclado do estado CONTINUAR: 1/2 = continua com o jogador }
procedure TJogo.Teclado_Continuar(Tk: Integer);
begin
  if (Estado = CHS_CONTINUAR) and (Fichas > 0) and (ContagemSeg > 0) and (ContagemTick > 0) then
  begin
    if (Tk = Integer(SDL_SCANCODE_1)) and not Lutador[1].Ativo then
    begin
      Lutador[1].Ativo := True;
      Lutador[1].Escolheu := False;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      if Lutador[1].Adversarios[1] = 0 then Estado := CHS_SELECAO else Estado := CHS_ADVERSARIOS;
      ContagemSeg := 30;
      ContagemTick := 25;
      ContPisca := 0;
      TempoEstado := 0;
    end;
    if (Tk = Integer(SDL_SCANCODE_2)) and not Lutador[2].Ativo then
    begin
      Lutador[2].Ativo := True;
      Lutador[2].Escolheu := False;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      if Lutador[2].Adversarios[1] = 0 then Estado := CHS_SELECAO else Estado := CHS_ADVERSARIOS;
      ContagemSeg := 30;
      ContagemTick := 25;
      ContPisca := 0;
      TempoEstado := 0;
    end;
  end;
end;
