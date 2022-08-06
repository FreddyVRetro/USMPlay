;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ HPDRV.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ                 PC Speaker Driver                 บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 25/08/1996       บ
;            บ   Last Update .................. 24/09/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
; Yes, I'v done it, but I'm not proud of it. ;-)
.386p
INCLUDE OS.INC

CODE32 segment public para 'CODE' USE32
assume  cs:CODE32,ds:CODE32,es:CODE32

INCLUDE SETUP.INC

INCLUDE MIX.INC
INCLUDE USSVAR.INC
INCLUDE TIMER.INC
INCLUDE MEMORY.INC

;==============================================================================

public HP_DEVICE

HP_DEVICE label
	    dd Offset HP_Detect
            dd Offset HP_Init
            dd Offset MIX_LoadSample
	    dd Offset MIX_FreeSample
	    dd Offset MIX_SetAmpli
	    dd Offset HP_StartOutput
	    dd Offset HP_StopOutput
	    dd Offset MIX_UpdateSound

	    dw 1
	    dd 0
	    dd Offset HP_Name

HP_Name db 'Internal Speaker',0,36

;------------------------------------------------------------------------------

TickCnt      DD 0
PeriodicProc DD 0
BufferPtr    DD 0
BufferEnd    DD 0

;==============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  HP_detect: Detect Internal Speaker ;)                                  ณ
;ณ                                                                         ณ
;ณ Input: EAX Device type (0=Autodetect)                                   ณ
;ณ                                                                         ณ
;ณ Output: AL=1                                                            ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
HP_Detect proc
	or eax,eax
	jz No_HP
	mov _DEV_Freq,16000
	mov _DEV_Mode,DM_Mixed+DM_Signed
	mov _DEV_Name,Offset HP_Name
	mov _DEV_MaxChannels,Max_SSChannels
	mov ax,1
	clc       ; It's always here !
	ret
No_HP:        
	stc
	ret
HP_Detect endp

HP_Init Proc
        clc
        ret
HP_Init Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ HP_StartOutput                                                          ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic function to call                                    ณ
;ณ        EAX Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error Code in EAX.                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

HP_StartOutput proc

	mov PeriodicProc,esi

;** Buffer Size calculation **

	movzx eax,_DEV_Freq
	mov cx,50/2       ; 2 buffers => /25
	xor edx,edx
	div cx

        add eax,3
        and eax,0FFFFFFFCh

        mov MIX_BSize,eax
        shr MIX_BSize,1   ; ! MIX_BSize is the size of one buffer

        U_Malloc eax      ; Allocate the 2 final buffers
        mov MIX_FBOffset,eax

        call MIX_Start    ; Allocate MIX Buffers

;** Now, start the output **

        in al,61h         ; Start PC speaker output
        or al,03h         ; (Link timer 2 with the speaker)
        out 61h,al      

        mov al,0B6h       ; Init Timer 2
        out 43h,al
        mov al,0B0h
        out 43h,al
        mov al,034h
        out 43h,al
        xor al,al
        out 42h,al
        out 42h,al
        mov al,10010000b
        out 43h,al

        mov TickCnt,0
        mov MIX_ActiveB,1
        call SwapBuff
        mov MIX_ActiveB,0

        xor edx,edx
        mov eax,TimerSpeed      
        movzx ecx,_DEV_Freq     ; Use Output frequency for the timer speed
        div ecx                 ; => Internal Speaker device is Slowwwwww...

        mov ebx,eax
        mov eax,Offset HP_IRQ
        call Timer_Start        ; Start the PC Timer
        jc HP_StartOutputError  

        clc
        ret

HP_StartOutputError:
        stc
        ret
HP_StartOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ HP_StopOutput                                                           ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic proc to stop                                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error code in EAX                                      ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

HP_StopOutput proc

        in al,61h        ; Stop the sound ( That's better now :) )
        and al,0FCh
        out 61h,al
        
        mov eax,Offset HP_IRQ
        call Timer_Stop
        jc HP_StopOutputError

        call MIX_Stop

        U_Free MIX_FBOffset

        clc
        ret
HP_StopOutputError:
        stc
        ret
HP_StopOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SwapBuff: Get start and end of the buffer to be play                    ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SwapBuff Proc
         mov eax,MIX_FBOffset
         cmp MIX_ActiveB,0
         jne Use_1stBuffer
         add eax,MIX_BSize
Use_1stBuffer:
         mov BufferPtr,eax
         add eax,MIX_BSize
         dec eax
         mov BufferEnd,eax
         ret
SwapBuff Endp

HP_IRQ proc
        add TickCnt,eax

        mov edx,BufferPtr
        xor eax,eax
        mov al,[edx]
        mov al,T_beep[eax]
        inc edx

        out 42h,al        ; Here is the out that creates the wonderfull noise

        cmp edx,BufferEnd
        je  CallPeriodicProc
        mov BufferPtr,edx
        ret

CallPeriodicProc:

        call SwapBuff

        mov eax,TickCnt
        mov TickCnt,0

        call [PeriodicProc]

        ret
HP_IRQ endp

;=============================================================================

T_beep DB 20h,1Fh,1Eh,1Dh,1Ch,1Bh,1Ah,19h,18h,17h,16h,15h,14h,13h,12h,11h
       DB 11h,10h,10h,0Fh,0Fh,0Eh,0Eh,0Dh,0Dh,0Dh,0Ch,0Ch,0Ch,0Ch,0Bh,0Bh
       DB 0Bh,0Bh,0Ah,0Ah,0Ah,0Ah,0Ah,09h,09h,09h,09h,09h,09h,09h,09h,09h
       DB 08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,07h,07h,07h,07h
       DB 07h,07h,07h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,05h,05h
       DB 05h,05h,05h,05h,05h,05h,05h,05h,04h,04h,04h,04h,04h,04h,04h,04h
       DB 04h,04h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,02h,02h,02h,02h
       DB 02h,02h,02h,02h,02h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h

       DB 40h,40h,40h,40h,40h,40h,40h,40h,40h,40h,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
       DB 3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh,3Eh
       DB 3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Dh,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch,3Ch
       DB 3Ch,3Ch,3Ch,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Bh,3Ah,3Ah,3Ah
       DB 3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,39h,39h,39h,39h,39h,39h,39h,39h,39h
       DB 39h,38h,38h,38h,38h,38h,38h,38h,38h,37h,37h,37h,37h,37h,36h,36h
       DB 36h,36h,35h,35h,35h,35h,34h,34h,34h,33h,33h,32h,32h,31h,31h,30h
       DB 30h,2Fh,2Eh,2Dh,2Ch,2Bh,2Ah,29h,28h,27h,26h,25h,24h,23h,22h,21h

CODE32 ends
;=============================================================================
end
; HPDRV.ASM (c) 1997 FreddyV/Useless
