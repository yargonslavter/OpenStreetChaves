{ AcertosAntigo.inc - L7_Acertos como era no codigo, antes das regras de personagem irem para os
  roteiros [Acerto]. So e usado com CONFERIR_ROTEIRO ligado (ChavesJogo.pas). Quando a conferencia
  terminar, este arquivo sera apagado. }

procedure TJogo.L7_AcertosAntigo(Jog: Byte);
var
  P, O: PLutador;
  O_Jog: Byte;
  MX, MY: Integer;
  RX, RY: Integer;
  Giro: Boolean;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  O_Jog := 3 - Jog;

  // apanhando: empurrao para tras e poeira
  if ((P.Acao = acApanhaAlto) or (P.Acao = acApanhaBaixo)) and (FlashTela = 0) and (PausaImpacto = 0) then
  begin
    if P.Lado = ldDireita then Empurra(Jog, -P.Recuo);
    if P.Lado = ldEsquerda then Empurra(Jog, P.Recuo);
    if Sortear(2) = 0 then
    begin
      RX := Sortear(40);
      RY := Sortear(10);
      CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
    end;
  end;

  // caixa do golpe de P e caixa do corpo do oponente (coordenadas da tela)
  AtqX1 := Round(P.X) + P.AtaqueX1;
  AtqY1 := (Round(P.Y) - P.AlturaSprite) + P.AtaqueY1;
  AtqX2 := Round(P.X) + P.AtaqueX2;
  AtqY2 := (Round(P.Y) - P.AlturaSprite) + P.AtaqueY2;
  AlvoX1 := Round(O.X) + O.CorpoX1;
  AlvoY1 := (Round(O.Y) - O.AlturaSprite) + O.CorpoY1;
  AlvoX2 := Round(O.X) + O.CorpoX2;
  AlvoY2 := (Round(O.Y) - O.AlturaSprite) + O.CorpoY2;

  if P.GolpeAtivo and not O.Invulneravel and
     (AtqX1 < AlvoX2) and (AtqX2 > AlvoX1) and (AtqY1 < AlvoY2) and (AtqY2 > AlvoY1) and
     (PausaImpacto = 0) and (FlashTela = 0) then
  begin
    // ponto medio da caixa do golpe (onde aparece a faisca)
    MX := Round((P.AtaqueX1 + P.AtaqueX2) / 2);
    MY := Round((P.AtaqueY1 + P.AtaqueY2) / 2);

    // golpe alto/baixo vence a guarda errada
    if ((P.Acao = acAgChuteFraco) or (P.Acao = acAgChuteForte)) and (O.Acao = acDefesa) then O.Defendendo := False;
    if ((P.Acao = acArSocoFraco) or (P.Acao = acArChuteFraco) or (P.Acao = acArSocoForte) or (P.Acao = acArChuteForte)) and (O.Acao = acDefesaBaixa) then O.Defendendo := False;

    if O.Defendendo then
    begin
      // ---- defendido ----
      O.QuadroAcao := 1;
      SomPendente := sndDefesa;
      CriaEfeito(14, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      if O.Lado = ldDireita then Empurra(O_Jog, -10);
      if O.Lado = ldEsquerda then Empurra(O_Jog, 10);
      if (AvisoEntrada = 0) and not RelogioParado then
      begin
        O.Vida := O.Vida - P.DanoDefesa * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := sndAcertoEspecial;
        AcaoJogador(O_Jog, cmDerrubar);
      end;
      P.GolpeAtivo := False;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = fgFraco then PausaImpacto := Sortear(4) + 2;
        if P.ForcaGolpe = fgForte then PausaImpacto := Sortear(4) + 4;
      end;
    end;

    if not O.Defendendo then
    begin
      // ---- acertou ----
      if O.X < P.X then O.Lado := ldDireita;
      if O.X >= P.X then O.Lado := ldEsquerda;
      if P.Ativo and (O.Vida > 0) and (PausaImpacto = 0) and (FlashTela = 0) then
        P.Pontos := P.Pontos + 5;
      if P.CargaPoder < CargaMax then P.CargaPoder := P.CargaPoder + 2 * GanhoCarga;
      if O.CargaPoder < CargaMax then O.CargaPoder := O.CargaPoder + 1 * GanhoCarga;
      // combo
      if P.TempoAcertos <= 35 then P.Acertos := 0;
      Inc(P.Acertos);
      P.TempoAcertos := 44;
      if (P.Acao = acAgChuteForte) or (P.Acao = acArChuteForte) then P.TempoAcertos := 50;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial2) then P.TempoAcertos := 46;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial3) then P.TempoAcertos := 47;
      if (P.Personagem = pnProfGirafales) and (P.Acao = acEspecial5) then P.TempoAcertos := 50;
      if (P.Personagem = pnGloria) and (P.Acao = acEspecial3) then P.TempoAcertos := 50;
      if (AvisoEntrada = 0) and not RelogioParado then
      begin
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if Flash then
      begin
        if (P.ForcaGolpe = fgFraco) and (Sortear(5) = 0) then FlashVermelho := 6;
        if (P.ForcaGolpe = fgForte) and (Sortear(2) = 0) then FlashVermelho := 6;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := sndAcertoForte;
        AcaoJogador(O_Jog, cmDerrubar);
      end;
      // golpes que fazem o oponente girar no ar
      Giro := ((P.Personagem = pnQuico) and (P.Acao = acEspecial5)) or
              ((P.Personagem = pnDonaFlorinda) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = pnProfGirafales) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 22)) or
              ((P.Personagem = pnPaty) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 14)) or
              ((P.Personagem = pnNhonho) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = pnGodines) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 20)) or
              ((P.Personagem = pnSrFurtado) and (P.Acao = acEspecial4) and (P.QuadroAcao >= 22));
      if Giro then
      begin
        if O.Lado = ldDireita then O.VelAngular := -20;
        if O.Lado = ldEsquerda then O.VelAngular := 20;
      end;
      CriaEfeito(1, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      // sangue
      if (Sangue and (P.ForcaGolpe = fgForte) and (Sortear(5) = 0)) or CheatSatanas then
        CriaEfeito(10, '', 0, O.X, O.Y - (O.AlturaSprite - 40));
      // reacao do oponente
      if (P.Acao = acChuteFraco) or (P.Acao = acChuteForte) or (P.Acao = acAgSocoFraco) or (P.Acao = acAgChuteFraco) or (P.Acao = acAgSocoForte) then
        AcaoJogador(O_Jog, cmApanharBaixo)
      else
        AcaoJogador(O_Jog, cmApanharAlto);
      if P.EhChute or (O.VelY <> 0) or (ChaoY > O.Y) then AcaoJogador(O_Jog, cmDerrubar);
      // recuo (empurrao) do oponente
      O.Recuo := 4;
      if (P.Personagem = pnChaves) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 20;
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 13;
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial5) then O.Recuo := 20;
      if (P.Personagem = pnProfGirafales) and (P.Acao = acEspecial3) and (P.ForcaGolpe = fgForte) then O.Recuo := 25;
      if (P.Personagem = pnSrBarriga) and (P.Acao = acEspecial3) and (P.ForcaGolpe = fgForte) then O.Recuo := 18;
      if (P.Personagem = pnPaty) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15) then O.Recuo := 25;
      if (P.Personagem = pnNhonho) and (P.Acao = acEspecial4) and (P.ForcaGolpe = fgForte) then O.Recuo := 13;
      if (P.Personagem = pnSrFurtado) and (P.Acao = acEspecial2) and (P.ForcaGolpe = fgForte) then O.Recuo := 25;
      // lancamento para cima
      if (P.Personagem = pnQuico) and (P.Acao = acEspecial5) then O.VelY := -30;
      if (P.Personagem = pnDonaFlorinda) and (P.Acao = acEspecial5) and (P.QuadroAcao >= 15) then O.VelY := -30;
      if (P.Personagem = pnGloria) and (P.Acao = acEspecial3) then O.VelY := -26;
      if P.ForcaGolpe = fgFraco then SomPendente := sndAcertoFraco;
      if P.ForcaGolpe = fgForte then SomPendente := sndAcertoForte;
      if P.ForcaGolpe = fgEspecial then SomPendente := sndAcertoEspecial;
      // primeiro ataque do round
      if not PrimeiroAtaque then
      begin
        P.MsgBonus := 1;
        P.TempoMsgBonus := 50;
        if P.Ativo and (PausaImpacto = 0) and (FlashTela = 0) then P.Pontos := P.Pontos + 300;
        PrimeiroAtaque := True;
      end;
      P.DesenhaPorCima := True;
      O.DesenhaPorCima := False;
      P.GolpeAtivo := False;
      O.GolpeAtivo := False;
      // golpes encadeados (continuam em outra acao)
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial4) then
      begin
        P.Acao := acEspecial5;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnSeuMadruga) and (P.Acao = acEspecial6) then
      begin
        P.Acao := acEspecial7;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 40;
        Inc(P.Acertos);
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnChiquinha) and (P.Acao = acEspecial5) then
      begin
        P.Acao := acEspecial6;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := False;
      end;
      if (P.Personagem = pnSrBarriga) and (P.Acao = acEspecial5) then
      begin
        P.Acao := acEspecial6;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        O.GolpeAtivo := False;
      end;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = fgFraco then PausaImpacto := Sortear(4) + 5;
        if P.ForcaGolpe = fgForte then PausaImpacto := Sortear(4) + 7;
      end;
      AtualizaQuadro(O_Jog);
    end;

    // oponente encostado na borda da tela: o atacante recua
    if not RelogioParado then
    begin
      if CameraX + 370 <= O.X then Empurra(Jog, -12);
      if CameraX + 30 >= O.X then Empurra(Jog, 12);
    end;
  end;
end;
