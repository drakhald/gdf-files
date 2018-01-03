using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _4
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            Console.WriteLine(FontStyle.Bold | FontStyle.Italic);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (checkBox1.Checked)
            {
                //a meglévő stílushoz hozzáadjuk a félkövér stílust (bitenkénti vagy)
                label1.Font = new Font(label1.Font, label1.Font.Style | FontStyle.Bold);
            }
            else
            {
                //bitenkénti vagy "visszavonása"
                label1.Font = new Font(label1.Font, label1.Font.Style & ~FontStyle.Bold);
            }

            if (checkBox2.Checked)
            {
                //a meglévő stílushoz hozzáadjuk a dőlt stílust
                label1.Font = new Font(label1.Font, label1.Font.Style | FontStyle.Italic);
            }
            else
            {
                label1.Font = new Font(label1.Font, label1.Font.Style & ~FontStyle.Italic);
            }

            if (checkBox3.Checked)
            {
                //a meglévő stílushoz hozzáadjuk a aláhúzott stílust
                label1.Font = new Font(label1.Font, label1.Font.Style | FontStyle.Underline);
            }
            else
            {
                label1.Font = new Font(label1.Font, label1.Font.Style & ~FontStyle.Underline);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

    }
}
