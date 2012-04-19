; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

; void DisplayError(DWORD NTStatusMessage)
; {
;    LPVOID lpMessageBuffer;
;    HMODULE Hand = LoadLibrary("NTDLL.DLL");
;    
;    FormatMessage(
;        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
;        FORMAT_MESSAGE_FROM_SYSTEM | 
;        FORMAT_MESSAGE_FROM_HMODULE,
;        Hand, 
;        Err,  
;        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
;        (LPTSTR) &lpMessageBuffer,  
;        0,  
;        NULL);
; 
;    // Now display the string.
; 
;    // Free the buffer allocated by the system.
;    LocalFree(lpMessageBuffer); 
;    FreeLibrary(Hand);
; }

; ---------------------------------------------------------------------------
;- Consts
#ProcessBasicInformation  = 0
#STATUS_SUCCESS           = $00000000

; ---------------------------------------------------------------------------
;- Prototypes

Prototype.i protoPPEBLOCKROUTINE(*PebLock.i)

Declare.b Load_ntdll()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_ntdll()
CompilerElse
  Macro Unload_ntdll()
    ; Do nothing!
  EndMacro
CompilerEndIf

Prototype.i protoNtQueryInformationProcess(*ProcessHandle.i, ProcessInformationClass.i, *ProcessInformation.i, *ProcessInformationLength.i, *ReturnLength.l)


; ---------------------------------------------------------------------------
;- Types

Structure MY_LARGE_INTEGER
  LowPart.l
  HighPart.l
  QuadPart.q
EndStructure

Enumeration 
  #ProcessBasicInformation = 0
  #ProcessQuotaLimits
  #ProcessIoCounters
  #ProcessVmCounters
  #ProcessTimes
  #ProcessBasePriority
  #ProcessRaisePriority
  #ProcessDebugPort
  #ProcessExceptionPort
  #ProcessAccessToken
  #ProcessLdtInformation
  #ProcessLdtSize
  #ProcessDefaultHardErrorMode
  #ProcessIoPortHandlers
  #ProcessPooledUsageAndLimits
  #ProcessWorkingSetWatch
  #ProcessUserModeIOPL
  #ProcessEnableAlignmentFaultFixup
  #ProcessPriorityClass
  #ProcessWx86Information
  #ProcessHandleCount
  #ProcessAffinityMask
  #ProcessPriorityBoost
  #MaxProcessInfoClass
EndEnumeration

Structure UNICODE_STRING
  ; <wine>\include\winternl.h
  Length.u        ; /* bytes */
  MaximumLength.u ; /* bytes */
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
    unknown.c[4]
  CompilerEndIf
  *Buffer.u       ; /* PWSTR */
EndStructure

Structure LIST_ENTRY
  ; <wine>\include\winnt.h
  *Flink.LIST_ENTRY
  *Blink.LIST_ENTRY
EndStructure

Structure PEB_LDR_DATA
  ; <wine>\include\winternl.h
  Length.l
  Initialized.u
  *SsHandle.i
  *InLoadOrderModuleList.LIST_ENTRY
  *InMemoryOrderModuleList.LIST_ENTRY
  *InInitializationOrderModuleList.LIST_ENTRY
EndStructure

Structure CURDIR
  ; <wine>\include\winternl.h
  DosPath.UNICODE_STRING
  *Handle.i
EndStructure

Structure RTL_DRIVE_LETTER_CURDIR
  ; <wine>\include\winternl.h
  Flags.u ; /* USHORT */
  Length.u ; /* USHORT */
  TimeStamp.l
  DosPath.UNICODE_STRING
EndStructure

Structure RTL_USER_PROCESS_PARAMETERS
  ; <wine>\include\winternl.h                     /* win32/win64 */
  MaximumLength.l;                                 /* 000/000 */
  Length.l;                                           /* 004/004 */
  Flags.l;                                          /* 008/008 */
  DebugFlags.l;                                     /* 00C/00C */
  *ConsoleHandle.i;                                 /* 010/010 */
  ConsoleFlags.l;                                   /* 014/018 */
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
    unknown.c[4];                                   /*    /01C */
  CompilerEndIf
  *StandardInput.i;                                 /* 018/020 */
  *StandardOutput.i;                                /* 01C/028 */
  *StandardError.i;                                 /* 020/030 */
  CurrentDirectory.CURDIR;                          /* 024/038 */
  DllPath.UNICODE_STRING;                           /* 030/050 */
  ImagePathName.UNICODE_STRING;                     /* 038/060 */
  CommandLine.UNICODE_STRING;                       /* 040/070 */
  *Environment.u; /* PWSTR */                       /* 048/080 */
  StartingX.l;                                      /* 04C/088 */
  StartingY.l;                                      /* 050/08C */
  CountX.l;                                         /* 054/090 */
  CountY.l;                                         /* 058/094 */
  CountCharsX.l;                                    /* 05C/098 */
  CountCharsY.l;                                    /* 060/09C */
  FillAttribute.l;                                  /* 064/0A0 */
  WindowFlags.l;                                    /* 068/0A4 */
  ShowWindowFlags.l;                                /* 06C/0A8 */
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
    unknown2.c[4];                                  /*    /0AC */
  CompilerEndIf
  WindowTitle.UNICODE_STRING;                       /* 070/0B0 */
  DesktopInfo.UNICODE_STRING;                       /* 078/0C0 */
  ShellInfo.UNICODE_STRING;                         /* 080/0D0 */
  RuntimeData.UNICODE_STRING;                       /* 088/0E0 */
  CurrentDirectores.RTL_DRIVE_LETTER_CURDIR[32];    /*    /0F0 */
  EnvironmentSize.i;                                /*    /3F0 */
  EnvironmentVersion.i;                             /*    /3F8 */
EndStructure

Structure RTL_CRITICAL_SECTION
  ; <wine>\include\winnt.h
  *DebugInfo.i; /* PRTL_CRITICAL_SECTION_DEBUG */
  LockCount.l
  RecursionCount.l
  *OwningThread.i
  *LockSemaphore.i
  *SpinCount.l
EndStructure

Structure RTL_BITMAP
  ; <wine>\include\winternl.h
  SizeOfBitMap.l; /* Number of bits in the bitmap */
  *Buffer.l     ; /* Bitmap data, assumed sized to a DWORD boundary */
EndStructure

Structure PEB
  ; <wine>\include\winternl.h                     /* win32/win64 */
  InheritedAddressSpace.c;                          /* 000/000 */
  ReadImageFileExecOptions.c;                       /* 001/001 */
  BeingDebugged.c;                                  /* 002/002 */
  CompilerSelect #PB_Compiler_Processor
    CompilerCase #PB_Processor_x86
      SpareBool.c;                                  /* 003/003 */
    CompilerCase #PB_Processor_x64
      SpareBool.c[5];                               /* 003/003 */
  CompilerEndSelect
  *Mutant.i;                                        /* 004/008 */
  *ImageBaseAddress.i;                              /* 008/010 */
  *LdrData.PEB_LDR_DATA;                            /* 00c/018 */
  *ProcessParameters.RTL_USER_PROCESS_PARAMETERS;   /* 010/020 */
  *SubSystemData.i;                                 /* 014/028 */
  *ProcessHeap.i;                                   /* 018/030 */
  *FastPebLock.RTL_CRITICAL_SECTION;                /* 01c/038 */
  *FastPebLockRoutine.i; /*PPEBLOCKROUTINE*/        /* 020/040 */
  *FastPebUnlockRoutine.i; /*PPEBLOCKROUTINE*/      /* 024/048 */
  EnvironmentUpdateCount.l;                         /* 028/050 */
  *KernelCallbackTable.i;                           /* 02c/058 */
  Reserved.l[2];                                    /* 030/060 */
  *FreeList.i; /*PPEB_FREE_BLOCK*/                  /* 038/068 */
  TlsExpansionCounter.l;                            /* 03c/070 */
  *TlsBitmap.RTL_BITMAP;                            /* 040/078 */
  TlsBitmapBits.l[2];                               /* 044/080 */
  *ReadOnlySharedMemoryBase.i;                      /* 04c/088 */
  *ReadOnlySharedMemoryHeap.i;                      /* 050/090 */
  *ReadOnlyStaticServerData.i;                      /* 054/098 */
  *AnsiCodePageData.i;                              /* 058/0a0 */
  *OemCodePageData.i;                               /* 05c/0a8 */
  *UnicodeCaseTableData.i;                          /* 060/0b0 */
  NumberOfProcessors.l;                             /* 064/0b8 */
  NtGlobalFlag.l;                                   /* 068/0bc */
  CriticalSectionTimeout.MY_LARGE_INTEGER;          /* 070/0c0 */
  HeapSegmentReserve.i;                             /* 078/0c8 */
  HeapSegmentCommit.i;                              /* 07c/0d0 */
  HeapDeCommitTotalFreeThreshold.i;                 /* 080/0d8 */
  HeapDeCommitFreeBlockThreshold.i;                 /* 084/0e0 */
  NumberOfHeaps.l;                                  /* 088/0e8 */
  MaximumNumberOfHeaps.l;                           /* 08c/0ec */
  *ProcessHeaps.i;                                  /* 090/0f0 */
  *GdiSharedHandleTable.i;                          /* 094/0f8 */
  *ProcessStarterHelper.i;                          /* 098/100 */
  *GdiDCAttributeList.i;                            /* 09c/108 */
  *LoaderLock.i;                                    /* 0a0/110 */
  OSMajorVersion.l;                                 /* 0a4/118 */
  OSMinorVersion.l;                                 /* 0a8/11c */
  OSBuildNumber.l;                                  /* 0ac/120 */
  OSPlatformId.l;                                   /* 0b0/124 */
  ImageSubSystem.l;                                 /* 0b4/128 */
  ImageSubSystemMajorVersion.l;                     /* 0b8/12c */
  ImageSubSystemMinorVersion.l;                     /* 0bc/130 */
  ImageProcessAffinityMask.l;                       /* 0c0/134 */
  *GdiHandleBuffer.i[28];                           /* 0c4/138 */
  unknown.l[6];                                     /* 134/218 */
  *PostProcessInitRoutine.i;                        /* 14c/230 */
  *TlsExpansionBitmap.RTL_BITMAP;                   /* 150/238 */
  TlsExpansionBitmapBits.l[32];                     /* 154/240 */
  SessionId.l;                                      /* 1d4/2c0 */
  AppCompatFlags.LARGE_INTEGER;                     /* 1d8/2c8 */
  AppCompatFlagsUser.LARGE_INTEGER;                 /* 1e0/2d0 */
  *ShimData.i;                                      /* 1e8/2d8 */
  *AppCompatInfo.i;                                 /* 1ec/2e0 */
  CSDVersion.UNICODE_STRING;                        /* 1f0/2e8 */
  *ActivationContextData.i;                         /* 1f8/2f8 */
  *ProcessAssemblyStorageMap.i;                     /* 1fc/300 */
  *SystemDefaultActivationData.i;                   /* 200/308 */
  *SystemAssemblyStorageMap.i;                      /* 204/310 */
  MinimumStackCommit.i;                             /* 208/318 */
  *FlsCallback.i;                                   /* 20c/320 */
  FlsListHead.LIST_ENTRY;                           /* 210/328 */
  *FlsBitmap.RTL_BITMAP;                            /* 218/338 */
  FlsBitmapBits.l[4];                               /* 21c/340 */
EndStructure

Structure PROCESS_BASIC_INFORMATION
  ; <wine>\include\winternl.h                     /* win32/win64 */
  ExitStatus.i;                                     /* 000/000 */
  *PebBaseAddress.PEB;                              /* 004/008 */
  AffinityMask.i;                                   /* 008/010 */
  BasePriority.i;                                   /* 00C/018 */
  UniqueProcessId.i;                                /* 010/020 */
  InheritedFromUniqueProcessId.i;                   /* 014/028 */
EndStructure

; ---------------------------------------------------------------------------
;- Delayed Prototypes
Declare.s NtUnicodeStringToString(*pUstr.UNICODE_STRING)

; ---------------------------------------------------------------------------
;- Variables

Global ntdll.i = 0
Global ntdllSizer.i = 0

Global NtQueryInformationProcess.protoNtQueryInformationProcess = 0


; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_ntdll()
  CompilerIf #SIZE_MATTERS
    If ntdllSizer > 0
      ntdllSizer = ntdllSizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If ntdll
      ProcedureReturn #True
    EndIf
  CompilerEndIf
  
  ntdll = OpenLibrary(#PB_Any, "ntdll.dll")
  If Not ntdll
    ntdll = 0
    ProcedureReturn #False
  EndIf
  
  NtQueryInformationProcess = GetFunction(ntdll, "NtQueryInformationProcess")
  
  If Not (NtQueryInformationProcess)
    Unload_ntdll()
    ProcedureReturn #False
  EndIf
  
  ntdllSizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_ntdll()
    ntdllSizer = ntdllSizer - 1
    
    If ntdllSizer > 0
      ProcedureReturn #False
    EndIf
    
    If ntdll <> 0
      CloseLibrary(ntdll)
    EndIf
    
    ntdll = 0
    ntdllSizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

Procedure.s NtUnicodeStringToString(*pUstr.UNICODE_STRING)
  If (*pUstr\Buffer <> #Null) And (*pUstr\Length > 0)
    ProcedureReturn PeekS(*pUstr\Buffer, *pUstr\Length, #PB_Unicode)
  EndIf
  ProcedureReturn ""
EndProcedure

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 299
; FirstLine = 273
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant