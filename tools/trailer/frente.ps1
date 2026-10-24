# Trae la ventana de Roblox Studio al frente (maximizada) para grabarla con ffmpeg gdigrab.
#     powershell -ExecutionPolicy Bypass -File tools/trailer/frente.ps1
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Ventana {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, int f, int e);
}
"@
$studio = Get-Process RobloxStudioBeta | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $studio) { throw "Roblox Studio no está abierto" }
[Ventana]::keybd_event(0x12, 0, 0, 0)  # Alt: Windows deja cambiar el foco desde otro proceso
[Ventana]::ShowWindow($studio.MainWindowHandle, 3) | Out-Null  # maximizada
[Ventana]::SetForegroundWindow($studio.MainWindowHandle) | Out-Null
[Ventana]::keybd_event(0x12, 0, 2, 0)
