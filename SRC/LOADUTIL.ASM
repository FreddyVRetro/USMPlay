;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ   ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ LOADUTIL.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ             Useless Loaders Utilities             บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 06/04/1996       บ
;            บ   Last update .................. 30/12/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE USS.INC
INCLUDE USSVAR.INC
INCLUDE USM.INC

INCLUDE LOADUTIL.INC
INCLUDE MEMORY.INC

INCLUDE UTILS.INC

;=============================================================================

File_Open  DB 0
LoadMode   DB 0         ; 0 -> Load from a file, 1 -> Load from memory

MUS_MemOffset DD 0
MUS_File      DD 0
MUS_Offset    DD 0
MUS_Channels  DW 0

RowSize  DD 0
RowCount DD 0
OldPatternOffset DD 0
NewPatternOffset DD 0
NewPatternSize   DD 0

ChannelsUsed DB 0

SOffset       DD 0
SmpLength     DD 0
SPackedLength DW 0

;=============================================================================

Memoryfread Proc
        cmp ecx,0
        je MemoryfreadEnd
        push ecx
        mov esi,MUS_MemOffset
        add esi,MUS_Offset
        cld
        rep movsb
        pop ecx
        add MUS_Offset,ecx
MemoryfreadEnd:
        clc
        ret
Memoryfread Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ LU_LoadSample                                                           ณ
;ณ                                                                         ณ
;ณ Input: EDI Sample structure offset                                      ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

LU_LoadSample Proc
        Test SType[edi],SM_16Bit
        jz _LSNo16Bit

        shr SLoop[edi],1
        shr SLoopEnd[edi],1
        shr SLength[edi],1
        shr SSustain[edi],1
        shr SSustEnd[edi],1

        mov eax,SLoop[edi]
        cmp eax,SLoopEnd[edi]
        jne _LSLoopNotEmpty16
        and SType[edi],Not SM_Loop
_LSLoopNotEmpty16:

        mov eax,0
        mov ebx,0
        test Stype[edi],SM_Loop
        jz _LSNoLoop16
        mov eax,SLoopEnd[edi]
_LSNoLoop16:
        test Stype[edi],SM_Sustain
        jz _LSNoSustain16
        mov ebx,SSustEnd[edi]
_LSNoSustain16:
        cmp eax,ebx
        ja _UseLoopValue16
        mov eax,ebx
_UseLoopValue16:
        cmp eax,0
        je _LSLoopOk16
        test Stype[edi],SM_Loop
        je _LSLoopOk16
        cmp eax,SLength[edi]
        jae _LSLoopOk16
        inc eax                 ;to avoid loop click... ( On GUS )
        mov SLength[edi],eax    ;Adjust Sample Length (LoopEnd+1)
_LSLoopOk16:
        
        mov eax,SLength[edi]
        shl eax,1

        ; ******* 16 bit Sample *******
        push eax
        U_Malloc eax                 ;Allocate a buffer to load the sample.
        mov esi,eax
        mov Soffset,eax
        pop eax

        test Stype[edi],SM_Packed
        je NotPacked16
pushad
writeln '16 bit packed !'
waitkey
popad
NotPacked16:

        Mread esi,eax              ;Read sample data

        Test SFlag[edi],SF_Delta   ;Delta conversion ?
        jz   _NoDelta16

        xor eax,eax
        mov ecx,SLength[edi]
_Delta16Loop:                      ;Delta conversion Loop
        add ax,[esi]
        mov [esi],ax
        add esi,2
        dec ecx
        jnz _Delta16Loop

_NoDelta16:

        and SType[edi],Not SM_16Bit
        and SFlag[edi],Not SF_Delta

        push edi
        mov ecx,SLength[edi]
        mov esi,SOffset
        mov edi,esi
_8bitConvertLoop:               ;8 bit conversion Loop
        lodsw
        mov [edi],ah
        inc edi
        dec ecx
        jnz _8bitConvertLoop
        pop edi

        Test SFlag[edi],SF_Unsigned
        jz _Unsigned16
        mov esi,SOffset
        mov ecx,SLength[edi]
_UnsignedLoop16:                ;Unsigned to signed conversion loop
        mov al,[esi]
        xor al,80h
        mov [esi],al
        inc esi
        loop _UnsignedLoop16
        and SFlag[edi],Not SF_Unsigned
_Unsigned16:

        ;Appeler le loader de samples des drivers........

        mov esi,Soffset
        call USS_LoadSample

        U_Free Soffset

        ret
