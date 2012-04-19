; ***************************************************************************
; *                                                                         *
; * Author:      marpie (marpie+toolkit@a12d404.net)                        *
; * License:     BSD License                                                *
; * Copyright:   (c) 2012, a12d404.net                                      *
; * Status:      Prototype                                                  *
; *                                                                         *
; ***************************************************************************
EnableExplicit

XIncludeFile("tests/helper.pbi")
XIncludeFile("core/msg_format.pbi")

; ---------------------------------------------------------------------------

#TEST_COMMAND = 11

Global testData.s = "Hello World!"
Global testDataBig.s = "Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World!"

Define *pPack1.MSG_PACK
Define *pPack2.MSG_PACK

PrintN(#CRLF$ + "tests_msg_format.pbi")
PrintN(         "---------------")

*pPack1 = MsgEncode(#MSG_VERSION_1, #TEST_COMMAND, #Null, 0)
Test("MsgEncode (without Payload)", ((Not *pPack1 = #Null) And (Not *pPack1\pData = #Null)))
*pPack1 = MsgFreePack(*pPack1)

*pPack1 = MsgEncode(#MSG_VERSION_1, #TEST_COMMAND, @testDataBig, Len(testDataBig))
Test("MsgEncode", ((Not *pPack1 = #Null) And (Not *pPack1\pData = #Null)))
Test("MsgEncode (is Encrypted)", (Not CompareMemory(*pPack1\pData + SizeOf(MSG_HEADER), @testDataBig, *pPack1\header\dataSize)))
*pPack1 = MsgFreePack(*pPack1)

*pPack1 = MsgEncode(#MSG_VERSION_1, #TEST_COMMAND, @testDataBig, Len(testDataBig))
Test("MsgEncode 2", (Not *pPack1 = #Null))

*pPack2 = MsgDecode(*pPack1\pData, *pPack1\dataSize)
Test("MsgDecode", (Not *pPack2 = #Null))
*pPack1 = MsgFreePack(*pPack1)
Test("MsgDecode (is OK)", (CompareMemory(*pPack2\pData, @testDataBig, *pPack2\header\dataSize)))
*pPack2 = MsgFreePack(*pPack2)

Test("MsgFreePack", ((Not *pPack1 <> #Null) And (Not *pPack2 <> #Null)))

; IDE Options = PureBasic 4.50 Beta 3 (Windows - x64)
; CursorPosition = 46
; FirstLine = 4
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant