unit utestmain;

{ Teste da camada DelphiX: tudo criado em codigo (sem .lfm).
  Mostra: fundo com barra/retangulo/elipse/texto, sprite do Embutidos, alpha/add/sub,
  rotacao, estado do teclado (setas, Z X C V) e FPS. Tecla S = som de teste (se existir
  ..\Embutidos\teste.wav). }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Forms, Controls, Graphics, Dialogs,
  DXClass, DXInput, DXDraws, DXSounds;

type
  TFormTest = class(TForm)
  private
    DXDraw1: TDXDraw;
    DXImageList1: TDXImageList;
    DXTimer1: TDXTimer;
    DXInput1: TDXInput;
    DXSound1: TDXSound;
    DXWaveList1: TDXWaveList;
    FAngle: Integer;
    FFrames: Integer;
    FFps: Integer;
    FLastSec: Double;
    FX, FY: Integer;
    FDir: string;
    FPrevTick: QWord;
    FPrevHi: Double;
    FDtTick: QWord;
    FDtHi: Double;
    FPolls: Integer;
    FLog: TextFile;
    FDiag: TTimer;
    FDiagN: Integer;
    FLogOpen: Boolean;
    FTickN: Integer;
    FT0, FTDraw, FTFlip: Double;
    procedure Tick(Sender: TObject; LagCount: Integer);
    procedure TickBody(LagCount: Integer);
    procedure LogMsg(const S: string);
    procedure DiagTick(Sender: TObject);
    procedure KeyDownEv(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Txt(X, Y: Integer; const S: string; C: TColor);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FormTest: TFormTest;

implementation

constructor TFormTest.Create(AOwner: TComponent);
var
  Dir: string;
  It: TPictureCollectionItem;
  Wv: TWaveCollectionItem;
  It_: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := 'ShimTest - DelphiX shim';
  Position := poScreenCenter;
  BorderStyle := bsSingle;
  KeyPreview := True;
  OnKeyDown := KeyDownEv;

  DXDraw1 := TDXDraw.Create(Self);
  DXDraw1.Parent := Self;
  DXDraw1.SurfaceWidth := 400;
  DXDraw1.SurfaceHeight := 300;
  DXDraw1.SetBounds(0, 0, 800, 600);   // escala 2x
  ClientWidth := 800;
  ClientHeight := 600;

  DXInput1 := TDXInput.Create(Self);
  DXSound1 := TDXSound.Create(Self);
  DXWaveList1 := TDXWaveList.Create(Self);
  DXWaveList1.DXSound := DXSound1;
  DXImageList1 := TDXImageList.Create(Self);
  DXImageList1.DXDraw := DXDraw1;

  // procura a pasta Embutidos subindo a partir da pasta do exe
  Dir := ExtractFilePath(ParamStr(0));
  for It_ := 1 to 6 do
  begin
    if DirectoryExists(Dir + 'Embutidos') then Break;
    Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
  end;
  Dir := Dir + 'Embutidos' + PathDelim;
  FDir := Dir;
  try
    AssignFile(FLog, ExtractFilePath(ExcludeTrailingPathDelimiter(Dir)) + 'shimtest.log');
    Rewrite(FLog);
    FLogOpen := True;
    WriteLn(FLog, 'n;tickcount_ms;hires_ms;dt_sys;dt_hi;draw_ms;flip_ms;paint_ms;polls');
    Flush(FLog);
  except
    FLogOpen := False;
  end;
  It := DXImageList1.Items.Add;
  It.Name := 'Chaves';
  It.FileName := Dir + 'DXImageListAbertura__08_Chaves.bmp';
  It.TransparentColor := clWhite;
  It := DXImageList1.Items.Add;
  It.Name := 'Madruga';
  It.FileName := Dir + 'DXImageListAbertura__09_Seu_Madruga.bmp';

  Wv := DXWaveList1.Items.Add;
  Wv.Name := 'Teste';
  Wv.FileName := Dir + 'teste.wav';

  DXDraw1.Initialize;
  DXSound1.Initialize;

  DXTimer1 := TDXTimer.Create(Self);
  DXTimer1.Interval := 28;
  DXTimer1.OnTimer := Tick;
  DXTimer1.Enabled := True;
  DXTimer1.Start;       // criado em codigo (sem .lfm)
  FDiag := TTimer.Create(Self);
  FDiag.Interval := 500;
  FDiag.OnTimer := DiagTick;
  FX := 150; FY := 120;
  FLastSec := DXHiResMs;
end;

procedure TFormTest.KeyDownEv(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  W: TWaveCollectionItem;
begin
  if Key = Ord('S') then
  begin
    W := DXWaveList1.Items.Find('Teste');
    if W <> nil then W.Play;
  end;
end;

procedure TFormTest.Txt(X, Y: Integer; const S: string; C: TColor);
begin
  with DXDraw1.Surface.Canvas do
  begin
    Brush.Style := bsClear;
    Font.Name := 'Comic Sans MS';
    Font.Size := 10;
    Font.Color := clBlack;
    TextOut(X + 1, Y + 1, S);
    Font.Color := C;
    TextOut(X, Y, S);
    Release;
  end;
end;

procedure TFormTest.DiagTick(Sender: TObject);
begin
  Inc(FDiagN);
  LogMsg(Format('diag %d: polls=%d reason=%d running=%s enabled=%s hires=%.0f next=%.0f appActive=%s',
    [FDiagN, DXTimer1.PollCount, DXTimer1.Reason, BoolToStr(DXTimer1.Running, True),
     BoolToStr(DXTimer1.Enabled, True), DXHiResMs, DXTimer1.NextTick, BoolToStr(Application.Active, True)]));
  if FDiagN >= 12 then FDiag.Enabled := False;
end;

procedure TFormTest.LogMsg(const S: string);
begin
  if FLogOpen then
  begin
    WriteLn(FLog, '# ' + S);
    Flush(FLog);
  end;
end;

procedure TFormTest.Tick(Sender: TObject; LagCount: Integer);
begin
  if FTickN = 0 then LogMsg('primeiro Tick, lag=' + IntToStr(LagCount));
  try
    TickBody(LagCount);
  except
    on E: Exception do
    begin
      LogMsg('EXCECAO: ' + E.ClassName + ': ' + E.Message);
      DXTimer1.Enabled := False;
    end;
  end;
end;

procedure TFormTest.TickBody(LagCount: Integer);
var
  S: TDXInputStates;
  Surf: TDirectDrawSurface;
  Img: TPictureCollectionItem;
  Mad: TPictureCollectionItem;
  St: string;
  I: Integer;
  N: Double;
begin
  FDtTick := GetTickCount64 - FPrevTick; FPrevTick := GetTickCount64;
  FDtHi := DXHiResMs - FPrevHi; FPrevHi := DXHiResMs;
  FT0 := DXHiResMs;
  Surf := DXDraw1.Surface;
  DXInput1.Update;
  S := DXInput1.Keyboard.States;
  if isLeft in S then Dec(FX, 3);
  if isRight in S then Inc(FX, 3);
  if isUp in S then Dec(FY, 3);
  if isDown in S then Inc(FY, 3);
  FAngle := (FAngle + 2) and 255;

  // fundo
  with Surf.Canvas do
  begin
    Brush.Color := clBlack;
    FillRect(Rect(0, 0, 400, 300));
    Brush.Color := RGBToColor(30, 60, 120);
    FillRect(Rect(10, 30, 390, 290));
    Brush.Color := clYellow;
    FrameRect(Rect(10, 30, 390, 290));
    Pen.Color := clWhite;
    Brush.Color := clRed;
    Brush.Style := bsSolid;
    RoundRect(20, 40, 120, 80, 12, 12);
    Pen.Color := clLime;
    Brush.Color := clGreen;
    Ellipse(130, 40, 200, 80);
    Release;
  end;

  Img := DXImageList1.Items.Find('Chaves');
  Mad := DXImageList1.Items.Find('Madruga');
  if Img <> nil then
  begin
    Img.Draw(Surf, FX, FY, 0);                                         // normal, com transparencia
    Img.DrawAlpha(Surf, Rect(220, 50, 220 + Img.Width, 50 + Img.Height), 0, 128);   // alpha 50%
    Img.DrawAdd(Surf, Rect(220, 160, 220 + Img.Width, 160 + Img.Height), 0, 200);    // aditivo
    Img.DrawRotate(Surf, 300, 160, Img.Width, Img.Height, 0, 0.5, 0.5, FAngle);       // rotacao
    Img.StretchDraw(Surf, Rect(20, 200, 20 + Img.Width div 2, 200 + Img.Height div 2), 0);  // reduzido
  end;
  if Mad <> nil then Mad.Draw(Surf, 330, 50, 0);

  St := 'Teclas:';
  if isUp in S then St := St + ' CIMA';
  if isDown in S then St := St + ' BAIXO';
  if isLeft in S then St := St + ' ESQ';
  if isRight in S then St := St + ' DIR';
  for I := 0 to 3 do
    if TDXInputState(Ord(isButton1) + I) in S then St := St + ' B' + IntToStr(I + 1);
  Txt(10, 4, St, clWhite);
  Txt(200, 4, Format('FPS: %d  lag: %d  (S = som)', [FFps, LagCount]), clAqua);
  Txt(200, 280, 'Texto centrado', clYellow);
  if Img <> nil then
    Txt(10, 250, Format('Chaves: %dx%d pat=%d existe=%s', [Img.Surface.Width, Img.Surface.Height,
      Img.PatternCount, BoolToStr(FileExists(Img.FileName), True)]), clWhite)
  else
    Txt(10, 250, 'Chaves: item nao encontrado', clRed);
  Txt(10, 265, 'Dir: ' + FDir, clWhite);
  FTDraw := DXHiResMs - FT0;

  Inc(FFrames);
  N := DXHiResMs;
  if N - FLastSec >= 1000 then
  begin
    FFps := FFrames;
    FFrames := 0;
    FLastSec := N;
  end;

  Txt(10, 220, Format('dt: sistema %d ms, hires %.1f ms, polls %d', [FDtTick, FDtHi, DXTimer1.PollCount]), clYellow);
  Txt(10, 235, Format('desenho %.0f ms  flip %.0f ms paint %.1f ms', [FTDraw, FTFlip, DXDraw1.LastPaintMs]), clLime);
  FT0 := DXHiResMs;
  DXDraw1.Flip;
  FTFlip := DXHiResMs - FT0;
  Inc(FTickN);
  if FLogOpen then
  begin
    WriteLn(FLog, Format('%d;%d;%.2f;%d;%.2f;%.2f;%.2f;%.2f;%d', [FTickN, GetTickCount64, DXHiResMs,
      FDtTick, FDtHi, FTDraw, FTFlip, DXDraw1.LastPaintMs, DXTimer1.PollCount]));
    Flush(FLog);
    if FTickN >= 300 then begin CloseFile(FLog); FLogOpen := False; end;
  end;
end;

end.
