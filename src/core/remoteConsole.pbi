; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

; --- DEBUG ---
;
; --- DEBUG ---

XIncludeFile("network/network.pbi")
XIncludeFile("filesystem/filesystem.pbi")

; ---------------------------------------------------------------------------
;- Consts

#REMOTE_CONSOLE_PORT = $EA5E

Enumeration 
  #REMOTE_CONSOLE_CONNECTBACK
  #REMOTE_CONSOLE_FILE_UPLOAD
EndEnumeration


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

Procedure RemoteConsoleServer(serverId.i)
  Define active.b = #True
  Define sEvent.i = 0
  Define clientId.i = 0
  Define *buffer.i = #Null
  Define bufferSize.i = 0
  Define *msg.MSG_PACK = #Null
  
  While active
    Delay(10)
    
    sEvent = NetworkServerEvent()
    If sEvent And (EventServer() = serverId)
      Debug sEvent
      
      clientId = EventClient()
      
      Select sEvent
        Case #PB_NetworkEvent_Connect
          Debug "New connection."
        Case #PB_NetworkEvent_Data
          Debug "New data."
          *buffer = NetworkRecvMsg(clientId, @bufferSize)
          If *buffer
            *msg = MsgDecode(*buffer, bufferSize)
            FreeMemory(*buffer)
            If *msg
;               If *msg\header\command = #REMOTE_CONSOLE_FILE_UPLOAD
;                 If StreamToFile("I:\toolkit_v2\upload.bin", *msg\pData, *msg\dataSize)
;                   Debug "Written to I:\toolkit_v2\upload.bin."
;                 Else
;                   Debug "Error while writing file: I:\toolkit_v2\upload.bin"
;                 EndIf
;               EndIf
              
              *msg = MsgFreePack(*msg)
            Else
              Debug "Error while decoding msg!"
            EndIf
          Else
            Debug "Error while reading msg!"
          EndIf
          
        Case #PB_NetworkEvent_File
          Debug "New network file."
        Case #PB_NetworkEvent_Disconnect
          Debug "Connection closed."
      EndSelect
    EndIf
  Wend
  ;CloseNetworkServer(serverId)
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

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 80
; FirstLine = 59
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant