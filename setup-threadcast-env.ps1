#Requires -Version 5.1
<#
.SYNOPSIS
    Threadcast development environment setup for Windows.
.DESCRIPTION
    Installs and configures all tools and generates a project scaffold compatible with Drift.
#>

[CmdletBinding()]
param(
    [switch]$SkipVSCode,
    [switch]$SkipClaudeCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

$FlutterVersion    = '3.32.2'
$FlutterInstallDir = 'C:\flutter'
$FlutterBinDir     = 'C:\flutter\bin'
$AndroidApiLevel   = '36'
$AndroidApiLevelFB = '35'

$script:PassCount        = 0
$script:WarnCount        = 0
$script:FailCount        = 0
$script:NeedsAndroidInit = $false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Header {
    param([string]$Text)
    $line = '-' * 70
    Write-Host ''
    Write-Host $line -ForegroundColor DarkGray
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkGray
}

function Write-Step { param([string]$Text); Write-Host "  >> $Text" -ForegroundColor White }
function Write-Pass { param([string]$Text); Write-Host "  [OK] $Text" -ForegroundColor Green;  $script:PassCount++ }
function Write-Warn { param([string]$Text); Write-Host "  [!!] $Text" -ForegroundColor Yellow; $script:WarnCount++ }
function Write-Fail { param([string]$Text); Write-Host "  [XX] $Text" -ForegroundColor Red;    $script:FailCount++ }
function Write-Info { param([string]$Text); Write-Host "       $Text" -ForegroundColor DarkGray }

function Test-Command {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Add-ToUserPath {
    param([string]$PathToAdd)
    $current = [Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($current -notlike "*$PathToAdd*") {
        [Environment]::SetEnvironmentVariable('PATH', "$current;$PathToAdd", 'User')
        $env:PATH = "$env:PATH;$PathToAdd"
        Write-Info "Added to user PATH: $PathToAdd"
    }
    else {
        Write-Info "Already in PATH: $PathToAdd"
    }
}

function Add-ToMachinePath {
    param([string]$PathToAdd)
    $current = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($current -notlike "*$PathToAdd*") {
        [Environment]::SetEnvironmentVariable('PATH', "$current;$PathToAdd", 'Machine')
        $env:PATH = "$env:PATH;$PathToAdd"
        Write-Info "Added to machine PATH: $PathToAdd"
    }
}

function Invoke-WingetInstall {
    param(
        [string]$Id,
        [string]$Name,
        [string[]]$ExtraArgs = @()
    )
    Write-Step "Installing $Name via winget..."
    $wingetArgs = @(
        'install', '--id', $Id,
        '--exact',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements'
    ) + $ExtraArgs

    $result = & winget @wingetArgs 2>&1
    # -1978335189 = APPINSTALLER_ERROR_ALREADY_INSTALLED
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Pass "$Name installed (or already present)"
        return
    }
    else {
        Write-Warn "$Name install may have issues (exit code: $LASTEXITCODE)"
        $result | Select-Object -Last 5 | ForEach-Object { Write-Info $_ }
        return
    }
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

function Test-Preflight {
    Write-Header 'Preflight checks'

    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Fail 'Script must be run as Administrator. Right-click PowerShell and choose Run as Administrator.'
        exit 1
    }
    Write-Pass 'Running as Administrator'

    $os = [System.Environment]::OSVersion.Version
    if ($os.Major -lt 10 -or ($os.Major -eq 10 -and $os.Build -lt 19041)) {
        Write-Fail "Windows 10 21H1 (build 19041) or later required. Found build: $($os.Build)"
        exit 1
    }
    Write-Pass "Windows version OK (build $($os.Build))"

    if (-not (Test-Command 'winget')) {
        Write-Fail "winget not found. Install 'App Installer' from the Microsoft Store then re-run."
        exit 1
    }
    $wingetVer = (winget --version 2>&1).ToString().Trim()
    Write-Pass "winget: $wingetVer"

    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq 'Restricted') {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Pass 'Execution policy set to RemoteSigned'
    }
    else {
        Write-Pass "Execution policy: $policy"
    }

    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    if ($freeGB -lt 30) {
        Write-Warn "Low disk space: $freeGB GB free on C:. Recommend 30+ GB for SDK and emulator images."
    }
    else {
        Write-Pass "Disk space: $freeGB GB free on C:"
    }

    $connectivityTargets = @(
        @{ Uri = 'https://www.google.com';          Label = 'google.com' },
        @{ Uri = 'https://storage.googleapis.com';  Label = 'storage.googleapis.com' },
        @{ Uri = 'https://github.com';              Label = 'github.com' }
    )
    $connected = $false
    foreach ($target in $connectivityTargets) {
        try {
            $null = Invoke-WebRequest -Uri $target.Uri -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
            Write-Pass "Internet connectivity: OK (reached $($target.Label))"
            $connected = $true
            break
        }
        catch {
            Write-Info "Could not reach $($target.Label) - trying next..."
        }
    }
    if (-not $connected) {
        try {
            $null = [System.Net.Dns]::GetHostAddresses('google.com')
            Write-Pass 'Internet connectivity: OK (DNS resolution succeeded)'
            $connected = $true
        }
        catch { Write-Info 'DNS resolution also failed' }
    }
    if (-not $connected) {
        Write-Fail 'No internet connectivity detected. Check your network and try again.'
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

function Install-Git {
    Write-Header 'Git for Windows'

    if (Test-Command 'git') {
        Write-Pass "git already installed: $((git --version).ToString().Trim())"
        return
    }

    Invoke-WingetInstall -Id 'Git.Git' -Name 'Git for Windows'

    $gitBin = 'C:\Program Files\Git\cmd'
    Add-ToMachinePath $gitBin
    $env:PATH = "$env:PATH;$gitBin"

    if (Test-Command 'git') {
        Write-Pass 'git is available in PATH'
    }
    else {
        Write-Warn 'git installed but not yet in PATH for this session. Open a new terminal after setup.'
    }
}

# ---------------------------------------------------------------------------
# JDK 17
# ---------------------------------------------------------------------------

function Install-Jdk {
    Write-Header 'Java JDK 17'

    $javaHome = $env:JAVA_HOME
    if ($javaHome -and (Test-Path "$javaHome\bin\java.exe")) {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $javaVerOutput = (& "$javaHome\bin\java" -version 2>&1) | Select-Object -First 1
        $ErrorActionPreference = $prevEAP
        if ($javaVerOutput -match 'version "17') {
            Write-Pass "JDK 17 already configured: $javaHome"
            return
        }
    }

    Invoke-WingetInstall -Id 'Microsoft.OpenJDK.17' -Name 'Microsoft OpenJDK 17'

    $searchPatterns = @(
        'C:\Program Files\Microsoft\jdk-17*',
        'C:\Program Files\Eclipse Adoptium\jdk-17*',
        'C:\Program Files\Java\jdk-17*'
    )
    $jdkPath = $null
    foreach ($pattern in $searchPatterns) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $jdkPath = $found.FullName; break }
    }

    if ($jdkPath) {
        [Environment]::SetEnvironmentVariable('JAVA_HOME', $jdkPath, 'Machine')
        $env:JAVA_HOME = $jdkPath
        Add-ToMachinePath "$jdkPath\bin"
        Write-Pass "JAVA_HOME set to: $jdkPath"
    }
    else {
        Write-Warn 'JDK 17 installed but path not auto-detected. Set JAVA_HOME manually after restart.'
    }
}

# ---------------------------------------------------------------------------
# Android Studio + SDK
# ---------------------------------------------------------------------------

function Install-AndroidStudio {
    Write-Header 'Android Studio + Android SDK'

    $studioExe = 'C:\Program Files\Android\Android Studio\bin\studio64.exe'
    if (Test-Path $studioExe) {
        Write-Pass 'Android Studio already installed'
    }
    else {
        Invoke-WingetInstall -Id 'Google.AndroidStudio' -Name 'Android Studio'
    }

    $androidSdkRoot = "$env:LOCALAPPDATA\Android\Sdk"

    if (-not (Test-Path $androidSdkRoot)) {
        Write-Warn 'Android SDK not yet initialised.'
        Write-Info 'Launch Android Studio, complete the setup wizard, then re-run this script.'
        $script:NeedsAndroidInit = $true
        return
    }

    [Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidSdkRoot, 'User')
    $env:ANDROID_HOME = $androidSdkRoot
    Add-ToUserPath "$androidSdkRoot\platform-tools"
    Add-ToUserPath "$androidSdkRoot\emulator"
    Write-Pass "ANDROID_HOME set to: $androidSdkRoot"

    $sdkManager = @(
        "$androidSdkRoot\cmdline-tools\latest\bin\sdkmanager.bat",
        "$androidSdkRoot\tools\bin\sdkmanager.bat"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $sdkManager) {
        Write-Warn 'sdkmanager not found. Install Command-line Tools via Android Studio SDK Manager, then re-run.'
        return
    }

    Write-Step 'Installing Android SDK packages...'

    $pkgPlatform   = "platforms;android-$($AndroidApiLevel)"
    $pkgPlatformFB = "platforms;android-$($AndroidApiLevelFB)"
    $pkgBuildTools = "build-tools;$($AndroidApiLevel).0.0"
    $pkgSysImg     = "system-images;android-$($AndroidApiLevel);google_apis_playstore;x86_64"
    $pkgSysImgFB   = "system-images;android-$($AndroidApiLevelFB);google_apis_playstore;x86_64"

    $packages = @(
        $pkgPlatform, $pkgPlatformFB, $pkgBuildTools,
        $pkgSysImg, $pkgSysImgFB,
        'platform-tools', 'emulator', 'cmdline-tools;latest'
    )

    foreach ($pkg in $packages) {
        Write-Info "  sdkmanager: $pkg"
        "y" | & $sdkManager $pkg "--sdk_root=$androidSdkRoot" 2>&1 | Out-Null
    }
    Write-Pass 'Android SDK packages installed'

    $avdManager = "$androidSdkRoot\cmdline-tools\latest\bin\avdmanager.bat"
    if (Test-Path $avdManager) {
        Write-Step "Creating Pixel 8 Pro AVD (Android $($AndroidApiLevel))..."
        "no" | & $avdManager create avd `
            --name 'Pixel_8_Pro_API_36' `
            --package $pkgSysImg `
            --device 'pixel_8_pro' `
            --force 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) { Write-Pass "AVD 'Pixel_8_Pro_API_36' created" }
        else { Write-Warn 'AVD creation failed. Create it manually in Android Studio AVD Manager.' }
    }
    else {
        Write-Warn 'avdmanager not found. Create the AVD manually in Android Studio.'
    }
}

# ---------------------------------------------------------------------------
# Flutter
# ---------------------------------------------------------------------------

function Install-Flutter {
    Write-Header 'Flutter SDK'

    $flutterBat = "$FlutterBinDir\flutter.bat"

    if (Test-Path $flutterBat) {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $allVerLines = (& $flutterBat --version 2>&1)
        $ErrorActionPreference = $prevEAP
        $verLine = ($allVerLines | Where-Object { $_.ToString() -match '^Flutter ' } | Select-Object -First 1).ToString()
        if (-not $verLine) { $verLine = $allVerLines | Select-Object -Last 1 }
        Write-Pass "Flutter already installed: $verLine"
        Add-ToUserPath $FlutterBinDir
        return
    }

    $zipFileName = "flutter_windows_$($FlutterVersion)-stable.zip"
    $zipUrl  = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$zipFileName"
    $zipPath = "$env:TEMP\flutter.zip"

    Write-Step "Downloading Flutter $FlutterVersion..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Pass 'Flutter ZIP downloaded'
    }
    catch {
        Write-Fail "Flutter download failed: $_"
        Write-Info 'Download manually from https://flutter.dev/docs/get-started/install/windows'
        return
    }

    Write-Step "Extracting Flutter to $FlutterInstallDir..."
    if (Test-Path $FlutterInstallDir) { Remove-Item $FlutterInstallDir -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath 'C:\' -Force
    Remove-Item $zipPath -Force
    Write-Pass "Flutter extracted to $FlutterInstallDir"

    Add-ToUserPath $FlutterBinDir
    $env:PATH = "$env:PATH;$FlutterBinDir"

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    & $flutterBat config --no-analytics 2>&1 | Out-Null
    Write-Step 'Accepting Android SDK licenses...'
    "y`ny`ny`ny`ny`ny`ny" | & $flutterBat doctor --android-licenses 2>&1 | Out-Null
    $ErrorActionPreference = $prevEAP

    Write-Pass "Flutter $FlutterVersion installed"
}

# ---------------------------------------------------------------------------
# VS Code
# ---------------------------------------------------------------------------

function Install-VSCode {
    Write-Header 'Visual Studio Code'

    if ($SkipVSCode) { Write-Info 'Skipped via -SkipVSCode flag'; return }

    if (Test-Command 'code') {
        Write-Pass 'VS Code already installed'
    }
    else {
        Invoke-WingetInstall -Id 'Microsoft.VisualStudioCode' -Name 'VS Code'
        $vscodeBin = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
        Add-ToUserPath $vscodeBin
        $env:PATH = "$env:PATH;$vscodeBin"
    }

    if (Test-Command 'code') {
        Write-Step 'Installing VS Code extensions...'
        $extensions = @(
            'Dart-Code.flutter',
            'Dart-Code.dart-code',
            'usernamehw.errorlens',
            'streetsidesoftware.code-spell-checker',
            'eamodio.gitlens'
        )
        foreach ($ext in $extensions) {
            Write-Info "  $ext"
            & code --install-extension $ext --force 2>&1 | Out-Null
        }
        Write-Pass 'VS Code extensions installed'
    }
    else {
        Write-Warn 'VS Code not in PATH for this session. Extensions will need to be installed after restarting terminal.'
    }
}

# ---------------------------------------------------------------------------
# Node.js + Claude Code
# ---------------------------------------------------------------------------

function Install-NodeAndClaudeCode {
    Write-Header 'Node.js + Claude Code'

    if ($SkipClaudeCode) { Write-Info 'Skipped via -SkipClaudeCode flag'; return }

    if (Test-Command 'node') {
        Write-Pass "Node.js already installed: $((node --version).ToString().Trim())"
    }
    else {
        Invoke-WingetInstall -Id 'OpenJS.NodeJS.LTS' -Name 'Node.js LTS'
        $nodeBin = 'C:\Program Files\nodejs'
        Add-ToMachinePath $nodeBin
        $env:PATH = "$env:PATH;$nodeBin"
    }

    if (Test-Command 'claude') {
        Write-Pass "Claude Code already installed: $((claude --version 2>&1).ToString().Trim())"
    }
    elseif (Test-Command 'npm') {
        Write-Step 'Installing Claude Code globally...'
        & npm install -g '@anthropic-ai/claude-code' 2>&1 | Out-Null
        if (Test-Command 'claude') { Write-Pass 'Claude Code installed' }
        else { Write-Warn 'Claude Code installed but not in PATH yet. Open a new terminal and run: claude --version' }
    }
    else {
        Write-Warn 'npm not available in this session. After restarting terminal run: npm install -g @anthropic-ai/claude-code'
    }
}

# ---------------------------------------------------------------------------
# Kokoro TTS model setup
# ---------------------------------------------------------------------------

function Install-KokoroModels {
    Write-Header 'Kokoro TTS model setup'

    $repoRoot  = $PSScriptRoot
    $sourceDir = $null

    $candidate = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'kokoro' } | Select-Object -First 1
    if ($candidate) { $sourceDir = $candidate.FullName }

    if (-not $sourceDir) {
        $looseOnnx = Get-ChildItem -Path $repoRoot -Filter '*.onnx' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'kokoro' } | Select-Object -First 1
        if ($looseOnnx) { $sourceDir = $repoRoot }
    }

    if (-not $sourceDir) {
        $archiveName = 'kokoro-en-v0_19.tar.bz2'
        $downloadUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$archiveName"
        $archivePath = Join-Path $repoRoot $archiveName

        Write-Step "Kokoro models not found locally. Downloading (~335 MB)..."
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Pass "Download complete: $archiveName"
        }
        catch {
            Write-Fail "Download failed: $_"
            Write-Info 'Download manually from: https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2'
            return
        }

        $sevenZipExe = $null
        foreach ($c in @('C:\Program Files\7-Zip\7z.exe','C:\Program Files (x86)\7-Zip\7z.exe')) {
            if (Test-Path $c) { $sevenZipExe = $c; break }
        }
        if (-not $sevenZipExe) {
            $prevEAP2 = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
            & winget install --id 7zip.7zip --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            $ErrorActionPreference = $prevEAP2
            foreach ($c in @('C:\Program Files\7-Zip\7z.exe','C:\Program Files (x86)\7-Zip\7z.exe')) {
                if (Test-Path $c) { $sevenZipExe = $c; break }
            }
        }
        if (-not $sevenZipExe) {
            Write-Fail '7-Zip not found after install attempt.'
            Write-Info "Manual fix: install 7-Zip from https://7-zip.org then run:"
            Write-Info "  `"C:\Program Files\7-Zip\7z.exe`" x `"$archivePath`" -o`"$repoRoot`" -y"
            Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
            return
        }
        Write-Pass "7-Zip found: $sevenZipExe"

        Write-Step "Extracting $archiveName..."
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
        & $sevenZipExe x $archivePath "-o$repoRoot" -y 2>&1 | Out-Null
        $tarPath = $archivePath -replace '\.bz2$', ''
        if (Test-Path $tarPath) {
            & $sevenZipExe x $tarPath "-o$repoRoot" -y 2>&1 | Out-Null
            Remove-Item $tarPath -Force -ErrorAction SilentlyContinue
        }
        $tarExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue

        if ($tarExit -ne 0) { Write-Fail "Extraction failed (exit: $tarExit)."; return }
        Write-Pass 'Extraction complete'

        $candidate = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'kokoro' } | Select-Object -First 1
        if ($candidate) { $sourceDir = $candidate.FullName }
        else { Write-Fail 'Could not locate extracted model directory.'; return }
    }

    Write-Pass "Found Kokoro source at: $sourceDir"

    $flutterProjectRoot = $null
    if (Test-Path (Join-Path $repoRoot 'pubspec.yaml')) {
        $flutterProjectRoot = $repoRoot
    }
    else {
        $nested = Get-ChildItem -Path $repoRoot -Filter 'pubspec.yaml' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($nested) { $flutterProjectRoot = $nested.DirectoryName }
    }

    if (-not $flutterProjectRoot) {
        Write-Warn 'Flutter project (pubspec.yaml) not found. Re-run after project is created.'
        return
    }

    $targetDir = Join-Path (Join-Path $flutterProjectRoot 'assets') 'tts_models'
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

    Write-Step 'Copying model files...'

    $onnxSrc = Get-ChildItem -Path $sourceDir -Filter '*.onnx' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($onnxSrc) {
        Copy-Item $onnxSrc.FullName -Destination (Join-Path $targetDir 'kokoro-v0_19.onnx') -Force
        Write-Pass "  kokoro-v0_19.onnx ($([math]::Round($onnxSrc.Length / 1MB, 1)) MB)"
    }
    else { Write-Warn '  No .onnx file found in source directory' }

    foreach ($file in @('voices.bin','tokens.txt')) {
        $src = Join-Path $sourceDir $file
        if (Test-Path $src) {
            Copy-Item $src -Destination (Join-Path $targetDir $file) -Force
            Write-Pass "  $file"
        }
        else { Write-Warn "  $file not found" }
    }

    $espeakSrc = Join-Path $sourceDir 'espeak-ng-data'
    if (Test-Path $espeakSrc) {
        $espeakDest = Join-Path $targetDir 'espeak-ng-data'
        if (Test-Path $espeakDest) { Remove-Item $espeakDest -Recurse -Force }
        Copy-Item $espeakSrc -Destination $espeakDest -Recurse -Force
        $fileCount = (Get-ChildItem $espeakDest -Recurse -File).Count
        Write-Pass "  espeak-ng-data/ ($fileCount files)"
    }
    else { Write-Warn '  espeak-ng-data/ directory not found' }

    $totalMB = [math]::Round(
        ((Get-ChildItem $targetDir -Recurse -File | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
    Write-Pass "Kokoro TTS models installed ($totalMB MB total in assets/tts_models/)"
}

# ---------------------------------------------------------------------------
# Flutter project scaffold
# ---------------------------------------------------------------------------

function New-FlutterProject {
    Write-Header 'Flutter project scaffold'

    $repoRoot   = $PSScriptRoot
    $projectDir = $repoRoot
    $flutterBat = "$FlutterBinDir\flutter.bat"

    if (-not (Test-Path $flutterBat)) {
        Write-Warn 'Flutter not found -- cannot scaffold project. Install Flutter first.'
        return
    }

    # -----------------------------------------------------------------------
    # 1. Create Flutter project if it doesn't exist
    # -----------------------------------------------------------------------
    if (Test-Path (Join-Path $projectDir 'pubspec.yaml')) {
        Write-Pass "Flutter project already exists at: $projectDir"
    }
    else {
        Write-Step "Creating Flutter project in: $projectDir"
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
        Push-Location $projectDir
        & $flutterBat create . --org com.threadcast --platforms android,ios --project-name threadcast 2>&1 | Out-Null
        Pop-Location
        $ErrorActionPreference = $prevEAP

        if (Test-Path (Join-Path $projectDir 'pubspec.yaml')) { Write-Pass 'Flutter project created' }
        else { Write-Fail 'flutter create failed.'; return }
    }

    # -----------------------------------------------------------------------
    # 2. Write pubspec.yaml
    #    Dependencies chosen for active maintenance and long-term viability:
    #      drift + drift_flutter  : actively maintained SQLite ORM (replaces unmaintained isar)
    #      ffmpeg_kit_flutter_new : community fork of retired ffmpeg_kit_flutter (same API)
    #    NOTE: ffmpeg_kit_flutter_new downloads its Android AAR at Gradle build time.
    #          The FIRST build will fail with a download error. Run flutter run TWICE.
    # -----------------------------------------------------------------------
    Write-Step 'Writing pubspec.yaml...'
    $pubspecPath = Join-Path $projectDir 'pubspec.yaml'
    $pubspec = @'
name: threadcast
description: Reddit posts converted to on-device AI podcasts
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management & navigation
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^17.0.0

  # Networking
  dio: ^5.4.0

  # Reddit OAuth
  flutter_web_auth_2: ^5.0.1
  flutter_secure_storage: ^10.0.0

  # TTS
  sherpa_onnx: ^1.12.0

  # Audio playback
  just_audio: ^0.10.5

  # Audio export -- ffmpeg_kit_flutter was retired Jan 2025.
  # ffmpeg_kit_flutter_new is the original author's recommended community fork.
  # IMPORTANT: The first Gradle build will fail (AAR download incomplete).
  #            Run `flutter run` a second time and it will succeed.
  ffmpeg_kit_flutter_new: ^4.1.0

  # Database -- drift replaces unmaintained isar (abandoned 2023).
  # drift is actively maintained by simolus3 and widely used.
  drift: ^2.28.0
  drift_flutter: ^0.2.0     # handles SQLite native libs on Android + iOS
  path_provider: ^2.1.0

  # Sharing & export
  share_plus: ^12.0.1

  # Utilities
  uuid: ^4.3.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0      # used by both riverpod_generator and drift_dev
  drift_dev: ^2.28.0        # drift code generator (replaces isar_generator)
  flutter_lints: ^4.0.0
  # analyzer is intentionally not pinned -- drift_dev and riverpod_generator
  # both require analyzer ^6.x or ^7.x and pub resolves it automatically.

flutter:
  uses-material-design: true
  assets:
    - assets/tts_models/kokoro-v0_19.onnx
    - assets/tts_models/voices.bin
    - assets/tts_models/tokens.txt
    - assets/tts_models/espeak-ng-data/
'@
    Set-Content -Path $pubspecPath -Value $pubspec -NoNewline
    Write-Pass 'pubspec.yaml written'

    # -----------------------------------------------------------------------
    # 3. Create directory structure
    # -----------------------------------------------------------------------
    Write-Step 'Creating directory structure...'
    $dirs = @(
        'lib\core',
        'lib\features\onboarding',
        'lib\features\create\widgets',
        'lib\features\player\widgets',
        'lib\features\library\widgets',
        'lib\services\reddit\models',
        'lib\services\llm\models',
        'lib\services\tts',
        'lib\models',
        'lib\shared\widgets',
        'lib\shared\theme',
        'android\app\src\main\kotlin\com\threadcast\app\llm',
        'assets/tts_models'
    )
    foreach ($d in $dirs) {
        $fullPath = Join-Path $projectDir $d
        if (-not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
    }
    Write-Pass 'Directory structure created'

    # -----------------------------------------------------------------------
    # 4. Write Episode model (Drift schema)
    # -----------------------------------------------------------------------
    Write-Step 'Writing Episode model (Drift schema)...'
    $episodeDart = @'
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'episode.g.dart';

enum EpisodeStatus { pending, generating, complete, failed }

// Drift table definition -- generates type-safe query methods via build_runner.
// Run: dart run build_runner build --delete-conflicting-outputs
class Episodes extends Table {
  IntColumn    get id                 => integer().autoIncrement()();
  TextColumn   get episodeId          => text()();
  TextColumn   get title              => text()();
  TextColumn   get subreddit          => text()();
  // List<String> stored as JSON -- Drift does not support List columns natively.
  // Use AppDatabase.decodeUrls() / encodeUrls() helpers when reading/writing.
  TextColumn   get sourceUrlsJson     => text()();
  TextColumn   get tone               => text()();
  DateTimeColumn get createdAt        => dateTime()();
  IntColumn    get durationSeconds    => integer()();
  TextColumn   get audioWavPath       => text().nullable()();
  TextColumn   get audioMp3Path       => text().nullable()();
  TextColumn   get transcriptJsonPath => text().nullable()();
  // EpisodeStatus stored as int (0=pending, 1=generating, 2=complete, 3=failed)
  IntColumn    get status             => integer().withDefault(const Constant(0))();
  TextColumn   get errorMessage       => text().nullable()();
}

@DriftDatabase(tables: [Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Helper: encode List<String> -> JSON string for storage
  static String encodeUrls(List<String> urls) => jsonEncode(urls);

  // Helper: decode JSON string -> List<String> for reading
  static List<String> decodeUrls(String json) =>
      (jsonDecode(json) as List).cast<String>();

  // Helper: int -> EpisodeStatus enum
  static EpisodeStatus decodeStatus(int i) => EpisodeStatus.values[i];

  // Helper: EpisodeStatus enum -> int
  static int encodeStatus(EpisodeStatus s) => s.index;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'threadcast');
}
'@
    Set-Content -Path (Join-Path $projectDir 'lib\models\episode.dart') -Value $episodeDart -NoNewline
    Write-Pass 'lib/models/episode.dart written (Drift schema)'

    # -----------------------------------------------------------------------
    # 5. Write stub Dart files
    # -----------------------------------------------------------------------
function New-ProjectScaffold {
    param([string]$projectRoot)
    
    $stubs = @{}
    
    # Core Database Provider
    $stubs['lib\core\providers.dart'] = @'
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/episode.dart';

part 'providers.g.dart';

@riverpod
AppDatabase database(DatabaseRef ref) => AppDatabase();
'@

    # Feature Provider using Drift Companions
    $stubs['lib\features\create\create_provider.dart'] = @'
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart'; // REQUIRED for Value() and Companions
import '../../core/providers.dart';
import '../../models/episode.dart';

part 'create_provider.g.dart';

@riverpod
class CreateEpisode extends _$CreateEpisode {
  @override
  void build() {}

  Future<void> create(String title, String subreddit, List<String> urls) async {
    final db = ref.read(databaseProvider);
    
    final companion = EpisodesCompanion.insert(
      episodeId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subreddit: subreddit,
      sourceUrlsJson: AppDatabase.encodeUrls(urls),
      // Use Value() for fields that have defaults or are nullable
      status: const Value('queued'), 
      createdAt: DateTime.now(),
      tone: 'neutral',
      durationSeconds: 0,
    );

    await db.upsertEpisode(companion);
  }
}
'@

    foreach ($path in $stubs.Keys) {
        $fullPath = Join-Path $projectRoot $path
        $dir = Split-Path $fullPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
        Set-Content -Path $fullPath -Value $stubs[$path] -NoNewline
    }
}

    # -----------------------------------------------------------------------
    # 6. Native LLM stubs
    # -----------------------------------------------------------------------
    Write-Step 'Writing native LLM stub files...'

    $kotlinDir = Join-Path $projectDir 'android\app\src\main\kotlin\com\threadcast\app\llm'

    Set-Content -Path (Join-Path $kotlinDir 'GeminiNanoService.kt') -Value @'
package com.threadcast.app.llm

// TODO: Implement Gemini Nano via ML Kit GenAI Prompt API
// Dependency: implementation("com.google.mlkit:genai-prompt:1.0.0-beta1")
// See CLAUDE.md -- Android: Gemini Nano via ML Kit GenAI Prompt API
class GeminiNanoService {
    suspend fun isAvailable(): Boolean = false  // TODO
    suspend fun generateTranscript(prompt: String): String = ""  // TODO
    fun release() {}
}
'@ -NoNewline

    Set-Content -Path (Join-Path $kotlinDir 'LlmPlugin.kt') -Value @'
package com.threadcast.app.llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// TODO: Implement full LLM platform channel
// See CLAUDE.md -- Android: Gemini Nano via ML Kit GenAI Prompt API
class LlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val service = GeminiNanoService()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.threadcast.app/llm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable"         -> result.success(false)
            "generateTranscript"  -> result.error("NOT_IMPLEMENTED", "TODO", null)
            "cancelGeneration"    -> result.success(null)
            else                  -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        service.release()
    }
}
'@ -NoNewline

    $iosLlmDir = Join-Path $projectDir 'ios\Runner\llm'
    if (-not (Test-Path $iosLlmDir)) { New-Item -ItemType Directory -Path $iosLlmDir -Force | Out-Null }

    Set-Content -Path (Join-Path $iosLlmDir 'FoundationModelService.swift') -Value @'
import Foundation

// TODO: Implement Foundation Models integration
// Requires iOS 26+, and the Foundation Models entitlement must be enabled in Xcode:
//   Signing & Capabilities -> + Capability -> Foundation Models
// See CLAUDE.md -- iOS: Foundation Models Framework

@available(iOS 26.0, *)
class FoundationModelService {
    func isAvailable() -> Bool { return false }  // TODO
    func generateTranscript(prompt: String) async throws -> String { return "" }  // TODO
}
'@ -NoNewline

    Set-Content -Path (Join-Path $iosLlmDir 'LlmPlugin.swift') -Value @'
import Flutter
import UIKit

// TODO: Implement full LLM platform channel
// See CLAUDE.md -- iOS: Foundation Models Framework
class LlmPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.threadcast.app/llm",
            binaryMessenger: registrar.messenger()
        )
        let instance = LlmPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(false)  // TODO: check SystemLanguageModel.default.availability
        case "generateTranscript":
            result(FlutterError(code: "NOT_IMPLEMENTED", message: "TODO", details: nil))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
'@ -NoNewline

    Write-Pass 'Native LLM stub files written'

    # -----------------------------------------------------------------------
    # 7. Patch AndroidManifest.xml
    # -----------------------------------------------------------------------
    Write-Step 'Patching AndroidManifest.xml...'
    $manifestPath = Join-Path $projectDir 'android\app\src\main\AndroidManifest.xml'
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw
        # Deduplicate any extra deep-link intent-filters from previous runs
        # (keep only first occurrence between the </intent-filter> boundary)
        $deepLinkBlock = '(?s)(\s*<intent-filter android:autoVerify="true">\s*<action android:name="android\.intent\.action\.VIEW"/>.*?</intent-filter>)'
        $matches_ = [regex]::Matches($manifest, $deepLinkBlock)
        if ($matches_.Count -gt 1) {
            # Remove all but the first deep-link filter
            for ($di = $matches_.Count - 1; $di -ge 1; $di--) {
                $manifest = $manifest.Remove($matches_[$di].Index, $matches_[$di].Length)
            }
            Set-Content -Path $manifestPath -Value $manifest -NoNewline
        }

        foreach ($perm in @(
            'android.permission.INTERNET',
            'android.permission.WAKE_LOCK'
        )) {
            if ($manifest -notmatch [regex]::Escape($perm)) {
                $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"$perm`"/>"
            }
        }

        $deepLink = @'

            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="threadcast" android:host="oauth"/>
            </intent-filter>
'@
        # Only add if not already present (re-read to catch partial prior writes)
        $manifest = Get-Content $manifestPath -Raw
        if ($manifest -notmatch 'scheme=.threadcast.') {
            $manifest = $manifest -replace '(</activity>)', "$deepLink`$1"
        }

        Set-Content -Path $manifestPath -Value $manifest -NoNewline
        Write-Pass 'AndroidManifest.xml patched'
    }
    else {
        Write-Warn 'AndroidManifest.xml not found -- patch it manually per CLAUDE.md'
    }

    # -----------------------------------------------------------------------
    # 8. Patch android/app/build.gradle.kts -- set minSdk to 36
    # -----------------------------------------------------------------------
    Write-Step 'Patching android/app/build.gradle.kts (minSdk = 36)...'
    $buildGradlePath = Join-Path $projectDir 'android\app\build.gradle.kts'
    if (Test-Path $buildGradlePath) {
        $buildGradle = Get-Content $buildGradlePath -Raw
        if ($buildGradle -match 'minSdk\s*=\s*flutter\.minSdkVersion') {
            $buildGradle = $buildGradle -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 36'
            Set-Content -Path $buildGradlePath -Value $buildGradle -NoNewline
            Write-Pass 'minSdk set to 36 (Android 16 -- required for AICore / Gemini Nano)'
        }
        else {
            Write-Info 'minSdk already patched or uses a different pattern -- check manually'
        }

        # Also fix applicationId if it still has the wrong bundle ID
        if ($buildGradle -match 'applicationId\s*=\s*"com\.threadcast\.threadcast"') {
            $buildGradle = Get-Content $buildGradlePath -Raw
            $buildGradle = $buildGradle -replace 'applicationId\s*=\s*"com\.threadcast\.threadcast"', 'applicationId = "com.threadcast.app"'
            Set-Content -Path $buildGradlePath -Value $buildGradle -NoNewline
            Write-Pass 'applicationId corrected to com.threadcast.app'
        }
    }
    else {
        Write-Warn 'android/app/build.gradle.kts not found -- set minSdk = 36 manually'
    }

    # -----------------------------------------------------------------------
    # 9. Patch iOS Info.plist
    # -----------------------------------------------------------------------
    Write-Step 'Patching ios/Runner/Info.plist...'
    $plistPath = Join-Path $projectDir 'ios\Runner\Info.plist'
    if (Test-Path $plistPath) {
        $plist = Get-Content $plistPath -Raw

        $entriesToAdd = [ordered]@{
            'CFBundleURLTypes' = @'
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>threadcast</string>
		</array>
	</dict>
</array>
'@
            'NSMicrophoneUsageDescription' = @'
<key>NSMicrophoneUsageDescription</key>
<string>Threadcast does not use the microphone.</string>
'@
            'UIBackgroundModes' = @'
<key>UIBackgroundModes</key>
<array>
	<string>processing</string>
	<string>audio</string>
</array>
'@
            'BGTaskSchedulerPermittedIdentifiers' = @'
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
	<string>com.threadcast.app.generate</string>
</array>
'@
        }

        foreach ($key in $entriesToAdd.Keys) {
            if ($plist -notmatch "<key>$key</key>") {
                $plist = $plist -replace '(</dict>\s*</plist>)', "$($entriesToAdd[$key])`$1"
            }
        }

        Set-Content -Path $plistPath -Value $plist -NoNewline
        Write-Pass 'Info.plist patched'
    }
    else {
        Write-Warn 'Info.plist not found -- patch it manually per CLAUDE.md'
    }

    # -----------------------------------------------------------------------
    # 10. Add .vscode/settings.json for format on save
    # -----------------------------------------------------------------------
    Write-Step 'Writing .vscode/settings.json...'
    $vscodeDir = Join-Path $projectDir '.vscode'
    if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }
    $vsSettings = @'
{
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true
  },
  "[kotlin]": {
    "editor.formatOnSave": true
  }
}
'@
    Set-Content -Path (Join-Path $vscodeDir 'settings.json') -Value $vsSettings -NoNewline
    Write-Pass '.vscode/settings.json written'

    # -----------------------------------------------------------------------
    # 11. Add pre-commit hook
    # -----------------------------------------------------------------------
    Write-Step 'Writing git pre-commit hook...'
    $hooksDir = Join-Path $projectDir '.git\hooks'
    if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
    $hookScript = "#!/bin/sh`ndart format --set-exit-if-changed .`nif [ `$? -ne 0 ]; then`n  echo `"Dart formatting issues found. Run 'dart format .' to fix.`"`n  exit 1`nfi`n"
    [System.IO.File]::WriteAllText("$projectDir\.git\hooks\pre-commit", $hookScript)
    $chmodExe = 'C:\Program Files\Git\usr\bin\chmod.exe'
    if (Test-Path $chmodExe) {
        & $chmodExe +x "$projectDir\.git\hooks\pre-commit"
        Write-Pass 'Pre-commit hook installed (dart format on commit)'
    }
    else {
        Write-Warn 'chmod.exe not found -- hook created but may not be executable. Run: git update-index --chmod=+x .git/hooks/pre-commit'
    }

    # -----------------------------------------------------------------------
    # 12. flutter pub get
    # -----------------------------------------------------------------------
    Write-Step 'Running flutter pub get...'
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    Push-Location $projectDir
    Write-Host ''
    & $flutterBat pub get
    $pubGetExit = $LASTEXITCODE
    Write-Host ''
    Pop-Location
    $ErrorActionPreference = $prevEAP

    if ($pubGetExit -eq 0) {
        Write-Pass 'flutter pub get succeeded'
    }
    else {
        Write-Warn "flutter pub get failed (exit code: $pubGetExit) -- see output above"
        Write-Info 'Try running manually: flutter pub get'
    }

    # -----------------------------------------------------------------------
    # 13. Generate Drift code (episode.g.dart)
    # -----------------------------------------------------------------------
    Write-Step 'Running drift code generation (dart run build_runner build)...'
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    Push-Location $projectDir
    Write-Host ''
    & $flutterBat packages pub run build_runner build --delete-conflicting-outputs
    $buildRunnerExit = $LASTEXITCODE
    Write-Host ''
    Pop-Location
    $ErrorActionPreference = $prevEAP

    if ($buildRunnerExit -eq 0) {
        Write-Pass 'Drift code generation succeeded (episode.g.dart created)'
    }
    else {
        Write-Warn "build_runner failed (exit code: $buildRunnerExit)"
        Write-Info 'Try manually: dart run build_runner build --delete-conflicting-outputs'
    }

    # -----------------------------------------------------------------------
    # 14. Initial git commit
    # -----------------------------------------------------------------------
    if (Test-Command 'git') {
        Write-Step 'Creating initial git commit...'
        Push-Location $projectDir
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
        & git config core.autocrlf true 2>&1 | Out-Null
        $gitStatus = & git status --porcelain 2>&1
        if ($gitStatus) {
            & git add -A 2>&1 | Out-Null
            & git commit -m 'init: Flutter project scaffold + CLAUDE.md + TTS models' 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Pass 'Initial git commit created' }
            else { Write-Warn 'git commit failed -- commit manually: git add -A -and- git commit -m "init"' }
        }
        else { Write-Pass 'Nothing to commit -- working tree clean' }
        $ErrorActionPreference = $prevEAP
        Pop-Location
    }

    Write-Pass "Project scaffold complete: $projectDir"
    Write-Info "Next: cd $projectDir  then  claude"
}

