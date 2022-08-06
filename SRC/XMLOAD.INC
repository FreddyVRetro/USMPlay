;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ XMLOAD.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ            Useless XM Loader (XM->USM)            บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 06/04/1996       บ
;            บ   Last Update .................. 17/05/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ


;if _WATCOM
;Global XM_Load_  :Near
;else
Global XM_Load   :Near
;endif

XM_MAX_Channels EQU 32

XMHeaderLen EQU XMOrder+256

XMHeader Struc
         XMId       DB 17 DUP (0)
         XMName     DB 20 DUP (0)
         XMbyte     DB 0
         XMTracker  DB 20 DUP (0)
         XMVersion  DW 0
         XMHSize    DD 0
         XMSongLen  DW 0
         XMRestart  DW 0
         XMChannels DW 0
         XMPatterns DW 0
         XMInstr    DW 0
         XMFlags    DW 0
         XMTempo    DW 0
         XMBPM      DW 0
         XMOrder    DB 256 DUP (0)
XMHeader ENDS	

XMInstrumentSize EQU XMIReserved+2

XMInstrument Struc
        XMISSize      DD 0
        XMISNumber    DB 96 DUP (0)
        XMIVEnvelope  DW 24 DUP (0)
        XMIPEnvelope  DW 24 DUP (0)
        XMIVPoints    DB 0
        XMIPPoints    DB 0
        XMIVSustain   DB 0
        XMIVLoopStart DB 0
        XMIVLoopEnd   DB 0
        XMIPSustain   DB 0
        XMIPLoopStart DB 0
        XMIPLoopEnd   DB 0
        XMIVType      DB 0
        XMIPType      DB 0
        XMIVibType    DB 0
        XMIVibSweep   DB 0
        XMIVibdepth   DB 0
        XMIVibrate    DB 0
        XMIVFadeout   DW 0
        XMIReserved   DW 0
XMInstrument EndS
