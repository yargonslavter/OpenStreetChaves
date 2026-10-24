{ Comum_Quadro.inc - Laco do quadro: despacho dos estados (ExecutarQuadro), rodape comum e memoria das teclas. }

procedure TJogo.ExecutarQuadro;
begin
  if CheatMentecapto then
  begin
    DeslocHudTopo := -90;
    DeslocHudBase := 40;
  end;

  { cada estado e testado em sequencia: uma transicao ja executa o proximo no mesmo quadro }
  if Estado = CHS_RESOLUCAO then Estado0_Resolucao;
  if Estado = CHS_ABERTURA then Estado1_Abertura;
  if Estado = CHS_CONFIG then Estado2_Config;
  if Estado = CHS_TECLAS then Estado3_Teclas;
  if Estado = CHS_SELECAO then Estado4_Selecao;
  if Estado = CHS_ADVERSARIOS then Estado5_Adversarios;
  if Estado = CHS_PREPARALUTA then Estado6_PreparaLuta;
  if Estado = CHS_LUTA then Estado7_Luta;
  if Estado = CHS_RECORDES then Estado8_Recordes;
  if Estado = CHS_CONTINUAR then Estado9_Continuar;
  if Estado = CHS_FINAL then Estado10_Final;
  if Estado = CHS_AVISO then Estado11_Aviso;
  if Estado = CHS_INICIAIS then Estado12_Iniciais;
  RodapeDoQuadro;
end;

{ Sobreposicoes comuns a quase todos os estados + apresentacao do quadro }
procedure TJogo.RodapeDoQuadro;
var
  L: Integer;
begin
  if (Estado <> CHS_CONFIG) and (Estado <> CHS_TECLAS) then
  begin
    if AvisoVelocidade > 0 then
    begin
      texto(200, 260, TextoInterface('Velocidade'), ACentro, 8, Branco);
      L := 238 - Round(IntervaloTimer / 1.05);
      barra(160, 278, 240, 280, Branco);
      barra(L, 275, L + 2, 283, VermelhoAlerta);
      Dec(AvisoVelocidade);
    end;
    if MostrarNivel then
      texto(200, 285, Linha(TxtGeral, 18) + IntToStr(NivelJogo), ACentro, 10, Branco);
    if MostrarCreditos then
    begin
      texto(300, 285, Linha(TxtGeral, 19), AEsq, 10, Branco);
      texto(395, 285, IntToStr(Fichas), ADir, 10, Branco);
    end;
    { aviso "alguem entrou no combate" durante a demonstracao }
    if (AvisoEntrada > 0) and (Estado = CHS_LUTA) then
    begin
      barraredonda(80, 100, 320, 170, 10, Branco, Preto);
      texto(200, 100, Linha(TxtGeral, 10), ACentro, 15, RosaClaro);
      texto(200, 120, Linha(TxtGeral, 11), ACentro, 15, RosaClaro);
      texto(200, 140, Linha(TxtGeral, 12), ACentro, 15, RosaClaro);
      RelogioParado := True;
      Dec(AvisoEntrada);
      if AvisoEntrada = 0 then
      begin
        Estado := CHS_SELECAO;
        FaseSelecao := 1;
        ContagemSeg := 20;
        ContagemTick := 25;
      end;
    end;
  end;
  if Pausado then QuadroAtivo := False;
  MemorizaTeclas;
end;

{ Memoriza o estado das teclas deste quadro (deteccao de borda) e contadores de golpe }
procedure TJogo.MemorizaTeclas;
var
  K1, K2: Byte;
  I: Integer;
begin
  K1 := TecP1;
  K2 := TecP2;
  if ((K1 and 16) <> 0) and not Lutador[1].AntSocoFraco then Inc(Lutador[1].CargaSoco, 6)
  else if ((K1 and 64) <> 0) and not Lutador[1].AntSocoForte then Inc(Lutador[1].CargaSoco, 6);
  if ((K2 and 16) <> 0) and not Lutador[2].AntSocoFraco then Inc(Lutador[2].CargaSoco, 6)
  else if ((K2 and 64) <> 0) and not Lutador[2].AntSocoForte then Inc(Lutador[2].CargaSoco, 6);
  if ((K1 and 32) <> 0) and not Lutador[1].AntChuteFraco then Inc(Lutador[1].CargaChute, 6)
  else if ((K1 and 128) <> 0) and not Lutador[1].AntChuteForte then Inc(Lutador[1].CargaChute, 6);
  if ((K2 and 32) <> 0) and not Lutador[2].AntChuteFraco then Inc(Lutador[2].CargaChute, 6)
  else if ((K2 and 128) <> 0) and not Lutador[2].AntChuteForte then Inc(Lutador[2].CargaChute, 6);

  for I := 1 to 2 do
  begin
    if (Lutador[I].CargaSoco > 0) and (FlashTela = 0) and (PausaImpacto = 0) then Dec(Lutador[I].CargaSoco);
    if (Lutador[I].CargaChute > 0) and (FlashTela = 0) and (PausaImpacto = 0) then Dec(Lutador[I].CargaChute);
    if Lutador[I].CargaSoco > 15 then Lutador[I].CargaSoco := 15;
    if Lutador[I].CargaChute > 15 then Lutador[I].CargaChute := 15;
  end;

  { estado anterior das teclas (para deteccao de borda no proximo quadro) }
  Lutador[1].AntCima := (K1 and 1) <> 0;
  Lutador[1].AntBaixo := (K1 and 2) <> 0;
  Lutador[1].AntEsq := (K1 and 4) <> 0;
  Lutador[1].AntDir := (K1 and 8) <> 0;
  Lutador[1].AntSocoFraco := (K1 and 16) <> 0;
  Lutador[1].AntChuteFraco := (K1 and 32) <> 0;
  Lutador[1].AntSocoForte := (K1 and 64) <> 0;
  Lutador[1].AntChuteForte := (K1 and 128) <> 0;
  Lutador[2].AntCima := (K2 and 1) <> 0;
  Lutador[2].AntBaixo := (K2 and 2) <> 0;
  Lutador[2].AntEsq := (K2 and 4) <> 0;
  Lutador[2].AntDir := (K2 and 8) <> 0;
  Lutador[2].AntSocoFraco := (K2 and 16) <> 0;
  Lutador[2].AntChuteFraco := (K2 and 32) <> 0;
  Lutador[2].AntSocoForte := (K2 and 64) <> 0;
  Lutador[2].AntChuteForte := (K2 and 128) <> 0;
end;
