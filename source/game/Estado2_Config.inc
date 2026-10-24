{ Estado2_Config.inc - Estado CHS_CONFIG: tela de configuracoes (F1). }

{ bits que acabaram de ser pressionados (P1 ou P2) neste quadro }
function TJogo.BordaTeclas: Byte;
var
  K1, K2, A1, A2: Byte;
  function Prev(const L: TLutador): Byte;
  begin
    Result := 0;
    if L.AntCima then Result := Result or 1;
    if L.AntBaixo then Result := Result or 2;
    if L.AntEsq then Result := Result or 4;
    if L.AntDir then Result := Result or 8;
    if L.AntSocoFraco then Result := Result or 16;
    if L.AntChuteFraco then Result := Result or 32;
    if L.AntSocoForte then Result := Result or 64;
    if L.AntChuteForte then Result := Result or 128;
  end;
begin
  K1 := TecP1;
  K2 := TecP2;
  A1 := Prev(Lutador[1]);
  A2 := Prev(Lutador[2]);
  Result := Byte((K1 and (not A1)) or (K2 and (not A2)));
end;

{ Estado 2: tela de configuracoes (F1) }
procedure TJogo.Estado2_Config;
const
  Rotulo: array[1..12] of Integer = (2, 3, 6, 11, 12, 13, 14, 17, 18, 19, 20, 21);
var
  Sel: TColor;
  I, Y, E: Integer;

  procedure Rot(R: Integer; Cor: TColor);
  begin
    texto(10, 45 + 15 * R, Linha(TxtConfig, Rotulo[R]), AEsq, 11, Cor);
  end;

  procedure Val(X, R, Idx: Integer; Cor: TColor);
  begin
    texto(X, 45 + 15 * R, Linha(TxtConfig, Idx), AEsq, 11, Cor);
  end;

