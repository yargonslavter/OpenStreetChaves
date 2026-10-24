{ Comum_Recursos.inc - Carga de recursos (lutadores, cenarios, rostos, falas, animacoes, sons e musicas).
  A lista do que carregar fica em Dados/Recursos.ini. }

{ Cria a tela, as listas de imagens e os bancos de som (vazios). }
procedure TJogo.CriaComponentes;
begin
  Tela := TSuperficie.Create;
  Tela.SetSize(LarguraTela, AlturaTela);
  SomEfeitos := TBancoSom.Create(False);
  SomMusica := TBancoSom.Create(True);
  SomVitoria := TBancoSom.Create(False);
  ImgRetrato := TListaImagens.Create;
  ImgEfeitos := TListaImagens.Create;
  ImgCenario := TListaImagens.Create;
  ImgIcone := TListaImagens.Create;
  ImgLutador := TListaImagens.Create;
  ImgLutadorInvert := TListaImagens.Create;
  ImgAbertura := TListaImagens.Create;
  ImgFinal := TListaImagens.Create;
  ImgAnimacao := TListaImagens.Create;
  ImgEfeitosInvert := TListaImagens.Create;
  { o cenario e uma imagem so, recarregada a cada luta }
  ImgCenario.Adicionar('Cenario').CarregarArquivo('', False, Preto);
end;

{ Carrega tudo o que Dados/Recursos.ini lista. A ordem das cargas e a do jogo original
  (os numeros das imagens e dos sons dependem dela). }
procedure TJogo.CarregarRecursos;
var
  Ini: TMemIniFile;
  Linhas, Partes: TStringList;
  I, V, Qtd: Integer;
  Nome, Padrao: string;

  { Carrega uma secao Nome=arquivo,transparente: a ordem das linhas e o numero da imagem.
    @param(Lista lista que recebe as imagens)
    @param(Secao nome da secao em Dados/Recursos.ini) }
  procedure ListaComNomes(Lista: TListaImagens; const Secao: string);
  var
    J: Integer;
  begin
    Linhas.Clear;
    Ini.ReadSectionValues(Secao, Linhas);
    for J := 0 to Linhas.Count - 1 do
    begin
      SepararLista(Linhas.ValueFromIndex[J], Partes);
      if Partes.Count = 0 then Continue;
      Lista.Adicionar(Linhas.Names[J]).CarregarArquivo(Partes[0],
        (Partes.Count < 2) or (Partes[1] <> '0'), CorTransparente);
    end;
  end;

begin
  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Ini := AbrirDados(ArqRecursos);
  try
    LerVolumes;
    ListaComNomes(ImgIcone, 'Icones');
    ListaComNomes(ImgAbertura, 'Abertura');
    ListaComNomes(ImgFinal, 'Final');
    Nome := Ini.ReadString('Musicas', 'Menu', '');
    SomMusica.Adicionar(Nome, VolumeDe(Nome));
    FPadraoLutador := Ini.ReadString('Lutadores', 'Arquivo', '');
    FPadraoCenario := Ini.ReadString('Cenarios', 'Arquivo', '');
    FPadraoMusica := Ini.ReadString('Musicas', 'Arquivo', '');
    FPadraoDadosCenario := Ini.ReadString('Cenarios', 'Dados', '');
    FQtdCenarios := Ini.ReadInteger('Cenarios', 'Quantidade', 12);
    SetLength(FMusicaCenario, FQtdCenarios + 1);
    for I := 1 to FQtdCenarios do
      with TMemIniFile.Create(ResolverCaminho(ArquivoNN(FPadraoDadosCenario, I))) do
      try
        FMusicaCenario[I] := ReadInteger('Geral', 'Musica', 0);
      finally
        Free;
      end;
    FQtdLutadores := Ini.ReadInteger('Lutadores', 'Quantidade', 15);
    LerDadosLutadores(Ini.ReadString('Lutadores', 'Dados', ''));
    { roteiros das acoes (Dados/Lutadores/Comum.rot e CNN.rot); erro de escrita gera ERoteiro }
    CarregarRoteiros(Ini.ReadString('Lutadores', 'Roteiro', 'Dados/Lutadores/C##.rot'),
      Ini.ReadString('Lutadores', 'RoteiroComum', 'Dados/Lutadores/Comum.rot'), FQtdLutadores);

    { animacoes dos cenarios }
    Padrao := Ini.ReadString('Animacoes', 'Arquivo', '');
    for I := 1 to Ini.ReadInteger('Animacoes', 'Quantidade', 0) do
      carregaranimacao(ArquivoNN(Padrao, I));

    { efeitos (normal e espelhado) e os nomes usados pelo codigo }
    Padrao := Ini.ReadString('Efeitos', 'Arquivo', '');
    for I := 1 to Ini.ReadInteger('Efeitos', 'Quantidade', 0) do
      carregarefeitos(ArquivoNN(Padrao, I));
    Linhas.Clear;
    Ini.ReadSectionValues('Efeitos.Nomes', Linhas);
    LerEfeitos(ResolverCaminho(Ini.ReadString('Efeitos', 'Dados', '')));
    LerFinais(ResolverCaminho(Ini.ReadString('Finais', 'Dados', '')));
    for I := 0 to Linhas.Count - 1 do
    begin
      V := StrToIntDef(Linhas.ValueFromIndex[I], 0) - 1;
      ImgEfeitos.Apelidar(Linhas.Names[I], V);
      ImgEfeitosInvert.Apelidar(Linhas.Names[I], V);
    end;

    { efeitos sonoros: Som-01.wav, Som-02.wav ... (o original carrega ate o primeiro faltante,
      mais uma posicao vazia no fim) }
    Padrao := Ini.ReadString('Sons', 'Arquivo', '');
    I := 1;
    Nome := ArquivoNN(Padrao, I);
    while FileExists(Nome) do
    begin
      Nome := ArquivoNN(Padrao, I);
      carregareftsonoro(Nome);
      Inc(I);
    end;
    QtdSons := I;
    if QtdSons > 3 then QtdSons := QtdSons - 2;

    { musicas: so conta quantas existem (Musica-01.wav ...) }
    I := 1;
    Nome := ArquivoNN(FPadraoMusica, I);
    while FileExists(Nome) do
    begin
      Nome := ArquivoNN(FPadraoMusica, I);
      Inc(I);
    end;
    QtdMusicas := I;
    if QtdMusicas > 3 then QtdMusicas := QtdMusicas - 2;

    { falas de vitoria: para cada personagem, uma posicao por variante }
    SepararLista(Ini.ReadString('Falas', 'Variantes', ''), Partes);
    for I := 1 to Ini.ReadInteger('Falas', 'Quantidade', 0) do
      for V := 0 to Partes.Count - 1 do
        carregarfala(ArquivoNN(Partes[V], I));

    { rostos: para cada personagem, uma posicao por variante (* = espelhado) }
    SepararLista(Ini.ReadString('Rostos', 'Variantes', ''), Partes);
    for I := 1 to Ini.ReadInteger('Rostos', 'Quantidade', 0) do
      for V := 0 to Partes.Count - 1 do
      begin
        Nome := Partes[V];
        if (Nome <> '') and (Nome[Length(Nome)] = '*') then
          carregarosto(ArquivoNN(Copy(Nome, 1, Length(Nome) - 1), I), 2)
        else
          carregarosto(ArquivoNN(Nome, I), 1);
      end;

    { quadros dos lutadores: posicoes vazias, preenchidas por carregarlutador }
    Qtd := Ini.ReadInteger('Lutadores', 'VagasQuadros', 150);
    for I := 1 to Qtd do
    begin
      ImgLutador.Adicionar;
      ImgLutadorInvert.Adicionar;
    end;
  finally
    Ini.Free;
    Partes.Free;
    Linhas.Free;
  end;
  SomIniciar;
end;

{ Le Dados/Lutadores/Cnn.ini de cada personagem: secoes [Geral] e [Golpes]. }
procedure TJogo.LerDadosLutadores(const Padrao: string);
var
  Ini: TMemIniFile;
  Partes: TStringList;
  P, K, N: Integer;
  V: string;
begin
  SetLength(FLutadores, FQtdLutadores + 1);
  PrepararQuadrosLutadores(FQtdLutadores);
  Partes := TStringList.Create;
  try
    for P := 1 to FQtdLutadores do
    begin
      Ini := TMemIniFile.Create(ResolverCaminho(ArquivoNN(Padrao, P)));
      try
        with FLutadores[P] do
        begin
          AlturaSprite := Ini.ReadInteger('Geral', 'AlturaSprite', 160);
          Velocidade := LerDecimal(Ini, 'Geral', 'Velocidade', 8.0);
          Chefe := Ini.ReadInteger('Geral', 'Chefe', 1);
          NaoEnfrenta := [];
          SepararLista(Ini.ReadString('Geral', 'NaoEnfrenta', ''), Partes);
          for K := 0 to Partes.Count - 1 do
          begin
            N := StrToIntDef(Partes[K], -1);
            if (N >= 0) and (N <= 255) then Include(NaoEnfrenta, Byte(N));
          end;
          Cenario := Ini.ReadInteger('Geral', 'Cenario', 1);
          CenarioAlternativo := Ini.ReadInteger('Geral', 'CenarioAlternativo', 0);
          CenarioRaro := Ini.ReadInteger('Geral', 'CenarioRaro', 0);
          MusicaCPU := Ini.ReadInteger('Geral', 'MusicaCPU', 0);
          TremeAoCair := Ini.ReadBool('Geral', 'TremeAoCair', False);
          for K := 1 to High(Golpes) do
          begin
            V := Ini.ReadString('Golpes', IntToStr(K), '');
            N := LastDelimiter(',', V);
            if N = 0 then N := Length(V) + 1;
            Golpes[K].N := Trim(Copy(V, 1, N - 1));
            Golpes[K].S := Trim(Copy(V, N + 1, MaxInt));
          end;
        end;
        { teclas dos golpes especiais e botoes -> comandos }
        LerRegrasComando(Ini, 'Sequencias', FLutadores[P].Sequencias);
        LerRegrasComando(Ini, 'Botoes', FLutadores[P].Botoes);
        { centro do sprite e caixas de colisao de cada quadro (lidos por ChavesGolpes) }
        LerQuadrosLutador(P, Ini);
      finally
        Ini.Free;
      end;
    end;
  finally
    Partes.Free;
  end;
end;

{ Le as regras 1=, 2=, ... de [Sequencias] ("termos: De>Para") ou [Botoes] ("botao, termos: Comando"),
  na ordem dos numeros, ate o primeiro que faltar. Uma regra com algum termo desconhecido e ignorada
  inteira (nunca vale), para um erro de digitacao nao disparar golpes a toa. }
procedure TJogo.LerRegrasComando(Ini: TCustomIniFile; const Secao: string; out Regras: TRegrasComando);
const
  Setas: array[0..3] of string = ('Baixo', 'Frente', 'Tras', 'Cima');
  TiposSeta = 'BFTC';
  Botoes: array[1..4] of string = ('SocoFraco', 'ChuteFraco', 'SocoForte', 'ChuteForte');
  { termos com valor: nome, tipo e operador }
  NomesValor: array[0..4] of string = ('TempoBaixo', 'TempoTras', 'CargaSoco', 'CargaChute', 'Passo');
  TiposValor = 'btskP';
  OpsValor: array[0..4] of string = ('>=', '>=', '>=', '>=', '=');
var
  Partes: TStringList;
  K, N, I, J, Q, Dois: Integer;
  Linha, Esq, Dir, S: string;
  R: TRegraComando;
  T: TTermoComando;
  Ok, Achou: Boolean;
begin
  Regras := nil;
  Q := 0;
  Partes := TStringList.Create;
  try
    K := 1;
    repeat
      Linha := Trim(Ini.ReadString(Secao, IntToStr(K), ''));
      if Linha = '' then Break;
      Inc(K);
      Dois := LastDelimiter(':', Linha);
      if Dois = 0 then Continue;
      Esq := Copy(Linha, 1, Dois - 1);
      Dir := Trim(Copy(Linha, Dois + 1, MaxInt));
      R.Termos := nil;
      R.Botao := 0;
      R.Comando := 0;
      R.De := 0;
      R.Para := 0;
      Ok := True;
      { resultado }
      if Secao = 'Sequencias' then
      begin
        N := Pos('>', Dir);
        I := StrToIntDef(Trim(Copy(Dir, 1, N - 1)), -1);
        J := StrToIntDef(Trim(Copy(Dir, N + 1, MaxInt)), -1);
        if (N = 0) or (I < 0) or (I > 255) or (J < 0) or (J > 255) then Ok := False
        else
        begin
          R.De := I;
          R.Para := J;
        end;
      end
      else
      begin
        for I := 1 to MaxComando do
          if SameText(Dir, NomesComando[I]) then R.Comando := I;
        if R.Comando = 0 then Ok := False;
      end;
      { termos }
      SepararLista(Esq, Partes);
      for I := 0 to Partes.Count - 1 do
      begin
        S := Partes[I];
        if S = '' then Continue;
        T.Nega := S[1] = '!';
        if T.Nega then S := Trim(Copy(S, 2, MaxInt));
        T.Tipo := #0;
        T.Valor := 0;
        Achou := False;
        for J := 1 to 4 do
          if SameText(S, Botoes[J]) and not T.Nega and (R.Botao = 0) and (Secao = 'Botoes') then
          begin
            R.Botao := J;
            Achou := True;
          end;
        if Achou then Continue;
        for J := 0 to 3 do
          if SameText(S, Setas[J]) then T.Tipo := TiposSeta[J + 1];
        if SameText(S, 'NoChao') then T.Tipo := 'H';
        if SameText(S, 'NoAr') then T.Tipo := 'A';
        for J := 0 to 4 do
          if SameText(Copy(S, 1, Length(NomesValor[J]) + Length(OpsValor[J])), NomesValor[J] + OpsValor[J]) then
          begin
            N := StrToIntDef(Trim(Copy(S, Length(NomesValor[J]) + Length(OpsValor[J]) + 1, MaxInt)), -1);
            if N >= 0 then
            begin
              T.Tipo := TiposValor[J + 1];
              T.Valor := N;
            end;
          end;
        if T.Tipo = #0 then
          Ok := False
        else
        begin
          SetLength(R.Termos, Length(R.Termos) + 1);
          R.Termos[High(R.Termos)] := T;
        end;
      end;
      if (Secao = 'Botoes') and (R.Botao = 0) then Ok := False;
      if Ok then
      begin
        SetLength(Regras, Q + 1);
        Regras[Q] := R;
        Inc(Q);
      end;
    until False;
  finally
    Partes.Free;
  end;
end;

{ Volumes dos sons: Dados/Som.ini e, por cima, o Chaves.ini deste computador (secao [Volume]). }
procedure TJogo.LerVolumes;
var
  Linhas: TStringList;
  Ini: TMemIniFile;
  I, Arq: Integer;
