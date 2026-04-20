@echo off
setlocal enableextensions enabledelayedexpansion

REM Weekly upload script for Windows. Double-clickable.

cd /d "%~dp0"

set "LOG_DIR=%USERPROFILE%\Desktop"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd-HHmmss"') do set TS=%%i
set "LOG_FILE=%LOG_DIR%\upload-log-%TS%.txt"

REM Check internet.
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri https://github.com -TimeoutSec 5; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
  call :fail "No internet connection. Check your Wi-Fi and try again."
  exit /b 1
)

echo -^> Checking for updates from GitHub...
git pull --rebase 2> "%LOG_FILE%.tmp"
if errorlevel 1 (
  type "%LOG_FILE%.tmp" >> "%LOG_FILE%"
  git rebase --abort >nul 2>&1
  findstr /I /C:"Authentication failed" /C:"could not read Username" "%LOG_FILE%.tmp" >nul
  if not errorlevel 1 (
    del "%LOG_FILE%.tmp" >nul 2>&1
    call :fail "GitHub sign-in expired. Please re-run the setup script to sign in again."
    exit /b 1
  )
  findstr /I /C:"conflict" "%LOG_FILE%.tmp" >nul
  if not errorlevel 1 (
    del "%LOG_FILE%.tmp" >nul 2>&1
    call :fail "Something got out of sync. We couldn't merge the changes automatically."
    exit /b 1
  )
  del "%LOG_FILE%.tmp" >nul 2>&1
  call :fail "Something unexpected happened while checking for updates."
  exit /b 1
)
del "%LOG_FILE%.tmp" >nul 2>&1

echo -^> Preparing your changes...
git add -A

git diff --cached --quiet
if not errorlevel 1 (
  echo.
  echo ^> No changes to upload -- everything's already up to date.
  echo.
  pause
  exit /b 0
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm\""') do set COMMIT_TS=%%i
echo -^> Saving your changes...
git commit -m "Update %COMMIT_TS%" > "%LOG_FILE%.tmp" 2>&1
if errorlevel 1 (
  type "%LOG_FILE%.tmp" >> "%LOG_FILE%"
  del "%LOG_FILE%.tmp" >nul 2>&1
  call :fail "Something went wrong saving your changes."
  exit /b 1
)
del "%LOG_FILE%.tmp" >nul 2>&1

echo -^> Uploading to GitHub...
git push 2> "%LOG_FILE%.tmp"
if errorlevel 1 (
  type "%LOG_FILE%.tmp" >> "%LOG_FILE%"
  findstr /I /C:"Authentication failed" /C:"could not read Username" "%LOG_FILE%.tmp" >nul
  if not errorlevel 1 (
    del "%LOG_FILE%.tmp" >nul 2>&1
    call :fail "GitHub sign-in expired. Please re-run the setup script to sign in again."
    exit /b 1
  )
  findstr /I /C:"Could not resolve host" /C:"Failed to connect" /C:"Connection timed out" /C:"network" "%LOG_FILE%.tmp" >nul
  if not errorlevel 1 (
    del "%LOG_FILE%.tmp" >nul 2>&1
    call :fail "Lost internet connection while uploading. Your changes are saved locally -- check your Wi-Fi and try again."
    exit /b 1
  )
  del "%LOG_FILE%.tmp" >nul 2>&1
  call :fail "Something went wrong uploading."
  exit /b 1
)
del "%LOG_FILE%.tmp" >nul 2>&1

for /f "delims=" %%u in ('git config --get remote.origin.url') do set REPO_URL=%%u
for /f "delims=" %%n in ('powershell -NoProfile -Command "(('%REPO_URL%') -replace '.*[:/]([^/]+)/[^/]+\.git$','$1')"') do set USERNAME=%%n

echo.
echo ^> Uploaded! Your site will update in about 1 minute.
if defined USERNAME if not "%USERNAME%"=="%REPO_URL%" echo   Visit: https://%USERNAME%.github.io
echo.
pause
exit /b 0

:fail
(
  echo.
  echo --- git status ---
  git status
  echo --- git log -5 ---
  git log --oneline -5
) >> "%LOG_FILE%" 2>&1
echo.
echo X %~1
echo.
echo A log has been saved to: %LOG_FILE%
echo Please send it to the person who set this up.
echo.
pause
goto :eof
