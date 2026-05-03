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
$vuonAcMaWorkerSource = Join-Path $root 'features\vuon_ac_ma_worker.ahk'
$workerSource = Join-Path $root 'tools\ocr_worker.py'
$ocrWorkerRequirements = Join-Path $root 'tools\ocr_worker_requirements.txt'
$workerBuildRoot = Join-Path $root '.build\ocr_worker'
$workerStageRoot = Join-Path $workerBuildRoot 'stage'
$workerTempOut = Join-Path $workerStageRoot 'ocr_worker.exe'
$ahkBaseCandidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey32.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey32.exe')
)

if (Test-Path $releaseRoot) {
    try {
        Remove-Item $releaseRoot -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Step "không xoá được release cũ hoàn toàn, sẽ ghi đè phần build mới: $($_.Exception.Message)"
    }
}

function Get-RequirementPackageNames {
    param([string]$RequirementsPath)

    $names = @()

    foreach ($rawLine in Get-Content -LiteralPath $RequirementsPath) {
        $line = $rawLine.Trim()
        if (($line -eq '') -or $line.StartsWith('#')) { continue }

        $line = ($line -split ';', 2)[0].Trim()
        $line = ($line -split '\[', 2)[0].Trim()
        $name = ($line -split '\s*(==|!=|<=|>=|~=|<|>)\s*', 2)[0].Trim()

        if ($name -ne '') {
            $names += $name
        }
    }

    return $names | Sort-Object -Unique
}

function Add-PyInstallerPackageOption {
    param(
        [System.Collections.Generic.List[string]]$Args,
        [string]$Option,
        [string[]]$Packages
    )

    foreach ($package in ($Packages | Sort-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($package)) { continue }
        $Args.Add($Option)
        $Args.Add($package)
    }
}

function Stop-OcrWorkerProcesses {
    param(
        [string[]]$ExePaths = @(),
        [int]$TimeoutSec = 5
    )

    $targets = @()
    foreach ($path in $ExePaths) {
        if ($path -and (Test-Path $path)) {
            $targets += (Resolve-Path -LiteralPath $path).Path.ToLowerInvariant()
        }
    }

    $query = Get-CimInstance Win32_Process -Filter "Name = 'ocr_worker.exe'" -ErrorAction SilentlyContinue
    if ($targets.Count -gt 0) {
        $query = $query | Where-Object { $_.ExecutablePath -and ($targets -contains $_.ExecutablePath.ToLowerInvariant()) }
    }

    foreach ($proc in $query) {
        try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue } catch { }
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $stillRunning = Get-CimInstance Win32_Process -Filter "Name = 'ocr_worker.exe'" -ErrorAction SilentlyContinue
        if ($targets.Count -gt 0) {
            $stillRunning = $stillRunning | Where-Object { $_.ExecutablePath -and ($targets -contains $_.ExecutablePath.ToLowerInvariant()) }
        }

        if (-not $stillRunning) {
            return $true
        }

        Start-Sleep -Milliseconds 200
    }

    return $false
}

function Copy-FileWithRetry {
    param(
        [string]$Source,
        [string]$Destination,
        [int]$RetryCount = 10,
        [int]$DelayMs = 300
    )

    for ($i = 1; $i -le $RetryCount; $i++) {
        try {
            if (Test-Path $Destination) {
                Remove-Item -LiteralPath $Destination -Force -ErrorAction Stop
            }
            Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
            return
        } catch {
            if ($i -eq $RetryCount) { throw }
            Start-Sleep -Milliseconds $DelayMs
        }
    }
}