_LSNo16Bit:

        ; *******  8 bit Sample *******	

        mov eax,SLoop[edi]
        cmp eax,SLoopEnd[edi]
        jne _LSLoopNotEmpty8
        and SType[edi],Not SM_Loop
_LSLoopNotEmpty8:		

        mov eax,0
        mov ebx,0
        test Stype[edi],SM_Loop
        jz _LSNoLoop8
        mov eax,SLoopEnd[edi]
_LSNoLoop8:
        test Stype[edi],SM_Sustain
        jz _LSNoSustain8
        mov ebx,SSustEnd[edi]
_LSNoSustain8:
        cmp eax,ebx
        ja _UseLoopValue8
        mov eax,ebx
_UseLoopValue8:
        cmp eax,0
        je _LSLoopOk8        
        test Stype[edi],SM_Loop
        je _LSLoopOk8
        cmp eax,SLength[edi]
        jae _LSLoopOk8
        inc eax                 ;to avoid loop click... ( On GUS )
        mov SLength[edi],eax    ;Adjust Sample Length (LoopEnd+1)
_LSLoopOk8:

        U_Malloc SLength[edi]   ;Allocate a buffer to load the sample.
        mov esi,eax
        mov Soffset,eax

        test Stype[edi],SM_Packed
        je NotPacked8

pushad
        writeln '8 bit packed !'
        write 'Length: '
        mov eax,SLength[edi]
        call print_dec
        writeln

        mov eax,Offset SPackedLength
        Mread eax,2             ;Read the packed sample length.
        movzx ecx,SPackedLength

pushad
        write 'Packed Length: '
        mov eax,ecx
        call print_dec
        writeln
popad

        U_Malloc ecx            ;Allocate a buffer for the packed sample.

push esi
push edi

;call debug
        mov ecx,SLength[edi]

        mov edi,esi
        mov esi,eax

        movzx eax,SPackedLength
        Mread esi,eax

        call D_Decompress8BitData

        U_Free esi

        writeln
        waitkey

pop edi
pop esi

popad
        jmp PackedSmpLoaded8
NotPacked8:

        Mread esi,Slength[edi]  ;Read sample data

PackedSmpLoaded8:

        Test SFlag[edi],SF_Delta ;Delta conversion ?
        jz   _NoDelta8

        xor eax,eax
        mov ecx,SLength[edi]
_Delta8Loop:                    ;Delta conversion Loop
        add al,[esi]
        mov [esi],al
        inc esi
        loop _Delta8Loop
        and SFlag[edi],Not SF_Delta

_NoDelta8:

        Test SFlag[edi],SF_Unsigned
        jz _Unsigned8
        mov esi,SOffset
        mov ecx,SLength[edi]
_UnsignedLoop8:                 ;Unsigned to signed conversion loop
        mov al,[esi]
        xor al,80h
        mov [esi],al
        inc esi
        loop _UnsignedLoop8
        and SFlag[edi],Not SF_Unsigned
_Unsigned8:

        ;Call the Soundcard driver LoadSample function

        mov esi,Soffset
        call USS_LoadSample

        U_Free Soffset	
        ret
LU_LoadSample Endp

D_Decompress8BitData Proc

        pushad
pushad
write 'ecx '
mov eax,ecx
call print_dec
write ' esi '
mov eax,esi
call print_dec
write ' edi '
mov eax,edi
call print_dec
writeln
popad

;call debug
        
        mov ebp,ecx

        mov bx,900h
        xor ecx,ecx
        xor edx,edx

D_Decompress8BitData1:
        push ecx
        mov ax,[esi]
        mov cl,ch

        shr ax,cl
        pop ecx

        add ch,bh
        mov dl,ch
        and ch,7
        shr dl,3
        add esi,edx

        cmp bh,6
        ja D_Decompress8BitA

        shl ax,cl

        cmp al,80h
        je D_Decompress8BitDepthChange1

D_Decompress8BitWriteData2:
        sar al,cl

D_Decompress8BitWriteData:
        add bl,al
        mov [edi],bl

        inc edi
        dec ebp
        jnz D_Decompress8BitData1

pushad
write 'ecx '
mov eax,ecx
call print_dec
write 'esi '
mov eax,esi
call print_dec
write ' edi '
mov eax,edi
call print_dec
writeln
popad

        popad
        ret

D_Decompress8BitDepthChange1:
        mov al,ah
        add ch,3

        and al,7
        mov dl,ch

        and ch,7
        shr dl,3

        add esi,edx
        jmp D_Decompress8BitD

D_Decompress8BitA:
        cmp BH,8
        ja D_Decompress8BitC
        je D_Decompress8BitB

        shl AL,1
        cmp AL,78h
        jb D_Decompress8BitWriteData2
        cmp AL,86h
        ja D_Decompress8BitWriteData2

        shr AL,1
        sub AL,3Ch
        jmp D_Decompress8BitD

D_Decompress8BitB:
        Cmp AL,7Ch
        JB D_Decompress8BitWriteData
        Cmp AL,83h
        JA D_Decompress8BitWriteData

        Sub AL,7Ch

D_Decompress8BitD:
        mov cl,8
        inc ax

        cmp AL,BH
        SBB AL,0FFh
        mov BH,AL
        sub CL,AL
        adc CL,0

        jmp     D_Decompress8BitData1

D_Decompress8BitC:
        and ax,1FFh

        test ax,100h
        jz D_Decompress8BitWriteData

        Jmp D_Decompress8BitD

D_Decompress8BitData Endp


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ LU_Check_Instrument: Check if instrument values are correct.            ณ
;ณ                                                                         ณ
;ณ Input: EDI Instrument sructure offset.                                  ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู


LU_Check_Instrument Proc
        cmp IPPoints[edi],0
        jne NoEmptyPEnvelope
        and IPType[edi],Not E_On        ;Panning Envelope is Off
NoEmptyPEnvelope:        

        cmp IVPoints[edi],0
        jne NoEmptyVEnvelope
        and IVType[edi],Not E_On        ;Volume Envelope is Off
NoEmptyVEnvelope:  
        ret
LU_Check_Instrument Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ LU_PackPattern                                                          ณ
;ณ                                                                         ณ
;ณ Input: ESI Pattern to pack                                              ณ
;ณ                                                                         ณ
;ณ Output: ESI New pattern offset                                          ณ
;ณ         EAX Number of used channels in this pattern                     ณ
;ณ                                                                         ณ
;ณ         CF Set -> Error code in EAX                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

LU_PackPattern Proc
;        call debug

        mov ChannelsUsed,0

        mov OldPatternOffset,esi

        mov edx,PSize[esi]
        U_Malloc edx
        mov NewPatternOffset,eax
        mov edi,eax

        mov PId[edi],'PLSU'
        mov ax,Pnumber[esi]
        mov Pnumber[edi],ax

        movzx eax,Prow[esi]
        mov Prow[edi],ax
        mov RowCount,eax
        movzx edx,MUS_Channels
        lea edx,[edx+4*edx]    ; Change this if NoteSize<>5 !
        mov Rowsize,edx

        add esi,USMPatternSize
        add edi,USMPatternSize
        cld
        push ds
        pop es
RowLoop:
        mov ecx,RowSize
RowLoop2:
        dec ecx
        cmp byte ptr [esi+ecx],0
        jne PackRow
        cmp ecx,0
        jne RowLoop2

        mov byte Ptr [edi],Row_End
        inc edi
        add esi,RowSize

        jmp DoRowLoop
PackRow:
        mov bl,NoteSize
        mov ax,cx
        div bl
        inc al
        cmp al,ChannelsUsed
        jbe NoChangeChannelsUsed
        mov ChannelsUsed,al
NoChangeChannelsUsed:
        cmp al,byte Ptr MUS_Channels
        je RowNotPacked
        mul bl

        mov cx,ax
        mov edx,RowSize
        sub edx,ecx

        rep movsb
        mov byte ptr [edi],Row_End
        add esi,edx
        inc edi
        jmp DoRowLoop
RowNotPacked:
        mov ecx,RowSize
        rep movsb
DoRowLoop:
        dec RowCount
        jnz RowLoop

        sub edi,NewPatternOffset    ; edi <- New pattern size
        mov esi,NewPatternOffset
        mov PSize[esi],edi          ; save pattern size
        mov NewPatternSize,edi

        U_Free OldPatternOffset     ; Free the old pattern memory
        U_Malloc NewPatternSize     ; Allocate memory to copy the new pattern        

        push eax
        mov ecx,NewPatternSize
        mov esi,NewPatternOffset
        mov edi,eax
        cld
        rep movsb                   ; Copy the pattern
        U_Free NewPatternOffset     ; Free the Packed pattern memory
        pop esi
        movzx eax,ChannelsUsed
        ret
LU_PackPattern Endp

CODE32 ENDS
;=============================================================================
end
; LOADUTIL.ASM (c) 1997 FreddyV/Useless
