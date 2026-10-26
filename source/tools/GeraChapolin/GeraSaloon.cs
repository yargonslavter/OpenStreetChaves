// GeraSaloon.cs - desenha o cenario 13 (Saloon do Velho Oeste), o cenario do Chapolin.
//
// Gera, a partir da pasta do jogo passada como argumento:
//   Cenarios/Cenario-13.bmp              fundo (600x320; o chao dos lutadores fica em y = 300)
//   Animacoes/Anim-79..97.bmp            objetos que quebram (inteiro e quebrado), lampioes e feno
//   Efeitos/Efeito-106..111.bmp          pedacos de madeira e de vidro
//   Sons/Som-70.wav, Som-71.wav          vidro e madeira quebrando
// As posicoes dos objetos, que o Dados/Cenarios/Cenario-13.ini usa, sao as constantes de Objetos().
//
// Compilar (Windows, .NET Framework):
//   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe -r:System.Drawing.dll GeraSaloon.cs
// Usar:
//   GeraSaloon.exe <pasta do jogo> [previa.png]
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

static class Saloon
{
    const int W = 600, H = 320;

    static readonly Color Contorno = Color.FromArgb(45, 25, 15);
    static readonly Color Madeira = Color.FromArgb(150, 90, 45);
    static readonly Color MadeiraClara = Color.FromArgb(190, 125, 65);
    static readonly Color MadeiraEscura = Color.FromArgb(95, 55, 28);
    static readonly Color Vidro = Color.FromArgb(170, 215, 225);

    static Random rnd = new Random(13);

    static Color Mistura(Color a, Color b, double t)
    {
        return Color.FromArgb((int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));
    }
    static Color Tom(Color c, double f)
    {
        return Color.FromArgb(Math.Min(255, (int)(c.R * f)), Math.Min(255, (int)(c.G * f)), Math.Min(255, (int)(c.B * f)));
    }

    static Graphics Novo(Bitmap b)
    {
        var g = Graphics.FromImage(b);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
        return g;
    }

    // tabuas de madeira (verticais ou horizontais) com veios
    static void Tabuas(Graphics g, RectangleF r, Color baseCor, float largura, bool verticais, int semente)
    {
        var rr = new Random(semente);
        var st = g.Save();
        g.SetClip(r);
        int n = (int)Math.Ceiling((verticais ? r.Width : r.Height) / largura);
        for (int i = 0; i < n; i++)
        {
            Color c = Tom(baseCor, 0.85 + rr.NextDouble() * 0.3);
            RectangleF t = verticais ? new RectangleF(r.X + i * largura, r.Y, largura, r.Height)
                                     : new RectangleF(r.X, r.Y + i * largura, r.Width, largura);
            using (var br = new LinearGradientBrush(t, Tom(c, 1.08), Tom(c, 0.9), verticais ? 0f : 90f)) g.FillRectangle(br, t);
            // veios
            using (var pv = new Pen(Color.FromArgb(60, Tom(c, 0.6)), 1))
                for (int k = 0; k < 3; k++)
                {
                    float o = (float)(rr.NextDouble() * largura);
                    if (verticais) g.DrawBezier(pv, t.X + o, t.Y, t.X + o + 2, t.Y + t.Height / 3, t.X + o - 2, t.Y + 2 * t.Height / 3, t.X + o, t.Bottom);
                    else g.DrawBezier(pv, t.X, t.Y + o, t.X + t.Width / 3, t.Y + o + 1.5f, t.X + 2 * t.Width / 3, t.Y + o - 1.5f, t.Right, t.Y + o);
                }
            using (var pj = new Pen(Color.FromArgb(150, Tom(c, 0.45)), 1.2f))
                if (verticais) g.DrawLine(pj, t.Right, t.Y, t.Right, t.Bottom); else g.DrawLine(pj, t.X, t.Bottom, t.Right, t.Bottom);
            // pregos
            using (var bp = new SolidBrush(Color.FromArgb(120, 40, 30, 25)))
                if (verticais) { g.FillEllipse(bp, t.X + largura / 2 - 1, r.Y + 6, 2, 2); g.FillEllipse(bp, t.X + largura / 2 - 1, r.Bottom - 8, 2, 2); }
        }
        g.Restore(st);
    }

    static void Retangulo(Graphics g, RectangleF r, Color c, float borda = 2)
    {
        using (var br = new SolidBrush(c)) g.FillRectangle(br, r);
        using (var p = new Pen(Contorno, borda)) g.DrawRectangle(p, r.X, r.Y, r.Width, r.Height);
    }

    static void Garrafa(Graphics g, float x, float base_, float alt, Color cor, bool rotulo = true)
    {
        float larg = alt * 0.32f;
        var corpo = new RectangleF(x - larg / 2, base_ - alt * 0.62f, larg, alt * 0.62f);
        var gargalo = new RectangleF(x - larg * 0.18f, base_ - alt, larg * 0.36f, alt * 0.42f);
        using (var path = new GraphicsPath())
        {
            path.AddRectangle(gargalo);
            path.AddEllipse(corpo.X, corpo.Y - larg * 0.35f, corpo.Width, larg * 0.7f);
            path.AddRectangle(corpo);
            path.FillMode = FillMode.Winding;
            using (var p = new Pen(Color.FromArgb(200, Contorno), 1.5f)) g.DrawPath(p, path);
            using (var br = new LinearGradientBrush(new PointF(corpo.X, 0), new PointF(corpo.Right + 0.5f, 0), Tom(cor, 1.4), Tom(cor, 0.6))) g.FillPath(br, path);
        }
        if (rotulo)
            using (var br = new SolidBrush(Color.FromArgb(235, 225, 190))) g.FillRectangle(br, corpo.X + 1, corpo.Y + corpo.Height * 0.3f, corpo.Width - 2, corpo.Height * 0.32f);
        using (var br = new SolidBrush(Color.FromArgb(150, 255, 255, 255))) g.FillRectangle(br, corpo.X + larg * 0.18f, corpo.Y + 2, 1.5f, corpo.Height * 0.6f);
    }

    // ---- fundo ----
    static Bitmap Fundo()
    {
        var b = new Bitmap(W, H, PixelFormat.Format24bppRgb);
        using (var g = Novo(b))
        {
            // parede de tabuas, mais escura em cima (sombra do teto)
            Tabuas(g, new RectangleF(0, 0, W, 240), Madeira, 22, true, 1);
            using (var br = new LinearGradientBrush(new PointF(0, 0), new PointF(0, 120), Color.FromArgb(150, 20, 10, 5), Color.FromArgb(0, 20, 10, 5)))
                g.FillRectangle(br, 0, 0, W, 120);
            // viga do teto e rodape
            Retangulo(g, new RectangleF(-2, -2, W + 4, 16), MadeiraEscura);
            Tabuas(g, new RectangleF(0, 200, W, 40), MadeiraEscura, 10, false, 2);
            using (var p = new Pen(Contorno, 2)) { g.DrawLine(p, 0, 200, W, 200); g.DrawLine(p, 0, 240, W, 240); }
            // chao de tabuas em perspectiva
            Tabuas(g, new RectangleF(0, 240, W, 80), Color.FromArgb(125, 78, 40), 9, false, 3);
            using (var p = new Pen(Color.FromArgb(90, 40, 20, 10), 1))
                for (int i = -12; i <= 24; i++)
                    g.DrawLine(p, 300 + i * 25, 240, 300 + i * 60, 320);
            using (var br = new LinearGradientBrush(new PointF(0, 240), new PointF(0, 262), Color.FromArgb(120, 0, 0, 0), Color.FromArgb(0, 0, 0, 0)))
                g.FillRectangle(br, 0, 240, W, 22);

            // vao da janela (o vidro e um objeto): paisagem do deserto
            var jan = new RectangleF(22, 62, 112, 108);
            using (var br = new LinearGradientBrush(jan, Color.FromArgb(120, 175, 235), Color.FromArgb(250, 205, 140), 90f)) g.FillRectangle(br, jan);
            var st = g.Save(); g.SetClip(jan);
            using (var br = new SolidBrush(Color.FromArgb(255, 235, 140))) g.FillEllipse(br, 95, 78, 22, 22);
            using (var br = new SolidBrush(Color.FromArgb(190, 105, 60)))
                g.FillPolygon(br, new[] { new PointF(20, 150), new PointF(40, 120), new PointF(75, 118), new PointF(85, 150) });
            using (var br = new SolidBrush(Color.FromArgb(215, 140, 80)))
                g.FillRectangle(br, 20, 145, 120, 30);
            Cacto(g, 112, 152, 18);
            Cacto(g, 52, 160, 12);
            g.Restore(st);
            // moldura da janela
            using (var p = new Pen(MadeiraEscura, 7)) g.DrawRectangle(p, jan.X - 3, jan.Y - 3, jan.Width + 6, jan.Height + 6);
            using (var p = new Pen(Contorno, 2)) g.DrawRectangle(p, jan.X - 7, jan.Y - 7, jan.Width + 14, jan.Height + 14);
            Retangulo(g, new RectangleF(jan.X - 12, jan.Bottom + 6, jan.Width + 24, 8), MadeiraClara);

            // cartaz de procurado
            var cart = new RectangleF(150, 70, 52, 68);
            using (var br = new SolidBrush(Color.FromArgb(225, 205, 160))) g.FillRectangle(br, cart);
            using (var p = new Pen(Color.FromArgb(120, 90, 50), 1.5f)) g.DrawRectangle(p, cart.X, cart.Y, cart.Width, cart.Height);
            using (var f = new Font("Georgia", 7.5f, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var f2 = new Font("Georgia", 9, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var br = new SolidBrush(Color.FromArgb(70, 40, 20)))
            {
                var sf = new StringFormat { Alignment = StringAlignment.Center };
                g.DrawString("PROCURA-SE", f, br, cart.X + cart.Width / 2, cart.Y + 3, sf);
                g.DrawString("$ 1000", f2, br, cart.X + cart.Width / 2, cart.Bottom - 14, sf);
            }
            using (var br = new SolidBrush(Color.FromArgb(150, 110, 70))) g.FillEllipse(br, cart.X + 15, cart.Y + 16, 22, 26);
            using (var br = new SolidBrush(Color.FromArgb(70, 45, 25))) { g.FillRectangle(br, cart.X + 11, cart.Y + 17, 30, 5); g.FillRectangle(br, cart.X + 17, cart.Y + 13, 18, 6); }
            using (var br = new SolidBrush(Color.FromArgb(60, 35, 20))) g.FillRectangle(br, cart.X + 18, cart.Y + 33, 16, 3);
            using (var br = new SolidBrush(Color.FromArgb(160, 140, 140, 140))) g.FillEllipse(br, cart.X + cart.Width / 2 - 2, cart.Y + 1, 4, 4);

            // espelho e prateleiras atras do balcao
            var esp = new RectangleF(212, 52, 210, 118);
            Retangulo(g, new RectangleF(esp.X - 8, esp.Y - 8, esp.Width + 16, esp.Height + 16), MadeiraEscura);
            using (var br = new LinearGradientBrush(esp, Color.FromArgb(150, 160, 150), Color.FromArgb(90, 100, 95), 60f)) g.FillRectangle(br, esp);
            using (var br = new SolidBrush(Color.FromArgb(50, 255, 255, 255)))
            { g.FillPolygon(br, new[] { new PointF(esp.X + 20, esp.Y), new PointF(esp.X + 50, esp.Y), new PointF(esp.X + 10, esp.Bottom), new PointF(esp.X - 10 + 1, esp.Bottom) }); }
            for (int k = 0; k < 2; k++)
            {
                float py = esp.Y + 48 + k * 52;
                Retangulo(g, new RectangleF(esp.X - 4, py, esp.Width + 8, 6), MadeiraClara, 1.5f);
                var cores = new[] { Color.FromArgb(40, 110, 50), Color.FromArgb(120, 60, 20), Color.FromArgb(150, 30, 30), Color.FromArgb(60, 60, 140), Color.FromArgb(160, 130, 40) };
                for (float bx = esp.X + 10; bx < esp.Right - 8; bx += 13 + (float)rnd.NextDouble() * 6)
                    Garrafa(g, bx, py, 26 + (float)rnd.NextDouble() * 10, cores[rnd.Next(cores.Length)], rnd.Next(2) == 0);
            }
            // placa SALOON
            var placa = new RectangleF(232, 18, 124, 26);
            Retangulo(g, placa, Color.FromArgb(120, 30, 25));
            using (var f = new Font("Georgia", 19, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var path = new GraphicsPath())
            {
                var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                path.AddString("SALOON", f.FontFamily, (int)FontStyle.Bold, f.Size, new PointF(placa.X + placa.Width / 2, placa.Y + placa.Height / 2 + 1), sf);
                using (var p = new Pen(Contorno, 3)) g.DrawPath(p, path);
                using (var br = new SolidBrush(Color.FromArgb(250, 210, 60))) g.FillPath(br, path);
            }
            // balcao
            var balc = new RectangleF(190, 176, 250, 66);
            Tabuas(g, balc, Color.FromArgb(120, 65, 30), 25, true, 4);
            using (var p = new Pen(Contorno, 2)) g.DrawRectangle(p, balc.X, balc.Y, balc.Width, balc.Height);
            for (int k = 0; k < 5; k++)
            {
                var pn = new RectangleF(balc.X + 10 + k * 47, balc.Y + 14, 38, 40);
                using (var p = new Pen(Color.FromArgb(110, 40, 20, 10), 2)) g.DrawRectangle(p, pn.X, pn.Y, pn.Width, pn.Height);
                using (var p = new Pen(Color.FromArgb(60, 255, 220, 170), 1)) g.DrawLine(p, pn.X + 2, pn.Y + 2, pn.Right - 2, pn.Y + 2);
            }
            Retangulo(g, new RectangleF(balc.X - 6, balc.Y - 7, balc.Width + 12, 9), Color.FromArgb(80, 40, 20));
            using (var p = new Pen(Color.FromArgb(200, 170, 90), 3)) g.DrawLine(p, balc.X, balc.Bottom - 6, balc.Right, balc.Bottom - 6);

            // portas de vaivem: luz de fora pelo vao
            var vao = new RectangleF(452, 104, 50, 136);
            using (var br = new LinearGradientBrush(vao, Color.FromArgb(255, 230, 170), Color.FromArgb(235, 180, 110), 90f)) g.FillRectangle(br, vao);
            using (var p = new Pen(MadeiraEscura, 6)) g.DrawRectangle(p, vao.X - 3, vao.Y - 3, vao.Width + 6, vao.Height + 3);
            for (int k = 0; k < 2; k++)
            {
                var folha = new RectangleF(vao.X + k * 25 + 1, 146, 23, 62);
                Tabuas(g, folha, MadeiraClara, 23, true, 5 + k);
                using (var p = new Pen(Contorno, 1.5f)) g.DrawRectangle(p, folha.X, folha.Y, folha.Width, folha.Height);
                using (var p = new Pen(Color.FromArgb(120, 60, 30, 15), 1))
                    for (float ly = folha.Y + 6; ly < folha.Bottom - 4; ly += 6) g.DrawLine(p, folha.X + 3, ly, folha.Right - 3, ly + 2);
            }

            // ferradura e roda de carroca na parede
            using (var p = new Pen(Color.FromArgb(90, 90, 95), 4)) g.DrawArc(p, 165, 158, 18, 20, 200, 300);
            Roda(g, 560, 75, 26);

            // lampioes: os suportes (as chamas sao animacao)
            Suporte(g, 205, 112);
            Suporte(g, 438, 112);
        }
        return b;
    }

    static void Cacto(Graphics g, float x, float base_, float alt)
    {
        using (var p = new Pen(Color.FromArgb(60, 120, 60), alt * 0.28f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        {
            g.DrawLine(p, x, base_, x, base_ - alt);
            g.DrawLine(p, x - alt * 0.35f, base_ - alt * 0.45f, x - alt * 0.35f, base_ - alt * 0.75f);
            g.DrawLine(p, x - alt * 0.35f, base_ - alt * 0.45f, x, base_ - alt * 0.45f);
            g.DrawLine(p, x + alt * 0.35f, base_ - alt * 0.55f, x + alt * 0.35f, base_ - alt * 0.85f);
            g.DrawLine(p, x + alt * 0.35f, base_ - alt * 0.55f, x, base_ - alt * 0.55f);
        }
    }

    static void Roda(Graphics g, float cx, float cy, float r)
    {
        using (var p = new Pen(Contorno, 6)) g.DrawEllipse(p, cx - r, cy - r, 2 * r, 2 * r);
        using (var p = new Pen(MadeiraClara, 4)) g.DrawEllipse(p, cx - r, cy - r, 2 * r, 2 * r);
        using (var p = new Pen(MadeiraEscura, 2.5f))
            for (int i = 0; i < 8; i++)
            {
                double a = i * Math.PI / 4;
                g.DrawLine(p, cx, cy, cx + (float)Math.Cos(a) * (r - 2), cy + (float)Math.Sin(a) * (r - 2));
            }
        using (var br = new SolidBrush(MadeiraEscura)) g.FillEllipse(br, cx - 5, cy - 5, 10, 10);
    }

    static void Suporte(Graphics g, float x, float y)
    {
        using (var p = new Pen(Color.FromArgb(60, 50, 45), 3)) { g.DrawLine(p, x, y, x + 10, y); g.DrawLine(p, x + 10, y, x + 10, y - 6); }
        // base do lampiao
        using (var br = new SolidBrush(Color.FromArgb(70, 60, 55))) g.FillRectangle(br, x + 4, y - 8, 12, 4);
        using (var br = new SolidBrush(Color.FromArgb(90, 255, 220, 140))) g.FillEllipse(br, x - 20, y - 50, 60, 55);
    }

    // ---- objetos (desenhados sobre branco, que o jogo torna transparente) ----
    delegate void Desenho(Graphics g);

    static Bitmap Objeto(int w, int h, Desenho d)
    {
        var tmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Novo(tmp)) d(g);
        var bmp = new Bitmap(w, h, PixelFormat.Format24bppRgb);
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                var c = tmp.GetPixel(x, y);
                Color o = Color.White;
                if (c.A >= 100)
                {
                    // compoe sobre um fundo neutro para nao virar branco puro (transparente)
                    double a = c.A / 255.0;
                    o = Color.FromArgb((int)(c.R * a + 128 * (1 - a)), (int)(c.G * a + 100 * (1 - a)), (int)(c.B * a + 80 * (1 - a)));
                    if (o.R > 250 && o.G > 250 && o.B > 250) o = Color.FromArgb(248, 248, 248);
                }
                bmp.SetPixel(x, y, o);
            }
        tmp.Dispose();
        return bmp;
    }

    // janela de vidro (sobre o vao do fundo)
    static Bitmap Janela(bool quebrada)
    {
        return Objeto(112, 108, g =>
        {
            if (!quebrada)
            {
                // o jogo so tem uma cor transparente: o vidro aparece pelos reflexos e pelas travessas
                using (var br = new SolidBrush(Color.FromArgb(230, 225, 240, 245)))
                {
                    g.FillPolygon(br, new[] { new PointF(10, 0), new PointF(30, 0), new PointF(0, 40), new PointF(0, 14) });
                    g.FillPolygon(br, new[] { new PointF(70, 108), new PointF(84, 108), new PointF(112, 70), new PointF(112, 52) });
                }
                using (var p = new Pen(MadeiraEscura, 5)) { g.DrawLine(p, 56, 0, 56, 108); g.DrawLine(p, 0, 54, 112, 54); }
            }
            else
            {
                // so cacos presos na moldura
                using (var br = new SolidBrush(Color.FromArgb(150, Vidro)))
                {
                    g.FillPolygon(br, new[] { new PointF(0, 0), new PointF(30, 0), new PointF(12, 16), new PointF(0, 30) });
                    g.FillPolygon(br, new[] { new PointF(112, 0), new PointF(92, 0), new PointF(104, 22) });
                    g.FillPolygon(br, new[] { new PointF(0, 108), new PointF(0, 80), new PointF(18, 98), new PointF(26, 108) });
                    g.FillPolygon(br, new[] { new PointF(112, 108), new PointF(80, 108), new PointF(100, 90), new PointF(112, 76) });
                }
                using (var p = new Pen(MadeiraEscura, 5)) { g.DrawLine(p, 56, 0, 56, 40); g.DrawLine(p, 0, 54, 30, 54); g.DrawLine(p, 56, 108, 56, 80); }
            }
        });
    }

    static Bitmap Garrafas(bool quebradas, int semente)
    {
        return Objeto(60, 40, g =>
        {
            var r = new Random(semente);
            var cores = new[] { Color.FromArgb(40, 120, 50), Color.FromArgb(130, 70, 25), Color.FromArgb(160, 30, 30), Color.FromArgb(150, 120, 40) };
            for (int i = 0; i < 4; i++)
            {
                float x = 9 + i * 14, alt = 26 + r.Next(10);
                var cor = cores[r.Next(cores.Length)];
                if (!quebradas) Garrafa(g, x, 39, alt, cor);
                else
                {
                    // fundo da garrafa com a borda quebrada
                    float larg = alt * 0.32f;
                    var pts = new[] { new PointF(x - larg / 2, 39), new PointF(x - larg / 2, 31), new PointF(x - 1, 34), new PointF(x + 1, 29), new PointF(x + larg / 2, 33), new PointF(x + larg / 2, 39) };
                    using (var p = new Pen(Contorno, 1.5f)) g.DrawPolygon(p, pts);
                    using (var br = new SolidBrush(Tom(cor, 1.1))) g.FillPolygon(br, pts);
                }
            }
            if (quebradas)
                using (var br = new SolidBrush(Color.FromArgb(160, 150, 90, 40))) g.FillEllipse(br, 2, 34, 56, 6); // bebida derramada
        });
    }

    static Bitmap Lustre(bool quebrado)
    {
        // corrente comprida: o aro fica abaixo da placa SALOON
        return Objeto(80, 94, g =>
        {
            using (var p = new Pen(Color.FromArgb(60, 55, 50), 2)) g.DrawLine(p, 40, 0, 40, 52);
            g.TranslateTransform(0, 30);
            if (!quebrado)
            {
                using (var p = new Pen(Contorno, 6)) g.DrawEllipse(p, 8, 24, 64, 18);
                using (var p = new Pen(MadeiraClara, 4)) g.DrawEllipse(p, 8, 24, 64, 18);
                using (var p = new Pen(Color.FromArgb(60, 55, 50), 1.5f)) { g.DrawLine(p, 40, 22, 10, 32); g.DrawLine(p, 40, 22, 70, 32); g.DrawLine(p, 40, 22, 40, 40); }
                for (int i = 0; i < 5; i++)
                {
                    float x = 12 + i * 14, y = 30 + (i % 2) * 6;
                    using (var br = new SolidBrush(Color.FromArgb(240, 235, 210))) g.FillRectangle(br, x - 2, y - 10, 5, 10);
                    using (var br = new SolidBrush(Color.FromArgb(255, 200, 60))) g.FillEllipse(br, x - 2.5f, y - 17, 6, 8);
                    using (var br = new SolidBrush(Color.FromArgb(255, 250, 200))) g.FillEllipse(br, x - 1, y - 15, 3, 5);
                }
                // pingentes de vidro
                for (int i = 0; i < 7; i++)
                    using (var br = new SolidBrush(Color.FromArgb(200, Vidro))) g.FillPolygon(br, new[] { new PointF(12 + i * 9.5f, 40), new PointF(15 + i * 9.5f, 40), new PointF(13.5f + i * 9.5f, 52) });
            }
            else
            {
                // aro torto pendurado por um lado
                var st = g.Save(); g.TranslateTransform(40, 22); g.RotateTransform(28);
                using (var p = new Pen(Contorno, 6)) g.DrawEllipse(p, -32, 4, 64, 18);
                using (var p = new Pen(MadeiraClara, 4)) g.DrawEllipse(p, -32, 4, 64, 18);
                g.Restore(st);
                using (var br = new SolidBrush(Color.FromArgb(240, 235, 210))) { g.FillRectangle(br, 52, 34, 4, 7); g.FillRectangle(br, 22, 20, 4, 6); }
            }
        });
    }

    static void Mesa(Graphics g, bool quebrada)
    {
        if (!quebrada)
        {
            // cadeiras dos dois lados
            Cadeira(g, 6, 18, false);
            Cadeira(g, 92, 18, true);
            // tampo e pe
            Retangulo(g, new RectangleF(52, 26, 10, 30), MadeiraEscura, 1.5f);
            using (var p = new Pen(Contorno, 2)) g.DrawEllipse(p, 18, 15, 78, 16);
            using (var br = new SolidBrush(Madeira)) g.FillEllipse(br, 18, 15, 78, 16);
            using (var br = new SolidBrush(MadeiraClara)) g.FillEllipse(br, 24, 16, 66, 10);
            Retangulo(g, new RectangleF(38, 56, 38, 5), MadeiraEscura, 1.5f);
            // cartas de baralho e copo
            using (var br = new SolidBrush(Color.FromArgb(245, 245, 235))) { g.FillRectangle(br, 40, 17, 9, 5); g.FillRectangle(br, 52, 18, 9, 5); }
            using (var br = new SolidBrush(Color.FromArgb(200, 40, 40))) g.FillRectangle(br, 43, 18, 2, 2);
            Garrafa(g, 72, 22, 16, Color.FromArgb(130, 70, 25), false);
        }
        else
        {
            // tampo partido no chao e pernas soltas
            using (var p = new Pen(Contorno, 2))
            using (var br = new SolidBrush(Madeira))
            {
                var a = new[] { new PointF(14, 52), new PointF(56, 40), new PointF(60, 50), new PointF(18, 61) };
                var b = new[] { new PointF(62, 44), new PointF(100, 50), new PointF(98, 60), new PointF(60, 55) };
                g.FillPolygon(br, a); g.DrawPolygon(p, a); g.FillPolygon(br, b); g.DrawPolygon(p, b);
            }
            using (var p = new Pen(MadeiraEscura, 4) { StartCap = LineCap.Round, EndCap = LineCap.Round }) { g.DrawLine(p, 30, 60, 48, 56); g.DrawLine(p, 76, 61, 92, 58); g.DrawLine(p, 104, 58, 110, 46); }
            using (var br = new SolidBrush(Color.FromArgb(245, 245, 235))) { g.FillRectangle(br, 40, 57, 9, 4); g.FillRectangle(br, 82, 53, 9, 4); }
        }
    }

    static void Cadeira(Graphics g, float x, float y, bool espelha)
    {
        float s = espelha ? -1 : 1, ox = espelha ? x + 22 : x;
        using (var p = new Pen(Contorno, 4.5f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        using (var pm = new Pen(MadeiraClara, 2.5f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
            foreach (var pen in new[] { p, pm })
            {
                g.DrawLine(pen, ox, y, ox, y + 42);                       // encosto e perna de tras
                g.DrawLine(pen, ox, y + 24, ox + 20 * s, y + 24);         // assento
                g.DrawLine(pen, ox + 20 * s, y + 24, ox + 20 * s, y + 42); // perna da frente
                g.DrawLine(pen, ox, y + 6, ox + 3 * s, y + 6);
            }
    }

    static Bitmap MesaImg(bool q) { return Objeto(118, 64, g => Mesa(g, q)); }

    static Bitmap Barril(bool quebrado)
    {
        return Objeto(50, 62, g =>
        {
            if (!quebrado)
            {
                var r = new RectangleF(4, 4, 42, 56);
                using (var path = new GraphicsPath())
                {
                    path.AddBezier(r.X + 4, r.Y, r.X - 3, r.Y + 20, r.X - 3, r.Y + 36, r.X + 4, r.Bottom);
                    path.AddLine(r.X + 4, r.Bottom, r.Right - 4, r.Bottom);
                    path.AddBezier(r.Right - 4, r.Bottom, r.Right + 3, r.Y + 36, r.Right + 3, r.Y + 20, r.Right - 4, r.Y);
                    path.CloseFigure();
                    using (var br = new LinearGradientBrush(new PointF(r.X - 3, 0), new PointF(r.Right + 3, 0), MadeiraEscura, MadeiraClara)) g.FillPath(br, path);
                    var st = g.Save(); g.SetClip(path);
                    using (var p = new Pen(Color.FromArgb(100, 50, 25, 10), 1)) for (float x = r.X + 6; x < r.Right; x += 7) g.DrawLine(p, x, r.Y, x, r.Bottom);
                    using (var p = new Pen(Color.FromArgb(70, 70, 75), 4)) { g.DrawLine(p, 0, r.Y + 12, 50, r.Y + 12); g.DrawLine(p, 0, r.Bottom - 12, 50, r.Bottom - 12); }
                    g.Restore(st);
                    using (var p = new Pen(Contorno, 2)) g.DrawPath(p, path);
                }
                using (var p = new Pen(Contorno, 1.5f)) using (var br = new SolidBrush(Madeira)) { g.FillEllipse(br, 8, 1, 34, 8); g.DrawEllipse(p, 8, 1, 34, 8); }
                using (var f = new Font("Georgia", 9, FontStyle.Bold, GraphicsUnit.Pixel)) using (var br = new SolidBrush(Color.FromArgb(40, 20, 10)))
                    g.DrawString("XXX", f, br, 13, 27);
            }
            else
            {
                // aduelas espalhadas e o aro no chao
                using (var p = new Pen(Contorno, 6) { StartCap = LineCap.Round, EndCap = LineCap.Round })
                using (var pm = new Pen(Madeira, 4) { StartCap = LineCap.Round, EndCap = LineCap.Round })
                    foreach (var pen in new[] { p, pm })
                    { g.DrawLine(pen, 6, 58, 22, 40); g.DrawLine(pen, 18, 58, 26, 46); g.DrawLine(pen, 34, 58, 44, 44); g.DrawLine(pen, 28, 60, 40, 60); }
                using (var p = new Pen(Color.FromArgb(70, 70, 75), 3)) g.DrawEllipse(p, 4, 52, 40, 8);
                using (var br = new SolidBrush(Color.FromArgb(150, 160, 110, 40))) g.FillEllipse(br, 0, 56, 50, 6);
            }
        });
    }

    static Bitmap Piano(bool quebrado)
    {
        return Objeto(96, 92, g =>
        {
            var corpo = new RectangleF(4, 6, 86, 82);
            Tabuas(g, corpo, Color.FromArgb(90, 45, 25), 86, true, 9);
            using (var p = new Pen(Contorno, 2)) g.DrawRectangle(p, corpo.X, corpo.Y, corpo.Width, corpo.Height);
            Retangulo(g, new RectangleF(0, 2, 94, 7), Color.FromArgb(70, 35, 20));
            // painel com partitura
            Retangulo(g, new RectangleF(16, 14, 62, 22), Color.FromArgb(110, 60, 30), 1.5f);
            using (var br = new SolidBrush(Color.FromArgb(240, 235, 215))) g.FillRectangle(br, 34, 16, 26, 17);
            using (var p = new Pen(Color.FromArgb(60, 60, 60), 0.8f)) for (int i = 0; i < 4; i++) g.DrawLine(p, 36, 19 + i * 3.5f, 58, 19 + i * 3.5f);
            // teclado
            var tec = new RectangleF(6, 42, 82, 12);
            Retangulo(g, new RectangleF(2, 40, 90, 6), Color.FromArgb(70, 35, 20), 1.5f);
            using (var br = new SolidBrush(Color.FromArgb(245, 240, 225))) g.FillRectangle(br, tec.X, tec.Y + 4, tec.Width, 8);
            using (var p = new Pen(Color.FromArgb(120, 110, 100), 0.8f)) for (float x = tec.X; x < tec.Right; x += 4) g.DrawLine(p, x, tec.Y + 4, x, tec.Bottom);
            using (var br = new SolidBrush(Color.FromArgb(25, 20, 20))) for (float x = tec.X + 2; x < tec.Right - 2; x += 4) if (((int)(x / 4)) % 7 != 2 && ((int)(x / 4)) % 7 != 6) g.FillRectangle(br, x, tec.Y + 4, 2.4f, 5);
            // pernas
            Retangulo(g, new RectangleF(6, 54, 8, 34), Color.FromArgb(80, 40, 22), 1.5f);
            Retangulo(g, new RectangleF(80, 54, 8, 34), Color.FromArgb(80, 40, 22), 1.5f);
            if (quebrado)
            {
                // teclas arrancadas, rachaduras e tampa caida
                using (var br = new SolidBrush(Color.FromArgb(60, 30, 18))) g.FillPolygon(br, new[] { new PointF(30, 46), new PointF(60, 44), new PointF(54, 54), new PointF(36, 54) });
                using (var p = new Pen(Color.FromArgb(30, 15, 10), 2)) { g.DrawLines(p, new[] { new PointF(20, 10), new PointF(30, 26), new PointF(26, 40) }); g.DrawLines(p, new[] { new PointF(70, 58), new PointF(62, 72), new PointF(70, 86) }); }
                using (var br = new SolidBrush(Color.FromArgb(245, 240, 225))) { g.FillRectangle(br, 20, 82, 6, 3); g.FillRectangle(br, 44, 84, 6, 3); g.FillRectangle(br, 66, 80, 6, 3); }
                using (var br = new SolidBrush(Color.FromArgb(240, 235, 215))) g.FillPolygon(br, new[] { new PointF(36, 84), new PointF(58, 80), new PointF(60, 88), new PointF(38, 90) });
            }
        });
    }

    // ---- animacoes ----
    static Bitmap Chama(int n)
    {
        return Objeto(20, 30, g =>
        {
            // lampiao: vidro, chama
            using (var br = new SolidBrush(Color.FromArgb(150, 210, 230, 230))) g.FillEllipse(br, 3, 6, 14, 20);
            using (var p = new Pen(Color.FromArgb(70, 60, 55), 1.5f)) g.DrawEllipse(p, 3, 6, 14, 20);
            float h = n == 0 ? 12 : 9, dx = n == 0 ? 0 : 1;
            using (var br = new SolidBrush(Color.FromArgb(255, 170, 40))) g.FillEllipse(br, 7 + dx, 22 - h, 6, h);
            using (var br = new SolidBrush(Color.FromArgb(255, 245, 170))) g.FillEllipse(br, 8.5f + dx, 24 - h * 0.6f, 3, h * 0.55f);
            using (var br = new SolidBrush(Color.FromArgb(70, 60, 55))) { g.FillRectangle(br, 4, 25, 12, 4); g.FillRectangle(br, 6, 2, 8, 4); }
        });
    }

    static Bitmap Feno()
    {
        return Objeto(20, 18, g =>
        {
            var r = new Random(5);
            using (var p = new Pen(Color.FromArgb(150, 110, 50), 1.2f))
                for (int i = 0; i < 26; i++)
                {
                    double a = r.NextDouble() * Math.PI * 2, b = a + 1 + r.NextDouble() * 2;
                    float r1 = 4 + (float)r.NextDouble() * 4, r2 = 4 + (float)r.NextDouble() * 4;
                    g.DrawLine(p, 10 + (float)Math.Cos(a) * r1, 9 + (float)Math.Sin(a) * r1, 10 + (float)Math.Cos(b) * r2, 9 + (float)Math.Sin(b) * r2);
                }
        });
    }

    // ---- pedacos (efeitos) ----
    static Bitmap Lasca(int n)
    {
        return Objeto(14, 14, g =>
        {
            var pts = n == 0 ? new[] { new PointF(1, 4), new PointF(12, 2), new PointF(13, 6), new PointF(2, 9) }
                    : n == 1 ? new[] { new PointF(3, 1), new PointF(7, 2), new PointF(11, 13), new PointF(6, 12) }
                    : new[] { new PointF(1, 7), new PointF(7, 3), new PointF(13, 9), new PointF(6, 12) };
            using (var p = new Pen(Contorno, 1.5f)) g.DrawPolygon(p, pts);
            using (var br = new SolidBrush(n == 1 ? MadeiraEscura : MadeiraClara)) g.FillPolygon(br, pts);
        });
    }

    static Bitmap Caco(int n)
    {
        return Objeto(12, 12, g =>
        {
            var pts = n == 0 ? new[] { new PointF(2, 2), new PointF(10, 4), new PointF(4, 10) }
                    : n == 1 ? new[] { new PointF(6, 1), new PointF(10, 10), new PointF(2, 8) }
                    : new[] { new PointF(1, 5), new PointF(9, 2), new PointF(11, 6), new PointF(5, 11) };
            using (var p = new Pen(Color.FromArgb(70, 110, 120), 1.2f)) g.DrawPolygon(p, pts);
            using (var br = new SolidBrush(n == 2 ? Color.FromArgb(70, 140, 70) : Vidro)) g.FillPolygon(br, pts);
            using (var br = new SolidBrush(Color.FromArgb(240, 252, 252))) g.FillRectangle(br, pts[0].X + 1, pts[0].Y + 1, 2, 1);
        });
    }

    // ---- sons (22050 Hz, mono, 8 bits) ----
    static void GravaWav(string arq, double[] s)
    {
        using (var w = new BinaryWriter(File.Create(arq)))
        {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + s.Length);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1); w.Write((short)1);
            w.Write(22050); w.Write(22050); w.Write((short)1); w.Write((short)8);
            w.Write(Encoding.ASCII.GetBytes("data")); w.Write(s.Length);
            foreach (var a in s) w.Write((byte)Math.Max(0, Math.Min(255, 128 + a * 115)));
        }
    }

    static double[] SomVidro()
    {
        // estalo de ruido agudo e tilintar de cacos caindo
        var r = new Random(1); int n = (int)(22050 * 0.6); var s = new double[n];
        double ant = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / 22050.0, ruido = r.NextDouble() * 2 - 1;
            double agudo = ruido - ant; ant = ruido; // filtro passa-alta
            s[i] = agudo * Math.Exp(-t * 18) * 0.8;
        }
        for (int k = 0; k < 14; k++)
        {
            int ini = (int)(22050 * (0.04 + r.NextDouble() * 0.45)); double f = 2500 + r.NextDouble() * 3500;
            for (int i = 0; i < 1200 && ini + i < n; i++)
                s[ini + i] += 0.35 * Math.Sin(2 * Math.PI * f * i / 22050) * Math.Exp(-i / 220.0);
        }
        return s;
    }

    static double[] SomMadeira()
    {
        // pancada grave e estalos de madeira rachando
        var r = new Random(2); int n = (int)(22050 * 0.45); var s = new double[n];
        double lp = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / 22050.0;
            lp += 0.15 * ((r.NextDouble() * 2 - 1) - lp); // ruido abafado
            s[i] = 1.6 * lp * Math.Exp(-t * 9) + 0.5 * Math.Sin(2 * Math.PI * 90 * t) * Math.Exp(-t * 20);
        }
        for (int k = 0; k < 6; k++)
        {
            int ini = (int)(22050 * (0.02 + r.NextDouble() * 0.25));
            for (int i = 0; i < 300 && ini + i < n; i++) s[ini + i] += (r.NextDouble() * 2 - 1) * 0.6 * Math.Exp(-i / 60.0);
        }
        return s;
    }

    static void Main(string[] args)
    {
        string jogo = args.Length > 0 ? args[0] : ".";
        Func<string, string> P = rel => Path.Combine(jogo, rel);
        var fundo = Fundo();
        fundo.Save(P("Cenarios/Cenario-13.bmp"), ImageFormat.Bmp);

        // animacoes 79..97 (A79..A97 no Cenario-13.ini)
        var anim = new List<Bitmap> {
            Janela(false), Janela(true),          // 79, 80
            Garrafas(false, 1), Garrafas(true, 1), // 81, 82
            Garrafas(false, 2), Garrafas(true, 2), // 83, 84
            Lustre(false), Lustre(true),          // 85, 86
            MesaImg(false), MesaImg(true),        // 87, 88
            Barril(false), Barril(true),          // 89, 90
            Barril(false), Barril(true),          // 91, 92
            Piano(false), Piano(true),            // 93, 94
            Chama(0), Chama(1),                   // 95, 96
            Feno(),                               // 97
        };
        for (int i = 0; i < anim.Count; i++) anim[i].Save(P(string.Format("Animacoes/Anim-{0:D2}.bmp", 79 + i)), ImageFormat.Bmp);

        // pedacos: madeira 106..108, vidro 109..111 (S105..S110 no Efeitos.ini)
        for (int i = 0; i < 3; i++) Lasca(i).Save(P(string.Format("Efeitos/Efeito-{0:D3}.bmp", 106 + i)), ImageFormat.Bmp);
        for (int i = 0; i < 3; i++) Caco(i).Save(P(string.Format("Efeitos/Efeito-{0:D3}.bmp", 109 + i)), ImageFormat.Bmp);

        GravaWav(P("Sons/Som-70.wav"), SomVidro());
        GravaWav(P("Sons/Som-71.wav"), SomMadeira());

        // previa: fundo com os objetos inteiros nas posicoes do .ini
        if (args.Length > 1)
        {
            var pos = new[] { new Point(22, 62), new Point(222, 137), new Point(352, 137), new Point(355, 14), new Point(48, 222),
                              new Point(176, 224), new Point(392, 224), new Point(502, 150), new Point(200, 82), new Point(433, 82) };
            int[] idx = { 0, 2, 4, 6, 8, 10, 12, 14, 16, 16 };
            using (var prev = new Bitmap(fundo))
            using (var g = Graphics.FromImage(prev))
            {
                var ia = new ImageAttributes(); ia.SetColorKey(Color.White, Color.White);
                for (int i = 0; i < pos.Length; i++)
                {
                    var im = anim[idx[i]];
                    g.DrawImage(im, new Rectangle(pos[i].X, pos[i].Y, im.Width, im.Height), 0, 0, im.Width, im.Height, GraphicsUnit.Pixel, ia);
                }
                prev.Save(args[1], ImageFormat.Png);
            }
        }
    }
}
