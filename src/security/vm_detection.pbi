; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


;IncludeFile(#LOOP_FILE)

#VM_BUFFER_SIZE = 128
Define vmfunctionCount.i = 0
Define *vmBuffer = AllocateMemory(#VM_BUFFER_SIZE)
Define vm8.c
Define vm16.w

CompilerIf Defined(VMDETECTION_STANDALONE, #PB_Constant)
  #LOOP_FILE = "vm_detection_loop.pbi"
  If Not OpenConsole()
    End
  EndIf
  
  Procedure PrettyPrintBuffer(name.s, *buffer, size.i)
    Define count.i
    Print(name + ": ")
    For count = 0 To size-1
      Print(RSet(Hex(PeekC(*buffer+count), #PB_Byte), 2, "0") + " ")
    Next
    PrintN("")
  EndProcedure
  
  ; Test
  ; Print IDTR, GDTR and LDTR
  FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
  !MOV EAX, dword [p_vmBuffer]
  !SIDT [EAX]
  PrettyPrintBuffer("IDTR", *vmBuffer, 6)
  
  FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
  !MOV EAX, dword [p_vmBuffer]
  !SGDT [EAX]
  PrettyPrintBuffer("GDTR", *vmBuffer, 6)
  
  FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
  !MOV EAX, dword [p_vmBuffer]
  !SLDT [EAX]
  PrettyPrintBuffer("LDTR", *vmBuffer, 6)
  
  Input()
  
CompilerElse
  #LOOP_FILE = "security/vm_detection_loop.pbi"
CompilerEndIf

;EnableASM

; Check 1
vmfunctionCount = vmfunctionCount + 1
!XOR AX, AX
!SLDT AX
!MOV [v_vm16], AX
If vm16 <> 0
  IncludeFile(#LOOP_FILE)
EndIf

; Check 2
vmfunctionCount = vmfunctionCount + 1
FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
!MOV EAX, dword [p_vmBuffer]
!SIDT [EAX]
If PeekC(*vmBuffer+5) > $D0
  IncludeFile(#LOOP_FILE)
EndIf

; Check 3
vmfunctionCount = vmfunctionCount + 1
FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
!MOV EAX, dword [p_vmBuffer]
!SGDT [EAX]
If PeekC(*vmBuffer+5) > $D0
  IncludeFile(#LOOP_FILE)
EndIf

; Check 4
vmfunctionCount = vmfunctionCount + 1
FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
!MOV EAX, dword [p_vmBuffer]
!SLDT [EAX]
If (PeekC(*vmBuffer) <> 0) And (PeekC(*vmBuffer+1) <> 0)
  IncludeFile(#LOOP_FILE)
EndIf

; Check 5
vmfunctionCount = vmfunctionCount + 1
FillMemory(*vmBuffer, #VM_BUFFER_SIZE)
!MOV EAX, dword [p_vmBuffer]
!STR [EAX]
If (PeekC(*vmBuffer) = 0) And (PeekC(*vmBuffer+1) = $40)
  IncludeFile(#LOOP_FILE)
EndIf

;DisableASM

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 42
; FirstLine = 18
; Folding = -
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant