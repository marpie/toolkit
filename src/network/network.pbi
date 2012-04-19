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

; ---------------------------------------------------------------------------
;- Consts

#NETWORK_READ_TIMEOUT          =     5
#NETWORK_MAXIMUM_TRANMISSION_UNIT = 64000


; ---------------------------------------------------------------------------
;- Prototypes

Prototype.i NetworkServerHandler(serverId.i)

Declare.i NetworkCreateServer(*pEventProc.NetworkServerHandler, port.i, mode.i = #PB_Network_TCP)
Declare.b NetworkConnectAndSend(serverName.s, serverPort.i, msgVersion.c, msgCommand.c, *pInData.i = #Null, inDataSize.q = 0, serverMode.i = #PB_Network_TCP)
Declare.i NetworkRecvMsg(connectionId.i, *pOutSize.i, networkTimeoutSec.i = #NETWORK_READ_TIMEOUT)
Declare.b NetworkSendMsg(connectionId.i, msgVersion.c, msgCommand.c, *pInData.i, inDataSize.q)


; ---------------------------------------------------------------------------
;- Types

Structure NETWORK_GENERIC_SERVER_PARAMS
  *pEventProc.NetworkServerHandler
  serverId.i
EndStructure


; ---------------------------------------------------------------------------
;- Variables
Global networkLib_Init.i = 0


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * NetworkInit -- This function must be called before any network library  *
; *                function.                                                *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b NetworkLibInit()
  If networkLib_Init = 0
    networkLib_Init = InitNetwork()
  EndIf
  
  ProcedureReturn networkLib_Init
EndProcedure

Procedure NetworkGenericServerHandler(*params.NETWORK_GENERIC_SERVER_PARAMS)
  If *params
    *params\pEventProc(*params\serverId)
  EndIf
EndProcedure

; ***************************************************************************
; * NetworkCreateServer -- Starts a server on the specified port and        *
; *                        creates a new Thread for the *pEventProc funct.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i NetworkCreateServer(*pEventProc.NetworkServerHandler, port.i, mode.i = #PB_Network_TCP)
  Define *params.NETWORK_GENERIC_SERVER_PARAMS
  
  If (Not *pEventProc) Or (NetworkLibInit() = 0)
    ProcedureReturn #Null
  EndIf
  
  *params = AllocateMemory(SizeOf(NETWORK_GENERIC_SERVER_PARAMS))
  If Not *params
    ProcedureReturn #Null
  EndIf
  
  *params\serverId = CreateNetworkServer(#PB_Any, port, mode)
  If Not *params\serverId
    FreeMemory(*params)
    ProcedureReturn #Null
  EndIf
  
  *params\pEventProc = *pEventProc
  
  ProcedureReturn CreateThread(@NetworkGenericServerHandler(), *params)
EndProcedure

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b NetworkConnectAndSend(serverName.s, serverPort.i, msgVersion.c, msgCommand.c, *pInData.i = #Null, inDataSize.q = 0, serverMode.i = #PB_Network_TCP)
  Define res.b = #False
  Define connectionId.i = 0
  
  If (serverName = "") Or (NetworkLibInit() = 0)
    ProcedureReturn res
  EndIf
  
  connectionId = OpenNetworkConnection(serverName, serverPort, serverMode)
  If Not connectionId
    ProcedureReturn res
  EndIf
  
  res = NetworkSendMsg(connectionId, msgVersion, msgCommand, *pInData, inDataSize)
  
  CloseNetworkConnection(connectionId)
  
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * NetworkRecvMsg -- Tries to read a MSG_FORMAT message from the specified *
; *                   client and returns the data stream. The memory has to *
; *                   be freed by the calling function. The returned stream *
; *                   should be processed by the MsgDecode function. The    *
; *                   pOutSize variable receives (on success) the size of   *
; *                   the buffer.                                           *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i NetworkRecvMsg(connectionId.i, *pOutSize.i, networkTimeoutSec.i = #NETWORK_READ_TIMEOUT)
  Define *buffer.i = #Null
  Define *bufferOld.i = #Null
  Define *header.MSG_HEADER = #Null
  Define bytesRead.i = 0, bytesToReadTotal.i = 0, bytesReadTotal.i = 0, bytesToRead.i = 0
  Define timeout.i = 0
  
  If Not *pOutSize
    ProcedureReturn #Null
  EndIf
  
  *buffer = AllocateMemory(SizeOf(MSG_HEADER))
  If Not *buffer
    ProcedureReturn #Null
  EndIf
  
  If ReceiveNetworkData(connectionId, *buffer, SizeOf(MSG_HEADER)) <> SizeOf(MSG_HEADER)
    Goto NetworkReadMsgExitError
  EndIf
  
  *header = *buffer
  If *header\dataSizePacked > 0
    *bufferOld = *buffer
    *buffer = ReAllocateMemory(*buffer, SizeOf(MSG_HEADER) + *header\dataSizePacked)
    If Not *buffer
      *buffer = *bufferOld
      Goto NetworkReadMsgExitError
    EndIf
    
    bytesToReadTotal = MsgCalcWholePackedSize(*header)
    bytesReadTotal = SizeOf(MSG_HEADER)
    Repeat
      Delay(10)
      If (bytesReadTotal <> bytesToReadTotal)
        
        bytesToRead = bytesToReadTotal - bytesReadTotal
        If bytesToRead > #NETWORK_MAXIMUM_TRANMISSION_UNIT
          bytesToRead = #NETWORK_MAXIMUM_TRANMISSION_UNIT
        EndIf
        
        bytesRead = ReceiveNetworkData(connectionId, *buffer + bytesReadTotal, bytesToRead)
        If bytesRead = -1
          Continue
        ElseIf bytesRead > 0
          bytesReadTotal = bytesReadTotal + bytesRead
          timeout = ElapsedMilliseconds() + (networkTimeoutSec * 1000)
        EndIf
        
        ; Check if timeout got hit
        If ElapsedMilliseconds() > timeout
          Break
        EndIf
      Else
        Break ; All data received!
      EndIf
    ForEver
  EndIf
  
  If bytesReadTotal <> bytesToReadTotal
    Goto NetworkReadMsgExitError
  EndIf
  
  PokeQ(*pOutSize, bytesReadTotal)
  ProcedureReturn *buffer
  
  NetworkReadMsgExitError:
  FreeMemory(*buffer)
  ProcedureReturn #Null
EndProcedure

; ***************************************************************************
; * NetworkSendMsg -- Tries to send a MSG_FORMAT message to the specified   *
; *                   client and returns #True if it was successful.        *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b NetworkSendMsg(connectionId.i, msgVersion.c, msgCommand.c, *pInData.i, inDataSize.q)
  Define *msgPack.MSG_PACK
  Define bytesSend.i = 0, bytesSendTotal.i = 0, bytesToSend.i = 0
  
  *msgPack = MsgEncode(msgVersion, msgCommand, *pInData, inDataSize)
  If Not *msgPack
    ProcedureReturn #False
  EndIf
  
  Repeat
    
    bytesToSend = *msgPack\dataSize - bytesSendTotal
    If bytesToSend < 0 
      Break
    ElseIf bytesToSend > #NETWORK_MAXIMUM_TRANMISSION_UNIT
      bytesToSend = #NETWORK_MAXIMUM_TRANMISSION_UNIT
    EndIf
    
    bytesSend = SendNetworkData(connectionId, *msgPack\pData + bytesSendTotal, bytesToSend)
    If bytesSend = -1
      Goto NetworkSendMsgCleanUp
    EndIf
    bytesSendTotal = bytesSendTotal + bytesSend
  Until (bytesSendTotal = *msgPack\dataSize)
  
  ProcedureReturn (Not bytesSendTotal <> *msgPack\dataSize)
  
  NetworkSendMsgCleanUp:
  FreeMemory(*msgPack\pData)
  FreeMemory(*msgPack)
  
  ProcedureReturn #False
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
; CursorPosition = 235
; FirstLine = 212
; Folding = --
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant