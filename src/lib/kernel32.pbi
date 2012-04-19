; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

; ---------------------------------------------------------------------------
;- Consts
#MAX_TOTAL_PATH = $7FFF ; 32767
#MAX_PATH = 260
#MAX_MODULE_NAME32 = 255

#FILE_SHARE_DELETE = $00000004

; #TH32CS_SNAPHEAPLIST  = $00000001
; #TH32CS_SNAPPROCESS   = $00000002
; #TH32CS_SNAPTHREAD    = $00000004
; #TH32CS_SNAPMODULE    = $00000008
; #TH32CS_SNAPMODULE32  = $00000010
; #TH32CS_SNAPALL       = (#TH32CS_SNAPHEAPLIST | #TH32CS_SNAPPROCESS | #TH32CS_SNAPTHREAD | #TH32CS_SNAPMODULE)
; #TH32CS_INHERIT       = $80000000

#PROCESS_TERMINATE                  = $0001
#PROCESS_CREATE_THREAD              = $0002
#PROCESS_SET_SESSIONID              = $0004
#PROCESS_VM_OPERATION               = $0008
#PROCESS_VM_READ                    = $0010
#PROCESS_VM_WRITE                   = $0020
#PROCESS_DUP_HANDLE                 = $0040
#PROCESS_CREATE_PROCESS             = $0080
#PROCESS_SET_QUOTA                  = $0100
#PROCESS_SET_INFORMATION            = $0200
#PROCESS_QUERY_INFORMATION          = $0400
#PROCESS_SUSPEND_RESUME             = $0800
#PROCESS_QUERY_LIMITED_INFORMATION  = $1000

#PROCESS_NAME_NATIVE = $00000001

#ProcessWow64Information = 26

#PROCESSOR_ARCHITECTURE_AMD64   = 9 ; x64 (AMD Or Intel)
#PROCESSOR_ARCHITECTURE_IA64    = 6 ; Intel Itanium Processor Family (IPF)
#PROCESSOR_ARCHITECTURE_INTEL   = 0 ; x86
#PROCESSOR_ARCHITECTURE_UNKNOWN = $ffff

; ---------------------------------------------------------------------------
;- Types

; Structure HEAPENTRY32
;   dwSize.l
;   hHandle.l
;   dwAddress.l
;   dwBlockSize.l
;   dwFlags.l
;   dwLockCount.l
;   dwResvd.l
;   th32ProcessID.l
;   th32HeapID.l
; EndStructure

; Structure MODULEENTRY32
;   dwSize.l
;   th32ModuleID .l ; This module
;   th32ProcessID.l ; owning process
;   GlblcntUsage.l  ; Global usage count on the module
;   ProccntUsage.l  ; Module usage count in th32ProcessID's context
;   *modBaseAddr.b  ; Base address of module in th32ProcessID's context
;   modBaseSize.l   ; Size in bytes of module starting at modBaseAddr
;   *hModule.i      ; The hModule of this module in th32ProcessID's context
;   szModule.c[MAX_MODULE_NAME32 + 1]
;   szExePath.c[MAX_PATH]
; EndStructure

; Structure PROCESSENTRY32
;   dwSize.l
;   cntUsage.l
;   th32ProcessID.l       ; this process
;   *th32DefaultHeapID.i
;   th32ModuleID.l        ; associated exe
;   cntThreads.l
;   th32ParentProcessID.l ; this process's parent process
;   pcPriClassBase.l      ; Base priority of process's threads
;   dwFlags.l
;   szExeFile.c[MAX_PATH] ; Path
; EndStructure

; Structure THREADENTRY32
;   dwSize.l
;   cntUsage.l
;   th32ThreadID.l        ; this thread
;   th32OwnerProcessID.l  ; Process this thread is associated With
;   tpBasePri.l
;   tpDeltaPri.l
;   dwFlags.l
; EndStructure


; ---------------------------------------------------------------------------
;- Prototypes

Declare.b Load_Kernel32()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_Kernel32()
CompilerElse
  Macro Unload_Kernel32()
    ; Do nothing!
  EndMacro
CompilerEndIf

Prototype.i protoLoadLibrary(*lpFileName.s)
Prototype.b protoFreeLibrary(*hModule.i)
Prototype.b protoCloseHandle(*hObject.i)

Prototype.i protoGetCurrentProcess()
Prototype.i protoGetCurrentProcessId()
Prototype.i protoGetModuleHandle(lpModuleName.s)
Prototype.i protoOpenProcess(dwDesiredAccess.l, bInheritHandle.b, dwProcessId.l)
Prototype.l protoGetModuleFileName(*hModule.i, *lpFilename.s, nSize.l)

Prototype.i protoCreateToolhelp32Snapshot(dwFlags.l, th32ProcessID.l)

; Prototype.b protoHeap32First(*lphe.HEAPENTRY32, th32ProcessID.l, *th32HeapID.i)
; Prototype.b protoHeap32Next(*lphe.HEAPENTRY32)
; Prototype.b protoHeap32ListFirst(*hSnapshot.i, *lphl.HEAPLIST32)
; Prototype.b protoHeap32ListNext(*hSnapshot.i, *lphl.HEAPLIST32)

Prototype.b protoModule32First(*hSnapshot.i, *lpme.MODULEENTRY32)
Prototype.b protoModule32Next(*hSnapshot.i, *lpme.MODULEENTRY32)

Prototype.b protoProcess32First(*hSnapshot.i, *lppe.PROCESSENTRY32)
Prototype.b protoProcess32Next(*hSnapshot, *lppe.PROCESSENTRY32)
Prototype.b protoThread32First(*hSnapshot.i, *lpte.THREADENTRY32)
Prototype.b protoThread32Next(*hSnapshot.i, *lpte.THREADENTRY32)

Prototype.b protoQueryFullProcessImageName(*hProcess.i, dwFlags.l, *lpExeName.s, *lpdwSize.l)

Prototype.l protoGetLogicalDriveStrings(nBufferLength.l, *lpBuffer.s)
Prototype.l protoQueryDosDevice(*lpDeviceName.i, *lpTargetPath.i, ucchMax.l)
Prototype.b protoGetVolumePathName(*lpszFileName, *lpszVolumePathName, cchBufferLength.l)

Prototype.b protoTerminateProcess(*hProcess.i, uExitCode.i)

Prototype.i protoVirtualQueryEx(*hProcess.i, *lpAddress.i, *lpBuffer.MEMORY_BASIC_INFORMATION, dwLength.i)

Prototype protoGetNativeSystemInfo(*lpSystemInfo.SYSTEM_INFO)

; Resource Mgmt
Prototype.i protoBeginUpdateResource(*pFileName.s, bDeleteExistingResources.b)
Prototype.b protoEndUpdateResource(*hUpdate.i, fDiscard.b)
Prototype.b protoUpdateResource(*hUpdate.i, *lpType.s, *lpName.s, wLanguage.w, *lpData, cbData.l)
Prototype.i protoFindResource(*hModule.i, *lpName.s, *lpType.s)
Prototype.i protoLoadResource(*hModule.i, *hResInfo.i)
Prototype.i protoLockResource(*hResData.i)
Prototype.l protoSizeofResource(*hModule.i, *hResInfo.i)

Prototype.l protoWaitForSingleObject(*hHandle.i, dwMilliseconds.l)

Prototype.l protoCreateRemoteThread(*hProcess.i, *lpThreadAttributes.SECURITY_ATTRIBUTES, dwStackSize.i, *lpStartAddress.i, *lpParameter.i, dwCreationFlags.l, *lpOutThreadId.l)
Prototype.i protoVirtualAllocEx(*hProcess.i, *lpAddress.i, dwSize.i, flAllocationType.l, flProtect.l)
Prototype.i protoVirtualFreeEx(*hProcess.i, *lpAddress.i, dwSize.i, dwFreeType.l)
Prototype.b protoWriteProcessMemory(*hProcess.i, *lpBaseAddress.i, *lpBuffer.i, nSize.i, *lpNumberOfBytesWritten.i)
Prototype.b protoReadProcessMemory(*hProcess.i, *lpBaseAddress, *lpBuffer, nSize.i, *lpNumberOfBytesRead.i)

; Misc
Prototype protoSleep( dwMilliseconds.l)


; ---------------------------------------------------------------------------
;- Variables

Global kernel32.i = 0
Global kernel32Sizer.i = 0

Global LoadLibrary.protoLoadLibrary = 0
Global FreeLibrary.protoFreeLibrary = 0
Global CloseHandle.protoCloseHandle = 0

Global GetCurrentProcess.protoGetCurrentProcess = 0
Global GetCurrentProcessId.protoGetCurrentProcessId = 0
Global GetModuleHandle.protoGetModuleHandle = 0
Global OpenProcess.protoOpenProcess = 0
Global GetModuleFileName.protoGetModuleFileName = 0

Global CreateToolhelp32Snapshot.protoCreateToolhelp32Snapshot = 0

; Global Heap32First.protoHeap32First = 0
; Global Heap32Next.protoHeap32Next = 0
; Global Heap32ListFirst.protoHeap32ListFirst = 0
; Global Heap32ListNext.protoHeap32ListNext = 0

Global Module32First.protoModule32First = 0
Global Module32Next.protoModule32Next = 0

Global Process32First.protoProcess32First = 0
Global Process32Next.protoProcess32Next = 0

Global Thread32First.protoThread32First = 0
Global Thread32Next.protoThread32Next = 0

Global QueryFullProcessImageName.protoQueryFullProcessImageName = 0

Global GetLogicalDriveStrings.protoGetLogicalDriveStrings = 0
Global QueryDosDevice.protoQueryDosDevice = 0
Global GetVolumePathName.protoGetVolumePathName = 0

Global TerminateProcess.protoTerminateProcess = 0

Global VirtualQueryEx.protoVirtualQueryEx = 0

Global GetNativeSystemInfo.protoGetNativeSystemInfo = 0

Global BeginUpdateResource.protoBeginUpdateResource = 0
Global EndUpdateResource.protoEndUpdateResource = 0
Global UpdateResource.protoUpdateResource = 0
Global FindResource.protoFindResource = 0
Global LoadResource.protoLoadResource = 0
Global LockResource.protoLockResource = 0
Global SizeofResource.protoSizeofResource = 0

Global WaitForSingleObject.protoWaitForSingleObject = 0

Global CreateRemoteThread.protoCreateRemoteThread = 0
Global VirtualAllocEx.protoVirtualAllocEx = 0
Global VirtualFreeEx.protoVirtualFreeEx = 0
Global WriteProcessMemory.protoWriteProcessMemory = 0
Global ReadProcessMemory.protoReadProcessMemory = 0

Global Sleep.protoSleep = 0

; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_Kernel32()
  CompilerIf #SIZE_MATTERS
    If kernel32Sizer > 0
      kernel32Sizer = kernel32Sizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If kernel32
      ProcedureReturn #True
    EndIf
  CompilerEndIf
  
  kernel32 = OpenLibrary(#PB_Any, "kernel32.dll")
  If Not kernel32
    kernel32 = 0
    ProcedureReturn #False
  EndIf
  
  LoadLibrary = GetFunction(kernel32, "LoadLibraryA")
  FreeLibrary = GetFunction(kernel32, "FreeLibrary")
  CloseHandle = GetFunction(kernel32, "CloseHandle")
  
  GetCurrentProcess = GetFunction(kernel32, "GetCurrentProcess")
  GetCurrentProcessId = GetFunction(kernel32, "GetCurrentProcessId")
  GetModuleHandle = GetFunction(kernel32, "GetModuleHandleA")
  OpenProcess = GetFunction(kernel32, "OpenProcess")
  GetModuleFileName = GetFunction(kernel32, "GetModuleFileNameA")
  
  CreateToolhelp32Snapshot = GetFunction(kernel32, "CreateToolhelp32Snapshot")
  
;   Heap32First = GetFunction(kernel32, "Heap32First")
;   Heap32Next = GetFunction(kernel32, "Heap32Next")
;   Heap32ListFirst = GetFunction(kernel32, "Heap32ListFirst")
;   Heap32ListNext = GetFunction(kernel32, "Heap32ListNext")
  
  Module32First = GetFunction(kernel32, "Module32First")
  Module32Next = GetFunction(kernel32, "Module32Next")
  
  Process32First = GetFunction(kernel32, "Process32First")
  Process32Next = GetFunction(kernel32, "Process32Next")
  
  Thread32First = GetFunction(kernel32, "Thread32First")
  Thread32Next = GetFunction(kernel32, "Thread32Next")
  
  ; Vista or higher ...
  QueryFullProcessImageName = GetFunction(kernel32, "QueryFullProcessImageNameA")
  
  GetLogicalDriveStrings = GetFunction(kernel32, "GetLogicalDriveStringsA")
  QueryDosDevice = GetFunction(kernel32, "QueryDosDeviceA")
  GetVolumePathName = GetFunction(kernel32, "GetVolumePathNameA")
  
  TerminateProcess = GetFunction(kernel32, "TerminateProcess")
  
  VirtualQueryEx = GetFunction(kernel32, "VirtualQueryEx")
  
  GetNativeSystemInfo = GetFunction(kernel32, "GetNativeSystemInfo")
  
  BeginUpdateResource = GetFunction(kernel32, "BeginUpdateResourceA")
  EndUpdateResource = GetFunction(kernel32, "EndUpdateResourceA")
  UpdateResource = GetFunction(kernel32, "UpdateResourceA")
  FindResource = GetFunction(kernel32, "FindResourceA")
  LoadResource = GetFunction(kernel32, "LoadResource")
  LockResource = GetFunction(kernel32, "LockResource")
  SizeofResource = GetFunction(kernel32, "SizeofResource")
  
  WaitForSingleObject = GetFunction(kernel32, "WaitForSingleObject")
  
  CreateRemoteThread = GetFunction(kernel32, "CreateRemoteThread")
  VirtualAllocEx = GetFunction(kernel32, "VirtualAllocEx")
  VirtualFreeEx = GetFunction(kernel32, "VirtualFreeEx")
  WriteProcessMemory = GetFunction(kernel32, "WriteProcessMemory")
  ReadProcessMemory = GetFunction(kernel32, "ReadProcessMemory")
  
  Sleep = GetFunction(kernel32, "Sleep")
  
  ; Heap32First And Heap32Next And Heap32ListFirst And Heap32ListNext And 
  If Not (LoadLibrary And FreeLibrary And CloseHandle And GetCurrentProcess And GetCurrentProcessId And GetModuleHandle And OpenProcess And GetModuleFileName And CreateToolhelp32Snapshot And Module32First And Module32Next And Process32First And Process32Next And Thread32First And Thread32Next And GetLogicalDriveStrings And QueryDosDevice And GetVolumePathName And TerminateProcess And VirtualQueryEx And BeginUpdateResource And EndUpdateResource And UpdateResource And FindResource And LoadResource And LockResource And SizeofResource And WaitForSingleObject And CreateRemoteThread And VirtualAllocEx And WriteProcessMemory And ReadProcessMemory And Sleep)
    Unload_Kernel32()
    ProcedureReturn #False
  EndIf
  
  kernel32Sizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_Kernel32()
    kernel32Sizer = kernel32Sizer - 1
    
    If kernel32Sizer > 0
      ProcedureReturn #False
    EndIf
    
    If kernel32 <> 0
      CloseLibrary(kernel32)
    EndIf
    
    kernel32 = 0
    kernel32Sizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 338
; FirstLine = 295
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant