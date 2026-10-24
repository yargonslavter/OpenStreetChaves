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
  ImgEfeitos.PorNome('Sombra').Draw(Sup, SX, SY, 0);

  // parado/andando/agachado no chao: vira para o oponente
  if (Acao = 1) or (Acao = 2) or (Acao = 7) then
    if P.VelY = 0 then
    begin
      if P.X < O.X then P.Lado := 1;
      if P.X >= O.X then P.Lado := 2;
    end;

  if MostrarCaixas then
  begin
    barra(P.CorpoX1 + X - CameraX, (Y - P.AlturaSprite - CameraY) + P.CorpoY1,
          P.CorpoX2 + X - CameraX, (Y - P.AlturaSprite) + P.CorpoY2 - CameraY, RGB(50, 50, 255));
    if P.GolpeAtivo then
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

{ Animacoes do cenario (bandeiras, torcida, fogueira, etc.), lidas de Dados/Cenarios/Cenario-NN.ini:
  cada desenho aparece numa faixa de ContPisca (0..31) e some quando um dos lutadores e o proprio
  personagem da animacao. A ordem dos desenhos (e das chamadas a Random) e a do arquivo. }
procedure TJogo.desenhaanimacoes;
var
  I, X, Y: Integer;
  D: ^TDesenhoCenario;
begin
  for I := 0 to High(FDesenhos) do
  begin
    D := @FDesenhos[I];
    if (Lutador[1].Personagem in D.Esconde) or (Lutador[2].Personagem in D.Esconde) then Continue;
    if (D.De >= 0) and ((ContPisca < D.De) or ((D.Ate >= 0) and (ContPisca > D.Ate))) then Continue;
    if D.Especial <> '' then
    begin
      AnimacaoEspecial(D.Especial);
      Continue;
    end;
    X := D.X;
    Y := D.Y;
    if D.TremorX > 0 then X := Random(D.TremorX) + X;
    if D.TremorY > 0 then Y := Y - D.PassoY * Random(D.TremorY);
    A_Desenha(D.Lista, D.Indice, X - CameraX, Y - CameraY);
  end;
end;

{ Desenhos de cenario que dependem de conta (nao cabem numa linha do .ini). }
procedure TJogo.AnimacaoEspecial(const Nome: string);
var
  J: Integer;
begin
  { cenario 8: figura que vai e volta conforme ContPisca }
  if Nome = 'Vaivem' then
  begin
    if ContPisca < 15 then A_Desenha(ImgAnimacao, 16, ((ContPisca shl 2)+200)-CameraX, 255 - CameraY);
    if ContPisca >= 15 then A_Desenha(ImgAnimacao, 17, (((30-ContPisca) shl 2)+200)-CameraX, 255 - CameraY);
  end;
  { cenario 8: torcida que acompanha os lutadores }
  if Nome = 'Torcida' then
    for J := 1 to 5 do
      A_Desenha(ImgAnimacao, 18, Random(2) + 15 * J + (Round((Lutador[1].X + Lutador[2].X) / 2) - 60) - CameraX, 269 - 4 * Random(3) - CameraY);
  { cenario 12: peso do teste de forca subindo e descendo }
  if Nome = 'TesteDeForca' then
    A_Desenha(ImgIcone, ImgIcone.IndiceDe('TesteDeForca'), 225 - CameraX, 134 - CameraY - Round(-Cos((ContPisca - 11) / 5) * 70));
end;


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
      if E.Quadro >= E.Duracao - 20 then E.Estagio := True;
    end;
    if E.Tipo = 4 then
    begin
      E.Sprite := 11;
      if E.Quadro >= E.Duracao - 20 then E.Estagio := True;
    end;
    if E.Tipo = 5 then
    begin
      if E.Quadro >= E.Duracao - 10 then E.Estagio := True;
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
      if E.Quadro = 5 then E.Estagio := True;
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
      E.PodeAcertar := True;
      Inc(E.Quadro);
    end;
    if (E.Tipo = 28) and ((E.Contagem = 3) or (E.Contagem = 6) or (E.Contagem = 9)) then
    begin
      E.PodeAcertar := True;
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
        E.PodeAcertar := True;
        Inc(E.Contagem);
        if Lutador[E.Dono].Acao <> 29 then E.Tipo := 0;
      end;
    if (E.Tipo = 30) and (Lutador[E.Dono].Acao <> 26) then E.Tipo := 0;
    if (E.Tipo = 34) and (E.Quadro >= 14) then E.PodeAcertar := False;
    if E.Tipo = 24 then
    begin
      E.X := Round(Cos(E.Quadro) * 2) + E.X;
      E.Y := E.Y - 1;
    end;

    { ---- gravidade ---- }
    if E.Flag52 and (FlashTela = 0) and (PausaImpacto = 0) then
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
          E.Estagio := True;
          E.PodeAcertar := False;
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

    if MostrarCaixas then
      barra(Round(E.X) + E.CaixaX1 - CameraX, Round(E.Y) + E.CaixaY1 - CameraY,
        Round(E.X) + E.CaixaX2 - CameraX, Round(E.Y) + E.CaixaY2 - CameraY, RGB(50, 255, 50));

    { ---- desenho ---- }
    if (ImgEfeitos.Count > E.Sprite) and (E.Tipo <> 5) then
    begin
      W2 := Round(ImgEfeitos[E.Sprite].Width / 2);
      H2 := Round(ImgEfeitos[E.Sprite].Height / 2);
      if E.Flag51 then H2 := ImgEfeitos[E.Sprite].Height;
      Pisca := not E.Estagio or (E.Estagio and (ContPisca mod 2 = 0));
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
      if not E.Estagio or (E.Estagio and (ContPisca mod 2 = 0)) then
        texto(Round(E.X) - CameraX, Round(E.Y) - CameraY, Linha(MemoTexto, 5), ACentro, 10, VerdeBonus);
      if FlashTela = 0 then E.Y := E.Y - 5;
    end;

    { ---- colisao com os outros efeitos ---- }
    for J := 1 to MaxEfeitos do
    begin
      F := @Efeitos[J];
      if (E.CaixaX2 + E.X > F.CaixaX1 + F.X) and (E.CaixaX1 + E.X < F.CaixaX2 + F.X) and
         (E.CaixaY2 + E.Y > F.CaixaY1 + F.Y) and (E.CaixaY1 + E.Y < F.CaixaY2 + F.Y) and
         F.PodeAcertar and E.PodeAcertar and (F.Tipo <> 0) and (E.Tipo <> 0) and
         (F.Dano > 0) and (E.Dano > 0) and (J <> I) then
      begin
        if E.Flag50 then
        begin
          F.Dono := E.Dono;
          F.Lado := Lutador[E.Dono].Lado;
        end;
        if F.Flag50 then
        begin
          E.Dono := F.Dono;
          E.Lado := Lutador[F.Dono].Lado;
        end;
        if F.Dono <> E.Dono then
        begin
          if not E.Terminando then
          begin
            CriaEfeito(1, '', 0, E.X, E.Y);
            E.Tipo := 0;
          end;
          if not F.Terminando then
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
        if P.Defendendo and E.PodeAcertar and (E.Dano > 0) and (K <> E.Dono) then
        begin
          P.QuadroAcao := 1;
          SomPendente := 10;
          CriaEfeito(14, '', 0, E.X, E.Y);
          if P.Lado = 1 then Empurra(K, -10);
          if P.Lado = 2 then Empurra(K, 10);
          if (AvisoEntrada = 0) and not RelogioParado then
          begin
            P.Vida := P.Vida - E.DanoDefesa * NivelDano;
            P.AtrasoBarra := 20;
          end;
          if P.Vida <= 0 then
          begin
            SomPendente := 9;
            AcaoJogador(K, 10);
          end;
          if not E.Terminando then E.Tipo := 0;
          E.PodeAcertar := False;
          if P.Vida > 0 then PausaImpacto := 2;
        end;

        { acertou quem estava desprotegido }
        if E.PodeAcertar and (E.Dano > 0) and not P.Vencedor and (K <> E.Dono) and not P.Defendendo then
        begin
          if P.X < O.X then P.Lado := 1;
          if P.X >= O.X then P.Lado := 2;
          SomPendente := 9;
          CriaEfeito(1, '', 0, E.X, E.Y);
          if Flash and (Random(3) = 0) then FlashVermelho := 4;
          if (Sangue and (Random(3) = 0)) or CheatSatanas then
            CriaEfeito(10, '', 0, P.X, P.Y - (P.AlturaSprite - 40));
          if O.Ativo and (P.Vida > 0) then O.Pontos := O.Pontos + 10;
          if O.TempoAcertos <= 35 then O.Acertos := 0;
          Inc(O.Acertos);
          O.TempoAcertos := 50;
          if (AvisoEntrada = 0) and not RelogioParado then
          begin
            P.Vida := P.Vida - E.Dano * NivelDano;
            if P.CargaPoder < CargaMax then P.CargaPoder := 1 * GanhoCarga + P.CargaPoder;
            P.AtrasoBarra := 20;
          end;
          if E.Variante or (P.VelY <> 0) or (P.Vida <= 0) then AcaoJogador(K, 10);
          AcaoJogador(K, 9);
          P.Recuo := 8;
          if not PrimeiroAtaque then
          begin
            O.MsgBonus := 1;
            O.TempoMsgBonus := 50;
            if O.Ativo then O.Pontos := O.Pontos + 300;
            PrimeiroAtaque := True;
          end;
          O.DesenhaPorCima := True;
          P.DesenhaPorCima := False;
          if P.Vida > 0 then PausaImpacto := 5;
          if E.Tipo = 8 then
          begin
            P.Recuo := 10;
            P.VelY := -60;
          end;
          if E.Tipo = 20 then
          begin
            P.VelY := -20;
            P.Vencedor := False;
            P.Recuo := 6;
          end;
          if (E.Tipo = 8) or (E.Tipo = 20) then
          begin
            P.Acao := 19;
            if P.Lado = 1 then P.VelAngular := -20;
            if P.Lado = 2 then P.VelAngular := 20;
          end;
          if not E.Terminando then E.Tipo := 0;
          E.PodeAcertar := False;
          AtualizaQuadro(K);
        end;

        { energeticos: curam ao tocar }
        if ((E.Tipo = 3) or (E.Tipo = 4)) and (E.Quadro > 13) and (P.Vida > 0) and not RelogioParado then
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
        if E.Contagem >= E.LimiteContagem - 2 then E.PodeAcertar := True;
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
