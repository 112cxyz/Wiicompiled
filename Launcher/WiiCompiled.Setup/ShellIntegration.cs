using Microsoft.Win32;

namespace WiiCompiled.Setup;

internal static class ShellIntegration
{
    public static void RegisterUninstaller(string installDirectory, bool retroInstalled)
    {
        using var key = Registry.CurrentUser.CreateSubKey(ProductInfo.UninstallKey, writable: true)
                        ?? throw new InvalidOperationException("Could not register the uninstaller.");
        var cli = Path.Combine(installDirectory, ProductInfo.SetupCopyName);
        key.SetValue("DisplayName", ProductInfo.Name);
        key.SetValue("DisplayVersion", ProductInfo.Version);
        key.SetValue("Publisher", "WiiCompiled");
        key.SetValue("InstallLocation", installDirectory);
        key.SetValue("DisplayIcon", cli);
        key.SetValue("UninstallString", $"\"{cli}\" --uninstall --install-dir \"{installDirectory}\"");
        key.SetValue("QuietUninstallString", $"\"{cli}\" --silent-uninstall --install-dir \"{installDirectory}\"");
        key.SetValue("NoModify", 1, RegistryValueKind.DWord);
        key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
        key.SetValue("EstimatedSize", EstimateSizeKb(installDirectory), RegistryValueKind.DWord);
        key.SetValue("Comments", retroInstalled ? "Includes the Retro Rewind profile" : "WiiCompiled");
    }

    public static void UnregisterUninstaller() =>
        Registry.CurrentUser.DeleteSubKeyTree(ProductInfo.UninstallKey, throwOnMissingSubKey: false);

    /// <summary>Removes shortcuts left by GUI-capable releases from before Wheel Wizard owned the UI.</summary>
    public static void RemoveAllShortcuts()
    {
        var desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
        var startMenuFolder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.StartMenu), "Programs", ProductInfo.Name);
        RemoveAllShortcuts(desktop, startMenuFolder);
    }

    internal static void RemoveAllShortcuts(string desktop, string startMenuFolder)
    {
        var failures = new List<Exception>();
        DeleteFileBestEffort(Path.Combine(desktop, "WiiCompiled.lnk"), failures);
        DeleteFileBestEffort(Path.Combine(desktop, "Retro Rewind.lnk"), failures);
        DeleteDirectoryBestEffort(startMenuFolder, failures);

        if (failures.Count != 0)
            throw new AggregateException("One or more WiiCompiled shortcuts could not be removed.", failures);
    }

    private static void DeleteFileBestEffort(string path, List<Exception> failures)
    {
        try
        {
            File.Delete(path);
        }
        catch (Exception ex)
        {
            failures.Add(new IOException($"Could not delete shortcut {path}: {ex.Message}", ex));
        }
    }

    private static void DeleteDirectoryBestEffort(string path, List<Exception> failures)
    {
        try
        {
            if (Directory.Exists(path)) Directory.Delete(path, recursive: true);
        }
        catch (Exception ex)
        {
            failures.Add(new IOException($"Could not delete shortcut folder {path}: {ex.Message}", ex));
        }
    }

    private static int EstimateSizeKb(string directory)
    {
        try
        {
            var bytes = Directory.EnumerateFiles(directory, "*", SearchOption.AllDirectories)
                .Sum(path => new FileInfo(path).Length);
            return (int)Math.Min(int.MaxValue, (bytes + 1023) / 1024);
        }
        catch
        {
            return 0;
        }
    }
}
