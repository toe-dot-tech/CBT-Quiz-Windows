@echo off
echo 🚀 BUILDING WINDOWS EXE
echo =======================
echo.

:: Clean Windows build (show output so you can see what's happening)
echo 🧹 Cleaning Windows build...
call flutter clean
if %errorlevel% neq 0 (
    echo ❌ Clean failed! Continuing anyway...
) else (
    echo ✅ Clean completed
)

:: Build EXE (show full output)
echo.
echo 🔨 Building Windows EXE (this may take 3-5 minutes)...
echo.
call flutter build windows --release

:: Check if build succeeded
if %errorlevel% neq 0 (
    echo.
    echo ❌ Build failed! See errors above.
    echo.
    pause
    exit /b 1
)

:: Get desktop path
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop 2^>nul') do set DESKTOP=%%b
if "%DESKTOP%"=="" set DESKTOP=%USERPROFILE%\Desktop

:: Create distribution folder
echo.
echo 📁 Creating distribution folder on Desktop...
set DIST_DIR=%DESKTOP%\CBT_Exam_System
rmdir /s /q "%DIST_DIR%" 2>nul
mkdir "%DIST_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to create folder!
    pause
    exit /b 1
)

:: Check if build output exists
if not exist "build\windows\x64\runner\Release\cbtapp.exe" (
    echo ❌ cbtapp.exe not found! Build may have failed.
    pause
    exit /b 1
)

:: Copy files with progress indicators
echo.
echo 📋 Copying files to Desktop...

echo    - Copying cbtapp.exe...
copy "build\windows\x64\runner\Release\cbtapp.exe" "%DIST_DIR%\" >nul

echo    - Copying DLLs...
copy "build\windows\x64\runner\Release\*.dll" "%DIST_DIR%\" >nul 2>nul

echo    - Copying data folder...
if exist "build\windows\x64\runner\Release\data" (
    xcopy /E /I /Y "build\windows\x64\runner\Release\data" "%DIST_DIR%\data\" >nul
) else (
    echo      ⚠️ data folder not found
)

echo    - Copying web assets...
if exist "assets\web" (
    mkdir "%DIST_DIR%\assets" 2>nul
    xcopy /E /I /Y "assets\web" "%DIST_DIR%\assets\web\" >nul
) else (
    echo      ⚠️ web assets not found
)

echo    - Copying CSV files...
copy "*.csv" "%DIST_DIR%\" >nul 2>nul

:: Create a simple README
echo    - Creating README...
(
echo CBT EXAM SYSTEM
echo ===============
echo.
echo To run:
echo 1. Double-click cbtapp.exe
echo 2. Click "START EXAM"
echo 3. Students connect to http://localhost:8080
) > "%DIST_DIR%\README.txt"

:: Count files in distribution
set COUNT=0
for /f %%i in ('dir /b "%DIST_DIR%" 2^>nul ^| find /c /v ""') do set COUNT=%%i

:: Done
echo.
echo ================================================
echo ✅ EXE BUILT SUCCESSFULLY!
echo ================================================
echo.
echo 📁 Location: %DIST_DIR%
echo 📊 Files copied: %COUNT%
echo.
echo 🚀 To run:
echo    1. Open: %DIST_DIR%
echo    2. Double-click cbtapp.exe
echo.
echo 🔍 If build is slow or hanging:
echo    - Open a new Command Prompt
echo    - Navigate to your project
echo    - Run: flutter build windows --release -v
echo    - This shows detailed progress
echo.
pause

:: Open the folder
explorer "%DIST_DIR%"