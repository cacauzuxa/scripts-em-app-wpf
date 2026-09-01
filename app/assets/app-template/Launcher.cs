using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Forms;

internal static class Launcher
{
    private const string AppScript = "__APP_SCRIPT__";
    private const string AppTitle = "__APP_TITLE__";
    private const string MutexName = "Local\\__MUTEX_NAME__";

    [STAThread]
    private static void Main()
    {
        using (var mutex = new Mutex(true, MutexName, out var firstInstance))
        {
            if (!firstInstance)
            {
                MessageBox.Show("O aplicativo já está aberto.", AppTitle,
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var root = AppDomain.CurrentDomain.BaseDirectory;
            var script = Path.Combine(root, AppScript);
            if (!File.Exists(script))
            {
                MessageBox.Show("Interface não encontrada:\n" + script, AppTitle,
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            var start = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -STA -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File \"" + script + "\"",
                WorkingDirectory = root,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (var process = Process.Start(start))
            {
                process?.WaitForExit();
            }
        }
    }
}
