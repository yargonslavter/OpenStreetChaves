unit DXClass;

{ Camada de compatibilidade DelphiX -> Lazarus (LCL), sem componentes de terceiros.
  Esta unit mantem os nomes originais do DelphiX usados pelo Street Chaves:
    TDXTimer, TDXTimerEvent, THashCollection, THashCollectionItem.

  TDXTimer: no jogo original o evento OnTimer ignora LagCount e o intervalo
  (Interval) e reajustado a cada quadro (padrao 28 ms). Aqui o disparo usa um
  relogio de alta resolucao e compensa o atraso, para a velocidade media ficar
  correta mesmo com a resolucao baixa do TTimer do Windows. }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms
  {$IFDEF WINDOWS}, Windows, MMSystem{$ENDIF};

type
  TDXTimerEvent = procedure(Sender: TObject; LagCount: Integer) of object;

  { TDXTimer }
  TDXTimer = class(TComponent)
  private
    FRunning: Boolean;
    FFired: Boolean;
    FEnabled: Boolean;
    FActiveOnly: Boolean;
    FInterval: Integer;
    FOnTimer: TDXTimerEvent;
    FNextTick: Double;      // ms (relogio de alta resolucao)
    FInTick: Boolean;
    FPollCount: Integer;
    FReason: Integer;
    procedure SetEnabled(Value: Boolean);
    procedure SetInterval(Value: Integer);
    procedure Tick(Sender: TObject);
    procedure IdleHandler(Sender: TObject; var Done: Boolean);
    procedure Run(Value: Boolean);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PollCount: Integer read FPollCount write FPollCount;   // diagnostico
    property Reason: Integer read FReason;      // diagnostico: 1 desligado,2 em Tick,3 sem evento,4 inativo,5 cedo,6 disparou
    property NextTick: Double read FNextTick;   // diagnostico
    property Running: Boolean read FRunning;    // diagnostico
    procedure Start;   // para timers criados em codigo (em .lfm o Loaded ja chama)
  published
    property ActiveOnly: Boolean read FActiveOnly write FActiveOnly default True;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Interval: Integer read FInterval write SetInterval default 1000;
    property OnTimer: TDXTimerEvent read FOnTimer write FOnTimer;
  end;

  { THashCollectionItem / THashCollection: colecao com busca por nome }
  THashCollectionItem = class(TCollectionItem)
  private
    FName: string;
  protected
    function GetDisplayName: string; override;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Name: string read FName write FName;
  end;

  THashCollection = class(TCollection)
  public
    function IndexOf(const Name: string): Integer;
    function Find(const Name: string): THashCollectionItem;
  end;

{ Relogio de alta resolucao em milissegundos }
function DXHiResMs: Double;

{ Resolve um caminho relativo de recurso: tenta a pasta atual, depois sobe a partir da
  pasta do executavel (ate 8 niveis). Devolve o proprio nome se nao achar. }
function DXResolvePath(const AFileName: string): string;

implementation

var
  GFreq: Int64 = 0;

function DXHiResMs: Double;
{$IFDEF WINDOWS}
var
  C: Int64;
begin
  if GFreq = 0 then
  begin
    QueryPerformanceFrequency(GFreq);
    if GFreq = 0 then GFreq := 1000;
  end;
  QueryPerformanceCounter(C);
  // aritmetica inteira de 64 bits: evita perda de precisao (antes saltava de 256 em 256 ms)
  // atribuicao implicita Int64 -> Double (NAO usar Double(x): isso reinterpreta os bits)
  Result := (C div GFreq) * 1000 + ((C mod GFreq) * 1000) div GFreq;
end;
{$ELSE}
begin
  Result := GetTickCount64;
end;
{$ENDIF}

function DXResolvePath(const AFileName: string): string;
var
  Dir: string;
  I: Integer;
begin
  Result := AFileName;
  if AFileName = '' then Exit;
  if FileExists(AFileName) then Exit;
  if (ExtractFileDrive(AFileName) <> '') or (AFileName[1] in ['/', '\']) then Exit;
  Dir := ExtractFilePath(ParamStr(0));
  for I := 1 to 8 do
  begin
    if FileExists(Dir + AFileName) then
    begin
      Result := Dir + AFileName;
      Exit;
    end;
    Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
    if Dir = '' then Break;
  end;
end;

{ TDXTimer }

constructor TDXTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := True;
  FActiveOnly := True;
  FInterval := 1000;
end;

destructor TDXTimer.Destroy;
begin
  Run(False);
  inherited Destroy;
end;

{ Laco de jogo: roda quando a fila de mensagens esta vazia (Done := False impede o
  Application de ficar esperando mensagem). Mais preciso e rapido que TTimer, que no
  Windows e uma mensagem de baixa prioridade. }
procedure TDXTimer.Run(Value: Boolean);
begin
  if Value = FRunning then Exit;
  FRunning := Value;
  if Value then
  begin
    {$IFDEF WINDOWS}timeBeginPeriod(1);{$ENDIF}
    Application.AddOnIdleHandler(IdleHandler, False);
  end
  else
  begin
    Application.RemoveOnIdleHandler(IdleHandler);
    {$IFDEF WINDOWS}timeEndPeriod(1);{$ENDIF}
  end;
end;

procedure TDXTimer.IdleHandler(Sender: TObject; var Done: Boolean);
begin
  Done := False;
  FFired := False;
  Tick(Sender);
  if not FFired then Sleep(1);
end;

procedure TDXTimer.Start;
begin
  // em tempo de projeto nunca dispara
  if not (csDesigning in ComponentState) then
  begin
    FNextTick := DXHiResMs + FInterval;
    Run(FEnabled);
  end;
end;

procedure TDXTimer.Loaded;
begin
  inherited Loaded;
  Start;
end;

procedure TDXTimer.SetEnabled(Value: Boolean);
begin
  if FEnabled = Value then Exit;
  FEnabled := Value;
  if csLoading in ComponentState then Exit;
  if csDesigning in ComponentState then Exit;
  if Value then FNextTick := DXHiResMs + FInterval;
  Run(Value);
end;

procedure TDXTimer.SetInterval(Value: Integer);
begin
  if Value < 1 then Value := 1;
  FInterval := Value;
end;

procedure TDXTimer.Tick(Sender: TObject);
var
  Now_, Behind: Double;
  Lag: Integer;
begin
  Inc(FPollCount);
  FReason := 1;
  if not FEnabled then Exit;
  FReason := 2;
  if FInTick then Exit;
  FReason := 3;
  if not Assigned(FOnTimer) then Exit;
  FReason := 4;
  if FActiveOnly and (not Application.Active) then
  begin
    FNextTick := DXHiResMs + FInterval;   // nao acumula atraso enquanto inativo
    Exit;
  end;
  Now_ := DXHiResMs;
  FReason := 5;
  if Now_ < FNextTick then Exit;
  FReason := 6;
  Behind := Now_ - FNextTick;
  Lag := 1 + Trunc(Behind / FInterval);
  // compensa o atraso mas nunca tenta "recuperar" mais que alguns quadros
  FNextTick := FNextTick + FInterval;
  if Now_ - FNextTick > 4 * FInterval then FNextTick := Now_ + FInterval;
  FInTick := True;
  FFired := True;
  try
    FOnTimer(Self, Lag);
  finally
    FInTick := False;
  end;
end;

{ THashCollectionItem }

function THashCollectionItem.GetDisplayName: string;
begin
  Result := FName;
  if Result = '' then Result := inherited GetDisplayName;
end;

procedure THashCollectionItem.Assign(Source: TPersistent);
begin
  if Source is THashCollectionItem then
    FName := THashCollectionItem(Source).FName
  else
    inherited Assign(Source);
end;

{ THashCollection }

function THashCollection.IndexOf(const Name: string): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if SameText(THashCollectionItem(Items[I]).Name, Name) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

function THashCollection.Find(const Name: string): THashCollectionItem;
var
  I: Integer;
begin
  I := IndexOf(Name);
  if I >= 0 then Result := THashCollectionItem(Items[I]) else Result := nil;
end;

end.
