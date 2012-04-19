; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("version.pbi")
XIncludeFile("tests/helper.pbi")

; ---------------------------------------------------------------------------

If Not OpenConsole()
  End
EndIf

PrintN(#__PROGRAM__ + " " + #__VERSION__ + " (" + #__RELEASE__ + ")")


PrintN(#CRLF$ + #CRLF$ + "Core Interface")
XIncludeFile("tests/core/tests_core.pbi")
XIncludeFile("tests/core/tests_msg_format.pbi")
XIncludeFile("tests/core/tests_plugins.pbi")
XIncludeFile("tests/core/tests_utils.pbi")


PrintN(#CRLF$ + #CRLF$ + #CRLF$ + "filesystem/")
XIncludeFile("tests/filesystem/tests_install.pbi")


PrintN(#CRLF$ + #CRLF$ + #CRLF$ + "network/")
XIncludeFile("tests/network/tests_network.pbi")
XIncludeFile("tests/network/tests_tcpip.pbi")


PrintN(#CRLF$ + #CRLF$ + #CRLF$ + "processes/")
XIncludeFile("tests/processes/tests_processes.pbi")


PrintN(#CRLF$ + #CRLF$ + #CRLF$ + "[X] All tests passed (" + Str(TestCount()) + " test cases)")
Print("Print [Enter] to exit...")
Input()


; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 26
; FirstLine = 6
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant