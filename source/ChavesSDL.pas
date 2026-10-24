unit ChavesSDL;

{ ChavesSDL.pas - NOVO PRINCIPAL do jogo (migracao gradual para SDL2).

  Esta unit e a "casa" do jogo em SDL2: abre a janela, cria o renderizador, mantem o laco
  principal (eventos -> logica a intervalo fixo -> desenho -> apresentacao) e traduz o teclado.
  A migracao segue por fases (ver MIGRACAO_SDL.md).

  FASE 2 (esta versao): o jogo e a classe TJogo (ChavesJogo.pas), sem formulario. A cada
  passo de IntervaloTimer ms chamamos Jogo.PassoSDL (logica + desenho no buffer 400x300),
  apresentamos esse buffer numa textura SDL e repassamos o teclado do SDL ao jogo (codigos
  fisicos SDL_SCANCODE_*, sem conversao).

  Como executar:
    StreetChaves.exe          jogo na janela SDL
    StreetChaves.exe --demo   quadro de teste da fase 0 (infraestrutura SDL)

  Teclas do host: F11 ou Alt+Enter = alterna tela cheia. No modo --demo: I = escala inteira,
  ESC = sair. No jogo, as demais teclas vao direto ao jogo (ESC sai, como no original). }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, DXTipos, DXClass, sdl2, ChavesConst, ChavesTipos, ChavesJogo, DXFonte, ChavesDados;

type
  { Tecla recebida: Scan = codigo fisico do SDL (SDL_SCANCODE_*) }
  TTeclaSDLEvent = procedure(Scan: Integer; Pressionada: Boolean) of object;

  TAppSDL = class
  private
    FJanela: PSDL_Window;
    FRender: PSDL_Renderer;
    FTextura: PSDL_Texture;
    FPixels: array of Cardinal;        // buffer ARGB (0xAARRGGBB), LarguraTela x AlturaTela
    FRodando: Boolean;
    FJanelaAtiva: Boolean;             // janela com foco (sem foco o jogo pausa e solta as teclas)
    FTelaCheia: Boolean;
    FEscalaInteira: Boolean;
    FTeclas: array[0..511] of Boolean;
    FControle: array[0..1] of PSDL_GameController;   // gamepads dos jogadores 1 e 2
    FJoy: array[0..1] of PSDL_Joystick;              // joysticks genericos (sem mapeamento de gamepad no SDL)
    FControleId: array[0..1] of TSDL_JoystickID;
    FControleBotoes: array[0..1] of Byte;            // Start/Back do passo anterior (para detectar o aperto)
    FIntervaloMs: Integer;             // passo da logica (original: 28 ms)
    FTickDemo: Integer;
    FFrames: Integer;
    FUltimoFps: UInt64;
    FTitulo: string;
    FJogo: TJogo;                      // o jogo (nil = quadro de teste)
    FEsticar: Boolean;                 // modo de tela 3: ocupa a janela toda, sem manter 4:3
    FOnAtualizar: TNotifyEvent;
    FOnDesenhar: TNotifyEvent;
    FOnTecla: TTeclaSDLEvent;
    function GetPixels: Pointer;
    procedure Erro(const Msg: string);
    procedure TratarEvento(var Ev: TSDL_Event);
    procedure AlternarTelaCheia;
    procedure AbrirControle(Indice: Integer);
    procedure FecharControle(IdInstancia: Integer);
    procedure AbrirJoystick(Indice: Integer);
    procedure FecharJoystick(IdInstancia: Integer);
    procedure LerControles;
    procedure LerJoystick(I: Integer);
    function NomeControle(I: Integer): string;
    procedure IniciarJogo;
    procedure AoMudarTela(Sender: TObject);
    procedure AplicarModoTela(Modo: Integer);
    procedure Atualizar;
    procedure Desenhar;
    procedure Apresentar;
    function TeclaAtiva(Scan: Integer): Boolean;
    { quadro de teste da fase 0 }
    procedure Retangulo(X, Y, W, H: Integer; Cor: Cardinal);
    procedure DesenharDemo;
  public
    constructor Create;
    destructor Destroy; override;
    function Iniciar(ComJogo: Boolean): Boolean;
    procedure Executar;
    procedure Parar;
    property IntervaloMs: Integer read FIntervaloMs write FIntervaloMs;
    property Pixels: Pointer read GetPixels;
    property OnAtualizar: TNotifyEvent read FOnAtualizar write FOnAtualizar;
    property OnDesenhar: TNotifyEvent read FOnDesenhar write FOnDesenhar;
    property OnTecla: TTeclaSDLEvent read FOnTecla write FOnTecla;
  end;

{ Ponto de entrada do modo SDL (padrao do StreetChaves.lpr; --demo = quadro de teste) }
procedure ExecutarModoSDL;

implementation

function TAppSDL.GetPixels: Pointer;
begin
  Result := @FPixels[0];
end;

constructor TAppSDL.Create;
begin
  inherited Create;
  FIntervaloMs := 28;
  FJanelaAtiva := True;
  SetLength(FPixels, LarguraTela * AlturaTela);
end;

destructor TAppSDL.Destroy;
begin
  if FJogo <> nil then
  begin
    FJogo.AoMudarTela := nil;
    FJogo.Free;
    FJogo := nil;
  end;
  if FTextura <> nil then SDL_DestroyTexture(FTextura);
  if FRender <> nil then SDL_DestroyRenderer(FRender);
  if FJanela <> nil then SDL_DestroyWindow(FJanela);
  SDL_Quit;
  inherited Destroy;
end;

procedure TAppSDL.Erro(const Msg: string);
begin
  SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, 'Open Street Chaves (SDL)',
    PAnsiChar(AnsiString(Msg)), FJanela);
end;

function TAppSDL.Iniciar(ComJogo: Boolean): Boolean;
var
  Info: TSDL_RendererInfo;
  V: TSDL_Version;
begin
  Result := False;
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_JOYSTICK or SDL_INIT_GAMECONTROLLER) <> 0 then
  begin
    Erro('SDL_Init falhou: ' + string(SDL_GetError));
    Exit;
  end;

  { pixels nitidos ao ampliar (sem suavizacao) }
  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, '0');

  FJanela := SDL_CreateWindow('Open Street Chaves (SDL)', SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED, LarguraTela * 2, AlturaTela * 2,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE);
  if FJanela = nil then
  begin
    Erro('SDL_CreateWindow falhou: ' + string(SDL_GetError));
    Exit;
  end;

  FRender := SDL_CreateRenderer(FJanela, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if FRender = nil then      // sem aceleracao: tenta o renderizador por software
    FRender := SDL_CreateRenderer(FJanela, -1, SDL_RENDERER_SOFTWARE);
  if FRender = nil then
  begin
    Erro('SDL_CreateRenderer falhou: ' + string(SDL_GetError));
    Exit;
  end;

  { o jogo desenha sempre em 400x300; o SDL amplia mantendo a proporcao (faixas pretas) }
  SDL_RenderSetLogicalSize(FRender, LarguraTela, AlturaTela);
  SDL_RenderSetIntegerScale(FRender, SDL_FALSE);

  FTextura := SDL_CreateTexture(FRender, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
    LarguraTela, AlturaTela);
  if FTextura = nil then
  begin
    Erro('SDL_CreateTexture falhou: ' + string(SDL_GetError));
    Exit;
  end;

  SDL_GetVersion(@V);
  FTitulo := 'Open Street Chaves (SDL)';
  if SDL_GetRendererInfo(FRender, @Info) = 0 then
    FTitulo := Format('Open Street Chaves (SDL) - SDL %d.%d.%d - %s',
      [V.major, V.minor, V.patch, string(Info.name)]);
  SDL_SetWindowTitle(FJanela, PAnsiChar(AnsiString(FTitulo)));
  if ComJogo then IniciarJogo;
  Result := True;
end;

{ Cria o jogo (sem formulario) e liga as pontes com o SDL }
procedure TAppSDL.IniciarJogo;
begin
  if not DXFonteDisponivel then
  begin
    Erro('Arquivo Fontes\ComicSansMS.atlas nao encontrado (ou invalido).' + LineEnding +
      'Gere-o uma vez com a ferramenta source\tools\GeraFonte (precisa da fonte Comic Sans MS no Windows).');
    Halt(1);
  end;
  if not FileExists(DXResolvePath(PastaDados + ArqRecursos)) then
  begin
    Erro('Arquivo Dados\' + ArqRecursos + ' nao encontrado.' + LineEnding +
      'A pasta Dados (ao lado do executavel) traz a lista de imagens e sons do jogo.');
    Halt(1);
  end;
  FJanelaAtiva := True;         // o "foco" e da janela SDL
  FJogo := TJogo.Create(nil);
  FJogo.AoMudarTela := AoMudarTela;
  FJogo.Iniciar;
  AplicarModoTela(FJogo.ModoTela);
  SDL_ShowCursor(0);
  FIntervaloMs := IntervaloTimer;
end;

{ O jogo pediu outro modo de tela: 1 = janela, 2 = tela cheia 4:3, 3 = tela cheia esticada }
procedure TAppSDL.AoMudarTela(Sender: TObject);
begin
  AplicarModoTela(FJogo.ModoTela);
end;

procedure TAppSDL.AplicarModoTela(Modo: Integer);
begin
  FEsticar := Modo = 3;
  if Modo = 1 then
  begin
    SDL_SetWindowFullscreen(FJanela, 0);
    FTelaCheia := False;
  end
  else
  begin
    SDL_SetWindowFullscreen(FJanela, SDL_WINDOW_FULLSCREEN_DESKTOP);
    FTelaCheia := True;
  end;
  if FEsticar then SDL_RenderSetLogicalSize(FRender, 0, 0)
  else SDL_RenderSetLogicalSize(FRender, LarguraTela, AlturaTela);
end;

procedure TAppSDL.Parar;
begin
  FRodando := False;
end;

function TAppSDL.TeclaAtiva(Scan: Integer): Boolean;
begin
  Result := (Scan >= 0) and (Scan <= High(FTeclas)) and FTeclas[Scan];
end;

procedure TAppSDL.AlternarTelaCheia;
begin
  FTelaCheia := not FTelaCheia;
  if FTelaCheia then
    SDL_SetWindowFullscreen(FJanela, SDL_WINDOW_FULLSCREEN_DESKTOP)
  else
    SDL_SetWindowFullscreen(FJanela, 0);
end;

procedure TAppSDL.TratarEvento(var Ev: TSDL_Event);
var
  Scan: Integer;
  Baixo: Boolean;
begin
  case Ev.type_ of
    SDL_QUITEV:
      FRodando := False;

    SDL_WINDOWEVENT:
      { ao perder o foco, solta todas as teclas (evita tecla "presa") }
      if Ev.window.event = SDL_WINDOWEVENT_FOCUS_GAINED then FJanelaAtiva := True
      else if Ev.window.event = SDL_WINDOWEVENT_FOCUS_LOST then
      begin
        FJanelaAtiva := False;
        FillChar(FTeclas, SizeOf(FTeclas), 0);
        if FJogo <> nil then FJogo.SoltarTeclas;
      end;

    SDL_CONTROLLERDEVICEADDED: AbrirControle(Ev.cdevice.which);
    SDL_CONTROLLERDEVICEREMOVED: FecharControle(Ev.cdevice.which);
    SDL_JOYDEVICEADDED: AbrirJoystick(Ev.jdevice.which);
    SDL_JOYDEVICEREMOVED: FecharJoystick(Ev.jdevice.which);

    SDL_KEYDOWN, SDL_KEYUP:
      begin
        Scan := Integer(Ev.key.keysym.scancode);
        Baixo := Ev.type_ = SDL_KEYDOWN;
        if (Scan >= 0) and (Scan <= High(FTeclas)) then FTeclas[Scan] := Baixo;

        if Baixo and (Ev.key.repeat_ = 0) then
        begin
          if (Scan = Integer(SDL_SCANCODE_ESCAPE)) and (FJogo = nil) then FRodando := False;
          if Scan = Integer(SDL_SCANCODE_F11) then AlternarTelaCheia;
          if (Scan = Integer(SDL_SCANCODE_RETURN)) and
             ((Ev.key.keysym.mod_ and (KMOD_LALT or KMOD_RALT)) <> 0) then AlternarTelaCheia;
          if (Scan = Integer(SDL_SCANCODE_I)) and (FJogo = nil) then
          begin
            FEscalaInteira := not FEscalaInteira;
            if FEscalaInteira then SDL_RenderSetIntegerScale(FRender, SDL_TRUE)
            else SDL_RenderSetIntegerScale(FRender, SDL_FALSE);
          end;
        end;
        if Assigned(FOnTecla) then FOnTecla(Scan, Baixo);
        { alt+enter e F11 sao do host; o resto vai ao jogo (inclusive repeticao, como no Windows) }
        if (FJogo <> nil) and
           (Scan <> Integer(SDL_SCANCODE_F11)) and
           not ((Scan = Integer(SDL_SCANCODE_RETURN)) and ((Ev.key.keysym.mod_ and (KMOD_LALT or KMOD_RALT)) <> 0)) then
          FJogo.TeclaSDL(Scan, Baixo);
      end;
  end;
end;

{ gamepads: o primeiro conectado e o jogador 1, o segundo e o jogador 2 }
procedure TAppSDL.AbrirControle(Indice: Integer);
var
  C: PSDL_GameController;
  I: Integer;
begin
  if SDL_IsGameController(Indice) = SDL_FALSE then Exit;
  C := SDL_GameControllerOpen(Indice);
  if C = nil then Exit;
  for I := 0 to 1 do
    if (FControle[I] = nil) and (FJoy[I] = nil) then
    begin
      FControle[I] := C;
      FControleId[I] := SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(C));
      FControleBotoes[I] := 0;
      Exit;
    end;
  SDL_GameControllerClose(C);      // ja ha dois controles em uso
end;

procedure TAppSDL.FecharControle(IdInstancia: Integer);
var
  I: Integer;
begin
  for I := 0 to 1 do
    if (FControle[I] <> nil) and (FControleId[I] = IdInstancia) then
    begin
      SDL_GameControllerClose(FControle[I]);
      FControle[I] := nil;
      if FJogo <> nil then FJogo.EntradaControle(I + 1, 0);
    end;
end;

{ joystick generico (o SDL nao conhece o mapeamento): eixos 0/1 ou hat 0, botoes 0..3 = botoes do jogo }
procedure TAppSDL.AbrirJoystick(Indice: Integer);
var
  J: PSDL_Joystick;
  I: Integer;
begin
  if SDL_IsGameController(Indice) <> SDL_FALSE then Exit;     // esse vem por SDL_CONTROLLERDEVICEADDED
  J := SDL_JoystickOpen(Indice);
  if J = nil then Exit;
  for I := 0 to 1 do
    if (FControle[I] = nil) and (FJoy[I] = nil) then
    begin
      FJoy[I] := J;
      FControleId[I] := SDL_JoystickInstanceID(J);
      FControleBotoes[I] := 0;
      Exit;
    end;
  SDL_JoystickClose(J);
end;

procedure TAppSDL.FecharJoystick(IdInstancia: Integer);
var
  I: Integer;
begin
  for I := 0 to 1 do
    if (FJoy[I] <> nil) and (FControleId[I] = IdInstancia) then
    begin
      SDL_JoystickClose(FJoy[I]);
      FJoy[I] := nil;
      if FJogo <> nil then FJogo.EntradaControle(I + 1, 0);
    end;
end;

function TAppSDL.NomeControle(I: Integer): string;
begin
  Result := '-';
  if FControle[I] <> nil then Result := 'gamepad ' + string(SDL_GameControllerName(FControle[I]))
  else if FJoy[I] <> nil then Result := 'joystick ' + string(SDL_JoystickName(FJoy[I]));
end;

procedure TAppSDL.LerJoystick(I: Integer);
const
  Limite = 16000;
var
  J: PSDL_Joystick;
  Bits, Bt, H: Byte;
  Ax, Ay, B: Integer;
begin
  J := FJoy[I];
  Bits := 0;
  Ax := 0;
  Ay := 0;
  if SDL_JoystickNumAxes(J) >= 2 then
  begin
    Ax := SDL_JoystickGetAxis(J, 0);
    Ay := SDL_JoystickGetAxis(J, 1);
  end;
  H := 0;
  if SDL_JoystickNumHats(J) > 0 then H := SDL_JoystickGetHat(J, 0);
  if ((H and SDL_HAT_UP) <> 0) or (Ay < -Limite) then Bits := Bits or 1;
  if ((H and SDL_HAT_DOWN) <> 0) or (Ay > Limite) then Bits := Bits or 2;
  if ((H and SDL_HAT_LEFT) <> 0) or (Ax < -Limite) then Bits := Bits or 4;
  if ((H and SDL_HAT_RIGHT) <> 0) or (Ax > Limite) then Bits := Bits or 8;
  for B := 0 to 3 do
    if (B < SDL_JoystickNumButtons(J)) and (SDL_JoystickGetButton(J, B) <> 0) then
      Bits := Bits or (16 shl B);
  FJogo.EntradaControle(I + 1, Bits);

  { botoes 8 = Back (moeda) e 9 = Start, como nos controles DirectInput comuns }
  Bt := 0;
  if (SDL_JoystickNumButtons(J) > 9) and (SDL_JoystickGetButton(J, 9) <> 0) then Bt := Bt or 1;
  if (SDL_JoystickNumButtons(J) > 8) and (SDL_JoystickGetButton(J, 8) <> 0) then Bt := Bt or 2;
  if ((Bt and 1) <> 0) and ((FControleBotoes[I] and 1) = 0) then
  begin
    FJogo.TeclaSDL(Integer(SDL_SCANCODE_1) + I, True);
    FJogo.TeclaSDL(Integer(SDL_SCANCODE_1) + I, False);
  end;
  if ((Bt and 2) <> 0) and ((FControleBotoes[I] and 2) = 0) then
  begin
    FJogo.TeclaSDL(Integer(SDL_SCANCODE_5), True);
    FJogo.TeclaSDL(Integer(SDL_SCANCODE_5), False);
  end;
  FControleBotoes[I] := Bt;
end;

{ converte direcional/analogico esquerdo/botoes em bits do jogo e entrega ao jogo.
  A=botao 1, B=botao 2, X=botao 3, Y=botao 4; Start = ficha de jogador (1 ou 2); Back = moeda. }
procedure TAppSDL.LerControles;
const
  Limite = 16000;
var
  I: Integer;
  C: PSDL_GameController;
  Bits, Bt: Byte;
  Ax, Ay: Integer;
begin
  if FJogo = nil then Exit;
  for I := 0 to 1 do
  begin
    C := FControle[I];
    if C = nil then
    begin
      if FJoy[I] <> nil then LerJoystick(I);
      Continue;
    end;
    Bits := 0;
    Ax := SDL_GameControllerGetAxis(C, SDL_CONTROLLER_AXIS_LEFTX);
    Ay := SDL_GameControllerGetAxis(C, SDL_CONTROLLER_AXIS_LEFTY);
    if (SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_DPAD_UP) <> 0) or (Ay < -Limite) then Bits := Bits or 1;
    if (SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_DPAD_DOWN) <> 0) or (Ay > Limite) then Bits := Bits or 2;
    if (SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_DPAD_LEFT) <> 0) or (Ax < -Limite) then Bits := Bits or 4;
    if (SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_DPAD_RIGHT) <> 0) or (Ax > Limite) then Bits := Bits or 8;
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_A) <> 0 then Bits := Bits or 16;
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_B) <> 0 then Bits := Bits or 32;
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_X) <> 0 then Bits := Bits or 64;
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_Y) <> 0 then Bits := Bits or 128;
    FJogo.EntradaControle(I + 1, Bits);

    Bt := 0;                                           // bit 1 = Start, bit 2 = Back
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_START) <> 0 then Bt := Bt or 1;
    if SDL_GameControllerGetButton(C, SDL_CONTROLLER_BUTTON_BACK) <> 0 then Bt := Bt or 2;
    if ((Bt and 1) <> 0) and ((FControleBotoes[I] and 1) = 0) then
    begin
      FJogo.TeclaSDL(Integer(SDL_SCANCODE_1) + I, True);
      FJogo.TeclaSDL(Integer(SDL_SCANCODE_1) + I, False);
    end;
    if ((Bt and 2) <> 0) and ((FControleBotoes[I] and 2) = 0) then
    begin
      FJogo.TeclaSDL(Integer(SDL_SCANCODE_5), True);
      FJogo.TeclaSDL(Integer(SDL_SCANCODE_5), False);
    end;
    FControleBotoes[I] := Bt;
  end;
end;

procedure TAppSDL.Atualizar;
begin
  if FJanelaAtiva then LerControles;
  Inc(FTickDemo);
  if FJogo <> nil then
  begin
    if FJanelaAtiva then FJogo.PassoSDL;   // como o TDXTimer com ActiveOnly: pausa sem foco
    FIntervaloMs := IntervaloTimer;      // as teclas - e = mudam a velocidade
    if FIntervaloMs < 1 then FIntervaloMs := 1;
  end;
  if Assigned(FOnAtualizar) then FOnAtualizar(Self);
end;

procedure TAppSDL.Retangulo(X, Y, W, H: Integer; Cor: Cardinal);
var
  I, J: Integer;
begin
  for J := Y to Y + H - 1 do
  begin
    if (J < 0) or (J >= AlturaTela) then Continue;
    for I := X to X + W - 1 do
      if (I >= 0) and (I < LarguraTela) then FPixels[J * LarguraTela + I] := Cor;
  end;
end;

{ quadro de teste: degrade, barras de cor, quadrado que se move a cada passo de 28 ms e
  uma fileira de indicadores de teclado (jogador 1 e jogador 2) }
procedure TAppSDL.DesenharDemo;
const
  P1: array[0..7] of Integer = (Integer(SDL_SCANCODE_UP), Integer(SDL_SCANCODE_DOWN), Integer(SDL_SCANCODE_LEFT),
    Integer(SDL_SCANCODE_RIGHT), Integer(SDL_SCANCODE_Z), Integer(SDL_SCANCODE_X), Integer(SDL_SCANCODE_C),
    Integer(SDL_SCANCODE_V));
  P2: array[0..7] of Integer = (Integer(SDL_SCANCODE_W), Integer(SDL_SCANCODE_S), Integer(SDL_SCANCODE_A),
    Integer(SDL_SCANCODE_D), Integer(SDL_SCANCODE_R), Integer(SDL_SCANCODE_T), Integer(SDL_SCANCODE_Y),
    Integer(SDL_SCANCODE_U));
  Barras: array[0..5] of Cardinal = ($FFFF0000, $FF00FF00, $FF0000FF, $FFFFFF00, $FFFF00FF, $FF00FFFF);
var
  X, Y, I, Px: Integer;
  G: Cardinal;
begin
  for Y := 0 to AlturaTela - 1 do
  begin
    G := Cardinal(Y * 255 div (AlturaTela - 1));
    for X := 0 to LarguraTela - 1 do
      FPixels[Y * LarguraTela + X] := $FF000000 or (G shr 1) or ((G shr 2) shl 8) or (G shl 16);
  end;

  for I := 0 to High(Barras) do
    Retangulo(20 + I * 60, 20, 50, 60, Barras[I]);

  { borda de 1 pixel em volta da tela: confere o enquadramento 400x300 }
  Retangulo(0, 0, LarguraTela, 1, $FFFFFFFF);
  Retangulo(0, AlturaTela - 1, LarguraTela, 1, $FFFFFFFF);
  Retangulo(0, 0, 1, AlturaTela, $FFFFFFFF);
  Retangulo(LarguraTela - 1, 0, 1, AlturaTela, $FFFFFFFF);

  { quadrado em movimento: 1 volta a cada ~ 7 s no passo de 28 ms }
  Px := (FTickDemo * 2) mod (2 * (LarguraTela - 40));
  if Px >= LarguraTela - 40 then Px := 2 * (LarguraTela - 40) - Px;
  Retangulo(Px + 10, 120, 20, 20, $FFFFFFFF);

  for I := 0 to 7 do
  begin
    if TeclaAtiva(P1[I]) then G := $FFFFFF00 else G := $FF404040;
    Retangulo(40 + I * 40, 200, 30, 30, G);
    if TeclaAtiva(P2[I]) then G := $FF00FFFF else G := $FF404040;
    Retangulo(40 + I * 40, 240, 30, 30, G);
  end;
end;

procedure TAppSDL.Desenhar;
begin
  if Assigned(FOnDesenhar) then FOnDesenhar(Self) else DesenharDemo;
end;

procedure TAppSDL.Apresentar;
var
  Fonte: Pointer;
  Dst: TSDL_Rect;
  W, H: Integer;
begin
  Fonte := @FPixels[0];
  if FJogo <> nil then Fonte := FJogo.PixelsSDL;
  SDL_UpdateTexture(FTextura, nil, Fonte, LarguraTela * SizeOf(Cardinal));
  SDL_RenderClear(FRender);
  if FJogo = nil then
    SDL_RenderCopy(FRender, FTextura, nil, nil)
  else if FEsticar then
  begin
    { tela cheia esticada: ocupa a janela toda; o deslocamento (, e .) e proporcional }
    SDL_GetRendererOutputSize(FRender, @W, @H);
    Dst.x := FJogo.DeslocamentoX * W div LarguraTela;
    Dst.y := 0;
    Dst.w := W;
    Dst.h := H;
    SDL_RenderCopy(FRender, FTextura, nil, @Dst);
  end
  else
  begin
    Dst.x := FJogo.DeslocamentoX;
    Dst.y := 0;
    Dst.w := LarguraTela;
    Dst.h := AlturaTela;
    SDL_RenderCopy(FRender, FTextura, nil, @Dst);
  end;
  SDL_RenderPresent(FRender);
end;

procedure TAppSDL.Executar;
var
  Ev: TSDL_Event;
  Freq, Agora, Ultimo: UInt64;
  Acum: Double;
begin
  Freq := SDL_GetPerformanceFrequency;
  Ultimo := SDL_GetPerformanceCounter;
  FUltimoFps := Ultimo;
  Acum := 0;
  FRodando := True;
  while FRodando do
  begin
    while SDL_PollEvent(@Ev) <> 0 do TratarEvento(Ev);
    if FJogo <> nil then
    begin
      if FJogo.Sair then FRodando := False;       // o jogo pediu para sair (ESC)
    end;

    Agora := SDL_GetPerformanceCounter;
    Acum := Acum + (Agora - Ultimo) * 1000.0 / Freq;
    Ultimo := Agora;
    if Acum > 250 then Acum := 250;                // apos travamento nao tenta "recuperar" tudo
    while Acum >= FIntervaloMs do
    begin
      Atualizar;
      Acum := Acum - FIntervaloMs;
    end;

    Desenhar;
    Apresentar;
    Inc(FFrames);
    if Agora - FUltimoFps >= Freq then          // a cada segundo mostra os quadros/s no titulo
    begin
      SDL_SetWindowTitle(FJanela, PAnsiChar(AnsiString(Format('%s - %d fps - controles: %s / %s',
        [FTitulo, FFrames, NomeControle(0), NomeControle(1)]))));
      FFrames := 0;
      FUltimoFps := Agora;
    end;
    SDL_Delay(1);                                   // cede CPU quando o vsync nao bloqueia
  end;
end;

procedure ExecutarModoSDL;
var
  App: TAppSDL;
begin
  App := TAppSDL.Create;
  try
    if App.Iniciar(not ((ParamCount > 0) and SameText(ParamStr(1), '--demo'))) then App.Executar;
  finally
    App.Free;
  end;
end;

end.
