{ ChavesSom.pas - audio do jogo, 100% SDL2 (sem LCL, sem MCI, sem SDL2_mixer).

  Mixer proprio sobre um unico dispositivo de audio SDL (44100 Hz, 16 bits, estereo):
    - os WAVs sao carregados com SDL_LoadWAV_RW (PCM, ADPCM...) e convertidos UMA vez para o
      formato do mixer (SDL_AudioStream), ficando em memoria;
    - cada Tocar ocupa uma "voz" do mixer; um mesmo som tocado de novo corta a voz anterior
      dele (no original: MaxPlayingCount = 1);
    - sons em loop (musica) repetem sem emenda;
    - o callback de audio soma as vozes com saturacao.
  Sem placa de som o jogo segue normalmente, apenas sem tocar.

  Uso: um TBancoSom e uma lista numerada de sons. Adicionar devolve o numero do som (o espaco
  e reservado mesmo se o arquivo nao existir, para manter a numeracao do jogo).
  Volume: cada som e carregado ja com o seu volume (em % do arquivo, 0..400; 100 = sem mudanca),
  aplicado uma vez nas amostras, com corte no maximo. }

unit ChavesSom;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ctypes, sdl2, ChavesDados;

type
  TAmostra = class
  private
    FDados: PSmallInt;      // amostras estereo S16 a 44100 Hz (2 por quadro)
    FQuadros: Integer;
  public
    { Para as vozes que tocam este som e libera as amostras. }
    destructor Destroy; override;
    { Para as vozes que tocam este som e libera as amostras (o som fica vazio). }
    procedure Limpar;
    { Carrega um WAV (qualquer formato que o SDL leia), converte para o formato
      do mixer (44100 Hz, 16 bits, estereo) e aplica o volume. Sem arquivo ou com erro o som fica vazio.
      @param(Arquivo caminho do WAV (resolvido por ResolverCaminho))
      @param(Volume volume em % do arquivo, 0..400 (100 = sem mudanca)) }
    procedure CarregarArquivo(const Arquivo: string; Volume: Integer = 100);
  end;

  TBancoSom = class
  private
    FSons: TList;           // de TAmostra
    FLoop: Boolean;
    { Som pelo numero.
      @param(Indice numero do som, a partir de 0)
      @returns(o som, ou nil fora da faixa) }
    function Obter(Indice: Integer): TAmostra;
    { @returns(quantos sons o banco tem (inclusive os vazios)) }
    function GetCount: Integer;
  public
    { Cria um banco de sons vazio.
      @param(ALoop True para os sons repetirem sem fim (musica)) }
    constructor Create(ALoop: Boolean = False);
    { Para e libera todos os sons do banco. }
    destructor Destroy; override;
    { Acrescenta um som ao fim do banco. O numero e reservado mesmo se o arquivo nao
      existir, para manter a numeracao do jogo.
      @param(Arquivo caminho do WAV; '' ou inexistente = som vazio)
      @param(Volume volume em % do arquivo, 0..400 (100 = sem mudanca))
      @returns(o numero do som novo) }
    function Adicionar(const Arquivo: string; Volume: Integer = 100): Integer;
    { Troca o conteudo de um som ja existente.
      @param(Indice numero do som (fora da faixa = ignora))
      @param(Arquivo caminho do WAV novo)
      @param(Volume volume em % do arquivo, 0..400) }
    procedure Carregar(Indice: Integer; const Arquivo: string; Volume: Integer = 100);
    { Toca um som do comeco. Se ele ja estiver tocando, a voz anterior e cortada (como
      MaxPlayingCount = 1 no original); sem voz livre, rouba a mais antiga. Abre o audio na
      primeira vez. Som vazio ou numero invalido nao faz nada.
      @param(Indice numero do som) }
    procedure Tocar(Indice: Integer);
    { Para todas as vozes de um som.
      @param(Indice numero do som) }
    procedure Parar(Indice: Integer);
    property Count: Integer read GetCount;
  end;

{ Abre o dispositivo de audio (44100 Hz, 16 bits, estereo). E chamado sozinho no primeiro
  Tocar e so tenta uma vez.
  @returns(True se o audio esta disponivel) }
function SomIniciar: Boolean;

implementation

const
  TaxaMixer = 44100;
  MaxVozes = 48;
  MaxAmostras = 16384;     // capacidade do buffer de mistura (amostras, nao quadros)

type
  TVoz = record
    Ativa: Boolean;
    Loop: Boolean;
    Dono: Pointer;         // TAmostra dona (para Parar / limite por som)
    Dados: PSmallInt;
    Quadros: Integer;
    Pos: Integer;
    Seq: Cardinal;
  end;

var
  GVozes: array[0..MaxVozes - 1] of TVoz;
  GDev: TSDL_AudioDeviceID = 0;
  GTentou: Boolean = False;
  GSeq: Cardinal = 0;
  GAcc: array[0..MaxAmostras - 1] of LongInt;

{ ---- mixer (roda na thread de audio do SDL, que ja segura o lock do dispositivo) ---- }

