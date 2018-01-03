using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _11
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            //ez a segédosztály
            TeruletSzamito szamito = new TeruletSzamito();
            //adatok ; alapján szétszedve egy tömbbe
            string[] adatok = textBox1.Text.Split(';');
            //ha 1 adat van csak
            if (adatok.Length == 1)
            {
                label2.Text = "Négyzet területe = " + szamito.NegyzetTeruletSzamito(adatok[0]);
            }
            else
            {
                label2.Text = "Téglalap területe = " + szamito.TeglalapTeruletSzamito(adatok[0], adatok[1]);
            }
        }
    }

    public class TeruletSzamito{
        public String NegyzetTeruletSzamito(string a)
        {
            //terület számítása, a .00# a helyiértékes kiíráshoz kell
            double result = double.Parse(a)*double.Parse(a);
            return result.ToString(".00#");
        }

        public String TeglalapTeruletSzamito(string a, string b)
        {
            double result = double.Parse(a)*double.Parse(b);
            return result.ToString(".00#");
        }
    }
}
