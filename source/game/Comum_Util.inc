{ Comum_Util.inc - Utilidades comuns: teclas do jogador, textos de memo, nomes de arquivo, som, configuracao, resolucao, recordes e zerar dados. }

function TJogo.TecP1: Byte;
begin
  Result := BitsTeclado(MapaP1) or ControleP[1];
end;

function TJogo.TecP2: Byte;
begin
  Result := BitsTeclado(MapaP2) or ControleP[2];
end;

function TJogo.Linha(Memo: TTextoLista; I: Integer): string;
begin
  if (I >= 0) and (I < Memo.Lines.Count) then Result := Memo.Lines[I] else Result := '';
end;

{ nome com N em 2 digitos (<10 ganha zero a esquerda), como as montagens do original }
function TJogo.NomeNN(const Prefixo, Sufixo: string; N: Integer): string;
begin
  if N < 10 then
    Result := Prefixo + '0' + IntToStr(N) + Sufixo
  else
    Result := Prefixo + IntToStr(N) + Sufixo;
end;

procedure TJogo.TocarSom(Indice: Integer);
begin
  if (Indice >= 0) and (Indice < SomEfeitos.Count) then
    SomEfeitos.Tocar(Indice);
end;

procedure TJogo.SalvarConfiguracao;
begin
  with MemoConfigSalvo.Lines do
  begin
    Clear;
    Add(IntToStr(NivelJogo));
    if TempoRound = 1 then Add('1');
    if TempoRound = 2 then Add('2');
    if TempoRound = 3 then Add('3');
    if TempoRound = 4 then Add('4');
    Add(IntToStr(ModoPoder));
    Add(FloatToStr(NivelDano));
    if Sangue = 0 then Add('0');
    if Sangue = 1 then Add('1');
    Add(IntToStr(NumRounds));
    Add(IntToStr(Idioma));
    if Flash = 0 then Add('0');
    if Flash = 1 then Add('1');
    if MostrarNivel = 0 then Add('0');
    if MostrarNivel = 1 then Add('1');
    if MostrarCreditos = 0 then Add('0');
    if MostrarCreditos = 1 then Add('1');
  end;
  try
    MemoConfigSalvo.Lines.SaveToFile('Chaves.dat');
  except
    // pasta somente leitura: ignora (o original tambem nao tratava)
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
    Acao := 1;
    VelY := 0;
    Vencedor := 0;
    Acertos := 0;
    TempoAcertos := 0;
    GolpeAtivo := 0;
    AtrasoBarra := 0;
    NoAr := 0;
  end;
  Lutador[1].X := 220.0;
  Lutador[2].X := 380.0;
  ChaoY := 300;
  Lutador[Jogador].Y := ChaoY;
  Lutador[1].Lado := 1;
  Lutador[2].Lado := 2;
  Lutador[1].DesenhaPorCima := 1;
  Lutador[2].DesenhaPorCima := 0;
  with Lutador[Jogador] do
  begin
    Velocidade := 8.0;
    case Personagem of
      3, 9: Velocidade := 8.5;
      6, 7, 10, 13, 14: Velocidade := 7.5;
    end;
  end;
  DeslocHudTopo := 0;
  DeslocHudBase := 0;
  PrimeiroAtaque := 0;
  CameraX := Round((Lutador[1].X + Lutador[2].X) / 2) - 200;
  CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  for I := 1 to MaxEfeitos do Efeitos[I].Tipo := 0;
end;