{ Mixer: chamado pelo SDL na thread de audio para preencher um bloco. Soma todas as vozes
  ativas com saturacao em 16 bits, repetindo as de loop e desligando as que terminam.
  @param(userdata nao usado)
  @param(stream buffer de saida, amostras S16 estereo)
  @param(len tamanho do buffer em bytes) }
procedure CallbackAudio(userdata: Pointer; stream: pcuint8; len: cint); cdecl;
var
  Total, I, V, N, K: Integer;
  Vz: ^TVoz;
  Src: PSmallInt;
  Dst: PSmallInt;
  S: LongInt;
begin
  Total := len div 2;                       // amostras S16
  if Total > MaxAmostras then Total := MaxAmostras;
  FillChar(stream^, len, 0);
  if Total <= 0 then Exit;
  FillChar(GAcc[0], Total * SizeOf(LongInt), 0);

  for V := 0 to MaxVozes - 1 do
  begin
    Vz := @GVozes[V];
    if not Vz^.Ativa then Continue;
    K := 0;                                  // amostras ja produzidas neste bloco
    while K < Total do
    begin
      N := (Vz^.Quadros - Vz^.Pos) * 2;      // amostras restantes
      if N > Total - K then N := Total - K;
      Src := Vz^.Dados + Vz^.Pos * 2;
      for I := 0 to N - 1 do
        GAcc[K + I] := GAcc[K + I] + Src[I];
      Inc(K, N);
      Inc(Vz^.Pos, N div 2);
      if Vz^.Pos >= Vz^.Quadros then
      begin
        if Vz^.Loop and (Vz^.Quadros > 0) then
          Vz^.Pos := 0
        else
        begin
          Vz^.Ativa := False;
          Break;
        end;
      end;
    end;
  end;

  Dst := PSmallInt(stream);
  for I := 0 to Total - 1 do
  begin
    S := GAcc[I];
    if S > 32767 then S := 32767
    else if S < -32768 then S := -32768;
    Dst[I] := S;
  end;
end;

function SomIniciar: Boolean;
var
  Pedido, Obtido: TSDL_AudioSpec;
begin
  if GDev <> 0 then Exit(True);
  if GTentou then Exit(False);
  GTentou := True;
  if SDL_InitSubSystem(SDL_INIT_AUDIO) <> 0 then Exit(False);
  FillChar(Pedido, SizeOf(Pedido), 0);
  FillChar(Obtido, SizeOf(Obtido), 0);
  Pedido.freq := TaxaMixer;
  Pedido.format := AUDIO_S16SYS;
  Pedido.channels := 2;
  Pedido.samples := 1024;                    // ~23 ms por bloco
  Pedido.callback := @CallbackAudio;
  GDev := SDL_OpenAudioDevice(nil, 0, @Pedido, @Obtido, 0);   // 0: o SDL converte para o dispositivo
  if GDev = 0 then Exit(False);
  SDL_PauseAudioDevice(GDev, 0);
  Result := True;
end;

{ Trava o dispositivo de audio (o callback espera) antes de mexer nas vozes. }
procedure Travar;
begin
  if GDev <> 0 then SDL_LockAudioDevice(GDev);
end;

{ Libera o dispositivo de audio travado por Travar. }
procedure Destravar;
begin
  if GDev <> 0 then SDL_UnlockAudioDevice(GDev);
end;

{ Desliga todas as vozes que tocam um som.
  @param(Dono a TAmostra dona das vozes) }
procedure CortarVozes(Dono: Pointer);
var
  V: Integer;
begin
  Travar;
  try
    for V := 0 to MaxVozes - 1 do
      if GVozes[V].Ativa and (GVozes[V].Dono = Dono) then GVozes[V].Ativa := False;
  finally
    Destravar;
  end;
end;

{ TAmostra }

destructor TAmostra.Destroy;
begin
  Limpar;
  inherited Destroy;
end;

procedure TAmostra.Limpar;
begin
  CortarVozes(Self);
  if FDados <> nil then FreeMem(FDados);
  FDados := nil;
  FQuadros := 0;
end;

{ Multiplica as amostras por Volume/100, cortando no maximo do formato.
  @param(Dados amostras S16)
  @param(Amostras quantidade de amostras (nao de quadros))
  @param(Volume volume em %, limitado a 0..400 (100 = nao mexe)) }
procedure AplicarVolume(Dados: PSmallInt; Amostras, Volume: Integer);
var
  I: Integer;
  S: LongInt;
begin
  if (Dados = nil) or (Volume = 100) then Exit;
  if Volume < 0 then Volume := 0;
  if Volume > 400 then Volume := 400;
  for I := 0 to Amostras - 1 do
  begin
    S := (LongInt(Dados[I]) * Volume) div 100;
    if S > 32767 then S := 32767
    else if S < -32768 then S := -32768;
    Dados[I] := S;
  end;
end;

procedure TAmostra.CarregarArquivo(const Arquivo: string; Volume: Integer);
var
  Nome: string;
  F: TFileStream;
  Mem: TMemoryStream;
  Rw: PSDL_RWops;
  Spec: TSDL_AudioSpec;
  Buf: pcuint8;
  Len: cuint32;
  Conv: PSDL_AudioStream;
  Disp: Integer;
begin
  Limpar;
  Nome := ResolverCaminho(Arquivo);
  if (Arquivo = '') or not FileExists(Nome) then Exit;
  if SDL_InitSubSystem(SDL_INIT_AUDIO) <> 0 then Exit;
  Mem := TMemoryStream.Create;
  try
    F := TFileStream.Create(Nome, fmOpenRead or fmShareDenyNone);
    try
      Mem.CopyFrom(F, 0);
    finally
      F.Free;
    end;
    if Mem.Size = 0 then Exit;
    Rw := SDL_RWFromMem(Mem.Memory, Mem.Size);
    if Rw = nil then Exit;
    Buf := nil;
    Len := 0;
    FillChar(Spec, SizeOf(Spec), 0);
    if SDL_LoadWAV_RW(Rw, 1, @Spec, @Buf, @Len) = nil then Exit;   // freesrc=1 fecha o Rw
    try
      Conv := SDL_NewAudioStream(Spec.format, Spec.channels, Spec.freq, AUDIO_S16SYS, 2, TaxaMixer);
      if Conv = nil then Exit;
      try
        if SDL_AudioStreamPut(Conv, Buf, Len) <> 0 then Exit;
        SDL_AudioStreamFlush(Conv);
        Disp := SDL_AudioStreamAvailable(Conv);
        Disp := Disp - (Disp mod 4);
        if Disp <= 0 then Exit;
        GetMem(FDados, Disp);
        if SDL_AudioStreamGet(Conv, FDados, Disp) < 0 then
        begin
          FreeMem(FDados);
          FDados := nil;
          Exit;
        end;
        FQuadros := Disp div 4;
        AplicarVolume(FDados, FQuadros * 2, Volume);
      finally
        SDL_FreeAudioStream(Conv);
      end;
    finally
      SDL_FreeWAV(Buf);
    end;
  finally
    Mem.Free;
  end;
end;

{ TBancoSom }

constructor TBancoSom.Create(ALoop: Boolean);
begin
  inherited Create;
  FSons := TList.Create;
  FLoop := ALoop;
end;

destructor TBancoSom.Destroy;
var
  I: Integer;
begin
  for I := 0 to FSons.Count - 1 do TAmostra(FSons[I]).Free;
  FSons.Free;
  inherited Destroy;
end;

function TBancoSom.GetCount: Integer;
begin
  Result := FSons.Count;
end;

function TBancoSom.Obter(Indice: Integer): TAmostra;
begin
  if (Indice >= 0) and (Indice < FSons.Count) then Result := TAmostra(FSons[Indice]) else Result := nil;
end;

function TBancoSom.Adicionar(const Arquivo: string; Volume: Integer): Integer;
var
  A: TAmostra;
begin
  A := TAmostra.Create;
  if Arquivo <> '' then A.CarregarArquivo(Arquivo, Volume);
  Result := FSons.Add(A);
end;

procedure TBancoSom.Carregar(Indice: Integer; const Arquivo: string; Volume: Integer);
var
  A: TAmostra;
begin
  A := Obter(Indice);
  if A <> nil then A.CarregarArquivo(Arquivo, Volume);
end;

procedure TBancoSom.Tocar(Indice: Integer);
var
  A: TAmostra;
  V, Livre, Antiga, AntigaSom: Integer;
begin
  A := Obter(Indice);
  if (A = nil) or (A.FDados = nil) then Exit;
  if not SomIniciar then Exit;
  Travar;
  try
    { um som tocado de novo corta a voz anterior dele }
    repeat
      AntigaSom := -1;
      for V := 0 to MaxVozes - 1 do
        if GVozes[V].Ativa and (GVozes[V].Dono = Pointer(A)) then
        begin
          AntigaSom := V;
          Break;
        end;
      if AntigaSom >= 0 then GVozes[AntigaSom].Ativa := False;
    until AntigaSom < 0;

    { voz livre; se nao houver, rouba a mais antiga de todas }
    Livre := -1;
    Antiga := 0;
    for V := 0 to MaxVozes - 1 do
    begin
      if (Livre < 0) and (not GVozes[V].Ativa) then Livre := V;
      if Integer(GVozes[V].Seq - GVozes[Antiga].Seq) < 0 then Antiga := V;
    end;
    if Livre < 0 then Livre := Antiga;

    Inc(GSeq);
    with GVozes[Livre] do
    begin
      Dono := Pointer(A);
      Dados := A.FDados;
      Quadros := A.FQuadros;
      Pos := 0;
      Loop := FLoop;
      Seq := GSeq;
      Ativa := True;
    end;
  finally
    Destravar;
  end;
end;

procedure TBancoSom.Parar(Indice: Integer);
var
  A: TAmostra;
begin
  A := Obter(Indice);
  if A <> nil then CortarVozes(A);
end;

initialization

finalization
  if GDev <> 0 then
  begin
    if SDL_WasInit(SDL_INIT_AUDIO) <> 0 then SDL_CloseAudioDevice(GDev);
    GDev := 0;
  end;

end.