# ---------------------------------------------------------------------------
# Flutter doctor
# ---------------------------------------------------------------------------

function Invoke-FlutterDoctor {
    Write-Header 'Flutter doctor'

    $flutterBat = "$FlutterBinDir\flutter.bat"
    if (-not (Test-Path $flutterBat)) {
        Write-Warn 'Flutter not found. Run flutter doctor manually after restarting your terminal.'
        return
    }

    Write-Step 'Running flutter doctor...'
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $doctorOutput = & $flutterBat doctor -v 2>&1
    $ErrorActionPreference = $prevEAP
    $doctorOutput | ForEach-Object {
        $line = $_.ToString()
        if     ($line -match '^\[v\]|^\[OK\]|^  \.')  { Write-Host "  $line" -ForegroundColor Green  }
        elseif ($line -match '^\[X\]|^\[!\]')          { Write-Host "  $line" -ForegroundColor Yellow }
        elseif ($line.Trim() -ne '')                    { Write-Host "  $line" -ForegroundColor DarkGray }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

function Write-Summary {
    Write-Header 'Setup summary'

    Write-Host ''
    Write-Host "  Passed  : $script:PassCount" -ForegroundColor Green
    Write-Host "  Warnings: $script:WarnCount" -ForegroundColor Yellow
    Write-Host "  Failed  : $script:FailCount" -ForegroundColor Red
    Write-Host ''

    if ($script:NeedsAndroidInit) {
        Write-Host '  ACTION REQUIRED - Android Studio first-run:' -ForegroundColor Yellow
        Write-Host '    1. Open Android Studio from the Start menu'         -ForegroundColor White
        Write-Host '    2. Complete the setup wizard (accept all defaults)'  -ForegroundColor White
        Write-Host '    3. Wait for the initial SDK download to finish'      -ForegroundColor White
        Write-Host '    4. Close Android Studio'                             -ForegroundColor White
        Write-Host '    5. Re-run this script'                               -ForegroundColor White
        Write-Host ''
    }

    Write-Host '  IMPORTANT -- ffmpeg_kit_flutter_new first-build quirk:' -ForegroundColor Yellow
    Write-Host '    The first `flutter run` or `flutter build` will fail with an AAR' -ForegroundColor White
    Write-Host '    download error. This is expected and documented behavior.'         -ForegroundColor White
    Write-Host '    Run the same command a SECOND time and it will succeed.'           -ForegroundColor White
    Write-Host ''

    Write-Host '  Next steps:' -ForegroundColor Cyan
    Write-Host '    1. Open a new terminal (PATH changes take effect in new windows)'  -ForegroundColor White
    Write-Host '    2. Run: flutter doctor -- fix any [!] or [X] items'                -ForegroundColor White
    Write-Host '    3. Submit Reddit API approval: support.reddithelp.com'            -ForegroundColor White
    Write-Host '    4. cd D:\github\Threadcast  then  claude'                         -ForegroundColor White
    Write-Host ''
    Write-Host '  iOS note:' -ForegroundColor Cyan
    Write-Host '    iOS builds require macOS + Xcode. Use Codemagic CI (Issue #27).'  -ForegroundColor White
    Write-Host '    https://codemagic.io (500 free minutes/month)'                    -ForegroundColor DarkGray
    Write-Host ''

    if ($script:FailCount -gt 0) {
        Write-Host '  Some steps failed. Review the [XX] items above before proceeding.' -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ''
Write-Host '  ================================================================' -ForegroundColor Cyan
Write-Host '   THREADCAST  -  Windows Developer Environment Setup'              -ForegroundColor Cyan
Write-Host '   Flutter + Android Studio + JDK 17 + Node + Claude Code + TTS'   -ForegroundColor DarkGray
Write-Host '   Database: drift  |  FFmpeg: ffmpeg_kit_flutter_new'              -ForegroundColor DarkGray
Write-Host '  ================================================================' -ForegroundColor Cyan
Write-Host ''

Test-Preflight
Install-Git
Install-Jdk
Install-AndroidStudio
Install-Flutter
Install-VSCode
Install-NodeAndClaudeCode
Install-KokoroModels
New-FlutterProject
Invoke-FlutterDoctor
Write-Summary