begin
  FVolumes.Clear;
  Linhas := TStringList.Create;
  try
    for Arq := 1 to 2 do
    begin
      if Arq = 1 then
        Ini := AbrirDados('Som.ini')
      else
        Ini := TMemIniFile.Create(ArqConfiguracao);
      try
        Linhas.Clear;
        Ini.ReadSectionValues('Volume', Linhas);
        for I := 0 to Linhas.Count - 1 do
          FVolumes.Values[Trim(Linhas.Names[I])] := Trim(Linhas.ValueFromIndex[I]);
      finally
        Ini.Free;
      end;
    end;
  finally
    Linhas.Free;
  end;
end;

{ Volume (em % do arquivo) do som Arquivo: procura o nome do arquivo sem extensao (Som-05), depois
  a pasta (Sons, Falas, Musicas...), depois Padrao; sem nada, 100. }
function TJogo.VolumeDe(const Arquivo: string): Integer;
var
  Chaves: array[0..2] of string;
  I, K: Integer;
begin
  Result := 100;
  Chaves[0] := ChangeFileExt(ExtractFileName(Arquivo), '');
  Chaves[1] := ExtractFileName(ExcludeTrailingPathDelimiter(ExtractFilePath(Arquivo)));
  Chaves[2] := 'Padrao';
  for K := 0 to High(Chaves) do
  begin
    if Chaves[K] = '' then Continue;
    I := FVolumes.IndexOfName(Chaves[K]);
    if I >= 0 then
    begin
      Result := StrToIntDef(FVolumes.ValueFromIndex[I], 100);
      Break;
    end;
  end;
  if Result < 0 then Result := 0;
  if Result > 400 then Result := 400;
end;

{ True se Musica e a musica propria de algum cenario (so toca nele). }
function TJogo.MusicaDeCenario(Musica: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to High(FMusicaCenario) do
    if FMusicaCenario[I] = Musica then Result := True;
end;

{ Copia o quadro [X1,X2) x [Y1,Y2) da folha FFrameSheet para Indice das listas
  ImgLutador (normal) e ImgLutadorInvert (espelhado). }
procedure TJogo.copiabmp(Indice, X1, Y1, X2, Y2: Integer);
begin
  ImgLutador[Indice].AtribuirRegiao(FFrameSheet, X1, Y1, X2, Y2, False, True, CorTransparente);
  ImgLutadorInvert[Indice].AtribuirRegiao(FFrameSheet, X1, Y1, X2, Y2, True, True, CorTransparente);
end;

{ Carrega a folha de sprites do lutador. Os quadros sao separados por colunas
  "escuras" (R,G,B <= 100 no topo e na base). Jogador 1 ocupa os indices 1.. e
  jogador 2 os indices 51.. das listas. }
procedure TJogo.carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
var
  Desloc, Cont, Ini, Col, W, H: Integer;
  C1, C2: TColor;

  { @param(C cor de um pixel)
    @returns(True se R, G e B sao todos <= 100 (coluna separadora de quadros)) }
  function Escuro(C: TColor): Boolean;
  begin
    Result := ((C and $FF) <= 100) and (((C shr 8) and $FF) <= 100) and (((C shr 16) and $FF) <= 100);
  end;

begin
  if not FileExists(Nome) then
  begin
    QuadroAtivo := True;
    Exit;
  end;
  if FFrameSheet = nil then FFrameSheet := TSuperficie.Create;
  FFrameSheet.CarregarBMP(Nome);
  Desloc := 0;
  if Jogador = 1 then Desloc := 0;
  if Jogador = 2 then Desloc := 50;

  Lutador[Jogador].Personagem := Personagem;
  if (Personagem >= 1) and (Personagem <= FQtdLutadores) then
    Lutador[Jogador].AlturaSprite := FLutadores[Personagem].AlturaSprite;

  W := FFrameSheet.Width;
  H := FFrameSheet.Height;
  Ini := 0;
  Cont := 1;
  for Col := 0 to W - 1 do
  begin
    C1 := FFrameSheet.Pixels[Col, 0];
    C2 := FFrameSheet.Pixels[Col, H - 1];
    if Escuro(C1) and Escuro(C2) then
    begin
      copiabmp(Cont + Desloc, Ini, 0, Col - 1, H - 1);
      Inc(Cont);
      Ini := Col + 1;
    end;
  end;
  QuadroAtivo := True;
end;

{ Carrega a imagem do cenario Numero e os dados dele (Dados/Cenarios/Cenario-NN.ini). }
procedure TJogo.carregarcenario(Numero: Integer);
var
  Nome: string;
begin
  QuadroAtivo := False;
  Nome := ArquivoNN(FPadraoCenario, Numero);
  if FileExists(Nome) then ImgCenario[0].CarregarArquivo(Nome, False, CorTransparente);
  FCameraXMax := Max(0, ImgCenario[0].Width - LarguraTela);
  FCameraYMax := Max(0, ImgCenario[0].Height - AlturaTela);
  LerDadosCenario(Numero);
  QuadroAtivo := True;
end;

{ Item que quebra, voador e animacoes do cenario Numero. }
procedure TJogo.LerDadosCenario(Numero: Integer);
var
  Ini: TMemIniFile;
  Partes: TStringList;
  A, K, N: Integer;
  Secao, S: string;
  Esconde: set of Byte;
  D: TDesenhoCenario;

  { @param(I posicao na lista separada por virgulas)
    @param(Padrao valor se faltar ou nao for numero)
    @returns(o numero) }
  function Parte(I, Padrao: Integer): Integer;
  begin
    if I < Partes.Count then Result := StrToIntDef(Partes[I], Padrao) else Result := Padrao;
  end;

begin
  SetLength(FDesenhos, 0);
  ItemBonus.Icone := 0;
  FVoadorModo := 0;
  Partes := TStringList.Create;
  Ini := TMemIniFile.Create(ResolverCaminho(ArquivoNN(FPadraoDadosCenario, Numero)));
  try
    { item que quebra quando um lutador cai em cima }
    if Ini.SectionExists('Item') then
    begin
      SepararLista(Ini.ReadString('Item', 'Caixa', ''), Partes);
      ItemBonus.X := Ini.ReadInteger('Item', 'X', 0);
      ItemBonus.Y := Ini.ReadInteger('Item', 'Y', 0);
      ItemBonus.Dx1 := Parte(0, 0);
      ItemBonus.Dy1 := Parte(1, 0);
      ItemBonus.Dx2 := Parte(2, 0);
      ItemBonus.Dy2 := Parte(3, 0);
      ItemBonus.Icone := Max(0, ImgIcone.IndiceDe(Ini.ReadString('Item', 'Icone', '')));
    end;

    { voador }
    S := Ini.ReadString('Voador', 'Aparece', '');
    if SameText(S, 'Sempre') then FVoadorModo := 1;
    if SameText(S, 'Luta') then FVoadorModo := 2;
    FVoadorY := Ini.ReadInteger('Voador', 'Y', 146);

    { animacoes: [Animacao1], [Animacao2]... cada uma com Esconde e desenhos 1=, 2=... }
    A := 1;
    while Ini.SectionExists('Animacao' + IntToStr(A)) do
    begin
      Secao := 'Animacao' + IntToStr(A);
      Esconde := [];
      SepararLista(Ini.ReadString(Secao, 'Esconde', ''), Partes);
      for K := 0 to Partes.Count - 1 do
      begin
        N := StrToIntDef(Partes[K], -1);
        if (N >= 0) and (N <= 255) then Include(Esconde, Byte(N));
      end;
      K := 1;
      while Ini.ValueExists(Secao, IntToStr(K)) do
      begin
        SepararLista(Ini.ReadString(Secao, IntToStr(K), ''), Partes);
        Inc(K);
        if Partes.Count < 2 then Continue;
        { faixa: * = sempre, 8-15, 24- }
        D.De := -1;
        D.Ate := -1;
        S := Partes[0];
        if S <> '*' then
        begin
          N := Pos('-', S);
          if N = 0 then N := Length(S) + 1;
          D.De := StrToIntDef(Copy(S, 1, N - 1), 0);
          D.Ate := StrToIntDef(Copy(S, N + 1, MaxInt), -1);
        end;
        { imagem: Sombra, A<n> ou Especial:<nome> }
        S := Partes[1];
        D.Lista := nil;
        D.Indice := -1;
        D.Especial := '';
        if SameText(S, 'Sombra') then
        begin
          D.Lista := ImgEfeitos;
          D.Indice := ImgEfeitos.IndiceDe('Sombra');
        end
        else if SameText(Copy(S, 1, 9), 'Especial:') then
          D.Especial := Copy(S, 10, MaxInt)
        else if (S <> '') and (UpCase(S[1]) = 'A') then
        begin
          D.Lista := ImgAnimacao;
          D.Indice := StrToIntDef(Copy(S, 2, MaxInt), 0) - 1;
        end;
        D.X := Parte(2, 0);
        D.Y := Parte(3, 0);
        D.TremorX := Parte(4, 0);
        D.TremorY := Parte(5, 0);
        D.PassoY := Parte(6, 0);
        D.Esconde := Esconde;
        SetLength(FDesenhos, Length(FDesenhos) + 1);
        FDesenhos[High(FDesenhos)] := D;
      end;
      Inc(A);
    end;
  finally
    Ini.Free;
    Partes.Free;
  end;
end;

{ Variante 1 = imagem normal, 2 = espelhada na horizontal }
procedure TJogo.carregarosto(const Nome: string; Variante: Byte);
var
  Item: TImagem;
  Folha: TSuperficie;
begin
  Item := ImgRetrato.Adicionar;
  if not FileExists(Nome) then Exit;
  if Variante = 1 then
    Item.CarregarArquivo(Nome, True, CorTransparente)
  else
  begin
    Folha := TSuperficie.Create;
    try
      Folha.CarregarBMP(Nome);
      Item.AtribuirRegiao(Folha, 0, 0, Folha.Width, Folha.Height, True, True, CorTransparente);
    finally
      Folha.Free;
    end;
  end;
end;

procedure TJogo.carregarfala(const Nome: string);
begin
  SomVitoria.Adicionar(Nome, VolumeDe(Nome));
end;

procedure TJogo.carregaranimacao(const Nome: string);
var
  Item: TImagem;
begin
  Item := ImgAnimacao.Adicionar;
  if FileExists(Nome) then Item.CarregarArquivo(Nome, True, CorTransparente);
end;

procedure TJogo.carregareftsonoro(const Nome: string);
begin
  SomEfeitos.Adicionar(Nome, VolumeDe(Nome));
end;

procedure TJogo.carregarmusica(Numero: Byte);
var
  Nome: string;
begin
  Nome := ArquivoNN(FPadraoMusica, Numero);
  if FileExists(Nome) then
  begin
    SomMusica.Carregar(0, Nome, VolumeDe(Nome));
    MusicaAtual := Numero;
  end;
end;

{ Efeitos: uma imagem normal e uma espelhada, em listas separadas }
procedure TJogo.carregarefeitos(const Nome: string);
var
  Normal, Espelhada: TImagem;
  Folha: TSuperficie;
begin
  Normal := ImgEfeitos.Adicionar;
  Espelhada := ImgEfeitosInvert.Adicionar;
  if not FileExists(Nome) then Exit;
  Normal.CarregarArquivo(Nome, True, CorTransparente);
  Folha := TSuperficie.Create;
  try
    Folha.CarregarBMP(Nome);
    Espelhada.AtribuirRegiao(Folha, 0, 0, Folha.Width, Folha.Height, True, True, CorTransparente);
  finally
    Folha.Free;
  end;
end;
