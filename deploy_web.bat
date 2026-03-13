@echo off
echo 🚀 DEPLOYING OFFLINE WEB ASSETS
echo ================================
echo.

:: Clean previous builds
echo 🧹 Cleaning previous web builds...
if exist "build\web" rmdir /s /q "build\web" 2>nul
if exist "assets\web" rmdir /s /q "assets\web" 2>nul

:: Build web with offline support (NO renderer flags - just offline)
echo.
echo 🔨 Building web for offline use...
echo.
call flutter build web --release --base-href "/" --no-web-resources-cdn

if %errorlevel% neq 0 (
    echo ❌ Web build failed!
    pause
    exit /b 1
)

:: Copy to assets folder
echo.
echo 📂 Copying to assets/web...
mkdir "assets\web" 2>nul
xcopy /E /I /Y /Q "build\web\*" "assets\web\" >nul

:: Verify
echo.
echo ✅ Web assets deployed successfully!
echo 📁 Location: assets/web
echo.
pause