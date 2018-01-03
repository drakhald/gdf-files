using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            System.Windows.Forms.Application.Exit();
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            IsNumeric(textBox1);
        }

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

        private void button1_Click(object sender, EventArgs e)
        {
            try
            {
                if (int.Parse(textBox1.Text) == int.Parse(textBox2.Text))
                {
                    label1.Text = "=";
                }
                else
                {
                    if (int.Parse(textBox1.Text) < int.Parse(textBox2.Text))
                    {
                        label1.Text = "<";
                    }
                    else
                    {
                        label1.Text = ">";
                    }
                }
            }
            catch
            {
                MessageBox.Show("Csak számok lehetnek a mezőben!", "Hiba", MessageBoxButtons.OK);
            }
        }
    }
}
