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
;- Types

; ---------------------------------------------------------------------------
;- Prototypes

Declare.b Load_Iphlpapi()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_Iphlpapi()
CompilerElse
  Macro Unload_Iphlpapi()
    ; Do nothing!
  EndMacro
CompilerEndIf
Prototype.l protoGetExtendedTcpTable(*pTcpTable, *pdwSize, bOrder.b, ulAf.l, TableClass.l, Reserved.l)


; ---------------------------------------------------------------------------
;- Variables

Global iphlpapi.i = 0
Global iphlpapiSizer.i = 0
Global GetExtendedTcpTable.protoGetExtendedTcpTable = 0

; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_Iphlpapi()
  CompilerIf #SIZE_MATTERS
    If iphlpapiSizer > 0
      iphlpapiSizer = iphlpapiSizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If iphlpapi
      ProcedureReturn
    EndIf
  CompilerEndIf
  
  iphlpapi = OpenLibrary(#PB_Any, "iphlpapi.dll")
  If Not iphlpapi
    iphlpapi = 0
    ProcedureReturn #False
  EndIf
  
  GetExtendedTcpTable = GetFunction(iphlpapi, "GetExtendedTcpTable")
  
  If (Not GetExtendedTcpTable)
    Unload_Iphlpapi()
    ProcedureReturn #False
  EndIf
  
  iphlpapiSizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_Iphlpapi()
    iphlpapiSizer = iphlpapiSizer - 1
    
    If iphlpapiSizer > 0
      ProcedureReturn #False
    EndIf
    
    If iphlpapi <> 0
      CloseLibrary(iphlpapi)
    EndIf
    
    iphlpapi = 0
    iphlpapiSizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 48
; FirstLine = 9
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant