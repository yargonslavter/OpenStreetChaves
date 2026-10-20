{ ChavesConst.pas - constantes compartilhadas: cores, alinhamentos de texto, limites do jogo.
  Cores sao TColor (formato $00BBGGRR do Lazarus). Cores calculadas em tempo de execucao
  (piscando, degrade) continuam usando RGB(...) no codigo. }

unit ChavesConst;

{$mode delphi}{$H+}

interface

uses
  Graphics;

const
  { ---- cores ---- }
  Branco = TColor($FFFFFF);          // branco puro: texto e molduras (255, 255, 255)
  Preto = TColor($000000);           // preto: fundos e cortinas (0, 0, 0)
  CinzaClaro = TColor($AAAAAA);      // moldura das barras (170, 170, 170)
  CinzaMedio = TColor($787878);      // opcoes desativadas (120, 120, 120)
  Vermelho = TColor($0000FF);        // flash de dano e barras (255, 0, 0)
  VermelhoAlerta = TColor($3232FF);  // ultimos segundos do relogio e caixas de ataque (255, 50, 50)
  Rosa = TColor($6464FF);            // destaques do menu (255, 100, 100)
  RosaClaro = TColor($8C8CFA);       // textos da tela de continuar (250, 140, 140)
  RosaPalido = TColor($B4B4FF);      // relogio piscando (255, 180, 180)
  AzulTitulo = TColor($FF5A5A);      // frases da abertura (90, 90, 255)
  AzulSelecao = TColor($FF8282);     // item selecionado nos menus (130, 130, 255)
  VerdeBonus = TColor($8CFF50);      // mensagens de bonus e textos flutuantes (80, 255, 140)
  VerdeAnuncio = TColor($B4FF96);    // anuncio do round (150, 255, 180)

  CorTransparente = Branco;         // cor que vira transparente nas imagens carregadas

  { ---- alinhamento de texto (usado por texto()) ---- }
  ACentro = 99;     // 'c'
  AEsq = 45;        // '-'
  ADir = 101;       // 'e'

  { ---- tela ---- }
  LarguraTela = 400;
  AlturaTela = 300;

  { ---- limites do jogo ---- }
  VidaMax = 125;        // energia cheia
  CargaMax = 102;       // carga cheia da barra do golpe especial
  MaxEfeitos = 80;      // vagas na tabela de efeitos (fagulhas, projeteis, textos...)

implementation

end.
