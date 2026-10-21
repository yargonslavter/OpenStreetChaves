{ ChavesFim.inc - estados 8 a 12: recordes, continuar, final de cada personagem,
  aviso e digitacao das iniciais. Incluido em ChavesPrj.pas depois de ChavesLuta7.inc. }

{ ===================================================================== }
{ Estado 8: tabela de recordes (rola de baixo para cima, revelando o 1o) }
{ ===================================================================== }
procedure TForm1.Estado8_Recordes;
var
  Sup: TDirectDrawSurface;
  L, Pos, Y, Idx: Integer;
  Pisca: Integer;
  Cor: TColor;
  Rotulo: string;
begin
  Sup := DXDraw1.Surface;
  for L := 0 to 20 do
    barra(0, L * 20, LarguraTela, L * 20 + 20, RGB(L * 5 + 100, L * 5 + 130, L * 5 + 160));
  for Pos := 1 to 10 do
  begin
    Pisca := 0;
    if (Pos = 1) and (ContPisca mod 2 = 0) then Pisca := 80;
    Cor := RGB(255, 255 - Pisca, 255 - Pisca);
    Y := Pos * 60 - 350 - CameraY;
    if Pos < 10 then Rotulo := '0' + IntToStr(Pos) + ' -' else Rotulo := IntToStr(Pos) + ' -';
    texto(50, Y, Rotulo, AEsq, 15, Cor);
    texto(100, Y, Recordes[Pos].Nome, AEsq, 15, Cor);
    Idx := (Recordes[Pos].Personagem - 1) * 5;
    if (Idx >= 0) and (Idx < DXImageListRetrato.Items.Count) then
    begin
      Sup.Canvas.Release;
      DXImageListRetrato.Items[Idx].Draw(Sup, 160, Pos * 60 - 370 - CameraY, 0);
    end;
    texto(230, Y, IntToStr(Recordes[Pos].Pontos), AEsq, 15, Cor);
  end;
  // cortina que fecha no fim
  if TempoEstado > 240 then
    for L := 0 to 15 do
      barra(0, L * 20, LarguraTela, L * 20 + (TempoEstado - 240), Preto);
  if ContPisca < 18 then texto(200, 5, Linha(MemoTexto, 21), ACentro, 12, Branco);
  if ContPisca < 10 then texto(200, 240, Linha(MemoTexto, 6), ACentro, 10, Branco);
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  Inc(TempoEstado);
  if TempoEstado > 1000 then TempoEstado := 1000;
  if TempoEstado > 80 then Dec(CameraY, 5);
  if CameraY < -320 then CameraY := -320;
  if TempoEstado > 280 then
  begin
    Estado := CHS_ABERTURA;
    ContPisca := 0;
    TempoEstado := 0;
    CameraY := 0;
  end;
end;

{ ===================================================================== }
{ Estado 9: "continuar?" com contagem regressiva                         }
{ ===================================================================== }
procedure TForm1.Estado9_Continuar;
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
      Lutador[1].Ativo := 0;
      Lutador[2].Ativo := 0;
    end;
  end;
end;

{ ===================================================================== }
{ Estado 10: final do personagem (cenas temporizadas com legenda)        }
{ ===================================================================== }

{ Sombra translucida sob o balao e a figura do final Img, em (X, Y). }
procedure TForm1.F10_Fala(R: TRect; Img, X, Y: Integer);
var
  Sup: TDirectDrawSurface;
begin
  Sup := DXDraw1.Surface;
  Sup.Canvas.Release;
  DXImageListEfeitos.Items[0].DrawAlpha(Sup, R, 0, 70);
  if Img < DXImageListFinal.Items.Count then DXImageListFinal.Items[Img].Draw(Sup, X, Y, 0);
end;

{ Tela cheia de cor aleatoria com duas fagulhas (explosao). }
procedure TForm1.F10_Explosao;
begin
  barra(50, 50, 350, 220, RGB(255, Random(255), Random(255)));
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
end;

procedure TForm1.Estado10_Final;
var
  Sup: TDirectDrawSurface;
  T, Base, Seg, Linha4, I: Integer;
  Cod: string;
