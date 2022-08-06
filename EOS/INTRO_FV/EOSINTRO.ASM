;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ    ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ EOSINTRO.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ           USM Play 'Intro' example                บ
;            บ                  (Using EOS)                      บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   by Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 26/10/1996       บ
;            บ   Last update .................. 13/10/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
; Warning: You must change the path to EOS files in makefile file.
;             This example show you how to use usm play in intros.
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE USMPLAY.INC   ; USM player
INCLUDE USS.INC       ; Useless Sound System
INCLUDE USSVAR.INC    ; DEV_Name definition

INCLUDE HARDWARE.INC
INCLUDE UTILS.INC     ; Display macros (write, writeln)
                      ; There is no need for utils.asm with write and writeln.

;=============================================================================

USMOffset DD 0

StartMSG DB 'Internal USM files example.',13,10,36
KeyMsg   DB 'Press any key to stop.',13,10,36

Music:  ; The music is in the EXE file ! :-)
INCLUDE CHIPBLUE.INC


;=============================================================================

Start32:

; ** USMPLAY Init

        call HardwareInit

; ** Player Start

        mov edx,Offset StartMSG
        mov ah,9
        int 21h

; ** Sound system Setup **

	call USS_AutoSetup	
        jc _PEnd

        write 'Device: '

        mov edx,_DEV_Name
        mov ah,9
        int 21h

        writeln

; ** "Load" the file **
; ** ! Warning: Do this only one time.

	mov esi,Offset Music
	call USMP_LoadInternalModule

; ** Start the output **

        call USMP_StartPlay
        jc _PEnd
	
        mov edx,Offset KeyMsg
        mov ah,9
        int 21h

        xor eax,eax
        DosInt 16h	

; ** Stop the output **

        call USMP_StopPlay

; You can use USMP_FreeInternalModule if you want to play more than 1 module.
; but it will increase your code size a little...
; Don't forget to set UseFreeInternalModule to Yes in SETUP.INC

;       mov esi,Offset Music
;       call USMP_FreeInternalModule


_PEnd:
        mov   ax,4C00h
        int   21h

CODE32 ENDS
;=============================================================================
END
; EX1.ASM (c) 1997 FreddyV/Useless
