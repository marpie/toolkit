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
XIncludeFile("network/tcpip.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_tcpip.pbi")
PrintN(         "---------------")
PrintN("No real test-case for ...")
PrintN("GetSuitablePidForTcpConnection: " + Str(GetSuitablePidForTcpConnection()))

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 17
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant