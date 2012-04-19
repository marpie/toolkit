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
XIncludeFile("network/network.pbi")
XIncludeFile("core/remoteConsole.pbi")

; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes

Declare.b CoreInit()
Declare CoreWaitUntilEnd()
Declare.b CoreStop(wait.b = #False)
Declare CoreThread(semaphore.i)

; ---------------------------------------------------------------------------
;- Variables
Global coreThreadSemaphore.i = 0
Global coreThreadId.i = 0
Global coreStatus.b = #False

; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * CoreInit -- Initialize the Core Components                              *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b CoreInit()
  coreThreadSemaphore = CreateSemaphore(0)
  coreThreadId = CreateThread(@CoreThread(), coreThreadSemaphore)
  ProcedureReturn (0 <> coreThreadId)
EndProcedure

; ***************************************************************************
; * CoreWaitUntilEnd -- Waits till the core thread exits.                   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure CoreWaitUntilEnd()
  WaitThread(coreThreadId)
EndProcedure

; ***************************************************************************
; * CoreStop -- Stops the core thread.                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b CoreStop(wait.b = #False)
  SignalSemaphore(coreThreadSemaphore)
  If wait
    CoreWaitUntilEnd()
  EndIf
  ProcedureReturn coreStatus
EndProcedure

Procedure CoreThread(semaphore.i)
  Define networkThreadId.i = 0
  
  If Not Load_Kernel32()
    Goto CoreThreadCleanup
  EndIf
  
  coreStatus = #True
  
  While TrySemaphore(semaphore) = 0
    If Not IsThread(networkThreadId)
      networkThreadId = NetworkCreateServer(@RemoteConsoleServer(), #REMOTE_CONSOLE_PORT)
    EndIf
    
    Sleep(10)
  Wend
  
CoreThreadCleanup:
  Unload_Kernel32()
  coreStatus = #False
  ProcedureReturn
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
; CursorPosition = 25
; FirstLine = 20
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant