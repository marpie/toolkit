@echo off

echo Preparing new injector release
echo -----------------------------
echo.
echo Please wait...

gen_injector_x86.exe %1 injector_x86.exe %2 injector_x86-64.exe %3 %4
if %errorlevel% == 1 Goto error0
REM upx --best %1

echo.
echo --------------------------
echo [injector (%1) is now ready!]
echo [Done.]
echo.
goto end

REM --------------- ERROR HANDLING STARTS HERE ---------------
:error0
echo.
echo General Error occured!
goto endError

:endError
echo.
PAUSE
REM ---------------  ERROR HANDLING ENDS HERE  ---------------

:end