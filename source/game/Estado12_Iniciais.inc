{ Estado12_Iniciais.inc - Estado CHS_INICIAIS: digitacao das iniciais de quem entrou nos recordes. }

procedure TJogo.Estado12_Iniciais;
var
  J, X: Integer;
  P: PLutador;
  K: Byte;
begin
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  Inc(ContPisca);
  if ContPisca > 20 then ContPisca := 0;
  Inc(TempoEstado);
  if TempoEstado > 1000 then TempoEstado := 1000;

  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    if Recordes[10].Pontos >= Cardinal(P.Pontos) then Continue;
    X := (J - 1) * 200 + 20;
    texto(X, 5, P.Iniciais[1], AEsq, 15, Branco);
    texto(X + 15, 5, P.Iniciais[2], AEsq, 15, Branco);
    texto(X + 30, 5, P.Iniciais[3], AEsq, 15, Branco);
    if ContPisca < 15 then texto(X + (P.CursorIni - 1) * 15, 4, '-', AEsq, 27, Branco);

    if J = 1 then K := TecP1 else K := TecP2;
    if ((K and 4) <> 0) and (P.AntEsq = 0) then Dec(P.CursorIni);
    if ((K and 8) <> 0) and (P.AntDir = 0) then Inc(P.CursorIni);
    if P.CursorIni < 1 then P.CursorIni := 1;
    if P.CursorIni > 3 then P.CursorIni := 3;
    if ((K and 1) <> 0) and (P.AntCima = 0) then P.Iniciais[P.CursorIni] := Chr(Ord(P.Iniciais[P.CursorIni]) + 1);
    if ((K and 2) <> 0) and (P.AntBaixo = 0) then P.Iniciais[P.CursorIni] := Chr(Ord(P.Iniciais[P.CursorIni]) - 1);
    if Ord(P.Iniciais[P.CursorIni]) < 48 then P.Iniciais[P.CursorIni] := Chr(48);
    if Ord(P.Iniciais[P.CursorIni]) > 90 then P.Iniciais[P.CursorIni] := Chr(90);
    if ((K and 16) <> 0) and (P.AntSocoFraco = 0) then Inc(P.CursorIni);

    // confirmou (3 letras) ou o tempo acabou
    if (P.CursorIni > 3) or (TempoEstado = 1000) then
    begin
      if P.Ativo = 0 then
      begin
        Estado := CHS_CONTINUAR;
        ContPisca := 0;
        TempoEstado := 0;
        ContagemSeg := 9;
        ContagemTick := 25;
        criarecorde(10, P.Iniciais, P.Personagem, P.Pontos);
        ordenarecordista;
      end
      else
      begin
        Estado := CHS_FINAL;
        ContPisca := 0;
        TempoEstado := 0;
        criarecorde(10, P.Iniciais, P.Personagem, P.Pontos);
        ordenarecordista;
      end;
    end;
  end;
end;
