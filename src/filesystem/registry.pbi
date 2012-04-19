; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile("lib/advapi32.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * RegistryWriteKey -- Writes any data to the Windows Registry.            *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b RegistryWriteKey(hKey.i, subKey.s, valueName.s, *value.i, valueLength.l, valueType.l = #REG_SZ)
  Define res.b
  Define phkResult.i = 0
  
  If Not Load_advapi32()
    Goto RegistryWriteKeyError
  EndIf
  
  If Not (RegOpenKeyEx(hKey, @subKey, 0, #KEY_SET_VALUE, @phkResult) = #ERROR_SUCCESS)
    Goto RegistryWriteKeyError
  EndIf
  
  If Not (RegSetValueEx(phkResult, @valueName, 0, valueType, *value, valueLength) = #ERROR_SUCCESS)
    Goto RegistryWriteKeyError
  EndIf
  
  res = #True
  
RegistryWriteKeyCleanup:
  If phkResult
    RegCloseKey(phkResult)
  EndIf
  Unload_advapi32()
  
  ProcedureReturn res
  
RegistryWriteKeyError:
  res = #False
  Goto RegistryWriteKeyCleanup
EndProcedure

; ***************************************************************************
; * RegistryWriteString -- Writes a string to the Windows Registry.         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b RegistryWriteString(hKey.i, subKey.s, valueName.s, value.s)
  ProcedureReturn RegistryWriteKey(hKey, subKey, valueName, @value, StringByteLength(value), #REG_SZ)
EndProcedure

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure.b Sample(param.l)
;   Define res.b
;   
; SampleCleanup:
;   
;   ProcedureReturn res
; SampleError:
;   res = #False
;   Goto SampleCleanup
;EndProcedure

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 62
; FirstLine = 27
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant