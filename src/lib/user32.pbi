; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit


; ---------------------------------------------------------------------------
;- Types

Structure KBDLLHOOKSTRUCT
  vkCode.l
  scanCode.l
  flags.l
  time.l
  *dwExtraInfo.l
EndStructure

; ---------------------------------------------------------------------------
;- Prototypes

Declare.b Load_user32()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_user32()
CompilerElse
  Macro Unload_user32()
    ; Do nothing!
  EndMacro
CompilerEndIf

Prototype.l protoHOOKPROC(code.i, *wParam, *lParam)
Prototype.i protoSetWindowsHookEx(idHook.i, *lpfn.protoHOOKPROC, hmod.i, dwThreadId.l)
Prototype.i protoCallNextHookEx(*hhk.i, nCode.i, *wParam.i, *lParam.i)
Prototype.i protoGetForegroundWindow()
Prototype.i protoGetWindowText(hWnd.i, *lpString.s, nMaxCount.i)
Prototype.l protoGetWindowThreadProcessId(hWnd.i, *lpdwProcessId.l)
Prototype.b protoGetKeyboardState(*lpKeyState.b)
Prototype.i protoMapVirtualKey(uCode.i, uMapType.i)
Prototype.i protoToAscii(uVirtKey.i, uScanCode.i, *lpKeyState.b, *lpChar.w, uFlags.i)
Prototype.i protoGetKeyNameText(lParam.l, *lpString.s, nSize.i)


; ---------------------------------------------------------------------------
;- Variables

Global user32.i = 0
Global user32Sizer.i = 0
Global SetWindowsHookEx.protoSetWindowsHookEx = 0
Global CallNextHookEx.protoCallNextHookEx = 0
Global GetForegroundWindow.protoGetForegroundWindow = 0
Global GetWindowText.protoGetWindowText = 0
Global GetWindowThreadProcessId.protoGetWindowThreadProcessId = 0
Global GetKeyboardState.protoGetKeyboardState = 0
Global MapVirtualKey.protoMapVirtualKey = 0
Global ToAscii.protoToAscii = 0
Global GetKeyNameText.protoGetKeyNameText = 0


; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_user32()
  CompilerIf #SIZE_MATTERS
    If user32Sizer > 0
      user32Sizer = user32Sizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If user32
      ProcedureReturn #True
    EndIf
  CompilerEndIf
  
  user32 = OpenLibrary(#PB_Any, "user32.dll")
  If Not user32
    user32 = 0
    ProcedureReturn #False
  EndIf
  
  SetWindowsHookEx = GetFunction(user32, "SetWindowsHookExA")
  CallNextHookEx = GetFunction(user32, "CallNextHookEx")
  GetForegroundWindow = GetFunction(user32, "GetForegroundWindow")
  GetWindowText = GetFunction(user32, "GetWindowTextA")
  GetWindowThreadProcessId = GetFunction(user32, "GetWindowThreadProcessId")
  GetKeyboardState = GetFunction(user32, "GetKeyboardState")
  MapVirtualKey = GetFunction(user32, "MapVirtualKeyA")
  ToAscii = GetFunction(user32, "ToAscii")
  GetKeyNameText = GetFunction(user32, "GetKeyNameTextA")
  
  If Not (SetWindowsHookEx And GetForegroundWindow And GetWindowText And GetWindowThreadProcessId And GetKeyboardState And MapVirtualKey And ToAscii And GetKeyNameText)
    Unload_user32()
    ProcedureReturn #False
  EndIf
  
  user32Sizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_user32()
    user32Sizer = user32Sizer - 1
    
    If user32Sizer > 0
      ProcedureReturn #False
    EndIf
    
    If user32 <> 0
      CloseLibrary(user32)
    EndIf
    
    user32 = 0
    user32Sizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 75
; FirstLine = 46
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant