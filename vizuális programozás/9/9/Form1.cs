using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _9
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            //textbox feltöltése
            textBox1.AppendText("Ez lett az első sor\r\nEz meg a második\r\nEz itt a harmadik\r\nÉs végül a negyedik");
        }

        private void button1_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void button3_Click(object sender, EventArgs e)
        {
            //ha nagyobb, mint a minimum, lehet csökkenteni (én belevettem a 0 méretű állapotot is)
            if (textBox1.Height >= 10)
            {
                textBox1.Height = textBox1.Height - 10;
            }
            else
            {
                textBox1.Height = 100;
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (button2.Text == "Sortörés nélkül")
            {
                button2.Text = "Sortöréssel";
                textBox1.Multiline = false;
            }
            else
            {
                button2.Text = "Sortörés nélkül";
                textBox1.Multiline = true;
            }

        }
    }
}
