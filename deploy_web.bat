@echo off
echo 🚀 Preparing web assets for CBT Server...

:: Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter not found in PATH. Please ensure Flutter is installed.
    pause
    exit /b 1
)

:: 1. Build the web version
echo 🔨 Building Flutter web application...
call flutter build web --release --base-href "/"

:: Check if build succeeded
if %errorlevel% neq 0 (
    echo ❌ Web build failed. Please check the errors above.
    pause
    exit /b 1
)

:: 2. Create assets/web directory if it doesn't exist
if not exist "assets\web" (
    echo 📂 Creating assets/web directory...
    mkdir "assets\web"
)

:: 3. Clear existing assets/web folder
echo 🗑️ Cleaning old assets...
if exist "assets\web\*" (
    del /f /s /q "assets\web\*.*" >nul 2>nul
    rmdir /s /q "assets\web" >nul 2>nul
    mkdir "assets\web"
)

:: 4. Copy all web build files to assets/web
echo 📦 Copying web files to assets/web...
xcopy /E /I /Y /Q "build\web\*" "assets\web\" >nul

:: 5. Verify copy was successful
if exist "assets\web\index.html" (
    echo ✅ Assets prepared successfully! Found index.html
    echo 📊 Asset count: 
    dir /s /b "assets\web" | find /c /v "" > temp_count.txt
    set /p count=<temp_count.txt
    del temp_count.txt
    echo    %count% files copied
) else (
    echo ❌ Failed to copy index.html. Build may have failed.
    pause
    exit /b 1
)

:: 6. Display next steps
echo.
echo ========================================
echo 🎯 Next Steps:
echo ========================================
echo 1. Run your Flutter Windows app
echo 2. Click START EXAM in the admin panel
echo 3. Students can access at: http://localhost:8080
echo ========================================
echo.

pause