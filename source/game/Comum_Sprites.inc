{ Comum_Sprites.inc - Desenho de lutadores, animacoes e efeitos (usado pela luta, pelo final e pela abertura). }

{ Desenha o lutador Jog na posicao (X, Y) (pes do lutador), na acao Acao / quadro de acao QuadroAcao.
  Tambem avanca a animacao (AtualizaQuadro) e desenha sombra, caixas de depuracao e o giro do sprite. }
procedure TJogo.desenhalutador(Jog: Byte; X, Y: Integer; Acao, QuadroAcao: Byte);
var
  P, O: PLutador;
  Sup: TSuperficie;
  Base, Jitter: Integer;
  SX, SY, CX, CY, W, H, LX, LY: Integer;
  Item: TImagem;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  Sup := Tela;
  P.Acao := Acao;
  P.QuadroAcao := QuadroAcao;

  // sombra no chao (encolhe com a altura)
  SX := X - 35 - CameraX;
  SY := (ChaoY - 12 - Round((ChaoY - Y) / 12)) - CameraY;
  ImgEfeitos[0].Draw(Sup, SX, SY, 0);

  // parado/andando/agachado no chao: vira para o oponente
  if (Acao = 1) or (Acao = 2) or (Acao = 7) then
    if P.VelY = 0 then
    begin
      if P.X < O.X then P.Lado := 1;
      if P.X >= O.X then P.Lado := 2;
    end;

  if MostrarCaixas = 1 then
  begin
    barra(P.CorpoX1 + X - CameraX, (Y - P.AlturaSprite - CameraY) + P.CorpoY1,
          P.CorpoX2 + X - CameraX, (Y - P.AlturaSprite) + P.CorpoY2 - CameraY, RGB(50, 50, 255));
    if P.GolpeAtivo = 1 then
      barra(P.AtaqueX1 + X - CameraX, (Y - P.AlturaSprite - CameraY) + P.AtaqueY1,
            P.AtaqueX2 + X - CameraX, (Y - P.AlturaSprite) + P.AtaqueY2 - CameraY, VermelhoAlerta);
    retangulo(Round(P.X) - CameraX, 0, Round(P.X) - CameraX, 300, Branco);
    retangulo(0, Round(P.Y) - CameraY, 400, Round(P.Y) - CameraY + 1, Branco);
  end;

  if (FlashTela = 0) and (PausaImpacto = 0) then AtualizaQuadro(Jog);

  if Jog = 1 then Base := 0 else Base := 50;
  if P.Quadro = 0 then P.Quadro := Base + 1;

  // tremida ao apanhar
  Jitter := 0;
  if (P.Acao = 17) or (P.Acao = 18) then Jitter := Random(10) - 5;
  if (P.Acao = 19) and (PausaImpacto > 0) then Jitter := Random(14) - 7;
  if ((P.Acao = 17) or (P.Acao = 18) or (P.Acao = 19)) and (PausaImpacto > 15) then Jitter := Random(20) - 10;

  // giro (derrubado): so gira se nao estiver em pausa
  if (PausaImpacto = 0) and (FlashTela = 0) then P.Angulo := P.Angulo + P.VelAngular;
  if (P.Acao <> 12) and (P.Acao <> 19) then
  begin
    P.Angulo := 0;
    P.VelAngular := 0;
  end;

  if (P.Lado = 1) and (ImgLutador.Count > P.Quadro) then
  begin
    Item := ImgLutador[P.Quadro];
    W := Item.Width;
    H := Item.Height;
    LX := X - CentroX(Jog) + Jitter - CameraX;
    LY := Y - P.AlturaSprite - CameraY;
    if P.VelAngular = 0 then
      Item.Draw(Sup, LX, LY, 0)
    else
    begin
      CX := LX + Round(W / 2);
      CY := Round(H / 2) + LY;
      Item.DrawRotate(Sup, CX, CY, W, P.AlturaSprite, 0, 0.5, 0.5, P.Angulo and 255);
    end;
  end;

  if (P.Lado = 2) and (ImgLutadorInvert.Count > P.Quadro) then
  begin
    Item := ImgLutadorInvert[P.Quadro];
    W := ImgLutador[P.Quadro].Width;
    H := Item.Height;
    LX := CentroX(Jog) + X + Jitter - CameraX - W;
    LY := Y - P.AlturaSprite - CameraY;
    if P.VelAngular = 0 then
      Item.Draw(Sup, LX, LY, 0)
    else
    begin
      CX := CentroX(Jog) + X + Jitter - CameraX - Round(W / 2);
      CY := Round(H / 2) + LY;
      Item.DrawRotate(Sup, CX, CY, W, P.AlturaSprite, 0, 0.5, 0.5, P.Angulo and 255);
    end;
  end;
end;

{ Desenha um quadro de uma lista de imagens (se existir) em (X, Y) da tela. }
procedure TJogo.A_Desenha(Lista: TListaImagens; Idx, X, Y: Integer);
begin
  if (Idx >= 0) and (Idx < Lista.Count) then
  begin
    Lista[Idx].Draw(Tela, X, Y, 0);
  end;
end;

{ Animacoes do cenario (bandeiras, torcida, fogueira, etc.): cada uma troca de quadro conforme
  ContPisca (0..31) e some quando um dos lutadores e o proprio personagem da animacao. }
procedure TJogo.desenhaanimacoes;
var
  J, Rnd: Integer;
begin
  if (CenarioAtual in [1, 5, 6]) and (Lutador[1].Personagem <> 1) and (Lutador[2].Personagem <> 1) then
  begin
    A_Desenha(ImgEfeitos, 0, 230 - CameraX, 257 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 0, 240 - CameraX, 130 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 1, 220 - CameraX, 130 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 2, 240 - CameraX, 130 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 3, 240 - CameraX, 130 - CameraY);
  end;
  if (CenarioAtual in [1, 2, 6]) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    A_Desenha(ImgEfeitos, 0, 385 - CameraX, 260 - CameraY);
    if ContPisca < 10 then A_Desenha(ImgAnimacao, 4, 400 - CameraX, 160 - CameraY);
    if ContPisca >= 10 then A_Desenha(ImgAnimacao, 5, 401 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 9) and (Lutador[2].Personagem <> 9) then A_Desenha(ImgAnimacao, 11, 250 - CameraX, 21 - CameraY);
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(ImgEfeitos, 0, 84 - CameraX, 250 - CameraY);
    A_Desenha(ImgAnimacao, 15, 78 - CameraX, 132 - CameraY);
  end;
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(ImgEfeitos, 0, 470 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 27, 483 - CameraX, 138 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 28, 487 - CameraX, 139 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 27, 483 - CameraX, 138 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 28, 487 - CameraX, 139 - CameraY);
  end;
  if CenarioAtual = 1 then
  begin
    A_Desenha(ImgEfeitos, 0, 160 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 56, 180 - CameraX, 138 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 57, 180 - CameraX, 138 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 58, 180 - CameraX, 138 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 57, 180 - CameraX, 138 - CameraY);
  end;
  if (CenarioAtual = 2) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 9, 170 - CameraX, 155 - CameraY);
    if ContPisca >= 8 then A_Desenha(ImgAnimacao, 10, 170 - CameraX, 155 - CameraY);
  end;
  if (CenarioAtual = 2) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then
  begin
    A_Desenha(ImgEfeitos, 0, 310 - CameraX, 258 - CameraY);
    if ContPisca <= 15 then A_Desenha(ImgAnimacao, 59, 320 - CameraX, 155 - CameraY);
    if ContPisca > 15 then A_Desenha(ImgAnimacao, 60, 320 - CameraX, 155 - CameraY);
  end;
  if (CenarioAtual = 3) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) then
  begin
    A_Desenha(ImgEfeitos, 0, 215 - CameraX, 260 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 6, 230 - CameraX, 140 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 7, 230 - CameraX, 140 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 6, 230 - CameraX, 140 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 7, 230 - CameraX, 140 - CameraY);
  end;
  if (CenarioAtual = 3) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(ImgEfeitos, 0, 62 - CameraX, 240 - CameraY);
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 61, 60 - CameraX, 190 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 62, 55 - CameraX, 189 - CameraY);
  end;
  if (CenarioAtual = 4) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(ImgEfeitos, 0, 315 - CameraX, 235 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 36, 330 - CameraX, 85 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 37, 326 - CameraX, 85 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 36, 330 - CameraX, 85 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 37, 326 - CameraX, 85 - CameraY);
  end;
  if (CenarioAtual = 4) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then
  begin
    A_Desenha(ImgEfeitos, 0, 236 - CameraX, 259 - CameraY);
    A_Desenha(ImgAnimacao, 63, 230 - CameraX, 110 - CameraY);
  end;
  if (CenarioAtual = 5) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(ImgEfeitos, 0, 409 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 12, 420 - CameraX, 154 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 13, 420 - CameraX, 159 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 14, 420 - CameraX, 147 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 13, 420 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 5) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 7) and (Lutador[2].Personagem <> 7) then
  begin
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 32, 370 - CameraX, 110 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 33, 370 - CameraX, 110 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 10) and (Lutador[2].Personagem <> 10) then
  begin
    A_Desenha(ImgEfeitos, 0, 13 - CameraX, 227 - CameraY);
    A_Desenha(ImgAnimacao, 69, 20 - CameraX, 147 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(ImgEfeitos, 0, 79 - CameraX, 235 - CameraY);
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 34, 85 - CameraX, 180 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 20) then A_Desenha(ImgAnimacao, 35, 85 - CameraX, 175 - CameraY);
    if (ContPisca >= 20) and (ContPisca < 28) then A_Desenha(ImgAnimacao, 34, 85 - CameraX, 180 - CameraY);
    if ContPisca >= 28 then A_Desenha(ImgAnimacao, 35, 85 - CameraX, 175 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) then A_Desenha(ImgAnimacao, 8, 460 - CameraX, 145 - CameraY);
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then
  begin
    A_Desenha(ImgEfeitos, 0, 304 - CameraX, 230 - CameraY);
    if ContPisca < 9 then A_Desenha(ImgAnimacao, 64, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 9) and (ContPisca < 12) then A_Desenha(ImgAnimacao, 65, 316 - CameraX, 124 - CameraY);
    if (ContPisca >= 12) and (ContPisca < 15) then A_Desenha(ImgAnimacao, 66, 315 - CameraX, 151 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 18) then A_Desenha(ImgAnimacao, 65, 316 - CameraX, 124 - CameraY);
    if (ContPisca >= 18) and (ContPisca < 21) then A_Desenha(ImgAnimacao, 64, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 21) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 67, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 24) and (ContPisca < 27) then A_Desenha(ImgAnimacao, 68, 324 - CameraX, 90 - CameraY);
    if ContPisca >= 27 then A_Desenha(ImgAnimacao, 67, 326 - CameraX, 90 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 50, 380 - CameraX, 170 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 51, 380 - CameraX, 170 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) then
  begin
    A_Desenha(ImgEfeitos, 0, 466 - CameraX, 255 - CameraY);
    A_Desenha(ImgAnimacao, 52, 480 - CameraX, 130 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    A_Desenha(ImgEfeitos, 0, 73 - CameraX, 253 - CameraY);
    if ContPisca <= 10 then A_Desenha(ImgAnimacao, 53, 80 - CameraX, 140 - CameraY);
    if (ContPisca > 10) and (ContPisca <= 14) then A_Desenha(ImgAnimacao, 54, 88 - CameraX, 146 - CameraY);
    if (ContPisca > 14) and (ContPisca <= 25) then A_Desenha(ImgAnimacao, 55, 89 - CameraX, 148 - CameraY);
    if ContPisca > 25 then A_Desenha(ImgAnimacao, 54, 88 - CameraX, 146 - CameraY);
  end;
  if CenarioAtual = 8 then
  begin
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 16, ((ContPisca shl 2)+200)-CameraX, 255 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 17, (((30-ContPisca) shl 2)+200)-CameraX, 255 - CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 300 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 340 - CameraX, (258-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 380 - CameraX, (252-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 400 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 100 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 130 - CameraX, (160-(Rnd shl 2))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 145 - CameraX, (164-(Rnd shl 2))-CameraY);
    Rnd := Random(3);
    A_Desenha(ImgAnimacao, 18, 165 - CameraX, (162-(Rnd shl 2))-CameraY);
    if ContPisca <= 15 then A_Desenha(ImgAnimacao, 19, 520 - CameraX, 195 - CameraY);
    if ContPisca > 15 then A_Desenha(ImgAnimacao, 20, 520 - CameraX, 195 - CameraY);
    if ContPisca <= 8 then A_Desenha(ImgAnimacao, 21, 110 - CameraX, 175 - CameraY);
    if (ContPisca > 8) and (ContPisca <= 16) then A_Desenha(ImgAnimacao, 22, 114 - CameraX, 182 - CameraY);
    if (ContPisca > 16) and (ContPisca <= 24) then A_Desenha(ImgAnimacao, 21, 110 - CameraX, 175 - CameraY);
    if ContPisca > 24 then A_Desenha(ImgAnimacao, 22, 114 - CameraX, 182 - CameraY);
    if ContPisca <= 15 then A_Desenha(ImgAnimacao, 23, 480 - CameraX, 255 - CameraY);
    if ContPisca > 15 then A_Desenha(ImgAnimacao, 24, 480 - CameraX, 255 - CameraY);
    if ContPisca <= 15 then A_Desenha(ImgAnimacao, 25, 170 - CameraX, 250 - CameraY);
    if ContPisca > 15 then A_Desenha(ImgAnimacao, 26, 170 - CameraX, 250 - CameraY);
    for J := 1 to 5 do
      A_Desenha(ImgAnimacao, 18, Random(2) + 15 * J + (Round((Lutador[1].X + Lutador[2].X) / 2) - 60) - CameraX, 269 - 4 * Random(3) - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 29, 230 - CameraX, 85 - CameraY);
    if (ContPisca >= 8) and (ContPisca <= 16) then A_Desenha(ImgAnimacao, 31, 231 - CameraX, 88 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 27) then A_Desenha(ImgAnimacao, 30, 231 - CameraX, 94 - CameraY);
    if ContPisca >= 27 then A_Desenha(ImgAnimacao, 31, 231 - CameraX, 88 - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 1) and (Lutador[2].Personagem <> 1) then
  begin
    A_Desenha(ImgEfeitos, 0, 400 - CameraX, 215 - CameraY);
    if ContPisca < 5 then A_Desenha(ImgAnimacao, 70, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 5) and (ContPisca < 10) then A_Desenha(ImgAnimacao, 71, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 10) and (ContPisca < 15) then A_Desenha(ImgAnimacao, 72, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 20) then A_Desenha(ImgAnimacao, 70, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 20) and (ContPisca < 25) then A_Desenha(ImgAnimacao, 71, 400 - CameraX, 165 - CameraY);
    if ContPisca >= 25 then A_Desenha(ImgAnimacao, 72, 400 - CameraX, 165 - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    if ContPisca < 11 then A_Desenha(ImgAnimacao, 73, 185 - CameraX, 157 - CameraY);
    if (ContPisca >= 11) and (ContPisca < 22) then A_Desenha(ImgAnimacao, 74, 185 - CameraX, 157 - CameraY);
    if (ContPisca >= 22) and (ContPisca < 26) then A_Desenha(ImgAnimacao, 73, 185 - CameraX, 157 - CameraY);
    if ContPisca >= 26 then A_Desenha(ImgAnimacao, 74, 185 - CameraX, 157 - CameraY);
  end;
  if (CenarioAtual = 10) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then A_Desenha(ImgAnimacao, 38, 380 - CameraX, 138 - CameraY);
  if (CenarioAtual = 10) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then A_Desenha(ImgAnimacao, 39, Random(2) + 150 - CameraX, 138 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then A_Desenha(ImgAnimacao, 75, 387 - CameraX, 152 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then A_Desenha(ImgAnimacao, 76, Random(2) + 120 - CameraX, 82 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 8) and (Lutador[2].Personagem <> 8) then A_Desenha(ImgAnimacao, 77, 310 - CameraX, 110 - CameraY);
  if CenarioAtual = 12 then
  begin
    A_Desenha(ImgEfeitos, 0, 260 - CameraX, 228 - CameraY);
    if ContPisca <= 5 then A_Desenha(ImgAnimacao, 40, 260 - CameraX, 80 - CameraY);
    if (ContPisca > 5) and (ContPisca <= 8) then A_Desenha(ImgAnimacao, 41, 222 - CameraX, 128 - CameraY);
    if (ContPisca > 8) and (ContPisca <= 11) then A_Desenha(ImgAnimacao, 42, 200 - CameraX, 150 - CameraY);
    if (ContPisca > 11) and (ContPisca <= 14) then A_Desenha(ImgAnimacao, 43, 220 - CameraX, 150 - CameraY);
    if (ContPisca > 14) and (ContPisca <= 19) then A_Desenha(ImgAnimacao, 42, 200 - CameraX, 150 - CameraY);
    if (ContPisca > 19) and (ContPisca <= 22) then A_Desenha(ImgAnimacao, 41, 222 - CameraX, 128 - CameraY);
    if (ContPisca > 22) and (ContPisca <= 30) then A_Desenha(ImgAnimacao, 40, 260 - CameraX, 80 - CameraY);
    A_Desenha(ImgIcone, 13, 225 - CameraX, 134 - CameraY - Round(-Cos((ContPisca - 11) / 5) * 70));
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) then
  begin
    A_Desenha(ImgEfeitos, 0, 135 - CameraX, 255 - CameraY);
    A_Desenha(ImgAnimacao, 44, 140 - CameraX, 160 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(ImgEfeitos, 0, 295 - CameraX, 263 - CameraY);
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 45, 290 - CameraX, 120 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 46, 292 - CameraX, 118 - CameraY);
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 47, 257 - CameraX, 55 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 47, 259 - CameraX, 53 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(ImgEfeitos, 0, 9 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 12, 20 - CameraX, 154 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 13, 20 - CameraX, 159 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 14, 20 - CameraX, 147 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 13, 20 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then
  begin
    A_Desenha(ImgEfeitos, 0, 539 - CameraX, 268 - CameraY);
    if ContPisca < 8 then A_Desenha(ImgAnimacao, 48, 550 - CameraX, 160 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(ImgAnimacao, 49, 552 - CameraX, 161 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(ImgAnimacao, 48, 550 - CameraX, 160 - CameraY);
    if ContPisca >= 24 then A_Desenha(ImgAnimacao, 49, 552 - CameraX, 161 - CameraY);
  end;
end;


{ Lista dos golpes de cada personagem: nome ("*" = golpe especial final) e sequencia de teclas.
  Cada letra da sequencia vira um icone da lista de icones (C, B, D, E, Y, Z) ou um texto:
  P = "+S" (soco), K = "+C" (chute), R = "(rapido)", ? = "+S/C". }
type
  TGolpeInfo = record
    N: string;
    S: string;
  end;

const
  GolpesDoPersonagem: array[1..15, 1..5] of TGolpeInfo = (
    ((N: 'Power Wave'; S: 'BDP'), (N: 'Burn Knuckle'; S: 'BEP'), (N: 'Rising Tackle'; S: 'BCP'), (N: 'Crack Shoot'; S: 'BEK'), (N: '*Power Geyser'; S: 'BEBDP')),
    ((N: 'Ryuu Geki Ken'; S: 'BDP'), (N: 'RyuuGa'; S: 'DBDP'), (N: 'Genei Kyaku'; S: 'DEDK'), (N: 'Hien Ryuu Jin Kyaku'; S: 'CBEK'), (N: '*Ryuko Ranbu'; S: 'BDBEP')),
    ((N: 'Ko Ou Ken'; S: 'BDP'), (N: 'Kuu Ga'; S: 'DBDP'), (N: 'Hien Senpuuken'; S: 'BEP'), (N: 'Hien Senpuukyaku'; S: 'BEK'), (N: '*Hien Honou Kyaku'; S: 'BDBEK')),
    ((N: 'Hi Sho Ken'; S: 'BEP'), (N: 'Zan Ei Ken'; S: 'YDP'), (N: 'Ku Ha Dan'; S: 'EBDK'), (N: 'Sho Ryu Dan'; S: 'BDP'), (N: '*Cho Reppa Da'; S: 'BEBDK')),
    ((N: 'Souhakkei'; S: 'BDP'), (N: 'Sen en Shuu'; S: 'BEK'), (N: 'Spinning Bird Kick'; S: 'BCK'), (N: 'Hyakuretsu Kyaku'; S: 'KR'), (N: '*Senretsu Kyaku'; S: 'BDBDK')),
    ((N: 'Tiger Shot'; S: 'BDP'), (N: 'Low Tiger Shot'; S: 'BDK'), (N: 'Tiger Blow'; S: 'DBDP'), (N: 'Tiger Crush'; S: 'DBDK'), (N: '*Tiger Cannon'; S: 'BDBDK')),
    ((N: 'Tekkyu Dai Kaiten'; S: 'PR'), (N: 'Tekkyu FunsaiGeki'; S: 'EDP'), (N: 'Tekkyu Hi En Zan'; S: 'BCK'), (N: 'Ricchi Futoi'; S: 'BCP'), (N: '*Tekkyu Dai Bouson'; S: 'BDBEP')),
    ((N: 'Chaos Flare'; S: 'BDP'), (N: 'Chaos Flare (AR)'; S: 'CBDP'), (N: 'Demon Cradle'; S: 'DBDP'), (N: 'Bat Spin'; S: 'BEK'), (N: '*Demon Horde'; S: 'BDBDK')),
    ((N: 'Cannon Drill'; S: 'BDK'), (N: 'Cannon Spike'; S: 'DBDK'), (N: 'Accel S. Knuckle'; S: 'BDP'), (N: 'Cannon Strike (AR)'; S: 'CBEK'), (N: '*Spin D. Smasher'; S: 'BDBDK')),
    ((N: 'Hyakuretsu Harite'; S: 'PR'), (N: 'Super Zutsuki'; S: 'EDP'), (N: 'Super Hyakkan Otoshi'; S: 'BCK'), (N: 'Biggu Hara'; S: 'BDK'), (N: '*Onimussou'; S: 'EDEDP')),
    ((N: 'Bad Stone'; S: 'BDP'), (N: 'Criminal Upper'; S: 'BEP'), (N: 'Raffian Kick'; S: 'BDK'), (N: 'Bushin Hurricane'; S: 'BEK'), (N: '*Dead End Irony'; S: 'BDBDK')),
    ((N: 'Gadouken'; S: 'BDP'), (N: 'Kouryuken'; S: 'DBDP'), (N: 'Dankuu Kyaku'; S: 'BEK'), (N: 'Dankuu Kyaku (AR)'; S: 'CBEK'), (N: '*Kouryuu Rekka'; S: 'BDBDK')),
    ((N: 'Psycho Shot'; S: 'BDP'), (N: 'Double Knee Press'; S: 'BDK'), (N: 'Psycho Field'; S: 'BEP'), (N: 'Jaiminho Warp'; S: 'DBD?'), (N: '*Psycho Crusher'; S: 'EDEDP')),
    ((N: 'Psycho Ball Attack'; S: 'BEP'), (N: 'Psycho Reflector'; S: 'BEK'), (N: 'Phoenix Arrow (AR)'; S: 'BEK'), (N: 'Psycho Sword'; S: 'DBDP'), (N: '*Shining Crystal Bit'; S: 'BEBEP')),
    ((N: 'KaChoSen'; S: 'BDP'), (N: 'RyuEnBu'; S: 'BEP'), (N: 'Hisho RyuEnJin'; S: 'DBDK'), (N: 'Hissatsu Shinobibachi'; S: 'BDK'), (N: '*Cho Hissatsu S.'; S: 'BEBDK'))
  );

{ Processa e desenha os efeitos (fagulhas, sangue, bolas de fogo, textos, itens...).
  Para cada efeito ativo: escolhe o sprite pelo tipo/quadro, move, desenha e testa colisao com
  os outros efeitos e com os lutadores; no fim controla a vida util. }
procedure TJogo.desenhaefeitos;
var
  I, J, K, W2, H2: Integer;
  E, F: PEfeito;
  P, O: PLutador;
  Sup: TSuperficie;
  Pisca: Boolean;
begin
  Sup := Tela;
  for I := 1 to MaxEfeitos do
  begin
    E := @Efeitos[I];
    if E.Tipo = 0 then Continue;

    { ---- sprite e estagio conforme o tipo e o quadro de animacao ---- }
    if E.Tipo = 1 then
    begin
      if E.Quadro = 0 then E.Sprite := 1;
      if E.Quadro = 1 then E.Sprite := 2;
      if E.Quadro = 3 then E.Sprite := 3;
    end;
    if E.Tipo = 2 then
    begin
      if E.Quadro = 0 then E.Sprite := 4;
      if E.Quadro = 3 then E.Sprite := 5;
      if E.Quadro = 6 then E.Sprite := 6;
      if E.Quadro = 9 then E.Sprite := 7;
      if E.Quadro = 12 then E.Sprite := 8;
      if (FlashTela = 0) and (PausaImpacto = 0) then E.Y := E.Y - 1;
    end;
    if E.Tipo = 3 then
    begin
      E.Sprite := 10;
      if E.Quadro >= E.Duracao - 20 then E.Estagio := 1;
    end;
    if E.Tipo = 4 then
    begin
      E.Sprite := 11;
      if E.Quadro >= E.Duracao - 20 then E.Estagio := 1;
    end;
    if E.Tipo = 5 then
    begin
      if E.Quadro >= E.Duracao - 10 then E.Estagio := 1;
    end;
    if E.Tipo = 6 then
    begin
      E.Sprite := 12;
    end;
    if E.Tipo = 7 then
    begin
      if E.Quadro = 0 then E.Sprite := 13;
      if E.Quadro = 1 then E.Sprite := 13;
      if E.Quadro = 2 then E.Sprite := 14;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 8 then
    begin
      if E.Quadro = 0 then E.Sprite := 15;
      if E.Quadro = 2 then E.Sprite := 16;
      if E.Quadro = 5 then E.Sprite := 17;
      if E.Quadro = 5 then E.Estagio := 1;
    end;
    if E.Tipo = 9 then
    begin
      if E.Quadro = 0 then E.Sprite := 18;
      if E.Quadro = 1 then E.Sprite := 18;
      if E.Quadro = 2 then E.Sprite := 19;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 10 then
    begin
      if E.Quadro = 0 then E.Sprite := 20;
      if E.Quadro = 2 then E.Sprite := 21;
      if E.Quadro = 4 then E.Sprite := 22;
      if E.Quadro = 6 then E.Sprite := 23;
      if E.Quadro = 8 then E.Sprite := 24;
      if E.Quadro = 10 then E.Sprite := 25;
      if E.Quadro = 12 then E.Sprite := 26;
    end;
    if E.Tipo = 11 then
    begin
      if E.Quadro = 0 then E.Sprite := 27;
      if E.Quadro = 3 then E.Sprite := 28;
      if E.Quadro = 6 then E.Sprite := 29;
      if E.Quadro = 9 then E.Sprite := 30;
      if E.Quadro = 12 then E.Sprite := 31;
    end;
    if E.Tipo = 12 then
    begin
      if E.Quadro = 0 then E.Sprite := 32;
      if E.Quadro = 1 then E.Sprite := 32;
      if E.Quadro = 2 then E.Sprite := 33;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 13 then
    begin
      if E.Quadro = 0 then E.Sprite := 34;
      if E.Quadro = 1 then E.Sprite := 34;
      if E.Quadro = 2 then E.Sprite := 35;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 14 then
    begin
      if E.Quadro = 0 then E.Sprite := 36;
      if E.Quadro = 2 then E.Sprite := 37;
      if E.Quadro = 4 then E.Sprite := 38;
    end;
    if E.Tipo = 15 then
    begin
      if E.Quadro = 0 then E.Sprite := 39;
      if E.Quadro = 1 then E.Sprite := 39;
      if E.Quadro = 2 then E.Sprite := 40;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 16 then
    begin
      if E.Quadro = 0 then E.Sprite := 41;
      if E.Quadro = 2 then E.Sprite := 42;
      if E.Quadro = 4 then E.Sprite := 43;
    end;
    if E.Tipo = 17 then
    begin
      if E.Quadro = 0 then E.Sprite := 44;
      if E.Quadro = 4 then E.Sprite := 45;
      if E.Quadro = 8 then E.Sprite := 46;
    end;
    if E.Tipo = 18 then
    begin
      if E.Quadro = 0 then E.Sprite := 47;
      if E.Quadro = 1 then E.Sprite := 47;
      if E.Quadro = 2 then E.Sprite := 48;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 19 then
    begin
      if E.Quadro = 0 then E.Sprite := 49;
      if E.Quadro = 1 then E.Sprite := 49;
      if E.Quadro = 2 then E.Sprite := 50;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 20 then
    begin
      if E.Quadro = 0 then E.Sprite := 51;
      if E.Quadro = 1 then E.Sprite := 51;
      if E.Quadro = 2 then E.Sprite := 52;
      if E.Quadro = 3 then E.Quadro := 0;
    end;
    if E.Tipo = 23 then
    begin
      if E.Quadro = 0 then E.Sprite := 57;
      if E.Quadro = 2 then E.Sprite := 58;
      if E.Quadro = 4 then E.Sprite := 57;
      if E.Quadro = 6 then E.Sprite := 58;
      if E.Quadro = 8 then E.Sprite := 57;
      if E.Quadro = 10 then E.Sprite := 58;
      if E.Quadro = 12 then E.Sprite := 57;
      if E.Quadro = 14 then E.Sprite := 58;
      if E.Quadro = 16 then E.Sprite := 57;
      if E.Quadro = 18 then E.Sprite := 58;
      if E.Quadro = 20 then E.Sprite := 57;
      if E.Quadro = 22 then E.Sprite := 79;
      if E.Quadro = 24 then E.Sprite := 60;
    end;
    if E.Tipo = 24 then
    begin
      if E.Quadro < E.Duracao - 10 then E.Sprite := 61;
      if E.Quadro >= E.Duracao - 10 then E.Sprite := 62;
    end;
    if E.Tipo = 25 then
    begin
      if E.Quadro < 12 then E.Sprite := 63;
      if (E.Quadro >= 12) and (E.Quadro < 24) then E.Sprite := 64;
      if E.Quadro >= 24 then E.Sprite := 65;
    end;
    if E.Tipo = 26 then
    begin
      if E.Quadro = 0 then E.Sprite := 66;
      if E.Quadro = 1 then E.Sprite := 66;
      if E.Quadro = 4 then E.Sprite := 67;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 27 then
    begin
      if E.Quadro = 0 then E.Sprite := 68;
      if E.Quadro = 1 then E.Sprite := 68;
      if E.Quadro = 4 then E.Sprite := 69;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 28 then
    begin
      if E.Quadro = 0 then E.Sprite := 70;
      if E.Quadro = 1 then E.Sprite := 70;
      if E.Quadro = 3 then E.Sprite := 71;
      if E.Quadro = 4 then E.Quadro := 0;
    end;
    if E.Tipo = 29 then
    begin
      if E.Quadro = 0 then E.Sprite := 72;
      if E.Quadro = 2 then E.Sprite := 72;
      if E.Quadro = 4 then E.Sprite := 73;
      if E.Quadro = 5 then E.Sprite := 74;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 30 then
    begin
      if E.Quadro = 0 then E.Sprite := 75;
      if E.Quadro = 1 then E.Sprite := 75;
      if E.Quadro = 4 then E.Sprite := 76;
      if E.Quadro = 5 then E.Quadro := 0;
      if E.Contagem >= E.LimiteContagem - 10 then E.Sprite := 77;
      if E.Contagem >= E.LimiteContagem - 7 then E.Sprite := 78;
      if E.Contagem >= E.LimiteContagem - 4 then E.Sprite := 79;
    end;
    if E.Tipo = 31 then
    begin
      if E.Quadro = 2 then E.Sprite := 72;
      if E.Quadro = 4 then E.Sprite := 73;
      if E.Quadro = 5 then E.Sprite := 74;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 32 then
    begin
      if E.Quadro < 2 then E.Sprite := 72;
      if E.Quadro = 2 then E.Sprite := 72;
      if E.Quadro = 4 then E.Sprite := 73;
      if E.Quadro = 5 then E.Sprite := 74;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 33 then
    begin
      if E.Quadro = 0 then E.Sprite := 80;
      if E.Quadro = 1 then E.Sprite := 80;
      if E.Quadro = 2 then E.Sprite := 81;
      if E.Quadro = 4 then E.Sprite := 82;
      if E.Quadro = 5 then E.Sprite := 83;
      if E.Quadro = 6 then E.Quadro := 0;
    end;
    if E.Tipo = 34 then
    begin
      if E.Quadro = 0 then E.Sprite := 84;
      if E.Quadro = 3 then E.Sprite := 85;
      if E.Quadro = 6 then E.Sprite := 86;
      if E.Quadro = 9 then E.Sprite := 87;
      if E.Quadro = 12 then E.Sprite := 88;
      if E.Quadro = 15 then E.Sprite := 89;
      if E.Quadro = 18 then E.Sprite := 90;
    end;
    if E.Tipo = 35 then
    begin
      if E.Quadro = 0 then E.Sprite := 91;
      if E.Quadro = 2 then E.Sprite := 92;
      if E.Quadro = 4 then E.Sprite := 93;
      if E.Quadro = 6 then E.Sprite := 94;
      if E.Quadro = 8 then E.Sprite := 95;
    end;
    if E.Tipo = 36 then
    begin
      if E.Quadro = 0 then E.Sprite := 96;
      if E.Quadro = 2 then E.Sprite := 97;
      if E.Quadro = 4 then E.Sprite := 98;
      if E.Quadro = 6 then E.Sprite := 99;
      if E.Quadro = 8 then E.Sprite := 100;
    end;

    { ---- caixas de colisao dos efeitos que as tem ---- }
    if (E.Tipo = 8) and (E.Quadro = 2) then DefineCaixaEfeito(I, -45, -150, 45, 0);
    if (E.Tipo = 8) and (E.Quadro = 5) then DefineCaixaEfeito(I, -45, -220, 45, 0);
    if (E.Tipo = 8) and ((E.Quadro = 6) or (E.Quadro = 12)) then
    begin
      E.PodeAcertar := 1;
      Inc(E.Quadro);
    end;
    if (E.Tipo = 28) and ((E.Contagem = 3) or (E.Contagem = 6) or (E.Contagem = 9)) then
    begin
      E.PodeAcertar := 1;
      Inc(E.Contagem);
    end;

    { ---- tipos 31/32: orbitam o dono ---- }
    if E.Tipo = 31 then
    begin
      E.X := Round(Cos(E.Contagem / 3) * 70) + Lutador[E.Dono].X;
      E.Y := Round(Cos(E.Contagem / 3) * 70) + (Lutador[E.Dono].Y - 80);
    end;
    if E.Tipo = 32 then
    begin
      E.X := Lutador[E.Dono].X - Round(Cos(E.Contagem / 3) * 70);
      E.Y := Round(Cos(E.Contagem / 3) * 70) + (Lutador[E.Dono].Y - 80);
    end;
    if (E.Tipo = 31) or (E.Tipo = 32) then
      if E.Contagem mod 10 = 0 then
      begin
        E.PodeAcertar := 1;
        Inc(E.Contagem);
        if Lutador[E.Dono].Acao <> 29 then E.Tipo := 0;
      end;
    if (E.Tipo = 30) and (Lutador[E.Dono].Acao <> 26) then E.Tipo := 0;
    if (E.Tipo = 34) and (E.Quadro >= 14) then E.PodeAcertar := 0;
    if E.Tipo = 24 then
    begin
      E.X := Round(Cos(E.Quadro) * 2) + E.X;
      E.Y := E.Y - 1;
    end;

    { ---- gravidade ---- }
    if (E.Flag52 = 1) and (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      E.Y := E.VelY + E.Y;
      E.VelY := E.VelY + 4;
      if (ChaoY - 5) < E.Y then
      begin
        E.Y := ChaoY - 5;
        E.Vel := 0;
        E.VelY := 0;
        if E.Tipo = 22 then
        begin
          E.Estagio := 1;
          E.PodeAcertar := 0;
        end;
      end;
    end;

    { ---- deslocamento ---- }
    if (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      if E.Lado = 1 then E.X := E.Vel + E.X;
      if E.Lado = 2 then E.X := E.X - E.Vel;
      if E.Tipo = 19 then E.Y := E.Vel + E.Y;
      if E.Tipo = 20 then E.Y := Random(13) + (E.Y - 7);
    end;

    if MostrarCaixas = 1 then
      barra(Round(E.X) + E.CaixaX1 - CameraX, Round(E.Y) + E.CaixaY1 - CameraY,
        Round(E.X) + E.CaixaX2 - CameraX, Round(E.Y) + E.CaixaY2 - CameraY, RGB(50, 255, 50));

    { ---- desenho ---- }
    if (ImgEfeitos.Count > E.Sprite) and (E.Tipo <> 5) then
    begin
      W2 := Round(ImgEfeitos[E.Sprite].Width / 2);
      H2 := Round(ImgEfeitos[E.Sprite].Height / 2);
      if E.Flag51 = 1 then H2 := ImgEfeitos[E.Sprite].Height;
      Pisca := (E.Estagio = 0) or ((E.Estagio = 1) and (ContPisca mod 2 = 0));
      if Pisca then
      begin
        if E.Lado = 1 then
          ImgEfeitos[E.Sprite].Draw(Sup, Round(E.X) - CameraX - W2, Round(E.Y) - CameraY - H2, 0);
        if E.Lado = 2 then
          ImgEfeitosInvert[E.Sprite].Draw(Sup, Round(E.X) - CameraX - W2, Round(E.Y) - CameraY - H2, 0);
      end;
    end;

    { ---- tipo 5: texto que sobe ---- }
    if E.Tipo = 5 then
    begin
      if (E.Estagio = 0) or ((E.Estagio = 1) and (ContPisca mod 2 = 0)) then
        texto(Round(E.X) - CameraX, Round(E.Y) - CameraY, Linha(MemoTexto, 5), ACentro, 10, VerdeBonus);
      if FlashTela = 0 then E.Y := E.Y - 5;
    end;

    { ---- colisao com os outros efeitos ---- }
    for J := 1 to MaxEfeitos do
    begin
      F := @Efeitos[J];
      if (E.CaixaX2 + E.X > F.CaixaX1 + F.X) and (E.CaixaX1 + E.X < F.CaixaX2 + F.X) and
         (E.CaixaY2 + E.Y > F.CaixaY1 + F.Y) and (E.CaixaY1 + E.Y < F.CaixaY2 + F.Y) and
         (F.PodeAcertar = 1) and (E.PodeAcertar = 1) and (F.Tipo <> 0) and (E.Tipo <> 0) and
         (F.Dano > 0) and (E.Dano > 0) and (J <> I) then
      begin
        if E.Flag50 = 1 then
        begin
          F.Dono := E.Dono;
          F.Lado := Lutador[E.Dono].Lado;
        end;
        if F.Flag50 = 1 then
        begin
          E.Dono := F.Dono;
          E.Lado := Lutador[F.Dono].Lado;
        end;
        if F.Dono <> E.Dono then
        begin
          if E.Terminando = 0 then
          begin
            CriaEfeito(1, '', 0, E.X, E.Y);
            E.Tipo := 0;
          end;
          if F.Terminando = 0 then
          begin
            CriaEfeito(1, '', 0, F.X, F.Y);
            F.Tipo := 0;
          end;
        end;
      end;
    end;

    { ---- colisao com os lutadores ---- }
    for K := 1 to 2 do
    begin
      P := @Lutador[K];
      O := @Lutador[3 - K];
      if (E.CaixaX2 + E.X > P.CorpoX1 + P.X) and (E.CaixaX1 + E.X < P.CorpoX2 + P.X) and
         (E.CaixaY2 + E.Y > (P.Y - P.AlturaSprite) + P.CorpoY1) and
         (E.CaixaY1 + E.Y < (P.Y - P.AlturaSprite) + P.CorpoY2) then
      begin
        { acertou quem estava defendendo }
        if (P.Defendendo = 1) and (E.PodeAcertar = 1) and (E.Dano > 0) and (K <> E.Dono) then
        begin
          P.QuadroAcao := 1;
          SomPendente := 10;
          CriaEfeito(14, '', 0, E.X, E.Y);
          if P.Lado = 1 then Empurra(K, -10);
          if P.Lado = 2 then Empurra(K, 10);
          if (AvisoEntrada = 0) and (RelogioParado = 0) then
          begin
            P.Vida := P.Vida - E.DanoDefesa * NivelDano;
            P.AtrasoBarra := 20;
          end;
          if P.Vida <= 0 then
          begin
            SomPendente := 9;
            AcaoJogador(K, 10);
          end;
          if E.Terminando = 0 then E.Tipo := 0;
          E.PodeAcertar := 0;
          if P.Vida > 0 then PausaImpacto := 2;
        end;

        { acertou quem estava desprotegido }
        if (E.PodeAcertar = 1) and (E.Dano > 0) and (P.Vencedor = 0) and (K <> E.Dono) and (P.Defendendo = 0) then
        begin
          if P.X < O.X then P.Lado := 1;
          if P.X >= O.X then P.Lado := 2;
          SomPendente := 9;
          CriaEfeito(1, '', 0, E.X, E.Y);
          if (Flash = 1) and (Random(3) = 0) then FlashVermelho := 4;
          if ((Sangue = 1) and (Random(3) = 0)) or (CheatSatanas = 1) then
            CriaEfeito(10, '', 0, P.X, P.Y - (P.AlturaSprite - 40));
          if (O.Ativo = 1) and (P.Vida > 0) then O.Pontos := O.Pontos + 10;
          if O.TempoAcertos <= 35 then O.Acertos := 0;
          Inc(O.Acertos);
          O.TempoAcertos := 50;
          if (AvisoEntrada = 0) and (RelogioParado = 0) then
          begin
            P.Vida := P.Vida - E.Dano * NivelDano;
            if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
            P.AtrasoBarra := 20;
          end;
          if (E.Variante = 1) or (P.VelY <> 0) or (P.Vida <= 0) then AcaoJogador(K, 10);
          AcaoJogador(K, 9);
          P.Recuo := 8;
          if PrimeiroAtaque = 0 then
          begin
            O.MsgBonus := 1;
            O.TempoMsgBonus := 50;
            if O.Ativo = 1 then O.Pontos := O.Pontos + 300;
            PrimeiroAtaque := 1;
          end;
          O.DesenhaPorCima := 1;
          P.DesenhaPorCima := 0;
          if P.Vida > 0 then PausaImpacto := 5;
          if E.Tipo = 8 then
          begin
            P.Recuo := 10;
            P.VelY := -60;
          end;
          if E.Tipo = 20 then
          begin
            P.VelY := -20;
            P.Vencedor := 0;
            P.Recuo := 6;
          end;
          if (E.Tipo = 8) or (E.Tipo = 20) then
          begin
            P.Acao := 19;
            if P.Lado = 1 then P.VelAngular := -20;
            if P.Lado = 2 then P.VelAngular := 20;
          end;
          if E.Terminando = 0 then E.Tipo := 0;
          E.PodeAcertar := 0;
          AtualizaQuadro(K);
        end;

        { energeticos: curam ao tocar }
        if ((E.Tipo = 3) or (E.Tipo = 4)) and (E.Quadro > 13) and (P.Vida > 0) and (RelogioParado = 0) then
        begin
          if AvisoEntrada = 0 then
          begin
            if E.Tipo = 3 then P.Vida := 20 * NivelDano + P.Vida;
            if E.Tipo = 4 then P.Vida := 30 * NivelDano + P.Vida;
          end;
          SomPendente := 11;
          CriaEfeito(5, '', 0, E.X, E.Y);
          E.Tipo := 0;
        end;
      end;
    end;

    { ---- vida util ---- }
    if (E.Duracao <> 99) and (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      Inc(E.Quadro);
      if E.Quadro > E.Duracao then E.Tipo := 0;
    end;
    if (E.LimiteContagem <> 0) and (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      Inc(E.Contagem);
      if E.Tipo = 27 then
      begin
        if E.Contagem >= E.LimiteContagem - 2 then E.PodeAcertar := 1;
        if E.Contagem >= E.LimiteContagem then
        begin
          CriaEfeito(28, 'A', E.Dono, E.X - 30, E.Y + 20);
          CriaEfeito(28, 'A', E.Dono, E.X + 30, E.Y + 20);
          CriaEfeito(28, 'A', E.Dono, E.X, E.Y - 40);
        end;
      end;
      if E.Contagem >= E.LimiteContagem then E.Tipo := 0;
    end;

    { ---- saiu da tela / bateu no chao ---- }
    if CameraX - 50 > E.X then E.Tipo := 0;
    if CameraX + 450 < E.X then E.Tipo := 0;
    if CameraY - 50 > E.Y then E.Tipo := 0;
    if (ChaoY < E.CaixaY2 + E.Y) and (E.Tipo = 19) then
    begin
      E.Tipo := 0;
      CriaEfeito(1, '', 0, E.X, E.Y);
    end;
  end;
end;
