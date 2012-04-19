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
XIncludeFile("network/network.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_network.pbi")
PrintN(         "---------------")

Procedure testNetworkServerHandler(serverId.i)
  ; sEvent.i = NetworkServerEvent()
  CloseNetworkServer(serverId)
EndProcedure


Test("NetworkCreateServer", (Not NetworkCreateServer(@testNetworkServerHandler(), 12345) = 0))

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 26
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant