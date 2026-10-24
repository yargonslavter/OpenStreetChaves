{ Estado10_Final.inc - Estado CHS_FINAL: final de cada personagem (cenas temporizadas com legenda).
  O roteiro de cada final vem de Dados/Finais.ini. }

{ Le Dados/Finais.ini: [FinalN] com Legenda= e linhas N=condicao: comando args. }
procedure TJogo.LerFinais(const Arquivo: string);
var
  Ini: TMemIniFile;
  Linhas, Partes, Grupos: TStringList;
  F, I, G, NL, P: Integer;
  V, Cond, Cmd, Termo: string;
  C: TComandoFinal;
begin
  SetLength(FFinais, 1);
  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Grupos := TStringList.Create;
  Grupos.Delimiter := '|';
  Grupos.StrictDelimiter := True;
  Ini := TMemIniFile.Create(Arquivo);
  try
    F := 1;
    while Ini.SectionExists('Final' + IntToStr(F)) do
    begin
      SetLength(FFinais, F + 1);
      FFinais[F].Legenda := Ini.ReadInteger('Final' + IntToStr(F), 'Legenda', 0);
      NL := 1;
      while Ini.ValueExists('Final' + IntToStr(F), IntToStr(NL)) do
      begin
        V := Ini.ReadString('Final' + IntToStr(F), IntToStr(NL), '');
        Inc(NL);
        P := Pos(':', V);
        if P = 0 then Continue;
        Cond := Trim(Copy(V, 1, P - 1));
        Cmd := Trim(Copy(V, P + 1, MaxInt));
        { condicao: grupos separados por |, termos por & }
        SetLength(C.Grupos, 0);
        if Cond <> '*' then
        begin
          Grupos.DelimitedText := Cond;
          SetLength(C.Grupos, Grupos.Count);
          for G := 0 to Grupos.Count - 1 do
          begin
            SepararLista(StringReplace(Grupos[G], '&', ',', [rfReplaceAll]), Partes);
            SetLength(C.Grupos[G], Partes.Count);
            for I := 0 to Partes.Count - 1 do
            begin
              Termo := Partes[I];
              with C.Grupos[G][I] do
              begin
                Tipo := UpCase(Termo[1]);
                Op := '';
                if Tipo = 'T' then
                begin
                  if (Length(Termo) >= 3) and (Termo[3] in ['=', '>']) then Op := Copy(Termo, 2, 2)
                  else Op := Copy(Termo, 2, 1);
                  K := StrToIntDef(Copy(Termo, 2 + Length(Op), MaxInt), 0);
                end
                else
                  K := StrToIntDef(Copy(Termo, 2, MaxInt), 1);
              end;
            end;
          end;
        end;
        { comando: nome e argumentos separados por virgula }
        P := Pos(' ', Cmd);
        if P = 0 then P := Length(Cmd) + 1;
        C.Nome := LowerCase(Copy(Cmd, 1, P - 1));
        SepararLista(Trim(Copy(Cmd, P + 1, MaxInt)), Partes);
        SetLength(C.Args, Partes.Count);
        for I := 0 to Partes.Count - 1 do C.Args[I] := Partes[I];
        with FFinais[F] do
        begin
          SetLength(Comandos, Length(Comandos) + 1);
          Comandos[High(Comandos)] := C;
        end;
      end;
      Inc(F);
    end;
  finally
    Ini.Free;
    Grupos.Free;
    Partes.Free;
    Linhas.Free;
  end;
end;

{ Executa, em ordem, os comandos do final F cuja condicao vale no tempo T. }
procedure TJogo.ExecutarFinal(const F: TFinal; T: Integer);
var
  I, G, J, X, Y: Integer;
  Vale, Grupo: Boolean;
  A: array of string;
  Cmd: string;

  { @param(K posicao do argumento)
    @returns(o argumento como numero (0 se faltar)) }
  function N(K: Integer): Integer;
  begin
    if K < Length(A) then Result := StrToIntDef(A[K], 0) else Result := 0;
  end;

  { @param(K posicao do argumento)
    @returns(o argumento como texto ('' se faltar)) }
  function Arg(K: Integer): string;
  begin
    if K < Length(A) then Result := A[K] else Result := '';
  end;

  { Argumento com sorteio: "150+R100" = 150 + Random(100).
    @param(K posicao do argumento)
    @returns(o valor) }
  function Sorteado(K: Integer): Integer;
  var
    P: Integer;
  begin
    P := Pos('+R', Arg(K));
    if P = 0 then Exit(N(K));
    Result := StrToIntDef(Copy(Arg(K), 1, P - 1), 0) + Random(StrToIntDef(Copy(Arg(K), P + 2, MaxInt), 1));
  end;

begin
  for I := 0 to High(F.Comandos) do
  begin
    { condicao (como no original: para no primeiro termo falso, sem sortear a toa) }
    Vale := Length(F.Comandos[I].Grupos) = 0;
    for G := 0 to High(F.Comandos[I].Grupos) do
    begin
      Grupo := True;
      for J := 0 to High(F.Comandos[I].Grupos[G]) do
      begin
        with F.Comandos[I].Grupos[G][J] do
          if Tipo = 'R' then Grupo := Random(K) = 0
          else Grupo := CompararInt(T, Op, K);
        if not Grupo then Break;
      end;
      if Grupo then
      begin
        Vale := True;
        Break;
      end;
    end;
    if not Vale then Continue;
    A := F.Comandos[I].Args;
    Cmd := F.Comandos[I].Nome;
    if Cmd = 'cenario' then carregarcenario(N(0))
    else if Cmd = 'lutador' then carregarlutador(ArquivoNN(FPadraoLutador, N(0)), N(0), N(1))
    else if Cmd = 'desenha' then desenhalutador(N(0), N(1), N(2), N(3), N(4))
    else if Cmd = 'fala' then F10_Fala(Rect(N(0), N(1), N(2), N(3)), Arg(4), N(5), N(6))
    else if Cmd = 'imagem' then ImgFinal.PorNome(Arg(0)).Draw(Tela, N(1), N(2), 0)
    else if Cmd = 'preto' then barra(0, 0, LarguraTela, AlturaTela, Preto)
    else if Cmd = 'explosao' then F10_Explosao
    else if Cmd = 'efeito' then
    begin
      X := Sorteado(1);
      Y := Sorteado(2);
      CriaEfeito(N(0), '', 0, X, Y);
    end;
  end;
end;

{ Sombra translucida sob o balao e a figura do final Img, em (X, Y). }
procedure TJogo.F10_Fala(R: TRect; const Img: string; X, Y: Integer);
var
  Sup: TSuperficie;
begin
  Sup := Tela;
  ImgEfeitos.PorNome('Sombra').DrawAlpha(Sup, R, 0, 70);
  ImgFinal.PorNome(Img).Draw(Sup, X, Y, 0);
end;

{ Tela cheia de cor aleatoria com duas fagulhas (explosao). }
procedure TJogo.F10_Explosao;
begin
  barra(50, 50, 350, 220, RGB(255, Random(255), Random(255)));
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
  CriaEfeito(1, '', 0, Random(150) + 130, Random(100) + 100);
end;

procedure TJogo.Estado10_Final;
var
  Sup: TSuperficie;
  T, Base, Seg, Linha4, I: Integer;
  Cod: string;
begin
  Sup := Tela;
  CameraX := 0;
  CameraY := 0;
  ChaoY := 210;
  Lutador[1].X := 100;
  Lutador[1].Lado := ldDireita;
  Lutador[2].X := 200;
  Lutador[2].Lado := ldEsquerda;
  T := TempoEstado;

  if T = 0 then
  begin
    if Lutador[1].Ativo then FinalId := Lutador[1].Personagem;
    if Lutador[2].Ativo then FinalId := Lutador[2].Personagem;
  end;

  if ImgCenario.Count > 0 then
  begin
    ImgCenario[0].Draw(Sup, -80, -100, 0);
  end;

  { cena do final (Dados/Finais.ini) }
  Base := 0;
  if (FinalId >= 1) and (FinalId <= High(FFinais)) then
  begin
    Base := FFinais[FinalId].Legenda;
    ExecutarFinal(FFinais[FinalId], T);
  end;

  desenhaefeitos;

  // moldura de cinema: so a janela central aparece
  barra(0, 0, LarguraTela, 50, Preto);
  barra(0, 220, LarguraTela, AlturaTela, Preto);
  barra(0, 50, 50, 220, Preto);
  barra(350, 50, LarguraTela, 220, Preto);

  // legenda: a cada 200 quadros muda o trecho (4 linhas do memo de finais por trecho)
  Seg := T div 200;
  if Seg > 10 then Seg := 10;
  Linha4 := Seg * 4 + Base;
  Cod := Linha(TxtFinais, Linha4);
  if Cod = '-' then Tmp4494 := 99;
  for I := 0 to 14 do
    if Cod = Chr(Ord('A') + I) then Tmp4494 := I * 5;
  if (Tmp4494 <> 99) and (ImgRetrato.Count > Tmp4494) and (T < 2200) then
  begin
    ImgRetrato[Tmp4494].Draw(Sup, 20, 222, 0);
  end;
  if (Tmp4494 <> 99) and (T < 2200) then
  begin
    texto(80, 228, Linha(TxtFinais, Linha4 + 1), AEsq, 12, Branco);
    texto(80, 245, Linha(TxtFinais, Linha4 + 2), AEsq, 12, Branco);
    texto(80, 262, Linha(TxtFinais, Linha4 + 3), AEsq, 12, Branco);
  end;

  Inc(TempoEstado);
  if TempoEstado > 2200 then
  begin
    ContPisca := 0;
    TempoEstado := 0;
    Estado := CHS_AVISO;
  end;

  // qualquer botao ativo pula para o fim do trecho atual
  if (((TecP1 and 16) <> 0) and Lutador[1].Ativo) or
     (((TecP2 and 16) <> 0) and Lutador[2].Ativo) then
    for I := 0 to 20 do
      if (TempoEstado > I * 100 + 5) and (TempoEstado < I * 100 + 85) then
        TempoEstado := I * 100 + 85;
end;
