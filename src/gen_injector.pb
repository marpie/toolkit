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
XIncludeFile("security/rc4_crypto.pbi")
XIncludeFile("filesystem/pefile.pbi")
XIncludeFile("include/inc_injector.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Define outputFile.s   = ProgramParameter(0)
Define injector32Exe.s = ProgramParameter(1)
Define injector32Dll.s = ProgramParameter(2)
Define injector64Exe.s = ProgramParameter(3)
Define injector64Dll.s = ProgramParameter(4)
Define targetProcessName.s = ProgramParameter(5)


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
; * UpdateInjector -- Packs all the injector parts (32bit exe+dll, 64bit exe+ *
; *                  dll) into one package.                                 *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i UpdateInjector(outFileName.s, injector32Exe.s, injector32Dll.s, injector64Exe.s, injector64Dll.s, targetProcessName.s)
  Define res.b
  Define checkSum.s = GenerateChecksum(outFileName + targetProcessName)
  Define encryptedProcessName.s
  Define encryptedUrlExtension.s
  Define packFilename.s = checkSum + ".pak"
  Define injector64ExeFilename.s = checkSum + "_64.exe"
  
  ; Copy 32bit injector
  If Not CopyFile(injector32Exe, outFileName)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 32bit EXE *
  ; *************************
  
  ; add ARCFOUR key
  If Not ResourceAddString(outFileName, #RES_STR_LOCAL_FILE_NAME, checkSum)
    Goto UpdateInjectorError
  EndIf
  
  ; encrypt the targetProcessName using ARCFOUR + BASE64
  encryptedProcessName = rc4_base64_encrypt(@checkSum, StringByteLength(checkSum), targetProcessName)
  If encryptedProcessName = ""
    Goto UpdateInjectorError
  EndIf
  
  ; add the targetProcessName (encrypted with ARCFOUR+BASE64) to the 32bit injector DLL
  If Not ResourceAddString(outFileName, #RES_STR_TARGET_PROCESS, encryptedProcessName)
    Goto UpdateInjectorError
  EndIf
  
  ; Open PACK Payload
  If Not CreatePack(packFilename)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 32bit DLL *
  ; *************************
  
  ; add the 32bit injector DLL
  If Not AddPackFile(injector32Dll, 9)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 64bit EXE *
  ; *************************
  
  If Not CopyFile(injector64Exe, injector64ExeFilename)
    Goto UpdateInjectorError
  EndIf
  
  ; add ARCFOUR key
  If Not ResourceAddString(injector64ExeFilename, #RES_STR_LOCAL_FILE_NAME, checkSum)
    Goto UpdateInjectorError
  EndIf
  
  ; add the targetProcessName (encrypted with ARCFOUR+BASE64) to the 32bit injector DLL
  If Not ResourceAddString(injector64ExeFilename, #RES_STR_TARGET_PROCESS, encryptedProcessName)
    Goto UpdateInjectorError
  EndIf
  
  ; add the 64bit injector EXE
  If Not AddPackFile(injector64ExeFilename, 9)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 64bit DLL *
  ; *************************
  
  ; add the 64bit injector DLL
  If Not AddPackFile(injector64Dll, 9)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  ; * Add the PACK file to the injector *
  ; ************************************
  
  ClosePack()
  If Not ResourceAddDataFromFile(outFileName, #RES_PAYLOAD, packFilename, #RT_BITMAP)
    Goto UpdateInjectorError
  EndIf
  
  ; *************************************************************************
  
UpdateInjectorCleanup:
  If FileSize(injector64ExeFilename) > 0
    DeleteFile(injector64ExeFilename)
  EndIf
  
  If FileSize(packFilename) > 0
    DeleteFile(packFilename)
  EndIf
  
  ProcedureReturn res
UpdateInjectorError:
  res = 1
  If FileSize(injector32Exe) > 0
    DeleteFile(injector32Exe)
  EndIf
  Goto UpdateInjectorCleanup
EndProcedure

; ---------------------------------------------------------------------------

If Not OpenConsole()
  End
EndIf

If CountProgramParameters() = 0
  PrintN("gen_injector.exe [output-filename] [injector-32bit-filename] [injector-32bit-dll] [injector-64bit-filename] [injector-64bit-dll] [target-process-name]")
  End 1
EndIf

If FileSize(injector32Exe) < 1
  PrintN("File (" + injector32Exe + ") not found!")
  End 1
EndIf

If FileSize(injector32Dll) < 1
  PrintN("File (" + injector32Dll + ") not found!")
  End 1
EndIf

If FileSize(injector64Exe) < 1
  PrintN("File (" + injector64Exe + ") not found!")
  End 1
EndIf

If FileSize(injector64Dll) < 1
  PrintN("File (" + injector64Dll + ") not found!")
  End 1
EndIf

If targetProcessName = ""
  PrintN("Target process name not defined!")
  End 1
EndIf

End UpdateInjector(outputFile, injector32Exe, injector32Dll, injector64Exe, injector64Dll, targetProcessName)

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 129
; FirstLine = 92
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant