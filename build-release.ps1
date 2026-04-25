param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
    Write-Host "[build] $Message"
}

function Resolve-ToolCommand {
    param(
        [string]$ToolName,
        [string[]]$Candidates,
        [string]$Hint
    )

    $checked = New-Object System.Collections.Generic.List[string]

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $checked.Add($candidate)

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $cmd) {
            if ($cmd.Path) { return $cmd.Path }
            if ($cmd.Source) { return $cmd.Source }
            return $cmd.Definition
        }
    }

    $checkedText = ($checked | Select-Object -Unique) -join ', '
    throw @"
Không tìm thấy $ToolName.
Đã thử: $checkedText
$Hint
"@
}

function Invoke-Tool {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$Label
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        $exitCode = if ($null -eq $LASTEXITCODE) { 'unknown' } else { $LASTEXITCODE }
        throw "$Label failed with exit code $exitCode"
    }
}

function Build-AhkExe {
    param(
        [string]$Source,
        [string]$Output,
        [string]$BaseExe,
        [string]$IconPath = $null,
        [string]$Label = 'Ahk2Exe'
    )

    $buildArgs = @('/in', $Source, '/out', $Output, '/bin', $BaseExe)
    if ($IconPath) {
        $buildArgs += @('/icon', $IconPath)
    }

    Invoke-Tool -Command $ahk2Exe -Arguments $buildArgs -Label $Label
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$releaseRoot = Join-Path $root 'release\kynguyenhaitac-auto'
$resourcesSrc = Join-Path $root 'resources'
$mainSource = Join-Path $root 'main.ahk'
$dailyWorkerSource = Join-Path $root 'features\daily_worker.ahk'
$bossWorkerSource = Join-Path $root 'features\boss_worker.ahk'
$htttWorkerSource = Join-Path $root 'features\haitacthongthai_worker.ahk'
$workerSource = Join-Path $root 'tools\ocr_worker.py'
$workerBuildRoot = Join-Path $root '.build\ocr_worker'
$ahkBaseCandidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey32.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey32.exe')
)

if (Test-Path $releaseRoot) {
    Remove-Item $releaseRoot -Recurse -Force
}

if (Test-Path $workerBuildRoot) {
    Remove-Item $workerBuildRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

if (-not (Test-Path $mainSource)) { throw "Thiếu main.ahk" }
if (-not (Test-Path $dailyWorkerSource)) { throw "Thiếu features\daily_worker.ahk" }
if (-not (Test-Path $bossWorkerSource)) { throw "Thiếu features\boss_worker.ahk" }
if (-not (Test-Path $htttWorkerSource)) { throw "Thiếu features\haitacthongthai_worker.ahk" }
if (-not (Test-Path $workerSource)) { throw "Thiếu tools\ocr_worker.py" }
if (-not (Test-Path $resourcesSrc)) { throw "Thiếu thư mục resources" }
$iconPath = Join-Path $resourcesSrc 'icon.ico'
if (-not (Test-Path $iconPath)) { throw "Thiếu resources\icon.ico" }

$ahk2Exe = Resolve-ToolCommand `
    -ToolName 'Ahk2Exe' `
    -Candidates @(
        $env:AHK2EXE,
        $env:AHK2EXE_PATH,
        $env:AUTOHOTKEY_AHK2EXE,
        (Join-Path $env:ProgramFiles 'AutoHotkey\Compiler\Ahk2Exe.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\Compiler\Ahk2Exe.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\Compiler\Ahk2Exe.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\Compiler\Ahk2Exe.exe'),
        'Ahk2Exe.exe'
    ) `
    -Hint 'Cài AutoHotkey v2 + Ahk2Exe, hoặc set env AHK2EXE / AHK2EXE_PATH trỏ tới Ahk2Exe.exe.'

$python = $null
$pythonArgs = @()

try {
    $pyLauncher = Resolve-ToolCommand `
        -ToolName 'Python launcher' `
        -Candidates @('py') `
        -Hint 'Cài Python Launcher (py.exe), hoặc set env PYTHON / PYTHON_EXE trỏ tới Python có PyInstaller.'

    & $pyLauncher -3.13 -m PyInstaller --version | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $python = $pyLauncher
        $pythonArgs = @('-3.13')
    }
} catch {
    # fall through to explicit Python binaries
}

if ($null -eq $python) {
    $python = Resolve-ToolCommand `
        -ToolName 'Python' `
        -Candidates @(
            $env:PYTHON,
            $env:PYTHON_EXE,
            'python'
        ) `
        -Hint 'Cài Python 3 và PyInstaller, hoặc set env PYTHON / PYTHON_EXE.'
}

$ahkBase = Resolve-ToolCommand `
    -ToolName 'AutoHotkey v2 base' `
    -Candidates $ahkBaseCandidates `
    -Hint 'Cài AutoHotkey v2 đầy đủ, hoặc đặt AHK2DIR/Program Files đúng vị trí AutoHotkey64.exe.'

Write-Step "release -> $releaseRoot"

$mainOut = Join-Path $releaseRoot 'kynguyenhaitac-auto.exe'
$dailyWorkerOut = Join-Path $releaseRoot 'daily_worker.exe'
$bossWorkerOut = Join-Path $releaseRoot 'boss_worker.exe'
$htttWorkerOut = Join-Path $releaseRoot 'haitacthongthai_worker.exe'
$workerOut = Join-Path $releaseRoot 'ocr_worker.exe'

Write-Step "build main exe"
Build-AhkExe -Source $mainSource -Output $mainOut -BaseExe $ahkBase -IconPath $iconPath -Label 'Ahk2Exe main'

Write-Step "build daily worker exe"
Build-AhkExe -Source $dailyWorkerSource -Output $dailyWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe daily worker'

Write-Step "build boss worker exe"
Build-AhkExe -Source $bossWorkerSource -Output $bossWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe boss worker'

Write-Step "build HTTT worker exe"
Build-AhkExe -Source $htttWorkerSource -Output $htttWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe HTTT worker'

Write-Step "build OCR worker exe"
New-Item -ItemType Directory -Force -Path $workerBuildRoot | Out-Null

$pyInstallerCheck = @('-m', 'PyInstaller', '--version')
& $python @pythonArgs @pyInstallerCheck | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Không tìm thấy PyInstaller trong môi trường Python hiện tại. Hãy chạy: python -m pip install pyinstaller"
}

$pyInstallerArgs = @(
    '-m', 'PyInstaller',
    '--noconfirm',
    '--clean',
    '--onefile',
    '--noconsole',
    '--name', 'ocr_worker',
    '--distpath', $releaseRoot,
    '--workpath', (Join-Path $workerBuildRoot 'work'),
    '--specpath', (Join-Path $workerBuildRoot 'spec'),
    $workerSource
)

& $python @pythonArgs @pyInstallerArgs
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller build failed"
}

if (-not (Test-Path $workerOut)) {
    throw "Build worker xong nhưng không thấy file: $workerOut"
}

Write-Step "copy resources"
$resourcesOut = Join-Path $releaseRoot 'resources'
if (Test-Path $resourcesOut) {
    Remove-Item $resourcesOut -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $resourcesOut | Out-Null
Copy-Item -Path (Join-Path $resourcesSrc '*') -Destination $resourcesOut -Recurse -Force

Write-Step "write README"
$readmePath = Join-Path $releaseRoot 'README.txt'
$readmeText = @(
    'Kynguyenhaitac Auto release'
    ''
    'Files:'
    '- kynguyenhaitac-auto.exe'
    '- daily_worker.exe'
    '- boss_worker.exe'
    '- haitacthongthai_worker.exe'
    '- ocr_worker.exe'
    '- resources\'
    ''
    'Run:'
    '1) Double-click kynguyenhaitac-auto.exe'
    '2) OCR worker is started automatically when needed'
    ''
    'Notes:'
    '- resources\ contains runtime INI/icon files'
    '- logs are created at runtime in the app folder'
) -join "`r`n"
Set-Content -LiteralPath $readmePath -Value $readmeText -Encoding UTF8

Write-Step "done"
Write-Host $releaseRoot
