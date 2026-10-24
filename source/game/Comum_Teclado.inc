{ Comum_Teclado.inc - entrada de teclado do jogo: teclas globais e despacho para cada estado.
  O teclado de cada estado fica no .inc do proprio estado (Teclado_*). }

procedure TJogo.TeclaAbaixo(Key: Integer);
var
  Tk: Integer;
begin
  { teclado numerico vale como 1, 2 e 5 nas fichas/entradas }
  Tk := Key;
  if Key = Integer(SDL_SCANCODE_KP_1) then Tk := Integer(SDL_SCANCODE_1);
  if Key = Integer(SDL_SCANCODE_KP_2) then Tk := Integer(SDL_SCANCODE_2);
  if Key = Integer(SDL_SCANCODE_KP_5) then Tk := Integer(SDL_SCANCODE_5);
  if Key = Integer(SDL_SCANCODE_ESCAPE) then Sair := True;
  { - e = : velocidade do jogo }
  if (Key = Integer(SDL_SCANCODE_MINUS)) and (IntervaloTimer < 80) then Inc(IntervaloTimer);
  if (Key = Integer(SDL_SCANCODE_EQUALS)) and (IntervaloTimer >= 1) then Dec(IntervaloTimer);
  if (Key = Integer(SDL_SCANCODE_MINUS)) or (Key = Integer(SDL_SCANCODE_EQUALS)) then AvisoVelocidade := 30;
  { , e . : desloca a imagem }
  if (Key = Integer(SDL_SCANCODE_COMMA)) and (DeslocX > -40) then DeslocX := DeslocX - 1;
  if (Key = Integer(SDL_SCANCODE_PERIOD)) and (DeslocX < 40) then DeslocX := DeslocX + 1;
  { P = pausa }
  if Key = Integer(SDL_SCANCODE_P) then
  begin
    if not Pausado then
      Pausado := True
    else
    begin
      QuadroAtivo := True;
      Pausado := False;
      PassoAPasso := False;
    end;
  end;
  { o resto depende do estado em que o jogo esta }
  case Estado of
    CHS_ABERTURA: Teclado_Abertura(Key, Tk);
    CHS_CONFIG: Teclado_Config(Key);
    CHS_TECLAS: Teclado_Teclas(Key);
    CHS_SELECAO: Teclado_Selecao(Tk);
    CHS_LUTA: Teclado_Luta(Key, Tk);
    CHS_CONTINUAR: Teclado_Continuar(Tk);
  end;
  { tecla 5 = insere ficha }
  if Tk = Integer(SDL_SCANCODE_5) then
  begin
    if Fichas < 99 then
    begin
      Inc(Fichas);
      TocarSom(0);
      if (TempoDemo > 0) or (Estado = CHS_RECORDES) then
        if Fichas > 0 then
        begin
          Estado := CHS_ABERTURA;
          TempoEstado := 500;
          ContPisca := 0;
          CameraY := -200;
          TempoDemo := 0;
        end;
    end;
  end;
end;
