@echo off
setlocal enableextensions enabledelayedexpansion

echo === Setting up your website tools ===
echo.

REM Check Git.
where git >nul 2>&1
if errorlevel 1 (
  echo Git is not installed on this computer.
  echo Opening the Git download page in your browser...
  start "" "https://git-scm.com/download/win"
  echo.
  echo Please install Git, then re-run this script.
  echo During installation, accept all default options.
  echo.
  pause
  exit /b 1
)

REM Verify Git Credential Manager is wired up (default for Git for Windows 2.x+).
for /f "delims=" %%h in ('git config --global credential.helper 2^>nul') do set GIT_HELPER=%%h
if not defined GIT_HELPER (
  echo.
  echo WARNING: Git Credential Manager does not appear to be configured.
  echo This usually means Git for Windows was installed with non-default options.
  echo You may be prompted for a GitHub password during clone, which will fail.
  echo If clone fails, re-install Git for Windows and accept all defaults.
  echo.
  pause
)

REM Prompt for GitHub username.
set /p GH_USERNAME="GitHub username: "
if "%GH_USERNAME%"=="" (
  echo Username cannot be empty.
  pause
  exit /b 1
)

set "DEFAULT_REPO=%GH_USERNAME%.github.io"
set /p REPO_NAME="Repository name [%DEFAULT_REPO%]: "
if "%REPO_NAME%"=="" set "REPO_NAME=%DEFAULT_REPO%"

set "CLONE_DIR=%USERPROFILE%\Documents\my-website"

if exist "%CLONE_DIR%\.git" (
  echo -^> Repo already cloned at %CLONE_DIR%; skipping clone.
) else (
  echo -^> Cloning %GH_USERNAME%/%REPO_NAME%...
  echo    A browser window will open for you to sign in to GitHub.
  git clone "https://github.com/%GH_USERNAME%/%REPO_NAME%.git" "%CLONE_DIR%"
  if errorlevel 1 (
    echo.
    echo X Clone failed. Double-check the repo name and that it exists.
    pause
    exit /b 1
  )
)

cd /d "%CLONE_DIR%"

REM Configure git name/email if not set.
for /f "delims=" %%n in ('git config user.name 2^>nul') do set HAS_NAME=1
if not defined HAS_NAME (
  set /p GIT_NAME="Your name (for commit history): "
  git config user.name "!GIT_NAME!"
)
for /f "delims=" %%e in ('git config user.email 2^>nul') do set HAS_EMAIL=1
if not defined HAS_EMAIL (
  set /p GIT_EMAIL="Your email: "
  git config user.email "!GIT_EMAIL!"
)

REM Create a Desktop shortcut to upload.bat via PowerShell.
set "SHORTCUT=%USERPROFILE%\Desktop\Upload My Website.lnk"
set "TARGET=%CLONE_DIR%\upload.bat"
powershell -NoProfile -Command ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('%SHORTCUT%'); $s.TargetPath='%TARGET%'; $s.WorkingDirectory='%CLONE_DIR%'; $s.IconLocation='%SystemRoot%\\System32\\imageres.dll,173'; $s.Save()"

echo.
echo ^> All set!
echo.
echo   Your files: %CLONE_DIR%
echo   Upload shortcut: Upload My Website (on your Desktop)
echo.
echo Edit files inside %CLONE_DIR%, then double-click 'Upload My Website' on your Desktop.
echo.
pause
exit /b 0
