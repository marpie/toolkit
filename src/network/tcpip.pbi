; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile "lib/iphlpapi.pbi"
XIncludeFile "processes/processes.pbi"

; ---------------------------------------------------------------------------
;- Types

#MIB_TCPROW_OWNER_PID_ARRAY_SIZE = 2048

Enumeration ; TCP_TABLE_CLASS
  #TCP_TABLE_BASIC_LISTENER = 0
  #TCP_TABLE_BASIC_CONNECTIONS
  #TCP_TABLE_BASIC_ALL
  #TCP_TABLE_OWNER_PID_LISTENER
  #TCP_TABLE_OWNER_PID_CONNECTIONS
  #TCP_TABLE_OWNER_PID_ALL
  #TCP_TABLE_OWNER_MODULE_LISTENER
  #TCP_TABLE_OWNER_MODULE_CONNECTIONS
  #TCP_TABLE_OWNER_MODULE_ALL
EndEnumeration

; http://msdn.microsoft.com/en-us/library/aa366913(v=VS.85).aspx
Structure MIB_TCPROW_OWNER_PID
  dwState.l
  dwLocalAddr.l
  dwLocalPort.l
  dwRemoteAddr.l
  dwRemotePort.l
  dwOwningPid.l
EndStructure

; http://msdn.microsoft.com/en-us/library/aa366921(VS.85).aspx
Structure MIB_TCPTABLE_OWNER_PID
  dwNumEntries.l
  table.MIB_TCPROW_OWNER_PID[#MIB_TCPROW_OWNER_PID_ARRAY_SIZE]
EndStructure

; ---------------------------------------------------------------------------
;- Prototypes

Declare.l GetSuitablePidForTcpConnection(get32BitProcess.i = -1)
Declare.l Get32BitSuitablePidForTcpConnection()
Declare.l Get64BitSuitablePidForTcpConnection()
Declare.b HasPidTcpConnections(pid.l)

; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * GetSuitablePidForTcpConnection -- Finds a TCP connection owned by a     *
; *                                   usermode program (32 or 64 bit) and   *
; *                                   returns the PID. If get32BitProcess   *
; *                                   is -1 any usermode process (32/64)    *
; *                                   will be returned.                     *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l GetSuitablePidForTcpConnection(get32BitProcess.i = -1)
  Define tcpTable.MIB_TCPTABLE_OWNER_PID
  Define sizer.l
  Define pid.l
  Define tmpRes.b = #False
  
  sizer = 0
  pid = 0
  
  If Not Load_Iphlpapi()
    ProcedureReturn pid
  EndIf
  
  ; Make an initial call to GetExtendedTcpTable to get the
  ; necessary size into the dwSize variable.
  sizer = SizeOf(MIB_TCPTABLE_OWNER_PID)
  ; Get the actual data.
  If GetExtendedTcpTable(@TcpTable, @sizer, #False, #AF_INET, #TCP_TABLE_OWNER_PID_CONNECTIONS, 0) = #NO_ERROR
    For sizer = 0 To tcpTable\dwNumEntries-1
      If IsPidUserProcess(tcpTable\table[sizer]\dwOwningPid)
        Select get32BitProcess
          Case 1
            ; returns the PID if the process is 32bit
            If IsProcess32bit(tcpTable\table[sizer]\dwOwningPid, @tmpRes)
              If Not tmpRes
                Continue
              EndIf
            EndIf
          Case 0
            ; returns the PID if the process is 64bit
            If IsProcess32bit(tcpTable\table[sizer]\dwOwningPid, @tmpRes)
              If tmpRes
                Continue
              EndIf
            EndIf
        EndSelect
        pid = tcpTable\table[sizer]\dwOwningPid
        Break
      EndIf
    Next
  EndIf
    
  Unload_Iphlpapi()
  ProcedureReturn pid
EndProcedure

; ***************************************************************************
; * Get32BitSuitablePidForTcpConnection -- Returns a matching 32bit process *
; *                                        (usermode) with at least one     *
; *                                        open TCP connection.             *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l Get32BitSuitablePidForTcpConnection()
  ProcedureReturn GetSuitablePidForTcpConnection(#True)
EndProcedure

; ***************************************************************************
; * Get64BitSuitablePidForTcpConnection -- Returns a matching 64bit process *
; *                                        (usermode) with at least one     *
; *                                        open TCP connection.             *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l Get64BitSuitablePidForTcpConnection()
  ProcedureReturn GetSuitablePidForTcpConnection(#False)
EndProcedure

; ***************************************************************************
; * HasPidTcpConnections -- Returns #True if the supplied process has open  *
; *                         TCP connections.                                *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b HasPidTcpConnections(pid.l)
  Define res.b = #False
  Define tcpTable.MIB_TCPTABLE_OWNER_PID
  Define sizer.l
  Define pid.l
  
  sizer = 0
  pid = 0
  
  If Not Load_Iphlpapi()
    ProcedureReturn pid
  EndIf
  
  If pid = 0
    Goto HasPIDTcpConnectionsError
  EndIf
  
  ; Make an initial call to GetExtendedTcpTable to get the
  ; necessary size into the dwSize variable.
  sizer = SizeOf(MIB_TCPTABLE_OWNER_PID)
  ; Get the actual data.
  If GetExtendedTcpTable(@TcpTable, @sizer, #False, #AF_INET, #TCP_TABLE_OWNER_PID_CONNECTIONS, 0) = #NO_ERROR
    For sizer = 0 To tcpTable\dwNumEntries-1
      If tcpTable\table[sizer]\dwOwningPid = pid
        res = #True
        Break
      EndIf
    Next
  EndIf
  
HasPIDTcpConnectionsCleanup:
  Unload_Iphlpapi()
  ProcedureReturn res
  
HasPIDTcpConnectionsError:
  res = #False
  Goto HasPIDTcpConnectionsCleanup
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

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 103
; FirstLine = 58
; Folding = x
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant