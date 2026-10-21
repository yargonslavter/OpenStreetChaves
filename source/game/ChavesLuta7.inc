{ ChavesLuta7.inc - desenho e fluxo da luta (estado 7). Incluido em ChavesPrj.pas. }

{ Desenha o lutador Jog na posicao (X, Y) (pes do lutador), na acao Acao / quadro de acao QuadroAcao.
  Tambem avanca a animacao (AtualizaQuadro) e desenha sombra, caixas de depuracao e o giro do sprite. }
procedure TForm1.desenhalutador(Jog: Byte; X, Y: Integer; Acao, QuadroAcao: Byte);
var
  P, O: PLutador;
  Sup: TDirectDrawSurface;
  Base, Jitter: Integer;
  SX, SY, CX, CY, W, H, LX, LY: Integer;
  Item: TPictureCollectionItem;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  Sup := DXDraw1.Surface;
  P.Acao := Acao;
  P.QuadroAcao := QuadroAcao;
  Sup.Canvas.Release;

  // sombra no chao (encolhe com a altura)
  SX := X - 35 - CameraX;
  SY := (ChaoY - 12 - Round((ChaoY - Y) / 12)) - CameraY;
  DXImageListEfeitos.Items[0].Draw(Sup, SX, SY, 0);

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

  if (P.Lado = 1) and (DXImageListLutador.Items.Count > P.Quadro) then
  begin
    Item := DXImageListLutador.Items[P.Quadro];
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

  if (P.Lado = 2) and (DXImageListLutadorInvert.Items.Count > P.Quadro) then
  begin
    Item := DXImageListLutadorInvert.Items[P.Quadro];
    W := DXImageListLutador.Items[P.Quadro].Width;
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

{ ===================================================================== }
{ Partes do estado 7 (luta). Cada rotina L7_* corresponde a um trecho do }
{ procedimento original, na mesma ordem em que eram executados.          }
{ ===================================================================== }

{ Desenha um quadro de uma lista de imagens (se existir) em (X, Y) da tela. }
procedure TForm1.A_Desenha(Lista: TDXImageList; Idx, X, Y: Integer);
begin
  if (Idx >= 0) and (Idx < Lista.Items.Count) then
  begin
    DXDraw1.Surface.Canvas.Release;
    Lista.Items[Idx].Draw(DXDraw1.Surface, X, Y, 0);
  end;
end;

{ Animacoes do cenario (bandeiras, torcida, fogueira, etc.): cada uma troca de quadro conforme
  ContPisca (0..31) e some quando um dos lutadores e o proprio personagem da animacao. }
procedure TForm1.desenhaanimacoes;
var
  J, Rnd: Integer;
begin
  if (CenarioAtual in [1, 5, 6]) and (Lutador[1].Personagem <> 1) and (Lutador[2].Personagem <> 1) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 230 - CameraX, 257 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 0, 240 - CameraX, 130 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 1, 220 - CameraX, 130 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 2, 240 - CameraX, 130 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 3, 240 - CameraX, 130 - CameraY);
  end;
  if (CenarioAtual in [1, 2, 6]) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 385 - CameraX, 260 - CameraY);
    if ContPisca < 10 then A_Desenha(DXImageListAnimacao, 4, 400 - CameraX, 160 - CameraY);
    if ContPisca >= 10 then A_Desenha(DXImageListAnimacao, 5, 401 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 9) and (Lutador[2].Personagem <> 9) then A_Desenha(DXImageListAnimacao, 11, 250 - CameraX, 21 - CameraY);
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 84 - CameraX, 250 - CameraY);
    A_Desenha(DXImageListAnimacao, 15, 78 - CameraX, 132 - CameraY);
  end;
  if (CenarioAtual = 1) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 470 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 27, 483 - CameraX, 138 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 28, 487 - CameraX, 139 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 27, 483 - CameraX, 138 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 28, 487 - CameraX, 139 - CameraY);
  end;
  if CenarioAtual = 1 then
  begin
    A_Desenha(DXImageListEfeitos, 0, 160 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 56, 180 - CameraX, 138 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 57, 180 - CameraX, 138 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 58, 180 - CameraX, 138 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 57, 180 - CameraX, 138 - CameraY);
  end;
  if (CenarioAtual = 2) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 9, 170 - CameraX, 155 - CameraY);
    if ContPisca >= 8 then A_Desenha(DXImageListAnimacao, 10, 170 - CameraX, 155 - CameraY);
  end;
  if (CenarioAtual = 2) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 310 - CameraX, 258 - CameraY);
    if ContPisca <= 15 then A_Desenha(DXImageListAnimacao, 59, 320 - CameraX, 155 - CameraY);
    if ContPisca > 15 then A_Desenha(DXImageListAnimacao, 60, 320 - CameraX, 155 - CameraY);
  end;
  if (CenarioAtual = 3) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 215 - CameraX, 260 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 6, 230 - CameraX, 140 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 7, 230 - CameraX, 140 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 6, 230 - CameraX, 140 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 7, 230 - CameraX, 140 - CameraY);
  end;
  if (CenarioAtual = 3) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 62 - CameraX, 240 - CameraY);
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 61, 60 - CameraX, 190 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 62, 55 - CameraX, 189 - CameraY);
  end;
  if (CenarioAtual = 4) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 315 - CameraX, 235 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 36, 330 - CameraX, 85 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 37, 326 - CameraX, 85 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 36, 330 - CameraX, 85 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 37, 326 - CameraX, 85 - CameraY);
  end;
  if (CenarioAtual = 4) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 236 - CameraX, 259 - CameraY);
    A_Desenha(DXImageListAnimacao, 63, 230 - CameraX, 110 - CameraY);
  end;
  if (CenarioAtual = 5) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 409 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 12, 420 - CameraX, 154 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 13, 420 - CameraX, 159 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 14, 420 - CameraX, 147 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 13, 420 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 5) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 7) and (Lutador[2].Personagem <> 7) then
  begin
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 32, 370 - CameraX, 110 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 33, 370 - CameraX, 110 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 10) and (Lutador[2].Personagem <> 10) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 13 - CameraX, 227 - CameraY);
    A_Desenha(DXImageListAnimacao, 69, 20 - CameraX, 147 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 79 - CameraX, 235 - CameraY);
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 34, 85 - CameraX, 180 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 20) then A_Desenha(DXImageListAnimacao, 35, 85 - CameraX, 175 - CameraY);
    if (ContPisca >= 20) and (ContPisca < 28) then A_Desenha(DXImageListAnimacao, 34, 85 - CameraX, 180 - CameraY);
    if ContPisca >= 28 then A_Desenha(DXImageListAnimacao, 35, 85 - CameraX, 175 - CameraY);
  end;
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) then A_Desenha(DXImageListAnimacao, 8, 460 - CameraX, 145 - CameraY);
  if (CenarioAtual = 6) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 304 - CameraX, 230 - CameraY);
    if ContPisca < 9 then A_Desenha(DXImageListAnimacao, 64, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 9) and (ContPisca < 12) then A_Desenha(DXImageListAnimacao, 65, 316 - CameraX, 124 - CameraY);
    if (ContPisca >= 12) and (ContPisca < 15) then A_Desenha(DXImageListAnimacao, 66, 315 - CameraX, 151 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 18) then A_Desenha(DXImageListAnimacao, 65, 316 - CameraX, 124 - CameraY);
    if (ContPisca >= 18) and (ContPisca < 21) then A_Desenha(DXImageListAnimacao, 64, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 21) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 67, 326 - CameraX, 90 - CameraY);
    if (ContPisca >= 24) and (ContPisca < 27) then A_Desenha(DXImageListAnimacao, 68, 324 - CameraX, 90 - CameraY);
    if ContPisca >= 27 then A_Desenha(DXImageListAnimacao, 67, 326 - CameraX, 90 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 50, 380 - CameraX, 170 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 51, 380 - CameraX, 170 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 466 - CameraX, 255 - CameraY);
    A_Desenha(DXImageListAnimacao, 52, 480 - CameraX, 130 - CameraY);
  end;
  if (CenarioAtual = 7) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 73 - CameraX, 253 - CameraY);
    if ContPisca <= 10 then A_Desenha(DXImageListAnimacao, 53, 80 - CameraX, 140 - CameraY);
    if (ContPisca > 10) and (ContPisca <= 14) then A_Desenha(DXImageListAnimacao, 54, 88 - CameraX, 146 - CameraY);
    if (ContPisca > 14) and (ContPisca <= 25) then A_Desenha(DXImageListAnimacao, 55, 89 - CameraX, 148 - CameraY);
    if ContPisca > 25 then A_Desenha(DXImageListAnimacao, 54, 88 - CameraX, 146 - CameraY);
  end;
  if CenarioAtual = 8 then
  begin
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 16, ((ContPisca shl 2)+200)-CameraX, 255 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 17, (((30-ContPisca) shl 2)+200)-CameraX, 255 - CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 300 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 340 - CameraX, (258-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 380 - CameraX, (252-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 400 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 100 - CameraX, (255-(Rnd+(Rnd*2)))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 130 - CameraX, (160-(Rnd shl 2))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 145 - CameraX, (164-(Rnd shl 2))-CameraY);
    Rnd := Random(3);
    A_Desenha(DXImageListAnimacao, 18, 165 - CameraX, (162-(Rnd shl 2))-CameraY);
    if ContPisca <= 15 then A_Desenha(DXImageListAnimacao, 19, 520 - CameraX, 195 - CameraY);
    if ContPisca > 15 then A_Desenha(DXImageListAnimacao, 20, 520 - CameraX, 195 - CameraY);
    if ContPisca <= 8 then A_Desenha(DXImageListAnimacao, 21, 110 - CameraX, 175 - CameraY);
    if (ContPisca > 8) and (ContPisca <= 16) then A_Desenha(DXImageListAnimacao, 22, 114 - CameraX, 182 - CameraY);
    if (ContPisca > 16) and (ContPisca <= 24) then A_Desenha(DXImageListAnimacao, 21, 110 - CameraX, 175 - CameraY);
    if ContPisca > 24 then A_Desenha(DXImageListAnimacao, 22, 114 - CameraX, 182 - CameraY);
    if ContPisca <= 15 then A_Desenha(DXImageListAnimacao, 23, 480 - CameraX, 255 - CameraY);
    if ContPisca > 15 then A_Desenha(DXImageListAnimacao, 24, 480 - CameraX, 255 - CameraY);
    if ContPisca <= 15 then A_Desenha(DXImageListAnimacao, 25, 170 - CameraX, 250 - CameraY);
    if ContPisca > 15 then A_Desenha(DXImageListAnimacao, 26, 170 - CameraX, 250 - CameraY);
    for J := 1 to 5 do
      A_Desenha(DXImageListAnimacao, 18, Random(2) + 15 * J + (Round((Lutador[1].X + Lutador[2].X) / 2) - 60) - CameraX, 269 - 4 * Random(3) - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 29, 230 - CameraX, 85 - CameraY);
    if (ContPisca >= 8) and (ContPisca <= 16) then A_Desenha(DXImageListAnimacao, 31, 231 - CameraX, 88 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 27) then A_Desenha(DXImageListAnimacao, 30, 231 - CameraX, 94 - CameraY);
    if ContPisca >= 27 then A_Desenha(DXImageListAnimacao, 31, 231 - CameraX, 88 - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 1) and (Lutador[2].Personagem <> 1) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 400 - CameraX, 215 - CameraY);
    if ContPisca < 5 then A_Desenha(DXImageListAnimacao, 70, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 5) and (ContPisca < 10) then A_Desenha(DXImageListAnimacao, 71, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 10) and (ContPisca < 15) then A_Desenha(DXImageListAnimacao, 72, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 15) and (ContPisca < 20) then A_Desenha(DXImageListAnimacao, 70, 400 - CameraX, 165 - CameraY);
    if (ContPisca >= 20) and (ContPisca < 25) then A_Desenha(DXImageListAnimacao, 71, 400 - CameraX, 165 - CameraY);
    if ContPisca >= 25 then A_Desenha(DXImageListAnimacao, 72, 400 - CameraX, 165 - CameraY);
  end;
  if (CenarioAtual = 9) and (Lutador[1].Personagem <> 3) and (Lutador[2].Personagem <> 3) then
  begin
    if ContPisca < 11 then A_Desenha(DXImageListAnimacao, 73, 185 - CameraX, 157 - CameraY);
    if (ContPisca >= 11) and (ContPisca < 22) then A_Desenha(DXImageListAnimacao, 74, 185 - CameraX, 157 - CameraY);
    if (ContPisca >= 22) and (ContPisca < 26) then A_Desenha(DXImageListAnimacao, 73, 185 - CameraX, 157 - CameraY);
    if ContPisca >= 26 then A_Desenha(DXImageListAnimacao, 74, 185 - CameraX, 157 - CameraY);
  end;
  if (CenarioAtual = 10) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then A_Desenha(DXImageListAnimacao, 38, 380 - CameraX, 138 - CameraY);
  if (CenarioAtual = 10) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then A_Desenha(DXImageListAnimacao, 39, Random(2) + 150 - CameraX, 138 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 5) and (Lutador[2].Personagem <> 5) and (Lutador[1].Personagem <> 6) and (Lutador[2].Personagem <> 6) then A_Desenha(DXImageListAnimacao, 75, 387 - CameraX, 152 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then A_Desenha(DXImageListAnimacao, 76, Random(2) + 120 - CameraX, 82 - CameraY);
  if (CenarioAtual = 11) and (Lutador[1].Personagem <> 8) and (Lutador[2].Personagem <> 8) then A_Desenha(DXImageListAnimacao, 77, 310 - CameraX, 110 - CameraY);
  if CenarioAtual = 12 then
  begin
    A_Desenha(DXImageListEfeitos, 0, 260 - CameraX, 228 - CameraY);
    if ContPisca <= 5 then A_Desenha(DXImageListAnimacao, 40, 260 - CameraX, 80 - CameraY);
    if (ContPisca > 5) and (ContPisca <= 8) then A_Desenha(DXImageListAnimacao, 41, 222 - CameraX, 128 - CameraY);
    if (ContPisca > 8) and (ContPisca <= 11) then A_Desenha(DXImageListAnimacao, 42, 200 - CameraX, 150 - CameraY);
    if (ContPisca > 11) and (ContPisca <= 14) then A_Desenha(DXImageListAnimacao, 43, 220 - CameraX, 150 - CameraY);
    if (ContPisca > 14) and (ContPisca <= 19) then A_Desenha(DXImageListAnimacao, 42, 200 - CameraX, 150 - CameraY);
    if (ContPisca > 19) and (ContPisca <= 22) then A_Desenha(DXImageListAnimacao, 41, 222 - CameraX, 128 - CameraY);
    if (ContPisca > 22) and (ContPisca <= 30) then A_Desenha(DXImageListAnimacao, 40, 260 - CameraX, 80 - CameraY);
    A_Desenha(DXImageListIcone, 13, 225 - CameraX, 134 - CameraY - Round(-Cos((ContPisca - 11) / 5) * 70));
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 11) and (Lutador[2].Personagem <> 11) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 135 - CameraX, 255 - CameraY);
    A_Desenha(DXImageListAnimacao, 44, 140 - CameraX, 160 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 2) and (Lutador[2].Personagem <> 2) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 295 - CameraX, 263 - CameraY);
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 45, 290 - CameraX, 120 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 46, 292 - CameraX, 118 - CameraY);
    if ContPisca < 15 then A_Desenha(DXImageListAnimacao, 47, 257 - CameraX, 55 - CameraY);
    if ContPisca >= 15 then A_Desenha(DXImageListAnimacao, 47, 259 - CameraX, 53 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 4) and (Lutador[2].Personagem <> 4) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 9 - CameraX, 255 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 12, 20 - CameraX, 154 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 13, 20 - CameraX, 159 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 14, 20 - CameraX, 147 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 13, 20 - CameraX, 159 - CameraY);
  end;
  if (CenarioAtual = 12) and (Lutador[1].Personagem <> 14) and (Lutador[2].Personagem <> 14) then
  begin
    A_Desenha(DXImageListEfeitos, 0, 539 - CameraX, 268 - CameraY);
    if ContPisca < 8 then A_Desenha(DXImageListAnimacao, 48, 550 - CameraX, 160 - CameraY);
    if (ContPisca >= 8) and (ContPisca < 16) then A_Desenha(DXImageListAnimacao, 49, 552 - CameraX, 161 - CameraY);
    if (ContPisca >= 16) and (ContPisca < 24) then A_Desenha(DXImageListAnimacao, 48, 550 - CameraX, 160 - CameraY);
    if ContPisca >= 24 then A_Desenha(DXImageListAnimacao, 49, 552 - CameraX, 161 - CameraY);
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

{ Escreve o nome do golpe e, em seguida, os icones (e textos) da sequencia de teclas. }
procedure TForm1.mostrasequencia(X, Y: Integer; const Nome, Seq: string);
var
  I, DX: Integer;
  Cor: TColor;
  C: Char;
begin
  Cor := Branco;
  if (Nome <> '') and (Nome[1] = '*') then Cor := RGB(255, 120, 120);
  texto(X, Y, Nome + ' - ', AEsq, 9, Cor);
  DX := DXDraw1.Surface.Canvas.TextWidth(Nome + ' - ');
  for I := 1 to Length(Seq) do
  begin
    C := Seq[I];
    DXDraw1.Surface.Canvas.Release;
    case C of
      'C': A_Desenha(DXImageListIcone, 0, X + DX, Y + 3);
      'B': A_Desenha(DXImageListIcone, 1, X + DX, Y + 3);
      'D': A_Desenha(DXImageListIcone, 2, X + DX, Y + 3);
      'E': A_Desenha(DXImageListIcone, 3, X + DX, Y + 3);
      'Y': A_Desenha(DXImageListIcone, 4, X + DX, Y + 3);
      'Z': A_Desenha(DXImageListIcone, 5, X + DX, Y + 3);
      'P': texto(X + DX, Y, '+S', AEsq, 9, Branco);
      'K': texto(X + DX, Y, '+C', AEsq, 9, Branco);
      'R': texto(X + DX, Y, ' (rápido)', AEsq, 9, Branco);
      '?': texto(X + DX, Y, '+S/C', AEsq, 9, Branco);
    end;
    Inc(DX, 12);
  end;
end;

{ Modo passo a passo: mostra, para cada jogador, os golpes do personagem escolhido. }
procedure TForm1.mostragolpe;
var
  J, K, X, Y: Integer;
  Pers: Byte;
begin
  Y := 120;
  for J := 1 to 2 do
  begin
    X := (J - 1) * 200;
    barra(X + 3, Y - 5, X + 197, Y + 80, RGB(20, 40, 60));
    retangulo(X + 3, Y - 5, X + 197, Y + 80, Branco);
    Pers := Lutador[J].Personagem;
    if (Pers >= 1) and (Pers <= 15) then
      for K := 1 to 5 do
        mostrasequencia(X + 6, Y + (K - 1) * 15, GolpesDoPersonagem[Pers, K].N, GolpesDoPersonagem[Pers, K].S);
  end;
end;

{ Processa e desenha os efeitos (fagulhas, sangue, bolas de fogo, textos, itens...).
  Para cada efeito ativo: escolhe o sprite pelo tipo/quadro, move, desenha e testa colisao com
  os outros efeitos e com os lutadores; no fim controla a vida util. }
procedure TForm1.desenhaefeitos;
var
  I, J, K, W2, H2: Integer;
  E, F: PEfeito;
  P, O: PLutador;
  Sup: TDirectDrawSurface;
  Pisca: Boolean;
begin
  Sup := DXDraw1.Surface;
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
    Sup.Canvas.Release;
    if (DXImageListEfeitos.Items.Count > E.Sprite) and (E.Tipo <> 5) then
    begin
      W2 := Round(DXImageListEfeitos.Items[E.Sprite].Width / 2);
      H2 := Round(DXImageListEfeitos.Items[E.Sprite].Height / 2);
      if E.Flag51 = 1 then H2 := DXImageListEfeitos.Items[E.Sprite].Height;
      Pisca := (E.Estagio = 0) or ((E.Estagio = 1) and (ContPisca mod 2 = 0));
      if Pisca then
      begin
        if E.Lado = 1 then
          DXImageListEfeitos.Items[E.Sprite].Draw(Sup, Round(E.X) - CameraX - W2, Round(E.Y) - CameraY - H2, 0);
        if E.Lado = 2 then
          DXImageListEfeitosInvert.Items[E.Sprite].Draw(Sup, Round(E.X) - CameraX - W2, Round(E.Y) - CameraY - H2, 0);
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

{ Posicionamento inicial do round 1: os lutadores entram pulando pelos lados. }
procedure TForm1.L7_Prepara;
var
  I: Integer;
begin
  ChaoY := 300;
  if (RoundAtual = 1) and (FaseIntro = 0) then
  begin
    Lutador[1].X := 0;
    Lutador[1].DirPulo := 3;
    Lutador[2].X := 600;
    Lutador[2].DirPulo := 2;
    for I := 1 to 2 do
    begin
      Lutador[I].Y := ChaoY;
      Lutador[I].NoAr := 1;
      Lutador[I].VelY := -25;
      Lutador[I].Quadro := 21;
      Lutador[I].Acao := 12;
      Lutador[I].QuadroAcao := 0;
      Lutador[I].DuracaoAcao := 99;
    end;
    RelogioParado := 1;
    CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  end;
  // chefe (fase 8): dialogo antes da luta quando ha um computador
  if (Fase = 8) and (RoundAtual = 1) and (FaseIntro = 1) and
     ((Lutador[1].Ativo = 0) or (Lutador[2].Ativo = 0)) then
  begin
    TempoDialogo := 600;
    FaseIntro := 2;
    DeslocHudTopo := -120;
    DeslocHudBase := 60;
  end;
  if TempoDialogo > 0 then Dec(TempoDialogo);
end;

{ Toca musica/som pendentes, pisca a tela, move a camera e desenha o cenario. }
procedure TForm1.L7_CenarioECamera;
var
  Sup: TDirectDrawSurface;
  Desloc, C, L: Integer;
begin
  Sup := DXDraw1.Surface;
  if (MusicaAtual <> 0) and (MusicaPendente = 1) and (DXWaveListMusica.Items.Count > 0) then
  begin
    DXWaveListMusica.Items[0].Play(False);
    MusicaPendente := 0;
  end;
  if SomPendente <> 0 then
    if DXWaveListSnd.Items.Count > SomPendente then
    begin
      DXWaveListSnd.Items[SomPendente].Play(False);
      SomPendente := 0;
    end;

  if FlashTela > 0 then
  begin
    Dec(FlashTela);
    Desloc := 0;
    if FlashTela mod 2 = 0 then Desloc := 20;
    if FlashTela mod 3 = 0 then Desloc := 40;
    if FlashTela mod 4 = 0 then Desloc := 60;
    if FlashTela mod 5 = 0 then Desloc := 80;
    for C := 0 to 5 do
      for L := 0 to 4 do
        DXImageListIcone.Items[7].Draw(Sup, C * 100 - 80 + Desloc, L * 100, 0);
  end;

  if RelogioParado = 0 then
  begin
    CameraX := Round((Lutador[1].X + Lutador[2].X) / 2) - 200;
    CameraY := Round((Lutador[1].Y + Lutador[2].Y) / 8) - 55;
  end;
  if TremorTela > 0 then
  begin
    Dec(TremorTela);
    CameraX := Random(20) + (CameraX - 10);
    CameraY := Random(20) + (CameraY - 10);
  end;
  if CameraX < 0 then CameraX := 0;
  if CameraX > 200 then CameraX := 200;
  if CameraY < 0 then CameraY := 0;
  if CameraY > 20 then CameraY := 20;

  Sup.Canvas.Release;
  if FlashTela = 0 then
  begin
    if (DXImageListCenario.Items.Count > 0) and (DXImageListCenario.Items[0].Surface <> nil) then
    begin
      DXImageListCenario.Items[0].Draw(Sup, -CameraX, -CameraY, 0);
      desenhaanimacoes;
    end
    else
      barra(0, 0, LarguraTela, AlturaTela, Preto);
  end;
end;

{ Cabecalho: "FASE n", relogio redondo e contagem regressiva do round. }
procedure TForm1.L7_Relogio;
var
  T: Integer;
  Cor: TColor;
begin
  T := DeslocHudTopo;
  texto(200, T + 3, Linha(MemoTexto, 29) + ' ' + IntToStr(Fase), ACentro, 7, Branco);
  barraredonda(170, T + 15, 230, T + 54, 15, Branco, Branco);
  barraredonda(172, T + 17, 228, T + 52, 15, CinzaClaro, CinzaClaro);
  barraredonda(174, T + 19, 226, T + 50, 15, Preto, Preto);
  if TempoRound <> 4 then
  begin
    Cor := VermelhoAlerta;
    if ContagemTick <= 2 then Cor := RosaPalido;
    if ContagemSeg >= 10 then texto(200, T + 10, IntToStr(ContagemSeg), ACentro, 25, Cor);
    if ContagemSeg < 10 then texto(200, T + 10, '0' + IntToStr(ContagemSeg), ACentro, 25, Cor);
    if (ContagemSeg < 10) and (ContagemTick mod 2 = 0) then
      texto(200, T + 10, '0' + IntToStr(ContagemSeg), ACentro, 25, RosaPalido);
    if (FlashTela = 0) and (PausaImpacto = 0) and (RelogioParado = 0) then Dec(ContagemTick);
    if ContagemTick = 0 then
    begin
      ContagemTick := 25;
      if ContagemSeg > 0 then Dec(ContagemSeg);
    end;
  end;
end;

{ Barra de energia, retrato, nome, rounds ganhos e placar do lutador Jog (parte de cima). }
procedure TForm1.L7_HudCima(Jog: Byte);
var
  P: PLutador;
  T, Mult, I, X0, X1: Integer;
  Cor: TColor;
begin
  P := @Lutador[Jog];
  T := DeslocHudTopo;
  if (Lutador[1].Vida > 0) and (Lutador[2].Vida > 0) then P.Vida := P.Vida + BonusEnergeticos;
  if TempoDemo > 0 then
  begin
    P.Vida := VidaMax;
    P.Poder := 3;
  end;
  if P.Vida < 0 then P.Vida := 0;
  if P.Vida > VidaMax then P.Vida := VidaMax;

  if Jog = 1 then Mult := -1 else Mult := 1;
  Tmp4494 := Round(Cos(ContPisca / 4.75) * 30);
  if Jog = 1 then Cor := RGB(Tmp4494 + 50, Tmp4494 + 50, 255)
  else Cor := RGB(255, Tmp4494 + 30, Tmp4494 + 30);
  barra(Mult * 198 + 200, T + 40, Mult * 130 + 200, T + 68, Cor);
  retangulo(Mult * 198 + 200, T + 40, Mult * 130 + 200, T + 68, Branco);
  barraredonda(Mult * 157 + 200, T + 30, 17 * Mult + 200, T + 50, 8, Preto, Branco);
  barraredonda(Mult * 155 + 200, T + 32, Mult * 19 + 200, T + 48, 8, CinzaClaro, CinzaClaro);
  barraredonda(Mult * 153 + 200, T + 34, Mult * 21 + 200, T + 46, 8, Preto, Preto);
  if (P.Vida <= 15) and (ContPisca mod 2 = 0) then
    barraredonda(Mult * 153 + 200, T + 34, Mult * 21 + 200, T + 46, 8, Preto, RGB(200, 0, 0));

  // retrato (treme quando a barra vermelha esta descendo)
  Tmp4494 := 0;
  if (P.VidaBarra > P.Vida) and (ContPisca mod 2 = 0) then Tmp4494 := -1;
  if (P.VidaBarra > P.Vida) and (ContPisca mod 2 <> 0) then Tmp4494 := 1;
  I := (P.Personagem - 1) * 5;
  if Jog = 1 then
  begin
    if (Tmp4494 = 0) and (DXImageListRetrato.Items.Count > I) then
      DXImageListRetrato.Items[I].Draw(DXDraw1.Surface, 3 - Tmp4494, T + 7, 0);
    if (Tmp4494 <> 0) and (DXImageListRetrato.Items.Count > I + 2) then
      DXImageListRetrato.Items[I + 2].Draw(DXDraw1.Surface, 3 - Tmp4494, T + 7, 0);
  end
  else
  begin
    if (Tmp4494 = 0) and (DXImageListRetrato.Items.Count > I + 1) then
      DXImageListRetrato.Items[I + 1].Draw(DXDraw1.Surface, 347 - Tmp4494, T + 7, 0);
    if (Tmp4494 <> 0) and (DXImageListRetrato.Items.Count > I + 3) then
      DXImageListRetrato.Items[I + 3].Draw(DXDraw1.Surface, 347 - Tmp4494, T + 7, 0);
  end;

  // marcas da barra
  for I := 0 to 6 do
  begin
    if P.Vida > 15 then
      retangulo((I * 16 + 40) * Mult + 200, T + 35, (I * 16 + 40) * Mult + 200, T + 45, RGB(80, 80, 80));
    if P.Vida <= 15 then
      retangulo((I * 16 + 40) * Mult + 200, T + 35, (I * 16 + 40) * Mult + 200, T + 45, RGB(150, 30, 30));
  end;

  // barra vermelha (dano recente) e barra amarela (energia)
  if P.VidaBarra > VidaMax then P.VidaBarra := VidaMax;
  X0 := Round((25 + P.VidaBarra) * Mult) + 200;
  X1 := 25 * Mult + 200;
  barra(X0, T + 35, X1, T + 45, RGB(170, 0, 0));
  if (FlashTela = 0) and (PausaImpacto = 0) and (P.AtrasoBarra = 0) then
  begin
    if P.VidaBarra > P.Vida then
    begin
      P.VidaBarra := P.VidaBarra - 3;
      if P.VidaBarra < P.Vida then P.VidaBarra := P.Vida;
    end
    else
      P.VidaBarra := P.Vida;
  end;
  if P.AtrasoBarra > 0 then P.AtrasoBarra := P.AtrasoBarra - 1;
  if P.Vida > VidaMax then P.Vida := VidaMax;
  if P.Vida < 0 then P.Vida := 0;
  X0 := Round((25 + P.Vida) * Mult) + 200;
  barra(X0, T + 35, X1, T + 45, RGB(150, 150, 0));
  barra(X0, T + 36, X1, T + 44, RGB(220, 220, 70));
  barra(X0, T + 38, X1, T + 42, RGB(250, 250, 100));
  barra(X0, T + 39, X1, T + 40, Branco);

  // rounds ganhos
  Tmp4494 := Round(Cos(ContPisca / 2.735) * 60);
  for I := 1 to NumRounds do
  begin
    barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
      Branco, Preto);
    if P.RoundsVencidos >= I then
    begin
      barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
        Branco, RGB(160 - Tmp4494, 0, 0));
      if ContPisca < 10 then
        barraredonda((195 - (I - 1) * 17) * Mult + 200, T + 70, (180 - (I - 1) * 17) * Mult + 200, T + 85, 5,
          Branco, Vermelho);
    end;
  end;

  // jogador ausente: convite para entrar
  if (P.Ativo = 0) and (TempoDemo = 0) then
  begin
    if (ContPisca < 15) and (Fichas = 0) then
      texto(Mult * 100 + 200, 0, Linha(MemoTexto, 6), ACentro, 10, Branco);
    if (ContPisca < 15) and (Fichas > 0) and (RelogioParado = 0) then
      texto(Mult * 100 + 200, 0, Linha(MemoTexto, 7), ACentro, 10, Branco);
  end;

  if Jog = 1 then
    texto(Mult * 145 + 200, T + 45, Linha(MemoNomes, P.Personagem), AEsq, 12, RGB(120, 120, 255))
  else
    texto(Mult * 145 + 200, T + 45, Linha(MemoNomes, P.Personagem), ADir, 12, RGB(255, 110, 110));

  if P.Ativo = 1 then
  begin
    Tmp4494 := Round(Cos(ContPisca / 4.75) * 20);
    if Jog = 1 then
    begin
      texto(Mult * 145 + 200, T + 10, '1P', AEsq, 12, RGB(Tmp4494 + 120, Tmp4494 + 120, 255));
      texto(Mult * 50 + 200, T + 10, IntToStr(P.Pontos), ADir, 12, RGB(Tmp4494 + 120, Tmp4494 + 120, 255));
    end
    else
    begin
      texto(Mult * 145 + 200, T + 10, '2P', ADir, 12, RGB(255, Tmp4494 + 110, Tmp4494 + 110));
      texto(Mult * 50 + 200, T + 10, IntToStr(P.Pontos), AEsq, 12, RGB(255, Tmp4494 + 110, Tmp4494 + 110));
    end;
  end;
end;

{ Comandos do jogador humano Jog (K = teclas: 1 cima, 2 baixo, 4 esquerda, 8 direita, 16..128 botoes 1..4). }
procedure TForm1.L7_Entrada(Jog, K: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if (K and 2) = 0 then
  begin
    if (K and 4) <> 0 then AcaoJogador(Jog, 1);
    if (K and 8) <> 0 then AcaoJogador(Jog, 2);
  end;
  if (K and 2) <> 0 then AcaoJogador(Jog, 7);
  if ((K and 2) = 0) and (P.Acao = 7) then P.Acao := 1;

  // pulo
  if ((K and 1) <> 0) and ((P.Acao = 1) or (P.Acao = 2) or (P.Acao = 21) or (P.Acao = 22)) and
     (P.VelY = 0) and (P.NoAr = 0) then
  begin
    P.VelY := -32;
    P.NoAr := 1;
    P.Acao := 12;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 99;
    P.Defendendo := 0;
    P.DirPulo := 1;
    if (K and 4) <> 0 then P.DirPulo := 2;
    if (K and 8) <> 0 then P.DirPulo := 3;
  end;
  if ((K and 4) = 0) and ((K and 8) = 0) and (P.Acao = 2) then
  begin
    P.Acao := 1;
    P.QuadroAcao := 0;
  end;

  // golpes especiais (sequencias) e golpes normais
  if ((K and 16) <> 0) and (P.AntSocoFraco = 0) then golpe(Jog, 1);
  if ((K and 32) <> 0) and (P.AntChuteFraco = 0) then golpe(Jog, 2);
  if ((K and 64) <> 0) and (P.AntSocoForte = 0) then golpe(Jog, 3);
  if ((K and 128) <> 0) and (P.AntChuteForte = 0) then golpe(Jog, 4);
  if ((K and 16) <> 0) and (P.AntSocoFraco = 0) then AcaoJogador(Jog, 3);
  if ((K and 32) <> 0) and (P.AntChuteFraco = 0) then AcaoJogador(Jog, 4);
  if ((K and 64) <> 0) and (P.AntSocoForte = 0) then AcaoJogador(Jog, 5);
  if ((K and 128) <> 0) and (P.AntChuteForte = 0) then AcaoJogador(Jog, 6);
end;

{ Passaro/aviao que cruza o cenario e solta objetos. }
procedure TForm1.L7_Voador;
var
  Sup: TDirectDrawSurface;
begin
  Sup := DXDraw1.Surface;
  if ((CenarioAtual = 1) or ((CenarioAtual = 2) and (RelogioParado = 0))) and (Voador.Ativo = 0) and
     (CameraX > 40) and (CameraX < 160) and (Random(Voador.Alcance) = 0) then
  begin
    Voador.X := CameraX - 80;
    Voador.Y := 146;
    Voador.Vel := 7;
    Voador.Tipo := Random(2) + 1;
    Voador.Ativo := 1;
  end;
  if Voador.Ativo = 1 then
  begin
    Sup.Canvas.Release;
    DXImageListEfeitos.Items[0].Draw(Sup, Voador.X + 10 - CameraX, Voador.Y + 132 - CameraY, 0);
    DXImageListEfeitos.Items[9].Draw(Sup, Voador.X - CameraX, Voador.Y - CameraY, 0);
    if (FlashTela = 0) and (PausaImpacto = 0) then Voador.X := Voador.X + Voador.Vel;
    if Voador.X > CameraX + 420 then Voador.Ativo := 0;
    if (Voador.Tipo <> 0) and (Voador.X > CameraX + 150) and (Voador.X < CameraX + 250) and
       (Random(5) = 0) and (FlashTela = 0) and (PausaImpacto = 0) and (RelogioParado = 0) then
    begin
      if Voador.Tipo = 1 then CriaEfeito(3, '', 0, Voador.X + 13, Voador.Y - 5);
      if Voador.Tipo = 2 then CriaEfeito(4, '', 0, Voador.X + 13, Voador.Y - 5);
      Voador.Tipo := 0;
    end;
  end;
end;

{ Item bonus do cenario: desenha e coleta quando um lutador cai sobre ele (acao 19). }
procedure TForm1.L7_ItemBonus;
var
  Jog, K: Integer;
  P: PLutador;
  RX, RY: Integer;
begin
  if (ItemBonus.Icone <> 0) and (FlashTela = 0) and (ItemBonus.Icone < DXImageListIcone.Items.Count) then
    DXImageListIcone.Items[ItemBonus.Icone].Draw(DXDraw1.Surface, ItemBonus.X - CameraX, ItemBonus.Y - CameraY, 0);
  for Jog := 1 to 2 do
  begin
    P := @Lutador[Jog];
    AlvoX1 := Round(P.X) + P.CorpoX1;
    AlvoY1 := (Round(P.Y) - P.AlturaSprite) + P.CorpoY1;
    AlvoX2 := Round(P.X) + P.CorpoX2;
    AlvoY2 := (Round(P.Y) - P.AlturaSprite) + P.CorpoY2;
    if (P.Acao = 19) and
       (ItemBonus.X + ItemBonus.Dx2 >= AlvoX1) and (ItemBonus.Y + ItemBonus.Dy2 >= AlvoY1) and
       (ItemBonus.X + ItemBonus.Dx1 <= AlvoX2) and (ItemBonus.Y + ItemBonus.Dy1 <= AlvoY2) and
       (ItemBonus.Icone <> 0) then
    begin
      ItemBonus.Icone := 0;
      SomPendente := 9;
      for K := 1 to 30 do
      begin
        RX := Random(40);
        RY := Random(20);
        CriaEfeito(21, '', 0, RX + (ItemBonus.X + 20), RY + (ItemBonus.Y + 20));
      end;
    end;
  end;
end;

{ Mensagens de bonus/combo, indicador de poder (estoques e carga) de baixo. }
procedure TForm1.L7_HudBaixo(Jog: Byte);
var
  P: PLutador;
  B, Mult, I, X0: Integer;
begin
  P := @Lutador[Jog];
  B := DeslocHudBase;
  if Jog = 1 then Mult := -1 else Mult := 1;

  if P.TempoMsgBonus > 0 then
  begin
    texto(Mult * 100 + 200, 80, Linha(MemoTexto, P.MsgBonus), ACentro, 15, VerdeBonus);
    if (P.MsgBonus = 1) and (P.Ativo = 1) then
      texto(Mult * 80 + 200, 110, Linha(MemoTexto, 2), ACentro, 10, Branco);
    Dec(P.TempoMsgBonus);
  end;

  if P.TempoAcertos > 0 then
  begin
    if P.Acertos > P.MaxAcertos then P.MaxAcertos := P.Acertos;
    if P.Acertos > 1 then
    begin
      if P.TempoAcertos > 15 then
        texto(Random(10) + 195 + Mult * 170, 110, IntToStr(P.Acertos), ACentro, 25, Branco)
      else
        texto(Mult * 170 + 200, 110, IntToStr(P.Acertos), ACentro, 25, Branco);
      texto(Mult * 150 + 200, 145, Linha(MemoTexto, 3), ACentro, 12, VerdeBonus);
    end;
    if (FlashTela = 0) and (PausaImpacto = 0) then Dec(P.TempoAcertos);
    if P.TempoAcertos = 0 then P.Acertos := 0;
  end;

  // estoques de poder (bolinhas) e numero
  barraredonda(Mult * 65 + 200, B + 280, Mult * 22 + 200, B + 288, 6, Branco, RGB(10, 20, 30));
  Tmp4494 := 0;
  if (ContPisca mod 2 = 0) and (P.Poder > 0) then Tmp4494 := 100;
  for I := 1 to P.Poder do
    circulopintado((10 * (I - 1) + 30) * Mult + 200, B + 286, (10 * (I - 1) + 35) * Mult + 200, B + 281,
      RGB(255, 20, 20), RGB(255, Tmp4494 + 150, Tmp4494 + 150));
  Tmp4494 := 0;
  if (ContPisca mod 2 = 0) and (P.Poder > 0) then Tmp4494 := 50;
  texto(18 * Mult + 200, B + 270, IntToStr(P.Poder), ACentro, 12, RGB(255 - Tmp4494, 255 - Tmp4494, 255));

  if (ModoPoder = 2) or (ModoPoder = 4) then Lutador[1].Poder := 3;
  if (ModoPoder = 3) or (ModoPoder = 4) then Lutador[2].Poder := 3;
  if (P.CargaPoder >= CargaMax) and (P.Poder < 3) then
  begin
    P.CargaPoder := 0;
    P.Poder := P.Poder + 1;
    SomPendente := 13;
  end;
  if P.Poder >= 3 then
  begin
    P.CargaPoder := CargaMax;
    P.Poder := 3;
  end;

  // barra de carga do proximo poder
  barraredonda(Mult * 170 + 200, B + 275, Mult * 60 + 200, B + 285, 5, Branco, Branco);
  barraredonda(Mult * 169 + 200, B + 276, Mult * 61 + 200, B + 284, 5, CinzaClaro, CinzaClaro);
  barraredonda(Mult * 168 + 200, B + 277, Mult * 62 + 200, B + 283, 5, Preto, RGB(60, 30, 0));
  X0 := Round((64 + P.CargaPoder) * Mult) + 200;
  if P.CargaPoder < CargaMax then
  begin
    barra(X0, B + 278, Mult * 64 + 200, B + 282, RGB(210, 160, 30));
    barra(X0, B + 279, Mult * 64 + 200, B + 281, RGB(250, 220, 140));
  end;
  if P.CargaPoder = CargaMax then
  begin
    Tmp4494 := 0;
    if ContPisca mod 2 = 0 then Tmp4494 := 50;
    barra(X0, B + 278, Mult * 64 + 200, B + 282, RGB(240, Tmp4494 + 190, Tmp4494 + 60));
    barra(X0, B + 279, Mult * 64 + 200, B + 281, RGB(255, 250, Tmp4494 + 170));
    // (no original a cor do texto usa o contador do laco das bolinhas: Poder + 1 = 4)
    if ContPisca mod 2 = 0 then
      texto(Round(Mult * 115) + 200, B + 262, Linha(MemoTexto, 4), ACentro, 15, RGB(4 + 140, 4 + 140, 255))
    else
      texto(Round(Mult * 115) + 200, B + 262, Linha(MemoTexto, 4), ACentro, 15, RGB(4 + 170, 4 + 170, 255));
  end;
end;

{ Tempo esgotado: o de menor energia perde; empate perde os dois ("DRAW GAME"). }
procedure TForm1.L7_TempoEsgotado;
var
  Pisca: Integer;
begin
  if ContagemSeg <> 0 then Exit;
  if FaseFim < 30 then
  begin
    FaseFim := 30;
    SomPendente := 4;
  end;
  Pisca := 0;
  if ContPisca mod 2 = 0 then Pisca := 80;
  if FaseFim < 80 then
    texto(200, 40, Linha(MemoTexto, 27), ACentro, 28, RGB(255, Pisca, Pisca));
  if DeslocHudTopo > -120 then DeslocHudTopo := DeslocHudTopo - 10;
  if DeslocHudBase < 490 then DeslocHudBase := DeslocHudBase + 10;
  RelogioParado := 1;
  if Lutador[1].Vida < Lutador[2].Vida then Lutador[1].Vida := 0;
  if Lutador[2].Vida < Lutador[1].Vida then Lutador[2].Vida := 0;
  if Lutador[1].Vida = Lutador[2].Vida then
  begin
    Lutador[1].Vida := 0;
    Lutador[2].Vida := 0;
    if FaseFim < 90 then
      texto(200, 120, Linha(MemoTexto, 28), ACentro, 29, RGB(255, Pisca + Pisca, Pisca + Pisca));
  end;
end;

{ Abertura do round: barras enchendo, "ROUND n", "FIGHT!". }
procedure TForm1.L7_IntroRound;
var
  Pisca: Integer;
begin
  if (FaseIntro > 70) or (TempoDialogo <> 0) then Exit;
  Inc(FaseIntro);
  if FaseIntro < 10 then RelogioParado := 1;
  DeslocHudTopo := 0;
  DeslocHudBase := 0;
  if FaseIntro < 5 then
  begin
    Lutador[1].Vida := 1;
    Lutador[1].VidaBarra := 1;
    Lutador[2].Vida := 1;
    Lutador[2].VidaBarra := 1;
  end;
  if (FaseIntro > 5) and (FaseIntro < 55) then
  begin
    if Lutador[1].Vida < VidaMax then Lutador[1].Vida := Lutador[1].Vida + 3;
    if Lutador[2].Vida < VidaMax then Lutador[2].Vida := Lutador[2].Vida + 3;
  end;
  if (FaseIntro > 5) and (FaseIntro < 40) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 30;
    texto(260, 85, IntToStr(RoundAtual), ACentro, 35, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
    texto(200, 100, 'ROUND   ', ACentro, 20, Branco);
  end;
  if (FaseIntro > 42) and (FaseIntro < 60) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 120;
    texto(200, 120, Linha(MemoTexto, 15), ACentro, 25, RGB(255, Pisca + 30, Pisca));
  end;
  if FaseIntro = 55 then
  begin
    RelogioParado := 0;
    Lutador[1].Vida := VidaMax;
    Lutador[2].Vida := VidaMax;
  end;
end;

{ Fim do round: "KO", vencedor, bonus, cortina, proximo round ou fim da luta. }
procedure TForm1.L7_FimRound;
var
  Sup: TDirectDrawSurface;
  J, K, Pisca, I, Xr, Idx: Integer;
  P, O: PLutador;
  R: TRect;
begin
  Sup := DXDraw1.Surface;
  if not ((Lutador[1].Vida <= 0) or ((Lutador[2].Vida <= 0) and (FaseFim < 230))) then Exit;

  if (PausaImpacto = 0) and (FlashTela = 0) then Inc(FaseFim);
  if FaseFim > 40 then RelogioParado := 1;
  if FaseFim = 1 then
  begin
    PausaImpacto := 30;
    FaseFim := 2;
  end;
  if Lutador[1].Vida <= 0 then Lutador[2].Vencedor := 1;
  if Lutador[1].Vida <= 0 then Lutador[1].Vencedor := 0;
  if Lutador[2].Vida <= 0 then Lutador[1].Vencedor := 1;
  if Lutador[2].Vida <= 0 then Lutador[2].Vencedor := 0;

  if (FaseFim > 0) and (FaseFim < 30) then
  begin
    Pisca := 0;
    if ContPisca mod 2 = 0 then Pisca := 100;
    texto(200, 100, 'KO', ACentro, 70, RGB(255, Pisca, 0));
    DeslocHudTopo := DeslocHudTopo - 5;
    DeslocHudBase := DeslocHudBase + 5;
  end;

  // vencedor do round: nome, "WINS", pontos por energia, perfect, bonus
  if (FaseFim > 30) and (FaseFim < 90) then
    for J := 1 to 2 do
    begin
      P := @Lutador[J];
      O := @Lutador[3 - J];
      if P.Vida > 0 then
      begin
        if RelogioParado = 1 then AcaoJogador(J, 14);
        Pisca := 0;
        if ContPisca mod 2 = 0 then Pisca := 80;
        texto(200, 110, Linha(MemoNomes, P.Personagem), ACentro, 20, RGB(255, Pisca, Pisca));
        texto(200, 140, Linha(MemoTexto, 14), ACentro, 14, Branco);
        if (P.Ativo = 1) and (P.Vida < VidaMax) then
        begin
          texto(200, 210, Linha(MemoTexto, 5) + 'x5=' + IntToStr(Int64(Round(P.Vida)) * 5) + ' PTS.',
            ACentro, 12, Branco);
          if (FaseFim = 35) and (PausaImpacto = 0) and (FlashTela = 0) then
          begin
            P.Pontos := P.Pontos + Round(P.Vida) * 5;
            Inc(FaseFim);
          end;
        end;
        Pisca := 0;
        if ContPisca mod 2 = 0 then Pisca := 120;
        if (P.Vida = VidaMax) and (FaseFim > 35) then
          texto(200, 170, Linha(MemoTexto, 30), ACentro, 28, RGB(255, Pisca + 120, Pisca + 30));
        if (P.Ativo = 1) and (P.Vida = VidaMax) then
        begin
          texto(200, 210, 'BONUS ' + IntToStr(1000) + ' PTS.', ACentro, 15, Branco);
          if (FaseFim = 45) and (FlashTela = 0) and (PausaImpacto = 0) then
          begin
            P.Pontos := P.Pontos + 1000;
            Inc(FaseFim);
          end;
        end;
        if (P.Ativo = 1) and (NumRounds = P.RoundsVencidos) and (O.RoundsVencidos = 0) then
        begin
          Pisca := 0;
          if ContPisca mod 2 = 0 then Pisca := 20;
          texto(200, 240, Linha(MemoTexto, 32) + '  ' + IntToStr(1000) + ' PTS.', ACentro, 20,
            RGB(Pisca + 170, Pisca + 170, Pisca + 235));
          if (FaseFim = 45) and (FlashTela = 0) and (PausaImpacto = 0) then
            P.Pontos := P.Pontos + 1000;
        end;
      end;
    end;

  // conta o round ganho e sorteia a cortina e a frase de vitoria
  if FaseFim = 40 then
    for J := 2 downto 1 do
    begin
      P := @Lutador[3 - J];
      if (P.Vida > 0) and (FlashTela = 0) and (PausaImpacto = 0) then
      begin
        Inc(P.RoundsVencidos);
        Inc(FaseFim);
      end;
      EfeitoCortina := Round(Random(40) / 10) + 1;
      if EfeitoCortina > 4 then EfeitoCortina := 4;
      P.FraseVitoria := Round(Random(30) / 10) + 1;
      if P.FraseVitoria > 3 then P.FraseVitoria := 3;
    end;

  // vencedor da luta: retrato grande e frase
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if (NumRounds <= P.RoundsVencidos) and (FaseFim >= 90) and (FaseFim <= 210) then
    begin
      Pisca := 0;
      if ContPisca mod 2 = 0 then Pisca := 30;
      if RelogioParado = 1 then AcaoJogador(J, 14);
      if FaseFim = 100 then
      begin
        if O.Ativo = 0 then Inc(Fase);
        O.Ativo := 0;
      end;
      if (((TecP1 and 16) <> 0) and (J = 1)) or (((TecP2 and 16) <> 0) and (J = 2)) then
        if (FaseFim < 90) or (FaseFim > 100) then FaseFim := FaseFim + 2;
      if (FaseFim = 95) and (PausaImpacto = 0) and (FlashTela = 0) then
      begin
        K := Round(Random(200) / 200);
        if K < 0 then K := 0;
        if K > 1 then K := 1;
        Idx := (P.Personagem - 1) * 2 + K;
        if DXWaveListVitoria.Items.Count > Idx then DXWaveListVitoria.Items[Idx].Play(False);
      end;
      I := (P.Personagem - 1) * 5 + 4;
      if DXImageListRetrato.Items.Count > I then
      begin
        if FaseFim < 100 then
        begin
          R := Rect(728 - (FaseFim - 90) * 50, 29, 872 - (FaseFim - 90) * 50, 218);
          DXImageListRetrato.Items[I].DrawAlpha(Sup, R, 0, 255);
        end;
        if (FaseFim >= 100) and (FaseFim < 180) then
        begin
          R := Rect(128, 29, 272, 218);
          DXImageListRetrato.Items[I].DrawAlpha(Sup, R, 0, 255);
        end;
        if FaseFim >= 180 then
        begin
          R := Rect(128 - (FaseFim - 180) * 50, 29, 272 - (FaseFim - 180) * 50, 218);
          DXImageListRetrato.Items[I].DrawAlpha(Sup, R, 0, 255);
        end;
      end;
      if P.Ativo = 1 then
      begin
        texto(10, 20, Linha(MemoTexto, 16), AEsq, 12, RGB(Pisca + 30, Pisca + 220, Pisca + 30));
        texto(10, 35, IntToStr(P.MaxAcertos), AEsq, 14, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
        texto(10, 60, Linha(MemoTexto, 17), AEsq, 12, RGB(Pisca + 30, Pisca + 220, Pisca + 30));
        texto(10, 75, IntToStr(P.Pontos), AEsq, 14, RGB(255 - Pisca, 255 - Pisca, 255 - Pisca));
      end;
      barraredonda(5, 220, 395, 280, 5, Branco, Preto);
      texto(200, 237, Linha(MemoFrases, ((P.Personagem - 1) shl 2) + P.FraseVitoria), ACentro, 12,
        Branco);
    end;
  end;

  // cortinas pretas entre rounds
  if (Lutador[1].RoundsVencidos < NumRounds) and (Lutador[2].RoundsVencidos < NumRounds) and (FaseFim > 95) then
  begin
    if EfeitoCortina = 1 then
    begin
      barra(0, 0, 400, FaseFim * 10 - 950, Preto);
      barra(0, 1250 - FaseFim * 10, 400, 300, Preto);
    end;
    if EfeitoCortina = 2 then
    begin
      barra(0, 0, 200, FaseFim * 12 - 1150, Preto);
      barra(200, 1450 - FaseFim * 12, 400, 300, Preto);
    end;
    if EfeitoCortina = 3 then
      for K := 0 to 3 do
      begin
        barra(0, K * 80, FaseFim * 17 - 1670, K * 80 + 40, Preto);
        barra(2070 - FaseFim * 17, K * 80 + 40, 400, K * 80 + 80, Preto);
      end;
    if EfeitoCortina = 4 then
    begin
      barra(0, 0, 400, FaseFim * 10 - 1000, Preto);
      barra(0, 1300 - FaseFim * 10, 400, 300, Preto);
      barra(0, 0, FaseFim * 10 - 1000, 300, Preto);
      barra(1400 - FaseFim * 10, 0, 400, 300, Preto);
    end;
  end;

  // proximo round
  if (Lutador[1].RoundsVencidos < NumRounds) and (Lutador[2].RoundsVencidos < NumRounds) and (FaseFim > 130) then
  begin
    FaseIntro := 0;
    FaseFim := 0;
    Voador.Ativo := 0;
    zerardados(1);
    zerardados(2);
    if TempoRound = 1 then ContagemSeg := 30;
    if TempoRound = 2 then ContagemSeg := 60;
    if TempoRound = 3 then ContagemSeg := 90;
    if TempoRound = 4 then ContagemSeg := 99;
    ContagemTick := 25;
    Inc(RoundAtual);
  end;

  // fim da luta: segue para a proxima etapa (adversarios / recordes / continue)
  if FaseFim > 220 then
  begin
    Estado := CHS_ADVERSARIOS;
    SomPendente := 0;
    FaseSelecao := 1;
    Lutador[1].Escolheu := 0;
    Lutador[2].Escolheu := 0;
    RoundAtual := 1;
    ContagemSeg := 20;
    ContagemTick := 25;
    if (Lutador[1].Ativo = 1) or (Lutador[2].Ativo = 1) then
    begin
      if Fase > 8 then
      begin
        if (MusicaAtual <> 0) and (DXWaveListMusica.Items.Count > 0) then DXWaveListMusica.Items[0].Stop;
        ContPisca := 0;
        TempoEstado := 0;
        if (Recordes[10].Pontos < Cardinal(Lutador[1].Pontos)) or (Recordes[10].Pontos < Cardinal(Lutador[2].Pontos)) then
        begin
          Estado := CHS_INICIAIS;
          Lutador[1].Iniciais := 'AAA';
          Lutador[1].CursorIni := 1;
          Lutador[2].Iniciais := 'AAA';
          Lutador[2].CursorIni := 1;
        end
        else
          Estado := CHS_FINAL;
      end;
    end;
    if (Lutador[1].Ativo = 0) and (Lutador[2].Ativo = 0) then
    begin
      if (MusicaAtual <> 0) and (DXWaveListMusica.Items.Count > 0) then DXWaveListMusica.Items[0].Stop;
      SomPendente := 0;
      ContPisca := 0;
      TempoEstado := 0;
      ContagemSeg := 9;
      ContagemTick := 25;
      if (Recordes[10].Pontos < Cardinal(Lutador[1].Pontos)) or (Recordes[10].Pontos < Cardinal(Lutador[2].Pontos)) then
      begin
        Estado := CHS_INICIAIS;
        Lutador[1].Iniciais := 'AAA';
        Lutador[1].CursorIni := 1;
        Lutador[2].Iniciais := 'AAA';
        Lutador[2].CursorIni := 1;
      end
      else
        Estado := CHS_CONTINUAR;
    end;
  end;
end;

{ Resolve se o golpe do lutador Jog acertou (ou foi defendido por) o oponente. }
procedure TForm1.L7_Acertos(Jog: Byte);
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
  if ((P.Acao = 17) or (P.Acao = 18)) and (FlashTela = 0) and (PausaImpacto = 0) then
  begin
    if P.Lado = 1 then Empurra(Jog, -P.Recuo);
    if P.Lado = 2 then Empurra(Jog, P.Recuo);
    if Random(2) = 0 then
    begin
      RX := Random(40);
      RY := Random(10);
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

  if (P.GolpeAtivo = 1) and (O.Vencedor = 0) and
     (AtqX1 < AlvoX2) and (AtqX2 > AlvoX1) and (AtqY1 < AlvoY2) and (AtqY2 > AlvoY1) and
     (PausaImpacto = 0) and (FlashTela = 0) then
  begin
    // ponto medio da caixa do golpe (onde aparece a faisca)
    MX := Round((P.AtaqueX1 + P.AtaqueX2) / 2);
    MY := Round((P.AtaqueY1 + P.AtaqueY2) / 2);

    // golpe alto/baixo vence a guarda errada
    if ((P.Acao = 9) or (P.Acao = 11)) and (O.Acao = 21) then O.Defendendo := 0;
    if ((P.Acao = 13) or (P.Acao = 14) or (P.Acao = 15) or (P.Acao = 16)) and (O.Acao = 22) then O.Defendendo := 0;

    if O.Defendendo = 1 then
    begin
      // ---- defendido ----
      O.QuadroAcao := 1;
      SomPendente := 10;
      CriaEfeito(14, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      if O.Lado = 1 then Empurra(O_Jog, -10);
      if O.Lado = 2 then Empurra(O_Jog, 10);
      if (AvisoEntrada = 0) and (RelogioParado = 0) then
      begin
        O.Vida := O.Vida - P.DanoDefesa * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := 9;
        AcaoJogador(O_Jog, 10);
      end;
      P.GolpeAtivo := 0;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = 1 then PausaImpacto := Random(4) + 2;
        if P.ForcaGolpe = 2 then PausaImpacto := Random(4) + 4;
      end;
    end;

    if O.Defendendo = 0 then
    begin
      // ---- acertou ----
      if O.X < P.X then O.Lado := 1;
      if O.X >= P.X then O.Lado := 2;
      if (P.Ativo = 1) and (O.Vida > 0) and (PausaImpacto = 0) and (FlashTela = 0) then
        P.Pontos := P.Pontos + 5;
      if P.CargaPoder < CargaMax then P.CargaPoder := P.CargaPoder + 2 * GanhoCarga;
      if O.CargaPoder < CargaMax then O.CargaPoder := O.CargaPoder + 1 * GanhoCarga;
      // combo
      if P.TempoAcertos <= 35 then P.Acertos := 0;
      Inc(P.Acertos);
      P.TempoAcertos := 44;
      if (P.Acao = 11) or (P.Acao = 16) then P.TempoAcertos := 50;
      if (P.Personagem = 4) and (P.Acao = 26) then P.TempoAcertos := 46;
      if (P.Personagem = 4) and (P.Acao = 27) then P.TempoAcertos := 47;
      if (P.Personagem = 6) and (P.Acao = 29) then P.TempoAcertos := 50;
      if (P.Personagem = 15) and (P.Acao = 27) then P.TempoAcertos := 50;
      if (AvisoEntrada = 0) and (RelogioParado = 0) then
      begin
        O.Vida := O.Vida - P.DanoGolpe * NivelDano;
        O.AtrasoBarra := 20;
      end;
      if Flash = 1 then
      begin
        if (P.ForcaGolpe = 1) and (Random(5) = 0) then FlashVermelho := 6;
        if (P.ForcaGolpe = 2) and (Random(2) = 0) then FlashVermelho := 6;
      end;
      if O.Vida <= 0 then
      begin
        SomPendente := 8;
        AcaoJogador(O_Jog, 10);
      end;
      // golpes que fazem o oponente girar no ar
      Giro := ((P.Personagem = 4) and (P.Acao = 29)) or
              ((P.Personagem = 5) and (P.Acao = 29) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = 6) and (P.Acao = 29) and (P.QuadroAcao >= 22)) or
              ((P.Personagem = 9) and (P.Acao = 29) and (P.QuadroAcao >= 14)) or
              ((P.Personagem = 10) and (P.Acao = 29) and (P.QuadroAcao >= 15)) or
              ((P.Personagem = 11) and (P.Acao = 29) and (P.QuadroAcao >= 20)) or
              ((P.Personagem = 12) and (P.Acao = 28) and (P.QuadroAcao >= 22));
      if Giro then
      begin
        if O.Lado = 1 then O.VelAngular := -20;
        if O.Lado = 2 then O.VelAngular := 20;
      end;
      CriaEfeito(1, '', 0, MX + P.X, MY + (P.Y - P.AlturaSprite));
      // sangue
      if ((Sangue = 1) and (P.ForcaGolpe = 2) and (Random(5) = 0)) or (CheatSatanas = 1) then
        CriaEfeito(10, '', 0, O.X, O.Y - (O.AlturaSprite - 40));
      // reacao do oponente
      if (P.Acao = 4) or (P.Acao = 6) or (P.Acao = 8) or (P.Acao = 9) or (P.Acao = 10) then
        AcaoJogador(O_Jog, 9)
      else
        AcaoJogador(O_Jog, 8);
      if (P.EhChute = 1) or (O.VelY <> 0) or (ChaoY > O.Y) then AcaoJogador(O_Jog, 10);
      // recuo (empurrao) do oponente
      O.Recuo := 4;
      if (P.Personagem = 1) and (P.Acao = 26) and (P.ForcaGolpe = 2) then O.Recuo := 20;
      if (P.Personagem = 2) and (P.Acao = 26) and (P.ForcaGolpe = 2) then O.Recuo := 13;
      if (P.Personagem = 4) and (P.Acao = 29) then O.Recuo := 20;
      if (P.Personagem = 6) and (P.Acao = 27) and (P.ForcaGolpe = 2) then O.Recuo := 25;
      if (P.Personagem = 7) and (P.Acao = 27) and (P.ForcaGolpe = 2) then O.Recuo := 18;
      if (P.Personagem = 9) and (P.Acao = 29) and (P.QuadroAcao >= 15) then O.Recuo := 25;
      if (P.Personagem = 10) and (P.Acao = 28) and (P.ForcaGolpe = 2) then O.Recuo := 13;
      if (P.Personagem = 12) and (P.Acao = 26) and (P.ForcaGolpe = 2) then O.Recuo := 25;
      // lancamento para cima
      if (P.Personagem = 4) and (P.Acao = 29) then O.VelY := -30;
      if (P.Personagem = 5) and (P.Acao = 29) and (P.QuadroAcao >= 15) then O.VelY := -30;
      if (P.Personagem = 15) and (P.Acao = 27) then O.VelY := -26;
      if P.ForcaGolpe = 1 then SomPendente := 7;
      if P.ForcaGolpe = 2 then SomPendente := 8;
      if P.ForcaGolpe = 3 then SomPendente := 9;
      // primeiro ataque do round
      if PrimeiroAtaque = 0 then
      begin
        P.MsgBonus := 1;
        P.TempoMsgBonus := 50;
        if (P.Ativo = 1) and (PausaImpacto = 0) and (FlashTela = 0) then P.Pontos := P.Pontos + 300;
        PrimeiroAtaque := 1;
      end;
      P.DesenhaPorCima := 1;
      O.DesenhaPorCima := 0;
      P.GolpeAtivo := 0;
      O.GolpeAtivo := 0;
      // golpes encadeados (continuam em outra acao)
      if (P.Personagem = 2) and (P.Acao = 28) then
      begin
        P.Acao := 29;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := 0;
      end;
      if (P.Personagem = 2) and (P.Acao = 30) then
      begin
        P.Acao := 31;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 40;
        Inc(P.Acertos);
        O.GolpeAtivo := 0;
      end;
      if (P.Personagem = 3) and (P.Acao = 29) then
      begin
        P.Acao := 30;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 30;
        O.GolpeAtivo := 0;
      end;
      if (P.Personagem = 7) and (P.Acao = 29) then
      begin
        P.Acao := 30;
        P.QuadroAcao := 0;
        P.DuracaoAcao := 15;
        O.GolpeAtivo := 0;
      end;
      if O.Vida > 0 then
      begin
        if P.ForcaGolpe = 1 then PausaImpacto := Random(4) + 5;
        if P.ForcaGolpe = 2 then PausaImpacto := Random(4) + 7;
      end;
      AtualizaQuadro(O_Jog);
    end;

    // oponente encostado na borda da tela: o atacante recua
    if RelogioParado = 0 then
    begin
      if CameraX + 370 <= O.X then Empurra(Jog, -12);
      if CameraX + 30 >= O.X then Empurra(Jog, 12);
    end;
  end;
end;

{ Fim das acoes, queda ao chao, fisica do pulo/queda e limites da tela. }
procedure TForm1.L7_Fisica;
var
  J, K, RX, RY: Integer;
  P, O: PLutador;
begin
  // acao terminou (QuadroAcao chegou na duracao): volta ao estado parado
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if (P.DuracaoAcao <> 99) and (FlashTela = 0) and (PausaImpacto = 0) then Inc(P.QuadroAcao);
    if P.QuadroAcao >= P.DuracaoAcao then
    begin
      P.Acao := 1;
      P.GolpeAtivo := 0;
      P.DanoGolpe := 0;
      P.QuadroAcao := 0;
      P.Vencedor := 0;
      P.Defendendo := 0;
      P.EhChute := 0;
      P.ForcaGolpe := 0;
      if ChaoY > P.Y then
      begin
        P.NoAr := 1;
        P.Acao := 12;
      end;
      if P.X < O.X then P.Lado := 1;
      if P.X >= O.X then P.Lado := 2;
      if ChaoY < P.Y then P.Y := ChaoY;
      if P.VelY <> 0 then P.Acao := 12;
    end;
  end;

  // abaixo do chao: volta para o chao
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    if ChaoY < P.Y then
    begin
      P.Y := ChaoY;
      P.Angulo := 0;
      P.VelAngular := 0;
      P.VelY := 0;
      P.NoAr := 0;
      P.Acao := 1;
      P.QuadroAcao := 0;
      P.GolpeAtivo := 0;
      P.EhChute := 0;
    end;
  end;

  // no ar: gravidade, deslocamento horizontal, queda (acao 19) e aterrissagem
  for J := 1 to 2 do
  begin
    P := @Lutador[J];
    O := @Lutador[3 - J];
    if (P.NoAr = 1) and (FlashTela = 0) and (PausaImpacto = 0) then
    begin
      P.Y := P.Y + P.VelY;
      P.VelY := P.VelY + Gravidade;
      if P.DirPulo = 2 then Empurra(J, -8);
      if P.DirPulo = 3 then Empurra(J, 8);

      if P.Acao = 19 then
      begin
        if P.Lado = 1 then P.X := P.X - P.Recuo;
        if P.Lado = 2 then P.X := P.X + P.Recuo;
        if ChaoY <= P.Y then
        begin
          AcaoJogador(J, 11);
          P.Y := ChaoY - 10;
          P.Angulo := 0;
          P.VelAngular := 0;
          SomPendente := 12;
          if (P.Personagem = 7) or (P.Personagem = 10) then
          begin
            TremorTela := 20;
            for K := 1 to 20 do
            begin
              RX := Random(60);
              RY := Random(10);
              CriaEfeito(2, '', 0, RX + (P.X - 30), RY + P.Y);
            end;
          end;
          for K := 1 to 5 do
          begin
            RX := Random(40);
            RY := Random(10);
            CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
          end;
        end;
      end;

      if P.Acao = 20 then
      begin
        if P.Lado = 1 then Empurra(J, -P.Recuo);
        if P.Lado = 2 then Empurra(J, P.Recuo);
        if ((Sangue = 1) and (Random(4) = 0)) or (CheatSatanas = 1) then
          if P.QuadroAcao = 5 then
          begin
            if P.Lado = 1 then CriaEfeito(10, '', 0, P.X - 30, P.Y - 50);
            if P.Lado = 2 then CriaEfeito(10, '', 0, P.X + 30, P.Y - 50);
          end;
        if ChaoY < P.Y then
        begin
          P.Y := ChaoY;
          P.NoAr := 0;
          P.Angulo := 0;
          P.VelAngular := 0;
          P.VelY := 0;
          P.Recuo := 0;
        end;
      end;

      if ChaoY < P.Y then
      begin
        P.VelY := 0;
        P.NoAr := 0;
        P.Y := ChaoY;
        P.Angulo := 0;
        P.VelAngular := 0;
        P.Acao := 1;
        P.QuadroAcao := 0;
        P.GolpeAtivo := 0;
        P.DanoGolpe := 0;
        P.EhChute := 0;
        P.DirPulo := 0;
        if P.X < O.X then P.Lado := 1;
        if P.X >= O.X then P.Lado := 2;
        for K := 1 to 5 do
        begin
          RX := Random(40);
          RY := Random(10);
          CriaEfeito(2, '', 0, RX + (P.X - 20), RY + P.Y);
        end;
      end;
    end;

    // lutador vivo nao sai da tela
    if P.Vida > 0 then
    begin
      if CameraX + 30 > P.X then P.X := CameraX + 30;
      if CameraX + 370 < P.X then P.X := CameraX + 370;
    end;
  end;
end;

{ Dialogo do chefe (fase 8): quadros de conversa antes da luta. }
procedure TForm1.L7_Dialogo;
var
  Sup: TDirectDrawSurface;
  Jh, Jc, I, Base: Integer;
begin
  if TempoDialogo = 0 then Exit;
  Sup := DXDraw1.Surface;
  Jh := 1;
  if Lutador[1].Ativo = 1 then Jh := 1;
  if Lutador[2].Ativo = 1 then Jh := 2;
  Jc := 2;
  if Lutador[1].Ativo = 0 then Jc := 1;
  if Lutador[2].Ativo = 0 then Jc := 2;

  barraredonda(5, 165, 290, 215, 20, Branco, Preto);
  I := (Lutador[Jh].Personagem - 1) * 5 + 4;
  if DXImageListRetrato.Items.Count > I then
  begin
    if TempoDialogo > 580 then
      DXImageListRetrato.Items[I].Draw(Sup, 15 - (TempoDialogo - 580) * 10, 85, 0);
    if TempoDialogo <= 580 then
      DXImageListRetrato.Items[I].Draw(Sup, 15, 85, 0);
  end;
  barraredonda(110, 220, 395, 270, 20, Branco, Preto);
  I := (Lutador[Jc].Personagem - 1) * 5 + 4;
  if DXImageListRetrato.Items.Count > I then
  begin
    if TempoDialogo > 580 then
      DXImageListRetrato.Items[I].Draw(Sup, (TempoDialogo - 580) * 10 + 288, 140, 0);
    if TempoDialogo <= 580 then
      DXImageListRetrato.Items[I].Draw(Sup, 288, 140, 0);
  end;

  Base := (Lutador[Jh].Personagem - 1) * 12;
  I := Base;
  if (TempoDialogo > 450) and (TempoDialogo < 600) then
  begin
    I := Base;
    Tmp4494 := 1;
  end;
  if (TempoDialogo > 300) and (TempoDialogo < 450) then
  begin
    I := Base + 3;
    Tmp4494 := 2;
  end;
  if (TempoDialogo > 150) and (TempoDialogo < 300) then
  begin
    I := Base + 6;
    Tmp4494 := 1;
  end;
  if (TempoDialogo > 0) and (TempoDialogo < 150) then
  begin
    I := Base + 9;
    Tmp4494 := 2;
  end;
  if Tmp4494 = 1 then
  begin
    texto(115, 168, Linha(MemoDialogo, I), AEsq, 10, Branco);
    texto(115, 182, Linha(MemoDialogo, I + 1), AEsq, 10, Branco);
    texto(115, 196, Linha(MemoDialogo, I + 2), AEsq, 10, Branco);
  end;
  if Tmp4494 = 2 then
  begin
    texto(120, 223, Linha(MemoDialogo, I), AEsq, 10, Branco);
    texto(120, 237, Linha(MemoDialogo, I + 1), AEsq, 10, Branco);
    texto(120, 251, Linha(MemoDialogo, I + 2), AEsq, 10, Branco);
  end;
  DXInput1.Update;
  if (((TecP1 and 16) <> 0) and (Lutador[1].Ativo = 1)) or (((TecP2 and 16) <> 0) and (Lutador[2].Ativo = 1)) then
    if TempoDialogo > 10 then TempoDialogo := TempoDialogo - 5;
end;

{ Luta de demonstracao (sem jogador): cortina, "INSERT COIN" e logo; ao acabar volta a abertura. }
procedure TForm1.L7_Demo;
var
  Sup: TDirectDrawSurface;
  K, W, H, Idx: Integer;
  R: TRect;
begin
  if TempoDemo <= 0 then Exit;
  Sup := DXDraw1.Surface;
  Dec(TempoDemo);
  ContagemSeg := TempoRound;
  ContagemTick := 25;
  if TempoDemo < 40 then
    for K := 0 to 15 do
      barra(0, K * 20, 400, (40 - TempoDemo) + K * 20, Preto);
  if ContPisca < 20 then
    texto(200, 240, Linha(MemoTexto, 6), ACentro, 10, Branco);
  if TempoDemo < 500 then
  begin
    Idx := -1;
    if Idioma = 1 then Idx := 12;
    if Idioma = 2 then Idx := 13;
    if (Idx >= 0) and (DXImageListAbertura.Items.Count > Idx) then
    begin
      W := Round(DXImageListAbertura.Items[Idx].Width / 2);
      H := Round(DXImageListAbertura.Items[Idx].Height / 2);
      R := Rect(390 - W, 280 - H, 390, 280);
      DXImageListAbertura.Items[Idx].DrawAlpha(Sup, R, 0, 255);
    end;
  end;
  if TempoDemo <= 5 then
  begin
    Estado := CHS_RECORDES;
    SomPendente := 0;
    CameraY := 0;
    ContPisca := 0;
    TempoEstado := 0;
  end;
end;

{ Estado 7: a luta. }
procedure TForm1.Estado7_Luta;
var
  J: Integer;
begin
  L7_Prepara;
  L7_CenarioECamera;
  L7_Relogio;
  for J := 1 to 2 do L7_HudCima(J);

  DXInput1.Update;
  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) and (RelogioParado = 0) then
  begin
    if Lutador[1].Ativo = 1 then L7_Entrada(1, TecP1);
    if Lutador[2].Ativo = 1 then L7_Entrada(2, TecP2);
  end;
  sequenciagolpe(1);
  sequenciagolpe(2);
  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) then
    for J := 1 to 2 do
      if (Lutador[J].Ativo = 0) and (RelogioParado = 0) then cpu(J);

  L7_Voador;
  L7_ItemBonus;

  // lutadores (quem apanhou/atacou por ultimo e desenhado por cima)
  if Lutador[1].DesenhaPorCima = 1 then
  begin
    desenhalutador(2, Round(Lutador[2].X), Round(Lutador[2].Y), Lutador[2].Acao, Byte(Lutador[2].QuadroAcao));
    desenhalutador(1, Round(Lutador[1].X), Round(Lutador[1].Y), Lutador[1].Acao, Byte(Lutador[1].QuadroAcao));
  end;
  if Lutador[2].DesenhaPorCima = 1 then
  begin
    desenhalutador(1, Round(Lutador[1].X), Round(Lutador[1].Y), Lutador[1].Acao, Byte(Lutador[1].QuadroAcao));
    desenhalutador(2, Round(Lutador[2].X), Round(Lutador[2].Y), Lutador[2].Acao, Byte(Lutador[2].QuadroAcao));
  end;

  if (FlashTela = 0) and (PausaImpacto = 0) and (AvisoEntrada = 0) and (RelogioParado = 0) then
  begin
    defendergolpe(1);
    defendergolpe(2);
  end;
  desenhaefeitos;
  for J := 1 to 2 do L7_HudBaixo(J);

  L7_TempoEsgotado;
  L7_IntroRound;
  L7_FimRound;

  for J := 1 to 2 do L7_Acertos(J);
  if PausaImpacto > 0 then Dec(PausaImpacto);
  L7_Fisica;
  L7_Dialogo;

  if (FlashTela = 0) and (PausaImpacto = 0) then Inc(ContPisca);
  if ContPisca > 30 then ContPisca := 0;
  L7_Demo;

  if FlashVermelho > 0 then
  begin
    if ContPisca mod 2 = 0 then barra(0, 0, LarguraTela, AlturaTela, Vermelho);
    Dec(FlashVermelho);
  end;
  if (Estado = CHS_LUTA) and (PassoAPasso = 1) then mostragolpe;
end;
