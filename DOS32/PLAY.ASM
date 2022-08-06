;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ UPMP.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗       บ
;            บ                                                   บ
;            บ                    USM Play                       บ
;            บ                 (DOS32 Example)                   บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 13/03/1996       บ
;            บ   Last Update .................. 31/08/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
.MODEL FLAT
INCLUDE OS.INC

.STACK 1000h


INCLUDE ERR_CODE.INC

INCLUDE XMLOAD.INC
INCLUDE USMPLAY.INC
INCLUDE USS.INC
INCLUDE USSVAR.INC

INCLUDE HARDWARE.INC

INCLUDE MEMORY.INC
INCLUDE UTILS.INC

;=============================================================================
.data

Module DB '..\DATA\EFFECT.XM',0

USMOFFSET dd 0

StartMsg DB 'USM Play v',USMP_Version,' (DOS32 example).',13,10,DosStrEnd

;=============================================================================

.code

Start:
; "Hardware" Init       
	call HardwareInit

; ** Sound system Setup
	
        call USS_Setup
        jc _PEnd
 
; ** Player Start
 
        mov edx,offset StartMsg
        writeDOS

        U_Maxavail
	
        Write 'Free memory: '
        shr eax,10
        call Print_dec
        Writeln 'Kb'

        write 'Device: '

        mov edx,_DEV_Name
        WriteDOS

        writeln

        mov eax,20202020h
        mov ebx,LM_File
        mov esi,offset Module
        call XM_Load
        jc _PError

        mov USMOffset,esi

        call USMP_StartPlay

        Write 'A key to stop.'
        Waitkey

        call USMP_StopPlay

        mov esi,USMOffset
        call USMP_FreeModule

        jmp _PEnd
_PError:
        call Display_Error_

_PEnd:
        Stop

end  START