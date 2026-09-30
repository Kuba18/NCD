@echo off
setlocal

set "NCD_LIB=%~dp0ncd-lib.ps1"
if not exist "%NCD_LIB%" (
    echo ncd: nie znaleziono pliku "%NCD_LIB%" 1>&2
    exit /b 1
)

set "NCD_OUT=%TEMP%\ncd_%RANDOM%%RANDOM%.txt"

where pwsh >nul 2>nul
if %errorlevel%==0 (set "NCD_PS=pwsh") else (set "NCD_PS=powershell")

%NCD_PS% -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; . $env:NCD_LIB; if (-not (Get-Command ncd -CommandType Function -ErrorAction SilentlyContinue)) { exit 1 }; ncd"

set "NCD_DIR="
if exist "%NCD_OUT%" (
    set /p NCD_DIR=<"%NCD_OUT%"
    del "%NCD_OUT%" >nul 2>nul
)

endlocal & if not "%NCD_DIR%"=="" cd /d "%NCD_DIR%"
