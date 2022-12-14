;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?     ?????????????? USMLOAD.ASM ??????????????     ?
;            ?                                                   ?
;            ?                 Useless USM Loader                ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   By Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code starts .................. 19/10/1996       ?
;            ?   Last Update .................. 31/08/1997       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

FullLoad Equ Yes        ; Yes => Load all (Players,trackers..)
                        ; No  => Load all needed for the module (Demos,games..)

INCLUDE ERR_CODE.INC
INCLUDE USMLOAD.INC

INCLUDE MEMORY.INC
INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC
INCLUDE USM.INC         ; Useless Module Structures Definition

;INCLUDE UTILS.INC

;=============================================================================

USMH        DD 0
SampleTable DD 0

;=============================================================================

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  USM_LOAD: Load an USM file.                                            ?
;?                                                                         ?
;? Input: ESI file name/path                                               ?
;?        EAX Default panning                                              ?
;?        EBX=0 Load from a file                                           ?
;?        EBX=1 Load from memory                                           ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         EAX returns the error number                                    ?
;?                                                                         ?
;?         CF Clear                                                        ?
;?         ESI pointer to the USM module                                   ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
USM_Load  Proc
        mov LoadMode,bl

        MOpen ESI
        jc USMLoadErr

        ; *** Load the USM Header ***

        U_Malloc USMHeaderLen
        jc USMLoadErr
        mov USMH,eax

        MSetPos 0               ; ! Tester MReadPos !
        Mread USMH,USMHeaderLen	; Read the USM Header
        jc USMLoadErr

        mov esi,USMH
        cmp MId[esi],'MLSU'
        mov eax,LE_WrongFormat
        jne USMLoadErr          ;Bad File Format.

        cmp MVersion[esi],USMVersion
        mov eax,LE_WrongVersion
        jne USMLoadErr

        call USM_LoadPatterns
        jc USMLoadErr

        call USM_LoadSamples
        jc USMLoadErr

        clc
        mov esi,USMH    ;Returns a pointer to the Module...
        jmp USMLoadEnd

USMLoadErr:
        push eax
        MCLose          ;Close the file
        pop eax

if _WATCOM
        mov _Error_Number,eax
        xor eax,eax
        ret
else
        stc
        ret
endif

USMLoadEnd:
        MClose          ;Close the file

        clc
        ret
USM_Load  Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  USM_Loadpatterns: Load USM patterns.                                   ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

LPId     DD 0                    ; Useless pattern Id 'USLP'
LPSize   DD 0
LPnumber DW 0
LProw    DW 0

MODPPtr DD 0

;Warning: PTotal must be >0

USM_LoadPatterns Proc Near

        mov esi,USMH

        xor ecx,ecx
LoadPatternsLoop:
        mov edi,MPattPtr[esi+4*ecx]
        cmp edi,0
        je NotLoadPattern

        pushad
        MSetPos edi
        mov eax,Offset LPid
        MRead eax,USMPatternSize
        popad

        U_Calloc LPSize           ; Allocate USM Pattern Memory
	jc LPError
        mov MPattPtr[esi+4*ecx],eax

        pushad
        push eax
        MSetPos edi
        pop eax
        MRead eax,LPSize
        popad

NotLoadPattern:

        inc ecx
        cmp cx,MPatterns[esi]
        jne LoadPatternsLoop	; Pattern Loop

        clc
        ret
LPError:
        stc
        ret
USM_LoadPatterns Endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  USM_LoadSamples: Load USM samples and instruments                      ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?

USM_LoadSamples Proc Near
        mov esi,USMH
        mov eax,esi
        add eax,MSamplPtr
        mov SampleTable,eax

        cmp MSamples[esi],0
        je NotLoadSamples

        xor ecx,ecx
LoadSamplesLoop:
        mov edi,MSamplPtr[esi+4*ecx]

        cmp edi,0
        je NotLoadSample

        U_Malloc USSSampleSize
	jc LPError
        mov MSamplPtr[esi+4*ecx],eax	;Save the Sample Offset

        pushad
        push eax
        MSetPos edi
        pop eax
        MRead eax,USSSampleSize
        popad

        mov edi,eax

        test SFlag[edi],SF_Loaded    ; Is sample data in the file ?
        jz NotLoadSample

        pushad
        MSetPos SPointer[edi]
        and SFlag[edi],Not SF_Loaded ; Sample data is not in memory
        call LU_LoadSample      ; Load sample data.
        popad

NotLoadSample:
        inc ecx
        cmp cx,MSamples[esi]
        jne LoadSamplesLoop

NotLoadSamples:


; Loads the instruments structures

        cmp MInstruments[esi],0
        je NotLoadInstruments

        xor ecx,ecx
LoadInstrumentsLoop:
        mov edi,MInstrPtr[esi+4*ecx]

        cmp edi,0
        je NotLoadInstrument

        U_Calloc USSInstrSize
	jc LSError
        mov MInstrPtr[esi+4*ecx],eax    ;Save the Instrument Offset

        pushad
        push eax
        MSetPos edi                     ;Seek file pointer to instrument pos
        pop eax
        MRead eax,USSInstrSize          ;Load the Instrument
        popad

        mov ebx,SampleTable
        mov ISTable[eax],ebx

NotLoadInstrument:
        inc ecx
        cmp cx,MInstruments[esi]
        jne LoadInstrumentsLoop

NotLoadInstruments:

        clc
        ret
LSError:
        stc
        ret
USM_LoadSamples Endp

CODE32 ENDS
;=============================================================================
end
; USMLOAD.INC (c) 1997 FreddyV/Useless
