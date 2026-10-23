program StreetChaves;

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Interfaces, Forms, SysUtils, ChavesJogo, ChavesConst, ChavesTipos, ChavesTextos, ChavesSDL;

{$R *.res}

begin
  ExecutarModoSDL;                      // jogo em SDL2 (--demo = quadro de teste da infraestrutura)
end.
