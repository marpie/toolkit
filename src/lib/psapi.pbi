; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

; ---------------------------------------------------------------------------
;- Consts

; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes

Declare.b Load_Psapi()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_Psapi()
CompilerElse
  Macro Unload_Psapi()
    ; Do nothing!
  EndMacro
CompilerEndIf

Prototype.l protoGetProcessImageFileName(*hProcess.i, *lpImageFileName.s, nSize.l)


; ---------------------------------------------------------------------------
;- Variables

Global psapi.i = 0
Global psapiSizer.i = 0

Global GetProcessImageFileName.protoGetProcessImageFileName = 0


; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_Psapi()
  CompilerIf #SIZE_MATTERS
    If psapiSizer > 0
      psapiSizer = psapiSizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If psapi
      ProcedureReturn #True
    EndIf
  CompilerEndIf
  
  psapi = OpenLibrary(#PB_Any, "psapi.dll")
  If Not psapi
    psapi = 0
    ProcedureReturn #False
  EndIf
  
  GetProcessImageFileName = GetFunction(psapi, "GetProcessImageFileNameA")
  
  If Not (GetProcessImageFileName)
    Unload_Psapi()
    ProcedureReturn #False
  EndIf
  
  psapiSizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_Psapi()
    psapiSizer = psapiSizer - 1
    
    If psapiSizer > 0
      ProcedureReturn #False
    EndIf
    
    If psapi <> 0
      CloseLibrary(psapi)
    EndIf
    
    psapi = 0
    psapiSizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 54
; FirstLine = 18
; Folding = +
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant