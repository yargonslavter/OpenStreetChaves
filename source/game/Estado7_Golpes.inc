{ Estado7_Golpes.inc - Estado CHS_LUTA: golpes, sequencias, CPU e defesa (seta, sequencia, golpe, sequenciagolpe, cpu, defendergolpe). Gerado a partir do codigo de maquina e revisado a mao. }


function TJogo.seta(Jog: Byte; const Dir: string): Boolean;
{ Responde True se o jogador esta segurando a direcao pedida:
  'CIMA', 'BAIXO', 'FRENTE' (para onde esta virado) ou 'TRAS'. Jogador 1 = teclado, 2 = "joystick". }
var
  K: Byte;
begin
  Result := False;
  if Jog = 1 then K := TecP1 else K := TecP2;
  if ((K and 2) <> 0) and (Dir = 'BAIXO') then Result := True;
  if ((K and 1) <> 0) and (Dir = 'CIMA') then Result := True;
  if (K and 4) <> 0 then      // esquerda
  begin
    if (Lutador[Jog].Lado = 1) and (Dir = 'TRAS') then Result := True;
    if (Lutador[Jog].Lado = 2) and (Dir = 'FRENTE') then Result := True;
  end;
  if (K and 8) <> 0 then      // direita
  begin
    if (Lutador[Jog].Lado = 2) and (Dir = 'TRAS') then Result := True;
    if (Lutador[Jog].Lado = 1) and (Dir = 'FRENTE') then Result := True;
  end;
end;

procedure TJogo.sequencia(Jog, De, Para: Byte);
{ avanca a sequencia de teclas de um golpe especial: se esta no passo De, vai para o passo Para }
begin
  if Lutador[Jog].SeqEstado = De then
  begin
    Lutador[Jog].SeqEstado := Para;
    Lutador[Jog].SeqTempo := 9;
  end;
end;

procedure TJogo.golpe(Jog, Botao: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if FlashTela = 0 then
  begin
    if (P.Personagem) = 1 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 2 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 10) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 10) then
      begin
        AcaoJogador(Jog, 23);
      end;
    end;
    if (P.Personagem) = 3 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 4 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 9) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 9) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 11) then
      begin
        AcaoJogador(Jog, 23);
      end;
    end;
    if (P.Personagem) = 5 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.CargaChute) >= 6) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.CargaChute) >= 6) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 6 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 7) then
      begin
        AcaoJogador(Jog, 23);
      end;
    end;
    if (P.Personagem) = 7 then
    begin
      if (Botao = 1) and ((P.CargaSoco) >= 6) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.CargaSoco) >= 6) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 1) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 1) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 8 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 2) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) and ((P.VelY) <> 0) then
      begin
        AcaoJogador(Jog, 19);
      end;
    end;
    if (P.Personagem) = 9 then
    begin
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 17);
      end;
    end;
    if (P.Personagem) = 10 then
    begin
      if (Botao = 1) and ((P.CargaSoco) >= 6) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.CargaSoco) >= 6) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 1) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 1) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 4) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 11 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 21);
      end;
    end;
    if (P.Personagem) = 12 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 17);
      end;
    end;
    if (P.Personagem) = 13 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 25);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 10) then
      begin
        AcaoJogador(Jog, 26);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 10) then
      begin
        AcaoJogador(Jog, 26);
      end;
    end;
    if (P.Personagem) = 14 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 5) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 21);
      end;
    end;
    if (P.Personagem) = 15 then
    begin
      if (Botao = 1) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 16);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 17);
      end;
      if (Botao = 1) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 18);
      end;
      if (Botao = 3) and ((P.SeqEstado) = 3) then
      begin
        AcaoJogador(Jog, 19);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 20);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 6) then
      begin
        AcaoJogador(Jog, 21);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 22);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 2) then
      begin
        AcaoJogador(Jog, 23);
      end;
      if (Botao = 2) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
      if (Botao = 4) and ((P.SeqEstado) = 8) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
  end;
end;

procedure TJogo.sequenciagolpe(Jog: Byte);
var
  P: PLutador;
begin
  P := @Lutador[Jog];
  if seta(Jog, 'BAIXO') then
  begin
    P.TempoBaixo := (P.TempoBaixo)+1;
  end;
  if (P.TempoBaixo) > 18 then
  begin
    P.TempoBaixo := 18;
  end;
  if not seta(Jog, 'BAIXO') and ((P.TempoBaixo) > 1) then
  begin
    P.TempoBaixo := (P.TempoBaixo)-1;
  end;
  if seta(Jog, 'TRAS') then
  begin
    P.TempoTras := (P.TempoTras)+1;
  end;
  if (P.TempoTras) > 18 then
  begin
    P.TempoTras := 18;
  end;
  if not seta(Jog, 'TRAS') and ((P.TempoTras) > 1) then
  begin
    P.TempoTras := (P.TempoTras)-1;
  end;
  if (P.Personagem) = 1 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 10) and (((ChaoY)) = P.Y) then
    begin
      sequencia(Jog, 0, 4);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 10) and (((ChaoY)) = P.Y) then
    begin
      sequencia(Jog, 1, 4);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 5);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 6);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
  end;
  if (P.Personagem) = 2 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 3, 7);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 9);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 9, 10);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 2, 10);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 9, 10);
    end;
  end;
  if (P.Personagem) = 3 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 7);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 8);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
  end;
  if (P.Personagem) = 4 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 4, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 7, 2);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 4);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 5);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 7);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 7);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 9);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 10);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 10, 11);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 11);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 10, 11);
    end;
  end;
  if (P.Personagem) = 5 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 1);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 5) and (((ChaoY)) = P.Y) then
    begin
      sequencia(Jog, 0, 4);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 5) and (((ChaoY)) = P.Y) then
    begin
      sequencia(Jog, 1, 4);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 5);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
  end;
  if (P.Personagem) = 6 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 6);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 7);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 7);
    end;
  end;
  if (P.Personagem) = 7 then
  begin
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') and ((P.TempoTras) >= 6) then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 6) then
    begin
      sequencia(Jog, 0, 2);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 6) then
    begin
      sequencia(Jog, 3, 2);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
  end;
  if (P.Personagem) = 8 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 1);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 7);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
  end;
  if (P.Personagem) = 9 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if not seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 7);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
  end;
  if (P.Personagem) = 10 then
  begin
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') and ((P.TempoTras) >= 6) then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 6) then
    begin
      sequencia(Jog, 0, 2);
    end;
    if seta(Jog, 'CIMA') and not seta(Jog, 'BAIXO') and ((P.TempoBaixo) >= 6) then
    begin
      sequencia(Jog, 3, 2);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if not seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') and ((P.TempoTras) >= 6) then
    begin
      sequencia(Jog, 1, 5);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 5, 6);
    end;
  end;
  if (P.Personagem) = 11 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
  end;
  if (P.Personagem) = 12 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 2);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 6, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 7);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
  end;
  if (P.Personagem) = 13 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 5, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 0, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 4);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 8, 5);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 5, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') and ((P.TempoTras) >= 6) then
    begin
      sequencia(Jog, 0, 7);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') and ((P.TempoTras) >= 6) then
    begin
      sequencia(Jog, 7, 7);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'FRENTE') then
    begin
      sequencia(Jog, 8, 9);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 9, 10);
    end;
  end;
  if (P.Personagem) = 14 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 2);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 0, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 3, 3);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 6);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 6, 8);
    end;
  end;
  if (P.Personagem) = 15 then
  begin
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 0, 1);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 1, 1);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 2);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 1, 3);
    end;
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 5, 3);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 0, 4);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 4, 4);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 4, 5);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 2, 5);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 5, 6);
    end;
    if seta(Jog, 'BAIXO') and not seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 7);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 3, 8);
    end;
    if seta(Jog, 'BAIXO') and seta(Jog, 'FRENTE') and not seta(Jog, 'TRAS') then
    begin
      sequencia(Jog, 7, 8);
    end;
    if seta(Jog, 'FRENTE') and not seta(Jog, 'BAIXO') then
    begin
      sequencia(Jog, 7, 8);
    end;
  end;
  if ((P.SeqTempo) > 0) and (PausaImpacto = 0) and (FlashTela = 0) then
  begin
    P.SeqTempo := (P.SeqTempo)-1;
    if (P.SeqTempo) = 0 then
    begin
      P.SeqEstado := 0;
    end;
  end;
end;

procedure TJogo.cpu(Jog: Byte);
{ IA do computador: decide os comandos do lutador Jog (equivale a apertar teclas) }
var
  P, O: PLutador;
  E: PEfeito;
  Dist, DistProj, OppY, S_18, I: Integer;
  Ameaca: Byte;
  Fator: Double;
  r7, r9, r11, r13, r17, r19, r21, r25, r28, r31, r34, r42, r45, r48, r51, r54, r58, r61, r64, r67, r70, r75, r78, r81, r84, r87, r92, r95, r98, r101, r104, r109, r112, r115, r118, r123, r126, r129, r132, r137, r140, r143, r146, r149, r154, r157, r160, r163, r168, r171, r174, r177, r182, r185, r188, r191, r196, r199, r202, r205, r208, r213, r216, r219, r222, r225, r230, r233, r236, r239, r242, r247, r250, r253, r256, r259, r262, r265: Integer;
begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  Dist := Abs(Round(Lutador[1].X) - Round(Lutador[2].X));
  OppY := Round(O.Y);
  Ameaca := 0;
  DistProj := 0;
  for I := 1 to MaxEfeitos do
  begin
    E := @Efeitos[I];
    if E.PodeAcertar and (E.Dono <> Jog) and (E.Tipo <> 0) then
    begin
      Ameaca := 1;
      DistProj := Abs(Round(P.X) - Round(E.X));
    end;
  end;
  Fator := (8 - NivelJogo) * 0.6 + 1.3 - Fase * 0.1;
  if Random(13) = 0 then
  begin
    case Random(6) of
      0: P.DistanciaIA := 100;
      1: P.DistanciaIA := 150;
      2: P.DistanciaIA := 200;
      3: P.DistanciaIA := 250;
      4: P.DistanciaIA := 300;
      5: P.DistanciaIA := 350;
    end;
  end;
  if Abs(Dist - P.DistanciaIA) <= 50 then P.DistanciaIA := Dist;
  if not P.Defendendo and (Ameaca = 0) then
  begin
    if (Dist >= P.DistanciaIA) and ((P.Lado) = 1) then
    begin
      AcaoJogador(Jog, 2);
    end;
    if (Dist < P.DistanciaIA) and ((P.Lado) = 1) then
    begin
      AcaoJogador(Jog, 1);
    end;
    if (Dist >= P.DistanciaIA) and ((P.Lado) = 2) then
    begin
      AcaoJogador(Jog, 1);
    end;
    if (Dist < P.DistanciaIA) and ((P.Lado) = 2) then
    begin
      AcaoJogador(Jog, 2);
    end;
  end;
  if not P.Defendendo and (Ameaca = 0) and (Dist <= 80) then
  begin
    r7 := Random(Round(8 * Fator));
    if r7 = 0 then
    begin
      AcaoJogador(Jog, 3);
    end;
    r9 := Random(Round(8 * Fator));
    if r9 = 0 then
    begin
      AcaoJogador(Jog, 4);
    end;
    r11 := Random(Round(9 * Fator));
    if r11 = 0 then
    begin
      AcaoJogador(Jog, 5);
    end;
    r13 := Random(Round(9 * Fator));
    if r13 = 0 then
    begin
      AcaoJogador(Jog, 6);
    end;
    if Random(Round(4 * Fator)) = 0 then
    begin
      AcaoJogador(Jog, 7);
      r17 := Random(Round(2 * Fator));
      if r17 = 0 then
      begin
        AcaoJogador(Jog, 3);
      end;
      r19 := Random(Round(2 * Fator));
      if r19 = 0 then
      begin
        AcaoJogador(Jog, 4);
      end;
      r21 := Random(Round(3 * Fator));
      if r21 = 0 then
      begin
        AcaoJogador(Jog, 5);
      end;
      if Random(Round(3 * Fator)) = 0 then
      begin
        AcaoJogador(Jog, 6);
      end;
    end;
  end;
  if not P.Defendendo then
  begin
    if (P.Personagem) = 1 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r25 := Random(Round(7 * Fator));
        if r25 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r28 := Random(Round(30 * Fator));
        if r28 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r31 := Random(Round(40 * Fator));
        if r31 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Dist < 150) and (((ChaoY)) > O.Y) then
      begin
        r34 := Random(Round(50 * Fator));
        if r34 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(40 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, Random(2)+22);
      end;
      if (Dist < 150) and (((ChaoY)) > O.Y) and (Random(Round(50 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 2 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r42 := Random(Round(8 * Fator));
        if r42 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r45 := Random(Round(30 * Fator));
        if r45 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r48 := Random(Round(20 * Fator));
        if r48 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if Dist < 200 then
      begin
        S_18 := ((ChaoY))-100;
        if ((S_18)) > P.Y then
        begin
          r51 := Random(Round(10 * Fator));
          if r51 = 0 then
          begin
            AcaoJogador(Jog, Random(2)+20);
          end;
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r54 := Random(Round(40 * Fator));
        if r54 = 0 then
        begin
          AcaoJogador(Jog, 22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 250) and (Random(Round(55 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 23);
      end;
    end;
    if (P.Personagem) = 3 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r58 := Random(Round(8 * Fator));
        if r58 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r61 := Random(Round(45 * Fator));
        if r61 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r64 := Random(Round(18 * Fator));
        if r64 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r67 := Random(Round(20 * Fator));
        if r67 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 150) then
      begin
        r70 := Random(Round(40 * Fator));
        if r70 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 250) and (Random(Round(60 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 4 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r75 := Random(Round(8 * Fator));
        if r75 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r78 := Random(Round(40 * Fator));
        if r78 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r81 := Random(Round(35 * Fator));
        if r81 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r84 := Random(Round(40 * Fator));
        if r84 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 100 then
      begin
        r87 := Random(Round(10 * Fator));
        if r87 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 250) and (Random(Round(60 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 5 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r92 := Random(Round(8 * Fator));
        if r92 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r95 := Random(Round(50 * Fator));
        if r95 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 150) then
      begin
        r98 := Random(Round(30 * Fator));
        if r98 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 300) then
      begin
        r101 := Random(Round(40 * Fator));
        if r101 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 100 then
      begin
        r104 := Random(Round(10 * Fator));
        if r104 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(50 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 6 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r109 := Random(Round(6 * Fator));
        if r109 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r112 := Random(Round(30 * Fator));
        if r112 = 0 then
        begin
          AcaoJogador(Jog, Random(4)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r115 := Random(Round(18 * Fator));
        if r115 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r118 := Random(Round(35 * Fator));
        if r118 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(45 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 7 then
    begin
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r123 := Random(Round(40 * Fator));
        if r123 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r126 := Random(Round(10 * Fator));
        if r126 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 150) then
      begin
        r129 := Random(Round(30 * Fator));
        if r129 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r132 := Random(Round(30 * Fator));
        if r132 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(50 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 8 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r137 := Random(Round(7 * Fator));
        if r137 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r140 := Random(Round(30 * Fator));
        if r140 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if Dist < 200 then
      begin
        S_18 := ((ChaoY))-100;
        if ((S_18)) > P.Y then
        begin
          r143 := Random(Round(5 * Fator));
          if r143 = 0 then
          begin
            AcaoJogador(Jog, Random(2)+18);
          end;
        end;
      end;
      if (Ameaca = 0) and (Dist < 150) then
      begin
        r146 := Random(Round(20 * Fator));
        if r146 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist > 100) then
      begin
        r149 := Random(Round(30 * Fator));
        if r149 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist > 100) and (Random(Round(40 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 9 then
    begin
      if (Ameaca = 0) and (Dist < 200) then
      begin
        r154 := Random(Round(30 * Fator));
        if r154 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if Dist < 100 then
      begin
        r157 := Random(Round(5 * Fator));
        if r157 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if Dist < 150 then
      begin
        r160 := Random(Round(5 * Fator));
        if r160 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r163 := Random(Round(30 * Fator));
        if r163 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(40 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 10 then
    begin
      if Dist < 200 then
      begin
        r168 := Random(Round(20 * Fator));
        if r168 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 300) then
      begin
        r171 := Random(Round(40 * Fator));
        if r171 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if Dist < 100 then
      begin
        r174 := Random(Round(20 * Fator));
        if r174 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 200 then
      begin
        r177 := Random(Round(40 * Fator));
        if r177 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(40 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 11 then
    begin
      if Dist < 200 then
      begin
        r182 := Random(Round(20 * Fator));
        if r182 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if Dist < 300 then
      begin
        r185 := Random(Round(40 * Fator));
        if r185 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if Dist < 300 then
      begin
        r188 := Random(Round(30 * Fator));
        if r188 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 200 then
      begin
        r191 := Random(Round(40 * Fator));
        if r191 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 200) and (Random(Round(40 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 12 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r196 := Random(Round(8 * Fator));
        if r196 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r199 := Random(Round(50 * Fator));
        if r199 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 80) then
      begin
        r202 := Random(Round(15 * Fator));
        if r202 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 150) then
      begin
        r205 := Random(Round(20 * Fator));
        if r205 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 200 then
      begin
        S_18 := ((ChaoY))-100;
        if ((S_18)) > P.Y then
        begin
          r208 := Random(Round(10 * Fator));
          if r208 = 0 then
          begin
            AcaoJogador(Jog, Random(2)+20);
          end;
        end;
      end;
      if (Ameaca = 0) and (Dist < 250) and (Random(Round(60 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 22);
      end;
    end;
    if (P.Personagem) = 13 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r213 := Random(Round(8 * Fator));
        if r213 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 120) then
      begin
        r216 := Random(Round(40 * Fator));
        if r216 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 90) then
      begin
        r219 := Random(Round(15 * Fator));
        if r219 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist > 130) then
      begin
        r222 := Random(Round(20 * Fator));
        if r222 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist > 120 then
      begin
        r225 := Random(Round(20 * Fator));
        if r225 = 0 then
        begin
          AcaoJogador(Jog, Random(4)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 270) and (Random(Round(50 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 26);
      end;
    end;
    if (P.Personagem) = 14 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r230 := Random(Round(6 * Fator));
        if r230 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 160) then
      begin
        r233 := Random(Round(8 * Fator));
        if r233 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 1) and (DistProj < 170) then
      begin
        r236 := Random(Round(7 * Fator));
        if r236 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 120) then
      begin
        r239 := Random(Round(2 * Fator));
        if r239 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if Dist < 80 then
      begin
        r242 := Random(Round(10 * Fator));
        if r242 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 120) and (Random(Round(30 * Fator)) = 0) then
      begin
        AcaoJogador(Jog, 24);
      end;
    end;
    if (P.Personagem) = 15 then
    begin
      if (Ameaca = 1) and (DistProj > 140) then
      begin
        r247 := Random(Round(6 * Fator));
        if r247 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist > 160) then
      begin
        r250 := Random(Round(12 * Fator));
        if r250 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+16);
        end;
      end;
      if (Ameaca = 0) and (Dist < 100) then
      begin
        r253 := Random(Round(20 * Fator));
        if r253 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+18);
        end;
      end;
      if (Ameaca = 0) and (Dist < 120) then
      begin
        r256 := Random(Round(25 * Fator));
        if r256 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 80) and ((((ChaoY))-50) > OppY) then
      begin
        r259 := Random(Round(6 * Fator));
        if r259 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+20);
        end;
      end;
      if (Ameaca = 0) and (Dist < 140) then
      begin
        r262 := Random(Round(22 * Fator));
        if r262 = 0 then
        begin
          AcaoJogador(Jog, Random(2)+22);
        end;
      end;
      if (Ameaca = 0) and (Dist < 120) then
      begin
        r265 := Random(Round(30 * Fator));
        if r265 = 0 then
        begin
          AcaoJogador(Jog, 24);
        end;
      end;
    end;
  end;
end;

procedure TJogo.defendergolpe(Jog: Byte);
{ Defesa automatica. Jogador humano: segurar "para tras" (em pe ou agachado) defende de golpes e projeteis.
  Computador: decide defender/pular conforme a distancia e o nivel de dificuldade. }
var
  P, O: PLutador;
  E: PEfeito;
  I: Integer;
  Dist, DistProj, Ameaca: Integer;
  Terminando: Boolean;
  ProjY: Double;
  Fator: Double;

  procedure DefesaHumana;
  begin
    if seta(Jog, 'TRAS') and not seta(Jog, 'BAIXO') then AcaoJogador(Jog, 12);
    if seta(Jog, 'TRAS') and seta(Jog, 'BAIXO') then AcaoJogador(Jog, 13);
  end;

  procedure Pular;
  begin
    P.VelY := -32;
    P.NoAr := True;
    P.Acao := 12;
    P.QuadroAcao := 0;
    P.DuracaoAcao := 99;
    P.Defendendo := False;
    if P.Lado = 1 then P.DirPulo := 3;
    if P.Lado = 2 then P.DirPulo := 2;
    if Random(8) = 0 then P.DirPulo := 1;
  end;

begin
  P := @Lutador[Jog];
  O := @Lutador[3 - Jog];
  if P.Ativo then
  begin
    if O.GolpeAtivo then DefesaHumana;
    for I := 1 to MaxEfeitos do
    begin
      E := @Efeitos[I];
      if (E.Tipo <> 0) and E.PodeAcertar and (E.Dono <> Jog) then DefesaHumana;
    end;
  end;
  if not P.Ativo then
  begin
    Dist := Abs(Round(Lutador[Jog].X) - Round(O.X));
    Ameaca := 0;
    DistProj := 0;
    Terminando := False;
    ProjY := 0;
    for I := 1 to MaxEfeitos do
    begin
      E := @Efeitos[I];
      if E.PodeAcertar and (E.Dono <> Jog) and (E.Tipo <> 0) then
      begin
        Ameaca := 1;
        DistProj := Abs(Round(P.X) - Round(E.X));
        if E.Terminando then Terminando := True;
        ProjY := E.Y;
      end;
    end;
    Fator := (8 - NivelJogo) * 0.9 + 1.2 - Fase * 0.1;
    if Fator < 0 then Fator := 0;
    // golpe do adversario chegando
    if O.GolpeAtivo and (Dist <= 160) then
    begin
      if (ChaoY - 30) >= O.Y then
        if Random(Round(0.5 * Fator)) = 0 then AcaoJogador(Jog, 12);
      if (ChaoY - 30) <= O.Y then
        if Random(Round(0.5 * Fator)) = 0 then AcaoJogador(Jog, 13);
      if P.Acao = 21 then AcaoJogador(Jog, 12);
      if P.Acao = 22 then AcaoJogador(Jog, 13);
    end;
    // pulo (parado ou andando)
    if (P.Acao = 1) or (P.Acao = 2) then
    begin
      if (Ameaca = 1) and (DistProj <= 130) and ((P.Y - 120) < ProjY) and (Random(Round(5 * Fator)) <= 3) then
        Pular
      else if (Ameaca = 0) and (Random(Round(45 * Fator)) = 0) and not P.NoAr and not Terminando then
        Pular;
    end;
    // projetil chegando
    if (Ameaca = 1) and (DistProj <= 120) and ((P.Y - 120) < ProjY) then
      if Random(Round(0.4 * Fator)) = 0 then AcaoJogador(Jog, 12);
    if (Ameaca = 1) and (DistProj <= 100) and ((P.Y - 120) >= ProjY) then
      if Random(Round(2.5 * Fator)) = 0 then AcaoJogador(Jog, 13);
  end;
end;
