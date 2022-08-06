;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ GUSDRV.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ         Useless Gravis Ultrasound Driver          บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 13/03/1996       บ
;            บ   Last Update .................. 09/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE ERR_CODE.INC
INCLUDE GUSDRV.INC
INCLUDE USSVAR.INC
INCLUDE HARDWARE.INC
INCLUDE TIMER.INC

INCLUDE UTILS.INC

StopLineIn equ 0 ; 0: Enable GUS LineIn
                 ; 1: Stop Linein

;=============================================================================

Public GUS_DEVICE

GUS_DEVICE label
             dd Offset GUS_Detect
             dd Offset GUS_Init
             dd Offset GUS_LoadSample
             dd Offset GUS_FreeSample
             dd Offset GUS_DoNothing
             dd Offset GUS_StartOutput
             dd Offset GUS_StopOutput
             dd Offset GUS_UpdateOutput

             dw 1
             dd Offset GUS_PortList
             dd Offset GUS_Name

GUS_Name db 'Gravis UltraSound',0,36

GUS_PortList dw 210h,220h,230h,240h,250h,260h,-1

;------------------------------------------------------------------------------

GUSEnv db 8,'ULTRASND'

; - GUS Settings -

GUS_DRAMSIZE   DD 0     ; GUS DRAM Size

GUS_DRAMOffset DD 0     ; DRAM offset of the next sample.
GUS_divisor    DD 0
GUS_ActiveChannels DD 0

;------------------------------------------------------------------------------

GUSMode DB 0

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_Detect: Detect the Gravis UltraSound.                              ณ
;ณ                                                                         ณ
;ณ Input: EAX Device Type (0=Autodetect)                                   ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> No GUS                                                 ณ
;ณ         CF Cleared => AL Sub device number                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_Detect proc

        mov _DEV_BasePort,220h
        mov _DEV_Mode,DM_DRAM+DM_16bit+DM_Stereo+DM_Interp
        mov _DEV_Name,Offset GUS_Name
        mov _DEV_MaxChannels,32
        mov eax,Offset GUSEnv
        call GetEnvOffset
        jc GUS_DetectError

        xor eax,eax
        mov cl,3
GetGUSPortLoop:
        mov bl,[edi]
        inc edi
        cmp bl,' '
        je GetGUSPortLoop
        sub bl,'0'
        add al,bl
        shl eax,4
        dec cl
        jnz GetGUSPortLoop
        shr eax,4

        mov _DEV_BasePort,ax

        call GUS_harddetect             ;Is GUS here ?
        jc GUS_DetectError

        mov eax,1
        clc                             ;GUS found, good ! ;)
        ret

GUS_DetectError:
        stc
        ret
GUS_Detect endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_Init: Init the Gravis UltraSound.                                  ณ
;ณ                                                                         ณ
;ณ Input: EAX Device Type (0=Autodetect)                                   ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Init Error                                             ณ
;ณ         CF Cleared => Ok                                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_Init proc

        call GUS_harddetect             ;Is GUS here ?
        jc GUS_InitError

        mov GUS_DRAMOFFSET,0

        call GUS_OutputInit             ;Now Initialise the GUS card.

        clc
        ret
GUS_InitError:

        mov eax,DE_InitFail
        stc
        ret
GUS_Init endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUS_StartOutput                                                         ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic function to call                                    ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ณ Note : SSActiveChannels must be correctly set before.                   ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_StartOutput proc

; Set the number of active channels
        mov eax,SSActiveChannels
        mov ebx,32
        cmp eax,ebx
        jbe GUSChannelsOk
        mov eax,32
GUSChannelsOk:
        mov GUS_ActiveChannels,eax

        push eax
        cmp al,14
        jae VoicesOk
        mov al,14
VoicesOk:
        mov bl,VoicesActive
        dec al
        or al,0c0h
        call guswrite
        pop eax

        sub eax,14
        cmp eax,18
        jbe GetDivisor
        xor eax,eax
GetDivisor:
        xor ebx,ebx
        mov bx,VDivisor[2*eax]
        mov GUS_divisor,ebx

; Start the timer at 140Hz
        mov eax,esi
        mov ebx,TimerSpeed/(70*2) ; Two times faster than the screen
        call Timer_Start
        jc   GUS_StartOutputError

        clc
        ret

GUS_StartOutputError:
        stc
        ret
GUS_StartOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_StopOutput                                                          ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic proc to stop                                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error Code in EAX                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_StopOutput proc

        mov eax,esi
        call Timer_Stop
        jc GUS_StopOutputError
        call GUS_OutputInit
        clc
        ret

GUS_StopOutputError:
        call GUS_OutputInit
        stc
        ret
GUS_StopOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_LoadSample:                                                        ณ
;ณ                                                                         ณ
;ณ Input: ESI Sample data                                                  ณ
;ณ        EDI Sample structure                                             ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_LoadSample Proc
        mov edx,SLength[edi]
        inc GUS_DRAMOffset      ; 1 byte at Sample Start
        mov eax,GUS_DRAMOffset
        add eax,edx
        cmp eax,GUS_DRAMSIZE    ; Enaugh GUS memory to load the sample ?
        ja  GUS_LoadSampleError ; No -> Error.
        inc eax                 ; 1 byte at Sample End

        push edi
        mov edi,GUS_DRAMOffset
        mov ebx,edi
        mov GUS_DRAMOffset,eax

        mov ecx,edx
        call GUS_RAM2DRAM

        pop edi

        mov ecx,ebx             ; To avoid some more click...
        call GUS_Peek
        dec ecx
        call GUS_Poke
        add ecx,edx
        call GUS_Peek
        inc ecx
        call GUS_Poke

        mov SPointer[edi],ebx   ; Sample DRAM location
        or SFlag[edi],SF_Loaded ; Sample is loaded
        cli
        ret

GUS_LoadSampleError:
        sti
        ret
GUS_LoadSample Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_FreeSample:                                                        ณ
;ณ                                                                         ณ
;ณ Input: EDI Sample structure                                             ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_FreeSample Proc
        mov GUS_DRAMOffset,0
        and SFlag[edi],Not SF_Loaded ; Sample is released
        cli
        ret
GUS_FreeSample Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_UpdateSound:                                                       ณ
;ณ                                                                         ณ
;ณ Input:  --                                                              ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_UpdateOutput proc

; ** Ramp the volume down to stop the voices **

        xor ebp,ebp
StopLoop:
        mov eax,ebp
        call GUS_SetVoice              ; Select Voice Number

        test VChControl[2*ebp],CC_StopVoice
        jz   NoStopVoice
        and VChControl[2*ebp],Not CC_StopVoice

        mov bl,WriteVoiceMode
        mov al,3
        call GUSwrite
        call GUS_delay
        call GUSwrite

        call GUS_fadevoldown

NoStopVoice:
        inc ebp
        cmp ebp,GUS_ActiveChannels
        jne StopLoop

        xor ebp,ebp
WaitLoop:
        mov eax,ebp
        call GUS_SetVoice              ; Select Voice Number

; ** Wait until ramp End **

dowait:
        mov al,ReadVolCtrl
        call GUSread
        test al,1
        jz dowait

        inc ebp
        cmp ebp,GUS_ActiveChannels
        jne WaitLoop

; ** Start Voices update **

        xor ebp,ebp
ChannelLoop:
        mov eax,ebp
        call GUS_SetVoice               ; Select Voice Number

        test VChControl[2*ebp],CC_ChSample ; ** Start a sample ? **
        jz   NoChSample
        and VChControl[2*ebp],Not CC_ChSample

        mov esi,VChSmpAdress[4*ebp]
        mov ebx,SPointer[esi]          ; ebx <- Sample Start
        mov eax,VChSmpOffset[4*ebp]
        add eax,ebx

        cmp ebx,eax
        Ja NoChSample

        mov ecx,SLength[esi]

        Test Stype[esi],SM_Sustain
        jne _UseSustainLoop

        Test Stype[esi],SM_Loop         ; ** Loop **
        jz  _NoLoop
        mov ecx,SLoopEnd[esi]
_NoLoop:
        add ecx,ebx                     ; ecx <- Sample End
        cmp ecx,eax
        jb  NoChSample
        mov edx,SLoop[esi]
        add edx,ebx

        mov bl,SType[esi]
        and bl,00011100b
        mov GUSMode,bl                  ; Sample Mode (8/16bit, loop...)

        jmp _DoStartSample

_UseSustainLoop:
        mov ecx,SSustEnd[esi]           ; ** Sustain Loop **
        add ecx,ebx                     ; ecx <- Sample End
        cmp ecx,eax
        jb  NoChSample
        mov edx,SSustain[esi]
        add edx,ebx

        mov bl,SType[esi]
        mov bh,bl
        shr bh,2
        and bl,00000100b
        and bh,00011000b
        or bl,bh
        mov GUSMode,bl                  ; Sample Mode (8/16bit, loop...)
_DoStartSample:
        
        push edx

        mov bl,SampleStartLo            ; Set Sample Start
        call GUSSetAddress

        mov bl,SampleEndLo              ; Set Sample End
        mov eax,ecx
        call GUSSetAddress

        mov bl,LoopStartLo              ; Set Loop Start
        pop eax
        call GUSSetAddress

        mov al,GUSMode
        mov bl,WriteVoiceMode
        call GUSwrite                   ; Start the sample

NoChSample:
        test VChControl[2*ebp],CC_DoRelease      ; * Release the sample ? *
        jz   NoReleaseSample
        and VChControl[2*ebp],Not CC_DoRelease

        mov esi,VChSmpAdress[4*ebp]
        Test Stype[esi],SM_Sustain
        jz NoReleaseSample

        mov ebx,SPointer[esi]          ; ebx <- Sample Start
        mov eax,VChSmpOffset[4*ebp]
        add eax,ebx

        cmp ebx,eax
        Ja NoReleaseSample

        mov ecx,SLength[esi]

        Test Stype[esi],SM_Loop         ; ** Loop **
        jz  _RNoLoop
        mov ecx,SLoopEnd[esi]
_RNoLoop:
        add ecx,ebx                     ; ecx <- Sample End
        cmp ecx,eax
        jb  NoChSample
        mov edx,SLoop[esi]
        add edx,ebx

        push edx

        mov bl,SampleEndLo              ; Set Sample End
        mov eax,ecx
        call GUSSetAddress

        mov bl,LoopStartLo              ; Set Loop Start
        pop eax
        call GUSSetAddress

        mov al,SType[esi]
        and al,00011100b
        mov bl,WriteVoiceMode
        call GUSwrite                   ; Start the sample

NoReleaseSample:

        test VChControl[2*ebp],CC_ChPeriod       ; * Change Channel Frequency ? *
        jz   NoChPeriod
        and VChControl[2*ebp],Not CC_ChPeriod

        mov eax,VChFreq[4*ebp]

        xor edx,edx
        shl eax,10
        mov ebx,GUS_Divisor
        div ebx                         ; Now ax is GUS Frequency

        mov bl,SetVoiceFreq
        call GUSwritew                  ; Set GUS Frequency

NoChPeriod:

        test VChControl[2*ebp],CC_ChVolume ; ** Volume ? **
        jz   NoChVolume
        and VChControl[ebp],Not CC_ChVolume

        xor eax,eax
        mov al,VChFVolume[ebp]
        movzx edx,GUSvol[2*eax]

        call GUSfadevol

NoChVolume:

        test VChControl[2*ebp],CC_ChPanning  ; ** Panning ? **
        jz   NoChPanning
        and VChControl[2*ebp],Not CC_ChPanning

        mov al,VChFPanning[ebp]
        cmp al,128                           ; Middle panning ?
        jne GUS_NoMiddle
        mov al,7
        jmp GUS_SetPanning
GUS_NoMiddle:        
        shr al,4
GUS_SetPanning:
        mov bl,VoiceBalance
        call GUSwrite
NoChPanning:

        mov al,Read                          ; Is voice stopped ?
        call GUSread
        test al,1
        jz ChNotStopped
        and VChControl[2*ebp],Not CC_playing ; Yes => clear voice playing bit
ChNotStopped:

        inc ebp
        cmp ebp,GUS_ActiveChannels
        jne ChannelLoop

GUS_UpdateSoundEnd:

        clc
        ret
GUS_UpdateOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUS_DoNothing                                                           ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_DoNothing Proc
        clc
        ret
GUS_Donothing Endp

;***************************************************************
;********************  Internal functions **********************
;***************************************************************


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUS_RAM2DRAM: Dump sample to GUS DRAM.                                  ณ
;ณ                                                                         ณ
;ณ Input: ESI - sample to dump to RAM.                                     ณ
;ณ        EDI - DRAM location to dump to.                                  ณ
;ณ        ECX - Max bytes to dump.                                         ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_RAM2DRAM Proc

        pushad
        cli
        mov ebx,edi         ; BL SHL 16 + DI -> DRAM location
        shr ebx,16

        mov dx,_DEV_BasePort
        add dx,CommandPort  ; (Reg Select)

        mov dx,_DEV_BasePort
        add dx,CommandPort  ; (Reg Select)
        mov al,DRAMAddrHi   ; Dump upper byte, only do it on carry from now
        out dx,al           ; on.
        add dx,2
        push ax
        mov ax,bx           ; BX Partie haute de l'addresse
        out dx,al           ; 3x5 Data High
        pop ax
        sub dx,2
        mov al,DRAMAddrLo
        out dx,al           ; 3x3 Select Register
        inc dx
MainLoop:
        mov ax,di
        out dx,ax           ; 3x4 Data Low Port
        add dx,3
        mov al,[esi]
        inc esi
        out dx,al           ; 3x7 DRAM IO Port
        sub dx,3
        add di,1
        jnc DoLoop

        dec dx
        inc bx              ; Passe a une autre banque (DI>65536)}
        mov al,DRAMAddrHi
        out dx,al           ; 3x3 Select Register
        add dx,2
        mov ax,bx           ; SI Partie haute de l'addresse
        out dx,al           ; 3x5 Data High
        sub dx,2
        mov al,DRAMAddrLo
        out dx,al           ; 3x3 Select Register
        inc dx
DoLoop:
        dec ecx
        jnz MainLoop
        sti
        popad

        ret
GUS_RAM2DRAM Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUSwrite: Write AL value into the BL GUS register. (Data high port)     ณ
;ณ                                                                         ณ
;ณ Input: AL, Value                                                        ณ
;ณ        BL, GUS Register                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUSwrite Proc
        push edx
        mov dx,CommandPort
        add dx,_DEV_BasePort
        xchg al,bl
        out dx,al       ; Select the bl register.
        add dx,2        ; Data High port
        xchg al,bl
        out dx,al       ; Write AL in register BL
        pop edx
        ret
GUSwrite Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUSwritew: Write AX value into the BL GUS register. (Data low port)     ณ
;ณ                                                                         ณ
;ณ Input: AX, Value                                                        ณ
;ณ        BL, GUS Register                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUSwritew Proc
        push edx
        mov dx,CommandPort
        add dx,_DEV_BasePort
        xchg al,bl
        out dx,al       ; Select the bl register.
        inc dx          ; Data Low port
        xchg al,bl
        out dx,ax       ; Write AX in register BL
        pop edx
        ret
GUSwritew Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUSread: Read AL value from the AL GUS register. (Data high port)       ณ
;ณ                                                                         ณ
;ณ Input: AL, GUS Register                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUSread Proc
        mov dx,CommandPort
        add dx,_DEV_BasePort
        out dx,al
        add dx,2
        in al,dx
        ret
GUSread Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUSreadw: Read AX value from the AL GUS register. (Data low port)       ณ
;ณ                                                                         ณ
;ณ Input: AL, GUS Register                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
GUSreadw Proc
        mov dx,CommandPort
        add dx,_DEV_BasePort
        out dx,al
        inc dx
        in ax,dx
        ret
GUSreadw Endp

GUSSetaddress Proc
        push eax
        shr eax,7       ; Address High
        call GUSwritew
        pop eax
        shl eax,9       ; Address Low
        inc bl
        call GUSwritew
        ret
GUSSetaddress Endp

; Code taken from cubic mxm player (I'm sometimes lazy :) )

GUSfadevol proc

        mov al,ReadVolume
        push edx
        call GUSreadw
        pop edx
        movzx eax,ax
        mov bl,0
        cmp eax,edx
        jbe @@up
        xchg eax,edx
        mov bl,40h
@@up:
        sub edx,eax
        jz @@done
        cmp edx,4096
        jae @@normfade
        cmp bl,40h
        je @@swapped
        add eax,edx
@@swapped:
        mov bl,SetVolume
        push edx
        call GUSwritew
        pop edx
        jmp @@done

@@normfade:
        add edx,eax

        cmp eax,4096
        jae @@stok
        mov eax,4096
@@stok:
        cmp edx,64512
        jbe @@eok
        mov edx,64512
@@eok:

        push ebx
        mov al,ah
        mov bl,VolRampStart
        push edx
        call GUSwrite
        pop edx
        mov al,dh
        mov bl,VolRampEnd
        call GUSwrite
        pop eax
        mov bl,VolumeCtrl
        call GUSwrite
        call GUS_delay
        call GUSwrite

@@done:
        ret
GUSfadevol endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUS_fadevoldown: Fade channel volume to 0                               ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_fadevoldown proc
        mov bl,VolRampStart
        mov al,04h
        call guswrite
        mov bl,VolRampEnd
        mov al,0fch
        call guswrite
        mov bl,VolumeCtrl
        mov al,40h
        call GUSwrite
        call GUS_delay
        call GUSwrite
        ret
GUS_fadevoldown endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GUS_SetVoice: Set the current active Voice.                             ณ
;ณ                                                                         ณ
;ณ Input: AL, Voice number. (0-31)                                         ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_SetVoice Proc
        push edx
        mov dx,_DEV_BasePort
        add dx,ActiveVoicePort
        out dx,al
        pop edx
        ret
GUS_SetVoice Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_peek: Reads a byte from GUS DRAM.                                  ณ
;ณ                                                                         ณ
;ณ Input: ECX, DRAM location.                                              ณ
;ณ                                                                         ณ
;ณ Output: AL, read value.                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_peek proc
        push edx
        mov dx,_DEV_BasePort
        add dx,CommandPort      ; Select Register (3x3)
        mov al,DRAMAddrLo
        out dx,al
        inc dx                  ; DataLowPort     (3x4)
        mov eax,ecx
        out dx,ax
        dec dx                  ; CommandPort     (3x4)
        mov al,DRAMAddrHi
        out dx,al
        add dx,2
        shr eax,16
        out dx,al
        add dx,2
        in  al,dx
        pop edx
        ret
GUS_peek endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_poke: Write a byte to GUS DRAM.                                    ณ
;ณ                                                                         ณ
;ณ Input: ECX, DRAM location.                                              ณ
;ณ        AL, byte to write.                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_poke proc
        push edx
        push eax
        mov dx,_DEV_BasePort
        add dx,CommandPort      ; Select Register (3x3)
        mov al,DRAMAddrLo
        out dx,al
        inc dx                  ; DataLowPort     (3x4)
        mov eax,ecx
        out dx,ax
        dec dx                  ; CommandPort     (3x3)
        mov al,DRAMAddrHi
        out dx,al
        add dx,2                ; DataHighPort    (3x5)
        shr eax,16
        out dx,al
        add dx,2                ; DRAMIOPort      (3x7)
        pop eax
        out dx,al
        pop edx
        ret
GUS_poke endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_delay:                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_delay proc
        push dx
        push ax
        mov dx,_DEV_BasePort
        add dx,CommandPort
        rept 7
        in al,dx
        endm
        pop ax
        pop dx
        ret
GUS_delay endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_harddetect: Hardware detection of the Gravis UltraSound.           ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> No GUS                                                 ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GUS_harddetect proc
        mov dx,_DEV_BasePort
                                ; Take the Ultrasound out of a reset state
        add dx,CommandPort      ; because it's in a reset state at power up.
        mov al,Initialize
        out dx,al
        add dl,2                ; DataHighPort
        mov al,00000111b
        out dx,al
        mov ecx,100h            ; delay a bit ????
        loop $

        mov GUS_DRAMSize,0
        xor ecx,ecx
GUS_harddetectloop:
        mov al,55h
        call GUS_poke

        inc ecx
        mov al,0AAh
        call GUS_poke

        call GUS_peek
        cmp al,0AAh
        jne GUS_harddetectend

        dec ecx
        call GUS_peek
        cmp al,055h
        jne GUS_harddetectend

        add ecx,256*1024
        mov GUS_DRAMSize,ecx
        cmp ecx,1024*1024
        jne GUS_harddetectloop

GUS_harddetectend:
        cmp ecx,1
        jbe  _NoGUS
        clc
        ret
_NoGUS:
        stc
        ret

GUS_harddetect endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  GUS_OutputInit: Init the GUS                                           ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

GUS_OutputInit proc
        cli

        mov al,0                        ;Init <- 0 (GF1 Master Reset)
        mov bl,Initialize
        call GUSwrite

        call GUS_Delay
        call GUS_Delay

        mov al,1                        ;Init <- 1 (GF1 Enable)
        mov bl,Initialize
        call GUSwrite

        call GUS_Delay
        call GUS_Delay

        mov bl,VoicesActive
        mov al,31
        call guswrite

; ** Loop to clear the voices **

        push ecx
        mov ecx,32
Voiceclearloop:
        mov dx,_DEV_BasePort
        add dx,ActiveVoicePort
        mov al,cl
        dec al
        out dx,al                       ;Select the voice CL

        mov  al,3
        mov  bl,WriteVoiceMode          ;Voice Off
        call GUSWrite
        mov  bl,VolumeCtrl              ;Volume ramp off
        call GUSWrite
        mov  al,00111111b               ;Max RampRate
        mov  bl,VOLRampRate
        call GUSWrite
        mov  ax,05000h                  ;Volume <- 0
        mov  bl,SetVOLume
        call GUSwritew

        call GUS_delay
        call GUS_delay

        loop Voiceclearloop
        pop ecx

        mov al,3                       ;GF1 Enable, Output enable, IRQ disable
        mov bl,Initialize
        call GUSwrite

        call GUS_delay

        mov dx,_DEV_BasePort            ; "Mixer" port
        mov al,8+StopLineIn
        out dx,al

        sti
        ret
GUS_OutputInit endp

VDivisor dw 44100,41160,38587,36317,34300,32494,30870,29400,28063,26843
         dw 25725,24696,23746,22866,22050,21289,20580,19916,19293

;GUSvol dw 01500h
;       dw 0A0DEh,0AB52h,0B2BDh,0B87Eh,0BD31h,0C12Bh,0C49Ch,0C7A5h
;       dw 0CA5Dh,0CCD2h,0CF10h,0D120h,0D309h,0D4D1h,0D67Bh,0D80Bh
;       dw 0D984h,0DAE9h,0DC3Bh,0DD7Dh,0DEB0h,0DFD6h,0E0EFh,0E1FCh
;       dw 0E2FFh,0E3F8h,0E4E8h,0E5D0h,0E6AFh,0E788h,0E859h,0E924h
;       dw 0E9E9h,0EAA9h,0EB63h,0EC18h,0ECC8h,0ED73h,0EE1Ah,0EEBDh
;       dw 0EF5Ch,0EFF7h,0F08Fh,0F123h,0F1B5h,0F242h,0F2CDh,0F356h
;       dw 0F3DBh,0F45Eh,0F4DEh,0F55Bh,0F5D7h,0F650h,0F6C7h,0F73Ch
;       dw 0F7AEh,0F81Fh,0F88Eh,0F8FBh,0F967h,0F9D0h,0FA38h,0FA9Eh

GUSvol dw 05000h,08FF0h,09FF0h,0A800h,0AFF0h,0B400h,0B800h,0BC00h
       dw 0BFF0h,0C200h,0C400h,0C600h,0C800h,0CA00h,0CC00h,0CE00h
       dw 0CFF0h,0D100h,0D200h,0D300h,0D400h,0D500h,0D600h,0D700h
       dw 0D800h,0D900h,0DA00h,0DB00h,0DC00h,0DD00h,0DE00h,0DF00h
       dw 0DFF0h,0E080h,0E100h,0E180h,0E200h,0E280h,0E300h,0E380h
       dw 0E400h,0E480h,0E500h,0E580h,0E600h,0E680h,0E700h,0E780h
       dw 0E800h,0E880h,0E900h,0E980h,0EA00h,0EA80h,0EB00h,0EB80h
       dw 0EC00h,0EC80h,0ED00h,0ED80h,0EE00h,0EE80h,0EF00h,0EF80h
       dw 0EF80h

CODE32  ENDS
;=============================================================================
end
; GUSDRV.ASM (c) 1997 FreddyV/Useless
