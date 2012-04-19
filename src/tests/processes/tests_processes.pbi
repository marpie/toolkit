; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("tests/helper.pbi")
XIncludeFile("processes/processes.pbi")

; ---------------------------------------------------------------------------

PrintN(#CRLF$ + "tests_processes.pbi")
PrintN(         "-------------------")

Define tPID.i = 0
Define tPtr.i = #Null
Define tRes.b = #False
Define tStr.s = ""

; ---------------------------------------------------------------------------
; AllocateForeignMemory
tRes = #False
tStr = "explorer.exe"
If IsCurrentProcess32bit(@tRes) And tRes
  tStr = GetAny32bitUserProcessName()
  If tStr = ""
    tRes = #True
    PrintN("No 32bit Processes are running ... skipping next test!")
  EndIf
EndIf
tPID = GetPidByName(tStr)
If tPID <> 0
  tPtr = AllocateForeignMemory(tPID, 512)
  If tPtr <> #Null
    tRes = #True
  EndIf
  FreeForeignMemory(tPID, tPtr)
  tPtr = #Null
EndIf
Test("AllocateForeignMemory", tRes)

tRes = #False
If tPID <> 0
  tPtr = AllocateForeignMemory(tPID, 512)
  If FreeForeignMemory(tPID, tPtr)
    tRes = #True
  EndIf
  tPtr = #Null
EndIf
Test("FreeForeignMemory", tRes)

tPID = 0


; ---------------------------------------------------------------------------
; ConvertNativePathToWin32
; No tests for this hack! because it is file system and harddisk dependent!


; ---------------------------------------------------------------------------
; CurrentProcessAdjustPrivilege
tRes = #False
If CurrentProcessAdjustPrivilege("SeDebugPrivilege") <> 0
  tRes = #True
EndIf
CurrentProcessAdjustPrivilege("SeDebugPrivilege", #SE_PRIVILEGE_REMOVE)
Test("CurrentProcessAdjustPrivilege", tRes)


; ---------------------------------------------------------------------------
; CurrentProcessAdjustPrivilege
tRes = #False
tStr = GetAny32bitUserProcessName()
If tStr = ""
  PrintN("No 32bit Processes are running ... skipping next test!")
  tRes = #True
EndIf
If Get32PidByName(tStr) <> 0
  tRes = #True
EndIf
Test("Get32PidByName", tRes)


; ---------------------------------------------------------------------------
; GetActiveForegroundWindow
tRes = #False
If GetActiveForegroundWindow() <> 0
  tRes = #True
EndIf
Test("GetActiveForegroundWindow", tRes)


; ---------------------------------------------------------------------------
; GetActiveWindowPid
tRes = #False
If GetActiveWindowPid() <> 0
  tRes = #True
EndIf
Test("GetActiveWindowPid", tRes)


; ---------------------------------------------------------------------------
; GetActiveWindowText
tRes = #False
If GetActiveWindowText() <> ""
  tRes = #True
EndIf
Test("GetActiveWindowText", tRes)


; ---------------------------------------------------------------------------
; GetAny32bitUserProcessName
tRes = #False
If GetAny32bitUserProcessName() <> ""
  tRes = #True
Else
  PrintN("Maybe there are no 32bit processes running?")
EndIf
Test("GetAny32bitUserProcessName", tRes)


; ---------------------------------------------------------------------------
; GetAny64bitUserProcessName
tRes = #False
If GetAny64bitUserProcessName() <> ""
  tRes = #True
Else
  PrintN("Maybe there are no 64bit processes running?")
EndIf
Test("GetAny64bitUserProcessName", tRes)


; ---------------------------------------------------------------------------
; GetImageNameByPid
tRes = #False
If GetImageNameByPid(GetCurrentProcessId()) = GetFilePart(ProgramFilename())
  tRes = #True
EndIf
Test("GetImageNameByPid", tRes)


; ---------------------------------------------------------------------------
; GetImagePathNameByPid
tRes = #False
If GetImagePathNameByPid(GetCurrentProcessId()) = ProgramFilename()
  tRes = #True
EndIf
Test("GetImagePathNameByPid", tRes)


; ---------------------------------------------------------------------------
; GetIntegrityLevelByPid
tPtr = #Null
tRes = #False
If GetIntegrityLevelByPid(GetCurrentProcessId(), @tPtr)
  If tPtr <> #Null
    tRes = #True
  EndIf
EndIf
Test("GetIntegrityLevelByPid", tRes)


; ---------------------------------------------------------------------------
; GetNativeFullExePathByProcess
; ToDo ... no test available!


; ---------------------------------------------------------------------------
; GetPebAddress
tRes = #False
If GetPebAddress(GetCurrentProcessId()) <> 0
  tRes = #True
EndIf
Test("GetPebAddress", tRes)


; ---------------------------------------------------------------------------
; GetPidByName
tRes = #False
If GetPidByName(GetFilePart(ProgramFilename())) = GetCurrentProcessId()
  tRes = #True
EndIf
Test("GetPidByName", tRes)


; ---------------------------------------------------------------------------
; GetProcessEnvironmentList
NewMap environVarsTest.s()
Test("GetProcessEnvironmentList", GetProcessEnvironmentList(GetCurrentProcessId(), environVarsTest()))
Test("GetProcessEnvironmentList has Entries?", (Not MapSize(environVarsTest()) = 0))
FreeMap(environVarsTest.s())


; ---------------------------------------------------------------------------
; GetProcessList
NewList procList.PROCESSLIST()
Test("GetProcessList", GetProcessList(@procList()))
FreeList(procList())


; ---------------------------------------------------------------------------
; InjectDll
; ToDo ... no test available!


; ---------------------------------------------------------------------------
; IsCurrentProcess32bit
tRes = #False
If IsCurrentProcess32bit(@tRes) And (tRes = (#PB_Compiler_Processor = #PB_Processor_x86))
  tRes = #True
EndIf
Test("IsCurrentProcess32bit", tRes)


; ---------------------------------------------------------------------------
; IsPidUserProcess
tRes = #False
If IsPidUserProcess(GetCurrentProcessId())
  tRes = #True
EndIf
Test("IsPidUserProcess Not(SYSTEM)", (Not IsPidUserProcess(4)))
Test("IsPidUserProcess (current Process)", tRes)


; ---------------------------------------------------------------------------
; IsProcess32bit
tRes = #False
If IsProcess32bit(GetCurrentProcessId(), @tRes) And (tRes = (#PB_Compiler_Processor = #PB_Processor_x86))
  tRes = #True
EndIf
Test("IsProcess32bit", tRes)


; ---------------------------------------------------------------------------
; IsSidUser
; ToDo ... no test available!


; ---------------------------------------------------------------------------
; KillProcessByExeName
; ToDo ... no active test!
; Test("KillProcessByExeName", (KillProcessByExeName("notepad.exe")))


; ---------------------------------------------------------------------------
; KillProcessByPid
; ToDo ... no active test!
; Test("KillProcessByPid", (KillProcessByPid(1234)))


; ---------------------------------------------------------------------------
; ProcessIsMemoryReadable
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; ProcessIsMemoryWriteable
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; ReadForeignMemory
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; ReadPeb
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; ReadProcessParameters
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; RenameProcessInMemory
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; WaitForProcess
; ToDo ... no active test!


; ---------------------------------------------------------------------------
; WriteForeignMemory
; ToDo ... no active test!

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 139
; FirstLine = 130
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant