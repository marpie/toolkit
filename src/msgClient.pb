; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile("core/msg_format.pbi")
XIncludeFile("network/network.pbi")
XIncludeFile("core/remoteConsole.pbi")

; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Define command.c
Define hostname.s
Define port.i
Define connectBackIp.s
Define fileName.s
Define *buffer.i
Define bufferSize.q = 0
Define res.b = #False

; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure Sample(param.l)
  ; params:
  ;   - param -> first parameter
;EndProcedure

; ---------------------------------------------------------------------------

If Not OpenConsole()
  End
EndIf

command = #REMOTE_CONSOLE_CONNECTBACK
fileName = ProgramParameter()

If fileName <> ""
  command = #REMOTE_CONSOLE_FILE_UPLOAD
EndIf


Print("Connect to: ")
hostname = Input()
Print("Port: ")
port = Val(Input())

If (port < 0) Or (port > 65535)
  PrintN("Port has to be in the range: 0 - 65535.")
  End
EndIf

If hostname = ""
  PrintN("Using Host: localhost")
  hostname = "localhost"
EndIf

If port = 0
  PrintN("Using Port: " + Str(#REMOTE_CONSOLE_PORT))
  port = #REMOTE_CONSOLE_PORT
EndIf

connectBackIp = "123456789012345"

Select command
  Case #REMOTE_CONSOLE_CONNECTBACK
    Print("Trying to send the #REMOTE_CONSOLE_CONNECTBACK msg: ")
    res = NetworkConnectAndSend(hostname, port, #MSG_VERSION_1, #REMOTE_CONSOLE_CONNECTBACK, @connectBackIp, Len(connectBackIp))
    
  Case #REMOTE_CONSOLE_FILE_UPLOAD
    *buffer = FileToStream(fileName, @bufferSize)
    If *buffer
      Print("Trying to send the file (" + fileName + " - Size: " + Str(bufferSize) + "b): ")
      res = NetworkConnectAndSend(hostname, port, #MSG_VERSION_1, #REMOTE_CONSOLE_FILE_UPLOAD, *buffer, bufferSize)
    Else
      PrintN("Error while reading file!")
      End
    EndIf
    
EndSelect

If res
  PrintN("Successful.")
  End 0
Else
  PrintN("Error!")
  End 1
EndIf

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 53
; FirstLine = 27
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant