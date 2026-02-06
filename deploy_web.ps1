Write-Host "Building diary app for web deployment..." -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Building web app with base-href '/diary_app/'..." -ForegroundColor Yellow
flutter build web --base-href "/diary_app/" --web-renderer canvaskit
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build web app" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 3: Creating docs folder..." -ForegroundColor Yellow
if (!(Test-Path "docs")) {
    New-Item -ItemType Directory -Path "docs"
}

Write-Host ""
Write-Host "Step 4: Copying build files to docs folder..." -ForegroundColor Yellow
Copy-Item -Path "build\web\*" -Destination "docs\" -Recurse -Force
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to copy files to docs folder" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 5: Cleaning up build folder..." -ForegroundColor Yellow
Remove-Item -Path "build\web" -Recurse -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The app has been built and copied to the 'docs' folder." -ForegroundColor White
Write-Host "You can now deploy the 'docs' folder to your web server." -ForegroundColor White
Write-Host ""
Write-Host "To test locally, you can run:" -ForegroundColor Yellow
Write-Host "python -m http.server 8000 --directory docs" -ForegroundColor Gray
Write-Host ""
Write-Host "Then visit: http://localhost:8000/diary_app/" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
