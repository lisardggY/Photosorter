using Microsoft.Win32;
using System.Windows;
using System.IO;
using System.Management.Automation;
using System;
using System.Media;

namespace PhotoSorter.App
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private string ChooseFolder(string startFolder)
        {
            var ofd = new OpenFileDialog();
            ofd.InitialDirectory = startFolder;
            ofd.ValidateNames = false;
            ofd.CheckFileExists = false;
            ofd.FileName = "Select folder.";
            if (ofd.ShowDialog().GetValueOrDefault())
            {
                return Path.GetDirectoryName(ofd.FileName);
            }
            else
            {
                return null;
            }
        }

        private void SelectSourceFolder(object sender, RoutedEventArgs e)
        {
            txtSourceFolder.Text = ChooseFolder(txtSourceFolder.Text);
            txtTargetFolder.Text = txtSourceFolder.Text;
        }

        private void SelectTargetFolder(object sender, RoutedEventArgs e)
        {
            txtTargetFolder.Text = ChooseFolder(txtTargetFolder.Text);
        }

        private async void SortPhotos(object sender, RoutedEventArgs e)
        {
            var source = txtSourceFolder.Text;
            var target = txtTargetFolder.Text;
            if (!Directory.Exists(source))
            {
                MessageBox.Show("Can't find source folder");
                return;
            }
            if (!Directory.Exists(target))
            {
                MessageBox.Show("Can't find target folder");
                return;
            }

            txtOutput.Clear();

            using (var ps = PowerShell.Create())
            {
                ps.AddScript(File.ReadAllText("photosort.ps1"));
                ps.AddParameter("SourceFolder", source);
                ps.AddParameter("TargetFolder", target);
                ps.Streams.Error.DataAdded += (sender, args) =>
                {
                    var record = (sender as PSDataCollection<ErrorRecord>)[args.Index];
                    WriteLog("Error", record.Exception.Message);
                };
                ps.Streams.Warning.DataAdded += (sender, args) =>
                {
                    var record = (sender as PSDataCollection<WarningRecord>)[args.Index];
                    WriteLog("Warning", record.Message);
                };
                ps.Streams.Information.DataAdded += (sender, args) =>
                {
                    var record = (sender as PSDataCollection<InformationRecord>)[args.Index];
                    var hostMessage = record.MessageData as HostInformationMessage;
                    if (hostMessage != null)
                    {
                        WriteLog(null, hostMessage.Message);
                    }
                };
                ps.Streams.Debug.DataAdded += (sender, args) =>
                {
                    var record = (sender as PSDataCollection<DebugRecord>)[args.Index];
                    WriteLog("Info", record.Message);
                };
                var results = await ps.InvokeAsync();
                foreach (var result in results)
                {
                    WriteLog(null, result.ToString());
                }
                new SoundPlayer("c:\\windows\\media\\windows exclamation.wav").Play();
                MessageBox.Show("Done", "Done!");
               
            }
            
        }

        private void WriteLog(string category, string message)
        {
            txtOutput.Dispatcher.Invoke(() =>
            {
                txtOutput.Text += string.IsNullOrEmpty(category) ? message : $"{category}: {message}{Environment.NewLine}";
                txtOutput.ScrollToEnd();
            });
        }
    }
}
