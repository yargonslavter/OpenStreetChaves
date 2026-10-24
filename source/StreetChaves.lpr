program StreetChaves;

{ Street Chaves - porte para Free Pascal + SDL2 (sem LCL). }

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$IFNDEF ANDROID} cwstring,{$ENDIF}{$ENDIF}
  ChavesUTF8, SysUtils, ChavesJogo, ChavesConst, ChavesTipos, ChavesTextos, ChavesSDL;

{$R *.res}

begin
  ExecutarModoSDL;                      // jogo em SDL2 (--demo = quadro de teste da infraestrutura)
end.
