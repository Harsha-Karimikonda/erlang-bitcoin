@echo off
where escript >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%USERPROFILE%\erlang\otp-OTP-29.0.6\bin\escript.exe" (
        set "PATH=%USERPROFILE%\erlang\otp-OTP-29.0.6\bin;%PATH%"
    )
)
escript "%~dp0project1.escript" %*
