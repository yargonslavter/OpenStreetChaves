{ Estado7_Luta.inc - Estado CHS_LUTA: desenho, HUD, fisica e fluxo da luta (L7_*). As rotinas de golpe estao em Estado7_Golpes.inc. }

{ Escreve o nome do golpe e, em seguida, os icones (e textos) da sequencia de teclas. }
procedure TJogo.mostrasequencia(X, Y: Integer; const Nome, Seq: string);
var
  I, DX: Integer;
  Cor: TColor;
  C: Char;
begin
  Cor := Branco;
  if (Nome <> '') and (Nome[1] = '*') then Cor := RGB(255, 120, 120);
  texto(X, Y, Nome + ' - ', AEsq, 9, Cor);
  DX := Tela.LarguraTexto(Nome + ' - ', 9);
  for I := 1 to Length(Seq) do
  begin
    C := Seq[I];
    case C of
      'C': ImgIcone.PorNome('Cima').Draw(Tela, X + DX, Y + 3, 0);
      'B': ImgIcone.PorNome('Baixo').Draw(Tela, X + DX, Y + 3, 0);
      'D': ImgIcone.PorNome('Direita').Draw(Tela, X + DX, Y + 3, 0);
      'E': ImgIcone.PorNome('Esquerda').Draw(Tela, X + DX, Y + 3, 0);
      'Y': ImgIcone.PorNome('Diagonal1').Draw(Tela, X + DX, Y + 3, 0);
      'Z': ImgIcone.PorNome('Diagonal2').Draw(Tela, X + DX, Y + 3, 0);
      'P': texto(X + DX, Y, TextoInterface('GolpeSoco'), AEsq, 9, Branco);
      'K': texto(X + DX, Y, TextoInterface('GolpeChute'), AEsq, 9, Branco);
      'R': texto(X + DX, Y, TextoInterface('GolpeRapido'), AEsq, 9, Branco);
      '?': texto(X + DX, Y, TextoInterface('GolpeSocoOuChute'), AEsq, 9, Branco);
    end;
    Inc(DX, 12);
  end;
end;

{ Modo passo a passo: mostra, para cada jogador, os golpes do personagem escolhido. }
procedure TJogo.mostragolpe;
var
  J, K, X, Y: Integer;
  Pers: Byte;
begin
  Y := 120;
  for J := 1 to 2 do
  begin
    X := (J - 1) * 200;
    barra(X + 3, Y - 5, X + 197, Y + 80, RGB(20, 40, 60));
    retangulo(X + 3, Y - 5, X + 197, Y + 80, Branco);
    Pers := Lutador[J].Personagem;
    if (Pers >= 1) and (Pers <= FQtdLutadores) then
      for K := 1 to High(FLutadores[Pers].Golpes) do
        mostrasequencia(X + 6, Y + (K - 1) * 15, FLutadores[Pers].Golpes[K].N, FLutadores[Pers].Golpes[K].S);
  end;
end;

{ Posicionamento inicial do round 1: os lutadores entram pulando pelos lados. }
procedure TJogo.L7_Prepara;
var
  I: Integer;
begin
  ChaoY := 300;
  if (RoundAtual = 1) and (FaseIntro = 0) then
  begin
    Lutador[1].X := 0;
    Lutador[1].DirPulo := puloDireita;
    Lutador[2].X := 600;
    Lutador[2].DirPulo := puloEsquerda;
    for I := 1 to 2 do
    begin
      Lutador[I].Y := ChaoY;
      Lutador[I].NoAr := True;
      Lutador[I].VelY := -25;
      Lutador[I].Quadro := 21;
      Lutador[I].Acao := acPulo;
      Lutador[I].QuadroAcao := 0;
      Lutador[I].DuracaoAcao := 99;
    end;
    RelogioParado := True;
    CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  end;
  // chefe (fase 8): dialogo antes da luta quando ha um computador
  if (Fase = 8) and (RoundAtual = 1) and (FaseIntro = 1) and
     (not Lutador[1].Ativo or not Lutador[2].Ativo) then
  begin
    TempoDialogo := 600;
    FaseIntro := 2;
    DeslocHudTopo := -120;
    DeslocHudBase := 60;
  end;
  if TempoDialogo > 0 then Dec(TempoDialogo);
end;

{ Toca musica/som pendentes, pisca a tela, move a camera e desenha o cenario. }
procedure TJogo.L7_CenarioECamera;
var
  Sup: TSuperficie;
  Desloc, C, L: Integer;
begin
  Sup := Tela;
  if (MusicaAtual <> 0) and MusicaPendente and (SomMusica.Count > 0) then
  begin
    SomMusica.Tocar(0);
    MusicaPendente := False;
  end;
  if SomPendente <> 0 then
    if SomEfeitos.Count > SomPendente then
    begin
      SomEfeitos.Tocar(SomPendente);
      SomPendente := 0;
    end;

  if FlashTela > 0 then
  begin
    Dec(FlashTela);
    Desloc := 0;
    if FlashTela mod 2 = 0 then Desloc := 20;
    if FlashTela mod 3 = 0 then Desloc := 40;
    if FlashTela mod 4 = 0 then Desloc := 60;
    if FlashTela mod 5 = 0 then Desloc := 80;
    for C := 0 to 5 do
      for L := 0 to 4 do
        ImgIcone.PorNome('Especial').Draw(Sup, C * 100 - 80 + Desloc, L * 100, 0);
  end;

  if not RelogioParado then
  begin
    CameraX := Round((Lutador[1].X + Lutador[2].X) / 2) - 200;
    CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  end;
  if TremorTela > 0 then
  begin
    Dec(TremorTela);
    CameraX := Random(20) + (CameraX - 10);
    CameraY := Random(20) + (CameraY - 10);
  end;
  if CameraX < 0 then CameraX := 0;
  if CameraX > FCameraXMax then CameraX := FCameraXMax;
  if CameraY < 0 then CameraY := 0;
  if CameraY > FCameraYMax then CameraY := FCameraYMax;

  if FlashTela = 0 then
  begin
    if (ImgCenario.Count > 0) and (ImgCenario[0].Surface <> nil) then
    begin
      ImgCenario[0].Draw(Sup, -CameraX, -CameraY, 0);
      desenhaanimacoes;
    end
    else
      barra(0, 0, LarguraTela, AlturaTela, Preto);
  end;
end;

{ Cabecalho: "FASE n", relogio redondo e contagem regressiva do round. }
procedure TJogo.L7_Relogio;
var
  T: Integer;
  Cor: TColor;
begin
  T := DeslocHudTopo;
  texto(200, T + 3, Linha(TxtGeral, 29) + ' ' + IntToStr(Fase), ACentro, 7, Branco);
  barraredonda(170, T + 15, 230, T + 54, 15, Branco, Branco);
  barraredonda(172, T + 17, 228, T + 52, 15, CinzaClaro, CinzaClaro);
  barraredonda(174, T + 19, 226, T + 50, 15, Preto, Preto);
  if TempoRound <> 4 then
  begin
    Cor := VermelhoAlerta;
    if ContagemTick <= 2 then Cor := RosaPalido;
    if ContagemSeg >= 10 then texto(200, T + 10, IntToStr(ContagemSeg), ACentro, 25, Cor);
    if ContagemSeg < 10 then texto(200, T + 10, '0' + IntToStr(ContagemSeg), ACentro, 25, Cor);
    if (ContagemSeg < 10) and (ContagemTick mod 2 = 0) then
      texto(200, T + 10, '0' + IntToStr(ContagemSeg), ACentro, 25, RosaPalido);
    if (FlashTela = 0) and (PausaImpacto = 0) and not RelogioParado then Dec(ContagemTick);
    if ContagemTick = 0 then
    begin
      ContagemTick := 25;
      if ContagemSeg > 0 then Dec(ContagemSeg);
    end;
  end;
end;

{ Barra de energia, retrato, nome, rounds ganhos e placar do lutador Jog (parte de cima). }
procedure TJogo.L7_HudCima(Jog: Byte);
var
  P: PLutador;
  T, Mult, I, X0, X1: Integer;
  Cor: TColor;
begin
  P := @Lutador[Jog];
  T := DeslocHudTopo;
  if (Lutador[1].Vida > 0) and (Lutador[2].Vida > 0) then P.Vida := P.Vida + BonusEnergeticos;
  if TempoDemo > 0 then
  begin
    P.Vida := VidaMax;
    P.Poder := 3;
  end;
  if P.Vida < 0 then P.Vida := 0;
  if P.Vida > VidaMax then P.Vida := VidaMax;

  if Jog = 1 then Mult := -1 else Mult := 1;
  Tmp4494 := Round(Cos(ContPisca / 4.75) * 30);
  if Jog = 1 then Cor := RGB(Tmp4494 + 50, Tmp4494 + 50, 255)
  else Cor := RGB(255, Tmp4494 + 30, Tmp4494 + 30);
  barra(Mult * 198 + 200, T + 40, Mult * 130 + 200, T + 68, Cor);
  retangulo(Mult * 198 + 200, T + 40, Mult * 130 + 200, T + 68, Branco);
  barraredonda(Mult * 157 + 200, T + 30, 17 * Mult + 200, T + 50, 8, Preto, Branco);
  barraredonda(Mult * 155 + 200, T + 32, Mult * 19 + 200, T + 48, 8, CinzaClaro, CinzaClaro);
  barraredonda(Mult * 153 + 200, T + 34, Mult * 21 + 200, T + 46, 8, Preto, Preto);
  if (P.Vida <= 15) and (ContPisca mod 2 = 0) then
    barraredonda(Mult * 153 + 200, T + 34, Mult * 21 + 200, T + 46, 8, Preto, RGB(200, 0, 0));

  // retrato (treme quando a barra vermelha esta descendo)
  Tmp4494 := 0;
  if (P.VidaBarra > P.Vida) and (ContPisca mod 2 = 0) then Tmp4494 := -1;
  if (P.VidaBarra > P.Vida) and (ContPisca mod 2 <> 0) then Tmp4494 := 1;
  I := (P.Personagem - 1) * 5;
  if Jog = 1 then
  begin
    if (Tmp4494 = 0) and (ImgRetrato.Count > I) then
      ImgRetrato[I].Draw(Tela, 3 - Tmp4494, T + 7, 0);
    if (Tmp4494 <> 0) and (ImgRetrato.Count > I + 2) then
      ImgRetrato[I + 2].Draw(Tela, 3 - Tmp4494, T + 7, 0);
  end
  else
  begin
    if (Tmp4494 = 0) and (ImgRetrato.Count > I + 1) then
      ImgRetrato[I + 1].Draw(Tela, 347 - Tmp4494, T + 7, 0);
    if (Tmp4494 <> 0) and (ImgRetrato.Count > I + 3) then
      ImgRetrato[I + 3].Draw(Tela, 347 - Tmp4494, T + 7, 0);
  end;

  // marcas da barra
  for I := 0 to 6 do
  begin
    if P.Vida > 15 then
      retangulo((I * 16 + 40) * Mult + 200, T + 35, (I * 16 + 40) * Mult + 200, T + 45, RGB(80, 80, 80));
    if P.Vida <= 15 then
      retangulo((I * 16 + 40) * Mult + 200, T + 35, (I * 16 + 40) * Mult + 200, T + 45, RGB(150, 30, 30));
  end;

  // barra vermelha (dano recente) e barra amarela (energia)
  if P.VidaBarra > VidaMax then P.VidaBarra := VidaMax;
  X0 := Round((25 + P.VidaBarra) * Mult) + 200;
  X1 := 25 * Mult + 200;
  barra(X0, T + 35, X1, T + 45, RGB(170, 0, 0));
  if (FlashTela = 0) and (PausaImpacto = 0) and (P.AtrasoBarra = 0) then
  begin
    if P.VidaBarra > P.Vida then
    begin
      P.VidaBarra := P.VidaBarra - 3;
      if P.VidaBarra < P.Vida then P.VidaBarra := P.Vida;
    end
    else
      P.VidaBarra := P.Vida;
  end;
  if P.AtrasoBarra > 0 then P.AtrasoBarra := P.AtrasoBarra - 1;
  if P.Vida > VidaMax then P.Vida := VidaMax;
  if P.Vida < 0 then P.Vida := 0;
  X0 := Round((25 + P.Vida) * Mult) + 200;
  barra(X0, T + 35, X1, T + 45, RGB(150, 150, 0));
  barra(X0, T + 36, X1, T + 44, RGB(220, 220, 70));
  barra(X0, T + 38, X1, T + 42, RGB(250, 250, 100));
  barra(X0, T + 39, X1, T + 40, Branco);

  // rounds ganhos
  Tmp4494 := Round(Cos(ContPisca / 2.735) * 60);
  for I := 1 to NumRounds do
  begin
    barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
      Branco, Preto);
    if P.RoundsVencidos >= I then
    begin
      barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
        Branco, RGB(160 - Tmp4494, 0, 0));
      if ContPisca < 10 then
        barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
          Branco, Vermelho);
    end;
  end;

  // jogador ausente: convite para entrar
  if not P.Ativo and (TempoDemo = 0) then
  begin
    if (ContPisca < 15) and (Fichas = 0) then
      texto(Mult * 100 + 200, 0, Linha(TxtGeral, 6), ACentro, 10, Branco);
    if (ContPisca < 15) and (Fichas > 0) and not RelogioParado then
      texto(Mult * 100 + 200, 0, Linha(TxtGeral, 7), ACentro, 10, Branco);
  end;

  if Jog = 1 then
    texto(Mult * 145 + 200, T + 45, Linha(TxtNomes, P.Personagem), AEsq, 12, RGB(120, 120, 255))
  else
    texto(Mult * 145 + 200, T + 45, Linha(TxtNomes, P.Personagem), ADir, 12, RGB(255, 110, 110));

  if P.Ativo then
  begin
    Tmp4494 := Round(Cos(ContPisca / 4.75) * 20);
    if Jog = 1 then
    begin
      texto(Mult * 145 + 200, T + 10, '1P', AEsq, 12, RGB(Tmp4494 + 120, Tmp4494 + 120, 255));
      texto(Mult * 50 + 200, T + 10, IntToStr(P.Pontos), ADir, 12, RGB(Tmp4494 + 120, Tmp4494 + 120, 255));
    end
    else
    begin
      texto(Mult * 145 + 200, T + 10, '2P', ADir, 12, RGB(255, Tmp4494 + 110, Tmp4494 + 110));
      texto(Mult * 50 + 200, T + 10, IntToStr(P.Pontos), AEsq, 12, RGB(255, Tmp4494 + 110, Tmp4494 + 110));
    end;
  end;
end;

{ Comandos do jogador humano Jog (K = teclas: 1 cima, 2 baixo, 4 esquerda, 8 direita, 16..128 botoes 1..4). }
procedure TJogo.L7_Entrada(Jog, K: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if (K and 2) = 0 then
  begin
    if (K and 4) <> 0 then AcaoJogador(Jog, cmEsquerda);
    if (K and 8) <> 0 then AcaoJogador(Jog, cmDireita);
  end;
  if (K and 2) <> 0 then AcaoJogador(Jog, cmAgachar);
  if ((K and 2) = 0) and (P.Acao = acAgachado) then P.Acao := acParado;

  // pulo
  if ((K and 1) <> 0) and ((P.Acao = acParado) or (P.Acao = acAndando) or (P.Acao = acDefesa) or (P.Acao = acDefesaBaixa)) and
     (P.VelY = 0) and not P.NoAr then
  begin
    P.VelY := -32;
    P.NoAr := True;
    P.Acao := acPulo;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 99;
    P.Defendendo := False;
    P.DirPulo := puloReto;
    if (K and 4) <> 0 then P.DirPulo := puloEsquerda;
    if (K and 8) <> 0 then P.DirPulo := puloDireita;
  end;
  if ((K and 4) = 0) and ((K and 8) = 0) and (P.Acao = acAndando) then
  begin
    P.Acao := acParado;
    P.QuadroAcao := 0;
  end;

  // golpes especiais (sequencias) e golpes normais
  if ((K and 16) <> 0) and not P.AntSocoFraco then golpe(Jog, 1);
  if ((K and 32) <> 0) and not P.AntChuteFraco then golpe(Jog, 2);
  if ((K and 64) <> 0) and not P.AntSocoForte then golpe(Jog, 3);
  if ((K and 128) <> 0) and not P.AntChuteForte then golpe(Jog, 4);
  if ((K and 16) <> 0) and not P.AntSocoFraco then AcaoJogador(Jog, cmSocoFraco);
  if ((K and 32) <> 0) and not P.AntChuteFraco then AcaoJogador(Jog, cmChuteFraco);
  if ((K and 64) <> 0) and not P.AntSocoForte then AcaoJogador(Jog, cmSocoForte);
  if ((K and 128) <> 0) and not P.AntChuteForte then AcaoJogador(Jog, cmChuteForte);
end;

{ Passaro/aviao que cruza o cenario e solta objetos. }
procedure TJogo.L7_Voador;
var
  Sup: TSuperficie;
begin
  Sup := Tela;
  if ((FVoadorModo = 1) or ((FVoadorModo = 2) and not RelogioParado)) and not Voador.Ativo and
     (CameraX > 40) and (CameraX < 160) and (Random(Voador.Alcance) = 0) then
  begin
    Voador.X := CameraX - 80;
    Voador.Y := FVoadorY;
    Voador.Vel := 7;
    Voador.Tipo := Random(2) + 1;
    Voador.Ativo := True;
  end;
  if Voador.Ativo then
  begin
    ImgEfeitos.PorNome('Sombra').Draw(Sup, Voador.X + 10 - CameraX, Voador.Y + 132 - CameraY, 0);
    ImgEfeitos.PorNome('Voador').Draw(Sup, Voador.X - CameraX, Voador.Y - CameraY, 0);
    if (FlashTela = 0) and (PausaImpacto = 0) then Voador.X := Voador.X + Voador.Vel;
    if Voador.X > CameraX + 420 then Voador.Ativo := False;
    if (Voador.Tipo <> 0) and (Voador.X > CameraX + 150) and (Voador.X < CameraX + 250) and
       (Random(5) = 0) and (FlashTela = 0) and (PausaImpacto = 0) and not RelogioParado then
    begin
      if Voador.Tipo = 1 then CriaEfeito(3, '', 0, Voador.X + 13, Voador.Y - 5);
      if Voador.Tipo = 2 then CriaEfeito(4, '', 0, Voador.X + 13, Voador.Y - 5);
      Voador.Tipo := 0;
    end;
  end;
end;

{ Item bonus do cenario: desenha e coleta quando um lutador cai sobre ele (acao 19). }
procedure TJogo.L7_ItemBonus;
var
  Jog, K: Integer;
  P: PLutador;
  RX, RY: Integer;
begin
  if (ItemBonus.Icone <> 0) and (FlashTela = 0) and (ItemBonus.Icone < ImgIcone.Count) then
    ImgIcone[ItemBonus.Icone].Draw(Tela, ItemBonus.X - CameraX, ItemBonus.Y - CameraY, 0);
  for Jog := 1 to 2 do
  begin
    P := @Lutador[Jog];
    AlvoX1 := Round(P.X) + P.CorpoX1;
    AlvoY1 := (Round(P.Y) - P.AlturaSprite) + P.CorpoY1;
    AlvoX2 := Round(P.X) + P.CorpoX2;
    AlvoY2 := (Round(P.Y) - P.AlturaSprite) + P.CorpoY2;
    if (P.Acao = acDerrubado) and
       (ItemBonus.X + ItemBonus.Dx2 >= AlvoX1) and (ItemBonus.Y + ItemBonus.Dy2 >= AlvoY1) and
       (ItemBonus.X + ItemBonus.Dx1 <= AlvoX2) and (ItemBonus.Y + ItemBonus.Dy1 <= AlvoY2) and
       (ItemBonus.Icone <> 0) then
    begin
      ItemBonus.Icone := 0;
      SomPendente := sndAcertoEspecial;
      for K := 1 to 30 do
      begin
        RX := Random(40);
        RY := Random(20);
        CriaEfeito(21, '', 0, RX + (ItemBonus.X + 20), RY + (ItemBonus.Y + 20));
      end;
    end;
  end;
end;

{ Mensagens de bonus/combo, indicador de poder (estoques e carga) de baixo. }
procedure TJogo.L7_HudBaixo(Jog: Byte);
var
  P: PLutador;
  B, Mult, I, X0: Integer;
begin
  P := @Lutador[Jog];
  B := DeslocHudBase;
  if Jog = 1 then Mult := -1 else Mult := 1;

  if P.TempoMsgBonus > 0 then
  begin
    texto(Mult * 100 + 200, 80, Linha(TxtGeral, P.MsgBonus), ACentro, 15, VerdeBonus);
    if (P.MsgBonus = 1) and P.Ativo then
      texto(Mult * 80 + 200, 110, Linha(TxtGeral, 2), ACentro, 10, Branco);
    Dec(P.TempoMsgBonus);
  end;

  if P.TempoAcertos > 0 then
  begin
    if P.Acertos > P.MaxAcertos then P.MaxAcertos := P.Acertos;
    if P.Acertos > 1 then
    begin
      if P.TempoAcertos > 15 then
        texto(Random(10) + 195 + Mult * 170, 110, IntToStr(P.Acertos), ACentro, 25, Branco)
      else
        texto(Mult * 170 + 200, 110, IntToStr(P.Acertos), ACentro, 25, Branco);
      texto(Mult * 150 + 200, 145, Linha(TxtGeral, 3), ACentro, 12, VerdeBonus);
    end;
    if (FlashTela = 0) and (PausaImpacto = 0) then Dec(P.TempoAcertos);
    if P.TempoAcertos = 0 then P.Acertos := 0;
  end;

  // estoques de poder (bolinhas) e numero
  barraredonda(Mult * 65 + 200, B + 280, Mult * 22 + 200, B + 288, 6, Branco, RGB(10, 20, 30));
  Tmp4494 := 0;
  if (ContPisca mod 2 = 0) and (P.Poder > 0) then Tmp4494 := 100;
  for I := 1 to P.Poder do
    circulopintado((10 * (I - 1) + 30) * Mult + 200, B + 286, (10 * (I - 1) + 35) * Mult + 200, B + 281,
      RGB(255, 20, 20), RGB(255, Tmp4494 + 150, Tmp4494 + 150));
  Tmp4494 := 0;
  if (ContPisca mod 2 = 0) and (P.Poder > 0) then Tmp4494 := 50;
  texto(18 * Mult + 200, B + 270, IntToStr(P.Poder), ACentro, 12, RGB(255 - Tmp4494, 255 - Tmp4494, 255));

  if (ModoPoder = 2) or (ModoPoder = 4) then Lutador[1].Poder := 3;
  if (ModoPoder = 3) or (ModoPoder = 4) then Lutador[2].Poder := 3;
  if (P.CargaPoder >= CargaMax) and (P.Poder < 3) then
  begin
    P.CargaPoder := 0;
    P.Poder := P.Poder + 1;
    SomPendente := sndPoder;
  end;
  if P.Poder >= 3 then
  begin
    P.CargaPoder := CargaMax;
    P.Poder := 3;
  end;

  // barra de carga do proximo poder
  barraredonda(Mult * 170 + 200, B + 275, Mult * 60 + 200, B + 285, 5, Branco, Branco);
  barraredonda(Mult * 169 + 200, B + 276, Mult * 61 + 200, B + 284, 5, CinzaClaro, CinzaClaro);
  barraredonda(Mult * 168 + 200, B + 277, Mult * 62 + 200, B + 283, 5, Preto, RGB(60, 30, 0));
  X0 := Round((64 + P.CargaPoder) * Mult) + 200;
  if P.CargaPoder < CargaMax then
  begin
    barra(X0, B + 278, Mult * 64 + 200, B + 282, RGB(210, 160, 30));
    barra(X0, B + 279, Mult * 64 + 200, B + 281, RGB(250, 220, 140));
  end;
  if P.CargaPoder = CargaMax then
  begin
    Tmp4494 := 0;
    if ContPisca mod 2 = 0 then Tmp4494 := 50;
    barra(X0, B + 278, Mult * 64 + 200, B + 282, RGB(240, Tmp4494 + 190, Tmp4494 + 60));
    barra(X0, B + 279, Mult * 64 + 200, B + 281, RGB(255, 250, Tmp4494 + 170));
    // (no original a cor do texto usa o contador do laco das bolinhas: Poder + 1 = 4)
    if ContPisca mod 2 = 0 then
      texto(Round(Mult * 115) + 200, B + 262, Linha(TxtGeral, 4), ACentro, 15, RGB(4 + 140, 4 + 140, 255))
    else
      texto(Round(Mult * 115) + 200, B + 262, Linha(TxtGeral, 4), ACentro, 15, RGB(4 + 170, 4 + 170, 255));
  end;
end;

{ Tempo esgotado: o de menor energia perde; empate perde os dois ("DRAW GAME"). }
procedure TJogo.L7_TempoEsgotado;
var
  Pisca: Integer;
begin
  if ContagemSeg <> 0 then Exit;
  if FaseFim < 30 then
  begin
    FaseFim := 30;
    SomPendente := sndTempoEsgotado;
  end;
  Pisca := 0;
  if ContPisca mod 2 = 0 then Pisca := 80;
  if FaseFim < 80 then
    texto(200, 40, Linha(TxtGeral, 27), ACentro, 28, RGB(255, Pisca, Pisca));
  if DeslocHudTopo > -120 then DeslocHudTopo := DeslocHudTopo - 10;
  if DeslocHudBase < 490 then DeslocHudBase := DeslocHudBase + 10;
  RelogioParado := True;
  if Lutador[1].Vida < Lutador[2].Vida then Lutador[1].Vida := 0;
  if Lutador[2].Vida < Lutador[1].Vida then Lutador[2].Vida := 0;
  if Lutador[1].Vida = Lutador[2].Vida then
  begin
    Lutador[1].Vida := 0;
    Lutador[2].Vida := 0;
    if FaseFim < 90 then
      texto(200, 120, Linha(TxtGeral, 28), ACentro, 29, RGB(255, Pisca + Pisca, Pisca + Pisca));
  end;
end;

{ Abertura do round: barras enchendo, "ROUND n", "FIGHT!". }
procedure TJogo.L7_IntroRound;
var
  Pisca: Integer;
begin
  if (FaseIntro > 70) or (TempoDialogo <> 0) then Exit;
  Inc(FaseIntro);
  if FaseIntro < 10 then RelogioParado := True;
  DeslocHudTopo := 0;
  DeslocHudBase := 0;
  if FaseIntro < 5 then
  begin
    Lutador[1].Vida := 1;
    Lutador[1].VidaBarra := 1;
    Lutador[2].Vida := 1;
    Lutador[2].VidaBarra := 1;
  end;
  if (FaseIntro > 5) and (FaseIntro < 55) then
  begin
    if Lutador[1].Vida < VidaMax then Lutador[1].Vida := Lutador[1].Vida + 3;
    if Lutador[2].Vida < VidaMax then Lutador[2].Vida := Lutador[2].Vida + 3;
  end;
  if (FaseIntro > 5) and (FaseIntro < 40) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 30;
    texto(260, 85, IntToStr(RoundAtual), ACentro, 35, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
    texto(200, 100, 'ROUND   ', ACentro, 20, Branco);
  end;
  if (FaseIntro > 42) and (FaseIntro < 60) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 120;
    texto(200, 120, Linha(TxtGeral, 15), ACentro, 25, RGB(255, Pisca + 30, Pisca));
  end;
  if FaseIntro = 55 then
  begin
    RelogioParado := False;
    Lutador[1].Vida := VidaMax;
    Lutador[2].Vida := VidaMax;
  end;
end;

{ Fim do round: "KO", vencedor, bonus, cortina, proximo round ou fim da luta. }
procedure TJogo.L7_FimRound;
var
  Sup: TSuperficie;
  J, K, Pisca, I, Xr, Idx: Integer;
  P, O: PLutador;
  R: TRect;
begin
  Sup := Tela;
  if not ((Lutador[1].Vida <= 0) or ((Lutador[2].Vida <= 0) and (FaseFim < 230))) then Exit;

  if (PausaImpacto = 0) and (FlashTela = 0) then Inc(FaseFim);
  if FaseFim > 40 then RelogioParado := True;
  if FaseFim = 1 then
  begin
    PausaImpacto := 30;
    FaseFim := 2;
  end;
  if Lutador[1].Vida <= 0 then Lutador[2].Invulneravel := True;
  if Lutador[1].Vida <= 0 then Lutador[1].Invulneravel := False;
  if Lutador[2].Vida <= 0 then Lutador[1].Invulneravel := True;
  if Lutador[2].Vida <= 0 then Lutador[2].Invulneravel := False;

  if (FaseFim > 0) and (FaseFim < 30) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 100;
    texto(200, 100, 'KO', ACentro, 70, RGB(255, Pisca, 0));
    DeslocHudTopo := DeslocHudTopo - 5;
    DeslocHudBase := DeslocHudBase + 5;
  end;

  // vencedor do round: nome, "WINS", pontos por energia, perfect, bonus
  if (FaseFim > 30) and (FaseFim < 90) then
    for J := 1 to 2 do
    begin
      P := @Lutador[J];
      O := @Lutador[3 - J];
      if P.Vida > 0 then
      begin
        if RelogioParado then AcaoJogador(J, cmVitoria);
        Pisca := 0;
        if ContPisca mod 2 = 0 then Pisca := 80;
        texto(200, 110, Linha(TxtNomes, P.Personagem), ACentro, 20, RGB(255, Pisca, Pisca));
        texto(200, 140, Linha(TxtGeral, 14), ACentro, 14, Branco);
        if P.Ativo and (P.Vida < VidaMax) then
        begin
          texto(200, 210, Linha(TxtGeral, 5) + 'x5=' + IntToStr(Int64(Round(P.Vida)) * 5) + ' PTS.',
            ACentro, 12, Branco);
          if (FaseFim = 35) and (PausaImpacto = 0) and (FlashTela = 0) then
          begin
            P.Pontos := P.Pontos + Round(P.Vida) * 5;
            Inc(FaseFim);
          end;
        end;
        Pisca := 0;
        if ContPisca mod 2 = 0 then Pisca := 120;
        if (P.Vida = VidaMax) and (FaseFim > 35) then
          texto(200, 170, Linha(TxtGeral, 30), ACentro, 28, RGB(255, Pisca + 120, Pisca + 30));
        if P.Ativo and (P.Vida = VidaMax) then
        begin
          texto(200, 210, 'BONUS ' + IntToStr(1000) + ' PTS.', ACentro, 15, Branco);
          if (FaseFim = 45) and (FlashTela = 0) and (PausaImpacto = 0) then
          begin
            P.Pontos := P.Pontos + 1000;
            Inc(FaseFim);
          end;
        end;
        if P.Ativo and (NumRounds = P.RoundsVencidos) and (O.RoundsVencidos = 0) then
        begin
          Pisca := 0;
          if ContPisca mod 2 = 0 then Pisca := 20;
          texto(200, 240, Linha(TxtGeral, 32) + '  ' + IntToStr(1000) + ' PTS.', ACentro, 20,
            RGB(Pisca + 170, Pisca + 170, Pisca + 235));
          if (FaseFim = 45) and (FlashTela = 0) and (PausaImpacto = 0) then
            P.Pontos := P.Pontos + 1000;
        end;
      end;
    end;

  // conta o round ganho e sorteia a cortina e a frase de vitoria
  if FaseFim = 40 then
    for J := 2 downto 1 do
    begin
      P := @Lutador[3 - J];
      if (P.Vida > 0) and (FlashTela = 0) and (PausaImpacto = 0) then
      begin
        Inc(P.RoundsVencidos);
        Inc(FaseFim);
      end;
      EfeitoCortina := Round(Random(40) / 10) + 1;
      if EfeitoCortina > 4 then EfeitoCortina := 4;
      P.FraseVitoria := Round(Random(30) / 10) + 1;
      if P.FraseVitoria > 3 then P.FraseVitoria := 3;
    end;

  // vencedor da luta: retrato grande e frase
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if (NumRounds <= P.RoundsVencidos) and (FaseFim >= 90) and (FaseFim <= 210) then
    begin
      Pisca := 0;
      if ContPisca mod 2 = 0 then Pisca := 30;
      if RelogioParado then AcaoJogador(J, cmVitoria);
      if FaseFim = 100 then
      begin
        if not O.Ativo then Inc(Fase);
        O.Ativo := False;
      end;
      if (((TecP1 and 16) <> 0) and (J = 1)) or (((TecP2 and 16) <> 0) and (J = 2)) then
        if (FaseFim < 90) or (FaseFim > 100) then FaseFim := FaseFim + 2;
      if (FaseFim = 95) and (PausaImpacto = 0) and (FlashTela = 0) then
      begin
        K := Round(Random(200) / 200);
        if K < 0 then K := 0;
        if K > 1 then K := 1;
        Idx := (P.Personagem - 1) * 2 + K;
        if SomVitoria.Count > Idx then SomVitoria.Tocar(Idx);
      end;
      I := (P.Personagem - 1) * 5 + 4;
      if ImgRetrato.Count > I then
      begin
        if FaseFim < 100 then
        begin
          R := Rect(728 - (FaseFim - 90) * 50, 29, 872 - (FaseFim - 90) * 50, 218);
          ImgRetrato[I].DrawAlpha(Sup, R, 0, 255);
        end;
        if (FaseFim >= 100) and (FaseFim < 180) then
        begin
          R := Rect(128, 29, 272, 218);
          ImgRetrato[I].DrawAlpha(Sup, R, 0, 255);
        end;
        if FaseFim >= 180 then
        begin
          R := Rect(128 - (FaseFim - 180) * 50, 29, 272 - (FaseFim - 180) * 50, 218);
          ImgRetrato[I].DrawAlpha(Sup, R, 0, 255);
        end;
      end;
      if P.Ativo then
      begin
        texto(10, 20, Linha(TxtGeral, 16), AEsq, 12, RGB(Pisca + 30, Pisca + 220, Pisca + 30));
        texto(10, 35, IntToStr(P.MaxAcertos), AEsq, 14, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
        texto(10, 60, Linha(TxtGeral, 17), AEsq, 12, RGB(Pisca + 30, Pisca + 220, Pisca + 30));
        texto(10, 75, IntToStr(P.Pontos), AEsq, 14, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
      end;
      barraredonda(5, 220, 395, 280, 5, Branco, Preto);
      texto(200, 237, Linha(TxtFrases, ((P.Personagem - 1) shl 2) + P.FraseVitoria), ACentro, 12,
        Branco);
    end;
  end;

  // cortinas pretas entre rounds
  if (Lutador[1].RoundsVencidos < NumRounds) and (Lutador[2].RoundsVencidos < NumRounds) and (FaseFim > 95) then
  begin
    if EfeitoCortina = 1 then
    begin
      barra(0, 0, 400, FaseFim * 10 - 950, Preto);
      barra(0, 1250 - FaseFim * 10, 400, 300, Preto);
    end;
    if EfeitoCortina = 2 then
    begin
      barra(0, 0, 200, FaseFim * 12 - 1150, Preto);
      barra(200, 1450 - FaseFim * 12, 400, 300, Preto);
    end;
    if EfeitoCortina = 3 then
      for K := 0 to 3 do
      begin
        barra(0, K * 80, FaseFim * 17 - 1670, K * 80 + 40, Preto);
        barra(2070 - FaseFim * 17, K * 80 + 40, 400, K * 80 + 80, Preto);
      end;
    if EfeitoCortina = 4 then
    begin
      barra(0, 0, 400, FaseFim * 10 - 1000, Preto);
      barra(0, 1300 - FaseFim * 10, 400, 300, Preto);
      barra(0, 0, FaseFim * 10 - 1000, 300, Preto);
      barra(1400 - FaseFim * 10, 0, 400, 300, Preto);
    end;
  end;

  // proximo round
  if (Lutador[1].RoundsVencidos < NumRounds) and (Lutador[2].RoundsVencidos < NumRounds) and (FaseFim > 130) then
  begin
    FaseIntro := 0;
    FaseFim := 0;
    Voador.Ativo := False;
    zerardados(1);
    zerardados(2);
    if TempoRound = 1 then ContagemSeg := 30;
    if TempoRound = 2 then ContagemSeg := 60;
    if TempoRound = 3 then ContagemSeg := 90;
    if TempoRound = 4 then ContagemSeg := 99;
    ContagemTick := 25;
    Inc(RoundAtual);
  end;

  // fim da luta: segue para a proxima etapa (adversarios / recordes / continue)
  if FaseFim > 220 then
  begin
    Estado := CHS_ADVERSARIOS;
    SomPendente := 0;
    FaseSelecao := 1;
    Lutador[1].Escolheu := False;
    Lutador[2].Escolheu := False;
    RoundAtual := 1;
    ContagemSeg := 20;
    ContagemTick := 25;
    if Lutador[1].Ativo or Lutador[2].Ativo then
    begin
      if Fase > 8 then
      begin
        if (MusicaAtual <> 0) and (SomMusica.Count > 0) then SomMusica.Parar(0);
        ContPisca := 0;
        TempoEstado := 0;
        if (Recordes[10].Pontos < Cardinal(Lutador[1].Pontos)) or (Recordes[10].Pontos < Cardinal(Lutador[2].Pontos)) then
        begin
          Estado := CHS_INICIAIS;
          Lutador[1].Iniciais := 'AAA';
          Lutador[1].CursorIni := 1;
          Lutador[2].Iniciais := 'AAA';
          Lutador[2].CursorIni := 1;
        end
        else
          Estado := CHS_FINAL;
      end;
    end;
    if not Lutador[1].Ativo and not Lutador[2].Ativo then
    begin
      if (MusicaAtual <> 0) and (SomMusica.Count > 0) then SomMusica.Parar(0);
      SomPendente := 0;
      ContPisca := 0;
      TempoEstado := 0;
      ContagemSeg := 9;
      ContagemTick := 25;
      if (Recordes[10].Pontos < Cardinal(Lutador[1].Pontos)) or (Recordes[10].Pontos < Cardinal(Lutador[2].Pontos)) then
      begin
        Estado := CHS_INICIAIS;
        Lutador[1].Iniciais := 'AAA';
        Lutador[1].CursorIni := 1;
        Lutador[2].Iniciais := 'AAA';
        Lutador[2].CursorIni := 1;
      end
      else
        Estado := CHS_CONTINUAR;
    end;
  end;
end;

{ Resolve se o golpe do lutador Jog acertou (ou foi defendido por) o oponente. }
procedure TJogo.L7_Acertos(Jog: Byte);
var
  P, O: PLutador;
  O_Jog: Byte;
  MX, MY: Integer;
  RX, RY: Integer;
  Giro: Boolean;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  O_Jog := 3 - Jog;

  // apanhando: empurrao para tras e poeira
  if ((P.Acao = acApanhaAlto) or (P.Acao = acApanhaBaixo)) and (FlashTela = 0) and (PausaImpacto = 0) then
  begin
    if P.Lado = ldDireita then Empurra(Jog, -P.Recuo);
    if P.Lado = ldEsquerda then Empurra(Jog, P.Recuo);
    if Random(2) = 0 then
    begin
      RX := Random(40);
      RY := Random(10);
      CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
    end;
  end;

  // caixa do golpe de P e caixa do corpo do oponente (coordenadas da tela)
  AtqX1 := Round(P.X) + P.AtaqueX1;
  AtqY1 := (Round(P.Y) - P.AlturaSprite) + P.AtaqueY1;
  AtqX2 := Round(P.X) + P.AtaqueX2;
  AtqY2 := (Round(P.Y) - P.AlturaSprite) + P.AtaqueY2;
  AlvoX1 := Round(O.X) + O.CorpoX1;
  AlvoY1 := (Round(O.Y) - O.AlturaSprite) + O.CorpoY1;
  AlvoX2 := Round(O.X) + O.CorpoX2;
  AlvoY2 := (Round(O.Y) - O.AlturaSprite) + O.CorpoY2;

  if P.GolpeAtivo and not O.Invulneravel and
     (AtqX1 < AlvoX2) and (AtqX2 > AlvoX1) and (AtqY1 < AlvoY2) and (AtqY2 > AlvoY1) and
     (PausaImpacto = 0) and (FlashTela = 0) then
  begin
    // ponto medio da caixa do golpe (onde aparece a faisca)
    MX := Round((P.AtaqueX1 + P.AtaqueX2) / 2);
    MY := Round((P.AtaqueY1 + P.AtaqueY2) / 2);

    // golpe alto/baixo vence a guarda errada
    if ((P.Acao = acAgChuteFraco) or (P.Acao = acAgChuteForte)) and (O.Acao = acDefesa) then O.Defendendo := False;
    if ((P.Acao = acArSocoFraco) or (P.Acao = acArChuteFraco) or (P.Acao = acArSocoForte) or (P.Acao = acArChuteForte)) and (O.Acao = acDefesaBaixa) then O.Defendendo := False;

    if O.Defendendo then
    begin
      // ---- defendido ----
      O.QuadroAcao := 1;
      SomPendente := sndDefesa;
      CriaEfeito(14, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      if O.Lado = ldDireita then Empurra(O_Jog, -10);
      if O.Lado = ldEsquerda then Empurra(O_Jog, 10);
      if (AvisoEntrada = 0) and not RelogioParado then
      begin
        O.Vida := O.Vida - P.DanoDefesa * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := sndAcertoEspecial;
        AcaoJogador(O_Jog, cmDerrubar);
      end;
      P.GolpeAtivo := False;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = fgFraco then PausaImpacto := Random(4) + 2;
        if P.ForcaGolpe = fgForte then PausaImpacto := Random(4) + 4;
      end;
    end;

    if not O.Defendendo then
    begin
      // ---- acertou ----
      if O.X < P.X then O.Lado := ldDireita;
      if O.X >= P.X then O.Lado := ldEsquerda;
      if P.Ativo and (O.Vida > 0) and (PausaImpacto = 0) and (FlashTela = 0) then
        P.Pontos := P.Pontos + 5;
      if P.CargaPoder < CargaMax then P.CargaPoder := P.CargaPoder + 2 * GanhoCarga;
      if O.CargaPoder < CargaMax then O.CargaPoder := O.CargaPoder + 1 * GanhoCarga;
      // combo
      if P.TempoAcertos <= 35 then P.Acertos := 0;
      Inc(P.Acertos);
      P.TempoAcertos := 44;
      if (P.Acao = acAgChuteForte) or (P.Acao = acArChuteForte) then P.TempoAcertos := 50;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial2) then P.TempoAcertos := 46;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial3) then P.TempoAcertos := 47;
      if (P.Personagem = pnProfGirafales) and (P.Acao = acEspecial5) then P.TempoAcertos := 50;
      if (P.Personagem = pnGloria) and (P.Acao = acEspecial3) then P.TempoAcertos := 50;
      if (AvisoEntrada = 0) and not RelogioParado then
      begin
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if Flash then
      begin
        if (P.ForcaGolpe = fgFraco) and (Random(5) = 0) then FlashVermelho := 6;
        if (P.ForcaGolpe = fgForte) and (Random(2) = 0) then FlashVermelho := 6;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := sndAcertoForte;
        AcaoJogador(O_Jog, cmDerrubar);
      end;
      // golpes que fazem o oponente girar no ar
      Giro := ((P.Personagem = pnQuico) and (P.Acao = acEspecial5)) or
              ((P.Personagem = pnDonaFlorinda) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = pnProfGirafales) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 22)) or
              ((P.Personagem = pnPaty) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 14)) or
              ((P.Personagem = pnNhonho) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = pnGodines) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 20)) or
              ((P.Personagem = pnSrFurtado) and (P.Acao = acEspecial4) and (P.QuadroAcao >= 22));
      if Giro then
      begin
        if O.Lado = ldDireita then O.VelAngular := -20;
        if O.Lado = ldEsquerda then O.VelAngular := 20;
      end;
      CriaEfeito(1, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      // sangue
      if (Sangue and (P.ForcaGolpe = fgForte) and (Random(5) = 0)) or CheatSatanas then
        CriaEfeito(10, '', 0, O.X, O.Y - (O.AlturaSprite - 40));
      // reacao do oponente
      if (P.Acao = acChuteFraco) or (P.Acao = acChuteForte) or (P.Acao = acAgSocoFraco) or (P.Acao = acAgChuteFraco) or (P.Acao = acAgSocoForte) then
        AcaoJogador(O_Jog, cmApanharBaixo)
      else
        AcaoJogador(O_Jog, cmApanharAlto);
      if P.EhChute or (O.VelY <> 0) or (ChaoY > O.Y) then AcaoJogador(O_Jog, cmDerrubar);
      // recuo (empurrao) do oponente
      O.Recuo := 4;
      if (P.Personagem = pnChaves) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 20;
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 13;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial5) then O.Recuo := 20;
      if (P.Personagem = pnProfGirafales) and (P.Acao = acEspecial3) and (P.ForcaGolpe = fgForte) then O.Recuo := 25;
      if (P.Personagem = pnSrBarriga) and (P.Acao = acEspecial3) and (P.ForcaGolpe = fgForte) then O.Recuo := 18;
      if (P.Personagem = pnPaty) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15) then O.Recuo := 25;
      if (P.Personagem = pnNhonho) and (P.Acao = acEspecial4) and (P.ForcaGolpe = fgForte) then O.Recuo := 13;
      if (P.Personagem = pnSrFurtado) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 25;
      // lancamento para cima
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial5) then O.VelY := -30;
      if (P.Personagem = pnDonaFlorinda) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15) then O.VelY := -30;
      if (P.Personagem = pnGloria) and (P.Acao = acEspecial3) then O.VelY := -26;
      if P.ForcaGolpe = fgFraco then SomPendente := sndAcertoFraco;
      if P.ForcaGolpe = fgForte then SomPendente := sndAcertoForte;
      if P.ForcaGolpe = fgEspecial then SomPendente := sndAcertoEspecial;
      // primeiro ataque do round
      if not PrimeiroAtaque then
      begin
        P.MsgBonus := 1;
        P.TempoMsgBonus := 50;
        if P.Ativo and (PausaImpacto = 0) and (FlashTela = 0) then P.Pontos := P.Pontos + 300;
        PrimeiroAtaque := True;
      end;
      P.DesenhaPorCima := True;
      O.DesenhaPorCima := False;
      P.GolpeAtivo := False;
      O.GolpeAtivo := False;
      // golpes encadeados (continuam em outra acao)
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial4) then
      begin
        P.Acao := acEspecial5;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial6) then
      begin
        P.Acao := acEspecial7;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 40;
        Inc(P.Acertos);
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnChiquinha) and (P.Acao = acEspecial5) then
      begin
        P.Acao := acEspecial6;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnSrBarriga) and (P.Acao = acEspecial5) then
      begin
        P.Acao := acEspecial6;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        O.GolpeAtivo := False;
      end;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = fgFraco then PausaImpacto := Random(4) + 5;
        if P.ForcaGolpe = fgForte then PausaImpacto := Random(4) + 7;
      end;
      AtualizaQuadro(O_Jog);
    end;

    // oponente encostado na borda da tela: o atacante recua
    if not RelogioParado then
    begin
      if CameraX + 370 <= O.X then Empurra(Jog, -12);
      if CameraX + 30 >= O.X then Empurra(Jog, 12);
    end;
  end;
end;

{ Fim das acoes, queda ao chao, fisica do pulo/queda e limites da tela. }
procedure TJogo.L7_Fisica;
var
  J, K, RX, RY: Integer;
  P, O: PLutador;
begin
  // acao terminou (QuadroAcao chegou na duracao): volta ao estado parado
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if (P.DuracaoAcao <> 99) and (FlashTela = 0) and (PausaImpacto = 0) then Inc(P.QuadroAcao);
    if P.QuadroAcao >= P.DuracaoAcao then
    begin
      P.Acao := acParado;
      P.GolpeAtivo := False;
      P.DanoGolpe := 0;
      P.QuadroAcao := 0;
      P.Invulneravel := False;
      P.Defendendo := False;
      P.EhChute := False;
      P.ForcaGolpe := fgNenhum;
      if ChaoY > P.Y then
      begin
        P.NoAr := True;
        P.Acao := acPulo;
      end;
      if P.X < O.X then P.Lado := ldDireita;
      if P.X >= O.X then P.Lado := ldEsquerda;
      if ChaoY < P.Y then P.Y := ChaoY;
      if P.VelY <> 0 then P.Acao := acPulo;
    end;
  end;

  // abaixo do chao: volta para o chao
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    if ChaoY < P.Y then
    begin
      P.Y := ChaoY;
      P.Angulo := 0;
      P.VelAngular := 0;
      P.VelY := 0;
      P.NoAr := False;
      P.Acao := acParado;
      P.QuadroAcao := 0;
      P.GolpeAtivo := False;
      P.EhChute := False;
    end;
  end;

  // no ar: gravidade, deslocamento horizontal, queda (acao 19) e aterrissagem
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if P.NoAr and (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      P.Y := P.Y + P.VelY;
      P.VelY := P.VelY + Gravidade;
      if P.DirPulo = puloEsquerda then Empurra(J, -8);
      if P.DirPulo = puloDireita then Empurra(J, 8);

      if P.Acao = acDerrubado then
      begin
        if P.Lado = ldDireita then P.X := P.X - P.Recuo;
        if P.Lado = ldEsquerda then P.X := P.X + P.Recuo;
        if ChaoY <= P.Y then
        begin
          AcaoJogador(J, cmBaterNoChao);
          P.Y := ChaoY - 10;
          P.Angulo := 0;
          P.VelAngular := 0;
          SomPendente := sndQueda;
          if (P.Personagem = pnSrBarriga) or (P.Personagem = pnNhonho) then
          begin
            TremorTela := 20;
            for K := 1 to 20 do
            begin
              RX := Random(60);
              RY := Random(10);
              CriaEfeito(2, '', 0, RX + (P.X - 30), RY + P.Y);
            end;
          end;
          for K := 1 to 5 do
          begin
            RX := Random(40);
            RY := Random(10);
            CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
          end;
        end;
      end;

      if P.Acao = acQuicando then
      begin
        if P.Lado = ldDireita then Empurra(J, -P.Recuo);
        if P.Lado = ldEsquerda then Empurra(J, P.Recuo);
        if (Sangue and (Random(4) = 0)) or CheatSatanas then
          if P.QuadroAcao = 5 then
          begin
            if P.Lado = ldDireita then CriaEfeito(10, '', 0, P.X - 30, P.Y - 50);
            if P.Lado = ldEsquerda then CriaEfeito(10, '', 0, P.X + 30, P.Y - 50);
          end;
        if ChaoY < P.Y then
        begin
          P.Y := ChaoY;
          P.NoAr := False;
          P.Angulo := 0;
          P.VelAngular := 0;
          P.VelY := 0;
          P.Recuo := 0;
        end;
      end;

      if ChaoY < P.Y then
      begin
        P.VelY := 0;
        P.NoAr := False;
        P.Y := ChaoY;
        P.Angulo := 0;
        P.VelAngular := 0;
        P.Acao := acParado;
        P.QuadroAcao := 0;
        P.GolpeAtivo := False;
        P.DanoGolpe := 0;
        P.EhChute := False;
        P.DirPulo := puloNenhum;
        if P.X < O.X then P.Lado := ldDireita;
        if P.X >= O.X then P.Lado := ldEsquerda;
        for K := 1 to 5 do
        begin
          RX := Random(40);
          RY := Random(10);
          CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
        end;
      end;
    end;

    // lutador vivo nao sai da tela
    if P.Vida > 0 then
    begin
      if CameraX + 30 > P.X then P.X := CameraX + 30;
      if CameraX + 370 < P.X then P.X := CameraX + 370;
    end;
  end;
end;

{ Dialogo do chefe (fase 8): quadros de conversa antes da luta. }
procedure TJogo.L7_Dialogo;
var
  Sup: TSuperficie;
  Jh, Jc, I, Base: Integer;
begin
  if TempoDialogo = 0 then Exit;
  Sup := Tela;
  Jh := 1;
  if Lutador[1].Ativo then Jh := 1;
  if Lutador[2].Ativo then Jh := 2;
  Jc := 2;
  if not Lutador[1].Ativo then Jc := 1;
  if not Lutador[2].Ativo then Jc := 2;

  barraredonda(5, 165, 290, 215, 20, Branco, Preto);
  I := (Lutador[Jh].Personagem - 1) * 5 + 4;
  if ImgRetrato.Count > I then
  begin
    if TempoDialogo > 580 then
      ImgRetrato[I].Draw(Sup, 15 - (TempoDialogo - 580) * 10, 85, 0);
    if TempoDialogo <= 580 then
      ImgRetrato[I].Draw(Sup, 15, 85, 0);
  end;
  barraredonda(110, 220, 395, 270, 20, Branco, Preto);
  I := (Lutador[Jc].Personagem - 1) * 5 + 4;
  if ImgRetrato.Count > I then
  begin
    if TempoDialogo > 580 then
      ImgRetrato[I].Draw(Sup, (TempoDialogo - 580) * 10 + 288, 140, 0);
    if TempoDialogo <= 580 then
      ImgRetrato[I].Draw(Sup, 288, 140, 0);
  end;

  Base := (Lutador[Jh].Personagem - 1) * 12;
  I := Base;
  if (TempoDialogo > 450) and (TempoDialogo < 600) then
  begin
    I := Base;
    Tmp4494 := 1;
  end;
  if (TempoDialogo > 300) and (TempoDialogo < 450) then
  begin
    I := Base + 3;
    Tmp4494 := 2;
  end;
  if (TempoDialogo > 150) and (TempoDialogo < 300) then
  begin
    I := Base + 6;
    Tmp4494 := 1;
  end;
  if (TempoDialogo > 0) and (TempoDialogo < 150) then
  begin
    I := Base + 9;
    Tmp4494 := 2;
  end;
  if Tmp4494 = 1 then
  begin
    texto(115, 168, Linha(TxtDialogo, I), AEsq, 10, Branco);
    texto(115, 182, Linha(TxtDialogo, I + 1), AEsq, 10, Branco);
    texto(115, 196, Linha(TxtDialogo, I + 2), AEsq, 10, Branco);
  end;
  if Tmp4494 = 2 then
  begin
    texto(120, 223, Linha(TxtDialogo, I), AEsq, 10, Branco);
    texto(120, 237, Linha(TxtDialogo, I + 1), AEsq, 10, Branco);
    texto(120, 251, Linha(TxtDialogo, I + 2), AEsq, 10, Branco);
  end;
  if (((TecP1 and 16) <> 0) and Lutador[1].Ativo) or (((TecP2 and 16) <> 0) and Lutador[2].Ativo) then
    if TempoDialogo > 10 then TempoDialogo := TempoDialogo - 5;
end;

{ Luta de demonstracao (sem jogador): cortina, "INSERT COIN" e logo; ao acabar volta a abertura. }
procedure TJogo.L7_Demo;
var
  Sup: TSuperficie;
  K, W, H: Integer;
  R: TRect;
  Logo: TImagem;
begin
  if TempoDemo <= 0 then Exit;
  Sup := Tela;
  Dec(TempoDemo);
  ContagemSeg := TempoRound;
  ContagemTick := 25;
  if TempoDemo < 40 then
    for K := 0 to 15 do
      barra(0, K * 20, 400, (40 - TempoDemo) + K * 20, Preto);
  if ContPisca < 20 then
    texto(200, 240, Linha(TxtGeral, 6), ACentro, 10, Branco);
  if TempoDemo < 500 then
  begin
    Logo := ImgAbertura.PorNome('Logo' + SufixoIdioma);
    W := Round(Logo.Width / 2);
    H := Round(Logo.Height / 2);
    R := Rect(390 - W, 280 - H, 390, 280);
    Logo.DrawAlpha(Sup, R, 0, 255);
  end;
  if TempoDemo <= 5 then
  begin
    Estado := CHS_RECORDES;
    SomPendente := 0;
    CameraY := 0;
    ContPisca := 0;
    TempoEstado := 0;
  end;
end;

{ Estado 7: a luta. }
procedure TJogo.Estado7_Luta;
var
  J: Integer;
begin
  L7_Prepara;
  L7_CenarioECamera;
  L7_Relogio;
  for J := 1 to 2 do L7_HudCima(J);

  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) and not RelogioParado then
  begin
    if Lutador[1].Ativo then L7_Entrada(1, TecP1);
    if Lutador[2].Ativo then L7_Entrada(2, TecP2);
  end;
  sequenciagolpe(1);
  sequenciagolpe(2);
  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) then
    for J := 1 to 2 do
      if not Lutador[J].Ativo and not RelogioParado then cpu(J);

  L7_Voador;
  L7_ItemBonus;

  // lutadores (quem apanhou/atacou por ultimo e desenhado por cima)
  if Lutador[1].DesenhaPorCima then
  begin
    desenhalutador(2, Round(Lutador[2].X), Round(Lutador[2].Y), Lutador[2].Acao, Byte(Lutador[2].QuadroAcao));
    desenhalutador(1, Round(Lutador[1].X), Round(Lutador[1].Y), Lutador[1].Acao, Byte(Lutador[1].QuadroAcao));
  end;
  if Lutador[2].DesenhaPorCima then
  begin
    desenhalutador(1, Round(Lutador[1].X), Round(Lutador[1].Y), Lutador[1].Acao, Byte(Lutador[1].QuadroAcao));
    desenhalutador(2, Round(Lutador[2].X), Round(Lutador[2].Y), Lutador[2].Acao, Byte(Lutador[2].QuadroAcao));
  end;

  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) and not RelogioParado then
  begin
    defendergolpe(1);
    defendergolpe(2);
  end;
  desenhaefeitos;
  for J := 1 to 2 do L7_HudBaixo(J);

  L7_TempoEsgotado;
  L7_IntroRound;
  L7_FimRound;

  for J := 1 to 2 do L7_Acertos(J);
  if PausaImpacto > 0 then Dec(PausaImpacto);
  L7_Fisica;
  L7_Dialogo;

  if (FlashTela = 0) and (PausaImpacto = 0) then Inc(ContPisca);
  if ContPisca > 30 then ContPisca := 0;
  L7_Demo;

  if FlashVermelho > 0 then
  begin
    if ContPisca mod 2 = 0 then barra(0, 0, LarguraTela, AlturaTela, Vermelho);
    Dec(FlashVermelho);
  end;
  if (Estado = CHS_LUTA) and PassoAPasso then mostragolpe;
