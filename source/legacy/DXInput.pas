unit DXInput;

{ Camada de compatibilidade DelphiX -> Lazarus: entrada.

  O jogo original usa apenas:
    DXInput1.Update;
    DXInput1.Keyboard.States   (set de TDXInputState; bits 0..7 = Up, Down, Left, Right, Button1..4)
    DXInput1.Joystick.States   (idem; aqui sempre vazio: joystick sera tratado no futuro)
    DXInput1.Keyboard.KeyAssigns[...]  (leitura das teclas configuradas)

  Mapeamento padrao, decodificado do DFM original (Keyboard.Assigns):
    Up=VK_UP  Down=VK_DOWN  Left=VK_LEFT  Right=VK_RIGHT
    Button1='Z'  Button2='X'  Button3='C'  Button4='V'

  Enquanto nao houver suporte real a joystick, TDXInput.Joystick.States fica vazio
  e o teclado "engana" o jogo. Para ligar um joystick no futuro, basta preencher
  Joystick.States em TJoystick.Poll. }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LCLIntf, Forms, DXClass;

{ Estado do teclado independente de plataforma: o formulario alimenta a tabela com
  DXKeyDown/DXKeyUp (eventos OnKeyDown/OnKeyUp) e DXKeyReset ao perder o foco.
  Substitui GetKeyState (so Windows). Codigos = VK_* do LCL. }
procedure DXKeyDown(Key: Word);
procedure DXKeyUp(Key: Word);
procedure DXKeyReset;
function DXKeyIsDown(Key: Integer): Boolean;

type
  TDXInputState = (isUp, isDown, isLeft, isRight,
    isButton1, isButton2, isButton3, isButton4, isButton5, isButton6, isButton7, isButton8,
    isButton9, isButton10, isButton11, isButton12, isButton13, isButton14, isButton15, isButton16,
    isButton17, isButton18, isButton19, isButton20, isButton21, isButton22, isButton23, isButton24,
    isButton25, isButton26, isButton27, isButton28, isButton29, isButton30, isButton31, isButton32);
  TDXInputStates = set of TDXInputState;

  { No DelphiX original cada atribuicao ocupa 12 bytes; o jogo usa apenas o primeiro inteiro (codigo VK). }
  TKeyAssign = record
    Key: Integer;
    Reserved1: Integer;
    Reserved2: Integer;
  end;
  TKeyAssigns = array[TDXInputState] of TKeyAssign;

  TDXInput = class;

  { TCustomInput: base de Joystick/Keyboard/Mouse }
  TCustomInput = class(TPersistent)
  private
    FOwner: TDXInput;
    FStates: TDXInputStates;
    FEnabled: Boolean;
    FBindInputStates: Boolean;
    FForceFeedback: Boolean;
  public
    constructor Create(AOwner: TDXInput); virtual;
    procedure Poll; virtual;
    property States: TDXInputStates read FStates;
  published
    property BindInputStates: Boolean read FBindInputStates write FBindInputStates default True;
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property ForceFeedback: Boolean read FForceFeedback write FForceFeedback default False;
  end;

  TJoystick = class(TCustomInput)
  private
    FEmulateByKeyboard: Boolean;
    FKeyMap: TKeyAssigns;
    FAutoCenter: Boolean;
    FDeadZoneX, FDeadZoneY, FDeadZoneZ: Integer;
    FID: Integer;
    FRangeX, FRangeY, FRangeZ: Integer;
  public
    constructor Create(AOwner: TDXInput); override;
    procedure Poll; override;   // sem joystick real ainda: usa o teclado (EmulateByKeyboard)
    { Teclas que "enganam" o joystick (jogador 2). Padrao: W S A D + R T Y U (G e P sao teclas de pausa do jogo). }
    property KeyMap: TKeyAssigns read FKeyMap write FKeyMap;
    property EmulateByKeyboard: Boolean read FEmulateByKeyboard write FEmulateByKeyboard;
  published
    property AutoCenter: Boolean read FAutoCenter write FAutoCenter default True;
    property DeadZoneX: Integer read FDeadZoneX write FDeadZoneX default 50;
    property DeadZoneY: Integer read FDeadZoneY write FDeadZoneY default 50;
    property DeadZoneZ: Integer read FDeadZoneZ write FDeadZoneZ default 50;
    property ID: Integer read FID write FID default 0;
    property RangeX: Integer read FRangeX write FRangeX default 1000;
    property RangeY: Integer read FRangeY write FRangeY default 1000;
    property RangeZ: Integer read FRangeZ write FRangeZ default 1000;
  end;

  TKeyboard = class(TCustomInput)
  private
    FKeyAssigns: TKeyAssigns;
  public
    constructor Create(AOwner: TDXInput); override;
    procedure Poll; override;
    procedure SetKey(S: TDXInputState; Key: Integer);
    function GetKey(S: TDXInputState): Integer;
    property KeyAssigns: TKeyAssigns read FKeyAssigns write FKeyAssigns;
  end;

  TMouse = class(TCustomInput)
  public
    constructor Create(AOwner: TDXInput); override;
  end;

  { TDXInput }
  TDXInput = class(TComponent)
  private
    FActiveOnly: Boolean;
    FUseDirectInput: Boolean;
    FJoystick: TJoystick;
    FKeyboard: TKeyboard;
    FMouse: TMouse;
    FStates: TDXInputStates;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Update;
    property States: TDXInputStates read FStates;
  published
    property ActiveOnly: Boolean read FActiveOnly write FActiveOnly default True;
    property Joystick: TJoystick read FJoystick write FJoystick;
    property Keyboard: TKeyboard read FKeyboard write FKeyboard;
    property Mouse: TMouse read FMouse write FMouse;
    property UseDirectInput: Boolean read FUseDirectInput write FUseDirectInput default True;
  end;

implementation

var
  GKeys: array[0..255] of Boolean;

procedure DXKeyDown(Key: Word);
begin
  if Key <= 255 then GKeys[Key] := True;
end;

procedure DXKeyUp(Key: Word);
begin
  if Key <= 255 then GKeys[Key] := False;
end;

procedure DXKeyReset;
begin
  FillChar(GKeys, SizeOf(GKeys), 0);
end;

function DXKeyIsDown(Key: Integer): Boolean;
begin
  Result := (Key >= 0) and (Key <= 255) and GKeys[Key];
end;

{ TCustomInput }

constructor TCustomInput.Create(AOwner: TDXInput);
begin
  inherited Create;
  FOwner := AOwner;
  FEnabled := True;
  FBindInputStates := True;
  FForceFeedback := False;
  FStates := [];
end;

procedure TCustomInput.Poll;
begin
  FStates := [];
end;

{ TJoystick }

constructor TJoystick.Create(AOwner: TDXInput);
begin
  inherited Create(AOwner);
  FAutoCenter := True;
  FDeadZoneX := 50; FDeadZoneY := 50; FDeadZoneZ := 50;
  FRangeX := 1000; FRangeY := 1000; FRangeZ := 1000;
  FEmulateByKeyboard := True;
  FillChar(FKeyMap, SizeOf(FKeyMap), 0);
  FKeyMap[isUp].Key := Ord('W');
  FKeyMap[isDown].Key := Ord('S');
  FKeyMap[isLeft].Key := Ord('A');
  FKeyMap[isRight].Key := Ord('D');
  FKeyMap[isButton1].Key := Ord('R');
  FKeyMap[isButton2].Key := Ord('T');
  FKeyMap[isButton3].Key := Ord('Y');
  FKeyMap[isButton4].Key := Ord('U');
end;

procedure TJoystick.Poll;
var
  S: TDXInputState;
  K: Integer;
begin
  FStates := [];
  if (not FEnabled) or (not FEmulateByKeyboard) then Exit;
  for S := Low(TDXInputState) to High(TDXInputState) do
  begin
    K := FKeyMap[S].Key;
    if K = 0 then Continue;
    if DXKeyIsDown(K) then Include(FStates, S);
  end;
end;

{ TKeyboard }

constructor TKeyboard.Create(AOwner: TDXInput);
begin
  inherited Create(AOwner);
  FillChar(FKeyAssigns, SizeOf(FKeyAssigns), 0);
  FKeyAssigns[isUp].Key := VK_UP;
  FKeyAssigns[isDown].Key := VK_DOWN;
  FKeyAssigns[isLeft].Key := VK_LEFT;
  FKeyAssigns[isRight].Key := VK_RIGHT;
  FKeyAssigns[isButton1].Key := Ord('Z');
  FKeyAssigns[isButton2].Key := Ord('X');
  FKeyAssigns[isButton3].Key := Ord('C');
  FKeyAssigns[isButton4].Key := Ord('V');
end;

procedure TKeyboard.Poll;
var
  S: TDXInputState;
  K: Integer;
begin
  FStates := [];
  if not FEnabled then Exit;
  for S := Low(TDXInputState) to High(TDXInputState) do
  begin
    K := FKeyAssigns[S].Key;
    if K = 0 then Continue;
    if DXKeyIsDown(K) then Include(FStates, S);   // bit alto = tecla pressionada
  end;
end;

procedure TKeyboard.SetKey(S: TDXInputState; Key: Integer);
begin
  FKeyAssigns[S].Key := Key;
end;

function TKeyboard.GetKey(S: TDXInputState): Integer;
begin
  Result := FKeyAssigns[S].Key;
end;

{ TMouse }

constructor TMouse.Create(AOwner: TDXInput);
begin
  inherited Create(AOwner);
  FEnabled := False;
  FBindInputStates := False;
end;

{ TDXInput }

constructor TDXInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActiveOnly := True;
  FUseDirectInput := True;
  FJoystick := TJoystick.Create(Self);
  FKeyboard := TKeyboard.Create(Self);
  FMouse := TMouse.Create(Self);
end;

destructor TDXInput.Destroy;
begin
  FJoystick.Free;
  FKeyboard.Free;
  FMouse.Free;
  inherited Destroy;
end;

procedure TDXInput.Update;
begin
  if FActiveOnly and (not Application.Active) then
  begin
    FJoystick.FStates := [];
    FKeyboard.FStates := [];
    FMouse.FStates := [];
    FStates := [];
    Exit;
  end;
  FJoystick.Poll;
  FKeyboard.Poll;
  FMouse.Poll;
  FStates := [];
  if FJoystick.BindInputStates then FStates := FStates + FJoystick.States;
  if FKeyboard.BindInputStates then FStates := FStates + FKeyboard.States;
  if FMouse.BindInputStates then FStates := FStates + FMouse.States;
end;

end.
