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
XIncludeFile("core/plugins.pbi")

; ---------------------------------------------------------------------------

Define hello_world.s = "Hello World!"

Procedure.b TestPluginInit_1()
  PrintN("Plugin 1: Init!")
  ProcedureReturn #True
EndProcedure

Procedure.b TestPluginProcess_1(*pData, dataLen.l)
  PrintN("Plugin 1: Process (Data: '" + PeekS(*pData, dataLen) + "')")
  ProcedureReturn #True
EndProcedure

Procedure.b TestPluginInit_2()
  PrintN("Plugin 2: Init = #False")
  ProcedureReturn #False
EndProcedure

Procedure.b TestPluginProcess_2(*pData, dataLen.l)
  PrintN("Plugin 2: Process (Data: '" + PeekS(*pData, dataLen) + "') = #False")
  Test("PluginsProcessData (TestPluginProcess_2 shouldn't be called ... ever!)", #False)
  ProcedureReturn #False
EndProcedure

Procedure.b TestPluginProcess_3(*pData, dataLen.l)
  PrintN("Plugin 3: NoInit - Process (Data: '" + PeekS(*pData, dataLen) + "')")
  ProcedureReturn #True
EndProcedure

PrintN(#CRLF$ + "tests_plugins.pbi")
PrintN("-----------------")
Test("PluginsAdd (TestPluginInit_1)", PluginsAdd(@TestPluginInit_1(), @TestPluginProcess_1()))
Test("PluginsAdd (TestPluginInit_2)", (Not PluginsAdd(@TestPluginInit_2(), @TestPluginProcess_2())))
Test("PluginsAdd (TestPluginInit_3)", PluginsAdd(#Null, @TestPluginProcess_3()))

Test("PluginsProcessData", PluginsProcessData(@hello_world, Len(hello_world)))

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 13
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant