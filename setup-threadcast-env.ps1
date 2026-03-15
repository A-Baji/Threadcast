#Requires -Version 5.1
<#
.SYNOPSIS
    Threadcast development environment setup for Windows.

.DESCRIPTION
    Installs and configures all tools required to develop Threadcast:
    Flutter SDK, Android Studio, JDK 17, VS Code, Git, Node.js, Claude Code, Kokoro TTS models.
    Uses winget where available, direct download as fallback.

.NOTES
    Run this script from an elevated PowerShell prompt (Run as Administrator).
    Windows 10 21H1+ or Windows 11 required (winget dependency).
    Estimated runtime: 20-40 minutes depending on internet speed.
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

    # Try multiple endpoints - corporate firewalls often block specific hosts
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
        # Final fallback: DNS resolution check (works even when HTTP is blocked by proxy)
        try {
            $null = [System.Net.Dns]::GetHostAddresses('google.com')
            Write-Pass 'Internet connectivity: OK (DNS resolution succeeded)'
            $connected = $true
        }
        catch {
            Write-Info 'DNS resolution also failed'
        }
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
        # java -version writes to stderr by design. Suppress ErrorActionPreference
        # temporarily so PowerShell does not treat stderr as a terminating error.
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
        if ($found) {
            $jdkPath = $found.FullName
            break
        }
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

    # Use $() subexpressions to prevent PowerShell treating the dot as a
    # property accessor on the variable (e.g. $var.0 would be a parse error).
    $pkgPlatform   = "platforms;android-$($AndroidApiLevel)"
    $pkgPlatformFB = "platforms;android-$($AndroidApiLevelFB)"
    $pkgBuildTools = "build-tools;$($AndroidApiLevel).0.0"
    $pkgSysImg     = "system-images;android-$($AndroidApiLevel);google_apis_playstore;x86_64"
    $pkgSysImgFB   = "system-images;android-$($AndroidApiLevelFB);google_apis_playstore;x86_64"

    $packages = @(
        $pkgPlatform,
        $pkgPlatformFB,
        $pkgBuildTools,
        $pkgSysImg,
        $pkgSysImgFB,
        'platform-tools',
        'emulator',
        'cmdline-tools;latest'
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

        if ($LASTEXITCODE -eq 0) {
            Write-Pass "AVD 'Pixel_8_Pro_API_36' created"
        }
        else {
            Write-Warn 'AVD creation failed. Create it manually in Android Studio AVD Manager.'
        }
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
        # The version line starts with "Flutter" - skip build noise like "Resolving dependencies..."
        $verLine = ($allVerLines | Where-Object { $_.ToString() -match '^Flutter ' } | Select-Object -First 1).ToString()
        if (-not $verLine) { $verLine = $allVerLines | Select-Object -Last 1 }
        Write-Pass "Flutter already installed: $verLine"
        Add-ToUserPath $FlutterBinDir
        return
    }

    # Build the zip filename using a subexpression to avoid dot-property parse error
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
        Write-Info 'Extract to C:\flutter and add C:\flutter\bin to your PATH'
        return
    }

    Write-Step "Extracting Flutter to $FlutterInstallDir..."
    if (Test-Path $FlutterInstallDir) {
        Remove-Item $FlutterInstallDir -Recurse -Force
    }
    Expand-Archive -Path $zipPath -DestinationPath 'C:\' -Force
    Remove-Item $zipPath -Force
    Write-Pass "Flutter extracted to $FlutterInstallDir"

    Add-ToUserPath $FlutterBinDir
    $env:PATH = "$env:PATH;$FlutterBinDir"

    # flutter.bat writes to stderr during first-run tool compilation.
    # Suppress EAP so those messages don't terminate the script.
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    & $flutterBat config --no-analytics 2>&1 | Out-Null

    Write-Step 'Accepting Android SDK licenses...'
    "y`ny`ny`ny`ny`ny`ny" | & $flutterBat doctor --android-licenses 2>&1 | Out-Null

    $ErrorActionPreference = $prevEAP
    Write-Pass 'Android licenses accepted'

    Write-Pass "Flutter $FlutterVersion installed"
}

# ---------------------------------------------------------------------------
# VS Code
# ---------------------------------------------------------------------------

function Install-VSCode {
    Write-Header 'Visual Studio Code'

    if ($SkipVSCode) {
        Write-Info 'Skipped via -SkipVSCode flag'
        return
    }

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

    if ($SkipClaudeCode) {
        Write-Info 'Skipped via -SkipClaudeCode flag'
        return
    }

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
        if (Test-Command 'claude') {
            Write-Pass 'Claude Code installed'
        }
        else {
            Write-Warn 'Claude Code installed but not in PATH yet. Open a new terminal and run: claude --version'
        }
    }
    else {
        Write-Warn 'npm not available in this session. After restarting terminal run: npm install -g @anthropic-ai/claude-code'
    }
}

# ---------------------------------------------------------------------------
# Flutter project scaffold
# ---------------------------------------------------------------------------

function New-FlutterProject {
    Write-Header 'Flutter project scaffold'

    $repoRoot      = $PSScriptRoot
    $projectDir    = $repoRoot          # Flutter project lives in the repo root
    $flutterBat    = "$FlutterBinDir\flutter.bat"

    if (-not (Test-Path $flutterBat)) {
        Write-Warn 'Flutter not found — cannot scaffold project. Install Flutter first.'
        return
    }

    # -----------------------------------------------------------------------
    # 1. Create Flutter project if it does not exist
    # -----------------------------------------------------------------------
    if (Test-Path (Join-Path $projectDir 'pubspec.yaml')) {
        Write-Pass "Flutter project already exists at: $projectDir"
    }
    else {
        Write-Step "Creating Flutter project in repo root: $projectDir"
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        Push-Location $projectDir
        & $flutterBat create . `
            --org com.threadcast `
            --platforms android,ios `
            --project-name threadcast 2>&1 | Out-Null
        Pop-Location
        $ErrorActionPreference = $prevEAP

        if (Test-Path (Join-Path $projectDir 'pubspec.yaml')) {
            Write-Pass 'Flutter project created'
        }
        else {
            Write-Fail 'flutter create failed. Check Flutter installation and try again.'
            return
        }
    }

    # -----------------------------------------------------------------------
    # 2. Write pubspec.yaml
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

  # Audio
  just_audio: ^0.10.5
  ffmpeg_kit_flutter: ^6.0.3

  # Database
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
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
  build_runner: ^2.4.0
  isar_generator: ^3.1.0
  flutter_lints: ^4.0.0

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
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    }
    Write-Pass 'Directory structure created'

    # -----------------------------------------------------------------------
    # 4. Write stub Dart files
    # -----------------------------------------------------------------------
    Write-Step 'Writing stub Dart files...'

    $stubs = @{}

    $stubs['lib\core\constants.dart'] = @'
class AppConstants {
  // Set to empty string during development (uses public .json endpoint)
  // Set to your approved Reddit client ID for production OAuth flow
  static const redditClientId = '';

  static const redditRedirectUri = 'threadcast://oauth/callback';

  // TODO: replace YOUR_REDDIT_USERNAME before going to production
  static const redditUserAgent =
      'ios:com.threadcast.app:v1.0.0 (by /u/YOUR_REDDIT_USERNAME)';

  static const redditScopes = 'read identity';
}
'@

    $stubs['lib\core\errors.dart'] = @'
/// Typed error codes used throughout the pipeline.
/// See CLAUDE.md Error Handling Strategy for user-facing messages.
class ThreadcastError {
  static const modelUnavailable   = 'MODEL_UNAVAILABLE';
  static const redditAuthExpired  = 'REDDIT_AUTH_EXPIRED';
  static const redditRateLimited  = 'REDDIT_RATE_LIMITED';
  static const contextTooLong     = 'CONTEXT_TOO_LONG';
  static const generationFailed   = 'GENERATION_FAILED';
  static const ttsFailed          = 'TTS_FAILED';
  static const invalidUrl         = 'INVALID_URL';
  static const backgroundBlocked  = 'BACKGROUND_BLOCKED';
  static const cancelled          = 'CANCELLED';
}
'@

    $stubs['lib\core\extensions.dart'] = @'
import 'dart:io';

extension FileExtension on File {
  Future<void> deleteIfExists() async {
    if (await exists()) await delete();
  }
}
'@

    $stubs['lib\main.dart'] = @'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ThreadcastApp()));
}
'@

    $stubs['lib\app.dart'] = @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/create/create_screen.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/player/player_screen.dart';

class ThreadcastApp extends StatelessWidget {
  const ThreadcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Threadcast',
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/',            builder: (_, __) => const CreateScreen()),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/library',     builder: (_, __) => const LibraryScreen()),
    GoRoute(
      path: '/player/:episodeId',
      builder: (_, state) => PlayerScreen(
        episodeId: state.pathParameters['episodeId']!,
      ),
    ),
  ],
  // TODO: add redirect guard once auth service is wired up
);
'@

    # Feature screen stubs
    $screens = @{
        'lib\features\onboarding\onboarding_screen.dart' = 'OnboardingScreen'
        'lib\features\onboarding\onboarding_provider.dart' = '// TODO: implement Reddit OAuth provider'
        'lib\features\create\create_screen.dart' = 'CreateScreen'
        'lib\features\create\create_provider.dart' = '// TODO: implement generation pipeline provider'
        'lib\features\create\widgets\url_input_field.dart' = 'UrlInputField'
        'lib\features\create\widgets\url_chip_list.dart' = 'UrlChipList'
        'lib\features\create\widgets\generation_progress.dart' = 'GenerationProgress'
        'lib\features\player\player_screen.dart' = 'PlayerScreen'
        'lib\features\player\player_provider.dart' = '// TODO: implement audio player provider'
        'lib\features\player\widgets\playback_controls.dart' = 'PlaybackControls'
        'lib\features\player\widgets\transcript_view.dart' = 'TranscriptView'
        'lib\features\library\library_screen.dart' = 'LibraryScreen'
        'lib\features\library\library_provider.dart' = '// TODO: implement library provider'
        'lib\features\library\widgets\episode_tile.dart' = 'EpisodeTile'
        'lib\shared\widgets\threadcast_scaffold.dart' = 'ThreadcastScaffold'
        'lib\shared\widgets\unsupported_device_screen.dart' = 'UnsupportedDeviceScreen'
        'lib\shared\theme\app_theme.dart' = '// TODO: implement app theme'
        'lib\services\reddit\reddit_auth_service.dart' = '// TODO: implement Reddit OAuth 2.0 + PKCE'
        'lib\services\reddit\reddit_scraper.dart' = '// TODO: implement dual-mode scraper (see CLAUDE.md)'
        'lib\services\reddit\models\reddit_post.dart' = '// TODO: implement RedditPost model'
        'lib\services\reddit\models\reddit_comment.dart' = '// TODO: implement RedditComment model'
        'lib\services\llm\llm_service.dart' = '// TODO: implement LlmService abstract interface'
        'lib\services\llm\os_llm_service.dart' = '// TODO: implement OsLlmService (platform channel)'
        'lib\services\llm\llm_prompt_builder.dart' = '// TODO: implement two-phase prompt builder (see CLAUDE.md)'
        'lib\services\llm\models\transcript.dart' = '// TODO: implement Transcript + TranscriptSegment models'
        'lib\services\llm\models\speaker.dart' = '// TODO: implement Speaker model'
        'lib\services\tts\tts_service.dart' = '// TODO: implement TtsService (Sherpa-ONNX wrapper)'
        'lib\services\tts\voice_assignment.dart' = '// TODO: implement VoiceAssignment (see CLAUDE.md)'
        'lib\services\tts\audio_stitcher.dart' = '// TODO: implement AudioStitcher with FFmpeg'
        'lib\models\episode.dart' = '// TODO: implement Episode Isar schema (see CLAUDE.md)'
    }

    foreach ($file in $screens.Keys) {
        $fullPath = Join-Path $projectDir $file
        if (-not (Test-Path $fullPath)) {
            $name = $screens[$file]
            if ($name -match '^//') {
                Set-Content -Path $fullPath -Value $name -NoNewline
            }
            elseif ($name -match 'Provider$' -or $name -match 'provider$') {
                Set-Content -Path $fullPath -Value "// TODO: implement $name" -NoNewline
            }
            else {
                $stub = @"
import 'package:flutter/material.dart';

class $name extends StatelessWidget {
  const $name({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('$name — TODO')),
    );
  }
}
"@
                Set-Content -Path $fullPath -Value $stub -NoNewline
            }
        }
    }

    foreach ($file in $stubs.Keys) {
        $fullPath = Join-Path $projectDir $file
        if (-not (Test-Path $fullPath)) {
            Set-Content -Path $fullPath -Value $stubs[$file] -NoNewline
        }
    }
    Write-Pass 'Stub Dart files written'

    # -----------------------------------------------------------------------
    # 5. Native stub files
    # -----------------------------------------------------------------------
    Write-Step 'Writing native LLM stub files...'

    # Android Kotlin stubs
    $kotlinDir = Join-Path $projectDir 'android\app\src\main\kotlin\com\threadcast\app\llm'

    $geminiNanoStub = @'
package com.threadcast.app.llm

// TODO: Implement Gemini Nano via ML Kit GenAI Prompt API
// Dependency: implementation("com.google.mlkit:genai-prompt:1.0.0-beta1")
// See CLAUDE.md - Android: Gemini Nano via ML Kit GenAI Prompt API
class GeminiNanoService {
    suspend fun isAvailable(): Boolean = false  // TODO
    suspend fun generateTranscript(prompt: String): String = ""  // TODO
    fun release() {}
}
'@
    Set-Content -Path (Join-Path $kotlinDir 'GeminiNanoService.kt') -Value $geminiNanoStub -NoNewline

    $llmPluginKtStub = @'
package com.threadcast.app.llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// TODO: Implement full LLM platform channel
// See CLAUDE.md - Android: Gemini Nano via ML Kit GenAI Prompt API
class LlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val service = GeminiNanoService()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.threadcast.app/llm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable"         -> result.success(false)  // TODO: call service.isAvailable()
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
'@
    Set-Content -Path (Join-Path $kotlinDir 'LlmPlugin.kt') -Value $llmPluginKtStub -NoNewline

    # iOS Swift stubs
    $iosLlmDir = Join-Path $projectDir 'ios\Runner\llm'

    $foundationModelStub = @'
import Foundation

// TODO: Implement Foundation Models integration
// Requires iOS 26+, and the Foundation Models entitlement must be enabled in Xcode:
//   Signing & Capabilities -> + Capability -> Foundation Models
// See CLAUDE.md - iOS: Foundation Models Framework

@available(iOS 26.0, *)
class FoundationModelService {
    func isAvailable() -> Bool { return false }  // TODO
    func generateTranscript(prompt: String) async throws -> String { return "" }  // TODO
}
'@
    Set-Content -Path (Join-Path $iosLlmDir 'FoundationModelService.swift') -Value $foundationModelStub -NoNewline

    $llmPluginSwiftStub = @'
import Flutter
import UIKit

// TODO: Implement full LLM platform channel
// See CLAUDE.md - iOS: Foundation Models Framework
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
'@
    Set-Content -Path (Join-Path $iosLlmDir 'LlmPlugin.swift') -Value $llmPluginSwiftStub -NoNewline
    Write-Pass 'Native LLM stub files written'

    # -----------------------------------------------------------------------
    # 6. Android manifest additions
    # -----------------------------------------------------------------------
    Write-Step 'Patching AndroidManifest.xml...'
    $manifestPath = Join-Path $projectDir 'android\app\src\main\AndroidManifest.xml'
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw

        $permissionsToAdd = @(
            '<uses-permission android:name="android.permission.INTERNET"/>',
            '<uses-permission android:name="android.permission.WAKE_LOCK"/>'
        )
        foreach ($perm in $permissionsToAdd) {
            $permName = ($perm -replace '.*android:name="([^"]+)".*', '$1')
            if ($manifest -notmatch [regex]::Escape($permName)) {
                $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`n    $perm"
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
        if ($manifest -notmatch 'threadcast://oauth') {
            $manifest = $manifest -replace '(</activity>)', "$deepLink`$1"
        }

        Set-Content -Path $manifestPath -Value $manifest -NoNewline
        Write-Pass 'AndroidManifest.xml patched'
    }
    else {
        Write-Warn 'AndroidManifest.xml not found — patch it manually per CLAUDE.md'
    }

    # -----------------------------------------------------------------------
    # 7. iOS Info.plist additions
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
        Write-Warn 'Info.plist not found — patch it manually per CLAUDE.md'
    }

    # -----------------------------------------------------------------------
    # 8. Copy CLAUDE.md into project root if not already there
    # -----------------------------------------------------------------------
    # CLAUDE.md is already in the repo root which IS the project root — nothing to copy
    $claudePath = Join-Path $projectDir 'CLAUDE.md'
    if (Test-Path $claudePath) {
        Write-Pass 'CLAUDE.md present in project root'
    }
    else {
        Write-Warn 'CLAUDE.md not found — make sure it is in the repo root'
    }

    # -----------------------------------------------------------------------
    # 9. flutter pub get
    # -----------------------------------------------------------------------
    Write-Step 'Running flutter pub get...'
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    Push-Location $projectDir

    # Run flutter pub get and show output live so errors are visible
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
        Write-Warn "flutter pub get failed (exit code: $pubGetExit) — see output above"
        Write-Info 'Try running manually: cd D:\github\Threadcast && flutter pub get'
    }

    # -----------------------------------------------------------------------
    # 10. Initial git commit
    # -----------------------------------------------------------------------
    if (Test-Command 'git') {
        Write-Step 'Creating initial git commit...'
        Push-Location $projectDir

        # Suppress stderr — git prints LF/CRLF warnings and other info to stderr
        # which PowerShell treats as errors. Check exit codes instead.
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        # Configure git to stop warning about line endings in this repo
        & git config core.autocrlf true 2>&1 | Out-Null

        $gitStatus = & git status --porcelain 2>&1
        if ($gitStatus) {
            & git add -A 2>&1 | Out-Null
            & git commit -m 'init: Flutter project scaffold + CLAUDE.md + TTS models' 2>&1 | Out-Null
            $commitExit = $LASTEXITCODE
            if ($commitExit -eq 0) {
                Write-Pass 'Initial git commit created'
            }
            else {
                Write-Warn 'git commit failed — commit manually with: git add -A && git commit -m "init"'
            }
        }
        else {
            Write-Pass 'Nothing to commit — working tree clean'
        }

        $ErrorActionPreference = $prevEAP
        Pop-Location
    }

    Write-Pass "Project scaffold complete: $projectDir"
    Write-Info "Next: cd $projectDir  then  claude"
}

