;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?       ?????????????? MIX.ASM ??????????????       ?
;            ?                                                   ?
;            ?              MIXED DEVICES PROCEDURES             ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   By Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code starts .................. 26/08/1996       ?
;            ?   Last update .................. 30/09/1997       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  cs:CODE32,ds:CODE32,es:CODE32

INCLUDE SETUP.INC

INCLUDE MIX.INC
INCLUDE USSVAR.INC
INCLUDE MEMORY.INC

INCLUDE UTILS.INC ; For the SetBorder functions (DEBUG...)

SLenExt      EQU 512  ; Length of the Sample 'extention'
TotalRep     EQU 64

;=============================================================================

Align 4

MIX_BSize    DD 0     ; Buffers size  (2 buffers)
MIX_BOffset  DD 0     ; Buffer adress (1 buffer )
MIX_FBOffset DD 0     ; Final buffers (2 buffers)
MIX_ActiveB  DW 0     ; Buffer to update (0/1)

MixDecIncr   DW 0
MixIntIncr   DD 0
MIX_Cnt      DD 0     ; MIX loop counter (in stereo)
MIX_LeftVol  DD 0

Mix_Ampli    DW DefAmpli ; DefAmpli is defined in SETUP.INC

MIX_VTOffset  DD 0     ; Volume table Offset
MIX_RVTOffset DD 0     ; Real volume table Offset
MIX_CFBOffset DD 0     ; Current Final Buffer Offset (1st or 2nd)

MIX_VChDecPtr   DW MAX_SSCHANNELS DUP (0)
MIX_VChIntIncr  DW MAX_SSCHANNELS DUP (0)
MIX_VChDecIncr  DW MAX_SSCHANNELS DUP (0)

MIX_VChleftVol  DB MAX_SSCHANNELS DUP (0)
MIX_VChrightVol DB MAX_SSCHANNELS DUP (0)

SmpData    DD 0
SmpLength  DD 0
SmpLoop    DD 0
SmpLoopEnd DD 0
SmpPointer DD 0

SmpEnd       DD 0   ;Sample end Offset
LoopLen      DD 0   ;Sample Loop Length

SmpType      DB 0   ;Sample Type

Align 4

;=============================================================================

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_GetAmpli: Get Amplification value.                                 ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: AX=Amplification                                                ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
MIX_GetAmpli Proc
        mov ax,MIX_Ampli
        ret
MIX_GetAmpli Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_SetAmpli: Do the volume table.                                     ?
;?                                                                         ?
;? Input: EAX Amplification value                                          ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
MIX_SetAmpli proc

        mov MIX_Ampli,ax
        cmp MIX_RVTOffset,0  ; If the Volume table is not allocated
        je MIX_SetAmpliEnd   ; it only store the amplification value

        or eax,eax
        je _AmpliZero

        mov ecx,eax
        mov eax,256*1000
        xor edx,edx
        div ecx

        jmp _AmpliOk        
_AmpliZero:        
        mov eax,65535
_AmpliOk:        

        shl eax,6
        mov ecx,eax          ; ecx=Ampli*64

        mov edi,MIX_VTOffset
        xor ebx,ebx
        xor edx,edx
VolLoop:                     ; 65 Loop
        xor eax,eax

ByteLoop:                    ; 256 Loop
        push eax
        movsx eax,al
        imul ebx             ; sample Value*65535*Volume
        idiv ecx             ; ax = (Sample value*65535*Volume)/(64*Ampli)
        stosw
        pop eax

        inc eax
        cmp ax,256
        jne ByteLoop

        add ebx,65536
        cmp ebx,65*65536
        jne VolLoop

MIX_SetAmpliEnd:
        clc
        ret
MIX_SetAmpli endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_Start                                                              ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

MIX_Start Proc

        mov MIX_ActiveB,0
; ** Clear the output buffer **

        mov ecx,MIX_Bsize
        mov edi,MIX_FBOffset
        test _DEV_Mode,DM_16Bit
        jnz ClearFBuff
        shr ecx,1
ClearFBuff:
        xor eax,eax
        test _DEV_Mode,DM_Signed
        jnz DoClearBuff
        mov eax,80808080h
DoClearBuff:
        push ds
        pop es
        cld
        rep stosd

; ** Allocate the mix buffer ** (16b for Fast Mode, 32 bit for Quality Mode)

        mov eax,MIX_Bsize
        shl eax,2            ; Dword buffer => *2
        U_Malloc eax
        mov MIX_BOffset,eax

        call MIX_CreateVolumeTable
        ret
MIX_Start Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_Stop                                                               ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

MIX_Stop Proc
        U_Free MIX_BOffset
        U_Free MIX_RVTOffset
        mov MIX_RVTOffset,0
        ret
MIX_Stop Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_CreateVolumeTable: Create the volume table. (Internal function)    ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
MIX_CreateVolumeTable proc

        U_Malloc 65*256*2+512 ; ~32Kb
        jc @@CVError
        mov MIX_RVTOffset,eax

        and eax,0FFFFFE00h
        add eax,512

        mov MIX_VTOffset,eax

        movzx eax,MIX_Ampli
        call MIX_SetAmpli

        clc
        ret
@@CVError:
        stc
        ret
MIX_CreateVolumeTable endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_LoadSample: Load sample data in memory with extension for speed.   ?
;?                                                                         ?
;? Input: ESI Sample data                                                  ?
;?        EDI Sample structure                                             ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
LoopStart dd 0

MIX_LoadSample proc
	push ebp
        mov ebp,edi

        mov SmpData,esi
        
        mov eax,SLength[ebp]
        mov SmpLength,eax 
        mov eax,SLoop[ebp]
        mov SmpLoop,eax
        mov eax,SLoopEnd[ebp]
        mov SmpLoopEnd,eax
        mov al,SType[ebp]
        mov SmpType,al

        call MIX_DoLoadSample   ; Load the sample data

        mov eax,SmpPointer
        mov SPointer[ebp],eax

        test SType[ebp],SM_Sustain
        je NoLoadSustainedSampleData

        mov eax,SLength[ebp]
        mov SmpLength,eax 
        mov eax,SSustain[ebp]
        mov SmpLoop,eax
        mov eax,SSustEnd[ebp]
        mov SmpLoopEnd,eax
        mov al,SType[ebp]
        shr al,2                ; Get the Sustain loop values...
        mov SmpType,al

        mov esi,SmpData
        call MIX_DoLoadSample   ; Load the sustained sample data

        mov eax,SmpPointer
        mov SSPointer[ebp],eax
        
NoLoadSustainedSampleData:

        or SFlag[ebp],SF_Loaded ; Sample is loaded
	pop ebp
        clc
        ret
MIX_LoadSample endp

MIX_DoLoadSample Proc
        test SmpType,SM_Loop
        jnz  LoadLooped

        mov eax,SmpLength
        add eax,SLenExt
        U_Calloc eax
        mov SmpPointer,eax

        push edi
        mov ecx,SmpLength
        mov edi,eax
        cld
        push ds
        pop es
        rep movsb               ; Copy Sample data
        pop edi

        jmp MIX_DoLoadSampleEnd
LoadLooped:                     ;** Load a looped sample **

        mov ebx,SmpLoopEnd
        mov eax,ebx
        mov SmpLength,ebx       ; Looped => Sample end is loop end

        mov edx,SmpLoop
        sub ebx,edx

        test SmpType,SM_Bidi
        jz   S_NotBidi
        add eax,ebx
S_NotBidi:
        add eax,SLenExt
        U_Malloc eax
        mov SmpPointer,eax

        mov LoopStart,eax
        mov edx,SmpLoop
        add LoopStart,edx

        push edi

        mov ecx,SmpLength
        mov edi,eax
        push ds
        pop es
        cld
        rep movsb               ; Copy Sample data

;** Now, extend the sample **

        test SmpType,SM_Bidi
        jz NoBidiExtend

        mov ecx,ebx
        dec esi
ReverseExtendLoop:
        mov al,[esi]
        dec esi
        mov [edi],al
        inc edi
        dec ecx
        jnz ReverseExtendLoop

        shl ebx,1

NoBidiExtend:

        mov edx,SLenExt
ExtendLoop:
        mov esi,LoopStart
        mov ecx,edx
        cmp ebx,edx
        jae BigLoop
        mov ecx,ebx
BigLoop:
        sub edx,ecx
        push ds
        pop es
        cld
        rep movsb
        or edx,edx
        jnz ExtendLoop

        pop edi

MIX_DoLoadSampleEnd:
        ret
MIX_DoLoadSample Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_FreeSample: Remove the sample data from memory.                    ?
;?                                                                         ?
;? Input: EDI Sample structure Offset                                      ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
MIX_FreeSample Proc
        test SFlag[edi],SF_Loaded
        jz MIX_FreeSampleEnd
        mov eax,SPointer[edi]
        U_Free eax
        mov eax,SSPointer[edi]
        or eax,eax
        jz NoFreeSustainedSampleData
        U_Free eax
NoFreeSustainedSampleData:        
        and SFlag[ebp],Not SF_Loaded ; Sample is released
MIX_FreeSampleEnd:
        ret
MIX_FreeSample Endp


;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  MIX_UpdateSound: Create the new output buffer.                         ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

; Here are my priority for the mixing:
;
; 1: The sound quality.  => Mixing is done in 16 bit
; 2: The speed.          => I use unrolled loops
; 3: The code size.      => To mix only in 16 bit save memory.
;
; Then, 8 bit output will be slower than 16 bit output
; but I can't do anything else. :(

MIX_UpdateSound proc
        SetBorder 1 ; !!!!

;** Get Current Final Buffer Offset **

        mov ecx,MIX_BSize
        test _DEV_Mode,DM_16Bit
        jz No16BitBuffer
        shl ecx,1
No16BitBuffer:

        mov eax,MIX_FBOffset
        cmp MIX_ActiveB,0
        je  Use_1stBuffer
        add eax,ecx
Use_1stBuffer:
        mov MIX_CFBOffset,eax

;*********************** 1st, Clear the MIX buffer ************************

        xor eax,eax         ; Clear the buffer using DWORD

        mov ecx,MIX_BSize   ; Get buffer size
        test _DEV_Mode,DM_Interp
        jnz Clean_Big_Buffer
        shr ecx,1           ; Only /2 because the MIX buffer is 16 bit !
Clean_Big_Buffer:

        mov edi,MIX_BOffset
        push ds
        pop es
        cld
        rep stosd

        SetBorder 2 ; !!!!

;**************** 2nd, Mix the samples into the MIX buffer ****************

        xor ebp,ebp
ChLoop:

        test VChControl[2*ebp],CC_StopVoice
        jz   NoStopVoice
        and  VChControl[2*ebp],Not (CC_StopVoice+CC_Playing)
NoStopVoice:

        test VChControl[2*ebp],CC_ChSample ; ** Start Sample ? **
        jz   NoStartVoice
        and VChControl[2*ebp],Not CC_ChSample
        or VChControl[2*ebp],CC_Playing
        mov MIX_VChDecPtr[2*ebp],0         ; Reset decimal pointer position
NoStartVoice:

        test VChControl[2*ebp],CC_ChPeriod ; ** Change Periode ? **
        jz NoChangeIncrements

        xor edx,edx
        mov eax,VChFreq[4*ebp]

        mov edx,10000h
        mul edx

        movzx ecx,_DEV_Freq   ; Sample Frequence/Mix Frequence
        div ecx
        mov MIX_VChDecIncr[2*ebp],ax
        shr eax,16
        mov MIX_VChIntIncr[2*ebp],ax

NoChangeIncrements:

        test VChControl[2*ebp],CC_ChPanning
        jnz ChangeVolPanning

        test VChControl[2*ebp],CC_ChVolume ;Change volume ?
        jz NoChangeVolume

ChangeVolPanning:

        movzx ebx,VChFVolume[ebp]
        mov MIX_VChRightVol[ebp],bl      ;If mono, Channel volume=Rigth Volume

        test _DEV_Mode,DM_Stereo
        jz NoChangeVolume

        movzx ecx,VChFPanning[ebp]      ; Get 'Final' panning value.
        mov eax,ecx

        inc eax
        mul bx
        shr eax,8
        mov MIX_VChLeftVol[ebp],al

        mov eax,256
        sub eax,ecx
        mul bx
        shr eax,8
        mov MIX_VChRightVol[ebp],al

NoChangeVolume:

        and VChControl[2*ebp],Not (CC_ChPeriod+CC_ChVolume+CC_ChPanning)

        test VChControl[2*ebp],CC_Playing
        jz NoChannelMIX

        call DoChannelMIX

NoChannelMIX:

        inc ebp
        cmp ebp,SSActiveChannels
        jne ChLoop

        SetBorder 3 ;!!!!

;**** 3rd, move 'sound' to final buffer (with 8 bit/unsigned convertion) ****

        mov ecx,MIX_BSize
        shr ecx,2
        mov esi,MIX_BOffset
        mov edi,MIX_CFBOffset

        mov ax,_DEV_Mode

        test ax,DM_Interp
        jnz Convert_32b_Buffer

Convert_16b_Buffer:

        test ax,DM_16bit
        jz ConvertTo8bit
        test ax,DM_Signed
        jz ConvertToUnsigned16

; * 16 bit signed to 16 bit signed, Easy :)

        shl ecx,1
        cld
        rep movsd

        jmp MIX_UpdateSoundEnd
ConvertToUnsigned16:

; * 16 bit signed to 16 bit unsigned

        mov edx,80008000h
Unsigned16Loop:
        mov eax,[esi]
        mov ebx,[esi+4]
        xor eax,edx
        xor ebx,edx
        mov [edi],eax
        mov [edi+4],ebx
        add esi,8
        add edi,8
        dec ecx
        jne Unsigned16Loop

        jmp MIX_UpdateSoundEnd
ConvertTo8bit:


        test ax,DM_Signed
        jz ConvertToUnsigned8

; * 16 bit signed to 8 bit signed

Signed8Loop:
        mov eax,[esi]
        mov ebx,[esi+4]
        mov [edi],ah
        shr eax,16
        mov [edi+1],ah
        mov [edi+2],bh
        shr ebx,16
        mov [edi+3],bh
        add esi,8
        add edi,4
        dec ecx
        jne Signed8Loop

        jmp MIX_UpdateSoundEnd
ConvertToUnsigned8:

; * 16 bit signed to 8 bit unsigned

        mov edx,80008000h
Unsigned8Loop:
        mov eax,[esi]
        mov ebx,[esi+4]
        xor eax,edx
        xor ebx,edx
        mov [edi],ah
        shr eax,16
        mov [edi+1],ah
        mov [edi+2],bh
        shr ebx,16
        mov [edi+3],bh
        add esi,8
        add edi,4
        dec ecx
        jne UnSigned8Loop

        Jmp MIX_UpdateSoundEnd

Convert_32b_Buffer:

If FastStereoOversampling Eq Yes
        test ax,DM_Stereo      ; Fast Stereo oversampling is 16 bit mix !!
        jnz Convert_16b_Buffer ; => Return to 16 bit buffer convert...
EndIf

        shl ecx,1
        add esi,2

        test ax,DM_16bit
        jz ConvertTo8bit_O
        test ax,DM_Signed
        jz ConvertToUnsigned16_O

; * 32 bit signed to 16 bit signed.

Signed16Loop_O:
        mov ax,[esi]
        mov bx,[esi+4]
        mov [edi],ax
        mov [edi+2],bx
        add esi,8
        add edi,4
        dec ecx
        jne Signed16Loop_O

        jmp MIX_UpdateSoundEnd

ConvertToUnsigned16_O:

; * 32 bit signed to 16 bit unsigned

        mov edx,8000h
UnSigned16Loop_O:
        mov ax,[esi]
        mov bx,[esi+4]
        xor eax,edx
        xor ebx,edx
        mov [edi],ax
        mov [edi+2],bx
        add esi,8
        add edi,4
        dec ecx
        jne UnSigned16Loop_O

        jmp MIX_UpdateSoundEnd
ConvertTo8bit_O:


        test ax,DM_Signed
        jz ConvertToUnsigned8_O

; * 16 bit signed to 8 bit signed

Signed8Loop_O:
        mov ax,[esi]
        mov bx,[esi+4]
        mov [edi],ah
        mov [edi+1],bh
        add esi,8
        add edi,2
        dec ecx
        jne Signed8Loop_O

        jmp MIX_UpdateSoundEnd
ConvertToUnsigned8_O:

; * 16 bit signed to 8 bit unsigned

        mov edx,8000h
Unsigned8Loop_O:
        mov ax,[esi]
        mov bx,[esi+4]
        xor eax,edx
        xor ebx,edx
        mov [edi],ah
        mov [edi+1],bh
        add esi,8
        add edi,2
        dec ecx
        jne UnSigned8Loop_O

        Jmp MIX_UpdateSoundEnd

MIX_UpdateSoundEnd:

;******************************* THE END *********************************

        SetBorder 0 ;!!!!

        xor MIX_ActiveB,1    ;Change Active buffer number
        ret
MIX_UpdateSound endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  DoChannelMix: Mix on channel.                                          ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

DoChannelMIX Proc

        mov esi,VChSmpAdress[4*ebp]

        mov eax,SPointer[esi]
        mov SmpPointer,eax
        add eax,SLength[esi]
        mov SmpEnd,eax

        test VChControl[2*ebp],CC_Release
        jnz Mix_CheckLoop

        xor eax,eax
        test SType[esi],SM_Sustain
        jz   Mix_CheckLoop          ; Sustain loop ?
        mov eax,SSPointer[esi]
        mov SmpPointer,eax
        add eax,SSustEnd[esi]
        mov SmpEnd,eax              ; Yes => Sample End is LoopEnd
        mov eax,SSustEnd[esi]
        sub eax,SSustain[esi]
        test SType[esi],SM_SBidi
        jz   Mix_NoLoop
        add SmpEnd,eax
        shl eax,1                   ; Bidi loop => loop 2 times bigger
        jmp MIX_NoLoop
        
MIX_CheckLoop:
        xor eax,eax
        test SType[esi],SM_Loop
        jz   Mix_NoLoop             ; Is it looped ?

        mov eax,SPointer[esi]
        mov SmpPointer,eax
        add eax,SLoopEnd[esi]
        mov SmpEnd,eax              ; Yes => Sample End is LoopEnd
        mov eax,SLoopEnd[esi]
        sub eax,SLoop[esi]
        test SType[esi],SM_Bidi
        jz   Mix_NoLoop
        add SmpEnd,eax
        shl eax,1                   ; Bidi loop => loop 2 times bigger
Mix_NoLoop:

        mov LoopLen,eax

        mov esi,SmpPointer
        add esi,VChSmpOffset[4*ebp]
        mov edi,MIX_BOffset

        xor eax,eax
        mov ah,MIX_VChLeftVol[ebp]
        mov MIX_LeftVol,eax         ; Save Left Volume for Stereo mixing

        mov ebx,MIX_VTOffset
        shr ebx,1
        xor eax,eax
        mov ah,MIX_VChRightVol[ebp]
        add ebx,eax                 ; ebx=256*Volume + Volume table Offset/2

        mov cx,MIX_VChDecIncr[2*ebp]
        mov MixDecIncr,cx
        movzx ecx,MIX_VChDecPtr[2*ebp]

        push ebp

        movzx ebp,MIX_VChIntIncr[2*ebp]
        mov MixIntIncr,ebp

        mov edx,MIX_BSize
        shr edx,2

; EDX buffer Size/4
; EBX Volume table Offset
; ESI Sample Pointer
; EDI Buffer Pointer
; CX  Decimal Sample Pointer
; CL  Decimal Sample Pointer
; CH  Decimal increment
; EBP Integer increment
; AX  used to move data

        test _DEV_Mode,DM_Interp     ; Use Interpolation (Quality mode ?)
        jz SkipInterpMix

        test _DEV_Mode,DM_Stereo
        jnz  CallMixStereoInt

        call DoMixMonoInt

        jmp SkipMixStereo
CallMixStereoInt:

        call DoMixStereoInt
        jmp SkipMixStereo

SkipInterpMix:
        test _DEV_Mode,DM_Stereo
        jnz  CallMixStereo

        call DoMixMono

        jmp SkipMixStereo
CallMixStereo:

        call DoMixStereo
SkipMixStereo:

        cmp LoopLen,0
        jne DoUpdateChannelVar
        cmp esi,SmpEnd
        jae DoStopVoice              ; Stop if sample End (not looped)

DoUpdateChannelVar:
        pop ebp

        mov MIX_VChDecPtr[2*ebp],cx
        mov edi,VChSmpAdress[4*ebp]
        sub esi,SmpPointer
        mov VChSmpOffset[4*ebp],esi

        ret
DoStopVoice:
        pop ebp
StopVoice:
        and VChControl[2*ebp],Not CC_Playing
        ret
DoChannelMix Endp



MixAdjustPos Proc
       cmp LoopLen,0
       je AdjustNotLooped

; ** Looped sample **
AdjustPosLooped:
       cmp esi,SmpEnd
       jb  AdjustPosLoopedOk
       sub esi,LoopLen
       jmp AdjustPosLooped
AdjustPosLoopedOk:

       cmp edx,TotalRep/4
       jb  StopMainMixLoop
       clc
       ret
; ** Not looped sample **
AdjustNotLooped:
       cmp esi,SmpEnd
       jae StopMainMixLoop

       cmp edx,TotalRep/4
       jb  StopMainMixLoop

       clc
       ret
StopMainMixLoop:
       stc
       ret
MixAdjustPos Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  DoMixMono: Do the mono mixing.                                         ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
DoMixMono Proc

        call MixAdjustPos
        jc   DoSlowMixMono

DoMixMonoLoop:

        call MonoRepMix    ; Do the fast mixing

        sub edx,TotalRep/4

        call MixAdjustPos
        jnc DoMixMonoLoop

DoSlowMixMono:
        or edx,edx
        jz DoMixMonoEnd    ; edx=0 -> End

        cmp LoopLen,0
        jne DoMixMonoLoop2
        cmp esi,SmpEnd
        jae DoMixMonoEnd   ; Stop if sample End (not looped)

DoMixMonoLoop2:            ; Continue the mixing (slower)
i=0
rept 4
        mov bl,[esi]
        add cx,MixDecIncr
        mov ax,[2*ebx]
        adc esi,ebp
        add [edi+2*i],ax
i=i+1
endm
        add edi,4*2
        dec edx
        jnz DoMixMonoLoop2

DoMixMonoEnd:
        ret
DoMixMono Endp


Align 4

MonoRepMix Proc

i=0
rept TotalRep
        mov bl,[esi]
        add cx,MixDecIncr
        mov ax,[2*ebx]
        adc esi,ebp
        add [edi+2*i],ax
i=i+1
endm
        add edi,2*TotalRep
        ret
MonoRepMix ENdp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  DoMixStereo: Do the stereo mixing.                                     ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

DoMixStereo Proc
        shr edx,1 ; Stereo => /2
        mov MIX_Cnt,edx

; We need One more register to store right channel volume
; so we use edx and the loop counter will be MIX_Cnt

        mov edx,MIX_VTOffset
        shr edx,1
        add MIX_LeftVol,edx

        mov edx,Mix_Cnt
        call MixAdjustPos
        jc   DoSlowMixStereo

DoMixStereoLoop:

        mov edx,MIX_LeftVol  ; Get Left volume
        call StereoRepMix    ; Do the fast mixing

        mov edx,MIX_Cnt      ; Restaure MIX loop counter
        sub edx,TotalRep/4

        call MixAdjustPos
        mov MIX_Cnt,edx      ; Save MIX loop counter
        jnc DoMixStereoLoop

DoSlowMixStereo:
        or edx,edx
        jz DoMixStereoEnd    ; edx=0 -> End

        cmp LoopLen,0
        jne DoMixStereo2
        cmp esi,SmpEnd
        jae DoMixStereoEnd   ; Stop if sample End (not looped)

DoMixStereo2:
        mov edx,MIX_LeftVol  ; Get Right volume

DoMixStereoLoop2:            ; Continue the mixing (slower)
i=0
rept 4
        mov bl,[esi]
        add cx,MixDecIncr
        mov ax,[2*ebx]
        adc esi,ebp
        mov dl,bl
        add [edi+4*i],ax
        mov ax,[2*edx]
        add [edi+4*i+2],ax
i=i+1
endm
        add edi,4*4
        dec MIX_Cnt
        jnz DoMixStereoLoop2

DoMixStereoEnd:
        ret
DoMixStereo Endp


Align 4

StereoRepMix Proc

i=0
rept TotalRep
        mov bl,[esi]
        add cx,MixDecIncr
        mov ax,[2*ebx]
        adc esi,ebp
        mov dl,bl
        add [edi+4*i],ax
        mov ax,[2*edx]
        add [edi+4*i+2],ax
i=i+1
endm
        add edi,4*TotalRep
        ret
StereoRepMix ENdp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  DoMixMonoInt: Do the mono mixing with interpolation. (oversampling)    ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
DoMixMonoInt Proc
        mov Mix_Cnt,edx

        call MixAdjustPos
        jc   DoSlowMixMonoInt

DoMixMonoIntLoop:

        call MonoIntRepMix    ; Do the fast mixing

        mov edx,Mix_Cnt
        sub edx,TotalRep/4

        call MixAdjustPos
        mov Mix_Cnt,edx
        jnc DoMixMonoIntLoop

DoSlowMixMonoInt:
        or edx,edx
        jz  DoMixMonoIntEnd   ; edx=0 -> End
        
        cmp LoopLen,0
        jne DoMixMonoIntLoop2
        cmp esi,SmpEnd
        jae DoMixMonoIntEnd   ; Stop if sample End (not looped)
        
DoMixMonoIntLoop2:            ; Continue the mixing (slower)
i=0
rept 4
        mov bl,[esi]
        movsx edx,word ptr [2*ebx]
        mov bl,[esi+1]
        movsx eax,word ptr [2*ebx]

        sub eax,edx
        imul eax,ecx
        shl edx,16
        add edx,eax	

        add [edi+4*i],edx

        add cx,MixDecIncr
        adc esi,ebp
i=i+1
endm
        add edi,4*4
        dec Mix_Cnt    ;edx
        jnz DoMixMonoIntLoop2

DoMixMonoIntEnd:
        ret
DoMixMonoInt Endp

Align 4

MonoIntRepMix Proc

i=0
rept TotalRep
        mov bl,[esi]               ; Get Sample data.
        movsx edx,word ptr [2*ebx]
        mov bl,[esi+1]             ; Get Next Sample data.
        movsx eax,word ptr [2*ebx]

        sub eax,edx                ; Do the 16 bit interpolation.
        imul eax,ecx
        shl edx,16
        add edx,eax

        add [edi+4*i],edx          ; 32 bit mixing.

        add cx,MixDecIncr
        adc esi,ebp
i=i+1
endm
        add edi,4*TotalRep
        ret
MonoIntRepMix ENdp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  DoMixStereoInt: Do the stereo mixing.                                     ?
;?                                                                         ?
;? Input: --                                                               ?
;?                                                                         ?
;? Output: --                                                              ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

DoMixStereoInt Proc
        shr edx,1 ; Stereo => /2
	mov MIX_Cnt,edx

; We need One more register to store right channel volume
; so we use edx and the loop counter will be MIX_Cnt

        mov edx,MIX_VTOffset
        shr edx,1
        add MIX_LeftVol,edx

        mov edx,Mix_Cnt
        call MixAdjustPos
        jc   DoSlowMixStereoInt

DoMixStereoIntLoop:

        mov edx,MIX_LeftVol     ; Get Left volume
        call StereoIntRepMix    ; Do the fast mixing

        mov edx,MIX_Cnt         ; Restaure MIX loop counter
        sub edx,TotalRep/4

        call MixAdjustPos
        mov MIX_Cnt,edx         ; Save MIX loop counter
        jnc DoMixStereoIntLoop

DoSlowMixStereoInt:
        or edx,edx
        jz DoMixStereoIntEnd    ; edx=0 -> End

        cmp LoopLen,0
        jne DoMixStereoInt2
        cmp esi,SmpEnd
        jae DoMixStereoIntEnd   ; Stop if sample End (not looped)

DoMixStereoInt2:
        mov edx,MIX_LeftVol     ; Get Right volume

DoMixStereoIntLoop2:            ; Continue the mixing (slower)
i=0
rept 4

If FastStereoOversampling Eq Yes
        movsx eax,byte ptr [esi]
        movsx ebp,byte ptr [esi+1]

        sub ebp,eax                ; Do the 8 bit interpolation.
        imul ebp,ecx
        shr ebp,16
        add eax,ebp

        mov bl,al
        mov ax,word ptr [2*ebx]
        add [edi+4*i],ax           ; 16 bit mixing. (Left)
        mov dl,bl
	mov ax,word ptr [2*edx]
        add [edi+4*i+2],ax         ; 16 bit mixing. (Right)
Else
        mov bl,[esi]               ; Get Sample data.
        movsx ebp,word ptr [2*ebx]
        mov bl,[esi+1]             ; Get Next Sample data.
        movsx eax,word ptr [2*ebx]

        sub eax,ebp                ; Do the 16 bit Left interpolation.
        imul eax,ecx
        shl ebp,16
        add ebp,eax

        add [edi+8*i],ebp          ; 32 bit mixing. (Left)

        mov dl,[esi]               ; Get Sample data.
        movsx ebp,word ptr [2*edx]
        mov dl,bl                  ; Get Next Sample data. bl ?????
        movsx eax,word ptr [2*edx]

        sub eax,ebp                ; Do the 16 bit Right interpolation.
        imul eax,ecx
        shl ebp,16
        add ebp,eax

        add [edi+8*i+4],ebp        ; 32 bit mixing. (Right)
EndIf
        add cx,MixDecIncr
        adc esi,MixIntIncr
i=i+1
endm
If FastStereoOversampling Eq Yes
        add edi,4*4                ; Move into the 16 bit buffer
Else
        add edi,8*4                ; Move Into the 32 bit buffer
EndIf
        dec MIX_Cnt
        jnz DoMixStereoIntLoop2

DoMixStereoIntEnd:
        ret
DoMixStereoInt Endp


Align 4

StereoIntRepMix Proc
i=0
rept TotalRep
If FastStereoOversampling Eq Yes
                                   ; ** 8 bit Oversampling **
        movsx eax,byte ptr [esi]
        movsx ebp,byte ptr [esi+1]

        sub ebp,eax                ; Do the 8 bit interpolation.
        imul ebp,ecx
        shr ebp,16
        add eax,ebp

        mov bl,al
        mov ax,word ptr [2*ebx]
        add [edi+4*i],ax           ; 16 bit mixing. (Left)
        mov dl,bl
        mov ax,word ptr [2*edx]
        add [edi+4*i+2],ax         ; 16 bit mixing. (Right)
Else
                                   ; ** 16 bit Oversampling **

        mov bl,[esi]               ; Get Sample data.
        movsx ebp,word ptr [2*ebx]
        mov bl,[esi+1]             ; Get Next Sample data.
        movsx eax,word ptr [2*ebx]

        sub eax,ebp                ; Do the 16 bit interpolation.
        imul eax,ecx
        shl ebp,16
        add ebp,eax

        add [edi+8*i],ebp          ; 32 bit mixing. (Left)

        mov dl,[esi]               ; Get Sample data.
        movsx ebp,word ptr [2*edx]
        mov dl,bl                  ; Get Next Sample data. bl ?????
        movsx eax,word ptr [2*edx]

        sub eax,ebp                ; Do the 16 bit interpolation.
        imul eax,ecx
        shl ebp,16
        add ebp,eax

        add [edi+8*i+4],ebp        ; 32 bit mixing. (Right)
EndIf
        add cx,MixDecIncr
        adc esi,MixIntIncr
i=i+1
endm
If FastStereoOversampling Eq Yes
        add edi,4*TotalRep         ; Move into the 16 bit buffer
Else
        add edi,8*TotalRep         ; Move Into the 32 bit buffer
EndIf
        ret
StereoIntRepMix ENdp


CODE32 ends
;=============================================================================
end
; MIX.ASM (c) 1997 FreddyV/Useless