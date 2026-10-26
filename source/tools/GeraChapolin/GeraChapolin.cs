// GeraChapolin.cs - desenha o lutador 16 (Chapolin) a partir de um esqueleto de poses.
//
// Gera, a partir da pasta do jogo passada como argumento:
//   Lutadores/C16.bmp                folha de sprites (50 quadros, separados por colunas pretas)
//   Rostos/R16-a.bmp, -b.bmp, -c.bmp  retratos (normal, apanhando, grande)
//   Efeitos/Efeito-102..105.bmp       onda da corneta e o "PLAFT!" do especial final
//   Sons/Som-68.wav, Som-69.wav       guincho da marreta e zumbido da corneta
//   e escreve na saida padrao as secoes [CentroX], [Corpo] e [Ataque] do Dados/Lutadores/C16.ini.
//
// Compilar (Windows, .NET Framework):
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe -r:System.Drawing.dll GeraChapolin.cs
// Usar:
//   GeraChapolin.exe <pasta do jogo> [previa.png] > quadros.ini
//
// Angulos das poses, em graus: 0 = para baixo, + = para a frente (o lutador olha para a direita),
// 90 = para a frente na horizontal, 180 = para cima. Tronco e cabeca: inclinacao (+ = para a frente).
// Ombro e quadril sao absolutos; cotovelo e joelho sao relativos ao segmento de cima.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

enum Rosto { Normal, Grito, Dor }

class Pose
{
    public double Torso, Cabeca;
    public double BOmbro, BCotovelo, FOmbro, FCotovelo;
    public double BQuadril, BJoelho, FQuadril, FJoelho;
    public bool NoChao = true;   // apoia o ponto mais baixo no chao
    public double Altura;        // no ar: altura do quadril acima do chao
    public string Objeto = "";   // marreta, corneta, dedo, pilula
    public double ObjAng;        // angulo do objeto, relativo ao antebraco da frente
    public double Escala = 1;    // nanicolina
    public double Rot;           // giro do corpo todo em volta do quadril
    public Rosto Rosto = Rosto.Normal;

    public Pose(double tor, double cab, double bo, double bc, double fo, double fc, double bq, double bj, double fq, double fj)
    {
        Torso = tor; Cabeca = cab; BOmbro = bo; BCotovelo = bc; FOmbro = fo; FCotovelo = fc;
        BQuadril = bq; BJoelho = bj; FQuadril = fq; FJoelho = fj;
    }
    public Pose Copia() { return (Pose)MemberwiseClone(); }
    public Pose Ar(double altura) { var p = Copia(); p.NoChao = false; p.Altura = altura; return p; }
    public Pose Com(string obj, double ang = 0) { var p = Copia(); p.Objeto = obj; p.ObjAng = ang; return p; }
    public Pose Cara(Rosto r) { var p = Copia(); p.Rosto = r; return p; }
    public Pose BracoF(double o, double c) { var p = Copia(); p.FOmbro = o; p.FCotovelo = c; return p; }
    public Pose BracoB(double o, double c) { var p = Copia(); p.BOmbro = o; p.BCotovelo = c; return p; }
    public Pose PernaF(double q, double j) { var p = Copia(); p.FQuadril = q; p.FJoelho = j; return p; }
    public Pose PernaB(double q, double j) { var p = Copia(); p.BQuadril = q; p.BJoelho = j; return p; }
    public Pose Tronco(double t, double c) { var p = Copia(); p.Torso = t; p.Cabeca = c; return p; }
}

class Juntas
{
    public PointF Quadril, Ombro, Pescoco, Cabeca;
    public PointF BCot, BMao, FCot, FMao;
    public PointF BJoe, BTor, FJoe, FTor, BPe, FPe;
    public PointF Objeto;   // cabeca da marreta / campana da corneta
    public double AngBAnte, AngFAnte, AngBCan, AngFCan;
}

static class Rig
{
    public const double Tronco = 37, Pescoco = 4, RaioCab = 11, Braco = 21, Antebraco = 20, Coxa = 29, Canela = 30, Pe = 13;

    public static readonly Color Contorno = Color.FromArgb(70, 14, 18);
    public static readonly Color Vermelho = Color.FromArgb(206, 22, 34);
    public static readonly Color VermelhoClaro = Color.FromArgb(240, 70, 70);
    public static readonly Color VermelhoEscuro = Color.FromArgb(150, 10, 22);
    public static readonly Color Amarelo = Color.FromArgb(250, 210, 30);
    public static readonly Color Pele = Color.FromArgb(236, 186, 150);
    public static readonly Color PeleEscura = Color.FromArgb(200, 145, 110);

    public static PointF Dir(double ang, double len)
    {
        double r = ang * Math.PI / 180.0;
        return new PointF((float)(Math.Sin(r) * len), (float)(Math.Cos(r) * len));
    }
    public static PointF Add(PointF a, PointF b) { return new PointF(a.X + b.X, a.Y + b.Y); }
    static Color Escurece(Color c, double f) { return Color.FromArgb(c.A, (int)(c.R * f), (int)(c.G * f), (int)(c.B * f)); }

    public static Juntas Calcula(Pose p, PointF quadril)
    {
        var j = new Juntas();
        j.Quadril = quadril;
        j.Ombro = Add(quadril, Dir(180 - p.Torso, Tronco));
        j.Pescoco = Add(j.Ombro, Dir(180 - p.Torso - p.Cabeca, Pescoco));
        j.Cabeca = Add(j.Pescoco, Dir(180 - p.Torso - p.Cabeca, RaioCab));
        j.BCot = Add(j.Ombro, Dir(p.BOmbro, Braco));
        j.AngBAnte = p.BOmbro + p.BCotovelo;
        j.BMao = Add(j.BCot, Dir(j.AngBAnte, Antebraco));
        j.FCot = Add(j.Ombro, Dir(p.FOmbro, Braco));
        j.AngFAnte = p.FOmbro + p.FCotovelo;
        j.FMao = Add(j.FCot, Dir(j.AngFAnte, Antebraco));
        j.BJoe = Add(quadril, Dir(p.BQuadril, Coxa));
        j.AngBCan = p.BQuadril + p.BJoelho;
        j.BTor = Add(j.BJoe, Dir(j.AngBCan, Canela));
        j.FJoe = Add(quadril, Dir(p.FQuadril, Coxa));
        j.AngFCan = p.FQuadril + p.FJoelho;
        j.FTor = Add(j.FJoe, Dir(j.AngFCan, Canela));
        j.BPe = Add(j.BTor, Dir(j.AngBCan + 90, Pe));
        j.FPe = Add(j.FTor, Dir(j.AngFCan + 90, Pe));
        j.Objeto = j.FMao;
        if (p.Objeto == "marreta") j.Objeto = Add(j.FMao, Dir(j.AngFAnte + p.ObjAng, 30));
        if (p.Objeto == "corneta") j.Objeto = Add(j.FMao, Dir(j.AngFAnte + p.ObjAng, 22));
        return j;
    }

    // ---- primitivas ----

    // capsula afinando de wa (em a) para wb (em b)
    static GraphicsPath Capsula(PointF a, PointF b, float wa, float wb)
    {
        var path = new GraphicsPath(FillMode.Winding);
        float dx = b.X - a.X, dy = b.Y - a.Y; float l = (float)Math.Sqrt(dx * dx + dy * dy);
        if (l < 0.01f) { dx = 0; dy = 1; l = 1; }
        float nx = -dy / l, ny = dx / l;
        var quad = new[] {
            new PointF(a.X + nx * wa / 2, a.Y + ny * wa / 2), new PointF(b.X + nx * wb / 2, b.Y + ny * wb / 2),
            new PointF(b.X - nx * wb / 2, b.Y - ny * wb / 2), new PointF(a.X - nx * wa / 2, a.Y - ny * wa / 2) };
        // mesmo sentido das elipses (horario na tela), para o Winding unir as partes
        double area = 0;
        for (int i = 0; i < 4; i++) { var u = quad[i]; var v = quad[(i + 1) % 4]; area += u.X * v.Y - v.X * u.Y; }
        if (area < 0) Array.Reverse(quad);
        path.AddPolygon(quad);
        path.AddEllipse(a.X - wa / 2, a.Y - wa / 2, wa, wa);
        path.AddEllipse(b.X - wb / 2, b.Y - wb / 2, wb, wb);
        return path;
    }

    static void Preenche(Graphics g, Color c, GraphicsPath p)
    {
        using (p) using (var br = new SolidBrush(c)) g.FillPath(br, p);
    }

    // membro com volume: contorno, sombra de um lado e brilho do lado de cima/da frente
    static void Membro(Graphics g, PointF a, PointF b, float wa, float wb, Color c, Color luz)
    {
        Preenche(g, Contorno, Capsula(a, b, wa + 2.5f, wb + 2.5f));
        Preenche(g, Escurece(c, 0.8), Capsula(a, b, wa, wb));
        float dx = b.X - a.X, dy = b.Y - a.Y; float l = (float)Math.Sqrt(dx * dx + dy * dy);
        if (l < 0.01f) return;
        float nx = -dy / l, ny = dx / l;
        if (nx - ny < 0) { nx = -nx; ny = -ny; }
        float s = 0.12f;
        Preenche(g, c, Capsula(new PointF(a.X + nx * wa * s, a.Y + ny * wa * s), new PointF(b.X + nx * wb * s, b.Y + ny * wb * s), wa * 0.72f, wb * 0.72f));
        Preenche(g, Color.FromArgb(140, luz), Capsula(new PointF(a.X + nx * wa * 0.25f, a.Y + ny * wa * 0.25f),
            new PointF(b.X + nx * wb * 0.25f, b.Y + ny * wb * 0.25f), wa * 0.22f, wb * 0.22f));
    }
    static void Membro(Graphics g, PointF a, PointF b, float w, Color c, Color luz) { Membro(g, a, b, w, w, c, luz); }

    static void Bola(Graphics g, PointF c, float r, Color cor)
    {
        using (var b = new SolidBrush(Contorno)) g.FillEllipse(b, c.X - r - 1.3f, c.Y - r - 1.3f, 2 * r + 2.6f, 2 * r + 2.6f);
        using (var b = new SolidBrush(cor)) g.FillEllipse(b, c.X - r, c.Y - r, 2 * r, 2 * r);
    }

    static void Tenis(Graphics g, PointF tornozelo, PointF ponta, Color amarelo)
    {
        Membro(g, tornozelo, ponta, 9, 8, amarelo, Color.White);
        float dx = ponta.X - tornozelo.X, dy = ponta.Y - tornozelo.Y; float l = (float)Math.Sqrt(dx * dx + dy * dy);
        float nx = dy / l * 3.5f, ny = -dx / l * 3.5f;
        using (var ps = new Pen(Color.FromArgb(245, 245, 240), 2.5f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
            g.DrawLine(ps, tornozelo.X - nx, tornozelo.Y - ny, ponta.X - nx, ponta.Y - ny);
        // cadarcos vermelhos
        using (var pr = new Pen(VermelhoEscuro, 1.5f))
            for (int i = 1; i <= 2; i++)
            {
                float t = 0.3f + i * 0.2f;
                var m = new PointF(tornozelo.X + dx * t + nx * 0.6f, tornozelo.Y + dy * t + ny * 0.6f);
                g.DrawLine(pr, m.X - 2, m.Y - 1.5f, m.X + 2, m.Y + 0.5f);
            }
    }

    static void Marreta(Graphics g, PointF mao, double ang)
    {
        var fim = Add(mao, Dir(ang, 30));
        Membro(g, Add(mao, Dir(ang + 180, 5)), fim, 4, Amarelo, Color.White);
        // cabeca vermelha perpendicular ao cabo, com as pontas amarelas
        var e1 = Add(fim, Dir(ang + 90, 13)); var e2 = Add(fim, Dir(ang - 90, 13));
        Membro(g, e1, e2, 15, Vermelho, VermelhoClaro);
        using (var pa = new Pen(Amarelo, 13))
        {
            g.DrawLine(pa, Add(fim, Dir(ang + 90, 10)), Add(fim, Dir(ang + 90, 13)));
            g.DrawLine(pa, Add(fim, Dir(ang - 90, 10)), Add(fim, Dir(ang - 90, 13)));
        }
    }

    static void Corneta(Graphics g, PointF mao, double ang)
    {
        var sino = Add(mao, Dir(ang, 22));
        Membro(g, Add(mao, Dir(ang + 180, 6)), sino, 4, Amarelo, Color.White);
        var a = Add(sino, Dir(ang + 90, 9)); var b = Add(sino, Dir(ang - 90, 9));
        var c = Add(mao, Dir(ang, 12));
        var pts = new[] { Add(c, Dir(ang + 90, 2)), a, b, Add(c, Dir(ang - 90, 2)) };
        using (var pc = new Pen(Contorno, 3)) g.DrawPolygon(pc, pts);
        using (var br = new SolidBrush(Amarelo)) g.FillPolygon(br, pts);
        using (var pr = new Pen(Vermelho, 2)) g.DrawLine(pr, a, b);
    }

    static void Pilula(Graphics g, PointF mao)
    {
        var a = Add(mao, new PointF(-2, -6)); var b = Add(mao, new PointF(4, -9));
        Preenche(g, Contorno, Capsula(a, b, 6.5f, 6.5f));
        Preenche(g, Color.FromArgb(248, 248, 248), Capsula(a, new PointF((a.X + b.X) / 2, (a.Y + b.Y) / 2), 4, 4));
        Preenche(g, Color.FromArgb(40, 120, 220), Capsula(new PointF((a.X + b.X) / 2, (a.Y + b.Y) / 2), b, 4, 4));
    }

    static void Mao(Graphics g, PointF p, bool tras) { Bola(g, p, 4.6f, tras ? PeleEscura : Pele); }

    static void Coracao(Graphics g, PointF centro, double ang, float s)
    {
        var st = g.Save();
        g.TranslateTransform(centro.X, centro.Y);
        g.RotateTransform((float)ang);
        using (var path = new GraphicsPath())
        {
            path.AddBezier(0, s * 0.35f, -s * 0.15f, s * 0.15f, -s * 0.55f, s * 0.05f, -s * 0.5f, -s * 0.2f);
            path.AddBezier(-s * 0.5f, -s * 0.2f, -s * 0.45f, -s * 0.5f, -s * 0.05f, -s * 0.5f, 0, -s * 0.22f);
            path.AddBezier(0, -s * 0.22f, s * 0.05f, -s * 0.5f, s * 0.45f, -s * 0.5f, s * 0.5f, -s * 0.2f);
            path.AddBezier(s * 0.5f, -s * 0.2f, s * 0.55f, s * 0.05f, s * 0.15f, s * 0.15f, 0, s * 0.35f);
            using (var pc = new Pen(Contorno, 1.5f)) g.DrawPath(pc, path);
            using (var br = new SolidBrush(Amarelo)) g.FillPath(br, path);
        }
        using (var f = new Font("Arial Black", s * 0.3f, FontStyle.Bold, GraphicsUnit.Pixel))
        using (var br = new SolidBrush(VermelhoEscuro))
        {
            var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
            g.DrawString("CH", f, br, new PointF(0, -s * 0.04f), sf);
        }
        g.Restore(st);
    }

    static void Cabeca(Graphics g, Juntas j, Pose p)
    {
        var st = g.Save();
        g.TranslateTransform(j.Cabeca.X, j.Cabeca.Y);
        g.RotateTransform((float)(p.Torso + p.Cabeca));
        float r = (float)RaioCab;
        // anteninhas de vinil
        using (var pc = new Pen(Contorno, 4.5f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        using (var pv = new Pen(Vermelho, 2f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        {
            var a1 = new[] { new PointF(-2, -r + 2), new PointF(-5, -r - 8), new PointF(-9, -r - 14) };
            var a2 = new[] { new PointF(4, -r + 2), new PointF(6, -r - 9), new PointF(3, -r - 16) };
            g.DrawCurve(pc, a1); g.DrawCurve(pc, a2);
            g.DrawCurve(pv, a1); g.DrawCurve(pv, a2);
            Bola(g, new PointF(-9, -r - 15), 3.2f, Vermelho);
            Bola(g, new PointF(3, -r - 17), 3.2f, Vermelho);
            using (var bl = new SolidBrush(VermelhoClaro)) { g.FillEllipse(bl, -10.5f, -r - 17, 2, 2); g.FillEllipse(bl, 1.5f, -r - 19, 2, 2); }
        }
        // capuz
        using (var b = new SolidBrush(Contorno)) g.FillEllipse(b, -r - 1.5f, -r * 1.12f - 1.5f, 2 * r + 3, 2.24f * r + 3);
        using (var b = new LinearGradientBrush(new PointF(-r, 0), new PointF(r, 0), VermelhoEscuro, VermelhoClaro))
            g.FillEllipse(b, -r, -r * 1.12f, 2 * r, 2.24f * r);
        // rosto (3/4, virado para a frente)
        var rosto = new RectangleF(-r * 0.25f, -r * 0.75f, r * 1.15f, r * 1.55f);
        using (var b = new SolidBrush(Contorno)) g.FillEllipse(b, rosto.X - 1, rosto.Y - 1, rosto.Width + 2, rosto.Height + 2);
        using (var b = new SolidBrush(Pele)) g.FillEllipse(b, rosto);
        using (var b = new SolidBrush(PeleEscura)) g.FillEllipse(b, r * 0.78f, -r * 0.05f, 4, 5);
        using (var b = new SolidBrush(Color.FromArgb(30, 20, 20)))
        using (var pb = new Pen(Color.FromArgb(60, 35, 25), 1.4f))
        {
            if (p.Rosto == Rosto.Dor)
            {
                // olhos apertados e sobrancelhas para cima
                g.DrawLine(pb, r * 0.12f, -r * 0.22f, r * 0.38f, -r * 0.18f);
                g.DrawLine(pb, r * 0.6f, -r * 0.18f, r * 0.86f, -r * 0.22f);
                g.DrawLine(pb, r * 0.05f, -r * 0.4f, r * 0.4f, -r * 0.55f);
                g.DrawLine(pb, r * 0.55f, -r * 0.55f, r * 0.9f, -r * 0.4f);
            }
            else
            {
                g.FillEllipse(b, r * 0.15f, -r * 0.3f, 2.6f, 3.2f);
                g.FillEllipse(b, r * 0.62f, -r * 0.3f, 2.6f, 3.2f);
                g.DrawLine(pb, r * 0.05f, -r * 0.45f, r * 0.4f, -r * 0.5f);
                g.DrawLine(pb, r * 0.55f, -r * 0.5f, r * 0.9f, -r * 0.45f);
            }
        }
        if (p.Rosto == Rosto.Normal)
            using (var pm = new Pen(Color.FromArgb(120, 40, 40), 1.4f)) g.DrawArc(pm, r * 0.25f, r * 0.15f, r * 0.6f, r * 0.35f, 20, 140);
        else
            using (var b = new SolidBrush(Color.FromArgb(110, 20, 25))) g.FillEllipse(b, r * 0.3f, r * 0.18f, 6, 5.5f);
        using (var po = new Pen(VermelhoEscuro, 1.5f)) g.DrawArc(po, -r * 0.6f, -r * 0.3f, r * 0.45f, r * 0.6f, 90, 180);
        g.Restore(st);
    }

    public static void Desenha(Graphics g, Pose p, PointF quadril)
    {
        var j = Calcula(p, quadril);
        Color vT = Escurece(Vermelho, 0.8), aT = Escurece(Amarelo, 0.85);
        // braco e perna de tras
        Membro(g, j.Ombro, j.BCot, 8.5f, 7, vT, VermelhoClaro);
        Membro(g, j.BCot, j.BMao, 7, 5.5f, vT, VermelhoClaro);
        Mao(g, j.BMao, true);
        Membro(g, j.Quadril, j.BJoe, 13, 9.5f, vT, VermelhoClaro);
        Membro(g, j.BJoe, j.BTor, 9.5f, 6.5f, vT, VermelhoClaro);
        Tenis(g, j.BTor, j.BPe, aT);
        // perna da frente
        Membro(g, j.Quadril, j.FJoe, 13, 9.5f, Vermelho, VermelhoClaro);
        Membro(g, j.FJoe, j.FTor, 9.5f, 6.5f, Vermelho, VermelhoClaro);
        Tenis(g, j.FTor, j.FPe, Amarelo);
        // pescoco (coberto pelo capuz) e tronco
        Membro(g, j.Ombro, j.Pescoco, 8, 8, VermelhoEscuro, Vermelho);
        float ombroL = 12, quadrilL = 10;
        var perp = Dir(270 - p.Torso, 1);
        var pts = new[] {
            new PointF(j.Ombro.X + perp.X * ombroL, j.Ombro.Y + perp.Y * ombroL),
            new PointF(j.Ombro.X - perp.X * ombroL, j.Ombro.Y - perp.Y * ombroL),
            new PointF(j.Quadril.X - perp.X * quadrilL, j.Quadril.Y - perp.Y * quadrilL),
            new PointF(j.Quadril.X + perp.X * quadrilL, j.Quadril.Y + perp.Y * quadrilL) };
        using (var path = new GraphicsPath())
        {
            path.AddClosedCurve(pts, 0.3f);
            using (var pc = new Pen(Contorno, 2.5f)) g.DrawPath(pc, path);
            using (var br = new LinearGradientBrush(pts[1], pts[0], VermelhoEscuro, VermelhoClaro)) g.FillPath(br, path);
        }
        // calcao amarelo: da cintura ate o meio das coxas
        {
            var cint = Add(j.Quadril, Dir(180 - p.Torso, 6));
            var q1 = new PointF(cint.X + perp.X * (quadrilL - 4), cint.Y + perp.Y * (quadrilL - 4));
            var q2 = new PointF(cint.X - perp.X * (quadrilL - 4), cint.Y - perp.Y * (quadrilL - 4));
            var cb = Add(j.Quadril, Dir(p.BQuadril, Coxa * 0.4));
            var cf = Add(j.Quadril, Dir(p.FQuadril, Coxa * 0.4));
            Preenche(g, Contorno, Capsula(q1, q2, 13.5f, 13.5f));
            Preenche(g, Contorno, Capsula(j.Quadril, cb, 16.5f, 15));
            Preenche(g, Contorno, Capsula(j.Quadril, cf, 16.5f, 15));
            Preenche(g, aT, Capsula(j.Quadril, cb, 14, 12.5f));
            Preenche(g, Amarelo, Capsula(q1, q2, 11, 11));
            Preenche(g, Amarelo, Capsula(j.Quadril, cf, 14, 12.5f));
            Preenche(g, Color.FromArgb(150, 255, 248, 200), Capsula(Add(j.Quadril, Dir(p.FQuadril - 90, 3)), Add(cf, Dir(p.FQuadril - 90, 3)), 3, 3));
        }
        var peito = Add(Add(j.Quadril, Dir(180 - p.Torso, Tronco * 0.64)), Dir(90 - p.Torso, 2));
        Coracao(g, peito, p.Torso, 18);
        // braco da frente erguido passa atras da cabeca (senao cobre o rosto)
        bool erguido = p.FOmbro - p.Torso >= 140 && j.AngFAnte - p.Torso >= 140;
        if (!erguido) Cabeca(g, j, p);
        Membro(g, j.Ombro, j.FCot, 8.5f, 7, Vermelho, VermelhoClaro);
        Membro(g, j.FCot, j.FMao, 7, 5.5f, Vermelho, VermelhoClaro);
        if (p.Objeto == "marreta") Marreta(g, j.FMao, j.AngFAnte + p.ObjAng);
        if (p.Objeto == "corneta") Corneta(g, j.FMao, j.AngFAnte + p.ObjAng);
        Mao(g, j.FMao, false);
        if (p.Objeto == "dedo") Membro(g, j.FMao, Add(j.FMao, Dir(j.AngFAnte, 7)), 2.5f, Pele, Color.White);
        if (p.Objeto == "pilula") Pilula(g, j.FMao);
        if (erguido) Cabeca(g, j, p);
    }
}

class Quadro
{
    public Bitmap Img;
    public int CentroX;            // quadril, em x do quadro
    public PointF Mao, Pe, Objeto; // pontos de ataque (x relativo ao centro, y a partir do topo)
    public Rectangle Corpo;        // caixa do corpo (x relativo ao centro, y a partir do topo)
}

static class Programa
{
    const int AlturaFolha = 196;   // altura da folha de sprites
    const int Chao = AlturaFolha - 2;

    // desenha a pose sobre fundo transparente e recorta sobre o branco do jogo
    static Quadro Renderiza(Pose p, int num)
    {
        int W = 340, H = 300;
        var hip0 = new PointF(W / 2f, 150);
        Matrix m = new Matrix();
        m.Translate(hip0.X, hip0.Y); m.Rotate((float)p.Rot); m.Scale((float)p.Escala, (float)p.Escala); m.Translate(-hip0.X, -hip0.Y);
        var tmp = new Bitmap(W, H, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(tmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            g.Transform = m;
            Rig.Desenha(g, p, hip0);
        }
        // caixa dos pixels desenhados
        int minX = W, maxX = -1, minY = H, maxY = -1;
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
                if (tmp.GetPixel(x, y).A >= 110)
                { if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; }
        // desloca: no chao, o ponto mais baixo encosta no chao; no ar, o quadril fica em Altura
        int dy = p.NoChao ? Chao - maxY : (int)Math.Round(Chao - p.Altura * p.Escala - hip0.Y);
        if (minY + dy < 2) Console.Error.WriteLine("aviso: quadro " + num + " cortado em cima (" + (minY + dy) + ")");
        if (maxY + dy > Chao) Console.Error.WriteLine("aviso: quadro " + num + " passa do chao");
        minX = Math.Max(0, minX - 2); maxX = Math.Min(W - 1, maxX + 2);
        var q = new Quadro();
        q.Img = new Bitmap(maxX - minX + 1, AlturaFolha, PixelFormat.Format24bppRgb);
        for (int y = 0; y < AlturaFolha; y++)
            for (int x = minX; x <= maxX; x++)
            {
                int sy = y - dy;
                Color o = Color.White;
                if (y >= 2 && y <= Chao && sy >= 0 && sy < H)
                {
                    var c = tmp.GetPixel(x, sy);
                    if (c.A >= 110)
                    {
                        int r = c.R, gg = c.G, b = c.B;
                        if (r > 250 && gg > 250 && b > 250) { r = 248; gg = 248; b = 248; }
                        o = Color.FromArgb(r, gg, b);
                    }
                }
                q.Img.SetPixel(x - minX, y, o);
            }
        tmp.Dispose();
        // pontos de referencia no quadro
        var j = Rig.Calcula(p, hip0);
        var pts = new[] { j.Quadril, j.FMao, j.FPe, j.Objeto, j.Cabeca, j.Ombro, j.BPe, j.FTor, j.BTor, j.FJoe, j.BJoe };
        m.TransformPoints(pts);
        for (int i = 0; i < pts.Length; i++) pts[i] = new PointF(pts[i].X - minX, pts[i].Y + dy);
        q.CentroX = (int)Math.Round(pts[0].X);
        Func<PointF, PointF> rel = a => new PointF(a.X - q.CentroX, a.Y);
        q.Mao = rel(pts[1]); q.Pe = rel(pts[2]); q.Objeto = rel(pts[3]);
        // corpo: em volta do quadril, ombro e cabeca, do alto da cabeca ate os pes
        float cx = (pts[0].X + pts[5].X + pts[4].X) / 3 - q.CentroX;
        float topo = pts[4].Y - (float)(Rig.RaioCab * 1.1 * p.Escala);
        float baixo = Math.Max(Math.Max(pts[6].Y, pts[2].Y), Math.Max(pts[7].Y, pts[8].Y));
        if (p.NoChao) baixo = AlturaFolha + 4;
        float meia = (float)(16 * p.Escala);
        if (Math.Abs(p.Rot) > 45 || Math.Abs(p.Torso) > 60)
        {
            // deitado ou girando: usa a largura dos pontos do corpo
            float x1 = float.MaxValue, x2 = float.MinValue; topo = float.MaxValue;
            foreach (var a in new[] { pts[0], pts[4], pts[5], pts[9], pts[10], pts[7], pts[8] })
            { x1 = Math.Min(x1, a.X); x2 = Math.Max(x2, a.X); topo = Math.Min(topo, a.Y); }
            q.Corpo = Rectangle.FromLTRB((int)x1 - q.CentroX - 8, (int)topo - 8, (int)x2 - q.CentroX + 8, (int)baixo);
        }
        else
            q.Corpo = Rectangle.FromLTRB((int)(cx - meia), (int)topo, (int)(cx + meia), (int)baixo);
        return q;
    }

    // ---- poses (quadros 1..50, mesma ordem de acoes do Comum.rot) ----
    static List<Pose> Poses()
    {
        var L = new List<Pose>();
        var parado = new Pose(8, -4, 35, 105, 55, 95, -14, -18, 22, -28);
        var agach = new Pose(18, -12, 40, 100, 60, 95, 40, -125, 82, -100);
        var pulo = new Pose(5, -5, 150, 20, 130, 40, 70, -120, 100, -130).Ar(90);
        var deitado = new Pose(-90, 5, 95, 0, 80, 10, 92, 0, 85, -5);
        L.Add(parado);                                                                    // 1 parado
        L.Add(new Pose(6, -4, 30, 105, 50, 95, -25, -20, 30, -22));                        // 2 andando
        L.Add(new Pose(6, -4, 40, 100, 55, 92, -4, -30, 8, -10));                          // 3 andando
        L.Add(parado.Tronco(10, -5).BracoF(62, 70));                                       // 4 soco fraco
        L.Add(new Pose(15, -6, 30, 110, 92, 3, -20, -12, 26, -30));                        // 5
        L.Add(new Pose(0, -2, 40, 100, 55, 95, -6, -4, 60, -80));                          // 6 chute fraco
        L.Add(new Pose(-12, 10, 45, 95, 30, 110, -8, -4, 85, -8));                         // 7
        L.Add(new Pose(-5, -2, 60, 80, 10, 130, -18, -15, 25, -25));                       // 8 soco forte
        L.Add(new Pose(25, -12, 10, 90, 98, 0, -38, 0, 40, -38));                          // 9
        L.Add(new Pose(-10, 6, 40, 100, 50, 95, -8, -4, 95, -115));                        // 10 chute forte
        L.Add(new Pose(-28, 20, 40, 100, 15, 120, -12, -5, 118, 0));                       // 11
        L.Add(agach);                                                                     // 12 agachado
        L.Add(agach.BracoF(72, 68));                                                      // 13 agachado soco fraco
        L.Add(agach.Tronco(22, -14).BracoF(88, 4));                                       // 14
        L.Add(agach.PernaF(75, -60));                                                     // 15 agachado chute fraco
        L.Add(agach.Tronco(5, -5).PernaF(88, -4));                                        // 16
        L.Add(agach.BracoF(30, 120));                                                     // 17 agachado soco forte
        L.Add(new Pose(10, -15, 40, 100, 165, 5, 20, -60, 40, -50));                       // 18 (gancho)
        L.Add(agach.Tronco(30, -12));                                                     // 19 agachado chute forte
        L.Add(new Pose(45, -25, 100, 0, 60, 60, 50, -130, 92, 0));                         // 20 (rasteira)
        L.Add(pulo);                                                                      // 21 pulo
        L.Add(pulo.BracoF(60, 80));                                                       // 22 soco no ar
        L.Add(pulo.BracoF(65, 0).Tronco(15, -8));                                         // 23
        L.Add(pulo.PernaF(90, -110));                                                     // 24 chute no ar
        L.Add(pulo.PernaF(60, 0).PernaB(20, -90).Tronco(-20, 10));                        // 25
        L.Add(new Pose(-20, -25, -30, 60, 10, 40, -25, -5, 10, -15).Cara(Rosto.Dor));      // 26 apanhando alto
        L.Add(new Pose(35, 15, 70, 90, 60, 90, -10, -20, 20, -30).Cara(Rosto.Dor));        // 27 apanhando baixo
        L.Add(new Pose(-70, -20, 170, -20, 150, -10, 40, -30, 60, -20).Ar(90).Cara(Rosto.Dor)); // 28 derrubado
        L.Add(deitado.Cara(Rosto.Dor));                                                    // 29 no chao
        L.Add(new Pose(40, -20, 10, 0, 60, 90, 45, -125, 80, -100));                       // 30 levantando
        L.Add(parado.Tronco(-5, -10).BracoB(70, 140).BracoF(80, 135));                    // 31 defesa
        L.Add(agach.BracoB(70, 140).BracoF(80, 135));                                     // 32 defesa agachado
        var vit = new Pose(0, -10, -35, 95, 160, 15, -8, -2, 10, -3);
        L.Add(vit.Com("dedo"));                                                           // 33 vitoria: dedo para cima
        L.Add(vit.Tronco(-5, -15).BracoF(45, -115));                                      // 34 maos na cintura
        L.Add(vit.Tronco(5, -8).BracoF(110, -5).Com("dedo").Cara(Rosto.Grito));           // 35 sigam-me os bons
        var corn = new Pose(0, -5, 60, 90, 40, 60, -14, -10, 18, -20);
        L.Add(corn.Com("corneta", -40));                                                  // 36 corneta
        L.Add(corn.BracoF(70, 100).Com("corneta", -80));                                  // 37
        L.Add(corn.Tronco(-8, -2).BracoF(75, 105).Com("corneta", -90));                   // 38
        L.Add(corn.Tronco(-12, -5).BracoF(75, 105).Com("corneta", -90).PernaB(-25, -5).PernaF(28, -25)); // 39
        L.Add(new Pose(-15, 10, 60, 90, 175, 40, -15, -10, 20, -20).Com("marreta"));       // 40 marreta: sobe
        L.Add(new Pose(5, -5, 60, 90, 150, 0, -20, -10, 25, -25).Com("marreta"));          // 41
        L.Add(new Pose(35, -10, 70, 20, 80, 20, -30, -5, 40, -40).Com("marreta", 20));     // 42 bate
        var giro = new Pose(0, -5, 150, 20, 170, 0, -10, -20, 30, -60).Com("marreta").Ar(75);
        L.Add(giro);                                                                      // 43 chipote voador
        var giro2 = giro.Copia(); giro2.Rot = 100; L.Add(giro2);                          // 44
        L.Add(new Pose(-8, -20, 35, 100, 95, 78, -10, -5, 15, -10).Com("pilula"));       // 45 pilula
        var nano = new Pose(15, -5, -30, 90, 70, 80, -30, -30, 35, -20); nano.Escala = 0.4;
        L.Add(nano);                                                                      // 46 nanico correndo
        var nano2 = new Pose(15, -5, 60, 80, -20, 90, 10, -60, -5, -10); nano2.Escala = 0.4;
        L.Add(nano2);                                                                     // 47
        L.Add(new Pose(-5, -10, 30, 100, 172, 0, -15, 0, 20, -10).Cara(Rosto.Grito));     // 48 cresce com gancho
        L.Add(new Pose(5, -10, -35, 95, 115, -5, -18, -5, 25, -20).Com("dedo").Cara(Rosto.Grito)); // 49 sigam-me os bons
        L.Add(new Pose(-10, 5, 150, 20, 175, 30, 30, -90, 60, -100).Com("marreta").Ar(62).Cara(Rosto.Grito)); // 50 salto
        return L;
    }

    // ---- caixas de ataque: acao.quadroAcao = ponto do quadro, tamanho e dano ----
    class Golpe { public string Chave; public int Quadro; public string Ponto; public int W, H, Forca, Dano, DanoDefesa; }
    static Golpe G(string k, int q, string pt, int w, int h, int forca, int dano, int ddef)
    { return new Golpe { Chave = k, Quadro = q, Ponto = pt, W = w, H = h, Forca = forca, Dano = dano, DanoDefesa = ddef }; }

    static List<Golpe> Golpes()
    {
        // danos cerca de 15% acima dos do Chaves (7 / 14): ele e um oponente de chefe
        return new List<Golpe> {
            G("3.2", 5, "mao", 40, 14, 1, 8, 0),      G("4.2", 7, "pe", 46, 18, 1, 8, 0),
            G("5.5", 9, "mao", 44, 16, 2, 16, 0),     G("6.5", 11, "pe", 48, 22, 2, 16, 0),
            G("8.2", 14, "mao", 44, 16, 1, 8, 0),     G("9.2", 16, "pe", 50, 20, 1, 8, 0),
            G("10.5", 18, "mao", 30, 44, 2, 16, 0),   G("11.5", 20, "pe", 56, 20, 2, 16, 0),
            G("13.2", 23, "mao", 40, 24, 1, 8, 0),    G("14.2", 25, "pe", 44, 28, 1, 8, 0),
            G("15.5", 23, "mao", 40, 24, 2, 16, 0),   G("16.5", 25, "pe", 44, 28, 2, 16, 0),
            // marreta bionica
            G("26.7.f1", 42, "objeto", 50, 44, 0, 19, 3), G("26.10.f2", 42, "objeto", 54, 48, 0, 24, 4),
            // chipote voador (girando)
            G("27.0", 43, "corpo", 0, 0, 0, 12, 2),   G("27.3", 44, "corpo", 0, 0, 0, 8, 2),
            G("27.6", 43, "corpo", 0, 0, 0, 5, 2),    G("27.9", 44, "corpo", 0, 0, 0, 3, 2),
            // nanicolina: cresce com o gancho
            G("28.24", 48, "mao", 40, 70, 0, 18, 3),
            // especial final: a marreta gigante cai (o PLAFT! e um efeito)
            G("29.16", 42, "objeto", 70, 60, 0, 14, 3),
        };
    }

    static string Caixa(Quadro q, Golpe g)
    {
        Rectangle r;
        if (g.Ponto == "corpo")
            r = Rectangle.FromLTRB(q.Corpo.Left - 16, q.Corpo.Top, q.Corpo.Right + 16, Math.Min(q.Corpo.Bottom, AlturaFolha));
        else
        {
            PointF p = g.Ponto == "mao" ? q.Mao : g.Ponto == "pe" ? q.Pe : q.Objeto;
            // a caixa fica um pouco para tras do ponto (o braco ou a perna que chega ate ele)
            r = new Rectangle((int)(p.X - g.W * 0.75f), (int)(p.Y - g.H / 2f), g.W, g.H);
        }
        return string.Format("{0},{1},{2},{3},1,{4},{5},{6}", r.Left, r.Top, r.Right, r.Bottom, g.Forca, g.Dano, g.DanoDefesa);
    }

    // ---- retratos ----
    static Bitmap Retrato(int W, int H, double escala, Pose p, Color fundo1, Color fundo2)
    {
        var bmp = new Bitmap(W, H, PixelFormat.Format24bppRgb);
        using (var g = Graphics.FromImage(bmp))
        {
            using (var br = new LinearGradientBrush(new Point(0, 0), new Point(0, H), fundo1, fundo2)) g.FillRectangle(br, 0, 0, W, H);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            var hip = new PointF(0, 0);
            var j = Rig.Calcula(p, hip);
            // cabeca no meio, um pouco acima do centro
            g.TranslateTransform(W * 0.47f, H * 0.56f);
            g.ScaleTransform((float)escala, (float)escala);
            g.TranslateTransform(-j.Cabeca.X, -j.Cabeca.Y + 3);
            Rig.Desenha(g, p, hip);
        }
        return bmp;
    }

    // ---- efeitos ----
    static Bitmap NovoEfeito(int W, int H, Action<Graphics> desenho)
    {
        var tmp = new Bitmap(W, H, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(tmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
            desenho(g);
        }
        var bmp = new Bitmap(W, H, PixelFormat.Format24bppRgb);
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                var c = tmp.GetPixel(x, y);
                Color o = Color.White;
                if (c.A >= 110) o = (c.R > 250 && c.G > 250 && c.B > 250) ? Color.FromArgb(248, 248, 248) : Color.FromArgb(c.R, c.G, c.B);
                bmp.SetPixel(x, y, o);
            }
        tmp.Dispose();
        return bmp;
    }

    static Bitmap Onda(int n)
    {
        // ondas sonoras da corneta: arcos ")))" (n = 0 ou 1, para alternar)
        return NovoEfeito(56, 60, g =>
        {
            for (int i = 0; i < 3; i++)
            {
                float r = 12 + i * 9 + n * 4;
                var ret = new RectangleF(10 - r, 30 - r, 2 * r, 2 * r);
                using (var pc = new Pen(Rig.Contorno, 6)) g.DrawArc(pc, ret, -50, 100);
                using (var pa = new Pen(i == 1 ? Rig.Vermelho : Rig.Amarelo, 3.5f)) g.DrawArc(pa, ret, -50, 100);
            }
        });
    }

    static Bitmap Plaft(float escala)
    {
        int W = (int)(110 * escala), H = (int)(90 * escala);
        return NovoEfeito(W, H, g =>
        {
            var c = new PointF(W / 2f, H * 0.55f);
            var pts = new List<PointF>();
            var rnd = new Random(7);
            for (int i = 0; i < 24; i++)
            {
                double a = i * Math.PI * 2 / 24;
                double r = (i % 2 == 0 ? 0.48 : 0.3 + rnd.NextDouble() * 0.06);
                pts.Add(new PointF(c.X + (float)(Math.Cos(a) * r * W), c.Y + (float)(Math.Sin(a) * r * H * 1.0)));
            }
            using (var pc = new Pen(Rig.Contorno, 4)) g.DrawPolygon(pc, pts.ToArray());
            using (var br = new SolidBrush(Rig.Amarelo)) g.FillPolygon(br, pts.ToArray());
            using (var f = new Font("Arial Black", 17 * escala, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var path = new GraphicsPath())
            {
                var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                path.AddString("PLAFT!", f.FontFamily, (int)FontStyle.Bold, f.Size, c, sf);
                using (var pc = new Pen(Rig.Contorno, 3)) g.DrawPath(pc, path);
                using (var br = new SolidBrush(Rig.Vermelho)) g.FillPath(br, path);
            }
        });
    }

    // ---- sons (22050 Hz, mono, 8 bits, como os do jogo) ----
    static void GravaWav(string arq, double[] amostras)
    {
        const int taxa = 22050;
        using (var w = new BinaryWriter(File.Create(arq)))
        {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + amostras.Length);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1); w.Write((short)1);
            w.Write(taxa); w.Write(taxa); w.Write((short)1); w.Write((short)8);
            w.Write(Encoding.ASCII.GetBytes("data")); w.Write(amostras.Length);
            foreach (var a in amostras) w.Write((byte)Math.Max(0, Math.Min(255, 128 + a * 110)));
        }
    }

    static double[] Guincho()
    {
        // dois apertos do brinquedo de borracha: "fiu-fiu" subindo e descendo
        int n = (int)(22050 * 0.32);
        var s = new double[n]; double fase = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / 22050.0, u = (t % 0.16) / 0.16;
            double f = 1500 + 1300 * Math.Sin(Math.PI * u);
            fase += 2 * Math.PI * f / 22050;
            double env = Math.Sin(Math.PI * u) * (t < 0.16 ? 1 : 0.8);
            s[i] = env * (0.7 * Math.Sin(fase) + 0.3 * Math.Sin(2 * fase));
        }
        return s;
    }

    static double[] Zumbido()
    {
        // chicharra paralisadora: zumbido aspero com tremolo
        int n = (int)(22050 * 0.7);
        var s = new double[n]; double fase = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / 22050.0;
            double f = 330 + 25 * Math.Sin(2 * Math.PI * 9 * t);
            fase += 2 * Math.PI * f / 22050;
            double quadrada = Math.Sin(fase) > 0 ? 1 : -1;
            double env = Math.Min(1, t / 0.03) * Math.Min(1, (0.7 - t) / 0.1) * (0.75 + 0.25 * Math.Sin(2 * Math.PI * 22 * t));
            s[i] = env * (0.55 * quadrada + 0.45 * Math.Sin(3 * fase));
        }
        return s;
    }

    static void Main(string[] args)
    {
        string jogo = args.Length > 0 ? args[0] : ".";
        string previa = args.Length > 1 ? args[1] : null;
        var poses = Poses();
        var quadros = new List<Quadro>();
        for (int i = 0; i < poses.Count; i++) quadros.Add(Renderiza(poses[i], i + 1));

        // folha: quadros separados por uma coluna preta
        int largura = 0; foreach (var q in quadros) largura += q.Img.Width + 1;
        using (var folha = new Bitmap(largura, AlturaFolha, PixelFormat.Format24bppRgb))
        {
            using (var g = Graphics.FromImage(folha))
            {
                g.Clear(Color.White);
                int x = 0;
                foreach (var q in quadros)
                {
                    g.DrawImageUnscaled(q.Img, x, 0);
                    x += q.Img.Width;
                    g.DrawLine(Pens.Black, x, 0, x, AlturaFolha);
                    x += 1;
                }
            }
            folha.Save(Path.Combine(jogo, "Lutadores", "C16.bmp"), ImageFormat.Bmp);
            if (previa != null) folha.Save(previa, ImageFormat.Png);
        }

        // secoes do C16.ini
        var sb = new StringBuilder();
        sb.AppendLine("[CentroX]");
        sb.AppendLine("; quadro=deslocamento X do centro do sprite (onde fica a posicao do lutador)");
        for (int i = 0; i < quadros.Count; i++) sb.AppendLine((i + 1) + "=" + quadros[i].CentroX);
        sb.AppendLine();
        sb.AppendLine("[Corpo]");
        sb.AppendLine("; quadro=x1,y1,x2,y2 (caixa do corpo, relativa aos pes; y a partir do topo do sprite)");
        for (int i = 0; i < quadros.Count; i++)
        {
            var c = quadros[i].Corpo;
            sb.AppendLine(string.Format("{0}={1},{2},{3},{4}", i + 1, c.Left, c.Top, c.Right, c.Bottom));
        }
        sb.AppendLine();
        sb.AppendLine("[Ataque]");
        sb.AppendLine("; acao.quadroAcao=x1,y1,x2,y2,ativo,forca,dano,danoDefesa");
        sb.AppendLine("; .f1 / .f2 no fim da chave = vale so quando a forca do golpe e 1 / 2");
        foreach (var gp in Golpes()) sb.AppendLine(gp.Chave + "=" + Caixa(quadros[gp.Quadro - 1], gp));
        Console.Write(sb.ToString());

        // retratos: normal (3/4), apanhando e o grande
        var rosto = new Pose(5, -8, 10, 10, 15, 10, -14, -18, 22, -28);
        Color f1 = Color.FromArgb(150, 190, 230), f2 = Color.FromArgb(70, 110, 170);
        Retrato(50, 60, 1.75, rosto, f1, f2).Save(Path.Combine(jogo, "Rostos", "R16-a.bmp"), ImageFormat.Bmp);
        Retrato(50, 60, 1.75, rosto.Tronco(-10, -22).Cara(Rosto.Dor), Color.FromArgb(230, 160, 150), Color.FromArgb(170, 70, 70))
            .Save(Path.Combine(jogo, "Rostos", "R16-b.bmp"), ImageFormat.Bmp);
        Retrato(96, 126, 2.6, rosto.Tronco(0, -10), f1, f2).Save(Path.Combine(jogo, "Rostos", "R16-c.bmp"), ImageFormat.Bmp);

        // efeitos e sons
        Onda(0).Save(Path.Combine(jogo, "Efeitos", "Efeito-102.bmp"), ImageFormat.Bmp);
        Onda(1).Save(Path.Combine(jogo, "Efeitos", "Efeito-103.bmp"), ImageFormat.Bmp);
        Plaft(0.8f).Save(Path.Combine(jogo, "Efeitos", "Efeito-104.bmp"), ImageFormat.Bmp);
        Plaft(1.2f).Save(Path.Combine(jogo, "Efeitos", "Efeito-105.bmp"), ImageFormat.Bmp);
        GravaWav(Path.Combine(jogo, "Sons", "Som-68.wav"), Guincho());
        GravaWav(Path.Combine(jogo, "Sons", "Som-69.wav"), Zumbido());
    }
}
