;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ TIMER.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ                  Timer functions                  บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 14/07/1996       บ
;            บ   Last Update .................. 02/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC      ; Max_timers definition

INCLUDE ERR_CODE.INC   ; Error codes definition
INCLUDE HARDWARE.INC
INCLUDE TIMER.INC

Include UTILS.INC

TimerStrucSize EQU 18

Timer STRUC
      tspeed     DD 0
      tcount     DD 0
      tprevcount DD 0
      tproc      DD 0 ; proc to call offset.
      tactive    DB 0 ; 1 if the timer is On
      tfill      DB 0
ENDS

;=============================================================================

align 4         ; New DOS/4GW stack

if (OS EQ DOS4GW_ASM) OR (OS EQ DOS4GW_C)
_stack   DB 4*1024 DUP (0)
oldstack DF 0
endif

;-----------------------------------------------------------------------------

timersdata  DB max_timers*TimerStrucSize DUP (0)

timer_speed DD 0      ; Timer_speed is 10000h max ! (18.2 IRQ/s)
                      ; but sub timer speed can be more than 10000h
OldTimer    DF 0      ; Old Timer Proc
Oldtimercnt DD 0
data_selector DW 0    ; data selector save.

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Timer_Start:                                                           ณ
;ณ                                                                         ณ
;ณ Input: EAX Timer Procedure Offset                                       ณ
;ณ        EBX Timer Speed ( EBX/1193180 hz )                               ณ
;ณ                                                                         ณ
;ณ Output: CF clear => Ok                                                  ณ
;ณ         CF set   => Error in EAX                                        ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Timer_Start Proc

        mov ecx,Max_timers
        mov esi,offset timersdata
T_add_loop:
        cmp tactive[esi],0
        je  Timer_found
        add esi,TimerStrucSize
        dec ecx
        jnz T_add_loop

        mov eax,TE_NoFreeTimer

if Timer_error EQ 1
        call Display_Error_     ; Display the error and stop the program.
elseif
        stc                     ; Return the Error number
        ret
endif

