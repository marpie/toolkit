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
;- Consts
#SECURITY_MANDATORY_UNTRUSTED_RID         = $00000000 ; Untrusted. 
#SECURITY_MANDATORY_LOW_RID               = $00001000 ; Low integrity. 
#SECURITY_MANDATORY_MEDIUM_RID            = $00002000 ; Medium integrity. 
#SECURITY_MANDATORY_SYSTEM_RID            = $00004000 ; System integrity. 
#SECURITY_MANDATORY_PROTECTED_PROCESS_RID = $00005000 ; Protected process. 


; ---------------------------------------------------------------------------
;- Types
Enumeration ; TOKEN_INFORMATION_CLASS
  #TokenUser = 1
  #TokenGroups
  #TokenPrivileges
  #TokenOwner
  #TokenPrimaryGroup
  #TokenDefaultDacl
  #TokenSource
  #TokenType
  #TokenImpersonationLevel
  #TokenStatistics
  #TokenRestrictedSids
  #TokenSessionId
  #TokenGroupsAndPrivileges
  #TokenSessionReference
  #TokenSandBoxInert
  #TokenAuditPolicy
  #TokenOrigin
  #TokenElevationType
  #TokenLinkedToken
  #TokenElevation
  #TokenHasRestrictions
  #TokenAccessInformation
  #TokenVirtualizationAllowed
  #TokenVirtualizationEnabled
  #TokenIntegrityLevel
  #TokenUIAccess
  #TokenMandatoryPolicy
  #TokenLogonSid
  #MaxTokenInfoClass
EndEnumeration

Structure TOKEN_MANDATORY_LABEL
  Label.SID_AND_ATTRIBUTES
EndStructure

; ---------------------------------------------------------------------------
;- Prototypes

Declare.b Load_advapi32()
CompilerIf #SIZE_MATTERS
  Declare.b Unload_advapi32()
CompilerElse
  Macro Unload_advapi32()
    ; Do nothing!
  EndMacro
CompilerEndIf

Prototype.b protoLookupAccountSid(*lpSystemName.s, *lpSid.i, *lpName.s, *cchName.l, *lpReferencedDomainName.s, *cchReferencedDomainName.l, *peUse.i)
Prototype.b protoLookupPrivilegeValue(lpSystemName.s, lpName.s, *lpLuid.LUID)
Prototype.b protoOpenProcessToken(*ProcessHandle.i, DesiredAccess.l, *TokenHandle.i)
Prototype.b protoAdjustTokenPrivileges(*TokenHandle.i, DisableAllPrivileges.b, *NewState.TOKEN_PRIVILEGES, BufferLength.l, *PreviousState.TOKEN_PRIVILEGES, *ReturnLength.l)
Prototype.b protoGetTokenInformation(*TokenHandle.i, TokenInformationClass.i, *TokenInformation, TokenInformationLength.l, *ReturnLength.l)
Prototype.i protoGetSidSubAuthority(*pSid.i, nSubAuthority.l) ; returns a pointer to a DWORD (--> PDWORD)
Prototype.i protoGetSidSubAuthorityCount(*pSid.i) ; returns a pointer to a UCHAR (--> PUCHAR)

; Registry
Prototype.l protoRegOpenKeyEx(hKey.i, *lpSubKey.s, ulOptions.l, samDesired.i, *phkResult.i)
Prototype.l protoRegCloseKey(hKey.i)
Prototype.l protoRegSetValueEx(hKey.i, *lpValueName.s, Reserved.l, dwType.l, *lpData.i, cbData.l)


; ---------------------------------------------------------------------------
;- Variables

Global advapi32.i = 0
Global advapi32Sizer.i = 0

Global LookupAccountSid.protoLookupAccountSid = 0
Global LookupPrivilegeValue.protoLookupPrivilegeValue = 0
Global OpenProcessToken.protoOpenProcessToken = 0
Global AdjustTokenPrivileges.protoAdjustTokenPrivileges = 0
Global GetTokenInformation.protoGetTokenInformation = 0
Global GetSidSubAuthority.protoGetSidSubAuthority = 0
Global GetSidSubAuthorityCount.protoGetSidSubAuthorityCount = 0

Global RegOpenKeyEx.protoRegOpenKeyEx = 0
Global RegCloseKey.protoRegCloseKey = 0
Global RegSetValueEx.protoRegSetValueEx = 0



; ---------------------------------------------------------------------------
;- Procedures

Procedure.b Load_advapi32()
  CompilerIf #SIZE_MATTERS
    If advapi32Sizer > 0
      advapi32Sizer = advapi32Sizer + 1
      ProcedureReturn #True
    EndIf
  CompilerElse
    If advapi32
      ProcedureReturn #True
    EndIf
  CompilerEndIf
  
  advapi32 = OpenLibrary(#PB_Any, "advapi32.dll")
  If Not advapi32
    advapi32 = 0
    ProcedureReturn #False
  EndIf
  
  LookupAccountSid = GetFunction(advapi32, "LookupAccountSidA")
  LookupPrivilegeValue = GetFunction(advapi32, "LookupPrivilegeValueA")
  OpenProcessToken = GetFunction(advapi32, "OpenProcessToken")
  AdjustTokenPrivileges = GetFunction(advapi32, "AdjustTokenPrivileges")
  GetTokenInformation = GetFunction(advapi32, "GetTokenInformation")
  GetSidSubAuthority = GetFunction(advapi32, "GetSidSubAuthority")
  GetSidSubAuthorityCount = GetFunction(advapi32, "GetSidSubAuthorityCount")
  
  RegOpenKeyEx = GetFunction(advapi32, "RegOpenKeyExA")
  RegCloseKey = GetFunction(advapi32, "RegCloseKey")
  RegSetValueEx = GetFunction(advapi32, "RegSetValueExA")
  
  If Not (LookupPrivilegeValue And OpenProcessToken And AdjustTokenPrivileges And GetTokenInformation And GetSidSubAuthority And GetSidSubAuthorityCount And RegOpenKeyEx And RegCloseKey And RegSetValueEx)
    Unload_advapi32()
    ProcedureReturn #False
  EndIf
  
  advapi32Sizer = 1
  ProcedureReturn #True
EndProcedure

CompilerIf #SIZE_MATTERS
  Procedure.b Unload_advapi32()
    advapi32Sizer = advapi32Sizer - 1
    
    If advapi32Sizer > 0
      ProcedureReturn #False
    EndIf
    
    If advapi32 <> 0
      CloseLibrary(advapi32)
    EndIf
    
    advapi32 = 0
    advapi32Sizer = 0
    
    ProcedureReturn #True
  EndProcedure
CompilerEndIf

; ---------------------------------------------------------------------------

; IDE Options = PureBasic 4.61 Beta 1 (Windows - x64)
; CursorPosition = 115
; FirstLine = 92
; Folding = -
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant