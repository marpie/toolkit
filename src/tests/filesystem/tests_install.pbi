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
XIncludeFile("filesystem/install.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_filesystem.pbi")
PrintN("-----------------------------")

PrintN(GetAnySystemFilename())

;Test("PluginsProcessData", PluginsProcessData(@hello_world, Len(hello_world)))

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 20
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant