using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _2
{
    public partial class Form1 : Form
    {
        //ebben tároljuk a label színét
        private Color labelColor;


        public Form1()
        {
            InitializeComponent();

            //alapesetben legyen fekete a label színe
            labelColor = Color.Black;
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        //kattintásra megváltoztatjuk a label színét a kiválasztott színre
        private void button1_Click(object sender, EventArgs e)
        {
            label1.ForeColor = labelColor;
        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            labelColor = Color.Red;
        }

        private void radioButton2_CheckedChanged(object sender, EventArgs e)
        {
            labelColor = Color.Yellow;
        }

        private void radioButton3_CheckedChanged(object sender, EventArgs e)
        {
            labelColor = Color.Black;
        }
    }
}
