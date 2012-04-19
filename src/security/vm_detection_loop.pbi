; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

CompilerIf Defined(VMDETECTION_STANDALONE, #PB_Constant)
  PrintN("Check - " + Str(vmfunctionCount) + ": VM-Detected!")
  Input()
CompilerElse
  
  Repeat
    Delay(100)
  ForEver
  
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 13
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant