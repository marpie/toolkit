; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


;XIncludeFile("")

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

    ; These 4 procedures are Windows specific
    ;

    ; This procedure is called once, when the program loads the library
    ; for the first time. All init stuffs can be done here (but not DirectX init)
    ;
    ProcedureDLL AttachProcess(Instance)
      MessageRequester("InjectedHelloWorldDll", "AttachProcess")
    EndProcedure
  
  
    ; Called when the program release (free) the DLL
    ;
    ProcedureDLL DetachProcess(Instance)
      MessageRequester("InjectedHelloWorldDll", "DetachProcess")
    EndProcedure
  
  
    ; Both are called when a thread in a program call or release (free) the DLL
    ;
    ProcedureDLL AttachThread(Instance)
      MessageRequester("InjectedHelloWorldDll", "AttachThread")
    EndProcedure
  
    ProcedureDLL DetachThread(Instance)
      MessageRequester("InjectedHelloWorldDll", "DetachThread")
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

; IDE Options = PureBasic 4.51 (Windows - x64)
; CursorPosition = 59
; FirstLine = 33
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant