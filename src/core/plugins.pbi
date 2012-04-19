; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

;
; Plug-In Interface
;

; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes

Prototype.b ProtoPluginInitFunc()
Prototype.b ProtoPluginProcessingFunc(*pData, dataLen.l)


; ---------------------------------------------------------------------------
;- Variables

Global NewList plugins.i()


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * PluginsAdd -- Adds a new element to the Plug-Ins.                       *
; *                 If the initFunc returns an error the plug-in will       *
; *                 be removed again.                                       *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b PluginsAdd(*initFunc.ProtoPluginInitFunc, *processFunc.ProtoPluginProcessingFunc)
  ; params:
  ;   - *initFunc     -> this function is called once at application startup.
  ;   - *processFunc
  
  If *processFunc
    ForEach plugins()
      If plugins() = *processFunc
        ProcedureReturn #True
      EndIf
    Next
    
    If AddElement(plugins())
      plugins() = *processFunc
      
      ; If necessary call the initialization function.
      If *initFunc
        If CallFunctionFast(*initFunc)
          ProcedureReturn #True
        Else
          DeleteElement(plugins(), 1)
        EndIf
      Else
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

; ***************************************************************************
; * PluginsProcessData -- Calls all plug-ins and returns #True if ONE of    *
; *                       them succeeds.                                    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b PluginsProcessData(*pData, dataLen.l)
  ; params:
  ;   - *pData  -> pointer to the raw data.
  ;   - dataLen -> length of the data to be processed.
  Define res.b = #False
  
  If *pData And (dataLen > 0)
    ForEach plugins()
      ; Calls all functions and returns #True if one of them succeeds.
      res = CallFunctionFast(plugins(), *pData, dataLen) Or res
    Next
  EndIf
  
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure Sample(param.l)
  ; params:
  ;   - param -> first parameter
;EndProcedure

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 72
; FirstLine = 58
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant