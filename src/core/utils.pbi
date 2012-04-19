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

; ---------------------------------------------------------------------------
;- Variables

; ---------------------------------------------------------------------------
;- Procedures

Macro MAKELONG(low, high) 
  low | (high<<16) 
EndMacro

Macro LOWWORD(Value) 
  Value & $FFFF 
EndMacro

Macro HIGHWORD(Value) 
  (Value >> 16) & $FFFF 
EndMacro

; ***************************************************************************
; * GenerateChecksum -- Returns the first 7 chars of the param's SHA1sum    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GenerateChecksum(str.s, len.i = 7)
  If str = ""
    ProcedureReturn ""
  EndIf
  ProcedureReturn Left(SHA1Fingerprint(@str, StringByteLength(str)), len)
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
; CursorPosition = 46
; FirstLine = 7
; Folding = w
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant