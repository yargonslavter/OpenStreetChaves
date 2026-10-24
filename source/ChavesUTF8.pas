unit ChavesUTF8;

{ ChavesUTF8.pas - strings do jogo em UTF-8 em todas as plataformas.

  Antes isso vinha de graca com a LCL (a unit Interfaces liga o UTF-8 como codigo de pagina
  padrao). Sem a LCL, esta unit faz o mesmo e precisa ser a primeira do programa (depois das
  units de threads/strings do sistema). Textos, nomes de arquivo e o atlas de fonte continuam
  tratados como UTF-8, igual a antes. }

{$mode delphi}{$H+}

interface

implementation

initialization
  SetMultiByteConversionCodePage(CP_UTF8);
  SetMultiByteRTLFileSystemCodePage(CP_UTF8);

end.
