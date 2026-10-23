{ Estado5_Adversarios.inc - Estado CHS_ADVERSARIOS: ordem dos adversarios e cenario do proximo combate. }

{ Estado 5: mostra a ordem dos adversarios e o cenario do proximo combate }
procedure TJogo.Estado5_Adversarios;
const
  CenPrimeiro: array[1..15] of Byte = (1, 2, 2, 3, 3, 4, 11, 1, 1, 11, 6, 1, 1, 2, 1);
  CenAlt: array[1..15] of Byte = (0, 7, 10, 10, 8, 8, 5, 9, 10, 10, 5, 9, 5, 1, 6);
var
  C, J, K, Ch, X, Y, N: Integer;
  K1, K2: Byte;

  procedure Retrato(Indice, PX, PY: Integer);
  begin
    if Indice < ImgRetrato.Count then
      ImgRetrato[Indice].Draw(Tela, PX, PY, 0);
  end;

begin
  for C := 0 to 60 do
    barra(0, C * 10, 400, C * 10 + 10, RGB(C * 2 + 10, C * 3 + 20, C * 4 + 30));
  if Fase < 1 then Fase := 1;
  if Fase > 8 then Fase := 8;
  if (MusicaAtual <> 0) and (SomMusica.Count > 0) then SomMusica.Parar(0);
  for J := 1 to 2 do
  begin
    Lutador[J].RoundsVencidos := 0;
    Lutador[J].CargaPoder := 0;
    Lutador[J].Poder := 0;
    Lutador[J].MaxAcertos := 0;
  end;

  for J := 1 to 2 do
    if Lutador[J].Ativo = 1 then
    begin
      Lutador[J].Escolheu := 1;
      Ch := TempoEstado;
      if Ch < 30 then
        texto(200 - (Ch - 30) * 20, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      if (Ch >= 30) and (Ch <= 100) then
        texto(200, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      if Ch > 100 then
        texto(200 - (Ch - 100) * 20, 135, Linha(MemoTexto, 20), ACentro, 26, VerdeAnuncio);
      { o oponente da rodada atual vai para o outro lutador }
      Lutador[3 - J].Personagem := Lutador[J].Adversarios[Fase];
      if TempoEstado > 40 then
        texto(200, 180, Linha(MemoNomes, Lutador[3 - J].Personagem), ACentro, 15, Branco);
      for K := 1 to 8 do
      begin
        Ch := Lutador[J].Adversarios[K];
        N := 470 - TempoEstado * 5;
        Y := 220;
        if TempoEstado < 50 then Y := N;
        X := 48 * K - 40;
        if (Ch * 5 - 4 < ImgRetrato.Count) and (Fase >= K) then
          Retrato(Ch * 5 - 5 + 1, X, Y);
        if (Ch * 5 - 4 < ImgRetrato.Count) and (Fase > K) then
        begin
          if TempoEstado < 50 then
            ImgIcone[10].Draw(Tela, 48 * K - 35, 485 - TempoEstado * 5, 0)
          else
            ImgIcone[10].Draw(Tela, 48 * K - 35, 235, 0);
        end;
        if CheatChurros = 0 then
        begin
          if Fase < K then ImgIcone[9].Draw(Tela, X, Y, 0);
        end
        else if Fase < K then
          Retrato(Ch * 5 - 5 + 1, X, Y);
      end;
    end;

  if (TempoEstado >= 50) and (ContPisca <= 10) then
    ImgIcone[8].Draw(Tela, Fase * 48 - 20, 215, 0);
  if (TempoEstado > 60) and (ImgCenario.Count > 0) then
  begin
    ImgCenario[0].StretchDraw(Tela, Rect(80, 6, 320, 134), 0);
    texto(200, 115, Linha(MemoCenarios, CenarioAtual - 1), ACentro, 9, Branco);
  end;

  { no primeiro quadro: escolhe e carrega o cenario do adversario }
  if TempoEstado = 0 then
    for J := 1 to 2 do
      if Lutador[J].Ativo = 0 then
      begin
        Ch := Lutador[J].Personagem;
        if (Ch >= 1) and (Ch <= 15) then
        begin
          CenarioAtual := CenPrimeiro[Ch];
          if (Random(5) <= 1) and (Fase < 8) and (CenAlt[Ch] <> 0) then CenarioAtual := CenAlt[Ch];
          if (Random(6) <= 1) and (Fase < 8) and (Ch in [3, 4, 9, 10, 11, 14]) then CenarioAtual := 12;
          if (CenarioSecreto <> 0) and (Fase < 8) then
          begin
            if CenarioSecreto < 1 then CenarioSecreto := 1;
            if CenarioSecreto > 12 then CenarioSecreto := 12;
            CenarioAtual := CenarioSecreto;
          end;
          carregarcenario(NomeNN('Cenarios/Cenario-', '.bmp', CenarioAtual));
        end;
      end;

  Inc(ContPisca);
  if ContPisca > 15 then ContPisca := 0;
  if TempoEstado < 1000 then Inc(TempoEstado);
  K1 := TecP1;
  K2 := TecP2;
  if ((((K1 and 16) <> 0) and (Lutador[1].Ativo = 1)) or (((K2 and 16) <> 0) and (Lutador[2].Ativo = 1))) and
     (TempoEstado > 0) then
    Inc(TempoEstado, 5);
  if TempoEstado > 120 then
  begin
    for C := 0 to 15 do
      barra(0, C * 20, 400, C * 20 + (TempoEstado - 120), Preto);
    if TempoEstado > 150 then Estado := CHS_PREPARALUTA;
  end;
  if CheatFadiga = 1 then
  begin
    Estado := CHS_FINAL;
    ContPisca := 0;
    TempoEstado := 0;
  end;
end;
