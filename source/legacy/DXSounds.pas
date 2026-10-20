unit DXSounds;

{ Camada de compatibilidade DelphiX -> Lazarus: som, sem componentes de terceiros.

  Nomes mantidos: TDXSound, TDXWaveList, TWave, TWaveCollection, TWaveCollectionItem.
  Backend atual (Windows): MCI (mciSendString) via unit MMSystem, que ja vem com o FPC.
    - cada Play abre um alias MCI novo (permite sons sobrepostos ate MaxPlayingCount);
    - aliases terminados sao fechados por um TTimer de limpeza;
    - Looped (musica) reabre ao terminar.
  Em outras plataformas os metodos existem mas nao tocam nada (ponto de extensao futuro:
  trocar o bloco IFDEF WINDOWS por OpenAL/SDL/miniaudio). }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, DXClass
  {$IFDEF WINDOWS}, Windows, MMSystem{$ENDIF};

type
  TDXSoundOption = (soGlobalFocus, soStandardMixing, soHardware, soStickyFocus);
  TDXSoundOptions = set of TDXSoundOption;

  TWave = class(TPersistent)
  private
    FFileName: string;      // arquivo no disco (original ou temporario)
    FTempFile: Boolean;
    function GetEmpty: Boolean;
  public
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure Assign(Source: TPersistent); override;
    property FileName: string read FFileName;
    property Empty: Boolean read GetEmpty;
  end;

  TCustomDXSound = class;

  TWaveCollectionItem = class(THashCollectionItem)
  private
    FWave: TWave;
    FFileName: string;
    FLooped: Boolean;
    FMaxPlayingCount: Integer;
    FAliases: TStringList;
    FSeq: Integer;
    procedure SetFileName(const Value: string);
    function Owner_: TCustomDXSound;
    procedure Cleanup;
    procedure CloseAll;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Restore;
    procedure Play(Wait: Boolean = False);
    procedure Stop;
    function Playing: Boolean;
    property Wave: TWave read FWave;
  published
    property FileName: string read FFileName write SetFileName;   // extra (nao existe no DelphiX)
    property Looped: Boolean read FLooped write FLooped default False;
    property MaxPlayingCount: Integer read FMaxPlayingCount write FMaxPlayingCount default 1;
  end;

  TWaveCollection = class(THashCollection)
  private
    FOwnerList: TComponent;
    function GetItem(Index: Integer): TWaveCollectionItem;
  public
    constructor Create(AOwner: TComponent);
    function Add: TWaveCollectionItem;
    function Find(const Name: string): TWaveCollectionItem;
    procedure Restore;
    procedure StopAll;
    procedure CleanupAll;
    property Items[Index: Integer]: TWaveCollectionItem read GetItem; default;
  end;

  TCustomDXWaveList = class(TComponent)
  private
    FDXSound: TCustomDXSound;
    FItems: TWaveCollection;
    FTimer: TTimer;
    procedure SetDXSound(Value: TCustomDXSound);
    procedure SetItems(Value: TWaveCollection);
    procedure DoCleanup(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Restore;
    procedure Start;   // para listas criadas em codigo (em .lfm o Loaded ja chama)
    property DXSound: TCustomDXSound read FDXSound write SetDXSound;
    property Items: TWaveCollection read FItems write SetItems;
  end;

  TDXWaveList = class(TCustomDXWaveList)
  published
    property DXSound;
    property Items;
  end;

  TCustomDXSound = class(TComponent)
  private
    FAutoInitialize: Boolean;
    FInitialized: Boolean;
    FOptions: TDXSoundOptions;
    FOnInitialize, FOnFinalize: TNotifyEvent;
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize;
    procedure Finalize;
    property Initialized: Boolean read FInitialized;
    property AutoInitialize: Boolean read FAutoInitialize write FAutoInitialize default True;
    property Options: TDXSoundOptions read FOptions write FOptions;
    property OnInitialize: TNotifyEvent read FOnInitialize write FOnInitialize;
    property OnFinalize: TNotifyEvent read FOnFinalize write FOnFinalize;
  end;

  TDXSound = class(TCustomDXSound)
  published
    property AutoInitialize;
    property Options;
    property OnInitialize;
    property OnFinalize;
  end;

implementation

{$IFDEF WINDOWS}
function MciCmd(const Cmd: string): string;
var
  Buf: array[0..255] of AnsiChar;
begin
  Buf[0] := #0;
  if mciSendStringA(PAnsiChar(AnsiString(Cmd)), @Buf[0], SizeOf(Buf), 0) = 0 then
    Result := string(PAnsiChar(@Buf[0]))
  else
    Result := '';
end;

function MciOk(const Cmd: string): Boolean;
begin
  Result := mciSendStringA(PAnsiChar(AnsiString(Cmd)), nil, 0, 0) = 0;
end;
{$ENDIF}

var
  GTempCounter: Integer = 0;

{ TWave }

destructor TWave.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TWave.Clear;
begin
  if FTempFile and (FFileName <> '') then SysUtils.DeleteFile(FFileName);
  FFileName := '';
  FTempFile := False;
end;

function TWave.GetEmpty: Boolean;
begin
  Result := FFileName = '';
end;

procedure TWave.LoadFromFile(const AFileName: string);
begin
  Clear;
  if FileExists(DXResolvePath(AFileName)) then FFileName := ExpandFileName(DXResolvePath(AFileName));
end;

procedure TWave.LoadFromStream(Stream: TStream);
var
  F: TFileStream;
  Name: string;
begin
  Clear;
  Inc(GTempCounter);
  Name := IncludeTrailingPathDelimiter(GetTempDir) + Format('dxs_%d_%d.wav', [GetProcessID, GTempCounter]);
  F := TFileStream.Create(Name, fmCreate);
  try
    F.CopyFrom(Stream, Stream.Size - Stream.Position);
  finally
    F.Free;
  end;
  FFileName := Name;
  FTempFile := True;
end;

procedure TWave.Assign(Source: TPersistent);
begin
  if Source is TWave then
    LoadFromFile(TWave(Source).FFileName)
  else
    inherited Assign(Source);
end;

{ TWaveCollectionItem }

constructor TWaveCollectionItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FWave := TWave.Create;
  FAliases := TStringList.Create;
  FMaxPlayingCount := 1;
end;

destructor TWaveCollectionItem.Destroy;
begin
  CloseAll;
  FAliases.Free;
  FWave.Free;
  inherited Destroy;
end;

function TWaveCollectionItem.Owner_: TCustomDXSound;
begin
  Result := nil;
end;

procedure TWaveCollectionItem.SetFileName(const Value: string);
begin
  FFileName := Value;
  if Value <> '' then FWave.LoadFromFile(Value);   // se nao achar agora, Restore tenta de novo no Play
end;

procedure TWaveCollectionItem.Restore;
begin
  if (FFileName <> '') and FWave.Empty then FWave.LoadFromFile(FFileName);
end;

procedure TWaveCollectionItem.CloseAll;
{$IFDEF WINDOWS}
var
  I: Integer;
begin
  for I := 0 to FAliases.Count - 1 do
  begin
    MciOk('stop ' + FAliases[I]);
    MciOk('close ' + FAliases[I]);
  end;
  FAliases.Clear;
end;
{$ELSE}
begin
  FAliases.Clear;
end;
{$ENDIF}

procedure TWaveCollectionItem.Cleanup;
{$IFDEF WINDOWS}
var
  I: Integer;
  St: string;
begin
  for I := FAliases.Count - 1 downto 0 do
  begin
    St := MciCmd('status ' + FAliases[I] + ' mode');
    if SameText(St, 'playing') then Continue;
    if FLooped and SameText(St, 'stopped') and (FAliases.Count = 1) then
    begin
      MciOk('play ' + FAliases[I] + ' from 0');       // reinicia a musica
      Continue;
    end;
    MciOk('close ' + FAliases[I]);
    FAliases.Delete(I);
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

function TWaveCollectionItem.Playing: Boolean;
begin
  Cleanup;
  Result := FAliases.Count > 0;
end;

procedure TWaveCollectionItem.Play(Wait: Boolean);
{$IFDEF WINDOWS}
var
  Alias: string;
begin
  Restore;
  if FWave.Empty then Exit;
  Cleanup;
  if FMaxPlayingCount < 1 then FMaxPlayingCount := 1;
  while FAliases.Count >= FMaxPlayingCount do
  begin
    MciOk('stop ' + FAliases[0]);
    MciOk('close ' + FAliases[0]);
    FAliases.Delete(0);
  end;
  Inc(FSeq);
  Alias := 'dxs' + IntToStr(PtrUInt(Self) and $FFFFFF) + '_' + IntToStr(FSeq);
  if not MciOk('open "' + FWave.FileName + '" type waveaudio alias ' + Alias) then
    if not MciOk('open "' + FWave.FileName + '" alias ' + Alias) then Exit;
  FAliases.Add(Alias);
  if Wait then MciOk('play ' + Alias + ' wait')
  else MciOk('play ' + Alias);
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TWaveCollectionItem.Stop;
begin
  CloseAll;
end;

{ TWaveCollection }

constructor TWaveCollection.Create(AOwner: TComponent);
begin
  inherited Create(TWaveCollectionItem);
  FOwnerList := AOwner;
end;

function TWaveCollection.GetItem(Index: Integer): TWaveCollectionItem;
begin
  Result := TWaveCollectionItem(inherited Items[Index]);
end;

function TWaveCollection.Add: TWaveCollectionItem;
begin
  Result := TWaveCollectionItem(inherited Add);
end;

function TWaveCollection.Find(const Name: string): TWaveCollectionItem;
begin
  Result := TWaveCollectionItem(inherited Find(Name));
end;

procedure TWaveCollection.Restore;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do GetItem(I).Restore;
end;

procedure TWaveCollection.StopAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do GetItem(I).Stop;
end;

procedure TWaveCollection.CleanupAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do GetItem(I).Cleanup;
end;

{ TCustomDXWaveList }

constructor TCustomDXWaveList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TWaveCollection.Create(Self);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 200;
  FTimer.OnTimer := DoCleanup;
end;

destructor TCustomDXWaveList.Destroy;
begin
  FTimer.Enabled := False;
  FItems.StopAll;
  FItems.Free;
  inherited Destroy;
end;

procedure TCustomDXWaveList.Start;
begin
  FTimer.Enabled := True;
end;

procedure TCustomDXWaveList.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) then FTimer.Enabled := True;
end;

procedure TCustomDXWaveList.DoCleanup(Sender: TObject);
begin
  FItems.CleanupAll;
end;

procedure TCustomDXWaveList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDXSound) then FDXSound := nil;
end;

procedure TCustomDXWaveList.SetDXSound(Value: TCustomDXSound);
begin
  if FDXSound = Value then Exit;
  FDXSound := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;

procedure TCustomDXWaveList.SetItems(Value: TWaveCollection);
begin
  FItems.Assign(Value);
end;

procedure TCustomDXWaveList.Restore;
begin
  FItems.Restore;
end;

{ TCustomDXSound }

constructor TCustomDXSound.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoInitialize := True;
end;

destructor TCustomDXSound.Destroy;
begin
  Finalize;
  inherited Destroy;
end;

procedure TCustomDXSound.Loaded;
begin
  inherited Loaded;
  if FAutoInitialize and not (csDesigning in ComponentState) then Initialize;
end;

procedure TCustomDXSound.Initialize;
begin
  if FInitialized then Exit;
  FInitialized := True;
  if Assigned(FOnInitialize) then FOnInitialize(Self);
end;

procedure TCustomDXSound.Finalize;
begin
  if not FInitialized then Exit;
  if Assigned(FOnFinalize) then FOnFinalize(Self);
  FInitialized := False;
end;

initialization
  RegisterClasses([TDXSound, TDXWaveList]);

end.
