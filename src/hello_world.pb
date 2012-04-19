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
#HELLO = "Hello"
#DOT   = "..."
#SPACE = " "
#WORLD = "World!"

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

MessageRequester(#HELLO + #SPACE + #DOT, #DOT + #SPACE + #WORLD)

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 55
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant