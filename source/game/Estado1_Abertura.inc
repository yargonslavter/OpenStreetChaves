{ Estado1_Abertura.inc - Estado CHS_ABERTURA: abertura (predio, vila, logo) e modo "attract". }

{ Estado 1: abertura (predio, vila, logo) e modo "attract" }
procedure TJogo.Estado1_Abertura;
var
  Ab: TListaImagens;
  Sup: TSuperficie;
  I, J, L, L14: Integer;
  R: TRect;
  N: Integer;
  //Cor: TColor;
  S: string;
begin
  Ab := ImgAbertura;
  Sup := Tela;
  barra(0, 0, LarguraTela, AlturaTela, Preto);

  if TempoEstado < 100 then
  begin
    barra(0, 0, LarguraTela, AlturaTela, RGB(120, 120, 250));
    Ab.PorNome('Vencedores').Draw(Sup, 110, 10, 0);
    texto(200, 210, Linha(TxtGeral, 13), ACentro, 16, RGB(250, 200, 0));
  end;

  if (TempoEstado >= 100) and (TempoEstado <= 370) then
  begin
    if TempoEstado = 100 then CameraY := 0;
    { ceu em faixas }
    for I := 0 to 20 do
      barra(0, I * 15, 400, I * 15 + 15, RGB(I * 2 + 120, I * 2 + 120, 200));
    { nuvens e folhagens }
    N := Round(CameraY / 2);
    Ab.PorNome('Predio-02-a').Draw(Sup, 50, 50 - N, 0);
    Ab.PorNome('Predio-02-a').Draw(Sup, 350, 150 - N, 0);
    Ab.PorNome('Predio-02-a').Draw(Sup, 300, 180 - N, 0);
    for J := 0 to 4 do
    begin
      Ab.PorNome('Predio-02-b').Draw(Sup, 50, J * 47 + 73 - N, 0);
      Ab.PorNome('Predio-02-b').Draw(Sup, 350, J * 47 + 173 - N, 0);
      Ab.PorNome('Predio-02-b').Draw(Sup, 300, J * 47 + 203 - N, 0);
    end;
    { predio (esquerda e direita) }
    for J := 0 to 6 do
    begin
      Ab.PorNome('Predio-01-a').Draw(Sup, 100, J * 80 - 200 - CameraY, 0);
      Ab.PorNome('Predio-01-a').Draw(Sup, 305, J * 80 - 200 - CameraY, 0);
    end;
    for L := 0 to 4 do
      for J := 0 to 15 do
        Ab.PorNome('Predio-01-b').Draw(Sup, L * 39 + 113, J * 32 - 200 - CameraY, 0);
    barra(147, -155 - CameraY, 270, -48 - CameraY, Preto);
    retangulo(149, -153 - CameraY, 268, -50 - CameraY, Branco);
    for L := 0 to 7 do
      Ab.PorNome('Folhagem').Draw(Sup, L * 50, 220 - CameraY, 0);
    for L := 0 to 8 do
    begin
      L14 := 0;
      if ContPisca < 10 then L14 := 4;
      Ab.PorNome('Pessoa-03').Draw(Sup, L * 50, 245 - CameraY + L14, 0);
      Ab.PorNome('Pessoa-01').Draw(Sup, L * 50 - 15, 245 - CameraY + L14, 0);
      Ab.PorNome('Pessoa-02').Draw(Sup, L * 50 + 15, 245 - CameraY + L14, 0);
    end;
    L14 := 0;
    if ContPisca > 10 then L14 := 5;
    if TempoEstado < 200 then
    begin
      Ab.PorNome('Chaves').Draw(Sup, 210, L14 + 185 - CameraY, 0);
      Ab.PorNome('SeuMadruga').Draw(Sup, 50, L14 + 178 - CameraY, 0);
    end;
    if TempoEstado = 200 then SomEfeitos.Tocar(9);
    if TempoEstado >= 200 then
    begin
      Ab.PorNome('SeuMadrugaCaindo').Draw(Sup, 60 - ((TempoEstado - 200) shl 2),
        (TempoEstado - 200) * 2 + 180 - CameraY, 0);
      Ab.PorNome('ChavesSoco').Draw(Sup, 100, 190 - CameraY, 0);
    end;
  end;

  { logo que se expande: largura/altura do retangulo variam com TempoEstado }
  L := 0;
  if TempoEstado < 400 then L := 4;
  if (TempoEstado >= 400) and (TempoEstado <= 420) then L := TempoEstado - $18C;
  if (TempoEstado >= 420) and (TempoEstado <= 438) then L := 440 - TempoEstado;
  if TempoEstado >= 438 then L := 2;
  L14 := 0;
  if L <> 0 then
  begin
    L14 := Round(223 / L);
    LogoMeiaAltura := Round(117 / L);
  end;
  R := Rect(205 - L14, (-100 - CameraY) - LogoMeiaAltura, L14 + 205, (-100 - CameraY) + LogoMeiaAltura);
  Ab.PorNome('Logo-' + CodigoIdioma(Idioma)).DrawAlpha(Sup, R, 0, 255);

  if TempoEstado > 440 then
    texto(320, 140, Versao, AEsq, 8, Branco);
  if TempoEstado > 440 then
  begin
    S := Linha(TxtGeral, 22);
    if TempoEstado < 500 then
    begin
      if Odd(TempoEstado) then
        texto(200 - ((500 - TempoEstado) shl 2), 170, S, ACentro, 12, AzulTitulo)
      else
        texto(((500 - TempoEstado) shl 2) + 200, 170, S, ACentro, 12, AzulTitulo);
    end;
    if TempoEstado >= 500 then
      texto(200, 170, S, ACentro, 12, AzulTitulo);
    Ab.PorNome('Cybergamba').Draw(Sup, 5, 280, 0);
    texto(200, 253, Linha(TxtGeral, 26), ACentro, 8, Branco);
    texto(200, 267, Linha(TxtGeral, 31), ACentro, 8, Branco);
  end;

  if Fichas > 0 then
  begin
    TempoEstado := 500;
    CameraY := -200;
  end;
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  if TempoEstado < 1000 then Inc(TempoEstado);
  if TempoEstado > 235 then Dec(CameraY, 2);
  if CameraY < -200 then CameraY := -200;

  { fim da abertura: luta de demonstracao com 2 lutadores aleatorios }
  if TempoEstado > 650 then
  begin
    Estado := CHS_LUTA;
    FTick7 := 0;
    TempoDemo := 600;
    RelogioParado := False;
    ContagemSeg := 99;
    ContagemTick := 25;
    FaseIntro := 72;
    FaseFim := 0;
    Lutador[1].Ativo := False;
    Lutador[1].Acao := acParado;
    Lutador[2].Ativo := False;
    Lutador[2].Acao := acParado;
    zerardados(1);
    zerardados(2);
    PausaImpacto := 0;
    FlashTela := 0;
    FlashVermelho := 0;
    TremorTela := 0;
    DeslocHudTopo := -120;
    DeslocHudBase := 60;
    CameraX := 100;
    PrimeiroAtaque := True;
    L := Round(Random(FQtdCenarios * 10) / 10) + 1;
    if L < 1 then L := 1;
    if L > FQtdCenarios then L := FQtdCenarios;
    CenarioAtual := L;
    carregarcenario(CenarioAtual);
    for L := 1 to 2 do
    begin
      I := Round(Random(FQtdLutadores * 10) / 10) + 1;
      if I < 1 then I := 1;
      if I > FQtdLutadores then I := FQtdLutadores;
      Lutador[L].Personagem := I;
      carregarlutador(ArquivoNN(FPadraoLutador, I), I, L);
    end;
  end;

  if (ContPisca < 12) and (Fichas = 0) then
    texto(200, 235, Linha(TxtGeral, 6), ACentro, 10, Branco);
  if (ContPisca < 12) and (Fichas > 0) then
    texto(200, 235, Linha(TxtGeral, 7), ACentro, 10, Branco);
  //Cor := 0;
  //if Cor = 1 then Y0 := 0;
