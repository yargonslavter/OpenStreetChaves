{ Comum_SDL.inc - Interface do jogo com o ChavesSDL.pas: passo da logica, buffer de pixels e teclas. }

procedure TJogo.PassoSDL;
begin
  if QuadroAtivo then ExecutarQuadro;
end;

function TJogo.PixelsSDL: Pointer;
begin
  Result := Tela.ScanLine(0);
end;

function TJogo.DeslocamentoX: Integer;
begin
  Result := DeslocX;
end;

{ entrega ao jogo uma tecla vinda do SDL (Scan = SDL_SCANCODE_*) }
procedure TJogo.TeclaSDL(Scan: Integer; Baixo: Boolean);
begin
  if (Scan < 0) or (Scan > High(FTeclas)) then Exit;
  FTeclas[Scan] := Baixo;
  if Baixo then TeclaAbaixo(Scan);
end;

{ estado do gamepad do jogador (calculado pelo ChavesSDL a cada passo) }
procedure TJogo.EntradaControle(Jogador: Integer; Bits: Byte);
begin
  if (Jogador >= 1) and (Jogador <= 2) then ControleP[Jogador] := Bits;
end;

{ soltou todas as teclas (janela perdeu o foco) }
procedure TJogo.SoltarTeclas;
begin
  FillChar(FTeclas, SizeOf(FTeclas), 0);
  ControleP[1] := 0;
  ControleP[2] := 0;
end;

{ teclas padrao dos dois jogadores (teclas fisicas, independem do layout do teclado) }
procedure TJogo.IniciarEntrada;
begin
  MapaP1[0] := Integer(SDL_SCANCODE_UP);
  MapaP1[1] := Integer(SDL_SCANCODE_DOWN);
  MapaP1[2] := Integer(SDL_SCANCODE_LEFT);
  MapaP1[3] := Integer(SDL_SCANCODE_RIGHT);
  MapaP1[4] := Integer(SDL_SCANCODE_Z);
  MapaP1[5] := Integer(SDL_SCANCODE_X);
  MapaP1[6] := Integer(SDL_SCANCODE_C);
  MapaP1[7] := Integer(SDL_SCANCODE_V);
  MapaP2[0] := Integer(SDL_SCANCODE_W);
  MapaP2[1] := Integer(SDL_SCANCODE_S);
  MapaP2[2] := Integer(SDL_SCANCODE_A);
  MapaP2[3] := Integer(SDL_SCANCODE_D);
  MapaP2[4] := Integer(SDL_SCANCODE_R);
  MapaP2[5] := Integer(SDL_SCANCODE_T);
  MapaP2[6] := Integer(SDL_SCANCODE_Y);
  MapaP2[7] := Integer(SDL_SCANCODE_U);
end;

{ bits 1,2,4,8 = cima, baixo, esquerda, direita; 16,32,64,128 = botoes 1..4 }
function TJogo.BitsTeclado(const Mapa: array of Integer): Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 7 do
    if (Mapa[I] >= 0) and (Mapa[I] <= High(FTeclas)) and FTeclas[Mapa[I]] then
      Result := Result or (1 shl I);
end;

{ nome da tecla para a tela de configuracao (teclado numerico: NumN, como no original) }
function TJogo.NomeTecla(Scan: Integer): string;
begin
  if (Scan >= Integer(SDL_SCANCODE_KP_1)) and (Scan <= Integer(SDL_SCANCODE_KP_9)) then
    Result := 'Num' + IntToStr(Scan - Integer(SDL_SCANCODE_KP_1) + 1)
  else if Scan = Integer(SDL_SCANCODE_KP_0) then
    Result := 'Num0'
  else
    Result := string(SDL_GetKeyName(SDL_GetKeyFromScancode(TSDL_ScanCode(Scan))));
end;
