@echo off
setlocal

where escript >nul 2>nul
if %errorlevel% equ 0 (
    set "ESCRIPT_BIN=escript"
    goto :run
)

if exist "C:\Program Files\Erlang OTP\bin\escript.exe" (
    set "ESCRIPT_BIN=C:\Program Files\Erlang OTP\bin\escript.exe"
    goto :run
)

for /d %%D in ("C:\Program Files\erl*") do (
    if exist "%%D\bin\escript.exe" (
        set "ESCRIPT_BIN=%%D\bin\escript.exe"
        goto :run
    )
)

for /d %%D in ("C:\Program Files (x86)\erl*") do (
    if exist "%%D\bin\escript.exe" (
        set "ESCRIPT_BIN=%%D\bin\escript.exe"
        goto :run
    )
)

echo [ERROR] Erlang is not installed or not found in PATH.
echo Install Erlang via PowerShell: winget install Erlang.OTP
echo Or download from: https://www.erlang.org/patches/otp-27.0
exit /b 1

:run
"%ESCRIPT_BIN%" "%~dp0project1.escript" %*
