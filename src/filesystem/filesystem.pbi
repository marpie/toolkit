; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


;XIncludeFile("")

; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes
Declare.i FileToStream(inFileName.s, *pBufferSize.q)
Declare.b StreamToFile(outFileName.s, *buffer, bufferSize.i, overwriteIfExists.b = #True)

; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * FileToStream -- Reads the whole file to a buffer and returns a pointer. *
; *                 The returned pointer has to be released by the caller.  *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i FileToStream(inFileName.s, *pBufferSize.q)
  Define fileId.i = 0
  Define *buffer.i = 0
  Define bufferSize.q = FileSize(inFileName)
  Define bytesRead.q = 0
  
  If (Not *pBufferSize) Or (bufferSize < 0)
    ProcedureReturn #Null
  EndIf
  
  fileId = ReadFile(#PB_Any, inFileName)
  If fileId
    bufferSize = Lof(fileId)
    *buffer = AllocateMemory(bufferSize)
    If Not *buffer
      Goto FileToStreamError
    EndIf
    bytesRead = ReadData(fileId, *buffer, bufferSize)
    
    If bytesRead < bufferSize
      Goto FileToStreamError
    EndIf
  EndIf
  
  CloseFile(fileId)
  PokeQ(*pBufferSize, bufferSize)
  ProcedureReturn *buffer
  
  FileToStreamError:
  If *buffer
    FreeMemory(*buffer)
  EndIf
  
  If fileId
    CloseFile(fileId)
  EndIf
  
  ProcedureReturn #Null
EndProcedure

; ***************************************************************************
; * StreamToFile -- Write bufferSize-bytes of *buffer to a file.            *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b StreamToFile(outFileName.s, *buffer, bufferSize.i, overwriteIfExists.b = #True)
  Define fileId.i = 0
  Define bytesWritten.q = 0
  If (outFileName = "") Or ((Not overwriteIfExists) And (FileSize(outFileName) >= 0))
    ProcedureReturn #False
  EndIf
  
  fileId = CreateFile(#PB_Any, outFileName)
  If fileId
    bytesWritten = WriteData(fileId, *buffer, bufferSize)
    CloseFile(fileId)
  EndIf
  ProcedureReturn (Not bytesWritten <> bufferSize)
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

; IDE Options = PureBasic 4.50 RC 1 (Windows - x64)
; CursorPosition = 7
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant