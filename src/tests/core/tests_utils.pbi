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
XIncludeFile("core/utils.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_utils.pbi")
PrintN(         "---------------")

Define tRes.b

tRes = #False
If GenerateChecksum("test") = "a94a8fe"
  tRes = #True
EndIf
Test("GenerateChecksum", tRes)

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 18
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant