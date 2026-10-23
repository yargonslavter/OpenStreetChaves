{ Comum_Recursos.inc - Carga de recursos (lutadores, cenarios, rostos, falas, animacoes, sons e musicas). }

{ Copia o quadro [X1,X2) x [Y1,Y2) da folha FFrameSheet para Indice das listas
  ImgLutador (normal) e ImgLutadorInvert (espelhado). }
procedure TJogo.copiabmp(Indice, X1, Y1, X2, Y2: Integer);
begin
  ImgLutador[Indice].AtribuirRegiao(FFrameSheet, X1, Y1, X2, Y2, False, True, CorTransparente);
  ImgLutadorInvert[Indice].AtribuirRegiao(FFrameSheet, X1, Y1, X2, Y2, True, True, CorTransparente);
end;

{ Carrega a folha de sprites do lutador. Os quadros sao separados por colunas
  "escuras" (R,G,B <= 100 no topo e na base). Jogador 1 ocupa os indices 1.. e
  jogador 2 os indices 51.. das listas. }
procedure TJogo.carregarlutador(const Nome: string; Personagem: Byte; Jogador: Integer);
var
  Desloc, Cont, Ini, Col, W, H: Integer;
  C1, C2: TColor;

  function Escuro(C: TColor): Boolean;
  begin
    Result := ((C and $FF) <= 100) and (((C shr 8) and $FF) <= 100) and (((C shr 16) and $FF) <= 100);
  end;

begin
  if not FileExists(Nome) then
  begin
    QuadroAtivo := True;
    Exit;
  end;
  if FFrameSheet = nil then FFrameSheet := TSuperficie.Create;
  FFrameSheet.CarregarBMP(Nome);
  Desloc := 0;
  if Jogador = 1 then Desloc := 0;
  if Jogador = 2 then Desloc := 50;

  Lutador[Jogador].Personagem := Personagem;
  case Personagem of
    1: Lutador[Jogador].AlturaSprite := 156;
    2: Lutador[Jogador].AlturaSprite := 162;
    3: Lutador[Jogador].AlturaSprite := 147;
    4: Lutador[Jogador].AlturaSprite := 149;
    5: Lutador[Jogador].AlturaSprite := 144;
    6: Lutador[Jogador].AlturaSprite := 190;
    7: Lutador[Jogador].AlturaSprite := 160;
    8: Lutador[Jogador].AlturaSprite := 160;
    9: Lutador[Jogador].AlturaSprite := 150;
    10: Lutador[Jogador].AlturaSprite := 155;
    11: Lutador[Jogador].AlturaSprite := 155;
    12: Lutador[Jogador].AlturaSprite := 165;
    13: Lutador[Jogador].AlturaSprite := 155;
    14: Lutador[Jogador].AlturaSprite := 160;
    15: Lutador[Jogador].AlturaSprite := 165;
  end;

  W := FFrameSheet.Width;
  H := FFrameSheet.Height;
  Ini := 0;
  Cont := 1;
  for Col := 0 to W - 1 do
  begin
    C1 := FFrameSheet.Pixels[Col, 0];
    C2 := FFrameSheet.Pixels[Col, H - 1];
    if Escuro(C1) and Escuro(C2) then
    begin
      copiabmp(Cont + Desloc, Ini, 0, Col - 1, H - 1);
      Inc(Cont);
      Ini := Col + 1;
    end;
  end;
  QuadroAtivo := True;
end;

procedure TJogo.carregarcenario(const Nome: string);
begin
  QuadroAtivo := False;
  if FileExists(Nome) then ImgCenario[0].CarregarArquivo(Nome, False, CorTransparente);
  ItemBonus.Icone := 0;
  if CenarioAtual = 2 then
  begin
    ItemBonus.X := 395;
    ItemBonus.Y := 195;
    ItemBonus.Dx1 := 25;
    ItemBonus.Dy1 := 25;
    ItemBonus.Dx2 := 110;
    ItemBonus.Dy2 := 90;
    ItemBonus.Icone := 6;
  end;
  QuadroAtivo := True;
end;

{ Variante 1 = imagem normal, 2 = espelhada na horizontal }
procedure TJogo.carregarosto(const Nome: string; Variante: Byte);
var
  Item: TImagem;
  Folha: TSuperficie;
begin
  Item := ImgRetrato.Adicionar;
  if not FileExists(Nome) then Exit;
  if Variante = 1 then
    Item.CarregarArquivo(Nome, True, CorTransparente)
  else
  begin
    Folha := TSuperficie.Create;
    try
      Folha.CarregarBMP(Nome);
      Item.AtribuirRegiao(Folha, 0, 0, Folha.Width, Folha.Height, True, True, CorTransparente);
    finally
      Folha.Free;
    end;
  end;
end;

procedure TJogo.carregarfala(const Nome: string);
begin
  SomVitoria.Adicionar(Nome);
end;

procedure TJogo.carregaranimacao(const Nome: string);
var
  Item: TImagem;
begin
  Item := ImgAnimacao.Adicionar;
  if FileExists(Nome) then Item.CarregarArquivo(Nome, True, CorTransparente);
end;

procedure TJogo.carregareftsonoro(const Nome: string);
begin
  SomEfeitos.Adicionar(Nome);
end;

procedure TJogo.carregarmusica(Numero: Byte);
var
  Nome: string;
begin
  Nome := '';
  if Numero < 10 then Nome := 'Musicas/Musica-0' + IntToStr(Numero) + '.wav';
  if Numero >= 10 then Nome := 'Musicas/Musica-' + IntToStr(Numero) + '.wav';
  if FileExists(Nome) then
  begin
    SomMusica.Carregar(0, Nome);
    MusicaAtual := Numero;
  end;
end;

{ Efeitos: uma imagem normal e uma espelhada, em listas separadas }
procedure TJogo.carregarefeitos(const Nome: string);
var
  Normal, Espelhada: TImagem;
  Folha: TSuperficie;
begin
  Normal := ImgEfeitos.Adicionar;
  Espelhada := ImgEfeitosInvert.Adicionar;
  if not FileExists(Nome) then Exit;
  Normal.CarregarArquivo(Nome, True, CorTransparente);
  Folha := TSuperficie.Create;
  try
    Folha.CarregarBMP(Nome);
    Espelhada.AtribuirRegiao(Folha, 0, 0, Folha.Width, Folha.Height, True, True, CorTransparente);
  finally
    Folha.Free;
  end;
end;
