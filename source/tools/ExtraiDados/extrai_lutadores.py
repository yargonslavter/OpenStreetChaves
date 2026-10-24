#!/usr/bin/env python3
"""Extrai de source/game/ChavesGolpes.pas os dados fixos de cada lutador e grava em
Dados/Lutadores/Cnn.ini (um arquivo por personagem) as secoes abaixo; o que vem antes de
[CentroX] no arquivo ([Geral], [Golpes]) e mantido:

  [CentroX]  quadro=deslocamento X do centro do sprite      (funcao CentroX)
  [Corpo]    quadro=x1,y1,x2,y2                              (DefineCaixaCorpo em AtualizaQuadro)
  [Ataque]   acao.quadroAcao=x1,y1,x2,y2,ativo,forca,dano,danoDefesa
             acao.quadroAcao.fN = so quando ForcaGolpe = N   (DefineCaixaAtaque em AtualizaQuadro)

Os quadros sao os do jogador 1 (1..50); o jogo soma 50 para o jogador 2.
A ordem das linhas e a mesma do codigo (o ultimo a definir a mesma caixa vence no codigo; o script
avisa se houver chave repetida).

Uso (na raiz do repositorio):  python source/tools/ExtraiDados/extrai_lutadores.py
       --conferir   so confere a extracao, sem gravar
"""
import os
import re
import sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
FONTE = os.path.join(RAIZ, 'source', 'game', 'ChavesGolpes.pas')
DESTINO = os.path.join(RAIZ, 'Dados', 'Lutadores')
NUM = r'(-?\d+)'


def corpo_da_rotina(linhas, cabecalho):
    """Linhas (numero, texto) da rotina que comeca em 'cabecalho' ate a proxima rotina."""
    impl = linhas.index('implementation')
    ini = next(i for i in range(impl, len(linhas)) if linhas[i].startswith(cabecalho))
    fim = len(linhas)
    for i in range(ini + 1, len(linhas)):
        if re.match(r'^(procedure|function) ', linhas[i]) or linhas[i].startswith('end.'):
            fim = i
            break
    return [(i + 1, linhas[i]) for i in range(ini, fim)]


def extrai_centro(linhas):
    centro = {}
    pers = None
    for _, l in corpo_da_rotina(linhas, 'function CentroX('):
        m = re.match(r'^    (\d+):\s*$', l)
        if m:
            pers = int(m.group(1))
            centro[pers] = {}
            continue
        m = re.match(r'^\s+([\d,\s]+):\s*Result := ' + NUM + r';', l)
        if m and pers is not None:
            for q in m.group(1).split(','):
                q = int(q)
                if q in centro[pers]:
                    raise SystemExit(f'CentroX: quadro {q} repetido no personagem {pers}')
                centro[pers][q] = int(m.group(2))
    return centro


def extrai_caixas(linhas):
    corpo, ataque, avisos = {}, {}, []
    total = 0
    pers = None
    forca = None          # condicao "if (P.ForcaGolpe) = N" que envolve a chamada
    re_pers = re.compile(r'^  if \(P\.Personagem\) = (\d+) then')
    re_forca = re.compile(r'^    if \(P\.ForcaGolpe\) = (\d+) then')
    re_corpo = re.compile(r'^\s+DefineCaixaCorpo\(Jog, Desloc\+(\d+), ' + ', '.join([NUM] * 4) + r'\);')
    re_ataque = re.compile(r'^\s+DefineCaixaAtaque\(Jog, (\d+), (\d+), ' + ', '.join([NUM] * 8) + r'\);')
    for n, l in corpo_da_rotina(linhas, 'procedure AtualizaQuadro('):
        m = re_pers.match(l)
        if m:
            pers = int(m.group(1))
            corpo.setdefault(pers, [])
            ataque.setdefault(pers, [])
            forca = None
            continue
        m = re_forca.match(l)
        if m:
            forca = int(m.group(1))
            continue
        if re.match(r'^    end;', l):
            forca = None
            continue
        if 'DefineCaixa' not in l:
            continue
        total += 1
        if pers is None:
            raise SystemExit(f'linha {n}: caixa fora do bloco de um personagem')
        cond = forca if l.startswith('      ') else None
        if l.startswith('      ') and forca is None:
            raise SystemExit(f'linha {n}: caixa dentro de uma condicao desconhecida')
        m = re_corpo.match(l)
        if m:
            q, *v = map(int, m.groups())
            corpo[pers].append((str(q), v, n))
            continue
        m = re_ataque.match(l)
        if m:
            a, qa, *v = map(int, m.groups())
            chave = f'{a}.{qa}' + (f'.f{cond}' if cond else '')
            ataque[pers].append((chave, v, n))
            continue
        raise SystemExit(f'linha {n}: chamada nao reconhecida: {l.strip()}')
    for pers in corpo:
        for nome, lista in (('Corpo', corpo[pers]), ('Ataque', ataque[pers])):
            vistas = {}
            for chave, _, n in lista:
                if chave in vistas:
                    avisos.append(f'C{pers:02d} [{nome}] {chave}: repetida nas linhas {vistas[chave]} e {n}')
                vistas[chave] = n
    return corpo, ataque, total, avisos


def grava(pers, centro, corpo, ataque):
    arquivo = os.path.join(DESTINO, f'C{pers:02d}.ini')
    # o que vem antes de [CentroX] ([Geral], [Golpes]...) e editado a mao: fica como esta
    linhas = [
        f'; Dados/Lutadores/C{pers:02d}.ini - dados do personagem {pers}.',
        '; Gerado por source/tools/ExtraiDados/extrai_lutadores.py a partir de ChavesGolpes.pas.',
        '; Quadros contados a partir de 1 (jogador 1); o jogo soma 50 para o jogador 2.',
        '',
    ]
    if os.path.exists(arquivo):
        with open(arquivo, encoding='utf-8') as f:
            atual = f.read()
        if '\n[CentroX]\n' in atual:
            linhas = atual[:atual.index('\n[CentroX]\n')].rstrip('\n').split('\n') + ['']
    linhas += [
        '[CentroX]',
        '; quadro=deslocamento X do centro do sprite (onde fica a posicao do lutador)',
    ]
    linhas += [f'{q}={v}' for q, v in sorted(centro.items())]
    linhas += ['', '[Corpo]', '; quadro=x1,y1,x2,y2 (caixa do corpo, relativa aos pes; y a partir do topo do sprite)']
    linhas += [f'{q}=' + ','.join(map(str, v)) for q, v, _ in corpo]
    linhas += ['', '[Ataque]',
               '; acao.quadroAcao=x1,y1,x2,y2,ativo,forca,dano,danoDefesa',
               '; .f1 / .f2 no fim da chave = vale so quando a forca do golpe e 1 / 2']
    linhas += [f'{c}=' + ','.join(map(str, v)) for c, v, _ in ataque]
    os.makedirs(DESTINO, exist_ok=True)
    with open(arquivo, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(linhas) + '\n')


def main():
    with open(FONTE, encoding='latin-1') as f:
        linhas = f.read().splitlines()
    centro = extrai_centro(linhas)
    corpo, ataque, total, avisos = extrai_caixas(linhas)
    chamadas = sum(1 for l in linhas if re.match(r'^\s+DefineCaixa(Corpo|Ataque)\(Jog,', l))
    n_corpo = sum(len(v) for v in corpo.values())
    n_ataque = sum(len(v) for v in ataque.values())
    print(f'personagens: CentroX {len(centro)}, caixas {len(corpo)}')
    print(f'chamadas no codigo: {chamadas}; extraidas: {n_corpo} corpo + {n_ataque} ataque = {n_corpo + n_ataque}')
    if n_corpo + n_ataque != chamadas or total != chamadas:
        raise SystemExit('ERRO: nem todas as chamadas foram extraidas')
    if sorted(centro) != sorted(corpo):
        raise SystemExit('ERRO: personagens diferentes em CentroX e nas caixas')
    for a in avisos:
        print('aviso:', a)
    if '--conferir' in sys.argv:
        return
    for pers in sorted(corpo):
        grava(pers, centro[pers], corpo[pers], ataque[pers])
    print(f'gravados {len(corpo)} arquivos em {DESTINO}')


if __name__ == '__main__':
    main()
