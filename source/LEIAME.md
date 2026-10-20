# Street Chaves - porte para Lazarus

Estrutura (raiz = pasta onde fica o antigo `Chaves.exe`; tudo do porte fica em `source/`):

- `source/StreetChaves.lpi / .lpr` - projeto do Lazarus 4.8 (FPC 3.2.2). O build gera `StreetChaves.exe`
  na raiz (ao lado do `Chaves.exe`); units compiladas ficam em `source/build/`.
- `source/ChavesPrj.pas / .lfm` - formulario principal (so componentes padrao; abre no designer).
- `source/Embutidos/` - BMPs/WAVs extraidos do `Chaves.exe` original.
- `Cenarios/ Lutadores/ Sons/ ...` - recursos originais do jogo.
- `source/game/` - logica do jogo (ChavesTipos, ChavesConst, ChavesTextos, ChavesGolpes, *.inc).
- `source/legacy/` - camada de compatibilidade DelphiX (DXClass, DXDraws, DXInput, DXSounds).
- `source/3party/` - bibliotecas de terceiros futuras (portabilidade).
- `source/tests/ShimTest/` - app de teste da camada DelphiX (`ShimTest.lpi`).

Os componentes DelphiX nao ficam no .lfm: sao criados em codigo por `source/game/ChavesDX.inc`.
Teclas: P1 = setas + Z X C V (configuravel em F2); P2 = W A S D + R T Y U.