begin
  Sel := AzulSelecao;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 5, Linha(TxtConfig, 1), ACentro, 15, Branco);
  for I := 1 to 12 do Rot(I, Branco);
  for I := 1 to 8 do texto((I - 1) * 10 + 140, 60, IntToStr(I), AEsq, 11, Branco);
  texto(140, 75, '30', AEsq, 11, Branco);
  texto(190, 75, '60', AEsq, 11, Branco);
  texto(240, 75, '90', AEsq, 11, Branco);
  texto(290, 75, '--', AEsq, 11, Branco);
  Val(140, 3, 7, Branco);
  Val(215, 3, 8, Branco);
  Val(280, 3, 9, Branco);
  Val(345, 3, 10, Branco);
  barraredonda(140, 110, 300, 121, 5, Branco, Preto);
  barra(142, 112, Round(78 * NivelDano) + 142, 119, Vermelho);
  barra(142, 113, Round(78 * NivelDano) + 142, 114, Rosa);
  texto(310, 105, IntToStr(Round(NivelDano * 100)) + '%', AEsq, 11, Branco);
  Val(140, 5, 4, Branco);
  Val(230, 5, 5, Branco);
  for I := 1 to 3 do texto((I - 1) * 30 + 140, 135, IntToStr(I), AEsq, 11, Branco);
  Val(140, 7, 15, Branco);
  Val(230, 7, 16, Branco);
  texto(140, 165, IntToStr(SomPendente) + ' / ' + IntToStr(QtdSons), AEsq, 11, Branco);
  texto(140, 180, IntToStr(MusicaAtual) + ' / ' + IntToStr(QtdMusicas), AEsq, 11, Branco);
  Val(140, 10, 4, Branco);
  Val(230, 10, 5, Branco);
  Val(140, 11, 4, Branco);
  Val(230, 11, 5, Branco);
  Val(140, 12, 4, Branco);
  Val(230, 12, 5, Branco);
  texto(200, 280, Linha(TxtConfig, 22), ACentro, 11, Branco);

  { destaque da linha selecionada e dos valores atuais }
  if (CursorMenu >= 1) and (CursorMenu <= 12) then Rot(CursorMenu, Sel);
  texto((NivelJogo - 1) * 10 + 140, 60, IntToStr(NivelJogo), AEsq, 11, Sel);
  case TempoRound of
    1: texto(140, 75, '30', AEsq, 11, Sel);
    2: texto(190, 75, '60', AEsq, 11, Sel);
    3: texto(240, 75, '90', AEsq, 11, Sel);
    4: texto(290, 75, '--', AEsq, 11, Sel);
  end;
  case ModoPoder of
    1: Val(140, 3, 7, Sel);
    2: Val(215, 3, 8, Sel);
    3: Val(280, 3, 9, Sel);
    4: Val(345, 3, 10, Sel);
  end;
  if Sangue then Val(140, 5, 4, Sel);
  if not Sangue then Val(230, 5, 5, Sel);
  texto((NumRounds - 1) * 30 + 140, 135, IntToStr(NumRounds), AEsq, 11, Sel);
  if Idioma = 1 then Val(140, 7, 15, Sel);
  if Idioma = 2 then Val(230, 7, 16, Sel);
  if Flash then Val(140, 10, 4, Sel);
  if not Flash then Val(230, 10, 5, Sel);
  if MostrarNivel then Val(140, 11, 4, Sel);
  if not MostrarNivel then Val(230, 11, 5, Sel);
  if MostrarCreditos then Val(140, 12, 4, Sel);
  if not MostrarCreditos then Val(230, 12, 5, Sel);

  { entrada }
  E := BordaTeclas;
  if (E and 1) <> 0 then Dec(CursorMenu);
  if (E and 2) <> 0 then Inc(CursorMenu);
  if (E and 4) <> 0 then
  begin
    case CursorMenu of
      1: Dec(NivelJogo);
      2: Dec(TempoRound);
      3: Dec(ModoPoder);
      4: NivelDano := NivelDano - 0.1;
      5: Sangue := True;
      6: Dec(NumRounds);
      7: if Idioma = 2 then
         begin
           Idioma := 1;
           CarregarIdioma;
         end;
      8: if SomPendente > 1 then Dec(SomPendente);
      9: if MusicaAtual > 1 then Dec(MusicaAtual);
      10: Flash := True;
      11: MostrarNivel := True;
      12: MostrarCreditos := True;
    end;
  end;
  if (E and 8) <> 0 then
  begin
    case CursorMenu of
      1: Inc(NivelJogo);
      2: Inc(TempoRound);
      3: Inc(ModoPoder);
      4: NivelDano := NivelDano + 0.1;
      5: Sangue := False;
      6: Inc(NumRounds);
      7: if Idioma = 1 then
         begin
           Idioma := 2;
           CarregarIdioma;
         end;
      8: if SomPendente < QtdSons then Inc(SomPendente);
      9: if MusicaAtual < QtdMusicas then Inc(MusicaAtual);
      10: Flash := False;
      11: MostrarNivel := False;
      12: MostrarCreditos := False;
    end;
  end;
  if (E and 16) <> 0 then
  begin
    if CursorMenu = 8 then TocarSom(SomPendente - 1);
    if CursorMenu = 9 then
    begin
      carregarmusica(MusicaAtual);
      if (MusicaAtual <> 0) and (SomMusica.Count > 0) then
        SomMusica.Tocar(0);
    end;
  end;
  if (E and 32) <> 0 then
    if SomMusica.Count > 0 then SomMusica.Parar(0);

  { limites }
  if CursorMenu < 1 then CursorMenu := 12;
  if CursorMenu > 12 then CursorMenu := 1;
  if TempoRound < 1 then TempoRound := 1;
  if TempoRound > 4 then TempoRound := 4;
  if NivelJogo < 1 then NivelJogo := 1;
  if NivelJogo > 8 then NivelJogo := 8;
  if ModoPoder < 1 then ModoPoder := 1;
  if ModoPoder > 4 then ModoPoder := 4;
  if NivelDano < 0.3 then NivelDano := 0.3;
  if NivelDano > 2 then NivelDano := 2.0;
  if NumRounds < 1 then NumRounds := 1;
  if NumRounds > 3 then NumRounds := 3;
  if SomPendente < 1 then SomPendente := 1;
  if SomPendente > QtdSons then SomPendente := QtdSons;
  Y := 0;
  if Y = 1 then Y := 0;
end;

{ Teclado do estado CONFIG: F1 volta a abertura salvando a configuracao }
procedure TJogo.Teclado_Config(Key: Integer);
begin
  if Key = Integer(SDL_SCANCODE_F1) then
  begin
    Estado := CHS_ABERTURA;
    SalvarConfiguracao;
    if SomEfeitos.Count > SomPendente then SomEfeitos.Parar(SomPendente);
    if SomMusica.Count > 0 then SomMusica.Parar(0);
    SomPendente := 0;
    MusicaAtual := 0;
  end;
end;
