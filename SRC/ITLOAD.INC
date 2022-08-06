;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ ITLOAD.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ            Useless IT Loader (IT->USM)            บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 01/05/1997       บ
;            บ   Last Update .................. 25/01/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Global IT_Load   :Near

IT_MAX_Channels EQU 64
ITHeaderLen EQU ITChVol+IT_MAX_Channels

ITHeader Struc
	 ITId       DD 0                ; 'IMPM'
	 ITName     DB 26 DUP (0)       ; Song name, 26 char
         ITFill1    DW 0
         ITOrdNum   DW 0                ; Song Length
         ITInsNum   DW 0                ; Number of Instruments
         ITSmpNum   DW 0                ; Number of samples
         ITPatNum   DW 0                ; Number of patterns
         ITCwt      DW 0                ; Create with tracker
         ITCmwt     DW 0                ; Compatibility version number
         ITFlags    DW 0                ; Song flags
         ITSpecial  DW 0
         ITGV       DB 0                ; Global volume (0-128)
         ITMV       DB 0                ; Mix volume (0-128)
         ITIS       DB 0                ; Initial Speed
         ITIT       DB 0                ; Initial tempo
         ITSep      DB 0                ; Panning separation
         ITFill2    DB 0
         ITMsgLgth  DW 0                ; Song message length
         ITMsfOffs  DD 0                ; Song message file offset
         ITFill3    DD 0
         ITChPan    DB IT_MAX_Channels DUP (0)
         ITChVol    DB IT_MAX_Channels DUP (0)
         ITOrder    DB 0                ; Song Order (Size=ITOrdNum)
ITHeader Ends

; File Flags
ITF_Stereo    EQU 1     ;Stereo/Mono Mode.
ITF_Vol0Optim EQU 2     ;Volume 0 Optimisation.
ITF_InstrMode EQU 4     ;Instrument/Sample Mode.
ITF_Linear    EQU 8     ;Linear Slides (By now, converted to Linear XM Mode).
ITF_OldEfx    EQU 16    ;"Old" or IT Effects.
ITF_GxComp    EQU 32    ;Gx Effect compatibility mode

ITInstrumentSize EQU 554

ITInstrument1 Struc
        ITI1Id      DD 0
        ITI1DosName DB 12 DUP (0)
        ITI100h     DB 0
        ITI1NNA     DB 0
        ITI1DCT     DB 0
        ITI1DCA     DB 0
        ITI1FadeOut DW 0
        ITI1PPS     DB 0
        ITI1PPC     DB 0
        ITI1GbV     DB 0
        ITI1DfP     DB 0
        ITI1RV      DB 0
        ITI1RP      DB 0
        ITI1TrkVer  DW 0
        ITI1NoS     DB 0
        ITI1byte1   DB 0
        ITI1Name    DB 26 DUP (0)
        ITI1Word    DW 0
        ITI1MCh     DB 0
        ITI1MPr     DB 0
        ITI1MIDIBnk DW 0
        ITI1NoteTbl DB 240 DUP (0)

        ITI1VlEnvFlg DB 0        
        ITI1VlEnvNum DB 0
        ITI1VlEnvLpB DB 0
        ITI1VlEnvLpE DB 0
        ITI1VlEnvSLB DB 0
        ITI1VlEnvSLE DB 0
        ITI1VlEnvPts DB 75 DUP (0)
        ITI1VlEnvxxx DB 0        

        ITI1PnEnvFlg DB 0
        ITI1PnEnvNum DB 0
        ITI1PnEnvLpB DB 0
        ITI1PnEnvLpE DB 0
        ITI1PnEnvSLB DB 0
        ITI1PnEnvSLE DB 0
        ITI1PnEnvPts DB 75 DUP (0)
        ITI1PnEnvxxx DB 0        

        ITI1PtEnvFlg DB 0
        ITI1PtEnvNum DB 0
        ITI1PtEnvLpB DB 0
        ITI1PtEnvLpE DB 0
        ITI1PtEnvSLB DB 0
        ITI1PtEnvSLE DB 0
        ITI1PtEnvPts DB 75 DUP (0)
        ITI1PtEnvxxx DB 0
ITInstrument1 Ends

ITInstrument2 Struc
        ITI2Id       DD 0
        ITI2DosName  DB 12 DUP (0)
        ITI200h      DB 0
        ITI2Flag     DB 0
        ITI2VLS      DB 0
        ITI2VLE      DB 0
        ITI2SLS      DB 0
        ITI2SLE      DB 0
        ITI2Word     DW 0
        ITI2FadeOut  DW 0
        ITI2NNA      DB 0
        ITI2DNC      DB 0
        ITI2TrkVer   DW 0
        ITI2NoS      DB 0
        ITI2byte1    DB 0
        ITI2Name     DB 26 DUP (0)
        ITI2Fill6    DB 6 DUP (0)
        ITI2NoteTbl  DB 240 DUP (0)
        ITI2VlEnv    DB 200 DUP (0)
        ITI2VlEnvPts DB 50 DUP (0)
ITInstrument2 Ends

ITSampleSize EQU ITSVibType+1

ITSample Struc
        ITSId       DD 0         ; 'IMPS'
        ITSDosName  DB 12 DUP (0); DOS Filename
        ITSFill1    DB 0         ; =0
        ITSGvl      DB 0         ; Sample Volume
        ITSFlg      DB 0         ; Sample flags
        ITSVol      DB 0         ; Sample default volume
        ITSName     DB 26 DUP (0); Sample Name
        ITSConv     DB 0
        ITSDefPan   DB 0

        ITSLength   DD 0
        ITSLoop     DD 0
        ITSLoopEnd  DD 0
        ITSFine     DD 0
        ITSSustain  DD 0
        ITSSustEnd  DD 0

        ITSPointer  DD 0
        
        ITSVibSpeed DB 0
        ITSVibDepth DB 0
        ITSVibRate  DB 0
        ITSVibType  DB 0
ITSample Ends

ITSM_Loaded   EQU 1
ITSM_16Bit    EQU 2
ITSM_Stereo   EQU 4
ITSM_Packed   EQU 8
ITSM_Loop     EQU 16
ITSM_Sustain  EQU 32
ITSM_BLoop    EQU 64
ITSM_BSustain EQU 128

ITSF_Signed EQU 1