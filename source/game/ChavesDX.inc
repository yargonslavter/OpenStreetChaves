{ GERADO por gen2/mkdx.py - cria em codigo os componentes DelphiX (antes no .lfm).
  Mantem o .lfm so com componentes padrao, para abrir no designer sem instalar nada. }

procedure AddImagem(L: TDXImageList; const N, F: string; Transp: Boolean; TC: TColor; PW, PH: Integer);
begin
  with L.Items.Add do
  begin
    Name := N;
    FileName := F;
    Transparent := Transp;
    TransparentColor := TC;
    PatternWidth := PW;
    PatternHeight := PH;
  end;
end;

procedure AddSom(L: TDXWaveList; const N, F: string; Loop: Boolean; Max: Integer);
begin
  with L.Items.Add do
  begin
    Name := N;
    FileName := F;
    Looped := Loop;
    MaxPlayingCount := Max;
  end;
end;

procedure TForm1.CriaComponentesDX;
begin
  DXDraw1 := TDXDraw.Create(Self);
  with DXDraw1 do
  begin
    Parent := Self;
    SetBounds(0, 0, 100, 100);
    AutoInitialize := True;
    AutoSize := True;
    Color := clBtnFace;
    Display.BitCount := 16;
    Display.FixedBitCount := True;
    Display.FixedRatio := True;
    Display.FixedSize := False;
    Display.Height := 300;
    Display.Width := 400;
    Options := [doAllowReboot, doWaitVBlank, doCenter, doRetainedMode, doHardware, doSelectDriver];
    SurfaceHeight := 100;
    SurfaceWidth := 100;
    TabOrder := 0;
    OnMouseMove := DXDraw1MouseMove;
    Initialize;
  end;

  DXInput1 := TDXInput.Create(Self);
  with DXInput1 do
  begin
    ActiveOnly := True;
    Joystick.BindInputStates := True;
    Joystick.Enabled := True;
    Joystick.ForceFeedback := False;
    Keyboard.BindInputStates := True;
    Keyboard.Enabled := True;
    Keyboard.ForceFeedback := False;
    Mouse.BindInputStates := False;
    Mouse.Enabled := False;
    Mouse.ForceFeedback := False;
    UseDirectInput := True;
  end;

  DXSound1 := TDXSound.Create(Self);
  DXSound1.AutoInitialize := False;
  DXSound1.Options := [];

  DXImageListRetrato := TDXImageList.Create(Self);
  DXImageListRetrato.DXDraw := DXDraw1;
  DXImageListEfeitos := TDXImageList.Create(Self);
  DXImageListEfeitos.DXDraw := DXDraw1;
  DXWaveListSnd := TDXWaveList.Create(Self);
  DXWaveListSnd.DXSound := DXSound1;
  DXWaveListSnd.Start;
  DXImageListCenario := TDXImageList.Create(Self);
  DXImageListCenario.DXDraw := DXDraw1;
  AddImagem(DXImageListCenario, 'Cenario', '', False, clBlack, 0, 0);
  DXImageListIcone := TDXImageList.Create(Self);
  DXImageListIcone.DXDraw := DXDraw1;
  AddImagem(DXImageListIcone, 'Icone-01-Cima', 'source/Embutidos/DXImageListIcone__00_Icone-01-Cima.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-02-Baixo', 'source/Embutidos/DXImageListIcone__01_Icone-02-Baixo.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-03-Direita', 'source/Embutidos/DXImageListIcone__02_Icone-03-Direita.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-04-Esquerda', 'source/Embutidos/DXImageListIcone__03_Icone-04-Esquerda.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-05-Diagonal1', 'source/Embutidos/DXImageListIcone__04_Icone-05-Diagonal1.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-06-Diagonal2', 'source/Embutidos/DXImageListIcone__05_Icone-06-Diagonal2.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-07-Mesa', 'source/Embutidos/DXImageListIcone__06_Icone-07-Mesa.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-08-ESPECIAL', 'source/Embutidos/DXImageListIcone__07_Icone-08-ESPECIAL.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-09-Select', 'source/Embutidos/DXImageListIcone__08_Icone-09-Select.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-10-Rosto Secreto', 'source/Embutidos/DXImageListIcone__09_Icone-10-Rosto_Secreto.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-11-X', 'source/Embutidos/DXImageListIcone__10_Icone-11-X.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-12-Logo Transparente', 'source/Embutidos/DXImageListIcone__11_Icone-12-Logo_Transparente.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-13-Logo Transparente', 'source/Embutidos/DXImageListIcone__12_Icone-13-Logo_Transparente.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListIcone, 'Icone-14-Teste de forca', 'source/Embutidos/DXImageListIcone__13_Icone-14-Teste_de_forca.bmp', True, clWhite, 0, 0);
  DXWaveListMusica := TDXWaveList.Create(Self);
  DXWaveListMusica.DXSound := DXSound1;
  DXWaveListMusica.Start;
  AddSom(DXWaveListMusica, 'Musica', 'source/Embutidos/Musica.wav', True, 0);
  DXWaveListVitoria := TDXWaveList.Create(Self);
  DXWaveListVitoria.DXSound := DXSound1;
  DXWaveListVitoria.Start;
  DXImageListLutador := TDXImageList.Create(Self);
  DXImageListLutador.DXDraw := DXDraw1;
  DXImageListLutadorInvert := TDXImageList.Create(Self);
  DXImageListLutadorInvert.DXDraw := DXDraw1;
  DXImageListAbertura := TDXImageList.Create(Self);
  DXImageListAbertura.DXDraw := DXDraw1;
  AddImagem(DXImageListAbertura, 'Predio-01-a', 'source/Embutidos/DXImageListAbertura__00_Predio-01-a.bmp', False, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Predio-01-b', 'source/Embutidos/DXImageListAbertura__01_Predio-01-b.bmp', False, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Predio-02-a', 'source/Embutidos/DXImageListAbertura__02_Predio-02-a.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Predio-02-b', 'source/Embutidos/DXImageListAbertura__03_Predio-02-b.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Folhagem', 'source/Embutidos/DXImageListAbertura__04_Folhagem.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Pessoa-01', 'source/Embutidos/DXImageListAbertura__05_Pessoa-01.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Pessoa-02', 'source/Embutidos/DXImageListAbertura__06_Pessoa-02.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Pessoa-03', 'source/Embutidos/DXImageListAbertura__07_Pessoa-03.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Chaves', 'source/Embutidos/DXImageListAbertura__08_Chaves.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Seu Madruga', 'source/Embutidos/DXImageListAbertura__09_Seu_Madruga.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Chaves dando soco', 'source/Embutidos/DXImageListAbertura__10_Chaves_dando_soco.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Seu Madruga caindo', 'source/Embutidos/DXImageListAbertura__11_Seu_Madruga_caindo.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Logo - PORTUGUES', 'source/Embutidos/DXImageListAbertura__12_Logo_-_PORTUGUES.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Logo - ESPANHOL', 'source/Embutidos/DXImageListAbertura__13_Logo_-_ESPANHOL.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Vencedores', 'source/Embutidos/DXImageListAbertura__14_Vencedores.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListAbertura, 'Cybergamba', 'source/Embutidos/DXImageListAbertura__15_Cybergamba.bmp', True, clWhite, 0, 0);
  DXImageListFinal := TDXImageList.Create(Self);
  DXImageListFinal.DXDraw := DXDraw1;
  AddImagem(DXImageListFinal, 'Violao', 'source/Embutidos/DXImageListFinal__00_Violao.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Madruga-Violao', 'source/Embutidos/DXImageListFinal__01_Madruga-Violao.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Quico-Urso', 'source/Embutidos/DXImageListFinal__02_Quico-Urso.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Chaves-Urso', 'source/Embutidos/DXImageListFinal__03_Chaves-Urso.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Paty-Urso', 'source/Embutidos/DXImageListFinal__04_Paty-Urso.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Chaves-Bola', 'source/Embutidos/DXImageListFinal__05_Chaves-Bola.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Madruga-Machucado', 'source/Embutidos/DXImageListFinal__06_Madruga-Machucado.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Girafales-Flores', 'source/Embutidos/DXImageListFinal__07_Girafales-Flores.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Madruga-Velho do saco', 'source/Embutidos/DXImageListFinal__08_Madruga-Velho_do_saco.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Chaves-Gordo', 'source/Embutidos/DXImageListFinal__09_Chaves-Gordo.bmp', True, clWhite, 0, 0);
  AddImagem(DXImageListFinal, 'Prato vazio', 'source/Embutidos/DXImageListFinal__10_Prato_vazio.bmp', True, clWhite, 0, 0);
  DXImageListAnimacao := TDXImageList.Create(Self);
  DXImageListAnimacao.DXDraw := DXDraw1;
  DXImageListEfeitosInvert := TDXImageList.Create(Self);
  DXImageListEfeitosInvert.DXDraw := DXDraw1;
  DXTimer1 := TDXTimer.Create(Self);
  DXTimer1.ActiveOnly := True;
  DXTimer1.Interval := 1;
  DXTimer1.OnTimer := DXTimer1Timer;
  DXTimer1.Enabled := True;
  DXTimer1.Start;
end;
