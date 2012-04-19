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

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes


; ---------------------------------------------------------------------------
;- Variables
Define res.b = 0
Define targetExe.s = ""
Define command.s = ""
Define resName.s = ""


; ---------------------------------------------------------------------------
;- Procedures

Procedure PrintHelp()
  PrintN("Resource Modifier v0.1" + #CRLF$ + "----------------------" + #CRLF$)
  PrintN("usage: resourceModifier [target PE file (e.g. hello.exe)] [command] [args]" + #CRLF$ + #CRLF$ + #CRLF$ + "Supported commands:" + #CRLF$  + "   addString" + #CRLF$  + "     'resourceName' 'resourceValue'" + #CRLF$  + "   removeString" + #CRLF$  + "     'resourceName'" + #CRLF$  + "   addFile/addBitmap" + #CRLF$  + "     'resourceName' 'file-name'" + #CRLF$  + "   removeFile" + #CRLF$  + "     'resourceName'" + #CRLF$ + #CRLF$ + #CRLF$  + "Examples:" + #CRLF$  + "   resourceModifier anyExe.exe addString 'AnyName01' 'Hello World!'" + #CRLF$  + "   resourceModifier anyExe.exe addFile 'AnyName02' 'C:\pagefile.sys'" + #CRLF$ + "   resourceModifier anyExe.exe removeString 'AnyName01'" + #CRLF$ + "   resourceModifier anyExe.exe removeFile 'AnyName02'")
  End 1
EndProcedure

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure Sample(param.l)
  ; params:
  ;   - param -> first parameter
;EndProcedure

; ---------------------------------------------------------------------------

If Not OpenConsole()
  End 1
EndIf

If CountProgramParameters() = 0
  PrintHelp()
EndIf

targetExe = ProgramParameter()
command = LCase(ProgramParameter())
resName = ProgramParameter()

If resName = ""
  PrintHelp()
EndIf

Select command
  Case "addstring"
    res = ResourceAddString(targetExe, resName, ProgramParameter())
  Case "addfile"
    res = ResourceAddDataFromFile(targetExe, resName, ProgramParameter())
  Case "addbitmap"
    res = ResourceAddDataFromFile(targetExe, resName, ProgramParameter(), #RT_BITMAP)
  Case "removestring"
    res = ResourceRemoveString(targetExe, resName)
  Case "removefile"
    res = ResourceRemoveData(targetExe, resName)
  Default
    PrintHelp()
EndSelect

If res
  PrintN("  Done.")
Else
  PrintN("  Error!")
EndIf

End (Not res)

;Debug ResourceAddString("I:\addResource.exe", "TestResStr", "Any String Value.")
;Debug ResourceRemoveString("I:\addResource.exe", "TestResStr")
;Debug ResourceLoadString("TestResStr", "I:\addResource.exe")

; IDE Options = PureBasic 4.51 (Windows - x64)
; CursorPosition = 78
; FirstLine = 57
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant