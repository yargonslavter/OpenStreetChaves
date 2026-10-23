unit DXClass;

{ Utilidades que sobraram da camada DelphiX: colecao com busca por nome (usada pelas listas de
  imagens do DXDraws) e resolucao de caminhos de recursos. }

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
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

{ Resolve um caminho relativo de recurso: tenta a pasta atual, depois sobe a partir da
  pasta do executavel (ate 8 niveis). Devolve o proprio nome se nao achar. }
function DXResolvePath(const AFileName: string): string;

implementation

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
