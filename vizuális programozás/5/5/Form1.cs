using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _5
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        //textboxok ellenőrzése
        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            IsNumeric(textBox1);
        }

        //textboxok ellenőrzése
        private void textBox2_TextChanged(object sender, EventArgs e)
        {
            IsNumeric(textBox2);
        }

        private void IsNumeric(TextBox textbox)
        {
            int temp;
            if (int.TryParse(textbox.Text, out temp) == false)
            {
                MessageBox.Show("Csak számok lehetnek a mezőben!", "Hiba", MessageBoxButtons.OK);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            //az osztás van kijelölve
            if (radioButton1.Checked)
            {
                //nullával nem lehet osztani
                if (textBox2.Text == "0")
                {
                    MessageBox.Show("Nem lehet nullával osztani!", "Hiba", MessageBoxButtons.OK);
                }
                else
                {
                    try
                    {
                        //osztás
                        label1.Text = ((double.Parse(textBox1.Text) / double.Parse(textBox2.Text))).ToString();
                    }
                    catch
                    {
                        MessageBox.Show("Csak számok lehetnek a mezőben!", "Hiba", MessageBoxButtons.OK);
                    }
                }
            }

            if(radioButton2.Checked)
            {
                try
                {
                    //kivonás
                    label1.Text = ((int.Parse(textBox1.Text) - int.Parse(textBox2.Text))).ToString();
                }
                catch
                {
                    MessageBox.Show("Csak számok lehetnek a mezőben!", "Hiba", MessageBoxButtons.OK);
                }
            }
        }
    }
}
