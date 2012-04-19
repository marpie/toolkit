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

Declare Test(functionName.s, assertion.b)


; ---------------------------------------------------------------------------
;- Variables
Global testCounter.i = 0

; ---------------------------------------------------------------------------
;- Procedures

Procedure Test(functionName.s, assertion.b)
  Print(functionName + ": ")
  If assertion <> #False
    PrintN("OK.")
    testCounter = testCounter + 1
  Else
    PrintN("Error!")
    PrintN("Press Enter to Exit.")
    Input()
    End
  EndIf
EndProcedure

Procedure.i TestCount()
  ProcedureReturn testCounter
EndProcedure

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 39
; FirstLine = 5
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant