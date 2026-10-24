{ Estado3_Teclas.inc - Estado CHS_TECLAS: configuracao das teclas do jogador 1 (F2). }

{ Estado 3: configuracao das teclas do jogador 1 (F2) }
procedure TJogo.Estado3_Teclas;
var
  Sel: TColor;
  I, K, Y: Integer;
begin
  Sel := AzulSelecao;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 5, Linha(TxtConfig, 23), ACentro, 15, Branco);
  for I := 1 to 8 do texto(50, 60 + 20 * I, Linha(TxtConfig, 23 + I), AEsq, 11, Branco);
  for I := 1 to 8 do
  begin
    K := MapaP1[I - 1];
    Y := (I - 1) * 20;
    if K = Integer(SDL_SCANCODE_UP) then ImgIcone.PorNome('Cima').Draw(Tela, 200, Y + 85, 0)
    else if K = Integer(SDL_SCANCODE_DOWN) then ImgIcone.PorNome('Baixo').Draw(Tela, 200, Y + 85, 0)
    else if K = Integer(SDL_SCANCODE_RIGHT) then ImgIcone.PorNome('Direita').Draw(Tela, 200, Y + 85, 0)
    else if K = Integer(SDL_SCANCODE_LEFT) then ImgIcone.PorNome('Esquerda').Draw(Tela, 200, Y + 85, 0)
    else texto(200, Y + 80, NomeTecla(K), AEsq, 11, Branco);
  end;
  if (CursorMenu >= 1) and (CursorMenu <= 8) then
    texto(50, 60 + 20 * CursorMenu, Linha(TxtConfig, 23 + CursorMenu), AEsq, 11, Sel);
  if CursorMenu < 1 then CursorMenu := 1;
  if CursorMenu > 9 then CursorMenu := 9;
  texto(200, 280, Linha(TxtConfig, 32), ACentro, 11, Branco);
end;

{ Teclado do estado TECLAS: F2 volta a abertura; as demais teclas sao capturadas para a acao CursorMenu (1..8) }
procedure TJogo.Teclado_Teclas(Key: Integer);
begin
  if Key = Integer(SDL_SCANCODE_F2) then
    Estado := CHS_ABERTURA
  else
  begin
    { aceita letras, digitos, setas e teclado numerico, como no original }
    if ((Key >= Integer(SDL_SCANCODE_A)) and (Key <= Integer(SDL_SCANCODE_0))) or
       ((Key >= Integer(SDL_SCANCODE_RIGHT)) and (Key <= Integer(SDL_SCANCODE_UP))) or
       ((Key >= Integer(SDL_SCANCODE_KP_1)) and (Key <= Integer(SDL_SCANCODE_KP_0))) then
    begin
      if (CursorMenu >= 1) and (CursorMenu <= 8) then
        MapaP1[CursorMenu - 1] := Key;
      Inc(CursorMenu);
    end;
  end;
end;
