{ Estado10_Final.inc - Estado CHS_FINAL: final de cada personagem (cenas temporizadas com legenda). }

{ Sombra translucida sob o balao e a figura do final Img, em (X, Y). }
procedure TJogo.F10_Fala(R: TRect; Img, X, Y: Integer);
var
  Sup: TSuperficie;
begin
  Sup := Tela;
  ImgEfeitos[0].DrawAlpha(Sup, R, 0, 70);
  if Img < ImgFinal.Count then ImgFinal[Img].Draw(Sup, X, Y, 0);
end;

{ Tela cheia de cor aleatoria com duas fagulhas (explosao). }
procedure TJogo.F10_Explosao;
begin
  barra(50, 50, 350, 220, RGB(255, Random(255), Random(255)));
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
end;

procedure TJogo.Estado10_Final;
var
  Sup: TSuperficie;
  T, Base, Seg, Linha4, I: Integer;
  Cod: string;
begin
  Sup := Tela;
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

  if ImgCenario.Count > 0 then
  begin
    ImgCenario[0].Draw(Sup, -80, -100, 0);
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
          if ImgFinal.Count > 0 then ImgFinal[0].Draw(Sup, 175, 165, 0);
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
          if ImgFinal.Count > 10 then ImgFinal[10].Draw(Sup, 180, 190, 0);
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
  if (Tmp4494 <> 99) and (ImgRetrato.Count > Tmp4494) and (T < 2200) then
  begin
    ImgRetrato[Tmp4494].Draw(Sup, 20, 222, 0);
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
  if (((TecP1 and 16) <> 0) and (Lutador[1].Ativo = 1)) or
     (((TecP2 and 16) <> 0) and (Lutador[2].Ativo = 1)) then
    for I := 0 to 20 do
      if (TempoEstado > I * 100 + 5) and (TempoEstado < I * 100 + 85) then
        TempoEstado := I * 100 + 85;
end;
