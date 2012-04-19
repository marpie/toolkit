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

; ***************************************************************************
; * packed payload order *
; ************************
; - 32bit DLL
; - 64bit EXE
; - 64bit DLL

; ---------------------------------------------------------------------------
;- Consts
#RES_STR_URL             = "LOGO_FULLNAME"
#RES_STR_URL_EXTENSION   = "LOGO_CHECKSUM"
#RES_STR_LOCAL_FILE_NAME = "LOGO_NAME"
#RES_PAYLOAD             = "LOGO"

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

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 18
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant