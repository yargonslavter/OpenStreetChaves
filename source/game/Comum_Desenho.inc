{ Comum_Desenho.inc - Primitivas de desenho sobre a tela do jogo (Tela): barra, retangulo, circulo, texto. }

procedure TJogo.barra(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  Tela.PreencherRect(Rect(X1, Y1, X2, Y2), Cor);
end;

procedure TJogo.retangulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  Tela.Moldura(Rect(X1, Y1, X2, Y2), Cor);
end;

procedure TJogo.barraredonda(X1, Y1, X2, Y2, R: Integer; CorBorda, CorFundo: TColor);
begin
  Tela.RoundRect(X1, Y1, X2, Y2, R, R, CorBorda, CorFundo);
end;

procedure TJogo.circulo(X1, Y1, X2, Y2: Integer; Cor: TColor);
begin
  Tela.Elipse(X1, Y1, X2, Y2, Cor, Cor, False);
end;

procedure TJogo.circulopintado(X1, Y1, X2, Y2: Integer; CorBorda, CorFundo: TColor);
begin
  Tela.Elipse(X1, Y1, X2, Y2, CorBorda, CorFundo, True);
end;

{ Alinh: 99 = centralizado em X, 101 = alinhado a direita em X, outro = a esquerda.
  Desenha uma sombra preta deslocada de (+1,+1) antes do texto colorido. }
procedure TJogo.texto(X, Y: Integer; const Texto: string; Alinh: Byte; Tam: Integer; Cor: TColor);
var
  D: Integer;
begin
  D := 0;
  if Alinh = ACentro then D := Round(Tela.LarguraTexto(Texto, Tam) / 2);
  if Alinh = ADir then D := Tela.LarguraTexto(Texto, Tam);
  Tela.Texto(X - D + 1, Y + 1, Texto, Tam, Preto);
  Tela.Texto(X - D, Y, Texto, Tam, Cor);
end;
