@echo off

echo Preparing new dropper release
echo -----------------------------
echo.
echo Please wait...

gen_dropper_x86.exe %1 dropper_x86.exe dropper_x86.dll dropper_x86-64.exe dropper_x86-64.dll %2 %3
if %errorlevel% == 1 Goto error0

echo.
echo --------------------------
echo [dropper (%1) is now ready!]
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