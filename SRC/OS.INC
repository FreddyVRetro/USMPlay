;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?       ?????????????? OS.INC ??????????????        ?
;            ?                                                   ?
;            ?                 OS dependant part                 ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   by Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code starts .................. 22/08/1996       ?
;            ?   Last Update .................. 26/11/1997       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?
; This file should be included at the start of each ASM file
; It contains DOS extender dependant code.

_OS_ EQU 0

USMP_Version EQU <'1.1'>

; Availables DOS Extenders list:

DOS32      EQU 1   ; DOS32 DOS Extender
EOS        EQU 2   ; EOS DOS Extender
EOS3       EQU 3   ; EOS v3.00? or above.
PMODEW_ASM EQU 4   ; PMODE/W DOS Extender (100% ASM code)
PMODEW_C   EQU 5   ; PMODE/W DOS Extender unther WATCOM C
DOS4GW_ASM EQU 6   ; DOS4G/W DOS Extender (100% ASM code) (Don't work by now)
DOS4GW_C   EQU 7   ; DOS4G/W DOS Extender unther WATCOM C (Don't work by now)
DJGPP      EQU 8   ; DJGPP                     (Not supported by now)
PMODE      EQU 9   ; PMODE v3.07               (Not supported by now)
KERNEL     EQU 10  ; Technomancer's Kernel 386 (Not supported by now)

; DOS Extender selection

ifdef UseDOS32
OS EQU DOS32      ; DOS32 DOS Extender
endif
ifdef UseEOS
OS EQU EOS        ; EOS DOS Extender
endif
ifdef UseEOS3
OS EQU EOS3       ; EOS v3.00? or above.
endif
ifdef UsePMODEW_ASM
OS EQU PMODEW_ASM ; PMODE/W DOS Extender (100% ASM code)
endif
ifdef UsePMODEW_C
OS EQU PMODEW_C   ; PMODE/W DOS Extender unther WATCOM C
endif
ifdef UseDOS4GW_ASM
OS EQU DOS4GW_ASM ; DOS4G/W DOS Extender (100% ASM code) (Don't work by now)
endif
ifdef UseDOS4GW_C
OS EQU DOS4GW_C   ; DOS4G/W DOS Extender unther WATCOM C (Don't work by now)
endif
ifdef UseDJGPP
OS EQU DJGPP      ; DJGPP                     (Not supported by now)
endif
ifdef UsePMODE
OS EQU PMODE      ; PMODE v3.07               (Not supported by now)
endif
ifdef UseKERNEL
OS EQU KERNEL     ; Technomancer's Kernel 386
endif

; DPMI 0.9 compliant extenders
_DPMI   EQU ((OS eq EOS) or (OS eq DOS32) or (OS eq KERNEL)) eq 0
; WATCOM C
_WATCOM EQU ((OS Eq DOS4GW_C) or (OS Eq PMODEW_C))

; ****************************************************
; *  Here are the OS specific macros and definitions *
; ****************************************************

;                       ** DOS32 DEFINITIONS **

if OS eq DOS32
;EXTRN Debug :Near              ; Define external symbol

DOSStrEnd EQU 36

Cls MACRO       ; Clear the screen (Text Mode)
	mov ax,3
	int 10h
ENDM

writeDOS MACRO
        mov ah,9
        int 21h
ENDM

Waitkey MACRO   ; Wait for a key
	xor eax,eax
	int 16h
ENDM    

Stop MACRO      ; Return to DOS
	mov ax,4c00h
	int 21h
ENDM

endif

;                       ** EOS DEFINITIONS **

If ((OS eq EOS) or (OS eq EOS3))
INCLUDE EOS.INC

DOSStrEnd EQU 36

Cls MACRO       ; Clear the screen (Text Mode)
	mov ax,3
	Dosint 10h
ENDM

writeDOS MACRO
        mov ah,9
        int 21h
ENDM

Waitkey MACRO   ; Wait for a key
	xor eax,eax
	Dosint 16h
ENDM    

Stop MACRO      ; Return to DOS
	mov ax,4c00h
	int 21h
ENDM

endif

;                       ** DJGPP DEFINITIONS **

If OS Eq DJGPP
.MODEL FLAT,C

extrn getch:proc

DOSStrEnd EQU 36

Cls MACRO       ; Clear the screen (Text Mode)
	mov ax,3
	int 10h
ENDM

writeDOS MACRO
        mov ah,9
        int 21h
ENDM

Waitkey MACRO   ; Wait for a key
	call getch
ENDM    

Stop MACRO      ; Return to DOS
	mov ax,4c00h
	int 21h
ENDM

endif

;               ** PMODE/W AND DOS4G/W DEFINITIONS **

if (OS Eq PMODEW_ASM) or (OS Eq DOS4GW_ASM)
.model flat

DOSStrEnd EQU 36

Cls MACRO       ; Clear the screen (Text Mode)
	mov ax,3
	int 10h
ENDM

writeDOS MACRO
        mov ah,9
        int 21h
ENDM

Waitkey MACRO   ; Wait for a key
	xor eax,eax
	int 16h
ENDM    

Stop MACRO      ; Return to DOS
	mov ax,4c00h
	int 21h
ENDM

endif

;               ** PMODE/W AND DOS4G/W WITH WATCOM C **

if (OS Eq PMODEW_C) or (OS Eq DOS4GW_C)
.model flat,syscall

DOSStrEnd EQU 36

Cls MACRO       ; Clear the screen (Text Mode)
	mov ax,3
	int 10h
ENDM

writeDOS MACRO
        mov ah,9
        int 21h
ENDM

Waitkey MACRO   ; Wait for a key
	xor eax,eax
	int 16h
ENDM    

Stop MACRO      ; Return to DOS
	mov ax,4c00h
	int 21h
ENDM

endif

;                            ** KERNEL **

if (OS Eq KERNEL)

; Kernel 386 functions definition
INCLUDE COMMON.DEF
INCLUDE KRNL386.INC

DOSStrEnd EQU 0

Cls MACRO       ; Clear the screen (Text Mode)
        call KlearTextScreen
ENDM

writeDOS MACRO
        push esi
        mov esi,edx
        call DisplayNullString
        pop esi
ENDM

Waitkey MACRO   ; Wait for a key
	call KBD_Get
ENDM    

Stop MACRO      ; Return to DOS
	jmp BackToReality
ENDM

endif
