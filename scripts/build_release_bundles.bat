@echo off
REM Script to build release bundles for v1.0.0+3 and v1.0.0+4 (Windows)

REM Get script directory and change to project root
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%.."
set PROJECT_ROOT=%CD%
echo Project root: %PROJECT_ROOT%

echo Building release bundles for v1.0.0+3 and v1.0.0+4...

REM Save current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i
echo Current branch: %CURRENT_BRANCH%

REM Stash any uncommitted changes
echo Stashing uncommitted changes...
git stash push -m "WIP: Notes and highlights feature"

REM Build v1.0.0+4 bundle
echo.
echo === Building bundle for v1.0.0+4 ===
set LATEST_RELEASE=6e43a06
echo Checking out commit: %LATEST_RELEASE%
git checkout %LATEST_RELEASE%

REM Verify version
for /f "tokens=2" %%i in ('findstr /R "^version:" pubspec.yaml') do set VERSION=%%i
echo Version: %VERSION%

REM Build bundle
echo Building app bundle...
REM Ensure we're in project root before clean
cd /d "%PROJECT_ROOT%"
call flutter clean
call flutter pub get
call flutter pub run build_runner build --delete-conflicting-outputs
call flutter build appbundle --release

REM Copy bundle with version name
cd /d "%PROJECT_ROOT%"
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "build\app\outputs\bundle\release\app-release-v1.0.0+4.aab"
    echo Bundle created: build\app\outputs\bundle\release\app-release-v1.0.0+4.aab
) else (
    echo Failed to build bundle for v1.0.0+4
)

REM Build v1.0.0+3 bundle
echo.
echo === Building bundle for v1.0.0+3 ===
set V3_COMMIT=2ffd1ee
echo Checking out commit: %V3_COMMIT%
git checkout %V3_COMMIT%

REM Verify version
for /f "tokens=2" %%i in ('findstr /R "^version:" pubspec.yaml') do set VERSION=%%i
echo Version: %VERSION%

REM Build bundle
echo Building app bundle...
REM Ensure we're in project root before clean
cd /d "%PROJECT_ROOT%"
call flutter clean
call flutter pub get
call flutter pub run build_runner build --delete-conflicting-outputs
call flutter build appbundle --release

REM Copy bundle with version name
cd /d "%PROJECT_ROOT%"
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "build\app\outputs\bundle\release\app-release-v1.0.0+3.aab"
    echo Bundle created: build\app\outputs\bundle\release\app-release-v1.0.0+3.aab
) else (
    echo Failed to build bundle for v1.0.0+3
)

REM Return to original branch
echo.
echo Returning to original branch: %CURRENT_BRANCH%
cd /d "%PROJECT_ROOT%"
git checkout %CURRENT_BRANCH%

REM Restore stashed changes
echo Restoring stashed changes...
git stash pop

echo.
echo === Build Complete ===
echo Bundles created:
echo   - build\app\outputs\bundle\release\app-release-v1.0.0+3.aab
echo   - build\app\outputs\bundle\release\app-release-v1.0.0+4.aab

pause

