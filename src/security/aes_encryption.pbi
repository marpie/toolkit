#ENABLE_ENCRYPTION = #True

; Should be a 32 bytes Array for AES 256
DataSection
EncryptionKey:
  Data.b "jY_0 gklnUHpoCaT0yQ-vRdPdyvvqzJ"

EncryptionInitializationVector:
  Data.b "JX5QvA6iRxbld A _LKYil Z9gn-P_j"
EndDataSection

Global encryptionKeyLen = (?EncryptionInitializationVector-?EncryptionKey)
Global encryptionBitLen = encryptionKeyLen*8
Global encryptionActive = #ENABLE_ENCRYPTION And ((encryptionKeyLen = 16) Or (encryptionKeyLen = 24) Or (encryptionKeyLen = 32))

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 2
; EnableXP
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant