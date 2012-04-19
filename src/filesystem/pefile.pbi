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
XIncludeFile("filesystem/filesystem.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types
Enumeration ; PE Machine Type
  #IMAGE_FILE_MACHINE_UNKNOWN    =    $0
  #IMAGE_FILE_MACHINE_AM33       =  $1D3
  #IMAGE_FILE_MACHINE_AMD64      = $8664
  #IMAGE_FILE_MACHINE_ARM        =  $1C0
  #IMAGE_FILE_MACHINE_EBC        =  $EBC
  #IMAGE_FILE_MACHINE_I386       =  $14C
  #IMAGE_FILE_MACHINE_IA64       =  $200
  #IMAGE_FILE_MACHINE_M32R       = $9041
  #IMAGE_FILE_MACHINE_MIPS16     =  $266
  #IMAGE_FILE_MACHINE_MIPSFPU    =  $366
  #IMAGE_FILE_MACHINE_MIPSFPU16  =  $466
  #IMAGE_FILE_MACHINE_POWERPC    =  $1F0
  #IMAGE_FILE_MACHINE_POWERPCFP  =  $1F1
  #IMAGE_FILE_MACHINE_R4000      =  $166
  #IMAGE_FILE_MACHINE_SH3        =  $1A2
  #IMAGE_FILE_MACHINE_SH3DSP     =  $1A3
  #IMAGE_FILE_MACHINE_SH4        =  $1A6
  #IMAGE_FILE_MACHINE_SH5        =  $1A8
  #IMAGE_FILE_MACHINE_THUMB      =  $1C2
  #IMAGE_FILE_MACHINE_WCEMIPSV2  =  $169
EndEnumeration

; ---------------------------------------------------------------------------
;- Prototypes
Declare.b ResourceAddString(peFileName.s, resName.s, resValue.s)
Declare.b ResourceAddDataFromMemory(peFileName.s, resName.s, *memory, memLen.i, resType.i = #RT_RCDATA)
Declare.b ResourceAddDataFromFile(peFileName.s, resName.s, resFile.s, resType.i = #RT_RCDATA)
Declare.b ResourceRemoveString(peFileName.s, resName.s)
Declare.b ResourceRemoveData(peFileName.s, resName.s)
Declare.l ResourceSize(resName.s, resType.i = #RT_RCDATA, peFileName.s = "")
Declare.b ResourceLoadData(*outBuf.i, outBufSize.i, resName.s, resType.i = #RT_RCDATA, peFileName.s = "")
Declare.s ResourceLoadString(resName.s, peFileName.s = "")
Declare.l GetPeMachineTypeFromMemory(*mem, memSize.i)
Declare.l GetPeMachineTypeFromFile(fileName.s)
Declare.b AddPayload(outputFilename.s, payloadFilename.s, resName.s)
Declare.i ExtractPayload(outputFileName.s, resName.s)

; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * ResourceAddString -- Adds the specified string to the pe-file.          *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceAddString(peFileName.s, resName.s, resValue.s)
  Define res.b = #False
  Define *hRes = #Null
  Define hFile.i = #Null
  Define *buffer = #Null
  Define bufferSize.i = 0
  
  If Not Load_Kernel32()
    ProcedureReturn #False
  EndIf
  
  *hRes = BeginUpdateResource(@peFileName, #False)
  If Not *hRes
    Goto ResourceAddStringError
  EndIf
  
  If resValue <> ""
    bufferSize = StringByteLength(resValue)
    *buffer = @resValue
  Else
    ; delete Resource
    *buffer = #Null
    bufferSize = 0
  EndIf
  
  ; Update Resource
  res = UpdateResource(*hRes, #RT_STRING, @resName, #LANG_NEUTRAL, *buffer, bufferSize)
  If Not res
    Goto ResourceAddStringError
  EndIf
  
ResourceAddStringCleanup:
  ; Save/ discard changes
  If *hRes
    If (Not EndUpdateResource(*hRes, (Not res))) And res
      res = #False
    EndIf
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
  
ResourceAddStringError:
  res = #False
  Goto ResourceAddStringCleanup
EndProcedure

; ***************************************************************************
; * ResourceAddDataFromMemory -- Adds the resource from memory.             *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceAddDataFromMemory(peFileName.s, resName.s, *memory, memLen.i, resType.i = #RT_RCDATA)
  Define res.b = #False
  Define *hRes = #Null
  
  If Not Load_Kernel32()
    ProcedureReturn #False
  EndIf
  
  If (Not *memory) Or (memLen = 0)
    *memory = #Null
    memLen = 0
  EndIf
  
  *hRes = BeginUpdateResource(@peFileName, #False)
  If Not *hRes
    Goto ResourceAddDataFromMemoryError
  EndIf
  
  ; Update Resource
  res = UpdateResource(*hRes, resType, @resName, #LANG_NEUTRAL, *memory, memLen)
  If Not res
    Goto ResourceAddDataFromMemoryError
  EndIf
  
  ; HIER RESOURCE LÖSCHEN GEHT NICHT MEHR!!!!!!
  ; *******************************************
  
ResourceAddDataFromMemoryCleanup:
  ; Save/ discard changes
  If *hRes
    If (Not EndUpdateResource(*hRes, (Not res))) And res
      res = #False
    EndIf
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
  
ResourceAddDataFromMemoryError:
  res = #False
  Goto ResourceAddDataFromMemoryCleanup
EndProcedure

; ***************************************************************************
; * ResourceAddDataFromFile -- Adds the specified file as a resource.       *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceAddDataFromFile(peFileName.s, resName.s, inputFile.s, resType.i = #RT_RCDATA)
  Define res.b = #False
  Define hFile.i = #Null
  Define *buffer = #Null
  Define bufferSize.i = 0
  
  If inputFile = ""
    Goto ResourceAddDataFromFileError
  EndIf
  
  ; Open File
  hFile = ReadFile(#PB_Any, inputFile)
  If Not hFile
    Goto ResourceAddDataFromFileError
  EndIf
  
  ; Allocate Memory
  bufferSize = Lof(hFile)
  *buffer = AllocateMemory(bufferSize + 1)
  If ReadData(hFile, *buffer, Lof(hFile)) <> bufferSize
    Goto ResourceAddDataFromFileError
  EndIf
  
  res = ResourceAddDataFromMemory(peFileName, resName, *buffer, bufferSize, resType)
  
ResourceAddDataFromFileCleanup:
  ; Free Memory
  If *buffer
    FreeMemory(*buffer)
  EndIf
  
  ; Close File
  If hFile
    CloseFile(hFile)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
  
ResourceAddDataFromFileError:
  res = #False
  Goto ResourceAddDataFromFileCleanup
EndProcedure

; ***************************************************************************
; * ResourceRemoveString -- Removes the specified resource string.          *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceRemoveString(peFileName.s, resName.s)
  ProcedureReturn ResourceAddString(peFileName, resName, "")
EndProcedure

; ***************************************************************************
; * ResourceRemoveData -- If the resource exists it will be removed.        *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceRemoveData(peFileName.s, resName.s)
  ProcedureReturn ResourceAddDataFromMemory(peFileName, resName, #Null, 0)
EndProcedure

; ***************************************************************************
; * ResourceSize -- Returns the size of the requested resource.             *
; *                 If peFileName is empty the current Process EXE is used. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l ResourceSize(resName.s, resType.i = #RT_RCDATA, peFileName.s = "")
  Define res.l = 0
  Define *hExe = #Null
  Define *hRes.i = #Null
  
  If Not Load_Kernel32()
    Goto ResourceSizeError
  EndIf
  
  If peFileName = ""
    peFileName = ProgramFilename()
  EndIf
  
  *hExe = LoadLibrary(@peFileName)
  If Not *hExe
    Goto ResourceSizeError
  EndIf
  
  *hRes = FindResource(*hExe, @resName, resType)
  If Not *hRes
    Goto ResourceSizeError
  EndIf
  
  res = SizeofResource(*hExe, *hRes)
  
ResourceSizeCleanup:
  If *hExe
    FreeLibrary(*hExe)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
ResourceSizeError:
  res = 0
  Goto ResourceSizeCleanup
EndProcedure

; ***************************************************************************
; * ResourceLoadData -- Reads string into outBuf; returns #True on success. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b ResourceLoadData(*outBuf.i, outBufSize.i, resName.s, resType.i = #RT_RCDATA, peFileName.s = "")
  Define res.b = #False
  Define *hExe = #Null
  Define *hRes.i = #Null, *hResLoad.i = #Null, *hResLock.i = #Null
  
  If Not (Load_Kernel32() And *outBuf Or (outBufSize > 0))
    Goto ResourceLoadDataError
  EndIf
  
  If peFileName = ""
    peFileName = ProgramFilename()
  EndIf
  
  *hExe = LoadLibrary(@peFileName)
  If Not *hExe
    Goto ResourceLoadDataError
  EndIf
  
  *hRes = FindResource(*hExe, @resName, resType)
  If Not *hRes
    Goto ResourceLoadDataError
  EndIf
  
  *hResLoad = LoadResource(*hExe, *hRes)
  If Not *hResLoad
    Goto ResourceLoadDataError
  EndIf
  
  *hResLock = LockResource(*hResLoad)
  If Not *hResLock
    Goto ResourceLoadDataError
  EndIf
  
  CopyMemory(*hResLock, *outBuf, outBufSize)
  
  res = #True
  
ResourceLoadDataCleanup:
  If *hExe
    FreeLibrary(*hExe)
  EndIf
  
  Unload_Kernel32()
  ProcedureReturn res
ResourceLoadDataError:
  res = #False
  Goto ResourceLoadDataCleanup
EndProcedure

; ***************************************************************************
; * ResourceLoadString -- Reads the resource string and returns the value.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s ResourceLoadString(resName.s, peFileName.s = "")
  Define res.s = ""
  Define resSize.i = 0
  
  resSize = ResourceSize(resName, #RT_STRING, peFileName)
  If resSize = 0
    ProcedureReturn ""
  EndIf
  
  ; Prepare Buffer
  res = LSet("", resSize)
  
  If Not ResourceLoadData(@res, resSize, resName, #RT_STRING, peFileName)
    ProcedureReturn ""
  EndIf
  
  ProcedureReturn res
EndProcedure

; ***************************************************************************
; * GetPeMachineTypeFromMemory -- Returns the architecture type of the PE   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l GetPeMachineTypeFromMemory(*mem, memSize.i)
  Define res.i
  Define pos.i = 0
  Define peOffset.l = 0
  
  ; check for MZ or ZM at the beginning of the file
  If (PeekW(*mem) <> $5A4D) And (PeekW(*mem) <> $4D5A)
    Goto GetPeMachineTypeFromMemoryError
  EndIf
  
  ; the PE offset is always at $3C
  peOffset = PeekL(*mem+$3C)
  
  ; check for PE\0\0
  If PeekL(*mem+peOffset) <> $00004550
    Goto GetPeMachineTypeFromMemoryError
  EndIf
  
  ; get MachineType PE_Offset + 4
  res = PeekW(*mem+peOffset+$04)
  
GetPeMachineTypeFromMemoryCleanup:
  ProcedureReturn res
GetPeMachineTypeFromMemoryError:
  res = #IMAGE_FILE_MACHINE_UNKNOWN
  Goto GetPeMachineTypeFromMemoryCleanup
EndProcedure

; ***************************************************************************
; * GetPeMachineTypeFromFile -- Returns the architecture type of the PE     *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.l GetPeMachineTypeFromFile(fileName.s)
  Define res.i
  Define hFile.i = #Null
  Define mzCheck.w = 0
  Define peCheck.l = 0
  Define pos.i = 0
  Define peOffset.l = 0
  
  If fileName = ""
    Goto GetPeMachineTypeFromFileError
  EndIf
  
  hFile = ReadFile(#PB_Any, fileName)
  If Not hFile
    Goto GetPeMachineTypeFromFileError
  EndIf
  
  ; check for MZ or ZM at the beginning of the file
  mzCheck = ReadWord(hFile)
  If (mzCheck <> $5A4D) And (mzCheck <> $4D5A)
    Goto GetPeMachineTypeFromFileError
  EndIf
  
  ; the PE offset is always at $3C
  FileSeek(hFile, $3C)
  peOffset = ReadLong(hFile)
  FileSeek(hFile, peOffset)
  
  ; check for PE\0\0
  If ReadLong(hFile) <> $00004550
    Goto GetPeMachineTypeFromFileError
  EndIf
  
  ; get MachineType
  res = ReadWord(hFile)
  
GetPeMachineTypeFromFileCleanup:
  If hFile
    CloseFile(hFile)
  EndIf
  ProcedureReturn res
GetPeMachineTypeFromFileError:
  res = #IMAGE_FILE_MACHINE_UNKNOWN
  Goto GetPeMachineTypeFromFileCleanup
EndProcedure

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

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 421
; FirstLine = 117
; Folding = A5
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant