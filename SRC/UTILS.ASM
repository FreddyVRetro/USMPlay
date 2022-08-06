;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ UTILS.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗       บ
;            บ                                                   บ
;            บ              Useless misc routines                บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 03/04/1996       บ
;            บ   Last update .................. 21/06/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE UTILS.INC

;=============================================================================
dec_divider dd 1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000
firstone    db 0

digit   dd 0

Screen_Offset  DD 0
Current_Offset DD 0

ScreenSize DD 4000

;=============================================================================

Text80x25 Proc
        mov ScreenSize,4000
        mov ax,2
        int 10h
        ret
Text80x25 Endp

Text80x50 Proc
        mov ScreenSize,8000
        mov ax,2
        int 10h                 ; 80x25 Text Mode
        mov ax,1112h
        mov bl,0
        int 10h
        ret
Text80x50 Endp

GotoXY Proc
        pushad
        movzx eax,al        
        mov ecx,eax        
        shl ecx,1
        mov al,80*2
        mul bl
        add eax,ecx
        mov Current_Offset,eax
        popad        
        ret
GotoXY Endp

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  print_str: prints a null terminated string (starts at @ESI )            ณ
;ณ                                                                          ณ
;ณ   input: ESI, string start ECX, Max string length                        ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if Not (OS EQ KERNEL)
Print_Str PROC
if (OS EQ DJGPP)
display 'Erreur, pas d''affichage de caractere possible ????'
EndIf
	pushad
Print_Strloop:
	mov dl,[esi]
	inc esi
	cmp dl,0
	je Print_strend

	mov ah,2
	int 21h                 ; send character to screen
	
	dec ecx
	jnz Print_strloop
Print_StrEnd:
	popad
	ret
Print_Str ENDP
endif

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  print_dec: prints the Decimal value of EAX                              ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if Not (OS EQ KERNEL)
Print_Dec PROC
	pushad
	mov firstone,0
	mov esi,9
	mov ecx,eax
Print_Decloop:
	cmp esi,-1
	je Print_DecEnd
	mov eax,ecx
	xor edx,edx
	div dec_divider[esi*4]
	dec esi
	mov ecx,edx             ; reuse remainder       

	or firstone,al
	cmp firstone,0
	je Print_Decloop

	add al,'0'              ; use quotient as digit number
	mov dl,al

	mov ah,2
	int 21h                 ; send character to screen
	
	jmp Print_Decloop
Print_DecEnd:
	cmp firstone,0
	jne Print_DecEnd2
	mov dl,'0'

	mov ah,2
	int 21h
	
Print_DecEnd2:  
	popad
	ret
Print_Dec ENDP
endif

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  print_hex: prints the Decimal value of EAX                              ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if Not (OS EQ KERNEL)
print_hex   PROC
	pushad
	mov digit,eax
	mov ecx,8
L11:
	rol digit,4
	mov al,byte ptr digit
	and al,0fh
	cmp al,10
	jb j8
	add al,'A'-'0'-10
j8:     add al,'0'
	mov dl,al

	mov ah,02h
	int 21h
	
	loop L11
	popad
	ret
print_hex ENDP
endif

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  _Dprint_char                                                            ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_DPrint_char PROC Near

if (OS EQ DOS32)                        ; ** DOS32 **     
        cmp Screen_Offset,0
        jne _Ok

        pushad
        mov ax,0EE02h                   ; Get DOS32 Address information
        int 31h
        neg ebx                         ; EBX = program address
        add ebx,0b8000h                 ; Convert EBX to video memory
        mov Screen_Offset,ebx
        popad
_Ok:
        push ebx
        mov ebx,Current_Offset
        cmp ebx,ScreenSize
        jbe _Screen_Offset_Ok
        mov Current_Offset,0
_Screen_Offset_Ok:      
        add ebx,Screen_Offset
        mov [ebx],dl
        pop ebx
endif   

if ((OS EQ EOS) OR (OS EQ EOS3))        ;** EOS **
        push ebx
        mov ebx,Current_Offset
        cmp ebx,ScreenSize
        jbe _Screen_Offset_Ok
        mov Current_Offset,0
_Screen_Offset_Ok:      
        add ebx,[_0b8000h]
        mov [ebx],dl
        pop ebx
endif
                                        ;** PMODEW, DOS4GW **
if ((OS EQ PMODEW_ASM) or (OS EQ PMODEW_C) or (OS EQ DOS4GW_ASM) or (OS EQ DOS4GW_C))
        push ebx
        mov ebx,Current_Offset
        cmp ebx,ScreenSize
        jbe _Screen_Offset_Ok
        mov Current_Offset,0
_Screen_Offset_Ok:      
        add ebx,0B8000h
        mov [ebx],dl
        pop ebx
endif

if (OS EQ KERNEL)                       ;** KERNEL **
        mov al,dl
        call DisplayChar
endif
        add Current_Offset,2
        ret
_DPrint_char Endp


;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  Dprint_str: prints a null terminated string (starts at @ESI )           ณ
;ณ                                                                          ณ
;ณ   input: ESI, string start ECX, Max string length                        ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
_DPrint_Str PROC
if (OS EQ KERNEL)
        call DisplayNullString  ; KERNEL Function
else
        pushad
DPrint_Strloop:
        mov dl,[esi]
        inc esi
        cmp dl,0
        je DPrint_strend

        call _DPrint_char
	
        dec ecx
        jnz DPrint_strloop
DPrint_StrEnd:
        popad
endif
        ret
_DPrint_Str ENDP

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  Dprint_dec: prints the Decimal value of EAX                             ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
_DPrint_Dec PROC
if (OS EQ KERNEL)
        call DisplayEAXDec      ; KERNEL Function
else

        pushad
        mov firstone,0
        mov esi,9
        mov ecx,eax
DPrint_Decloop:
        cmp esi,-1
        je DPrint_DecEnd
        mov eax,ecx
        xor edx,edx
        div dec_divider[4*esi]
        dec esi
        mov ecx,edx             

        or firstone,al
        cmp firstone,0
        je DPrint_Decloop

        add al,'0'              ; use quotient as digit number
        mov dl,al

        call _Dprint_char

        jmp DPrint_Decloop
DPrint_DecEnd:
        cmp firstone,0
        jne DPrint_DecEnd2
        mov dl,'0'

        call _Dprint_char
	
DPrint_DecEnd2: 
        popad
endif
        ret
_DPrint_Dec ENDP

;ีออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ                                                                          ณ
;ณ  Dprint_hex: Direct prints the Decimal value of EAX                      ณ
;ณ                                                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
_Dprint_hex   PROC
if (OS EQ KERNEL)
        call DisplayEAX         ; KERNEL Function
else
        pushad
        mov digit,eax
        mov ecx,8
DL11:
        rol digit,4
        mov al,byte ptr digit
        and al,0fh
        cmp al,10
        jb Dj8
        add al,'A'-'0'-10
Dj8:    add al,'0'
        mov dl,al

        call _DPrint_Char
		
        loop DL11
        popad
endif
        ret

_Dprint_hex ENDP

CODE32 ENDS
;=============================================================================
end
; UTILS.ASM (c) 1997 FreddyV/Useless