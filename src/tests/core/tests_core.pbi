; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("tests/helper.pbi")
XIncludeFile("core/core.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_core.pbi")
PrintN(         "--------------")

Test("CoreInit", CoreInit())
Test("CoreStop", (CoreStop(#True) <> #True))

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 19
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant