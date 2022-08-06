;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ MODLOAD.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ           Useless MOD Loader (MOD->USM)           บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   Auteur๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚ Freddy Vtel    บ
;            บ                                                   บ
;            บ   Dbut d'criture๚๚๚๚๚๚๚๚๚๚๚๚๚๚ 19/08/1996       บ
;            บ   Dernire modification๚๚๚๚๚๚๚๚๚ 20/04/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Global MOD_Load   :Near

MODSampleSize EQU MODSLoopLen+2

MODSample Struc
	MODSName      DB 22 DUP (?)
	MODSLength    DW ?
	MODSFine      DB ?
	MODSVolume    DB ?
	MODSLoop      DW ?
	MODSLoopLen   DW ?
MODSample EndS		

; MODLOAD.INC (c) 1997 FreddyV/Useless