# ---------------------------------------------------------------------------
# Kokoro TTS model setup
# ---------------------------------------------------------------------------

function Install-KokoroModels {
    Write-Header 'Kokoro TTS model setup'

    # Detect the repo root — the script lives in the repo root, so use its directory
    $repoRoot = $PSScriptRoot

    # Expected source: a folder named kokoro-en-v0_19 (or similar) in the repo root,
    # or the files loose in a tts_models folder. We look for model.onnx or kokoro*.onnx.
    $sourceDir = $null

    # Option 1: extracted folder sitting in repo root
    $candidate = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'kokoro' } |
        Select-Object -First 1
    if ($candidate) { $sourceDir = $candidate.FullName }

    # Option 2: files are loose in repo root itself (user extracted in place)
    if (-not $sourceDir) {
        $looseOnnx = Get-ChildItem -Path $repoRoot -Filter '*.onnx' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'kokoro' } |
            Select-Object -First 1
        if ($looseOnnx) { $sourceDir = $repoRoot }
    }

    if (-not $sourceDir) {
        # Not found locally — download automatically
        $archiveName = 'kokoro-en-v0_19.tar.bz2'
        $downloadUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$archiveName"
        $archivePath = Join-Path $repoRoot $archiveName

        Write-Step "Kokoro models not found locally. Downloading (~335 MB)..."
        Write-Info "  Source: $downloadUrl"

        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Pass "Download complete: $archiveName"
        }
        catch {
            Write-Fail "Download failed: $_"
            Write-Info 'Download manually from: https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2'
            Write-Info 'Extract into the repo root folder, then re-run this script.'
            return
        }

        # Install 7-Zip for reliable .tar.bz2 extraction on Windows
        $sevenZipExe = $null
        $sevenZipCandidates = @(
            'C:\Program Files\7-Zip\7z.exe',
            'C:\Program Files (x86)\7-Zip\7z.exe'
        )
        foreach ($c in $sevenZipCandidates) {
            if (Test-Path $c) { $sevenZipExe = $c; break }
        }

        if (-not $sevenZipExe) {
            Write-Step 'Installing 7-Zip for archive extraction...'
            $prevEAP2 = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            & winget install --id 7zip.7zip --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            $ErrorActionPreference = $prevEAP2
            foreach ($c in $sevenZipCandidates) {
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

        # 7-Zip extracts .tar.bz2 in two passes: .bz2 -> .tar, then .tar -> folder
        Write-Step "Extracting $archiveName..."
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        # Pass 1: decompress .bz2 to .tar
        & $sevenZipExe x $archivePath "-o$repoRoot" -y 2>&1 | Out-Null
        $tarPath = $archivePath -replace '\.bz2$', ''

        # Pass 2: extract .tar
        if (Test-Path $tarPath) {
            & $sevenZipExe x $tarPath "-o$repoRoot" -y 2>&1 | Out-Null
            Remove-Item $tarPath -Force -ErrorAction SilentlyContinue
        }

        $tarExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP

        if ($tarExit -ne 0) {
            Write-Fail "Extraction failed (exit: $tarExit)."
            Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
            return
        }

        Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
        Write-Pass 'Extraction complete'

        # Re-detect after extraction
        $candidate = Get-ChildItem -Path $repoRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'kokoro' } |
            Select-Object -First 1
        if ($candidate) {
            $sourceDir = $candidate.FullName
            Write-Pass "Models ready at: $sourceDir"
        }
        else {
            Write-Fail 'Could not locate extracted model directory. Check the repo root manually.'
            return
        }
    }

    Write-Pass "Found Kokoro source at: $sourceDir"

    # Locate the Flutter project — look for pubspec.yaml in repo root or one level down
    $pubspec = $null
    $flutterProjectRoot = $null

    $directPubspec = Join-Path $repoRoot 'pubspec.yaml'
    if (Test-Path $directPubspec) {
        $pubspec = $directPubspec
        $flutterProjectRoot = $repoRoot
    }
    else {
        $nested = Get-ChildItem -Path $repoRoot -Filter 'pubspec.yaml' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($nested) {
            $pubspec = $nested.FullName
            $flutterProjectRoot = $nested.DirectoryName
        }
    }

    if (-not $flutterProjectRoot) {
        Write-Warn 'Flutter project (pubspec.yaml) not found.'
        Write-Info 'Create the project first: flutter create threadcast --org com.threadcast --platforms android,ios'
        Write-Info 'Then re-run this script to copy the model files.'
        return
    }

    Write-Pass "Flutter project found at: $flutterProjectRoot"

    # Create target directory - FIXED for PowerShell 5.1 compatibility
    $targetDir = Join-Path (Join-Path $flutterProjectRoot 'assets') 'tts_models'
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Info "Created: $targetDir"
    }

    # Map of source filename patterns to target filenames
    # Handles both the official naming (model.onnx) and any kokoro*.onnx variant
    Write-Step 'Copying model files...'

    # ONNX model — may be named model.onnx or kokoro-v0_19.onnx etc.
    $onnxSrc = Get-ChildItem -Path $sourceDir -Filter '*.onnx' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($onnxSrc) {
        Copy-Item $onnxSrc.FullName -Destination (Join-Path $targetDir 'kokoro-v0_19.onnx') -Force
        Write-Pass "  kokoro-v0_19.onnx ($([math]::Round($onnxSrc.Length / 1MB, 1)) MB)"
    }
    else {
        Write-Warn '  No .onnx file found in source directory'
    }

    # voices.bin
    $voicesSrc = Join-Path $sourceDir 'voices.bin'
    if (Test-Path $voicesSrc) {
        Copy-Item $voicesSrc -Destination (Join-Path $targetDir 'voices.bin') -Force
        $sz = [math]::Round((Get-Item $voicesSrc).Length / 1MB, 1)
        Write-Pass "  voices.bin ($sz MB)"
    }
    else {
        Write-Warn '  voices.bin not found'
    }

    # tokens.txt
    $tokensSrc = Join-Path $sourceDir 'tokens.txt'
    if (Test-Path $tokensSrc) {
        Copy-Item $tokensSrc -Destination (Join-Path $targetDir 'tokens.txt') -Force
        Write-Pass '  tokens.txt'
    }
    else {
        Write-Warn '  tokens.txt not found'
    }

    # espeak-ng-data directory (recursive copy)
    $espeakSrc = Join-Path $sourceDir 'espeak-ng-data'
    if (Test-Path $espeakSrc) {
        $espeakDest = Join-Path $targetDir 'espeak-ng-data'
        if (Test-Path $espeakDest) {
            Remove-Item $espeakDest -Recurse -Force
        }
        Copy-Item $espeakSrc -Destination $espeakDest -Recurse -Force
        $fileCount = (Get-ChildItem $espeakDest -Recurse -File).Count
        Write-Pass "  espeak-ng-data/ ($fileCount files)"
    }
    else {
        Write-Warn '  espeak-ng-data/ directory not found — G2P phoneme conversion will fail at runtime'
    }

    # Update pubspec.yaml to register the assets if not already present
    Write-Step 'Updating pubspec.yaml...'
    $pubspecContent = Get-Content $pubspec -Raw

    $assetEntries = @(
        '    - assets/tts_models/kokoro-v0_19.onnx',
        '    - assets/tts_models/voices.bin',
        '    - assets/tts_models/tokens.txt',
        '    - assets/tts_models/espeak-ng-data/'
    )

    $needsUpdate = $false
    foreach ($entry in $assetEntries) {
        if ($pubspecContent -notmatch [regex]::Escape($entry.Trim())) {
            $needsUpdate = $true
            break
        }
    }

    if ($needsUpdate) {
        # Check if a flutter: assets: section already exists
        if ($pubspecContent -match 'flutter:') {
            if ($pubspecContent -match '  assets:') {
                # Assets section exists — append entries after the assets: line
                $insertAfter = '  assets:'
                $newEntries = $assetEntries -join "`n"
                $pubspecContent = $pubspecContent -replace [regex]::Escape($insertAfter), "$insertAfter`n$newEntries"
            }
            else {
                # Flutter section exists but no assets: block — add it
                $insertAfter = 'flutter:'
                $newBlock = "flutter:`n  assets:`n" + ($assetEntries -join "`n")
                $pubspecContent = $pubspecContent -replace [regex]::Escape($insertAfter), $newBlock
            }
        }
        else {
            # No flutter section at all — append at end
            $pubspecContent += "`n`nflutter:`n  uses-material-design: true`n  assets:`n" + ($assetEntries -join "`n") + "`n"
        }
        Set-Content -Path $pubspec -Value $pubspecContent -NoNewline
        Write-Pass 'pubspec.yaml updated with asset entries'
    }
    else {
        Write-Pass 'pubspec.yaml already contains asset entries'
    }

    # Summary of what landed
    $totalSize = (Get-ChildItem $targetDir -Recurse -File |
        Measure-Object -Property Length -Sum).Sum
    $totalMB = [math]::Round($totalSize / 1MB, 1)
    Write-Pass "Kokoro TTS models installed ($totalMB MB total in assets/tts_models/)"
    Write-Info 'Note: espeak-ng-data will be extracted to app documents dir on first launch (see CLAUDE.md)'
}

# ---------------------------------------------------------------------------
# Flutter doctor
# ---------------------------------------------------------------------------

function Invoke-FlutterDoctor {
    Write-Header 'Flutter doctor'

    $flutterBat = "$FlutterBinDir\flutter.bat"
    if (-not (Test-Path $flutterBat)) {
        Write-Warn 'Flutter not found at expected path. Run flutter doctor manually after restarting your terminal.'
        return
    }

    Write-Step 'Running flutter doctor...'
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $doctorOutput = & $flutterBat doctor -v 2>&1
    $ErrorActionPreference = $prevEAP
    $doctorOutput | ForEach-Object {
        $line = $_.ToString()
        if ($line -match '^\[v\]' -or $line -match '^\[OK\]' -or $line -match '^  .' ) {
            Write-Host "  $line" -ForegroundColor Green
        }
        elseif ($line -match '^\[X\]' -or $line -match '^\[!\]') {
            Write-Host "  $line" -ForegroundColor Yellow
        }
        elseif ($line.Trim() -ne '') {
            Write-Host "  $line" -ForegroundColor DarkGray
        }
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
        Write-Host '    1. Open Android Studio from the Start menu' -ForegroundColor White
        Write-Host '    2. Complete the setup wizard (accept all defaults)' -ForegroundColor White
        Write-Host '    3. Wait for the initial SDK download to finish' -ForegroundColor White
        Write-Host '    4. Close Android Studio' -ForegroundColor White
        Write-Host '    5. Re-run this script to install API 36 and create the AVD' -ForegroundColor White
        Write-Host ''
    }

    Write-Host '  Next steps:' -ForegroundColor Cyan
    Write-Host '    1. Open a new terminal (PATH changes take effect in new windows)' -ForegroundColor White
    Write-Host '    2. Run: flutter doctor' -ForegroundColor White
    Write-Host '       Fix any remaining [!] or [X] items before writing code' -ForegroundColor DarkGray
    Write-Host '    3. Register your Reddit app at reddit.com/prefs/apps' -ForegroundColor White
    Write-Host '       App type: installed app  |  Redirect URI: threadcast://oauth/callback' -ForegroundColor DarkGray
    Write-Host '    4. Download Kokoro TTS model files:' -ForegroundColor White
    Write-Host '       github.com/k2-fsa/sherpa-onnx/releases' -ForegroundColor DarkGray
    Write-Host '    5. cd D:\github\Threadcast  then  claude' -ForegroundColor White
    Write-Host ''
    Write-Host '  iOS note:' -ForegroundColor Cyan
    Write-Host '    iOS builds require macOS + Xcode and cannot be compiled on Windows.' -ForegroundColor White
    Write-Host '    Options: MacStadium cloud Mac, or Codemagic CI free tier (500 min/month)' -ForegroundColor DarkGray
    Write-Host '    https://codemagic.io' -ForegroundColor DarkGray
    Write-Host ''

    if ($script:FailCount -gt 0) {
        Write-Host '  Some steps failed. Review the [XX] items above before proceeding.' -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

# Force UTF-8 output so bullet points and special chars render correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ''
Write-Host '  =========================================================' -ForegroundColor Cyan
Write-Host '   THREADCAST  -  Windows Developer Environment Setup'       -ForegroundColor Cyan
Write-Host '   Flutter + Android Studio + JDK 17 + Node.js + Claude Code + Kokoro TTS + Project Scaffold' -ForegroundColor DarkGray
Write-Host '  =========================================================' -ForegroundColor Cyan
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