end;

{ Teclado do estado ABERTURA: F1 = configuracoes, F2 = teclas, 1/2 = ficha do jogador (chamado por FormKeyDown) }
procedure TJogo.Teclado_Abertura(Key, Tk: Integer);
begin
  if Key = Integer(SDL_SCANCODE_F1) then
  begin
    Estado := CHS_CONFIG;
    CursorMenu := 1;
    SomPendente := 1;
    MusicaAtual := 1;
  end;
  if Key = Integer(SDL_SCANCODE_F2) then
  begin
    Estado := CHS_TECLAS;
    CursorMenu := 1;
  end;
  if (Estado = CHS_ABERTURA) and (Fichas > 0) then
  begin
    if (Tk = Integer(SDL_SCANCODE_1)) and not Lutador[1].Ativo then
    begin
      Lutador[1].Ativo := True;
      Lutador[1].Escolheu := False;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Lutador[1].Personagem := pnChaves;
      Dec(Fichas);
      Estado := CHS_SELECAO;
      FaseSelecao := 1;
      Fase := 1;
      if CheatGentalha then Fase := 8;
      ContagemSeg := 30;
      ContagemTick := 25;
      TempoEstado := 0;
    end;
    if (Tk = Integer(SDL_SCANCODE_2)) and not Lutador[2].Ativo then
    begin
      Lutador[2].Ativo := True;
      Lutador[2].Escolheu := False;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Lutador[2].Personagem := pnSeuMadruga;
      Dec(Fichas);
      Estado := CHS_SELECAO;
      FaseSelecao := 1;
      Fase := 1;
      if CheatGentalha then Fase := 8;
      ContagemSeg := 30;
      ContagemTick := 25;
      TempoEstado := 0;
    end;
  end;
end;