function Test-OcrWorkerSmoke {
    param(
        [string]$WorkerExe,
        [string]$Root
    )

    $smokeRoot = Join-Path $Root '.smoke'
    $smokeIpcDir = Join-Path $smokeRoot 'ipc'
    $smokeReadyFile = Join-Path $smokeIpcDir 'worker.ready'
    $smokeLogFile = Join-Path $smokeRoot 'ocr_worker_smoke.log'
    $smokeImagePath = Join-Path $smokeRoot 'smoke_ocr.png'
    $smokeRequestPath = Join-Path $smokeIpcDir 'requests\req_smoke.req'
    $smokeRequestTmpPath = Join-Path $smokeIpcDir 'requests\req_smoke.tmp'
    $smokeResponsePath = Join-Path $smokeIpcDir 'responses\resp_smoke.resp'

    if (Test-Path $smokeRoot) {
        Remove-Item $smokeRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $smokeIpcDir 'requests') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $smokeIpcDir 'responses') | Out-Null

    Add-Type -AssemblyName System.Drawing
    $bitmap = New-Object System.Drawing.Bitmap 240, 80
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $font = New-Object System.Drawing.Font('Arial', 24, [System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        try {
            $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
            $graphics.DrawString('SMOKE', $font, $brush, 20, 20)
        } finally {
            $brush.Dispose()
            $font.Dispose()
        }
        $bitmap.Save($smokeImagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    $process = Start-Process -FilePath $WorkerExe -ArgumentList @(
        '--server',
        '--ipc-dir', $smokeIpcDir,
        '--ready-file', $smokeReadyFile,
        '--log-file', $smokeLogFile,
        '--lang', 'vi'
    ) -PassThru -WindowStyle Hidden

    try {
        $deadline = (Get-Date).AddMinutes(3)
        while ((Get-Date) -lt $deadline) {
            if (Test-Path $smokeReadyFile) {
                $readyText = Get-Content -LiteralPath $smokeReadyFile -Raw -Encoding UTF8
                if ($readyText -match '(?m)^READY=1$') {
                    if ($readyText -notmatch '(?m)^PID=\d+$') {
                        throw "Smoke ready file missing PID: $smokeReadyFile"
                    }

                    $reqText = @(
                        'REQUEST_ID=smoke'
                        "IMAGE_PATH=$smokeImagePath"
                        "RESPONSE_PATH=$smokeResponsePath"
                        'LANG=vi'
                    ) -join "`n"
                    [System.IO.File]::WriteAllText($smokeRequestTmpPath, $reqText, [System.Text.UTF8Encoding]::new($false))
                    Move-Item -LiteralPath $smokeRequestTmpPath -Destination $smokeRequestPath -Force

                    $requestDeadline = (Get-Date).AddMinutes(1)
                    while ((Get-Date) -lt $requestDeadline) {
                        if (Test-Path $smokeResponsePath) {
                            $responseText = Get-Content -LiteralPath $smokeResponsePath -Raw -Encoding UTF8
                            if ($responseText -match 'PackageNotFoundError|ModuleNotFoundError') {
                                throw "Smoke response contains import failure: $smokeResponsePath"
                            }
                            if ($responseText -notmatch '(?m)^OK=1$') {
                                throw "Smoke OCR request did not succeed: $smokeResponsePath`n$responseText"
                            }
                            if ($responseText -notmatch '(?m)^TEXT=') {
                                throw "Smoke OCR response missing TEXT block: $smokeResponsePath`n$responseText"
                            }

                            if (Test-Path $smokeLogFile) {
                                $logText = Get-Content -LiteralPath $smokeLogFile -Raw -Encoding UTF8
                                if ($logText -match 'PackageNotFoundError|ModuleNotFoundError|ImportError') {
                                    throw "Smoke log still contains import failure: $smokeLogFile"
                                }
                            }

                            return [pscustomobject]@{
                                ReadyFile = $smokeReadyFile
                                LogFile = $smokeLogFile
                                ResponseFile = $smokeResponsePath
                                ReadyText = $readyText
                                ResponseText = $responseText
                            }
                        }

                        if ($process.HasExited) {
                            break
                        }

                        Start-Sleep -Milliseconds 200
                    }

                    $logText = if (Test-Path $smokeLogFile) { Get-Content -LiteralPath $smokeLogFile -Raw -Encoding UTF8 } else { '' }
                    throw "Smoke OCR request timeout after 1 minute: $smokeResponsePath`n$logText"
                }
            }

            if ($process.HasExited) {
                $exitCode = $process.ExitCode
                $logText = if (Test-Path $smokeLogFile) { Get-Content -LiteralPath $smokeLogFile -Raw -Encoding UTF8 } else { '' }
                throw "OCR worker exited early during smoke test (exitCode=$exitCode). Log: $smokeLogFile`n$logText"
            }

            Start-Sleep -Milliseconds 200
        }

        $logText = if (Test-Path $smokeLogFile) { Get-Content -LiteralPath $smokeLogFile -Raw -Encoding UTF8 } else { '' }
        throw "OCR worker smoke test timeout after 3 minutes. Ready file: $smokeReadyFile`n$logText"
    } finally {
        if ($process -and (-not $process.HasExited)) {
            try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch { }
            try { Wait-Process -Id $process.Id -Timeout 10 -ErrorAction SilentlyContinue } catch { }
        }
    }
}

if (-not (Stop-OcrWorkerProcesses)) {
    throw "Không dừng được ocr_worker.exe đang chạy từ release để rebuild"
}

if (Test-Path $workerBuildRoot) {
    try {
        Remove-Item $workerBuildRoot -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Step "không xoá được thư mục build OCR cũ hoàn toàn: $($_.Exception.Message)"
    }
}

New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

if (-not (Test-Path $mainSource)) { throw "Thiếu main.ahk" }
if (-not (Test-Path $dailyWorkerSource)) { throw "Thiếu features\daily_worker.ahk" }
if (-not (Test-Path $bossWorkerSource)) { throw "Thiếu features\boss_worker.ahk" }
if (-not (Test-Path $htttWorkerSource)) { throw "Thiếu features\haitacthongthai_worker.ahk" }
if (-not (Test-Path $vuonAcMaWorkerSource)) { throw "Thiếu features\vuon_ac_ma_worker.ahk" }
if (-not (Test-Path $workerSource)) { throw "Thiếu tools\ocr_worker.py" }
if (-not (Test-Path $ocrWorkerRequirements)) { throw "Thiếu tools\ocr_worker_requirements.txt" }
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
        -Hint 'Cài Python Launcher (py.exe), hoặc set env OCR_WORKER_PYTHON / PYTHON / PYTHON_EXE trỏ tới Python 3.11.'

    & $pyLauncher -3.11 -c "import sys" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $python = $pyLauncher
        $pythonArgs = @('-3.11')
    }
} catch {
    # fall through to explicit Python binaries
}

if ($null -eq $python) {
    $python = Resolve-ToolCommand `
        -ToolName 'Python' `
        -Candidates @(
            $env:OCR_WORKER_PYTHON,
            $env:PYTHON,
            $env:PYTHON_EXE,
            'python'
        ) `
        -Hint 'Cài Python 3.11 cho OCR worker và PyInstaller, hoặc set env OCR_WORKER_PYTHON / PYTHON / PYTHON_EXE.'
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
$vuonAcMaWorkerOut = Join-Path $releaseRoot 'vuon_ac_ma_worker.exe'
$workerOut = Join-Path $releaseRoot 'ocr_worker.exe'

Write-Step "build main exe"
Build-AhkExe -Source $mainSource -Output $mainOut -BaseExe $ahkBase -IconPath $iconPath -Label 'Ahk2Exe main'

Write-Step "build daily worker exe"
Build-AhkExe -Source $dailyWorkerSource -Output $dailyWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe daily worker'

Write-Step "build boss worker exe"
Build-AhkExe -Source $bossWorkerSource -Output $bossWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe boss worker'

Write-Step "build HTTT worker exe"
Build-AhkExe -Source $htttWorkerSource -Output $htttWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe HTTT worker'

Write-Step "build Vuon Ac Ma worker exe"
Build-AhkExe -Source $vuonAcMaWorkerSource -Output $vuonAcMaWorkerOut -BaseExe $ahkBase -Label 'Ahk2Exe Vuon Ac Ma worker'

Write-Step "build OCR worker exe"
New-Item -ItemType Directory -Force -Path $workerBuildRoot | Out-Null

Write-Step "install OCR worker requirements"
Invoke-Tool -Command $python -Arguments @($pythonArgs + @('-m', 'pip', 'install', '-r', $ocrWorkerRequirements)) -Label 'pip install OCR worker requirements'

Write-Step "install PyInstaller"
Invoke-Tool -Command $python -Arguments @($pythonArgs + @('-m', 'pip', 'install', 'pyinstaller')) -Label 'pip install PyInstaller'

$pyInstallerCheck = @('-m', 'PyInstaller', '--version')
& $python @pythonArgs @pyInstallerCheck | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Không tìm thấy PyInstaller trong môi trường Python hiện tại sau khi cài đặt. Hãy kiểm tra Python worker env và quyền pip."
}

$pyInstallerArgList = @(
    '-m', 'PyInstaller',
    '--noconfirm',
    '--clean',
    '--onefile',
    '--noconsole',
    '--name', 'ocr_worker',
    '--distpath', $workerStageRoot,
    '--workpath', (Join-Path $workerBuildRoot 'work'),
    '--specpath', (Join-Path $workerBuildRoot 'spec'),
    '--collect-data', 'Cython',
    '--collect-submodules', 'Cython',
    '--collect-all', 'paddle',
    '--collect-all', 'paddleocr',
    '--collect-all', 'imgaug',
    '--collect-all', 'imageio',
    '--collect-all', 'lmdb',
    '--collect-all', 'pyclipper',
    '--collect-all', 'skimage',
    '--hidden-import', 'imghdr',
    $workerSource
)

$pyInstallerArgs = New-Object System.Collections.Generic.List[string]
foreach ($arg in $pyInstallerArgList) {
    [void]$pyInstallerArgs.Add([string]$arg)
}

$ocrRequirementPackages = Get-RequirementPackageNames -RequirementsPath $ocrWorkerRequirements
Add-PyInstallerPackageOption -Args $pyInstallerArgs -Option '--recursive-copy-metadata' -Packages $ocrRequirementPackages

& $python @pythonArgs @($pyInstallerArgs.ToArray())
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller build failed"
}

if (-not (Test-Path $workerTempOut)) {
    throw "Build worker xong nhưng không thấy file staging: $workerTempOut"
}

Write-Step "smoke test OCR worker exe"
$smokeResult = Test-OcrWorkerSmoke -WorkerExe $workerTempOut -Root $workerBuildRoot
Write-Step "smoke ready: $($smokeResult.ReadyFile)"

Write-Step "publish OCR worker exe"
if (-not (Stop-OcrWorkerProcesses -ExePaths @((Join-Path $releaseRoot 'ocr_worker.exe'), $workerTempOut))) {
    throw "Không dừng được process ocr_worker.exe trước khi publish"
}

Copy-FileWithRetry -Source $workerTempOut -Destination (Join-Path $releaseRoot 'ocr_worker.exe')

if (-not (Test-Path (Join-Path $releaseRoot 'ocr_worker.exe'))) {
    throw "Publish worker xong nhưng không thấy file release: $workerOut"
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
    '- vuon_ac_ma_worker.exe'
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

Write-Step "cleanup OCR temp dirs"
Remove-Item -LiteralPath $workerStageRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $workerBuildRoot '.smoke') -Recurse -Force -ErrorAction SilentlyContinue

Write-Step "done"
Write-Host $releaseRoot
