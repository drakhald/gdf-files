using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _10
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            //városok feltöltése
            listBox1.Items.Add("Aba");
            listBox1.Items.Add("Budapest");
            listBox1.Items.Add("Cegléd");
            listBox1.Items.Add("Debrecen");
            listBox1.Items.Add("Eger");
            listBox1.Items.Add("Fertőd");
            listBox1.Items.Add("Gárdony");
            listBox1.Items.Add("Gyöngyös");
            listBox1.Items.Add("Harkány");
            listBox1.Items.Add("Jánosháza");

            //többszörös kiválasztás engedélyezése
            listBox1.SelectionMode = SelectionMode.MultiSimple;

            //label frissítése
            UpdateLabel();
        }

        //mind törlése, label frissítése
        private void button1_Click(object sender, EventArgs e)
        {
            listBox1.Items.Clear();
            UpdateLabel();
        }

        //kiválasztottak törlése, label frissítése
        private void button2_Click(object sender, EventArgs e)
        {
            //ha nincs kijelölve semmi, dobjon hibát
            if (listBox1.SelectedIndices.Count == 0)
            {
                MessageBox.Show("Nincs kijelölt elem!", "Hiba", MessageBoxButtons.OK);
            }
            else {
                //a kijelöltek törlése alulról felfelé, így nem romlik el az indexelés
                for (int x = listBox1.SelectedIndices.Count - 1; x >= 0; x--)
                {
                    int idx = listBox1.SelectedIndices[x];
                    listBox1.Items.RemoveAt(idx);
                }
                UpdateLabel();   
            }
        }

        //label frissítése
        private void UpdateLabel()
        {
            label1.Text = "A tételek száma = " + listBox1.Items.Count;
        }
    }
}
