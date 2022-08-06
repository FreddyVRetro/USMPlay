;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ S3MLOAD.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ           Useless S3M Loader (S3M->USM)           บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 22/07/1997       บ
;            บ   Last Update .................. 22/07/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Global S3M_Load   :Near

S3M_MAX_Channels EQU 32

S3MHeaderLen EQU S3MOrder

S3MHeader Struc
	 S3MName     DB 28 DUP (0)       ; Song name, 26 char
         S3M1A       DB 0                ; 1Ah
         S3MType     DB 0                ; File Type: 16=ST3 module
         S3MWFill    DW 0                ; Unused
         S3MOrdNum   DW 0                ; Song Length
         S3MSmpNum   DW 0                ; Number of samples
         S3MPatNum   DW 0                ; Number of patterns
         S3MFlags    DW 0                ; Song flags
         S3MCwt      DW 0                ; Create with tracker
         S3MVer      DW 0                ; Version number
	 S3MId       DD 0                ; 'SCRM'
         S3MGV       DB 0                ; Global volume (0-64)
         S3MIS       DB 0                ; Initial Speed
         S3MIT       DB 0                ; Initial tempo
         S3MMV       DB 0                ; Master Volume
         S3MUltraclk DB 0                ; Ultrackick removal info (unused)
         S3MPantable DB 0                ; Panning table included if = 0FCh
         S3MFill     DB 8 DUP (0)
         S3MSpecial  DW 0                ; Pointer to special custom data
         S3MChannels DB 32 DUP (0)       ; Channels settings
         S3MOrder    DB 0                ; Song Order (Size=S3MOrdNum)
S3MHeader Ends

; File Flags
S3MF_ST2Vibrato EQU 1
S3MF_ST2Tempo   EQU 2
S3MF_Vol0Optim  EQU 8    ;Volume 0 Optimisation.
S3MF_AmigaLim   EQU 16   ;
S3MF_Filter     EQU 32
S3MF_FastVS     EQU 64   ;Fast Volume slide


S3MSampleSize EQU S3MSId+4

S3MSample Struc
        S3MSType     DB 0          ; Sample/Adlib
        S3MSDosName  DB 12 DUP (0) ; DOS Filename
        S3MSZero     DB 0
        S3MSPointer  DW 0

        S3MSLength   DD 0
        S3MSLoop     DD 0
        S3MSLoopEnd  DD 0
        S3MSVol      DB 0          ; Sample default volume
        S3MSFill     DB 0
        S3MSPack     DB 0          ; Not used
        S3MSFlg      DB 0

        S3MSFine     DD 0          ; Fine (Only 16 bit used)
        S3MSFill2    DB 12 DUP (0)

        S3MSName     DB 28 DUP (0) ; Sample Name
        S3MSId       DD 0          ; 'SCRS'
S3MSample Ends

S3MSM_Loop     EQU 1
S3MSM_Stereo   EQU 2
S3MSM_16Bit    EQU 4