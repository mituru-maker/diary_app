@echo off
echo Building diary app for web deployment...
echo.

echo Step 1: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Step 2: Building web app with base-href "/diary_app/"...
flutter build web --base-href "/diary_app/" --web-renderer canvaskit
if %errorlevel% neq 0 (
    echo Failed to build web app
    pause
    exit /b 1
)

echo.
echo Step 3: Creating docs folder...
if not exist "docs" mkdir docs

echo.
echo Step 4: Copying build files to docs folder...
xcopy "build\web\*" "docs\" /E /I /Y
if %errorlevel% neq 0 (
    echo Failed to copy files to docs folder
    pause
    exit /b 1
)

echo.
echo Step 5: Cleaning up build folder...
rmdir /S /Q "build\web"

echo.
echo ========================================
echo Deployment completed successfully!
echo ========================================
echo.
echo The app has been built and copied to the 'docs' folder.
echo You can now deploy the 'docs' folder to your web server.
echo.
echo To test locally, you can run:
echo python -m http.server 8000 --directory docs
echo.
echo Then visit: http://localhost:8000/diary_app/
echo.
pause