begin
  Sup := DXDraw1.Surface;
  CameraX := 0;
  CameraY := 0;
  ChaoY := 210;
  Lutador[1].X := 100;
  Lutador[1].Lado := 1;
  Lutador[2].X := 200;
  Lutador[2].Lado := 2;
  T := TempoEstado;

  if T = 0 then
  begin
    if Lutador[1].Ativo = 1 then FinalId := Lutador[1].Personagem;
    if Lutador[2].Ativo = 1 then FinalId := Lutador[2].Personagem;
  end;

  if DXImageListCenario.Items.Count > 0 then
  begin
    Sup.Canvas.Release;
    DXImageListCenario.Items[0].Draw(Sup, -80, -100, 0);
  end;

  Base := 0;
  case FinalId of
    1:
      begin
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C01.bmp', 1, 1);
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        desenhalutador(1, 150, 210, 1, 0);
        desenhalutador(2, 250, 210, 1, 0);
      end;
    2:
      begin
        Base := 44;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-03.bmp');
          carregarlutador('Lutadores/C02.bmp', 2, 1);
          carregarlutador('Lutadores/C05.bmp', 5, 2);
        end;
        if T = 390 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C01.bmp', 1, 2);
        end;
        if T < 400 then
        begin
          desenhalutador(1, 150, 210, 1, 0);
          desenhalutador(2, 250, 210, 1, 0);
          Sup.Canvas.Release;
          if DXImageListFinal.Items.Count > 0 then DXImageListFinal.Items[0].Draw(Sup, 175, 165, 0);
        end;
        if (T > 350) and (T < 400) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T > 400 then
        begin
          F10_Fala(Rect(100, 203, 170, 217), 1, 110, 65);
          desenhalutador(2, 270, 210, 1, 0);
        end;
      end;
    3:
      begin
        Base := 88;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C09.bmp', 9, 1);
          carregarlutador('Lutadores/C04.bmp', 4, 2);
        end;
        if T = 390 then carregarlutador('Lutadores/C01.bmp', 1, 2);
        if T < 400 then
        begin
          desenhalutador(1, 150, 210, 20, 18);
          desenhalutador(2, 250, 210, 1, 0);
        end;
        if (T > 350) and (T < 400) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if (T > 400) and (T < 1000) then
        begin
          desenhalutador(1, 150, 210, 20, 18);
          desenhalutador(2, 300, 210, 1, 0);
          if T > 800 then F10_Fala(Rect(180, 203, 250, 217), 2, 170, 65);
        end;
        if (T >= 1000) and (T < 1400) then F10_Explosao;
        if (T >= 1400) and (T < 1600) then
        begin
          desenhalutador(1, 150, 210, 20, 18);
          F10_Fala(Rect(170, 197, 240, 211), 3, 165, 90);
        end;
        if T >= 1600 then
        begin
          F10_Fala(Rect(120, 197, 190, 211), 4, 135, 80);
          desenhalutador(2, 220, 210, 1, 0);
        end;
        if (T > 1800) and (Random(8) = 0) then CriaEfeito(24, '', 0, Random(100) + 150, Random(30) + 60);
      end;
    4:
      begin
        Base := 125;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C04.bmp', 4, 1);
          carregarlutador('Lutadores/C01.bmp', 1, 2);
        end;
        if (T < 1400) or (T >= 1600) then
        begin
          desenhalutador(1, 150, 210, 1, 0);
          desenhalutador(2, 250, 210, 1, 0);
        end;
        if ((T >= 500) and (T < 600)) or ((T >= 1100) and (T < 1200)) then F10_Explosao;
        if (T >= 1400) and (T < 1600) then
        begin
          desenhalutador(1, 150, 210, 1, 0);
          F10_Fala(Rect(200, 197, 270, 211), 5, 190, 90);
        end;
      end;
    5:
      begin
        Base := 166;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C05.bmp', 5, 1);
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        if T = 590 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C05.bmp', 5, 2);
        end;
        if T < 600 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          F10_Fala(Rect(220, 207, 290, 221), 6, 195, 120);
          if (T < 530) and (Random(8) = 0) then CriaEfeito(25, '', 0, Random(60) + 250, Random(20) + 110);
        end;
        if (T > 560) and (T < 600) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 600 then
        begin
          desenhalutador(2, 280, 210, 1, 0);
          F10_Fala(Rect(120, 197, 190, 211), 7, 120, 48);
        end;
      end;
    6:
      begin
        Base := 210;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-11.bmp');
          carregarlutador('Lutadores/C06.bmp', 6, 1);
          carregarlutador('Lutadores/C07.bmp', 7, 2);
        end;
        if T = 590 then
        begin
          carregarcenario('Cenarios/Cenario-03.bmp');
          carregarlutador('Lutadores/C05.bmp', 5, 2);
        end;
        if T < 600 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 245, 210, 20, 18);
        end;
        if (T > 550) and (T < 600) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 600 then
        begin
          desenhalutador(2, 280, 210, 1, 0);
          F10_Fala(Rect(120, 197, 190, 211), 7, 120, 48);
        end;
      end;
    7:
      begin
        Base := 254;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C07.bmp', 7, 1);
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        if T = 1790 then carregarcenario('Cenarios/Cenario-01.bmp');
        if T < 1700 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 235, 210, 1, 0);
        end;
        if (T >= 1700) and (T < 1800) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 1800 then F10_Fala(Rect(120, 197, 190, 211), 8, 125, 60);
      end;
    8:
      begin
        Base := 298;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C08.bmp', 8, 1);
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        if T = 1690 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C02.bmp', 2, 1);
        end;
        if T < 1700 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 235, 210, 1, 0);
        end;
        if (T >= 1600) and (T < 1700) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 1700 then
        begin
          desenhalutador(1, 105, 210, 1, 0);
          F10_Fala(Rect(240, 197, 310, 211), 9, 248, 67);
          Sup.Canvas.Release;
          if DXImageListFinal.Items.Count > 10 then DXImageListFinal.Items[10].Draw(Sup, 180, 190, 0);
        end;
      end;
    9:
      begin
        Base := 342;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C09.bmp', 9, 1);
          carregarlutador('Lutadores/C03.bmp', 3, 2);
        end;
        if T = 790 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C09.bmp', 9, 1);
          carregarlutador('Lutadores/C01.bmp', 1, 2);
        end;
        if T < 800 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 235, 210, 20, 18);
        end;
        if (T > 700) and (T < 800) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 800 then
        begin
          F10_Fala(Rect(120, 197, 190, 211), 4, 128, 80);
          desenhalutador(2, 215, 210, 1, 0);
        end;
      end;
    10:
      begin
        Base := 386;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C10.bmp', 10, 1);
          carregarlutador('Lutadores/C01.bmp', 1, 2);
        end;
        if T = 390 then
        begin
          carregarcenario('Cenarios/Cenario-03.bmp');
          carregarlutador('Lutadores/C10.bmp', 10, 1);
          carregarlutador('Lutadores/C04.bmp', 4, 2);
        end;
        if T < 400 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 235, 210, 20, 18);
        end;
        if (T > 300) and (T < 400) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 400 then
        begin
          desenhalutador(1, 125, 210, 1, 0);
          desenhalutador(2, 235, 210, 1, 0);
        end;
      end;
    11:
      begin
        Base := 430;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C11.bmp', 11, 1);
          carregarlutador('Lutadores/C03.bmp', 3, 2);
        end;
        if T = 590 then
        begin
          carregarcenario('Cenarios/Cenario-05.bmp');
          carregarlutador('Lutadores/C01.bmp', 1, 1);
          carregarlutador('Lutadores/C11.bmp', 11, 2);
        end;
        if T < 600 then
        begin
          desenhalutador(1, 115, 210, 1, 0);
          desenhalutador(2, 245, 210, 1, 0);
        end;
        if (T > 500) and (T < 600) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 600 then
        begin
          desenhalutador(1, 135, 210, 1, 0);
          desenhalutador(2, 225, 210, 1, 0);
        end;
      end;
    12:
      begin
        Base := 474;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C01.bmp', 1, 1);
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        desenhalutador(1, 135, 210, 1, 0);
        desenhalutador(2, 225, 210, 1, 0);
      end;
    13:
      begin
        Base := 518;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C13.bmp', 13, 1);
          carregarlutador('Lutadores/C01.bmp', 1, 2);
        end;
        desenhalutador(1, 135, 210, 1, 0);
        desenhalutador(2, 225, 210, 1, 0);
      end;
    14:
      begin
        Base := 562;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C13.bmp', 13, 1);
          carregarlutador('Lutadores/C14.bmp', 14, 2);
        end;
        desenhalutador(1, 135, 210, 1, 0);
        desenhalutador(2, 255, 210, 1, 0);
      end;
    15:
      begin
        Base := 606;
        if T = 0 then
        begin
          carregarcenario('Cenarios/Cenario-02.bmp');
          carregarlutador('Lutadores/C15.bmp', 15, 1);
          carregarlutador('Lutadores/C03.bmp', 3, 2);
        end;
        if T = 490 then
        begin
          carregarcenario('Cenarios/Cenario-01.bmp');
          carregarlutador('Lutadores/C02.bmp', 2, 2);
        end;
        if T = 1800 then
        begin
          carregarlutador('Lutadores/C02.bmp', 2, 1);
          carregarlutador('Lutadores/C04.bmp', 4, 2);
        end;
        if T <= 400 then
        begin
          desenhalutador(1, 135, 210, 1, 0);
          desenhalutador(2, 255, 210, 20, 18);
        end;
        if (T > 400) and (T < 500) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if (T >= 500) and (T < 1800) then
        begin
          desenhalutador(1, 135, 210, 2, 0);
          desenhalutador(2, 255, 210, 1, 0);
        end;
        if (T > 1800) and (T < 1850) then barra(0, 0, LarguraTela, AlturaTela, Preto);
        if T >= 1850 then
        begin
          desenhalutador(1, 135, 210, 1, 0);
          desenhalutador(2, 255, 210, 1, 0);
        end;
      end;
  end;

  desenhaefeitos;

  // moldura de cinema: so a janela central aparece
  barra(0, 0, LarguraTela, 50, Preto);
  barra(0, 220, LarguraTela, AlturaTela, Preto);
  barra(0, 50, 50, 220, Preto);
  barra(350, 50, LarguraTela, 220, Preto);

  // legenda: a cada 200 quadros muda o trecho (4 linhas do memo de finais por trecho)
  Seg := T div 200;
  if Seg > 10 then Seg := 10;
  Linha4 := Seg * 4 + Base;
  Cod := Linha(MemoFinais, Linha4);
  if Cod = '-' then Tmp4494 := 99;
  for I := 0 to 14 do
    if Cod = Chr(Ord('A') + I) then Tmp4494 := I * 5;
  if (Tmp4494 <> 99) and (DXImageListRetrato.Items.Count > Tmp4494) and (T < 2200) then
  begin
    Sup.Canvas.Release;
    DXImageListRetrato.Items[Tmp4494].Draw(Sup, 20, 222, 0);
  end;
  if (Tmp4494 <> 99) and (T < 2200) then
  begin
    texto(80, 228, Linha(MemoFinais, Linha4 + 1), AEsq, 12, Branco);
    texto(80, 245, Linha(MemoFinais, Linha4 + 2), AEsq, 12, Branco);
    texto(80, 262, Linha(MemoFinais, Linha4 + 3), AEsq, 12, Branco);
  end;

  Inc(TempoEstado);
  if TempoEstado > 2200 then
  begin
    ContPisca := 0;
    TempoEstado := 0;
    Estado := CHS_AVISO;
  end;

  // qualquer botao ativo pula para o fim do trecho atual
  DXInput1.Update;
  if (((TecP1 and 16) <> 0) and (Lutador[1].Ativo = 1)) or
     (((TecP2 and 16) <> 0) and (Lutador[2].Ativo = 1)) then
    for I := 0 to 20 do
      if (TempoEstado > I * 100 + 5) and (TempoEstado < I * 100 + 85) then
        TempoEstado := I * 100 + 85;
end;

{ ===================================================================== }
{ Estado 11: aviso final ("obrigado por jogar")                          }
{ ===================================================================== }
procedure TForm1.Estado11_Aviso;
var
  Sup: TDirectDrawSurface;
begin
  Sup := DXDraw1.Surface;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 50, Linha(MemoTexto, 25), ACentro, 15, Branco);
  Sup.Canvas.Release;
  if (Idioma = 1) and (DXImageListAbertura.Items.Count > 12) then DXImageListAbertura.Items[12].Draw(Sup, 89, 80, 0);
  if (Idioma = 2) and (DXImageListAbertura.Items.Count > 13) then DXImageListAbertura.Items[13].Draw(Sup, 89, 80, 0);
  texto(200, 240, Linha(MemoTexto, 26), ACentro, 10, Branco);
  texto(200, 260, Linha(MemoTexto, 31), ACentro, 10, Branco);
  Inc(TempoEstado);
  if TempoEstado > 200 then
  begin
    Estado := CHS_CONTINUAR;
    ContPisca := 0;
    TempoEstado := 0;
    ContagemSeg := 0;
    ContagemTick := 0;
  end;
end;

{ ===================================================================== }
{ Estado 12: digitacao das iniciais de quem entrou nos recordes          }
{ ===================================================================== }
procedure TForm1.Estado12_Iniciais;
var
  J, X: Integer;
  P: PLutador;
  K: Byte;
begin
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  Inc(TempoEstado);
  if TempoEstado > 1000 then TempoEstado := 1000;

  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    if Recordes[10].Pontos >= Cardinal(P.Pontos) then Continue;
    X := (J - 1) * 200 + 20;
    texto(X, 5, P.Iniciais[1], AEsq, 15, Branco);
    texto(X + 15, 5, P.Iniciais[2], AEsq, 15, Branco);
    texto(X + 30, 5, P.Iniciais[3], AEsq, 15, Branco);
    if ContPisca < 15 then texto(X + (P.CursorIni - 1) * 15, 4, '-', AEsq, 27, Branco);

    DXInput1.Update;
    if J = 1 then K := TecP1 else K := TecP2;
    if ((K and 4) <> 0) and (P.AntEsq = 0) then Dec(P.CursorIni);
    if ((K and 8) <> 0) and (P.AntDir = 0) then Inc(P.CursorIni);
    if P.CursorIni < 1 then P.CursorIni := 1;
    if P.CursorIni > 3 then P.CursorIni := 3;
    if ((K and 1) <> 0) and (P.AntCima = 0) then P.Iniciais[P.CursorIni] := Chr(Ord(P.Iniciais[P.CursorIni]) + 1);
    if ((K and 2) <> 0) and (P.AntBaixo = 0) then P.Iniciais[P.CursorIni] := Chr(Ord(P.Iniciais[P.CursorIni]) - 1);
    if Ord(P.Iniciais[P.CursorIni]) < 48 then P.Iniciais[P.CursorIni] := Chr(48);
    if Ord(P.Iniciais[P.CursorIni]) > 90 then P.Iniciais[P.CursorIni] := Chr(90);
    if ((K and 16) <> 0) and (P.AntSocoFraco = 0) then Inc(P.CursorIni);

    // confirmou (3 letras) ou o tempo acabou
    if (P.CursorIni > 3) or (TempoEstado = 1000) then
    begin
      if P.Ativo = 0 then
      begin
        Estado := CHS_CONTINUAR;
        ContPisca := 0;
        TempoEstado := 0;
        ContagemSeg := 9;
        ContagemTick := 25;
        criarecorde(10, P.Iniciais, P.Personagem, P.Pontos);
        ordenarecordista;
      end
      else
      begin
        Estado := CHS_FINAL;
        ContPisca := 0;
        TempoEstado := 0;
        criarecorde(10, P.Iniciais, P.Personagem, P.Pontos);
        ordenarecordista;
      end;
    end;
  end;
end;
