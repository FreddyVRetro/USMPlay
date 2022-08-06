;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ UTILS.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗       บ
;            บ                                                   บ
;            บ              Useless misc routines                บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 03/04/1996       บ
;            บ   Last Update .................. 27/06/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

ifndef _OS_
display 'OS.INC must be included before UTILS.INC'
Endif

Global Text80x25 :Near
Global Text80x50 :Near
Global GotoXY    :Near

Global _dprint_char :Near
Global _dprint_str  :Near
Global _dprint_dec  :Near
Global _dprint_hex  :Near

if (OS Eq KERNEL)
print_str Equ _dprint_str
print_dec Equ _dprint_dec
print_hex Equ _dprint_hex
else
Global print_str  :Near
Global print_dec  :Near
Global print_hex  :Near
endif

HideCursor MACRO
if  (OS EQ KERNEL)
                
else
        mov ah,02h      ; Function number 2
        mov bh,0        ; Screen page number
        mov ch,26       ; Row
        mov dl,0        ; column
        int 10h
endif
ENDM

showborder = 0           ; 'Raster' pour le %machine  Ooops, french ;-)
setborder MACRO no
      if showborder
      PUSH dx ax
      MOV  dx,03dah
      IN   al,dx
      MOV  dx,03c0h
      MOV  al,31h
      OUT  dx,al
      MOV  al,no
      OUT  dx,al
      POP  ax dx
      endif
ENDM


if (OS EQ DJGPP)                ;* DJGPP *

extrn printf:proc

write MACRO STRING_
LOCAL TEXT5_T , skip_wrln
        push  eax
        push  edx
        jmp skip_wrln

        IFB <STRING_>
TEXT5_T DB 0
        ELSE
TEXT5_T DB STRING_,0
        ENDIF
skip_wrln:

        push OFFSET TEXT5_T
        call printf
        add  sp,4

        pop edx
        pop eax
ENDM

writeln MACRO STRING_
LOCAL TEXT3_S
local skip_wrln
        push eax
        push edx

        jmp skip_wrln

        IFB <STRING_>
TEXT3_S DB 13,10,0
        ELSE
TEXT3_S DB STRING_,13,10,0
        ENDIF
skip_wrln:

        push offset TEXT3_S
        call printf
        add  sp,4
	
        pop edx
        pop eax
ENDM

elseif (OS Eq KERNEL)           ; * KERNEL *

dwritech MACRO Char
	 push eax
	 mov al,Char
	 call DisplayChar       ; Call to the KERNEL DisplayChar function
	 pop eax
EndM

dwrite MACRO STRING_
LOCAL TEXT_T , skip_dwr
        jmp skip_dwr

        IFB <STRING_>
TEXT_T DB 0
        ELSE
TEXT_T DB STRING_,0
        ENDIF
skip_dwr:
	push esi
        mov esi,OFFSET TEXT_T
	call DisplayNullString
	pop esi
ENDM

write MACRO STRING_
LOCAL TEXT_T , skip_wr
        jmp skip_wr

        IFB <STRING_>
TEXT_T DB 0
        ELSE
TEXT_T DB STRING_,0
        ENDIF
skip_wr:
        push esi
        mov esi,OFFSET TEXT_T
        call DisplayNullString
        pop esi
ENDM

writeln MACRO STRING_
LOCAL TEXT_T , skip_wrln

        jmp skip_wrln

        IFB <STRING_>
TEXT_T DB 0
        ELSE
TEXT_T DB STRING_,0
        ENDIF
skip_wrln:
        push edi
        mov esi,OFFSET TEXT_T
        call DisplayNullString
        call NextLine
        call DisplayCursor
        pop esi
ENDM

else                            ; * DOS32, EOS, PMODE/W ... *

dwritech MACRO Char
	 push edx
	 mov dl,Char
	 call _dprint_char
	 pop edx
EndM

dwrite MACRO STRING_
LOCAL TEXT_T , skip_dwr
        jmp skip_dwr

        IFB <STRING_>
TEXT_T DB 0
        ELSE
TEXT_T DB STRING_,0
        ENDIF
skip_dwr:

	push ecx
	push esi
        mov esi,OFFSET TEXT_T
	mov ecx,40
	call _dprint_str
	pop esi
	pop ecx
ENDM

write MACRO STRING_
LOCAL TEXT5_T , skip_wrln
        push  eax
        push  edx
        jmp skip_wrln

        IFB <STRING_>
TEXT5_T DB 36
        ELSE
TEXT5_T DB STRING_,36
        ENDIF
skip_wrln:

        MOV EDX,OFFSET TEXT5_T
        mov ah,9
        int 21h
        pop edx
        pop eax
ENDM

writeln MACRO STRING_
LOCAL TEXT3_S
local skip_wrln
        push eax
        push edx

        jmp skip_wrln

        IFB <STRING_>
TEXT3_S DB 13,10,36
        ELSE
TEXT3_S DB STRING_,13,10,36
        ENDIF
skip_wrln:
        mov EDX,offset TEXT3_S
        mov ah,9
        Int 21h
        pop edx
        pop eax
ENDM

Endif

; UTILS.INC (c) 1997 FreddyV/Useless