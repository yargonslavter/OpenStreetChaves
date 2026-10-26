{ Comum_Util.inc - Utilidades comuns: teclas do jogador, textos de memo, som, configuracao, resolucao, recordes e zerar dados. }

function TJogo.TecP1: Byte;
begin
  Result := BitsTeclado(MapaP1) or ControleP[1];
end;

function TJogo.TecP2: Byte;
begin
  Result := BitsTeclado(MapaP2) or ControleP[2];
end;

function TJogo.Linha(Lista: TStrings; I: Integer): string;
begin
  if (I >= 0) and (I < Lista.Count) then Result := Lista[I] else Result := '';
end;

{ (Re)carrega os textos do idioma atual (Idioma: 1 = PT, 2 = ES). }
procedure TJogo.CarregarIdioma;
begin
  CarregarTextos(Idioma, TxtNomes, TxtGeral, TxtConfig, TxtFrases, TxtDialogo, TxtFinais, TxtCenarios);
end;

{ Grava a configuracao da tela F1 em Chaves.ini (na pasta do jogo). }
procedure TJogo.SalvarConfiguracao;
const
  S = 'Configuracao';
var
  Ini: TMemIniFile;
begin
  try
    Ini := TMemIniFile.Create(ArqConfiguracao);
    try
      Ini.WriteInteger(S, 'NivelJogo', NivelJogo);
      Ini.WriteInteger(S, 'TempoRound', TempoRound);
      Ini.WriteInteger(S, 'ModoPoder', ModoPoder);
      GravarDecimal(Ini, S, 'NivelDano', NivelDano);
      Ini.WriteInteger(S, 'Sangue', Ord(Sangue));
      Ini.WriteInteger(S, 'NumRounds', NumRounds);
      Ini.WriteInteger(S, 'Idioma', Idioma);
      Ini.WriteInteger(S, 'Flash', Ord(Flash));
      Ini.WriteInteger(S, 'MostrarNivel', Ord(MostrarNivel));
      Ini.WriteInteger(S, 'MostrarCreditos', Ord(MostrarCreditos));
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  except
    // pasta somente leitura: ignora (o original tambem nao tratava)
  end;
end;

procedure TJogo.CarregarLiberacao;
var
  Partes: TStringList;
  Ini: TMemIniFile;
  I, N: Integer;

  { Marca os personagens de uma lista "9,10,11".
    @param(Lista numeros separados por virgula)
    @param(Valor True = liberado, False = bloqueado) }
  procedure Marca(const Lista: string; Valor: Boolean);
  var
    K: Integer;
  begin
    SepararLista(Lista, Partes);
    for K := 0 to Partes.Count - 1 do
    begin
      N := StrToIntDef(Partes[K], 0);
      if (N >= 1) and (N <= FQtdLutadores) then FLiberado[N] := Valor;
    end;
  end;

begin
  SetLength(FLiberado, FQtdLutadores + 1);
  for I := 1 to FQtdLutadores do FLiberado[I] := True;
  if FileExists('Liberados.dat') then Exit;
  Partes := TStringList.Create;
  try
    Marca(FOrdemLib, False);
    Marca(FIniciaisLib, True);
    if FileExists(ArqConfiguracao) then
    begin
      Ini := TMemIniFile.Create(ArqConfiguracao);
      try
        Marca(Ini.ReadString('Progresso', 'Liberados', ''), True);
      finally
        Ini.Free;
      end;
    end;
  finally
    Partes.Free;
  end;
end;

function TJogo.Liberado(Pers: Integer): Boolean;
begin
  Result := (Pers >= 1) and (Pers <= High(FLiberado)) and FLiberado[Pers];
end;

procedure TJogo.LiberarProximo;
var
  Partes: TStringList;
  Ini: TMemIniFile;
  I, N: Integer;
  Lista: string;
begin
  Partes := TStringList.Create;
  try
    SepararLista(FOrdemLib, Partes);
    for I := 0 to Partes.Count - 1 do
    begin
      N := StrToIntDef(Partes[I], 0);
      if (N >= 1) and (N <= FQtdLutadores) and not FLiberado[N] then
      begin
        FLiberado[N] := True;
        { grava a lista de quem a ordem ja liberou (mudar a ordem depois nao tira ninguem) }
        try
          Ini := TMemIniFile.Create(ArqConfiguracao);
          try
            Lista := Ini.ReadString('Progresso', 'Liberados', '');
            if Lista <> '' then Lista := Lista + ',';
            Ini.WriteString('Progresso', 'Liberados', Lista + IntToStr(N));
            Ini.UpdateFile;
          finally
            Ini.Free;
          end;
        except
          // pasta somente leitura: o lutador fica liberado so ate fechar o jogo
        end;
        Exit;
      end;
    end;
  finally
    Partes.Free;
  end;
end;

{ Modo 1 = janela 400x300; 2 = tela cheia mantendo proporcao; 3 = tela cheia esticada.
  (O original trocava o modo de video do DirectDraw.) Quem muda a janela e o ChavesSDL. }
procedure TJogo.AplicarResolucao(Modo: Integer);
begin
  ModoTela := Modo;
  if Assigned(AoMudarTela) then AoMudarTela(Self);
end;

procedure TJogo.criarecorde(Posicao: Integer; const Nome: string; Personagem: Byte; Pontos: Integer);
begin
  Recordes[Posicao].Nome := Copy(Nome, 1, 3);
  Recordes[Posicao].Personagem := Personagem;
  Recordes[Posicao].Pontos := Cardinal(Pontos);
end;

{ ordena em ordem decrescente de pontos }
procedure TJogo.ordenarecordista;
var
  I, J: Integer;
  T: TRecorde;
begin
  for I := 1 to 9 do
    for J := I + 1 to 10 do
      if Recordes[I].Pontos < Recordes[J].Pontos then
      begin
        T := Recordes[I];
        Recordes[I] := Recordes[J];
        Recordes[J] := T;
      end;
end;

procedure TJogo.zerardados(Jogador: Integer);
var
  I: Integer;
begin
  with Lutador[Jogador] do
  begin
    Vida := VidaMax;
    VidaBarra := VidaMax;
    Acao := acParado;
    VelY := 0;
    Invulneravel := False;
    Acertos := 0;
    TempoAcertos := 0;
    GolpeAtivo := False;
    AtrasoBarra := 0;
    NoAr := False;
  end;
  Lutador[1].X := 220.0;
  Lutador[2].X := 380.0;
  ChaoY := 300;
  Lutador[Jogador].Y := ChaoY;
  Lutador[1].Lado := ldDireita;
  Lutador[2].Lado := ldEsquerda;
  Lutador[1].DesenhaPorCima := True;
  Lutador[2].DesenhaPorCima := False;
  with Lutador[Jogador] do
  begin
    Velocidade := 8.0;
    if (Personagem >= 1) and (Personagem <= FQtdLutadores) then
      Velocidade := FLutadores[Personagem].Velocidade;
  end;
  DeslocHudTopo := 0;
  DeslocHudBase := 0;
  PrimeiroAtaque := False;
  CameraX := Round((Lutador[1].X + Lutador[2].X) / 2) - 200;
  CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  for I := 1 to MaxEfeitos do Efeitos[I].Tipo := 0;
end;
