using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _3
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            //a három szám legenerálása
            Random rnd = new Random();
            int rnd1 = rnd.Next(10);
            int rnd2 = rnd.Next(10);
            int rnd3 = rnd.Next(10);

            //labelek átírása
            label1.Text = rnd1.ToString();
            label2.Text = rnd2.ToString();
            label3.Text = rnd3.ToString();

            //egyenlőség ellenőrzése
            if(rnd1==rnd2 && rnd1 == rnd3){
                MessageBox.Show("Nyertél!", "Nyertél", MessageBoxButtons.OK);
            }
        }
    }
}
