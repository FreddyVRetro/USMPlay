;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ SBDRV.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ              Sound Blaster Driver                 บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 03/08/1996       บ
;            บ   Last Update .................. 26/11/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
; Some part of the code were taken from MIDASS because it's faster
; for me to do like this and there are not 100 ways of writing this...
; (And I'm during military service, so I'v got a lack of time :( )
; So, Thanks to MIDASS player authors.
; Part of this file is Copyright 1996 Petteri Kangaslampi and Jarno Paananen
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC

INCLUDE ERR_CODE.INC
INCLUDE SBDRV.INC
INCLUDE HARDWARE.INC
INCLUDE MIX.INC
INCLUDE USSVAR.INC

INCLUDE UTILS.INC

;==============================================================================

Public SB_DEVICE

SB_DEVICE label 
            dd Offset SB_Detect
            dd Offset SB_Init
            dd Offset MIX_LoadSample
            dd Offset MIX_FreeSample
            dd Offset MIX_SetAmpli
            dd Offset SB_StartOutput
            dd Offset SB_StopOutput
            dd Offset MIX_UpdateSound

            dw 5                        ; 5 Sub Devices
            dd Offset SB_PortList
SB_Name     dd Offset SB10_Name     
            dd Offset SB15_Name
            dd Offset SB20_Name     
            dd Offset SBPro_Name            
            dd Offset SB16_Name     
	    
SB10_Name  db 'Sound Blaster v1.0 or clone',0,36
SB15_Name  db 'Sound Blaster v1.5',0,36
SB20_Name  db 'Sound Blaster v2.0',0,36
SBPro_Name db 'Sound Blaster Pro',0,36
SB16_Name  db 'Sound Blaster 16',0,36

SB_PortList dw 210h,220h,230h,240h,250h,260h,-1

SB_Freq     dw 22050,22050,44100,44100,44100

SB_Mode    dw DM_Mixed+DM_8bit+DM_Mono                  ; SB 1.0
           dw DM_Mixed+DM_8bit+DM_Mono                  ; SB 1.5
           dw DM_Mixed+DM_8bit+DM_Mono                  ; SB 2.0
           dw DM_Mixed+DM_8bit+DM_Stereo                ; SB Pro
           dw DM_Mixed+DM_16bit+DM_Stereo+DM_signed     ; SB16

;------------------------------------------------------------------------------

align 4         ; New stack for DOS/4GW

if (OS EQ DOS4GW_ASM) OR (OS EQ DOS4GW_C)
_stack   DB 4*1024 DUP (0)
oldstack DF 0
endif

;------------------------------------------------------------------------------

SBTimeConst DB 0
SBAutoinit  DB 0
SBBuffSize  DD 0
SBBlockLength DW 0

SBIRQOn      DW 0
OldIRQ       DF 0
PeriodicProc DD 0
DataSel      DW 0

SBLowDMA     DB 0
SBHighDMA    DB 0
DetectType   DB 0
DetectedType DB 0
SBDetected   DB 0

BlasterEnv DB 7,'BLASTER'

SBWrite MACRO CmdValue  
	mov bl,CmdValue
	call SBDSPWrite
ENDM

;==============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  SB_Detect: Detect the Sound Blaster.                                       ณ
;ณ                                                                         ณ
;ณ Input: EAX Device type (0=Autodetect)                                   ณ
;ณ                                                                         ณ
;ณ Output: CF Set => No SB or wrong SB Type.                               ณ
;ณ         CF Cleared  => EAX Device type                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SB_Detect Proc

        mov SBDetected,0
        mov DetectType,al

; ** 'default' SB config

        mov _DEV_Type,SB10
        mov _DEV_BasePort,220h
        mov _DEV_IRQ,7
        mov _DEV_DMA,1
        mov _DEV_Mode,DM_Mixed+DM_8bit+DM_Mono
        mov _DEV_Freq,22100
        mov SBLowDMA,1
        mov SBHighDMA,5

; ** Read PORT/IRQ/DMA From Environment variable

        call SBReadEnvVar
	jc SB_NotDetected

; ** Try Sound Blaster Init

	call SBDSPInit
        jc SB_NotDetected

; ** Detect Device number

	call SBGetVersion
        jc SB_NotDetected

        mov SBDetected,1

SB_NotDetected:

; ** Return correct device info
        movzx eax,_DEV_Type
        mov DetectedType,al
        
        cmp DetectType,0
        je UseAutodetectedType
        
        movzx eax,DetectType
        mov _DEV_Type,ax

UseAutodetectedType:

        call GetSBInfo

        movzx eax,_DEV_Type
        cmp al,DetectedType     ; Is it the correct Sound Blaster card ?
        ja SB_DetectError

        cmp SBDetected,1        ; Is Sound Blaster card here ?
        jne SB_DetectError

        clc                     ; SB Found
        ret

SB_DetectError:
        stc                     ; No SB or No Environment var
        ret
SB_Detect Endp

GetSBInfo Proc
        mov bl,SBLowDMA
        mov _DEV_DMA,bl

        movzx eax,_DEV_Type
        cmp al,SB16
        jne SB_NoHighDMA
        mov bl,SBHighDMA
        mov _DEV_DMA,bl         ; If SB16, DMA is high DMA
SB_NoHighDMA:   
        dec eax 
        mov bx,SB_Mode[2*eax]
        mov _DEV_Mode,bx
        mov bx,SB_Freq[2*eax]
        mov _DEV_Freq,bx
        mov ebx,SB_Name[4*eax]  
        mov _DEV_Name,ebx       
        inc eax
        mov _DEV_MaxChannels,MAX_SSChannels ; Max number of channels for SB
        ret
GetSBInfo Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  SB_Init: Init Sound Blaster Device.                                    ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Init Error (No SB)                                    ณ
;ณ         CF Cleared  => Ok                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SB_init proc

	call SBDSPInit 
        jc SB_InitError
	
	mov SBIRQOn,0
	clc
	ret

SB_InitError:

        mov eax,DE_InitFail
        stc
	ret
SB_init Endp

;--

AsciiToDec Proc
	xor eax,eax
AsciiToDecLoop:
	movzx ebx,Byte Ptr[edi]
	inc edi
	sub bl,'0'
	add eax,ebx
	cmp Byte Ptr[edi],' '
	je AsciiToDecEnd
	cmp Byte Ptr[edi],0
	je AsciiToDecEnd
	imul eax,10
	jmp AsciiToDecLoop
AsciiToDecEnd:  
	ret 
AsciiToDec Endp

;--

AsciiToHex Proc
	xor eax,eax
AsciiToHexLoop:
	movzx ebx,Byte Ptr[edi]
	inc edi
	cmp bl,'9'
	jbe A2H_Number
	sub bl,'A'+10
	jmp A2H_Next
A2H_Number:
	sub bl,'0'
A2H_Next:       
	add eax,ebx
	
	cmp Byte Ptr[edi],' '
	je AsciiToHexEnd
	cmp Byte Ptr[edi],0
	je AsciiToHexEnd
	shl eax,4
	jmp AsciiToHexLoop
AsciiToHexEnd:  
	ret 
AsciiToHex Endp

;--

SBReadEnvVar Proc

        mov eax,Offset BlasterEnv
        call GetEnvOffset
        jc SBReadEnvVarErr

ReadEnvLoop:
	mov al,[edi]                ; get character from string
	inc edi
	or al,al                    ; end of string?
	jz SBReadEnvVarEnd

	and al,not 20h              ; convert to uppercase if a letter

	cmp al,'A'
	je Readport

	cmp al,'I'                  ; Ixx - IRQ number
	je Readirq

	cmp al,'D'                  ; Dx - DMA channel number
	je Readdma

	cmp al,'H'                  ; Hx - High DMA channel number
	je Readhighdma

	jmp Readenvloop

ReadPort:
	call AsciiToHex
	mov _DEV_BasePort,ax
	jmp ReadEnvLoop

ReadIRQ:
	call AsciiToDec
	mov _DEV_IRQ,al
	jmp ReadEnvLoop
ReadDMA:
	call AsciiToDec
        mov SBLowDMA,al
	jmp ReadEnvLoop
ReadHighDMA:
	call AsciiToDec
	mov SBHighDMA,al
	jmp ReadEnvLoop

SBReadEnvVarEnd:        
        clc
        ret

SBReadEnvVarErr:
        stc
        ret
SBReadEnvVar Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SB_StartOutput                                                          ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic function to call                                    ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error Code in EAX.                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SB_StartOutput proc
	mov PeriodicProc,esi

	call SBDSPInit
	mov eax,DE_InitFail
	jc SB_StartOutputError

	SBWrite TurnOnSpeaker
	mov eax,DE_InitFail
	jc SB_StartOutputError

; ****** Get SB Output rate ******

	cmp _DEV_Type,SB16     ; Sound Blaster 16?
	jae @@userate            ; if so, the sampling rate is directly used

	cmp _DEV_Type,SB20    ; Sound Blaster version < 2.0?
	jb @@limit1             ; if yes, rate limit is 21739Hz

	; Sound Blaster 2.0 or Pro - sampling rate limit is 43478Hz, so the
	; maximum Time Constant is 233
	mov ecx,233
	jmp @@timeconstant

@@limit1:
	; Sound Blaster 1.0 or 1.5 - sampling rate limit is 21739Hz, making
	; the maximum Time Constant 210
	mov ecx,210

@@timeconstant:
	; Calculate the Transfer Time Constant

	movzx ebx,_DEV_Freq
	test _DEV_Mode,DM_Stereo        ; use stereo?
	jz @@nostt              ; if yes, multiply rate with 2 when
	shl ebx,1               ; calculating Time Constant

@@nostt:
	xor edx,edx
	mov eax,1000000         ; eax = Time Constant =
	div ebx                 ; 256 - (1000000 / rate)
	neg eax
	add eax,256

	test eax,eax
	jns @@non1              ; Time Constant must be nonnegative
	xor eax,eax

@@non1: cmp eax,ecx             ; ecx is the maximum Time Constant
	jbe @@noa1
	mov eax,ecx             ; limit Time Constant to ecx value

@@noa1: mov SBTimeConst,al      ; store Transfer Time Constant

	mov ebx,256
	sub ebx,eax
	xor edx,edx
	mov eax,1000000         ; calculate actual playing rate
	div ebx                 ; (= 1000000 / (256 - TimeConstant))
	

	test _DEV_Mode,DM_Stereo        ; using stereo?
	jz @@nostt2
	shr eax,1               ; divide with 2 to get rate

@@nostt2:
	mov _DEV_Freq,ax
	jmp ProcBLen


@@userate:
	; Sound Blaster 16 - output uses the sampling rate directly

ProcBLen:

; Calculate required mixing and output buffer size: (1/50th of a second)

	mov ax,_DEV_Freq            ; ax = number of elements per second
	mov bx,50
	xor edx,edx
	div bx                      ; ax = number of elements in buffer

	add eax,3                   ; Align buffer size
	and eax,0FFFFFFFCh          ; To reduce Mixing job :)

	test _DEV_Mode,DM_Stereo
	jz  MonoBuffer
	shl eax,1         ; Stereo buffer is two times bigger
MonoBuffer:     

	mov MIX_BSize,eax ; MIX_BSize is not dependant of 8 or 16 bit output

	test _DEV_Mode,DM_16Bit
	jz  _8BitBuffer
	shl eax,1         ; 16 bit buffer is two times bigger
_8BitBuffer:

	mov SBBuffSize,eax

	mov eax,DMABuffer
	mov MIX_FBOffset,eax ; Final buffer is the DMA buffer

	call MIX_Start       ; Allocate MIX Buffers

;***** Set MONO/Stereo for SBPro *****

	cmp _DEV_Type,SBPro
	jne NotAnSBPro

	call SB_SetMono
	test _DEV_Mode,DM_Stereo
	jz NotAnSBPro
	call SB_SetStereo       
NotAnSBPro:

;***** Start the DMA *****
	
	mov al,1011000b    ;DMAAutoinit
	mov ah,_DEV_DMA 
	mov ecx,SBBuffSize
	shl ecx,1
	mov ebx,DMARealAddress

	call DMA_Setup

;***** Set SB IRQ ****

	mov SBIRQOn,1
	mov DataSel,ds

        GetIrq _DEV_IRQ,OldIRQ                 ; Get int 8 proc (IRQ 0)
	SetIrq _DEV_IRQ,cs,SB_IRQ              ; Set new Int 8  

	mov dl,_DEV_IRQ
	call IRQ_Enable

if (OS EQ KERNEL)
        movzx ebx,_DEV_IRQ
        call EnableCallBack
endif

;***** Start the SB  *****

	mov eax,MIX_BSize
	dec eax
	mov SBBlockLength,ax            ; SB DMA transfert size

	mov bx,_DEV_Type
	cmp bx,sb10                     ; Sound Blaster 1.0?
	je  @@v100                      ; if is, auto-initialize mode is not
					; available

	; use auto-initialize mode:

	mov SBAutoinit,1

	cmp bx,sb16                     ; Sound Blaster 16?
	je  @@v400                      ; if is, use DSP 4.00 playing mode
					; for all output modes

	cmp bx,sb20                     ; Sound Blaster 2.0 or Pro?
	jae @@v201                      ; if is, high-speed output is
					; available
	jmp @@v200

@@v100:
	; Sound Blaster 1.0 - play using mono single-cycle mode

	mov SBAutoinit,0
	call sbPlayMonoSingleCycle
	jmp @@playing

@@v200:
	; Sound Blaster 1.5 - play using mono auto-initialize mode
	call sbPlayMonoAutoinit
	jmp @@playing

@@v201:
	; Sound Blaster 2.0 or Pro - high-speed output is available
	test _DEV_Mode,DM_Stereo     ; use stereo?
	jnz @@plstereo               ; if yes, play using stereo mode

	cmp _DEV_Freq,22000          ; is sampling rate over 22000Hz?
	ja @@highspeed               ; if is, use high-speed mode

	; Sound Blaster 2.0 or Pro, mono, rate <= 22000Hz - play using mono
	; auto-initialize mode
	call sbPlayMonoAutoinit
	jmp @@playing

@@highspeed:
	; Sound Blaster 2.0 or Pro, mono, rate > 22000Hz - play using mono
	; high-speed (auto-initialize) mode
	call sbPlayMonoHighSpeed
	jmp @@playing

@@plstereo:
	; Sound Blaster Pro, stereo - play using stereo
	; high-speed auto-initialize mode
	call sbPlayStereo
	jmp @@playing

@@v400:
	; Sound Blaster 16 - use DSP v4.00 auto-initialize mode for all output
	; modes
	call sbPlay400

@@playing:
	clc
	ret
	
SB_StartOutputError:
	stc
	ret
SB_StartOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SB_StopOutput                                                           ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic proc to stop                                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error code in EAX.                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SB_StopOutput proc

	call SBDSPInit

        call MIX_Stop

	cmp SBIRQOn,0
	je NotRestIRQ

if (OS EQ KERNEL)
        movzx ebx,_DEV_IRQ
        call DisableCallBack
endif

	RestIRQ _DEV_IRQ,OldIRQ

NotRestIRQ:

	mov SBIRQOn,0

	clc
	ret
SB_StopOutput endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SB_DoNothing                                                            ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SB_DoNothing Proc
	clc
	ret
SB_Donothing Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SB_IRQ: Sound blaster IRQ (50/s)                                        ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SB_IRQ Proc

	push ds
	push es
	pushad

	mov ax,cs:DataSel
	mov ds,ax
	mov es,ax
	
; ** SB IRQ Acknowledge **

        mov dx,_DEV_BasePort
	add dx,DSP8AckPort
	in al,dx                ; acknowledge DSP interrupt (8 bit)
	inc dx
	in al,dx                ; acknowledge DSP interrupt (16 bit)

	cmp SBAutoinit,1
	je IRQAckEnd            ; Restart SB Output if not autoinit mode

	SBWrite 14h                      ; 8-bit PCM output
      
	mov bl,Byte Ptr SBBlockLength[0] ; block length low byte
	call SBDSPWrite                  
	mov bl,Byte Ptr SBBlockLength[1] ; block length high byte
	call SBDSPWrite 

IRQAckEnd:

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

        mov eax,1193180/50      ; 'Time' between 2 IRQ
	
	call [PeriodicProc]     ; Process module and mixing

if (OS EQ DOS4GW_ASM) OR (OS EQ DOS4GW_C)
        lss esp,Oldstack
endif

SB_IRQ_End:

; ** PC IRQ Acknowledge **

	mov al,20h              ; send End Of Interrupt command to PIC
	out 20h,al              
	mov al,20h              ; send EOI to PIC #2 (IRQ > 7)
	out 0A0h,al                
	
	popad
	pop es
	pop ds
	
	iretd
SB_IRQ ENDP

;***************************************************************
;********************  Internal functions **********************
;***************************************************************

;/***************************************************************************\
;*
;* Function:    sbPlayMonoSingleCycle
;*
;* Description: Starts playing the buffer using 8-bit mono Single-Cycle mode
;*
;\***************************************************************************/

SBPlayMonoSingleCycle Proc
	
	SBWrite SetTimeConst             ; set Transfer Time Constant
	SBWrite SBTimeConst              ; Time Constant

	SBWrite 14h                      ; 8-bit PCM output
      
	mov bl,Byte Ptr SBBlockLength[0] ; block length low byte
	call SBDSPWrite                  
	mov bl,Byte Ptr SBBlockLength[1] ; block length high byte
	call SBDSPWrite 

	clc
	ret
SBPlayMonoSingleCycle Endp

;/***************************************************************************\
;*
;* Function:    sbPlayMonoAutoinit
;*
;* Description: Starts playing the buffer using 8-bit Auto-initialize mode
;*
;\***************************************************************************/

sbPlayMonoAutoinit Proc

	SBWrite SetTimeConst            ; set DSP Transfer Time Constant
	SBWrite SBTimeConst             ; Transfer Time Constant

	SBWrite SetHSpeedSize           ; set DSP transfer block size
	mov bl,Byte Ptr SBBlockLength[0] ; block length low byte
	call SBDSPWrite                  
	mov bl,Byte Ptr SBBlockLength[1] ; block length high byte
	call SBDSPWrite 

	SBWrite 1Ch                     ; start 8-bit PCM output

	clc
	ret
SBPlayMonoAutoinit Endp

;/***************************************************************************\
;*
;* Function:    sbPlayMonoHighSpeed
;*
;* Description: Starts playing the buffer using 8-bit mono High-Speed
;*              Auto-initialize mode
;*
;\***************************************************************************/

sbPlayMonoHighSpeed Proc

	SBWrite SetTimeConst             ; set DSP transfer Time Constant (40h)
	SBWrite SBTimeConst              ; transfer Time Constant
	SBWrite SetHSpeedSize            ; set DSP transfer block size    (48h)

	mov bl,Byte Ptr SBBlockLength[0] ; block length low byte
	call SBDSPWrite                  
	mov bl,Byte Ptr SBBlockLength[1] ; block length high byte
	call SBDSPWrite                  

	SBWrite 90h                      ; 8-bit PCM high-speed output
	
	clc
	ret
SBPlayMonoHighSpeed Endp

;/***************************************************************************\
;*
;* Function:    sbPlayStereo
;*
;* Description: Starts playing the buffer using 8-bit stereo High-Speed
;*              Auto-initialize mode
;*
;\***************************************************************************/

sbPlayStereo Proc

	SBWrite SetTimeConst            ; set DSP transfer Time Constant
	SBWrite SBTimeConst             ; transfer Time Constant

	; save output filter status and turn it off:
;       mov     dx,_DEV_BasePort
;       add     dx,04h
;       mov     al,0Ch
;       out     dx,al
;       inc     dx
;       in      al,dx
;       or      al,20h
;       out     dx,al

	SBWrite SetHSpeedSize            ; set DSP transfer block size

	mov bl,Byte Ptr SBBlockLength[0] ; block length low byte
	call SBDSPWrite                  
	mov bl,Byte Ptr SBBlockLength[1] ; block length high byte
	call SBDSPWrite 

	SBWrite 90h                      ; 8-bit PCM high-speed output

	clc
	ret
SBPlayStereo ENDP

;/***************************************************************************\
;*
;* Function:    sbPlay400
;*
;* Description: Starts playing the buffer using the DSP 4.00 Auto-initialize
;*              transfer
;*
;\***************************************************************************/

SBPlay400 Proc

	SBWrite SetSampleRate           ; set DSP output sampling rate (41h)

	mov bl,byte Ptr _DEV_Freq[1]    ; sampling rate high byte
	call SBDSPWrite
	mov bl,byte Ptr _DEV_Freq[0]    ; sampling rate low byte
	call SBDSPWrite

	test    _DEV_Mode,DM_8bit       ; 8-bit mode?
	jnz     @@8bit

	SBWrite 0B4h                    ; 16-bit output
	test    _DEV_Mode,DM_Mono       ; mono?
	jnz     @@mono16
	SBWrite 30h                     ; 16-bit stereo signed PCM
	jmp     @@setlen
@@mono16:
	SBWrite 10h                     ; 16-bit mono signed PCM
	jmp     @@setlen

@@8bit:
	SBWrite 0C6h                    ; 8-bit output
	test    _DEV_Mode,DM_Mono       ; mono?
	jnz     @@mono8
	SBWrite 30h                     ; 8-bit stereo signed PCM
	jmp     @@setlen
@@mono8:
	SBWrite 10h                     ; 8-bit mono signed PCM

@@setlen:
	mov bl,byte Ptr sbBlockLength[0]  ; transfer length low byte
	call SBDSPWrite
	mov bl,byte Ptr sbBlockLength[1]  ; transfer length high byte
	call SBDSPWrite

@@err:
	ret
SBPlay400 Endp

SB_SetStereo Proc
	mov dx,_DEV_BasePort
	add dx,04h
	mov al,0Eh
	out dx,al          ; Slectionner le registre 0Eh
	inc dx
	in al,dx           ; Lecture registre 0Eh
	
	or al,2            ; Bit 1 … 1
	mov ah,al
		
	dec dx
	mov al,0Eh         ; mxrOutSetting
	out dx,al
	inc dx
	
	mov al,ah
	out dx,al          ; Sortie registre 0Eh
	ret
SB_SetStereo Endp

SB_SetMono Proc
	mov dx,_DEV_BasePort
	add dx,04h         ; MixAddrPort
	mov al,0Eh         ; mxrOutSetting
	out dx,al          ; Slectionner le registre 0Eh
	inc dx
	in al,dx           ; Lecture registre 0Eh
	
	and al,Not 2       ; Bit 1 … 0
	mov ah,al
		
	dec dx
	mov al,0Eh         ; mxrOutSetting
	out dx,al
	inc dx
	
	mov al,ah
	out dx,al          ; Sortie registre 0Eh
	ret
SB_SetMono ENDP

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SBWait: Wait before writing to the DSP                                  ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SBWait Proc
	mov dx,_DEV_BasePort
	add dx,DSPWritePort
	mov ecx,10000
WaitDSPLoop:
	in al,dx
	or al,al
	jns WaitDSPEnd
	loop WaitDSPLoop
	stc
	ret
WaitDSPEnd:
	clc
	ret
SBWait Endp 

SBDSPWrite Proc

	call SBWait
	jc SBDSPWriteErr
	mov al,bl
	out dx,al
SBDSPWriteErr:  
	ret
SBDSPWrite Endp


; !!! Out = ax !!!
SBDSPRead Proc
	mov dx,_DEV_BasePort
	add dx,DSPRStatPort
	mov ecx,10000
ReadWait:
	in al,dx
	or al,al
	js ReadOk
	loop ReadWait
	stc
	ret
ReadOk:
	add dx,(DSPReadPort-DSPRStatPort)
	in al,dx
	
	clc
	ret
SBDSPRead Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SBDSPInit: Initialise the Sound Blaster DSP                             ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SBDSPInit Proc
	mov dx,_DEV_BasePort
	add dx,DSPResetPort
	mov al,1
	out dx,al
	mov ecx,10
WaitInit:
	in al,dx
	loop WaitInit
	xor eax,eax
	out dx,al
	
	add dx,(DSPRStatPort-DSPResetPort)
	mov ecx,1000
InitReadWait:
	in al,dx
	test al,al
	js InitReadOk
	loop InitReadWait
	jmp SBDSPInitError
InitReadOk:

	add dx,(DSPReadPort-DSPRStatPort)
	mov ecx,1000
InitReadLoop:
	in al,dx
	cmp al,0AAh
	je SBDSPInited
	loop InitReadLoop
	jmp SBDSPInitError
SBDSPInited:

	clc
	ret

SBDSPInitError:
	stc
	ret
SBDSPInit Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SBGetVersion: Get the Sound Blaster DSP version.                        ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
SBGetVersion Proc

        SBWrite GetDSPVersion  ; Read SB DSP version
        jc SBGetVersionErr
        call SBDSPRead
        jc SBGetVersionErr
        mov bh,al
        call SBDSPRead
        jc SBGetVersionErr
        mov bl,al

        cmp bx,200h             ; DSP version < 2.00?
        jb IsSB10               ; if yes, SB version 1.0
        cmp bx,200h             ; DSP version 2.00?
        je IsSB15               ; if yes, SB version 1.5
        cmp bx,300h             ; DSP version < 3.00?
        jb IsSB20               ; if yes, SB version 2.0
        cmp bx,400h             ; DSP version < 4.00?
        jb IsSBPro              ; if yes, SB Pro

        mov _DEV_Type,SB16    ; DSP version >= 4.00 - Sound Blaster 16
        jmp SBGetVersionEnd
IsSB10:
        mov _DEV_Type,SB10
        jmp SBGetVersionEnd
IsSB15:
        mov _DEV_Type,SB15
        jmp SBGetVersionEnd
IsSB20:
        mov _DEV_Type,SB20
        jmp SBGetVersionEnd
IsSBPro:
        mov _DEV_Type,SBPro

SBGetVersionEnd:                
        clc
        ret
SBGetVersionErr:
        stc
        ret
SBGetVersion Endp

CODE32 ENDS
;=============================================================================
END
; SBDRV.ASM  (c) 1997 FreddyV/Useless