Timer_Found:
        mov tspeed[esi],ebx             ; New timer speed
        mov tcount[esi],0
        mov tprevcount[esi],0
        mov tproc[esi],eax              ; New timer procedure
        mov tactive[esi],1              ; Activate the new timer

        call get_max_speed

        cmp timer_speed,0
        jne _Donot_hook_timer

        mov data_selector,ds
        push ebx                        ; Save timer rate value (it's in ebx)

        GetIRQ 0,OldTimer               ; Get IRQ 0 proc
        SetIRQ 0,cs,Timer_INT           ; Set new IRQ 0

if (OS EQ KERNEL)
        cli
        call  GetIRQMasks
        and   AX,1111111111111110b
        call  SetIRQMasks
        sti
        xor  ebx,ebx
        call EnableCallback
endif

        pop ebx
_Donot_hook_timer:

        call Set_Timer_Speed
        clc
        ret
Timer_Start Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Timer_Stop:                                                            ณ
;ณ                                                                         ณ
;ณ Input: EAX Timer Proc to stop.                                          ณ
;ณ                                                                         ณ
;ณ Output: CF clear => Ok                                                  ณ
;ณ         CF set   => Error in EAX                                        ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Timer_Stop Proc
        cli

        mov ecx,Max_timers
        mov esi,offset timersdata
TS_loop:
        cmp tactive[esi],0
        je  TS_Not_Active
        cmp tproc[esi],eax
        je  TS_Found
TS_Not_Active:
        add esi,TimerStrucSize
        dec ecx
        jnz TS_loop
        sti

        mov eax,TE_NotFound

if Timer_error EQ 1
        call Display_Error_     ; Display the error and stop the program.
elseif
        stc                     ; Return the Error number
        ret
endif

TS_Found:
        mov tactive[esi],0              ; Stop timer

        call Get_max_speed

        call Set_Timer_Speed            ; Set speed to the fastest timer speed

        mov ecx,Max_timers              ; Restore old the timer ?
        mov esi,offset timersdata
TS_loop2:
        cmp tactive[esi],1
        je  TS_End                      ; One timer is active => NO
        add esi,TimerStrucSize
        dec ecx
        jnz TS_loop2
                                        ; No timer active => Restore old timer
if (OS EQ KERNEL)
        xor ebx,ebx
        call DisableCallBack
endif

        RestIrq 0,OldTimer              ; Set Old timer
        mov timer_speed,0
TS_End:
        sti
        clc
        ret
Timer_Stop Endp

;***************************************************************
;********************  Internal functions **********************
;***************************************************************

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Timer_Int                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

timer_int Proc

        push ds                          ; must save all registers used
        push es
        pushad
        mov ax,cs:data_selector          ; Load DS with data selector
        mov ds,ax
        mov es,ax


;mov eax,0B8000h
;inc dword ptr ds:[eax]

; I had stack fault (with DOS/4GW), this remove the error. Can I increase
; the stack size to avoid this ? this work fine with PMODE/W ! ???

if (OS EQ DOS4GW_ASM) OR (OS EQ DOS4GW_C)
        mov word ptr oldstack[4],ss
        mov dword ptr oldstack,esp
        cli  
        push ds
        pop ss
        mov esp,Offset _Stack
        sti
endif

        mov ecx,Max_timers
        mov esi,offset timersdata
T_call_loop:
        cmp tactive[esi],0
        je  Not_Active

        mov eax,tcount[esi]
        add eax,timer_speed
        mov tcount[esi],eax
        cmp eax,tspeed[esi]
        jb  Not_Active

        mov ebx,eax
        sub eax,tprevcount[esi]         ; eax <- Ticks between this call
        sub ebx,tspeed[esi]             ;        and the previous call
        mov tcount[esi],ebx
        mov tprevcount[esi],ebx

        push ecx
        push esi
        call tproc[esi]                 ; Call the timer Proc
        pop esi
        pop ecx

Not_Active:
        add esi,TimerStrucSize
        dec ecx
        jnz T_call_loop

if (OS EQ DOS4GW_ASM) OR (OS EQ DOS4GW_C)
        lss esp,Oldstack
endif

        ; ** Timer End, call the Old timer proc if needed... **

        mov eax,timer_speed
        add Oldtimercnt,eax
        cmp Oldtimercnt,10000h
        jae Do_Oldtimer

        mov al,20h
        out 20h,al
        popad
        pop es
        pop ds
        iretd                           ; irq end !!!

Do_Oldtimer:
        sub Oldtimercnt,10000h
        popad
        pop es
        pop ds

        jmp cs:OldTimer                 ; continue on interrupt chain.
                                        ; must use CS because DS is unknown
timer_int Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Get_max_speed. Returns the speed of the fastest timer.                 ณ
;ณ                                                                         ณ
;ณ Output: EBX Timer speed                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GET_MAX_SPEED Proc
        mov ebx,10000h
        mov ecx,Max_timers
        mov esi,offset timersdata
T_get_speed_loop:
        cmp tactive[esi],0
        je  GS_NoTimer
        cmp tspeed[esi],ebx
        jae GS_NoTimer
        mov ebx,tspeed[esi]
GS_NoTimer:
        add esi,TimerStrucSize
        dec ecx
        jnz T_get_speed_loop
        ret
GET_MAX_SPEED Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Set_Timer_Speed:  Set the new timer speed.                             ณ
;ณ                                                                         ณ
;ณ Input: BX Timer Value                                                   ณ
;ณ                                                                         ณ
;ณ        -> Timer frequence=1193180/BX                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Set_Timer_Speed Proc
        cmp timer_speed,ebx
        je  same_speed
        push ax
        cli
        mov al,00110110b
        out 43h,al
        mov ax,bx
        out 40h,al
        mov al,ah
        out 40h,al
        sti
        pop ax
        mov timer_speed,ebx
same_speed:
        ret
Set_Timer_Speed Endp

CODE32 ENDS
;=============================================================================
END
; TIMER.ASM (c) 1997 FreddyV/Useless