# Captura una ventana real del escritorio (sin recortar el contenido)
# Uso: powershell -File scripts\capturar-ventana.ps1 -Patron "srvadmin" -Salida "01-capturas\x.png"

param(
    [string]$Patron = "srvadmin|srvuniversidad|Terminal|PowerShell",
    [string]$Salida = "01-capturas\captura.png"
)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

if (-not ("Win32Api" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Api {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@
}

$candidatas = Get-Process |
    Where-Object { $_.MainWindowTitle -and $_.MainWindowHandle -ne 0 } |
    ForEach-Object {
        $r = New-Object Win32Api+RECT
        [Win32Api]::GetWindowRect($_.MainWindowHandle, [ref]$r) | Out-Null
        [pscustomobject]@{
            Proceso = $_.ProcessName
            Titulo  = $_.MainWindowTitle
            Handle  = $_.MainWindowHandle
            Ancho   = $r.Right - $r.Left
            Alto    = $r.Bottom - $r.Top
            Rect    = $r
        }
    }

$objetivo = $candidatas | Where-Object { $_.Titulo -match $Patron } |
    Sort-Object { $_.Ancho * $_.Alto } -Descending | Select-Object -First 1

if (-not $objetivo) {
    Write-Host "No se encontro ninguna ventana que coincida con: $Patron" -ForegroundColor Red
    $candidatas | Select-Object Proceso, Titulo, Ancho, Alto | Format-Table -AutoSize
    exit 1
}

[Win32Api]::SetForegroundWindow($objetivo.Handle) | Out-Null
Start-Sleep -Milliseconds 600

$r = New-Object Win32Api+RECT
[Win32Api]::GetWindowRect($objetivo.Handle, [ref]$r) | Out-Null
$ancho = $r.Right - $r.Left
$alto = $r.Bottom - $r.Top

$bmp = New-Object System.Drawing.Bitmap $ancho, $alto
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen((New-Object System.Drawing.Point $r.Left, $r.Top), [System.Drawing.Point]::Empty, (New-Object System.Drawing.Size $ancho, $alto))
$ruta = Join-Path (Get-Location) $Salida
$bmp.Save($ruta, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

Write-Host "Ventana: $($objetivo.Titulo)"
Write-Host "Tamano: ${ancho}x${alto}"
Write-Host "Guardado en: $ruta"
