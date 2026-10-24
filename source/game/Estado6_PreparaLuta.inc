{ Estado6_PreparaLuta.inc - Estado CHS_PREPARALUTA: carrega lutadores, cenario e musica e passa a luta. }

{ Estado 6: prepara a luta (carrega lutadores, cenario e musica) e passa ao estado 7 }
procedure TJogo.Estado6_PreparaLuta;
var
  J, L: Integer;
begin
  Estado := CHS_LUTA;
  FTick7 := 0;
  ContPisca := 0;
  TempoEstado := 0;
  MusicaPendente := True;
  RelogioParado := True;
  TempoDialogo := 0;
  case TempoRound of
    1: ContagemSeg := 30;
    2: ContagemSeg := 60;
    3: ContagemSeg := 90;
    4: ContagemSeg := 99;
  end;
  ContagemTick := 25;
  FaseIntro := 0;
  FaseFim := 0;
  CameraX := 100;
  TremorTela := 0;
  FlashTela := 0;
  PausaImpacto := 0;
  PrimeiroAtaque := False;
  zerardados(1);
  zerardados(2);
  Lutador[1].CargaPoder := 0;
  Lutador[1].Poder := 0;
  Lutador[2].CargaPoder := 0;
  Lutador[2].Poder := 0;
  for L := 1 to MaxEfeitos do Efeitos[L].Tipo := 0;
  QuadroAtivo := False;
  for J := 1 to 2 do
    if (Lutador[J].Personagem >= 1) and (Lutador[J].Personagem <= FQtdLutadores) then
      carregarlutador(ArqLutador(Lutador[J].Personagem), Lutador[J].Personagem, J);
  if Lutador[1].Ativo and Lutador[2].Ativo then
  begin
    L := Round(Random(FQtdCenarios * 10) / 10) + 1;
    if L < 1 then L := 1;
    if L > FQtdCenarios then L := FQtdCenarios;
    CenarioAtual := L;
    if CenarioSecreto <> 0 then
    begin
      if CenarioSecreto < 1 then CenarioSecreto := 1;
      if CenarioSecreto > FQtdCenarios then CenarioSecreto := FQtdCenarios;
      CenarioAtual := CenarioSecreto;
    end;
    carregarcenario(CenarioAtual);
  end;
  MusicaAtual := 0;
  { musica: a do adversario controlado pelo computador; a do cenario, se ele tiver uma }
  for J := 1 to 2 do
  begin
    L := Lutador[J].Personagem;
    if (L >= 1) and (L <= FQtdLutadores) and not Lutador[J].Ativo and (FLutadores[L].MusicaCPU <> 0) then
      MusicaAtual := FLutadores[L].MusicaCPU;
    if (CenarioAtual >= 1) and (CenarioAtual <= FQtdCenarios) and (FMusicaCenario[CenarioAtual] <> 0) then
      MusicaAtual := FMusicaCenario[CenarioAtual];
  end;
  if MusicaAtual = 0 then MusicaAtual := Round(Random(QtdMusicas * 10) / 10) + 1;
  if MusicaAtual < 1 then MusicaAtual := 1;
  if MusicaAtual > QtdMusicas then MusicaAtual := QtdMusicas;
  { a musica propria de um cenario so toca nele }
  if MusicaDeCenario(MusicaAtual) and
     not ((CenarioAtual >= 1) and (CenarioAtual <= FQtdCenarios) and (FMusicaCenario[CenarioAtual] = MusicaAtual)) then
    MusicaAtual := 1;
  carregarmusica(MusicaAtual);
  QuadroAtivo := True;
end;
