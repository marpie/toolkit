; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


XIncludeFile("security/aes_encryption.pbi")

; ---------------------------------------------------------------------------
;- Types

Enumeration ; MSG_VERSION
  #MSG_VERSION_1
EndEnumeration

Structure MSG_HEADER
  version.c        ; 8-bit unsigned  -> MSG_VERSION
  command.c        ; 8-bit unsigned
  dataCompressed.b ; 8-bit unsigned
  dataEncrypted.b  ; 8-bit unsigned
  dataSize.l       ; 64-bit signed
  dataSizePacked.l ; 64-bit signed
  crc32.l          ; 32-bit signed - CRC32 checksum
  ; ... data following ...
EndStructure

Structure MSG_PACK
  header.MSG_HEADER
  *pData.i
  dataSize.l
EndStructure

; ---------------------------------------------------------------------------
;- Prototypes
Declare.i MsgFreePack(*pack.MSG_PACK)
Declare.i MsgCalcWholePackedSize(*header.MSG_HEADER)
Declare.i MsgEncode(msgVersion.c, msgCommand.c, *pInData.i, inDataSize.q)
Declare.i MsgDecode(*pInData, inDataSize.q)


; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * MsgFreeMsgPack -- Frees all memory occupied by the supplied MSG_PACK.   *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i MsgFreePack(*pack.MSG_PACK)
  If Not *pack
    ProcedureReturn #Null
  EndIf
  
  If *pack\pData
    FreeMemory(*pack\pData)
  EndIf
  FreeMemory(*pack)
  
  ProcedureReturn #Null
EndProcedure

; ***************************************************************************
; * MsgCalcWholePackedSize -- Calculates the size that a package needs as a *
; *                           stream.                                       *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i MsgCalcWholePackedSize(*header.MSG_HEADER)
  Define size.i = 0
  If *header\version = #MSG_VERSION_1
    size = SizeOf(MSG_HEADER) + *header\dataSizePacked
  EndIf
  ProcedureReturn size
EndProcedure

; ***************************************************************************
; * MsgEncode -- Returns a pointer to a MSG_PACK struct. The memory has to  *
; *              be freed by the caller.                                    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i MsgEncode(msgVersion.c, msgCommand.c, *pInData.i, inDataSize.q)
  Define *msgPack.MSG_PACK
  Define *bufferCompressed.i = #Null
  Define bufferCompressedSize.q = 0
  
  ; Check for obvious errors.
  If (msgVersion <> #MSG_VERSION_1) Or (Not *pInData And (inDataSize > 0)) Or (inDataSize < 0)
    ProcedureReturn #Null
  EndIf
  
  ; Allocate space for return structure.
  *msgPack = AllocateMemory(SizeOf(MSG_PACK))
  If Not *msgPack
    ProcedureReturn #Null
  EndIf
  FillMemory(*msgPack, SizeOf(MSG_PACK))
  
  ; Populate MSG_HEADER
  *msgPack\header\version = msgVersion
  *msgPack\header\command = msgCommand
  *msgPack\header\dataSize = inDataSize
  *msgPack\header\dataSizePacked = inDataSize
  *msgPack\header\dataCompressed = #False
  *msgPack\header\dataEncrypted = #False
  *msgPack\header\crc32 = 0
  
  If inDataSize = 0
    ; Command only - no data payload
    ; 
    *msgPack\pData = AllocateMemory(SizeOf(MSG_HEADER))
    *msgPack\dataSize = SizeOf(MSG_HEADER)
  Else
    ; --------------- Data compression ---------------
    ; Allocate space for compression buffer
    *bufferCompressed = AllocateMemory(inDataSize + 8)
    If Not *bufferCompressed
      Goto MsgEncodeErrorExit
    EndIf
    
    bufferCompressedSize = PackMemory(*pInData, *bufferCompressed, inDataSize, 9)
    If bufferCompressedSize = 0
      ; Compression not possible
      FreeMemory(*bufferCompressed)
      *bufferCompressed = *pInData
      *msgPack\header\dataSizePacked = inDataSize
    Else
      ; Compression complete
      *msgPack\header\dataCompressed = #True
      *msgPack\header\dataSizePacked = bufferCompressedSize
    EndIf
    ; ------------------------------------------------
    
    ; --------------- Data encryption ---------------
    *msgPack\pData = AllocateMemory(SizeOf(MSG_HEADER) + *msgPack\header\dataSizePacked)
    If Not *msgPack\pData
      Goto MsgEncodeErrorExit
    EndIf
    If encryptionActive
      ; Encrypt data
      If AESEncoder(*bufferCompressed, *msgPack\pData + SizeOf(MSG_HEADER), *msgPack\header\dataSizePacked, ?EncryptionKey, encryptionBitLen, ?EncryptionInitializationVector)
        *msgPack\header\dataEncrypted = #True
      EndIf
    EndIf
    
    If Not *msgPack\header\dataEncrypted
      ; Encryption not active or encryption failed; just copy the unencrypted data.
      CopyMemory(*bufferCompressed, *msgPack\pData + SizeOf(MSG_HEADER), *msgPack\header\dataSizePacked)
    EndIf
    ; -----------------------------------------------
    
    ; --------------- Cleanup ---------------
    If *msgPack\header\dataCompressed And (Not *bufferCompressed = #Null)
      FreeMemory(*bufferCompressed)
      *bufferCompressed = #Null
    EndIf
    ; ---------------------------------------
    
    ; Calculate CRC32 checksum for the (compressed and encrypted) data stream.
    *msgPack\header\crc32 = CRC32Fingerprint(*msgPack\pData + SizeOf(MSG_HEADER), *msgPack\header\dataSizePacked)
    
    ; Set the size of the entire stream.
    *msgPack\dataSize = SizeOf(MSG_HEADER) + *msgPack\header\dataSizePacked
  EndIf
  
  CopyMemory(@*msgPack\header, *msgPack\pData, SizeOf(MSG_HEADER))
  
  ProcedureReturn *msgPack
  
  ; --------------- Error Handling ---------------
  MsgEncodeErrorExit:
  If *msgPack\header\dataCompressed And (Not *bufferCompressed = #Null)
    FreeMemory(*bufferCompressed)
    *bufferCompressed = #Null
  EndIf
  
  If (Not *msgPack\pData = #Null)
    FreeMemory(*msgPack\pData)
    *msgPack\pData = #Null
  EndIf
  
  FreeMemory(*msgPack)
  ProcedureReturn #Null
  ; ----------------------------------------------
EndProcedure

; ***************************************************************************
; * MsgDecode -- Decodes a message previously encoded with MsgEncode. And   *
; *              returns a pointer to a MSG_PACK structure. The memory of   *
; *              the MSG_PACK structure has to be freed by the caller.      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i MsgDecode(*pInData, inDataSize.q)
  Define *msgPack.MSG_PACK
  Define *bufferDecrypted = #Null
  Define currCRC32.l = 0
  
  *msgPack.MSG_PACK = AllocateMemory(SizeOf(MSG_PACK))
  If Not *msgPack
    ProcedureReturn #Null
  EndIf
  FillMemory(*msgPack, SizeOf(MSG_PACK))
  
  If inDataSize < SizeOf(MSG_HEADER)
    Goto MsgDecodeErrorExit
  EndIf
  
  ; Get the MSG_HEADER
  CopyMemory(*pInData, @*msgPack\header, SizeOf(MSG_HEADER))
  
  ; Check for obvious errors
  If ((*msgPack\header\dataCompressed Or *msgPack\header\dataEncrypted) And ((*msgPack\header\dataSize = 0) Or (*msgPack\header\dataSizePacked = 0))) Or ((*msgPack\header\crc32 = 0) And ((*msgPack\header\dataSize > 0) Or (*msgPack\header\dataSizePacked > 0)))
    Goto MsgDecodeErrorExit
  EndIf
  
  If *msgPack\header\dataSize = 0
    ; Command only - no data payload
    ; 
    ; Nothing to do here ...
    ; 
  Else
    If *msgPack\header\dataSizePacked > inDataSize-SizeOf(MSG_HEADER)
      Goto MsgDecodeErrorExit
    EndIf
    
    ; Change input to point to the data stream
    *pInData = *pInData + SizeOf(MSG_HEADER)
    
    ; Check for CRC errors
    currCRC32 = CRC32Fingerprint(*pInData, *msgPack\header\dataSizePacked)
    If currCRC32 <> *msgPack\header\crc32
      Goto MsgDecodeErrorExit
    EndIf
    
    ; --------------- Data decryption ---------------
    If encryptionActive And *msgPack\header\dataEncrypted
      *bufferDecrypted = AllocateMemory(*msgPack\header\dataSizePacked)
      If Not *bufferDecrypted
        Goto MsgDecodeErrorExit
      EndIf
      
      If Not AESDecoder(*pInData, *bufferDecrypted, *msgPack\header\dataSizePacked, ?EncryptionKey, encryptionBitLen, ?EncryptionInitializationVector)
        Goto MsgDecodeErrorExit
      EndIf
    Else
      *bufferDecrypted = *pInData
    EndIf
    ; -----------------------------------------------
    
    *msgPack\pData = AllocateMemory(*msgPack\header\dataSize)
    If Not *msgPack\pData
      Goto MsgDecodeErrorExit
    EndIf
    
    ; --------------- Unpack data ---------------
    If *msgPack\header\dataCompressed
      If Not UnpackMemory(*bufferDecrypted, *msgPack\pData) = *msgPack\header\dataSize
        Goto MsgDecodeErrorExit
      EndIf
    Else
      CopyMemory(*bufferDecrypted, *msgPack\pData, *msgPack\header\dataSize)
    EndIf
    ; -------------------------------------------
    
    ; --------------- Cleanup ---------------
    If encryptionActive And *msgPack\header\dataEncrypted And *bufferDecrypted
      FreeMemory(*bufferDecrypted)
      *bufferDecrypted = #Null
    EndIf
    ; ---------------------------------------
    
    *msgPack\dataSize = *msgPack\header\dataSize
  EndIf
  
  ProcedureReturn *msgPack
  
  MsgDecodeErrorExit:
  
  If encryptionActive And *msgPack\header\dataEncrypted And *bufferDecrypted
    FreeMemory(*bufferDecrypted)
    *bufferDecrypted = #Null
  EndIf
  
  If *msgPack\pData
    FreeMemory(*msgPack\pData)
    *msgPack\pData = #Null
  EndIf
  
  FreeMemory(*msgPack)
  ProcedureReturn #Null
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

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 34
; FirstLine = 12
; Folding = w
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant