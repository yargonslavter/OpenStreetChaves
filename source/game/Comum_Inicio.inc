{ Comum_Inicio.inc - Ciclo de vida do jogo: construtor, destrutor e Iniciar (antigo FormCreate). }

constructor TJogo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IniciarEntrada;
  MemoNomes := TTextoLista.Create;
  MemoTexto := TTextoLista.Create;
  MemoConfig := TTextoLista.Create;
  MemoFrases := TTextoLista.Create;
  MemoDialogo := TTextoLista.Create;
  MemoFinais := TTextoLista.Create;
  MemoCenarios := TTextoLista.Create;
  MemoConfigSalvo := TTextoLista.Create;
  ModoTela := 1;
end;

destructor TJogo.Destroy;
begin
  FreeAndNil(FFrameSheet);
  MemoNomes.Free;
  MemoTexto.Free;
  MemoConfig.Free;
  MemoFrases.Free;
  MemoDialogo.Free;
  MemoFinais.Free;
  MemoCenarios.Free;
  MemoConfigSalvo.Free;
  ImgRetrato.Free;
  ImgEfeitos.Free;
  ImgCenario.Free;
  ImgIcone.Free;
  ImgLutador.Free;
  ImgLutadorInvert.Free;
  ImgAbertura.Free;
  ImgFinal.Free;
  ImgAnimacao.Free;
  ImgEfeitosInvert.Free;
  Tela.Free;
  SomEfeitos.Free;
  SomMusica.Free;
  SomVitoria.Free;
  inherited Destroy;
end;

{ Inicializacao do jogo (antes era o FormCreate): cria os componentes DelphiX, carrega
  textos e recursos e deixa tudo pronto para o primeiro quadro. }
procedure TJogo.Iniciar;
var
  I, K: Integer;
  Nome: string;
  Ok: Boolean;
begin
  CriaComponentesDX;
  FFrameSheet := nil;
  { o original procurava os arquivos na pasta corrente: vamos para a pasta do jogo }
  Nome := DXResolvePath('Cenarios/Cenario-01.bmp');
  if FileExists(Nome) then SetCurrentDir(ExtractFilePath(ExtractFileDir(Nome)));

  Randomize;
  CheatChurros := 0;
  CheatGentalha := 0;
  CheatSatanas := 0;
  BonusEnergeticos := 0;
  CheatFadiga := 0;
  CheatMentecapto := 0;
  CheatBruxa := 0;
  CenarioSecreto := 0;
  { "truques" liberados pela simples existencia de arquivos .dat na pasta do jogo }
  if FileExists('Churros.dat') then CheatChurros := 1;
  if FileExists('Gentalha.dat') then CheatGentalha := 1;
  if FileExists('Energeticos.dat') then BonusEnergeticos := 0.15;
  if FileExists('Satanas.dat') then CheatSatanas := 1;
  if FileExists('Fadiga.dat') then CheatFadiga := 1;
  if FileExists('Mentecapto.dat') then CheatMentecapto := 1;
  if FileExists('Bruxa.dat') then CheatBruxa := 1;
  for I := 1 to 12 do
  begin
    if I < 10 then
      if FileExists('SC0' + IntToStr(I) + '.dat') then CenarioSecreto := I;
    if I >= 10 then
      if FileExists('SC' + IntToStr(I) + '.dat') then CenarioSecreto := I;
  end;

  Versao := 'V1.5A';
  Indef_4488 := 0;
  Indef_448C := 0;
  Indef_4490 := 0;
  LogoMeiaAltura := 0;
  Estado := CHS_RESOLUCAO;
  ContPisca := 0;
  TempoEstado := 0;
  CameraX := 0;
  CameraY := 0;
  FaseSelecao := 1;
  CursorMenu := 1;
  ContagemSeg := 30;
  ContagemTick := 25;
  TempoDialogo := 0;
  Depurar := 0;
  MostrarCaixas := 0;
  PassoAPasso := 0;
  Pausado := 0;
  TempoDemo := 0;
  Voador.Alcance := 330;
  GanhoCarga := 2.0;
  MusicaPendente := 0;
  RoundAtual := 1;
  Fase := 1;
  FaseIntro := 0;
  FaseFim := 0;
  RelogioParado := 1;
  for I := 1 to 2 do
    with Lutador[I] do
    begin
      CargaPoder := 0;
      Poder := 0;
      RoundsVencidos := 0;
      Pontos := 0;
      for K := 1 to 8 do Adversarios[K] := 1;
    end;
  IntervaloTimer := 28;
  Gravidade := 4;
  ModoPoder := 1;
  NivelJogo := 4;
  NivelDano := 0.9;
  Sangue := 1;
  NumRounds := 2;
  TempoRound := 3;
  Idioma := 1;
  Flash := 1;
  MostrarNivel := 1;
  MostrarCreditos := 1;

  { configuracao salva (Chaves.dat) }
  if FileExists('Chaves.dat') then
  begin
    MemoConfigSalvo.Lines.Clear;
    MemoConfigSalvo.Lines.LoadFromFile('Chaves.dat');
    with MemoConfigSalvo.Lines do
    begin
      if Count >= 1 then NivelJogo := StrToIntDef(Strings[0], NivelJogo);
      if Count >= 2 then
      begin
        if Strings[1] = '1' then TempoRound := 1;
        if Strings[1] = '2' then TempoRound := 2;
        if Strings[1] = '3' then TempoRound := 3;
        if Strings[1] = '4' then TempoRound := 4;
      end;
      if Count >= 3 then ModoPoder := StrToIntDef(Strings[2], ModoPoder);
      if Count >= 4 then NivelDano := StrToFloatDef(Strings[3], NivelDano);
      if Count >= 5 then
      begin
        if Strings[4] = '0' then Sangue := 0;
        if Strings[4] = '1' then Sangue := 1;
      end;
      if Count >= 6 then NumRounds := StrToIntDef(Strings[5], NumRounds);
      if Count >= 7 then Idioma := StrToIntDef(Strings[6], Idioma);
      if Count >= 8 then
      begin
        if Strings[7] = '0' then Flash := 0;
        if Strings[7] = '1' then Flash := 1;
      end;
      if Count >= 9 then
      begin
        if Strings[8] = '0' then MostrarNivel := 0;
        if Strings[8] = '1' then MostrarNivel := 1;
      end;
      if Count >= 10 then
      begin
        if Strings[9] = '0' then MostrarCreditos := 0;
        if Strings[9] = '1' then MostrarCreditos := 1;
      end;
    end;
  end;
  if NivelJogo < 1 then NivelJogo := 1;
  if NivelJogo > 8 then NivelJogo := 8;
  if TempoRound < 1 then TempoRound := 1;
  if TempoRound > 4 then TempoRound := 4;
  if ModoPoder < 1 then ModoPoder := 1;
  if ModoPoder > 4 then ModoPoder := 4;
  if NivelDano < 0.3 then NivelDano := 0.3;
  if NivelDano > 2 then NivelDano := 2.0;
  if NumRounds < 1 then NumRounds := 1;
  if NumRounds > 3 then NumRounds := 3;
  if Idioma < 1 then Idioma := 1;
  if Idioma > 2 then Idioma := 2;

  { textos no idioma escolhido }
  CarregarTextos(Idioma, MemoNomes.Lines, MemoTexto.Lines, MemoConfig.Lines,
    MemoFrases.Lines, MemoDialogo.Lines, MemoFinais.Lines, MemoCenarios.Lines);

  Fichas := 0;                    // fichas (creditos)
  Lutador[1].Personagem := 1;
  Lutador[2].Personagem := 2;
  Lutador[1].Ativo := 0;
  Lutador[2].Ativo := 0;
  Lutador[1].Escolheu := 0;
  Lutador[2].Escolheu := 0;
  zerardados(1);
  zerardados(2);
  criarecorde(1, 'CHV', 1, 10000);
  criarecorde(2, 'SMD', 2, 8000);
  criarecorde(3, 'CHQ', 3, 7500);
  criarecorde(4, 'QUI', 4, 7000);
  criarecorde(5, 'DFL', 5, 6500);
  criarecorde(6, 'PGR', 6, 6000);
  criarecorde(7, 'SBR', 7, 5500);
  criarecorde(8, 'B71', 8, 5000);
  criarecorde(9, 'PTY', 9, 4500);
  criarecorde(10, 'NHO', 10, 4000);
  ordenarecordista;

  AplicarResolucao(1);

  { recursos externos }
  for I := 1 to 78 do
    carregaranimacao(NomeNN('Animacoes/Anim-', '.bmp', I));
  for I := 1 to 102 do
  begin
    if I < 10 then carregarefeitos('Efeitos/Efeito-00' + IntToStr(I) + '.bmp');
    if (I >= 10) and (I < 100) then carregarefeitos('Efeitos/Efeito-0' + IntToStr(I) + '.bmp');
    if I >= 100 then carregarefeitos('Efeitos/Efeito-' + IntToStr(I) + '.bmp');
  end;

  { efeitos sonoros: Som-01.wav, Som-02.wav ... (o original carrega ate o primeiro faltante) }
  I := 1;
  Nome := NomeNN('Sons/Som-', '.wav', I);
  while FileExists(Nome) do
  begin
    Nome := NomeNN('Sons/Som-', '.wav', I);
    carregareftsonoro(Nome);
    Inc(I);
  end;
  QtdSons := I;
  if QtdSons > 3 then QtdSons := QtdSons - 2;

  { musicas: so conta quantas existem (Musica-01.wav ...) }
  I := 1;
  Nome := NomeNN('Musicas/Musica-', '.wav', I);
  while FileExists(Nome) do
  begin
    Nome := NomeNN('Musicas/Musica-', '.wav', I);
    Inc(I);
  end;
  QtdMusicas := I;
  if QtdMusicas > 3 then QtdMusicas := QtdMusicas - 2;

  for I := 1 to 15 do
  begin
    carregarfala(NomeNN('Falas/Fala-', '-a.wav', I));
    carregarfala(NomeNN('Falas/Fala-', '-b.wav', I));
  end;

  { rostos: a, a(espelhado), b, b(espelhado), c }
  for I := 1 to 15 do
  begin
    carregarosto(NomeNN('Rostos/R', '-a.bmp', I), 1);
    carregarosto(NomeNN('Rostos/R', '-a.bmp', I), 2);
    carregarosto(NomeNN('Rostos/R', '-b.bmp', I), 1);
    carregarosto(NomeNN('Rostos/R', '-b.bmp', I), 2);
    carregarosto(NomeNN('Rostos/R', '-c.bmp', I), 1);
  end;

  { quadros dos lutadores: 150 posicoes (2 jogadores x 75) em cada lista }
  for I := 1 to 150 do
  begin
    ImgLutador.Adicionar;
    ImgLutadorInvert.Adicionar;
  end;

  SomIniciar;
  Ok := True;
  if Ok then QuadroAtivo := True;
end;
