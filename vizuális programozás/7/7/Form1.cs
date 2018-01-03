using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _7
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            //label1 beállításai
            label1.BackColor = Color.White;
            label1.ForeColor = Color.Red;
            label1.Font = new Font(label1.Font.Name, 14f);
            label1.Text = "Szeretem a vizuális programozást";
            //középre igazítás
            label1.Left = (this.ClientSize.Width - label1.Width) / 2;
            label1.Top = (this.ClientSize.Height - label1.Height) / 2;
            //középre rögzítés
            label1.Anchor = AnchorStyles.None;

            button1.Text = "&Elrejt";
            button1.Location = new Point(this.ClientSize.Width - button1.Width - 30, this.ClientSize.Height - button1.Height - 30);
            button1.Anchor = AnchorStyles.Bottom | AnchorStyles.Right;

            //fekete csík elhelyezése
            label2.BackColor = Color.Black;
            label2.AutoSize = false;
            label2.Height = label1.Height / 2;
            label2.Width = this.ClientSize.Width - 10;
            label2.Top = this.ClientSize.Height-((this.ClientSize.Height-label1.Bottom)/2)-label2.Height/2;
            label2.Left = 5;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (button1.Text == "&Elrejt")
            {
                button1.Text = "&Megmutat";
                label2.Visible = false;
            }
            else
            {
                button1.Text = "&Elrejt";
                label2.Visible = true;
            }
        }

        //ablakméret változásának követése
        private void Form1_ClientSizeChanged(object sender, EventArgs e)
        {
            label2.Height = label1.Height / 2;
            label2.Width = this.ClientSize.Width - 10;
            label2.Top = this.ClientSize.Height - ((this.ClientSize.Height - label1.Bottom) / 2) - label2.Height / 2;
            label2.Left = 5;
        }
    }
}