end;

{ Teclado do estado LUTA: G = pausa quadro a quadro, 1/2 = entrada do jogador }
procedure TJogo.Teclado_Luta(Key, Tk: Integer);
begin
  { G = pausa quadro a quadro durante a luta }
  if (Key = Integer(SDL_SCANCODE_G)) and (Estado = CHS_LUTA) then
  begin
    if not Pausado then
    begin
      Pausado := True;
      PassoAPasso := True;
    end
    else
    begin
      QuadroAtivo := True;
      Pausado := False;
      PassoAPasso := False;
    end;
  end;
  if (Estado = CHS_LUTA) and (Fichas > 0) and not RelogioParado then
  begin
    if (Tk = Integer(SDL_SCANCODE_1)) and not Lutador[1].Ativo then
    begin
      Lutador[1].Ativo := True;
      Lutador[1].Escolheu := False;
      Lutador[1].Pontos := 0;
      Lutador[1].RoundsVencidos := 0;
      Dec(Fichas);
      AvisoEntrada := 100;
    end;
    if (Tk = Integer(SDL_SCANCODE_2)) and not Lutador[2].Ativo then
    begin
      Lutador[2].Ativo := True;
      Lutador[2].Escolheu := False;
      Lutador[2].Pontos := 0;
      Lutador[2].RoundsVencidos := 0;
      Dec(Fichas);
      AvisoEntrada := 100;
    end;
  end;
end;
