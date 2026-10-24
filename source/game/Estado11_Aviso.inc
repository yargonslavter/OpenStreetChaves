{ Estado11_Aviso.inc - Estado CHS_AVISO: aviso final ("obrigado por jogar"). }

procedure TJogo.Estado11_Aviso;
var
  Sup: TSuperficie;
begin
  Sup := Tela;
  barra(0, 0, LarguraTela, AlturaTela, Preto);
  texto(200, 50, Linha(MemoTexto, 25), ACentro, 15, Branco);
  ImgAbertura.PorNome('Logo' + SufixoIdioma).Draw(Sup, 89, 80, 0);
  texto(200, 240, Linha(MemoTexto, 26), ACentro, 10, Branco);
  texto(200, 260, Linha(MemoTexto, 31), ACentro, 10, Branco);
  Inc(TempoEstado);
  if TempoEstado > 200 then
  begin
    Estado := CHS_CONTINUAR;
    ContPisca := 0;
    TempoEstado := 0;
    ContagemSeg := 0;
    ContagemTick := 0;
  end;
end;
