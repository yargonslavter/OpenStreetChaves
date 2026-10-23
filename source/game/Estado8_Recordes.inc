{ Estado8_Recordes.inc - Estado CHS_RECORDES: tabela de recordes. }

procedure TJogo.Estado8_Recordes;
var
  Sup: TSuperficie;
  L, Pos, Y, Idx: Integer;
  Pisca: Integer;
  Cor: TColor;
  Rotulo: string;
begin
  Sup := Tela;
  for L := 0 to 20 do
    barra(0, L * 20, LarguraTela, L * 20 + 20, RGB(L * 5 + 100, L * 5 + 130, L * 5 + 160));
  for Pos := 1 to 10 do
  begin
    Pisca := 0;
    if (Pos = 1) and (ContPisca mod 2 = 0) then Pisca := 80;
    Cor := RGB(255, 255 - Pisca, 255 - Pisca);
    Y := Pos * 60 - 350 - CameraY;
    if Pos < 10 then Rotulo := '0' + IntToStr(Pos) + ' -' else Rotulo := IntToStr(Pos) + ' -';
    texto(50, Y, Rotulo, AEsq, 15, Cor);
    texto(100, Y, Recordes[Pos].Nome, AEsq, 15, Cor);
    Idx := (Recordes[Pos].Personagem - 1) * 5;
    if (Idx >= 0) and (Idx < ImgRetrato.Count) then
    begin
      ImgRetrato[Idx].Draw(Sup, 160, Pos * 60 - 370 - CameraY, 0);
    end;
    texto(230, Y, IntToStr(Recordes[Pos].Pontos), AEsq, 15, Cor);
  end;
  // cortina que fecha no fim
  if TempoEstado > 240 then
    for L := 0 to 15 do
      barra(0, L * 20, LarguraTela, L * 20 + (TempoEstado - 240), Preto);
  if ContPisca < 18 then texto(200, 5, Linha(MemoTexto, 21), ACentro, 12, Branco);
  if ContPisca < 10 then texto(200, 240, Linha(MemoTexto, 6), ACentro, 10, Branco);
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  Inc(TempoEstado);
  if TempoEstado > 1000 then TempoEstado := 1000;
  if TempoEstado > 80 then Dec(CameraY, 5);
  if CameraY < -320 then CameraY := -320;
  if TempoEstado > 280 then
  begin
    Estado := CHS_ABERTURA;
    ContPisca := 0;
    TempoEstado := 0;
    CameraY := 0;
  end;
end;
