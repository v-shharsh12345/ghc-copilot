@echo off
REM QMD wrapper for Windows - resolves the Node.js entry point directly
REM since the npm global bin wrapper uses bash (unavailable on Windows).
for /f "tokens=*" %%i in ('npm root -g') do set NPM_ROOT=%%i
node "%NPM_ROOT%\@tobilu\qmd\dist\qmd.js" %*
