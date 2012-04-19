; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile "lib/ntdll.pbi"
XIncludeFile "lib/advapi32.pbi"
XIncludeFile "lib/kernel32.pbi"
XIncludeFile "lib/user32.pbi"
XIncludeFile "lib/psapi.pbi"
XIncludeFile "lib/ntdll.pbi"

; ToDo: CHECK -------------------> IsPidUserProcess

; File Handle to file name: http://msdn.microsoft.com/en-us/library/aa366789(v=VS.85).aspx

; ---------------------------------------------------------------------------
;- Consts

#TOKEN_ADJUST_PRIVILEGES  = $20
#TOKEN_QUERY              = $08
#SE_PRIVILEGE_ENABLED     = $00000002
#SE_PRIVILEGE_REMOVE      = $00000004


; ---------------------------------------------------------------------------
;- Types

Enumeration ; SID_NAME_USE
  #SidTypeUser = 1
  #SidTypeGroup
  #SidTypeDomain
  #SidTypeAlias
  #SidTypeWellKnownGroup
  #SidTypeDeletedAccount
  #SidTypeInvalid
  #SidTypeUnknown
  #SidTypeComputer
  #SidTypeLabel
EndEnumeration

Structure SID
  Revision.b
  SubAuthorityCount.b
  *IdentifierAuthority.SID_IDENTIFIER_AUTHORITY
  SubAuthority.l[#ANYSIZE_ARRAY]
EndStructure

;Structure SID_AND_ATTRIBUTES
;  *Sid
;  Attributes.l
;EndStructure

Structure TOKEN_USER
  User.SID_AND_ATTRIBUTES
EndStructure

Structure PROCESSLIST
  pid.l
  parentPid.l
  exeName.s
  exeNativeFullPath.s
  exeWin32FullPath.s
EndStructure


; ---------------------------------------------------------------------------
;- Prototypes

Declare.i AllocateForeignMemory(pid.l, size.i, rights.l = #PAGE_READWRITE)
Declare.s ConvertNativePathToWin32(nativePath.s)
Declare.i CurrentProcessAdjustPrivilege(privilegeName.s, attributes.l = #SE_PRIVILEGE_ENABLED)
Declare.b FreeForeignMemory(pid.l, *memPtr)
Declare.l Get32PidByName(exeName.s)
Declare.i GetActiveForegroundWindow()
Declare.i GetActiveWindowPid()
Declare.s GetActiveWindowText()
Declare.s GetAny32bitUserProcessName()
Declare.s GetAny64bitUserProcessName()
Declare.s GetImageNameByPid(pid.l)
Declare.s GetImagePathNameByPid(pid.l)
Declare.b GetIntegrityLevelByPid(pid.l, *pOutIntegretyLevel.l)
Declare.s GetNativeFullExePathByProcess(*cProc.PROCESSENTRY32)
Declare.i GetPebAddress(pid.l)
Declare.l GetPidByName(exeName.s)
Declare.b GetProcessEnvironmentList(pid.l, Map environ.s())
Declare.b GetProcessList(List procList.PROCESSLIST())
Declare.b InjectDll(fullDllPath.s, pid.l)
Declare.b IsCurrentProcess32bit(*resultVar.b)
Declare.b IsPidUserProcess(pid.l)
Declare.b IsProcess32bit(pid.l, *resultVar.b)
Declare.b IsSidUser(*pSid)
Declare.b KillProcessByExeName(exeName.s)
Declare.b KillProcessByPid(pid.l)
Declare.b ProcessIsMemoryReadable(pid.l, *pMemory.i, *maxReadable.i)
Declare.b ProcessIsMemoryWriteable(pid.l, *pMemory.i, *maxWriteable.i)
Declare.i ReadForeignMemory(pid.l, *addrToRead.i, *buffer.i, bytesToRead.i)
Declare.b ReadPeb(pid.l, *pebVar.PEB)
Declare.b ReadProcessParameters(pid.l, *processParameters.RTL_USER_PROCESS_PARAMETERS)
Declare.b RenameProcessInMemory(pid.l, newProcessName.s)
Declare.b WaitForProcess(pid.l)
Declare.b WriteForeignMemory(pid.l, *destAddr.i, *sourceAddr.i, bytesToWrite.i)

; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * AllocateForeignMemory -- Allocates mem that belongs to another process. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i AllocateForeignMemory(pid.l, size.i, rights.l = #PAGE_READWRITE)
  Define res.i = #Null
  Define *hProcess.i = #Null
  
  If Not ((pid > 0) And (size > 0) And Load_Kernel32())
    ProcedureReturn res
  EndIf
  
  ; Open target process.
  ; #PROCESS_CREATE_THREAD | #PROCESS_QUERY_INFORMATION | #PROCESS_VM_OPERATION | #PROCESS_VM_WRITE | #PROCESS_VM_READ
  ; previous: #PROCESS_ALL_ACCESS
  *hProcess = OpenProcess(#PROCESS_VM_OPERATION, #False, pid)
  If Not *hProcess
    Goto AllocateForeignMemoryError
  EndIf
  
  res = VirtualAllocEx(*hProcess, #Null, size, #MEM_COMMIT | #MEM_RESERVE, rights)
  If Not res
    Goto AllocateForeignMemoryError
  EndIf
  
AllocateForeignMemoryCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  
  ProcedureReturn res
  
AllocateForeignMemoryError:
  res = #Null
  Goto AllocateForeignMemoryCleanup
EndProcedure

; ***************************************************************************
; * ConvertNativePathToWin32 -- Tries to convert a nativePath into a        *
; *                             "normal" DosDevice Path.                    *
; *                             E.g. \Device\HarddiskVolume2\tools\wget.exe *
; *                             to   C:\tools\wget.exe                      *
; *                                                                         *
; *                             On error the input string will be returned. *
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s ConvertNativePathToWin32(nativePath.s)
  Define *logicalDrives.i = 0
  Define logicalDrivesSize.l = 0
  Define pos.l = 0
  Define currDrive.s = ""
  Define currNativePathMaxSize.i = StringByteLength(nativePath) + 1
  Define currNativePathSize.i = 0
  Define *currNativePath.i = 0
  Define currNativePath.s
  Define nativePathLen.i = Len(nativePath)
  
  ; 2010-05-16 - noteip
  ; I would suggest no one touches this function ever again!
  ; It works but very, very briefly tested and is nothing but a hack!
  ; Apperently only 64bit Windows binaries are using the Mup device to 
  ; encode UNC path strings, because the x86 tests are correctly encoded
  ; as UNC strings :-(
  
  If Left(nativePath, 11) = "\Device\Mup"
    ; Convert MUP Path to UNC Path
    ; --> NOT TESTED on systems OTHER THAN Windows 7 Ultimate x86-64
    ProcedureReturn "\" + Mid(nativePath, 12)
  EndIf
  
  currNativePath = nativePath
  
  *currNativePath = AllocateMemory(currNativePathMaxSize)
  If Not *currNativePath
    ProcedureReturn currNativePath
  EndIf
  
  ; Get the required size
  logicalDrivesSize = GetLogicalDriveStrings(0, #Null)
  If logicalDrivesSize = 0
    ProcedureReturn currNativePath
  EndIf
  
  *logicalDrives = AllocateMemory(logicalDrivesSize)
  If Not *logicalDrives
    FreeMemory(*currNativePath)
    ProcedureReturn currNativePath
  EndIf
  
  logicalDrivesSize = GetLogicalDriveStrings(logicalDrivesSize, *logicalDrives)
  If logicalDrivesSize = 0
    FreeMemory(*currNativePath)
    FreeMemory(*logicalDrives)
    ProcedureReturn currNativePath
  EndIf
  
  Repeat
    currDrive = PeekS(*logicalDrives + pos)
    pos = pos + StringByteLength(currDrive) + 1
    
    If Right(currDrive, 1) = "\"
      currDrive = Left(currDrive, Len(currDrive) - 1)
    EndIf
    
    currNativePathSize = QueryDosDevice(@currDrive, *currNativePath, currNativePathMaxSize)
    currNativePath = PeekS(*currNativePath, currNativePathSize)
    If currNativePath = ""
      Continue
    EndIf
    
    If nativePathLen > currNativePathSize
      currNativePath = currNativePath + "\"
    EndIf
    If Left(nativePath, Len(currNativePath)) = currNativePath
      currNativePath = currDrive + Mid(nativePath, Len(currNativePath))
      Break
    EndIf
  Until Not (pos < logicalDrivesSize)
  
  If currNativePath = ""
    currNativePath = nativePath
  EndIf
  
  FreeMemory(*currNativePath)
  FreeMemory(*logicalDrives)
  ProcedureReturn currNativePath
EndProcedure

; ***************************************************************************
; * CurrentProcessAdjustPrivilege -- Tries to adjust the supplied Token.    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i CurrentProcessAdjustPrivilege(privilegeName.s, attributes.l = #SE_PRIVILEGE_ENABLED)
  Define res.b = #False
  Define dwRetLen.l = 0
  Define *hToken.i = #Null
  Define debugPriv.TOKEN_PRIVILEGES
  
  If Not (Load_Kernel32() And Load_advapi32() And Load_ntdll())
    ProcedureReturn #False
  EndIf
  
  If OpenProcessToken(GetCurrentProcess(), #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @*hToken)
    If LookupPrivilegeValue("", privilegeName, @debugPriv\Privileges[0]\Luid)
      debugPriv\PrivilegeCount = 1
      debugPriv\Privileges[0]\Attributes = attributes
      res = AdjustTokenPrivileges(*hToken, #False, @debugPriv, 0, #Null, #Null)
    EndIf
    CloseHandle(*hToken)
  EndIf
  
  
  Unload_ntdll()
  Unload_advapi32()
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * FreeForeignMemory -- Frees memory that belongs to another process and   *
; *                      was allocated by AllocateForeignMemory.            *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b FreeForeignMemory(pid.l, *memPtr)
  Define res.i = #True
  Define *hProcess.i = #Null
  
  If Not((pid > 0) And (*memPtr <> #Null) And Load_Kernel32())
    ProcedureReturn res
  EndIf
  
  ; Open target process.
  ; #PROCESS_CREATE_THREAD | #PROCESS_QUERY_INFORMATION | #PROCESS_VM_OPERATION | #PROCESS_VM_WRITE | #PROCESS_VM_READ
  ; previous: #PROCESS_ALL_ACCESS
  *hProcess = OpenProcess(#PROCESS_VM_OPERATION, #False, pid)
  If Not *hProcess
    Goto FreeForeignMemoryError
  EndIf
  
  If VirtualFreeEx(*hProcess, *memPtr, 0, #MEM_RELEASE) = 0
    Goto FreeForeignMemoryError
  EndIf
  
FreeForeignMemoryCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  
  ProcedureReturn res
  
FreeForeignMemoryError:
  res = #False
  Goto FreeForeignMemoryCleanup
EndProcedure

; ***************************************************************************
; * Get32PidByName -- Returns the PID of a 32bit instance of the EXE        *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l Get32PidByName(exeName.s)
  Define res.l = #Null
  Define *hSnapshot.i
  Define cProc.PROCESSENTRY32
  
  If exeName = ""
    ProcedureReturn res
  EndIf
  
  exeName = LCase(exeName)
  
  If Not Load_Kernel32()
    ProcedureReturn res
  EndIf
  
  *hSnapshot = CreateToolhelp32Snapshot(#TH32CS_SNAPPROCESS, 0)
  If *hSnapshot
    cProc\dwSize = SizeOf(PROCESSENTRY32)
    If Process32First(*hSnapshot, @cProc)
      Repeat
        If LCase(PeekS(@cProc\szExeFile)) = exeName
          If IsProcess32bit(cProc\th32ProcessID, @res)
            If res
              res = cProc\th32ProcessID
              Break
            EndIf
          EndIf
          res = #Null
        EndIf
      Until Not Process32Next(*hSnapshot, @cProc)
    EndIf
    CloseHandle(*hSnapshot)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * GetActiveForegroundWindow -- Returns a handle to the foreground window. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i GetActiveForegroundWindow()
  Define res.i = 0
  
  If Not Load_user32()
    ProcedureReturn res
  EndIf
  
  res = GetForegroundWindow()
  
  Unload_user32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * GetActiveWindowPid -- Returns the PID of the currently active window.   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i GetActiveWindowPid()
  Define hwnd.i = 0
  Define res.i = 0
  
  If Not Load_user32()
    ProcedureReturn res
  EndIf
  
  hwnd = GetActiveForegroundWindow()
  If GetWindowThreadProcessId(hwnd, @res) < 1
    Goto GetActiveWindowPidError
  EndIf
  
GetActiveWindowPidCleanup:
  Unload_user32()
  
  ProcedureReturn res
  
GetActiveWindowPidError:
  res = 0
  Goto GetActiveWindowPidCleanup
EndProcedure

; ***************************************************************************
; * GetActiveWindowText -- Returns the title of the currently active window *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetActiveWindowText()
  Define hwnd.i = 0
  Define res.s = ""
  Define tmpSize.i = 0
  Define tmp.s = Space(4096)
  
  If Not Load_user32()
    ProcedureReturn res
  EndIf
  
  hwnd = GetActiveForegroundWindow()
  tmpSize = GetWindowText(hwnd, @tmp, 4096)
  If (tmpSize > 0) And (tmpSize < 4096)
    res = Left(tmp, tmpSize)
  EndIf
  
GetActiveWindowTextCleanup:
  Unload_user32()
  
  ProcedureReturn res
  
GetActiveWindowTextError:
  res = ""
  Goto GetActiveWindowTextCleanup
EndProcedure

; ***************************************************************************
; * GetAny32bitUserProcessName -- Returns the EXE name of a random running  *
; *                               32bit process.                            *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetAny32bitUserProcessName()
  Define res.s = ""
  Define tRes.b = #False
  NewList procList.PROCESSLIST()
  NewList thirtyTwo.PROCESSLIST()
  
  If Not GetProcessList(@procList())
    Goto GetAny32bitUserProcessNameError
  EndIf
  
  ForEach procList()
    If IsProcess32bit(procList()\pid, @tRes)
      If tRes
        If IsPidUserProcess(procList()\pid)
          AddElement(thirtyTwo())
          thirtyTwo() = procList()
        EndIf
      EndIf
    EndIf
    
  Next
  ResetList(thirtyTwo())
  
  If ListSize(thirtyTwo()) <> 0
    SelectElement(thirtyTwo(), Random(ListSize(thirtyTwo())-1))
    res = thirtyTwo()\exeName
  EndIf
  
GetAny32bitUserProcessNameCleanup:
  FreeList(procList())
  ProcedureReturn res

GetAny32bitUserProcessNameError:
  Goto GetAny32bitUserProcessNameCleanup
EndProcedure

; ***************************************************************************
; * GetAny64bitUserProcessName -- Returns the EXE name of a random running  *
; *                               64bit process.                            *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetAny64bitUserProcessName()
  Define res.s = ""
  Define tRes.b = #False
  NewList procList.PROCESSLIST()
  NewList thirtyTwo.PROCESSLIST()
  
  If Not GetProcessList(@procList())
    Goto GetAny64bitUserProcessNameError
  EndIf
  
  ForEach procList()
    If IsProcess32bit(procList()\pid, @tRes)
      If Not tRes
        If IsPidUserProcess(procList()\pid)
          AddElement(thirtyTwo())
          thirtyTwo() = procList()
        EndIf
      EndIf
    EndIf
    
  Next
  ResetList(thirtyTwo())
  
  If ListSize(thirtyTwo()) <> 0
    SelectElement(thirtyTwo(), Random(ListSize(thirtyTwo())-1))
    res = thirtyTwo()\exeName
  EndIf
  
GetAny64bitUserProcessNameCleanup:
  FreeList(procList())
  ProcedureReturn res

GetAny64bitUserProcessNameError:
  Goto GetAny32bitUserProcessNameCleanup
EndProcedure

; ***************************************************************************
; * GetImageNameByPid -- Returns the Image Name of the supplied PID.        *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetImageNameByPid(pid.l)
  ProcedureReturn GetFilePart(GetImagePathNameByPid(pid))
EndProcedure

; ***************************************************************************
; * GetImagePathNameByPid -- Returns the ImagePathName of the supplied PID. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetImagePathNameByPid(pid.l)
  Define res.s
  Define bytesToRead.i = 0
  Define processParams.RTL_USER_PROCESS_PARAMETERS
  Define *buffer.i = #Null
  
  If Not (pid > 0)
    Goto GetImagePathNameByPidError
  EndIf
  
  If Not ReadProcessParameters(pid, @processParams)
    Goto GetImagePathNameByPidError
  EndIf
  
  If Not ProcessIsMemoryReadable(pid, processParams\ImagePathName\Buffer, @bytesToRead)
    Goto GetImagePathNameByPidError
  EndIf
  
  If bytesToRead < processParams\ImagePathName\Length
    Goto GetImagePathNameByPidError
  EndIf
  
  *buffer = AllocateMemory(processParams\ImagePathName\Length)
  FillMemory(*buffer, processParams\ImagePathName\Length)
  If Not *buffer
    Goto GetImagePathNameByPidError
  EndIf
  
  If Not ReadForeignMemory(pid, processParams\ImagePathName\Buffer, *buffer, processParams\ImagePathName\Length)
    Goto GetImagePathNameByPidError
  EndIf
  
  res = PeekS(*buffer, processParams\ImagePathName\Length/2, #PB_Unicode)  
  
GetImagePathNameByPidCleanup:
  If *buffer
    FreeMemory(*buffer)
  EndIf
  ProcedureReturn res
  
GetImagePathNameByPidError:
  res = ""
  Goto GetImagePathNameByPidCleanup
EndProcedure

; ***************************************************************************
; * GetIntegrityLevelByPid -- Returns the Integrety Level of the process.   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b GetIntegrityLevelByPid(pid.l, *pOutIntegretyLevel.l)
  Define res.b = #False
  Define *hProcess.i = #Null
  Define *hToken.i = #Null
  Define dwLengthNeeded.l = 0
  Define dwIntegrityLevel.l = 0
  Define *pTIL.TOKEN_MANDATORY_LABEL = #Null
  
  If Not ((pid <> 0) And *pOutIntegretyLevel)
    ProcedureReturn #False
  EndIf
  
  If Not (Load_advapi32() And Load_Kernel32())
    Goto GetIntegrityLevelByPidError
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_ALL_ACCESS, #False, pid)
  If Not *hProcess
    Goto GetIntegrityLevelByPidError
  EndIf
  
  If Not OpenProcessToken(*hProcess, #TOKEN_QUERY, @*hToken)
    Goto GetIntegrityLevelByPidError
  EndIf
  
  ; Get required size of the integrity level.
  GetTokenInformation(*hToken, #TokenIntegrityLevel, #Null, 0, @dwLengthNeeded)
  If dwLengthNeeded = 0
    Goto GetIntegrityLevelByPidError
  EndIf
  
  ; Allocate required memory
  *pTIL = AllocateMemory(dwLengthNeeded)
  If Not *pTIL
    Goto GetIntegrityLevelByPidError
  EndIf
  
  ; Get token label
  If Not GetTokenInformation(*hToken, #TokenIntegrityLevel, *pTIL, dwLengthNeeded, @dwLengthNeeded)
    Goto GetIntegrityLevelByPidError
  EndIf
  
  dwIntegrityLevel = PeekL(GetSidSubAuthority(*pTIL\Label\Sid, PeekL(GetSidSubAuthorityCount(*pTIL\Label\Sid)) - 1))
  res = #True
  
GetIntegrityLevelByPidCleanup:
  If *pTIL
    FreeMemory(*pTIL)
  EndIf
  
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  If res
    PokeL(*pOutIntegretyLevel, dwIntegrityLevel)
  EndIf
  
  Unload_Kernel32()
  Unload_advapi32()
  
  ProcedureReturn res
  
GetIntegrityLevelByPidError:
  res = #False
  Goto GetIntegrityLevelByPidCleanup
EndProcedure

; ***************************************************************************
; * GetNativeFullExePathByPid -- Returns the full path to the supplied PID. *
; *                              This function is heavily OS version        *
; *                              dependent and returns only native paths.   *
; *                              Use ConvertNativePathToWin32 to get a Dos- *
; *                              Device path (if available!).               *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetNativeFullExePathByProcess(*cProc.PROCESSENTRY32)
  Define osVersion.i = OSVersion()
  Define exeName.s = ""
  Define *hProcess.i = 0
  Define reqRights.l = 0
  Define *buffer.i = AllocateMemory(#MAX_TOTAL_PATH + 1)
  Define retSize.i = 0
  
  If Not *buffer
    ProcedureReturn exeName
  EndIf
  
  ; Windows 2000 = GetModuleFileName()
  ; Windows XP x32 = GetProcessImageFileName()
  ; Windows XP x64 = GetProcessImageFileName()
  ; Windows Vista = QueryFullProcessImageName()
  ; Windows 7 = QueryFullProcessImageName()
  
  If osVersion = #PB_OS_Windows_2000
    retSize = GetModuleFileName(*cProc\th32ModuleID, *buffer, #MAX_TOTAL_PATH)
  ElseIf osVersion > #PB_OS_Windows_2000
    ; Everything above Win2k requires a process handle.
    
    reqRights = #PROCESS_QUERY_INFORMATION
    If osVersion > #PB_OS_Windows_Vista
      ; To keep a lower profile on Vista and higher use fewer rights.
      reqRights = #PROCESS_QUERY_LIMITED_INFORMATION
    EndIf
    
    If Load_Kernel32()
      *hProcess = OpenProcess(reqRights, #False, *cProc\th32ProcessID)
      If *hProcess
        If (osVersion = #PB_OS_Windows_XP) Or (osVersion = #PB_OS_Windows_Server_2003)
          If Load_Psapi()
            retSize = GetProcessImageFileName(*hProcess, *buffer, #MAX_TOTAL_PATH)
            PrintN("Test")
            Unload_Psapi()
          EndIf
        Else
          ; Everything above Vista should call QueryFullProcessImageName()
          retSize = #MAX_TOTAL_PATH
          If Not QueryFullProcessImageName(*hProcess, #PROCESS_NAME_NATIVE, *buffer, @retSize)
            retSize = 0
          EndIf
        EndIf
        
        CloseHandle(*hProcess)
      EndIf
      Unload_Kernel32()
    EndIf
  EndIf
  
  If retSize > 0
    exeName = PeekS(*buffer, retSize)
  EndIf
  
  FreeMemory(*buffer)
  ProcedureReturn exeName
EndProcedure

; ***************************************************************************
; * GetPebAddress -- Retrieves the address of the process environment block.*
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i GetPebAddress(pid.l)
  Define res.i = #Null
  Define *hProcess.i = 0
  Define dwSizeNeeded = 0
  Define pbi.PROCESS_BASIC_INFORMATION
  
  If Not (Load_Kernel32() And Load_ntdll())
    ProcedureReturn #False
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_QUERY_INFORMATION, #False, pid)
  If Not *hProcess
    Goto GetPebAddressError
  EndIf
  
  If #STATUS_SUCCESS = NtQueryInformationProcess(*hProcess, #ProcessBasicInformation, @pbi, SizeOf(pbi), @dwSizeNeeded)
    res = pbi\PebBaseAddress
  EndIf
  
GetPebAddressCleanup:  
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  Unload_Kernel32()
  Unload_ntdll()
  
  ProcedureReturn res
  
GetPebAddressError:
  res = #Null
  Goto GetPebAddressCleanup
EndProcedure

; ***************************************************************************
; * GetPidByName -- Returns the PID of any instance of the EXE or #Null if  *
; *                 any error occures.                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l GetPidByName(exeName.s)
  Define res.l = #Null
  Define *hSnapshot.i
  Define cProc.PROCESSENTRY32
  
  If exeName = ""
    ProcedureReturn res
  EndIf
  
  exeName = LCase(exeName)
  
  If Not Load_Kernel32()
    ProcedureReturn res
  EndIf
  
  *hSnapshot = CreateToolhelp32Snapshot(#TH32CS_SNAPPROCESS, 0)
  If *hSnapshot
    cProc\dwSize = SizeOf(PROCESSENTRY32)
    If Process32First(*hSnapshot, @cProc)
      Repeat
        If LCase(PeekS(@cProc\szExeFile)) = exeName
          res = cProc\th32ProcessID
          Break
        EndIf
      Until Not Process32Next(*hSnapshot, @cProc)
    EndIf
    CloseHandle(*hSnapshot)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * GetProcessEnvironmentList -- Returns the environment variables of the   *
; *                              supplied PID.                              *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b GetProcessEnvironmentList(pid.l, Map environ.s())
  Define res.b = #False
  Define maxReadable.i = 0
  Define processParams.RTL_USER_PROCESS_PARAMETERS
  Define *environMem.i = #Null
  Define counter.i = 0
  Define tmpStr.s
  
  If Not ReadProcessParameters(pid, @processParams)
    Goto GetProcessEnvironmentListError
  EndIf
  
  If Not ProcessIsMemoryReadable(pid, processParams\Environment, @maxReadable)
    Goto GetProcessEnvironmentListError
  EndIf
  
  *environMem = AllocateMemory(maxReadable)
  If Not *environMem
    Goto GetProcessEnvironmentListError
  EndIf
  
  counter = ReadForeignMemory(pid, processParams\Environment, *environMem, maxReadable)
  maxReadable = counter
  
  ; Remove all entries
  ClearMap(environ())
  
  ; Ignore first Entry!
  tmpStr = PeekS(*environMem, -1, #PB_Unicode)
  counter = Len(tmpStr) * 2 + 2
  While counter < maxReadable
    If PeekW(*environMem+counter) = 0 ; Last Entry ends with \00\00\00\00
      Break
    EndIf
    tmpStr = PeekS(*environMem+counter, -1, #PB_Unicode)
    environ(StringField(tmpStr, 1, "=")) = StringField(tmpStr, 2, "=")
    counter = counter + (Len(tmpStr) * 2) + 2
  Wend
  
  res = (Not MapSize(environ()) = 0)
  
GetProcessEnvironmentListCleanup:
  If *environMem
    FreeMemory(*environMem)
  EndIf
  
  ProcedureReturn res
  
GetProcessEnvironmentListError:
  res = #False
  Goto GetProcessEnvironmentListCleanup
EndProcedure

; ***************************************************************************
; * GetProcessList -- Returns a list of all currently running processes.    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b GetProcessList(List procList.PROCESSLIST())
  Define res.b = #False
  Define *hSnapshot.i
  Define cProc.PROCESSENTRY32
  
  If Not Load_Kernel32()
    ProcedureReturn #False
  EndIf
  
  ClearList(procList())
  *hSnapshot = CreateToolhelp32Snapshot(#TH32CS_SNAPPROCESS, 0)
  If *hSnapshot
    cProc\dwSize = SizeOf(PROCESSENTRY32)
    If Process32First(*hSnapshot, @cProc)
      res = #True
      Repeat
        If Not AddElement(procList())
          res = #False
        EndIf
        procList()\pid = cProc\th32ProcessID
        procList()\parentPid = cProc\th32ParentProcessID
        procList()\exeName = PeekS(@cProc\szExeFile)
        procList()\exeNativeFullPath = GetNativeFullExePathByProcess(@cProc)
        procList()\exeWin32FullPath = ConvertNativePathToWin32(procList()\exeNativeFullPath)
      Until Not Process32Next(*hSnapshot, @cProc)
    EndIf
    CloseHandle(*hSnapshot)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * InjectDll -- Injects a loadable module in the specified running process *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b InjectDll(fullDllPath.s, pid.l)
  Define res.b = #False
  Define *hProcess.i = #Null
  Define *remoteBuffer.i = #Null
  Define dllBufferLen.i = 0
  Define dllPath.s
  Define bytesWritten.i = 0
  Define *loadLibA.i = #Null
  
  If Not ((FileSize(fullDllPath) > 0) And (pid > 0) And Load_Kernel32())
    ProcedureReturn res
  EndIf
  
  ; If fullDllPath is UNICODE convert ...
  dllPath = PeekS(@fullDllPath, Len(fullDllPath), #PB_Ascii)
  
  ; Open target process.
  ; #PROCESS_CREATE_THREAD | #PROCESS_QUERY_INFORMATION | #PROCESS_VM_OPERATION | #PROCESS_VM_WRITE | #PROCESS_VM_READ
  *hProcess = OpenProcess(#PROCESS_ALL_ACCESS, #False, pid)
  If Not *hProcess
    Goto InjectDllError
  EndIf
  
  ; Allocate memory for function parameter.
  dllBufferLen = Len(dllPath) + 1
  *remoteBuffer = VirtualAllocEx(*hProcess, #Null, dllBufferLen, #MEM_COMMIT | #MEM_RESERVE, #PAGE_READWRITE)
  If Not *remoteBuffer
    Goto InjectDllError
  EndIf
  
  ; Write dll path to allocated memory.
  If Not WriteProcessMemory(*hProcess, *remoteBuffer, @dllPath, dllBufferLen, @bytesWritten)
    Goto InjectDllError
  EndIf
  If dllBufferLen <> bytesWritten
    Goto InjectDllError
  EndIf
  
  ; Load dll through new Thread.
  res = (Not CreateRemoteThread(*hProcess, #Null, 0, LoadLibrary, *remoteBuffer, 0, #Null) = 0)
  
InjectDllCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  
  ProcedureReturn res
  
InjectDllError:
  res = #False
  Goto InjectDllCleanup
EndProcedure

; ***************************************************************************
; * IsCurrentProcess32bit -- If the result is #True *resultVar holds #True  *
; *                          if the Process is a 32bit process.             *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b  IsCurrentProcess32bit(*resultVar.b)
  Define res.b = #False
  If Not (Load_Kernel32())
    ProcedureReturn #False
  EndIf
  
  res = IsProcess32bit(GetCurrentProcessId(), *resultVar)
  
  Unload_Kernel32()
  
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * IsPidUserProcess -- Returns #True if the pid belongs to a normal user.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b IsPidUserProcess(pid.l)
  ; params:
  ;   - pid                   -> Process identifier
  ;   - tokenInformationClass -> SID_NAME_USE
  ;   - *token                -> holds the TokenInformation after the 
  ;                              function returns (if successful).
  ;   - tokenLen              -> Available size for *token
  Define res.b = #False
  Define process.l = 0
  Define processToken.i = 0
  Define dwSize.l = 0
  
  Dim buf.b(512)
  Define *tokenUser.TOKEN_USER
  
  If Not (Load_Kernel32() And Load_advapi32())
    ProcedureReturn #False
  EndIf
  
  ; Open process.
  process = OpenProcess(#PROCESS_QUERY_INFORMATION, #False, pid)
  
  If process <> 0
    ; Acquire process token.
    If OpenProcessToken(process, #TOKEN_QUERY, @processToken)
      ; Receive token information
      If GetTokenInformation(processToken, #TokenUser, buf(), 512, @dwSize)
        *tokenUser = buf()
        res = IsSidUser(*tokenUser\User\Sid)
      EndIf
      CloseHandle(processToken)
    EndIf
    CloseHandle(process)
  EndIf
  
  Unload_Kernel32()
  Unload_advapi32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * IsProcess32bit -- If the result is #True *resultVar holds #True if the  *
; *                   PID belongs to a 32bit process - regardless of the    *
; *                   host platform.                                        *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b IsProcess32bit(pid.l, *resVar.b)
  Define res.b = #False
  Define resultVar.b = #False
  Define *resultVar.b = *resVar
  Define sysInfo.SYSTEM_INFO
  Define *hProcess.i = #Null
  Define *anyPtr.i = #Null
  Define dwSizeNeeded.i = 0
  
  If Not (Load_Kernel32() And Load_ntdll())
    ProcedureReturn #False
  EndIf
  
  If Not GetNativeSystemInfo
    ; if GetNativeSystemInfo is not available it has to be a 32bit OS!
    res = #True
    resultVar = #True
    Goto IsProcess32bitCleanup
  EndIf
  
  GetNativeSystemInfo(@sysInfo)
  
  Select sysInfo\wProcessorArchitecture
    Case #PROCESSOR_ARCHITECTURE_INTEL
      res = #True
      resultVar = #True
      
      Goto IsProcess32bitCleanup
    Case #PROCESSOR_ARCHITECTURE_AMD64, #PROCESSOR_ARCHITECTURE_IA64
      ; fall through ...
    Default
      Goto IsProcess32bitCleanup
  EndSelect
  
  ; #PROCESSOR_ARCHITECTURE_AMD64 or #PROCESSOR_ARCHITECTURE_IA64
  *hProcess = OpenProcess(#PROCESS_QUERY_INFORMATION, #False, pid)
  If Not *hProcess
    Goto IsProcess32bitError
  EndIf
  
  If #STATUS_SUCCESS = NtQueryInformationProcess(*hProcess, #ProcessWow64Information, @*anyPtr, SizeOf(*anyPtr), @dwSizeNeeded)
    If *anyPtr <> #Null
      resultVar = #True
    EndIf
  EndIf
  
  res = #True
IsProcess32bitCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  Unload_Kernel32()
  Unload_ntdll()
  
  PokeB(*resultVar, resultVar)
  
  ProcedureReturn res
  
IsProcess32bitError:
  res = #False
  resultVar = #False
  Goto IsProcess32bitCleanup
EndProcedure

; ***************************************************************************
; * IsSidUser -- Checks if the given SID belongs to a normal user account.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b IsSidUser(*pSid)
  ; *pSid:
  ;   - Pointer to a SID Structure
  Define user.s = Space(#MAX_PATH)
  Define domain.s = Space(#MAX_PATH)
  Define dwUser.l = #MAX_PATH
  Define dwDomain.l = #MAX_PATH
  Define snu.l = #SidTypeUnknown
  
  LookupAccountSid(#Null, *pSid, @user, @dwUser, @domain, @dwDomain, @snu)
  
  ProcedureReturn (#SidTypeUser = snu)
EndProcedure

; ***************************************************************************
; * KillProcessByExeName -- Kills all instances of the process specified by *
; *                         the supplied exe filename.                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b KillProcessByExeName(exeName.s)
  Define res.b = #False
  Define *hSnapshot.i
  Define cProc.PROCESSENTRY32
  
  If exeName = ""
    ProcedureReturn #False
  EndIf
  
  exeName = LCase(exeName)
  
  If Not Load_Kernel32()
    ProcedureReturn #False
  EndIf
  
  *hSnapshot = CreateToolhelp32Snapshot(#TH32CS_SNAPPROCESS, 0)
  If *hSnapshot
    cProc\dwSize = SizeOf(PROCESSENTRY32)
    If Process32First(*hSnapshot, @cProc)
      Repeat
        If LCase(PeekS(@cProc\szExeFile)) = exeName
          res = KillProcessByPid(cProc\th32ProcessID)
        EndIf
      Until Not Process32Next(*hSnapshot, @cProc)
    EndIf
    CloseHandle(*hSnapshot)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * KillProcessByPid -- Kills the process specified by the supplied PID.    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b KillProcessByPid(pid.l)
  Define res.b = #False
  Define *hProcess.i = 0
  
  If Not Load_Kernel32()
    ProcedureReturn #False
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_TERMINATE, #False, pid)
  If Not *hProcess
    res = TerminateProcess(*hProcess, 0)
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * ProcessIsMemoryReadable -- Returns #True if the memory region is        *
; *                            readable. maxReadable receives the mem size. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ProcessIsMemoryReadable(pid.l, *pMemory.i, *maxReadable.i)
  Define res.b = #False
  Define *hProcess.i = #Null
  Define memInfo.MEMORY_BASIC_INFORMATION
  
  If Not Load_Kernel32()
    ProcedureReturn res
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_QUERY_INFORMATION, #False, pid)
  If Not *hProcess
    Goto ProcessIsMemoryReadableError
  EndIf
  
  If VirtualQueryEx(*hProcess, *pMemory, @memInfo, SizeOf(memInfo)) > 0
    If (#PAGE_NOACCESS = memInfo\Protect) Or (#PAGE_EXECUTE = memInfo\Protect)
      res = #False
      If *maxReadable
        PokeI(*maxReadable, 0)
      EndIf
    Else
      res = #True
      If *maxReadable
        PokeI(*maxReadable, memInfo\RegionSize-(*pMemory-memInfo\BaseAddress))
      EndIf
    EndIf
  EndIf
  
ProcessIsMemoryReadableCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  Unload_Kernel32()
  
  ProcedureReturn res
  
ProcessIsMemoryReadableError:
  res = #False
  Goto ProcessIsMemoryReadableCleanup
EndProcedure

; ***************************************************************************
; * ProcessIsMemoryWriteable -- Returns #True if the region is writeable    *
; *                             maxWriteable receives the mem size.         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ProcessIsMemoryWriteable(pid.l, *pMemory.i, *maxWriteable.i)
  Define res.b = #False
  Define *hProcess.i = #Null
  Define memInfo.MEMORY_BASIC_INFORMATION
  
  If Not Load_Kernel32()
    ProcedureReturn res
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_QUERY_INFORMATION, #False, pid)
  If Not *hProcess
    Goto ProcessIsMemoryWriteableError
  EndIf
  
  If VirtualQueryEx(*hProcess, *pMemory, @memInfo, SizeOf(memInfo)) > 0
    If Not ((#PAGE_READWRITE = memInfo\Protect) Or (#PAGE_WRITECOPY = memInfo\Protect))
      res = #False
      If *maxWriteable
        PokeI(*maxWriteable, 0)
      EndIf
    Else
      res = #True
      If *maxWriteable
        PokeI(*maxWriteable, memInfo\RegionSize-(*pMemory-memInfo\BaseAddress))
      EndIf
    EndIf
  EndIf
  
ProcessIsMemoryWriteableCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  Unload_Kernel32()
  
  ProcedureReturn res
  
ProcessIsMemoryWriteableError:
  res = #False
  Goto ProcessIsMemoryWriteableCleanup
EndProcedure

; ***************************************************************************
; * ReadForeignMemory -- Reads memory that belongs to another process.      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i ReadForeignMemory(pid.l, *addrToRead.i, *buffer.i, bytesToRead.i)
  Define res.i = 0
  Define *hProcess.i = 0
  Define *pebAddr.i = 0
  Define bytesRead.i = 0
  
  If Not ((pid <> 0) And (*addrToRead <> #Null) And (*buffer <> #Null) And (bytesToRead <> 0))
    ProcedureReturn 0
  EndIf
  
  If Not Load_Kernel32()
    ProcedureReturn 0
  EndIf
  
  *hProcess = OpenProcess(#PROCESS_VM_READ, #False, pid)
  If Not *hProcess
    Goto ReadForeignMemoryError
  EndIf
  
  If Not ReadProcessMemory(*hProcess, *addrToRead, *buffer, bytesToRead, @bytesRead)
    Goto ReadForeignMemoryError
  EndIf
  
  res = bytesRead
  
ReadForeignMemoryCleanup:  
  CurrentProcessAdjustPrivilege("SeDebugPrivilege", #SE_PRIVILEGE_REMOVE)
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  Unload_Kernel32()
  
  ProcedureReturn res
  
ReadForeignMemoryError:
  res = 0
  Goto ReadForeignMemoryCleanup
EndProcedure

; ***************************************************************************
; * ReadPeb -- Reads the process environment block of a given PID.          *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ReadPeb(pid.l, *pebVar.PEB)
  Define *pebAddr.i = GetPebAddress(pid)
  If *pebAddr
    ProcedureReturn (Not SizeOf(PEB) <> ReadForeignMemory(pid, *pebAddr, *pebVar, SizeOf(PEB)))
  EndIf
  ProcedureReturn #False
EndProcedure

; ***************************************************************************
; * ReadProcessParameters -- Read the process parameters of the given PID.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ReadProcessParameters(pid.l, *processParameters.RTL_USER_PROCESS_PARAMETERS)
  Define peb.PEB
  Define i.l = 0
  
  If Not ReadPeb(pid, @peb)
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn (Not SizeOf(RTL_USER_PROCESS_PARAMETERS) <> ReadForeignMemory(pid, peb\ProcessParameters, *processParameters, SizeOf(RTL_USER_PROCESS_PARAMETERS)))
EndProcedure

; ***************************************************************************
; * RenameProcessInMemory -- Changes the in memory image-name of the        *
; *                          process by modifying the PEB.                  *
; *                          ** not properly working **                     *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b RenameProcessInMemory(pid.l, newProcessName.s)
  Define res.b = #False
  Define processParams.RTL_USER_PROCESS_PARAMETERS
  Define *unicodeStr.i = #Null
  Define memLen.i = 0
  Define maxLen.i = 0
  
  If Not ReadProcessParameters(pid, @processParams)
    Goto RenameProcessInMemoryError
  EndIf
  
  newProcessName = newProcessName + "??"
  
  ; Convert ASCII to Unicode BEGIN
  memLen = Len(newProcessName) * 2 + 2
  *unicodeStr = AllocateMemory(memLen)
  If Not *unicodeStr
    Goto RenameProcessInMemoryError
  EndIf
  PokeS(*unicodeStr, newProcessName, Len(newProcessName), #PB_Unicode)
  ; Convert ASCII to Unicode END
  
  ; Window Title
  If memLen > processParams\WindowTitle\Length
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not ProcessIsMemoryWriteable(pid, processParams\WindowTitle\Buffer, @maxLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not WriteForeignMemory(pid, processParams\WindowTitle\Buffer, *unicodeStr, memLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  ; ImagePathName
  If memLen > processParams\ImagePathName\Length
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not ProcessIsMemoryWriteable(pid, processParams\ImagePathName\Buffer, @maxLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not WriteForeignMemory(pid, processParams\ImagePathName\Buffer, *unicodeStr, memLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  ; Commandline
  If memLen > processParams\CommandLine\Length
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not ProcessIsMemoryWriteable(pid, processParams\CommandLine\Buffer, @maxLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  If Not WriteForeignMemory(pid, processParams\CommandLine\Buffer+2, *unicodeStr, memLen)
    Goto RenameProcessInMemoryError
  EndIf
  
  res = #True
  
RenameProcessInMemoryCleanup:
  If *unicodeStr
    FreeMemory(*unicodeStr)
  EndIf
  ProcedureReturn res
  
RenameProcessInMemoryError:
  res = #False
  Goto RenameProcessInMemoryCleanup
EndProcedure

; ***************************************************************************
; * WaitForProcess -- Waits till the specified process exits.               *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b WaitForProcess(pid.l)
  Define res.b = #False
  Define *hProcess.i = #Null
  
  If Not (pid > 0)
    ProcedureReturn res
  EndIf
  
  If Not Load_Kernel32()
    ProcedureReturn res
  EndIf
  
  *hProcess = OpenProcess(#SYNCHRONIZE, #False, pid)
  If Not *hProcess
    Goto WaitForProcessError
  EndIf
  
  If WaitForSingleObject(*hProcess, #INFINITE) = 0
    res = #True
  EndIf
  
WaitForProcessCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
  
WaitForProcessError:
  res = #False
  Goto WaitForProcessCleanup
EndProcedure

; ***************************************************************************
; * WriteForeignMemory -- Writes to memory that belongs to another process. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b WriteForeignMemory(pid.l, *destAddr.i, *sourceAddr.i, bytesToWrite.i)
  Define res.b = #False
  Define *hProcess.i = #Null
  Define bytesWritten.i = 0
  
  If Not ((pid > 0) And *destAddr And *sourceAddr And (bytesToWrite > 0) And Load_Kernel32())
    ProcedureReturn res
  EndIf
  
  ; Open target process.
  ; #PROCESS_CREATE_THREAD | #PROCESS_QUERY_INFORMATION | #PROCESS_VM_OPERATION | #PROCESS_VM_WRITE | #PROCESS_VM_READ
  *hProcess = OpenProcess(#PROCESS_ALL_ACCESS, #False, pid)
  If Not *hProcess
    Goto WriteForeignMemoryError
  EndIf
  
  ; Write to foreign memory.
  If Not WriteProcessMemory(*hProcess, *destAddr, *sourceAddr, bytesToWrite, @bytesWritten)
    Goto WriteForeignMemoryError
  EndIf
  If bytesToWrite <> bytesWritten
    Goto WriteForeignMemoryError
  EndIf
  
  res = #True
  
WriteForeignMemoryCleanup:
  If *hProcess
    CloseHandle(*hProcess)
  EndIf
  
  Unload_Kernel32()
  
  ProcedureReturn res
  
WriteForeignMemoryError:
  res = #False
  Goto WriteForeignMemoryCleanup
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
; CursorPosition = 557
; FirstLine = 203
; Folding = AwAAA5
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant