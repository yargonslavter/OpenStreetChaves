{ Estado0_Resolucao.inc - Estado CHS_RESOLUCAO: escolha da resolucao. }

{ Estado 0: escolha da resolucao }
procedure TJogo.Estado0_Resolucao;
var
  Cor: TColor;
  K1, K2: Byte;
begin
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 10, TextoInterface('Titulo'), ACentro, 10, RGB(100, 100, 255));
  texto(200, 25, Versao, ACentro, 9, RGB(100, 100, 255));
  if ContPisca < 12 then
    texto(200, 100, TextoInterface('SelecioneResolucao'), ACentro, 10, Branco);
  texto(200, 130, TextoInterface('Janela'), ACentro, 10, CinzaMedio);
  texto(200, 150, TextoInterface('TelaCheia1'), ACentro, 10, CinzaMedio);
  texto(200, 170, TextoInterface('TelaCheia2'), ACentro, 10, CinzaMedio);
  Cor := Branco;
  if ContPisca <= 5 then Cor := Branco;
  if (ContPisca > 5) and (ContPisca <= 10) then Cor := RGB(225, 225, 225);
  if ContPisca > 10 then Cor := RGB(195, 195, 195);
  if CursorMenu = 1 then texto(200, 130, TextoInterface('Janela'), ACentro, 10, Cor);
  if CursorMenu = 2 then texto(200, 150, TextoInterface('TelaCheia1'), ACentro, 10, Cor);
  if CursorMenu = 3 then texto(200, 170, TextoInterface('TelaCheia2'), ACentro, 10, Cor);
  ImgIcone.PorNome('Cima').Draw(Tela, 150, 220, 0);
  ImgIcone.PorNome('Baixo').Draw(Tela, 165, 220, 0);
  texto(200, 220, TextoInterface('Seleciona'), ACentro, 7, Branco);
  texto(200, 230, TextoInterface('Confirma'), ACentro, 7, Branco);
  Cor := Rosa;
  if ContPisca <= 8 then Cor := RGB(255, 150, 150);
  texto(200, 270, TextoInterface('Freeware'), ACentro, 8, Cor);

  K1 := TecP1;
  K2 := TecP2;
  if ((K1 and 1) <> 0) and not Lutador[1].AntCima then Dec(CursorMenu);
  if ((K1 and 2) <> 0) and not Lutador[1].AntBaixo then Inc(CursorMenu);
  if ((K2 and 1) <> 0) and not Lutador[2].AntCima then Dec(CursorMenu);
  if ((K2 and 2) <> 0) and not Lutador[2].AntBaixo then Inc(CursorMenu);
  if CursorMenu < 1 then CursorMenu := 1;
  if CursorMenu > 3 then CursorMenu := 3;

  if ((K1 or K2) and 16) <> 0 then
  begin
    AplicarResolucao(CursorMenu);
    Estado := CHS_ABERTURA;
    CameraY := 0;
    ContPisca := 0;
    TempoEstado := 0;
  end;
  Inc(ContPisca);
  if ContPisca > 15 then ContPisca := 0;
end;
