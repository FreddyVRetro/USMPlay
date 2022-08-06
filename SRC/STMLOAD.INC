;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ STMLOAD.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ           Useless STM Loader (STM->USM)           บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 19/08/1996       บ
;            บ   Last Update .................. 20/04/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Global STM_Load   :Near

STMHeaderSize EQU STMFill2+13

STMHeader Struc
          STMName      DB 20 DUP (0) 
	  STMIdent     DB 8  DUP (0) ; Tracker Name ('!SCREAM!', for example)
          STMFill1     DB 0
	  STMFileType  DB 0          ; 1=song, 2=module 
          STMVer_major DB 0
	  STMVer_minor DB 0
	  STMTempo     DB 0
	  STMPatterns  DB 0
	  STMVolume    DB 0
	  STMFill2     DB 13 DUP (0) ; Reserved data
STMHeader Ends

STMSampleSize EQU STMSFill3+6

STMSample Struc
	STMSName      DB 14 DUP (0)
        STMSFill1     DW 0         ; Reserved word
	STMSLength    DW 0         ; Sample Length 
	STMSLoop      DW 0         ; Loop Start
	STMSLoopEnd   DW 0         ; Loop end
        STMSVolume    DB 0         ; Sample volume 
	STMSFill2     DB 0         ; Reserved byte
	STMSFine      DW 0         ; C4 Freq
        STMSFill3     DB 6 DUP (0) ; More reserved data
STMSample EndS		

; STMLOAD.INC (c) 1997 FreddyV/Useless