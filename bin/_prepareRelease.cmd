@echo off

echo Preparing toolkit v2 release
echo ----------------------------
echo.
echo Please wait...

echo.
echo Packing Utilities
echo -----------------
upx --best gen_dropper_x86.exe gen_injector_x86.exe hello_world_x86.dll hello_world_x86.exe resourceModifier.exe

echo.
echo --------------------------
echo [toolkit v2 is now ready!]
echo [Done.]
echo.
goto end

REM --------------- ERROR HANDLING STARTS HERE ---------------
:error0
echo.
echo General Error occured!
goto endError

:errorLoader0
echo.
echo Couldn't add loader_x86.dll
goto endError

:errorLoader1
echo.
echo Couldn't add loader_x86-64.dll
goto endError

:endError
echo.
PAUSE
exit /b 1
REM ---------------  ERROR HANDLING ENDS HERE  ---------------

:end
PAUSE
exit
