#requires -Version 5.1
<#
    Sinh anh placeholder cho SDU Life Simulator.

    Chay:    pwsh -File tools/gen_placeholder_art.ps1
    Ket qua: art/tileset_campus.png  (4 tile 16x16: co, san, tuong, duong)
             art/player_sheet.png    (4 huong x 4 frame di, o 24x32)

    Anh chi la placeholder de project chay duoc. Thay bang asset that
    (vi du Modern Interiors cua LimeZu) khi bat dau lam art chinh thuc.
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

$ArtDir = Join-Path $ProjectRoot 'art'
New-Item -ItemType Directory -Force -Path $ArtDir | Out-Null

function New-Canvas([int]$W, [int]$H) {
    [System.Drawing.Bitmap]::new($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function New-Color([int]$R, [int]$G, [int]$B, [int]$A = 255) {
    [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function Set-Px($Bmp, [int]$X, [int]$Y, $Color) {
    if ($X -lt 0 -or $Y -lt 0 -or $X -ge $Bmp.Width -or $Y -ge $Bmp.Height) { return }
    $Bmp.SetPixel($X, $Y, $Color)
}

function Fill-Rect($Bmp, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, $Color) {
    for ($y = $Y1; $y -le $Y2; $y++) {
        for ($x = $X1; $x -le $X2; $x++) { Set-Px $Bmp $x $y $Color }
    }
}

# ---------------------------------------------------------------- tileset 16x16

$T = 16
$sheet = New-Canvas ($T * 4) $T

# Tile 0 - co (grass)
$grassA = New-Color 84 152 74
$grassB = New-Color 99 171 86
for ($y = 0; $y -lt $T; $y++) {
    for ($x = 0; $x -lt $T; $x++) {
        $n = (($x * 7) + ($y * 13)) % 11
        $c = if ($n -lt 3) { $grassB } else { $grassA }
        Set-Px $sheet ($x + 0) $y $c
    }
}

# Tile 1 - san lop hoc (floor)
$floorBase = New-Color 205 198 182
$floorLine = New-Color 168 160 143
for ($y = 0; $y -lt $T; $y++) {
    for ($x = 0; $x -lt $T; $x++) {
        $c = $floorBase
        if ($x -eq 0 -or $y -eq 0) { $c = $floorLine }
        elseif ((($x + $y) % 8) -eq 0) { $c = (New-Color 194 186 170) }
        Set-Px $sheet ($x + $T) $y $c
    }
}

# Tile 2 - tuong (wall)
$wallBase = New-Color 128 100 86
$wallMortar = New-Color 94 72 62
for ($y = 0; $y -lt $T; $y++) {
    for ($x = 0; $x -lt $T; $x++) {
        $row = [math]::Floor($y / 8)
        $c = $wallBase
        if (($y % 8) -eq 0) { $c = $wallMortar }
        elseif (((($x + ($row * 8)) % 16)) -eq 0) { $c = $wallMortar }
        Set-Px $sheet ($x + ($T * 2)) $y $c
    }
}

# Tile 3 - duong di (path)
$pathBase = New-Color 158 154 150
for ($y = 0; $y -lt $T; $y++) {
    for ($x = 0; $x -lt $T; $x++) {
        $n = (($x * 5) + ($y * 3)) % 9
        $c = if ($n -lt 2) { New-Color 142 138 134 } else { $pathBase }
        Set-Px $sheet ($x + ($T * 3)) $y $c
    }
}

$tilesetPath = Join-Path $ArtDir 'tileset_campus.png'
$sheet.Save($tilesetPath, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()

# ------------------------------------------------------- player 24x32 x 4x4

$CW = 24
$CH = 32
$player = New-Canvas ($CW * 4) ($CH * 4)

$skin = New-Color 232 190 152
$hair = New-Color 58 40 32
$shirt = New-Color 72 118 198
$pants = New-Color 48 58 80
$shoe = New-Color 32 32 38
$eye = New-Color 28 24 30

for ($row = 0; $row -lt 4; $row++) {
    for ($f = 0; $f -lt 4; $f++) {
        $ox = $f * $CW
        $oy = $row * $CH

        # Do lech chan theo tung frame di
        $lo = 0; $ro = 0
        if ($f -eq 1) { $lo = 1; $ro = -1 }
        if ($f -eq 3) { $lo = -1; $ro = 1 }

        # Nhun nguoi len 1px o frame 1 va 3
        $bob = if (($f -eq 1) -or ($f -eq 3)) { -1 } else { 0 }

        # Chan + giay
        Fill-Rect $player ($ox + 7) ($oy + 24) ($ox + 11) ($oy + 29 + $lo) $pants
        Fill-Rect $player ($ox + 12) ($oy + 24) ($ox + 16) ($oy + 29 + $ro) $pants
        Fill-Rect $player ($ox + 6) ($oy + 29 + $lo) ($ox + 11) ($oy + 31 + $lo) $shoe
        Fill-Rect $player ($ox + 12) ($oy + 29 + $ro) ($ox + 17) ($oy + 31 + $ro) $shoe

        # Than + tay ao
        Fill-Rect $player ($ox + 6) (($oy + 13) + $bob) ($ox + 17) (($oy + 25) + $bob) $shirt
        Fill-Rect $player ($ox + 4) (($oy + 15) + $bob) ($ox + 5) (($oy + 23) + $bob) $shirt
        Fill-Rect $player ($ox + 18) (($oy + 15) + $bob) ($ox + 19) (($oy + 23) + $bob) $shirt

        # Dau
        Fill-Rect $player ($ox + 7) (($oy + 3) + $bob) ($ox + 16) (($oy + 13) + $bob) $skin

        # Toc
        if ($row -eq 3) {
            # Huong len: thay sau dau
            Fill-Rect $player ($ox + 7) (($oy + 2) + $bob) ($ox + 16) (($oy + 13) + $bob) $hair
        }
        else {
            Fill-Rect $player ($ox + 6) (($oy + 1) + $bob) ($ox + 17) (($oy + 6) + $bob) $hair
        }

        # Mat
        $eyeY = ($oy + 9) + $bob
        if ($row -eq 0) {
            Set-Px $player ($ox + 10) $eyeY $eye
            Set-Px $player ($ox + 13) $eyeY $eye
        }
        elseif ($row -eq 1) {
            Set-Px $player ($ox + 8) $eyeY $eye
            Set-Px $player ($ox + 11) $eyeY $eye
        }
        elseif ($row -eq 2) {
            Set-Px $player ($ox + 12) $eyeY $eye
            Set-Px $player ($ox + 15) $eyeY $eye
        }
    }
}

$playerPath = Join-Path $ArtDir 'player_sheet.png'
$player.Save($playerPath, [System.Drawing.Imaging.ImageFormat]::Png)
$player.Dispose()

Write-Host "Da sinh:"
Write-Host "  $tilesetPath"
Write-Host "  $playerPath"
