#Requires -Version 5.1
<#
.SYNOPSIS
    Threadcast development environment setup for Windows.
.DESCRIPTION
    Installs and configures all tools required to build and run Threadcast.
    Downloads the Kokoro TTS model files into assets/tts_models/.
    Runs flutter pub get and build_runner on the existing project.

    This script is a standup script only. It does not create, modify, or patch
    any source files, manifests, Gradle files, or project configuration.
    All source code lives in the repository.
.PARAMETER SkipVSCode
    Skip VS Code and extension installation.
.PARAMETER SkipClaudeCode
    Skip Node.js and Claude Code installation.
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

# Kokoro multi-lang v1.0 — English + Chinese, 53 speakers
# Model file inside archive: model.onnx
$KokoroArchiveName = 'kokoro-multi-lang-v1_0.tar.bz2'
$KokoroDownloadUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$KokoroArchiveName"
$KokoroDirPattern  = 'kokoro-multi-lang-v1_0'

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
    $zipUrl      = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$zipFileName"
    $zipPath     = "$env:TEMP\flutter.zip"

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
# 7-Zip (required for .tar.bz2 model extraction)
# ---------------------------------------------------------------------------

function Get-SevenZip {
    foreach ($candidate in @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    Write-Step 'Installing 7-Zip...'
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    & winget install --id 7zip.7zip --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    $ErrorActionPreference = $prevEAP

    foreach ($candidate in @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}

# ---------------------------------------------------------------------------
# Kokoro TTS model files
# Downloads kokoro-multi-lang-v1_0 and copies model files to assets/tts_models/.
# These binary files are gitignored and must be present locally to build.
# ---------------------------------------------------------------------------

function Install-KokoroModels {
    Write-Header 'Kokoro TTS model files'

    $repoRoot  = $PSScriptRoot
    $targetDir = Join-Path $repoRoot 'assets\tts_models'

    if (-not (Test-Path (Join-Path $repoRoot 'pubspec.yaml'))) {
        Write-Fail 'pubspec.yaml not found. Run this script from the repository root.'
        return
    }

    # Presence of model.onnx is the sentinel for a complete install.
    $onnxDest = Join-Path $targetDir 'model.onnx'
    if (Test-Path $onnxDest) {
        $sizeMB = [math]::Round((Get-Item $onnxDest).Length / 1MB, 1)
        Write-Pass "Kokoro model already present ($sizeMB MB) -- skipping download"
        return
    }

    # Check for a previously extracted source directory alongside the script.
    $sourceDir = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$KokoroDirPattern*" } | Select-Object -First 1 |
        ForEach-Object { $_.FullName }

    if (-not $sourceDir) {
        $archivePath = Join-Path $repoRoot $KokoroArchiveName
        Write-Step "Downloading Kokoro v1.0 (~600 MB)..."
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $KokoroDownloadUrl -OutFile $archivePath -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Pass "Downloaded: $KokoroArchiveName"
        }
        catch {
            Write-Fail "Download failed: $_"
            Write-Info "Download manually from: $KokoroDownloadUrl"
            return
        }

        $sevenZip = Get-SevenZip
        if (-not $sevenZip) {
            Write-Fail '7-Zip not found after install attempt.'
            Write-Info "Install 7-Zip from https://7-zip.org then run:"
            Write-Info "  `"C:\Program Files\7-Zip\7z.exe`" x `"$archivePath`" -o`"$repoRoot`" -y"
            Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
            return
        }
        Write-Pass "7-Zip: $sevenZip"

        Write-Step "Extracting $KokoroArchiveName..."
        $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
        & $sevenZip x $archivePath "-o$repoRoot" -y 2>&1 | Out-Null
        $tarPath = $archivePath -replace '\.bz2$', ''
        if (Test-Path $tarPath) {
            & $sevenZip x $tarPath "-o$repoRoot" -y 2>&1 | Out-Null
            Remove-Item $tarPath -Force -ErrorAction SilentlyContinue
        }
        $ErrorActionPreference = $prevEAP
        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Write-Pass 'Extraction complete'

        $sourceDir = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "$KokoroDirPattern*" } | Select-Object -First 1 |
            ForEach-Object { $_.FullName }

        if (-not $sourceDir) {
            Write-Fail 'Could not locate extracted model directory.'
            return
        }
    }

    Write-Pass "Model source: $sourceDir"

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Write-Step 'Copying model files to assets/tts_models/...'

    # model.onnx
    $onnxSrc = Get-ChildItem -Path $sourceDir -Filter '*.onnx' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($onnxSrc) {
        Copy-Item $onnxSrc.FullName -Destination $onnxDest -Force
        Write-Pass "  model.onnx ($([math]::Round($onnxSrc.Length / 1MB, 1)) MB)"
    }
    else { Write-Warn '  No .onnx file found in source directory' }

    # voices.bin, tokens.txt, lexicon-us-en.txt
    foreach ($file in @('voices.bin', 'tokens.txt', 'lexicon-us-en.txt')) {
        $src = Join-Path $sourceDir $file
        if (Test-Path $src) {
            Copy-Item $src -Destination (Join-Path $targetDir $file) -Force
            Write-Pass "  $file"
        }
        else { Write-Warn "  $file not found" }
    }

    # espeak-ng-data/
    $espeakSrc  = Join-Path $sourceDir 'espeak-ng-data'
    $espeakDest = Join-Path $targetDir 'espeak-ng-data'
    if (Test-Path $espeakSrc) {
        if (Test-Path $espeakDest) { Remove-Item $espeakDest -Recurse -Force }
        Copy-Item $espeakSrc -Destination $espeakDest -Recurse -Force
        $fileCount = (Get-ChildItem $espeakDest -Recurse -File).Count
        Write-Pass "  espeak-ng-data/ ($fileCount files)"
    }
    else { Write-Warn '  espeak-ng-data/ not found in source directory' }

    $totalMB = [math]::Round(
        ((Get-ChildItem $targetDir -Recurse -File | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
    Write-Pass "Kokoro models installed: $totalMB MB total in assets/tts_models/"
}

# ---------------------------------------------------------------------------
# Project dependencies
# Runs flutter pub get and regenerates Drift/Riverpod generated code.
# These outputs are gitignored and must be reproduced on each machine.
# Does not create, modify, or patch any source files.
# ---------------------------------------------------------------------------

function Initialize-ProjectDependencies {
    Write-Header 'Project dependencies'

    $repoRoot   = $PSScriptRoot
    $flutterBat = "$FlutterBinDir\flutter.bat"

    if (-not (Test-Path $flutterBat)) {
        Write-Warn 'Flutter not found -- skipping pub get and build_runner. Run manually after setup.'
        return
    }

    if (-not (Test-Path (Join-Path $repoRoot 'pubspec.yaml'))) {
        Write-Warn 'pubspec.yaml not found -- skipping. Run this script from the repository root.'
        return
    }

    # flutter pub get
    Write-Step 'Running flutter pub get...'
    Push-Location $repoRoot
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    Write-Host ''
    & $flutterBat pub get
    $pubGetExit = $LASTEXITCODE
    Write-Host ''
    $ErrorActionPreference = $prevEAP
    Pop-Location

    if ($pubGetExit -eq 0) {
        Write-Pass 'flutter pub get succeeded'
    }
    else {
        Write-Warn "flutter pub get failed (exit $pubGetExit) -- run manually: flutter pub get"
    }

    # build_runner regenerates episode.g.dart and Riverpod annotations.
    # These files are gitignored and must exist locally for the project to compile.
    Write-Step 'Running build_runner (generates episode.g.dart)...'
    Push-Location $repoRoot
    $prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    Write-Host ''
    & $flutterBat packages pub run build_runner build --delete-conflicting-outputs
    $buildRunnerExit = $LASTEXITCODE
    Write-Host ''
    $ErrorActionPreference = $prevEAP
    Pop-Location

    if ($buildRunnerExit -eq 0) {
        Write-Pass 'build_runner succeeded'
    }
    else {
        Write-Warn "build_runner failed (exit $buildRunnerExit) -- run manually: dart run build_runner build --delete-conflicting-outputs"
    }

    # Pre-commit hook -- git hooks are not tracked in source control and must
    # be installed per-machine. This enforces dart format before every commit.
    $hooksDir = Join-Path $repoRoot '.git\hooks'
    if (Test-Path $hooksDir) {
        $hookPath   = Join-Path $hooksDir 'pre-commit'
        $hookScript = "#!/bin/sh`ndart format --set-exit-if-changed .`nif [ `$? -ne 0 ]; then`n  echo `"Run 'dart format .' to fix formatting before committing.`"`n  exit 1`nfi`n"
        [System.IO.File]::WriteAllText($hookPath, $hookScript)

        $chmodExe = 'C:\Program Files\Git\usr\bin\chmod.exe'
        if (Test-Path $chmodExe) {
            & $chmodExe +x $hookPath
            Write-Pass 'Pre-commit hook installed (dart format)'
        }
        else {
            Write-Warn 'chmod.exe not found -- hook written but may not be executable. Run: git update-index --chmod=+x .git/hooks/pre-commit'
        }
    }
    else {
        Write-Info '.git/hooks not found -- skipping pre-commit hook'
    }
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
        if     ($line -match '^\[v\]|^\[OK\]|^  \.') { Write-Host "  $line" -ForegroundColor Green  }
        elseif ($line -match '^\[X\]|^\[!\]')         { Write-Host "  $line" -ForegroundColor Yellow }
        elseif ($line.Trim() -ne '')                   { Write-Host "  $line" -ForegroundColor DarkGray }
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
    Write-Host '    The first `flutter run` will fail with an AAR download error.'  -ForegroundColor White
    Write-Host '    This is expected. Run `flutter run` a second time to succeed.'  -ForegroundColor White
    Write-Host ''

    Write-Host '  Next steps:' -ForegroundColor Cyan
    Write-Host '    1. Open a new terminal (PATH changes take effect in new windows)' -ForegroundColor White
    Write-Host '    2. Run: flutter doctor  -- fix any [!] or [X] items'              -ForegroundColor White
    Write-Host '    3. Run: flutter run     -- run TWICE on first build'              -ForegroundColor White
    Write-Host '    4. Submit Reddit API approval: support.reddithelp.com'           -ForegroundColor White
    Write-Host ''
    Write-Host '  iOS note:' -ForegroundColor Cyan
    Write-Host '    iOS builds require macOS + Xcode. Use Codemagic CI (Issue #27).' -ForegroundColor White
    Write-Host '    https://codemagic.io (500 free build minutes/month)'             -ForegroundColor DarkGray
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
$OutputEncoding           = [System.Text.Encoding]::UTF8

Write-Host ''
Write-Host '  ================================================================' -ForegroundColor Cyan
Write-Host '   THREADCAST  -  Windows Developer Environment Setup'              -ForegroundColor Cyan
Write-Host '   Flutter + Android Studio + JDK 17 + Node + Claude Code + TTS'   -ForegroundColor DarkGray
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
Initialize-ProjectDependencies
Invoke-FlutterDoctor
Write-Summary