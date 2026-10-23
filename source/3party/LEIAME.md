# source/3party

Bibliotecas de terceiros.

- `SDL2/` - SDL2-for-Pascal (https://github.com/PascalGameDevelopment/SDL2-for-Pascal). O jogo usa `sdl2.pas`
  (e os `.inc` que ele inclui); a ligacao e estatica com `SDL2.dll` (na raiz do projeto, versao 2.28 ou mais nova).
  As units `sdl2_gfx`, `sdl2_image`, `sdl2_mixer`, `sdl2_net` e `sdl2_ttf` vieram junto com a biblioteca e nao sao usadas.

Ja esta no caminho de busca de units do projeto (`StreetChaves.lpi`).
