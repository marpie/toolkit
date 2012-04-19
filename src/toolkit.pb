; ***************************************************************************
; *                                                                         *
; * toolkit -- Release: v1 (Galapagos)                                      *
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("version.pbi")
XIncludeFile("core/core.pbi")

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
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure Sample(param.l)
  ; params:
  ;   - param -> first parameter
;EndProcedure

; ---------------------------------------------------------------------------

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  ProcedureDLL AttachProcess(Instance)
    
  EndProcedure
  
  ProcedureDLL DetachProcess(Instance)
    
  EndProcedure
  
  ProcedureDLL AttachThread(Instance)
    
  EndProcedure
  
  ProcedureDLL DetachThread(Instance)
    
  EndProcedure
CompilerEndIf

;    ProcedureDLL EasyRequester(Message$)
;      MessageRequester("EasyRequester !", Message$)
;    EndProcedure

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 63
; FirstLine = 27
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant