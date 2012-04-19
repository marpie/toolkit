; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; * This include file implements the ARCFOUR (RC4) as described in the IETF *
; * DRAFT 'A Stream Cipher Encryption Algorithm "Arcfour"'                  *
; * (draft-kaukonen-cipher-arcfour-03.txt).                                 *
; *                                                                         *
; ***************************************************************************
EnableExplicit


;XIncludeFile("")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types
Structure rc4_data
  SBox.a[256]
EndStructure


; ---------------------------------------------------------------------------
;- Prototypes
Declare rc4_init(*rc4.rc4_data, *key, keylen.i)
Declare rc4_memory(*key, keylen.i, *memory, memLen.i)
Declare.s rc4_base64_encrypt(*key, keylen.i, value.s)
Declare.s rc4_base64_decrypt(*key, keylen.i, value.s)

; ---------------------------------------------------------------------------
;- Variables


; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * rc4_init -- ARCFOUR Key Setup                                           *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure rc4_init(*rc4.rc4_data, *key, keylen.i)
  Define res.b = #True
  Define idx.a = 0
  Define keyIdx.a = 0
  Define j.a = 0
  
  Dim SBox2.b(255)
  
  For idx = 0 To 255
    *rc4\SBox[idx] = idx
    SBox2(idx) = PeekA(*key + keyIdx) & $FF
    keyIdx + 1   ; increment keyIdx
    If keyIdx = keyLen
      keyIdx = 0
    EndIf
  Next
  
  ; initialize SBox
  For idx = 0 To 255
    j = (j + *rc4\SBox[idx] + SBox2(idx)) % 256
    Swap *rc4\Sbox[idx], *rc4\SBox[j]
  Next
  
  FillMemory(@SBox2(), 256)
EndProcedure

; ***************************************************************************
; * rc4_memory -- ARCFOUR memory encryption/ decryption                     *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure rc4_memory(*key, keylen.i, *memory, memLen.i)
  Define rc4.rc4_data
  Define memIdx.i
  Define i.c
  Define j.c
  Define key.c
  
  rc4_init(@rc4, *key, keylen)
  
  For memIdx = 0 To memLen - 1
    i = (i+1) % 256
    j = (j + rc4\SBox[i]) % 256
    Swap rc4\SBox[i], rc4\SBox[j]
    key = rc4\SBox[(rc4\SBox[i] + rc4\SBox[j]) % 256]
    
    PokeC(*memory + memIdx, PeekC(*memory + memIdx) ! key)
  Next
  
  ClearStructure(@rc4, rc4_data)
EndProcedure

; ***************************************************************************
; * rc4_memory -- ARCFOUR stream memory encryption/ decryption              *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure rc4_stream(*rc4.rc4_data, *memory, memLen.i)
  Protected memIdx.i
  Protected i.c
  Protected j.c
  Protected key.c
  
  For memIdx = 0 To memLen - 1
    i = (i+1) % 256
    j = (j + *rc4\SBox[i]) % 256
    Swap *rc4\SBox[i], *rc4\SBox[j]
    key = *rc4\SBox[(*rc4\SBox[i] + *rc4\SBox[j]) % 256]
    
    PokeC(*memory + memIdx, PeekC(*memory + memIdx) ! key)
  Next
EndProcedure

; ***************************************************************************
; * rc4_base64_encrypt -- ARCFOUR String encryption and BASE64 encoding.    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s rc4_base64_encrypt(*key, keylen.i, value.s)
  Define encStr.s = value
  Define inSize.i = StringByteLength(value)
  Define outSize.i = 64+inSize*2
  Define outStr.s = Space(outSize)
  
  ; encrypt string
  rc4_memory(*key, keylen, @encStr, StringByteLength(encStr))
  
  ; encode string
  outSize = Base64Encoder(@encStr, inSize, @outStr, outSize)
  
  ProcedureReturn Left(outStr, outSize)
EndProcedure

; ***************************************************************************
; * rc4_base64_encrypt -- ARCFOUR String decryption and BASE64 decoding.    *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s rc4_base64_decrypt(*key, keylen.i, value.s)
  Define inSize.i = StringByteLength(value)
  Define outSize.i = inSize
  Define outStr.s = Space(outSize)
  
  ; decode string
  outSize = Base64Decoder(@value, inSize, @outStr, outSize)
  
  ; decrypt string
  rc4_memory(*key, keylen.i, @outStr, outSize)
  
  ProcedureReturn Left(outStr, outSize)
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
;   ProcedureReturn res
; SampleError:
;   res = #False
;   Goto SampleCleanup
;EndProcedure

; Procedure.b test_rc4()
;   Define res.b = #True
;   Define rc4.rc4_data
;   Define *mem = #Null
;   Define memLen.i = PeekI(?RC4_Test_Length)
;   
;   *mem = AllocateMemory(memLen)
;   If Not *mem
;     Goto test_rc4Error
;   EndIf
;   
;   TEST ENCRYPTION
;   res = rc4_init(@rc4, ?RC4_Test_Key, memLen)
;   If Not res
;     Goto test_rc4Error
;   EndIf
;   
;   Copy test Data
;   CopyMemory(?RC4_Test_PlainText, *mem, memLen)
;   
;   encrypt
;   rc4_memory(@rc4, *mem, memLen)
;   
;   If Not CompareMemory(*mem, ?RC4_Test_CipherText, memLen)
;     Goto test_rc4Error
;   EndIf
;   
;   test DECRYPTION
;   ARCFOUR init
;   CopyMemory(?RC4_Test_Key, *mem, memLen)
;   res = rc4_init(@rc4, *mem, memLen)
;   If Not res
;     Goto test_rc4Error
;   EndIf
;   
;   Copy test Data
;   CopyMemory(?RC4_Test_CipherText, *mem, memLen)
;   
;   decrypt
;   rc4_memory(@rc4, *mem, memLen)
;   
;   If Not CompareMemory(*mem, ?RC4_Test_PlainText, memLen)
;     Goto test_rc4Error
;   EndIf
;   
; test_rc4Cleanup:
;   
;   ProcedureReturn res
; test_rc4Error:
;   res = #False
;   Goto test_rc4Cleanup
; EndProcedure
; 
; DataSection
;   RC4_Test_Length:
;     Data.i 12
;   RC4_Test_PlainText:
;     Data.c $48, $65, $6C, $6C, $6F, $20, $57, $6F, $72, $6C, $64, $21
;   RC4_Test_Key:
;     Data.c $57, $6F, $72, $6C, $64, $21, $48, $65, $6C, $6C, $6F, $20
;   RC4_Test_CipherText:
;     Data.c $34, $6E, $63, $3B, $66, $98, $FD, $2C, $05, $37, $88, $77
; EndDataSection
; 
; If test_rc4()
;   MessageRequester("test_rc4", "OK")
; Else
;   MessageRequester("test_rc4", "KO!")
; EndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.60 Beta 3 (Windows - x64)
; CursorPosition = 149
; FirstLine = 60
; Folding = 5
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant