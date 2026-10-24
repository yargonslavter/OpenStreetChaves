{ Comum_Inicio.inc - Ciclo de vida do jogo: construtor, destrutor e Iniciar (antigo FormCreate). }

constructor TJogo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IniciarEntrada;
  TxtNomes := TStringList.Create;
  TxtGeral := TStringList.Create;
  TxtConfig := TStringList.Create;
  TxtFrases := TStringList.Create;
  TxtDialogo := TStringList.Create;
  TxtFinais := TStringList.Create;
  TxtCenarios := TStringList.Create;
  FVolumes := TStringList.Create;
  ModoTela := 1;
end;

destructor TJogo.Destroy;
begin
  FreeAndNil(FFrameSheet);
  TxtNomes.Free;
  TxtGeral.Free;
  TxtConfig.Free;
  TxtFrases.Free;
  TxtDialogo.Free;
  TxtFinais.Free;
  TxtCenarios.Free;
  FVolumes.Free;
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

{ Le a configuracao da tela F1 da secao Secao (valores ausentes ou invalidos mantem os atuais). }
procedure TJogo.LerConfiguracao(Ini: TCustomIniFile; const Secao: string);

  { liga/desliga gravado como 0 ou 1; outro valor mantem o atual }
  function ZeroOuUm(const Chave: string; Atual: Boolean): Boolean;
  var
    V: Integer;
  begin
    V := Ini.ReadInteger(Secao, Chave, Ord(Atual));
    if (V = 0) or (V = 1) then Result := V = 1 else Result := Atual;
  end;

begin
  NivelJogo := Ini.ReadInteger(Secao, 'NivelJogo', NivelJogo);
  TempoRound := Ini.ReadInteger(Secao, 'TempoRound', TempoRound);
  ModoPoder := Ini.ReadInteger(Secao, 'ModoPoder', ModoPoder);
  NivelDano := LerDecimal(Ini, Secao, 'NivelDano', NivelDano);
  Sangue := ZeroOuUm('Sangue', Sangue);
  NumRounds := Ini.ReadInteger(Secao, 'NumRounds', NumRounds);
  Idioma := Ini.ReadInteger(Secao, 'Idioma', Idioma);
  Flash := ZeroOuUm('Flash', Flash);
  MostrarNivel := ZeroOuUm('MostrarNivel', MostrarNivel);
  MostrarCreditos := ZeroOuUm('MostrarCreditos', MostrarCreditos);
end;

{ Inicializacao do jogo (antes era o FormCreate): cria os objetos, le Dados/Jogo.ini e a
  configuracao salva, carrega textos e recursos e deixa tudo pronto para o primeiro quadro. }
procedure TJogo.Iniciar;
var
  I, K: Integer;
  Nome: string;
  Ini: TMemIniFile;
  Partes: TStringList;
begin
  CriaComponentes;
  FFrameSheet := nil;
  { o original procurava os arquivos na pasta corrente: vamos para a pasta do jogo }
  Nome := ResolverCaminho(PastaDados + ArqRecursos);
  if FileExists(Nome) then SetCurrentDir(ExtractFilePath(ExtractFileDir(Nome)));

  Randomize;
  CheatChurros := False;
  CheatGentalha := False;
  CheatSatanas := False;
  BonusEnergeticos := 0;
  CheatFadiga := False;
  CheatMentecapto := False;
  CheatBruxa := False;
  CenarioSecreto := 0;
  { "truques" liberados pela simples existencia de arquivos .dat na pasta do jogo }
  if FileExists('Churros.dat') then CheatChurros := True;
  if FileExists('Gentalha.dat') then CheatGentalha := True;
  if FileExists('Energeticos.dat') then BonusEnergeticos := 0.15;
  if FileExists('Satanas.dat') then CheatSatanas := True;
  if FileExists('Fadiga.dat') then CheatFadiga := True;
  if FileExists('Mentecapto.dat') then CheatMentecapto := True;
  if FileExists('Bruxa.dat') then CheatBruxa := True;

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
  Depurar := False;
  MostrarCaixas := False;
  PassoAPasso := False;
  Pausado := False;
  TempoDemo := 0;
  MusicaPendente := False;
  RoundAtual := 1;
  Fase := 1;
  FaseIntro := 0;
  FaseFim := 0;
  RelogioParado := True;
  for I := 1 to 2 do
    with Lutador[I] do
    begin
      CargaPoder := 0;
      Poder := 0;
      RoundsVencidos := 0;
      Pontos := 0;
      for K := 1 to 8 do Adversarios[K] := 1;
    end;

  { valores do jogo e padroes da configuracao (Dados/Jogo.ini); o valor entre parenteses e o do
    jogo original, usado se a chave faltar }
  Partes := TStringList.Create;
  Ini := AbrirDados(ArqJogo);
  try
    Versao := Ini.ReadString('Jogo', 'Versao', 'V1.5A');
    IntervaloTimer := Ini.ReadInteger('Jogo', 'IntervaloTimer', 28);
    Gravidade := Ini.ReadInteger('Jogo', 'Gravidade', 4);
    GanhoCarga := LerDecimal(Ini, 'Jogo', 'GanhoCarga', 2.0);
    Voador.Alcance := Ini.ReadInteger('Jogo', 'AlcanceVoador', 330);
    NivelJogo := 4;
    TempoRound := 3;
    ModoPoder := 1;
    NivelDano := 0.9;
    Sangue := True;
    NumRounds := 2;
    Idioma := 1;
    Flash := True;
    MostrarNivel := True;
    MostrarCreditos := True;
    LerConfiguracao(Ini, 'Padroes');
    { recordes iniciais: posicao=iniciais,personagem,pontos }
    for I := 1 to 10 do
    begin
      SepararLista(Ini.ReadString('Recordes', IntToStr(I), ''), Partes);
      if Partes.Count >= 3 then
        criarecorde(I, Partes[0], StrToIntDef(Partes[1], 1), StrToIntDef(Partes[2], 0));
    end;
  finally
    Ini.Free;
    Partes.Free;
  end;

  { configuracao salva pelo jogador (Chaves.ini, gravada pela tela F1) }
  if FileExists(ArqConfiguracao) then
  begin
    Ini := TMemIniFile.Create(ArqConfiguracao);
    try
      LerConfiguracao(Ini, 'Configuracao');
    finally
      Ini.Free;
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
  CarregarIdioma;

  Fichas := 0;                    // fichas (creditos)
  Lutador[1].Personagem := pnChaves;
  Lutador[2].Personagem := pnSeuMadruga;
  Lutador[1].Ativo := False;
  Lutador[2].Ativo := False;
  Lutador[1].Escolheu := False;
  Lutador[2].Escolheu := False;
  zerardados(1);
  zerardados(2);
  ordenarecordista;

  AplicarResolucao(1);

  { imagens e sons listados em Dados/Recursos.ini }
  CarregarRecursos;
  { truque: SCnn.dat na pasta do jogo fixa o cenario nn }
  for I := 1 to FQtdCenarios do
    if FileExists(ArquivoNN('SC##.dat', I)) then CenarioSecreto := I;
  QuadroAtivo := True;
end;
