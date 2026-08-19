[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$allowedExtensions = @('.png', '.jpg', '.jpeg', '.webp', '.bmp')
$extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
if ($allowedExtensions -notcontains $extension) {
    throw "Unsupported image extension: $extension"
}

if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
    throw 'Run this script with pwsh -STA.'
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$source = $null
$clipboardImage = $null
try {
    $source = [Drawing.Image]::FromFile($resolvedPath)
    $clipboardImage = [Drawing.Bitmap]::new($source)
    [Windows.Forms.Clipboard]::SetImage($clipboardImage)
    [pscustomobject]@{
        ok = $true
        width = $clipboardImage.Width
        height = $clipboardImage.Height
        bytes = (Get-Item -LiteralPath $resolvedPath).Length
    } | ConvertTo-Json -Compress
} finally {
    if ($clipboardImage) { $clipboardImage.Dispose() }
    if ($source) { $source.Dispose() }
}
