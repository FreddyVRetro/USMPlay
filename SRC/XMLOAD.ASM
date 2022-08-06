;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ XMLOAD.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷      º
;            º                                                   º
;            º            Useless XM Loader (XM->USM)            º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 06/04/1996       º
;            º   Last update .................. 19/09/1996       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

PackPattern Equ Yes
FullLoad    Equ Yes     ; Yes => Load all (Players,trackers..)
                        ; No  => Load all needed for the module (Demos,games..)
INCLUDE ERR_CODE.INC
INCLUDE XMLOAD.INC

INCLUDE MEMORY.INC
INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC      ; Istruments and samples definition
INCLUDE USM.INC         ; Useless Module Structures Definition

INCLUDE LDEBUG.INC
INCLUDE UTILS.INC       ; For the writeln macro.

;----------------------------------------------------------------------------

XMH     DD 0
USMH    DD 0

XMOffset DD 0
USMFlags DW 0

;----------------------------------------------------------------------------

PCount DW 0
PTotal DW 0
PPtr   DD 0
PEnd   DD 0
PattSize  DD 0

XMPPtr DD 0

; XM Pattern Header.

XMPHLen DD 0
XMPType DB 0
XMProws DW 0
XMPsize DW 0

;----------------------------------------------------------------------------

ICount  DW 0
ITotal  DW 0
SCount  DW 0
SNumber DW 0

SampleTable DD 0

SfOffset    DD 0
XMIOffset   DD 0
USMIOffset  DD 0

; XM Instrument Header

ISize      DD 0
XMIName    DB 22 DUP (0)
IType      DB 0
INbSamples DW 0

; XM Samples Header

XMSLength  DD 0
XMSLoop    DD 0
XMSLoopLen DD 0
XMSVolume  DB 0
XMSFine    DB 0
XMSType    DB 0
XMSPanning DB 0
XMSRelNote DB 0
XMSRes     DB 0
XMSName    DB 22 DUP (0)

AVTypeConv DB 0,2,4,1

;=============================================================================

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  XM_LOAD: Load/convert an XM file. (XM->USM)                            ³
;³                                                                         ³
;³ Input: ESI file name/path or 'file' memory offset                       ³
;³        EAX Default panning (Not used in XM loader)                      ³
;³        EBX=0 Load from a file                                           ³
;³        EBX=1 Load from memory                                           ³
;³                                                                         ³
;³ Output: CF Set=> Error                                                  ³
;³         EAX returns the error number                                    ³
;³                                                                         ³
;³         CF Clear                                                        ³
;³         ESI pointer to the USM module                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;if _WATCOM
;XM_Load_ Proc
;else
XM_Load  Proc
;endif

        mov LoadMode,bl ;File/Memory loading

        MOpen ESI
        jc XMLoadErr

        ; *** Load the XM Header ***

        U_Calloc USMHeaderLen
        jc XMLoadErr
        mov USMH,eax

        U_Malloc XMHeaderLen
        mov XMH,eax
        jc XMLoadErr

        Mread eax,XMHeaderLen		;Read the XM Header
        jc XMLoadErr

        ; *** Convert XM Header -> USM Header ***

        mov esi,XMH
        mov edi,USMH

        mov eax,edi
        add eax,MSamplPtr
        mov SampleTable,eax

        mov MId[edi],'MLSU'
        mov MVersion[edi],USMVersion
        mov MTracker[edi],M_FT2

        If FullLoad eq Yes
        mov ecx,20/4
        add esi,XMName
        add edi,MName
        push ds
        pop es
        cld
        rep movsd               ;Convert the Module Name
        mov esi,XMH
        mov edi,USMH
        EndIf

        mov ax,XMVersion[esi]
        cmp ax,0104h
        jae XMVersionOk
        mov eax,LE_WrongVersion ;File Version Error !
        jmp XMLoadErr
XMVersionOk:
                                ;Set Panning Table
        push edi
        add edi,MChPan
        mov cx,Max_Channels/4
        xor eax,eax
        cld
        rep stosd	
        pop edi
                                ;Set Channel volume Table
        push edi
        add edi,MChVol
        mov ecx,Max_Channels
        mov al,64
        rep stosb
        pop edi

        mov ax,XMFlags[esi]
        and ax,00000000000000001b
        or  ax,F_InstrMode+F_BigGVolSlide+F_PlayedSmpVol
        mov MFlags[edi],ax
        mov USMFlags,ax

        Test USMFlags,F_Linear
        jnz UseLinearLimits
        mov MPeriodMin[edi],28              ; Minimum amiga period value  B-9
        mov MPeriodMax[edi],27392           ; Maximum amiga period value  C-0
        jmp AmigaLimitUsed
UseLinearLimits:        
;        mov MPeriodMin[edi],768             ; Minimum linear period value B-9
;        mov MPeriodMax[edi],768*11          ; Maximum linear period value C-0

        mov MPeriodMin[edi],0               ; Minimum linear period value B-9
        mov MPeriodMax[edi],768*10          ; Maximum linear period value C-0
AmigaLimitUsed:

        mov ax,XMChannels[esi]
        mov MChannels[edi],ax
        mov MUS_Channels,ax

        mov ax,XMSongLen[esi]
        mov MSongLen[edi],ax

        mov ax,XMPatterns[esi]
        mov MPatterns[edi],ax
        mov PTotal,ax           ;Save the Number of patterns

        mov ax,XMRestart[esi]
        mov MRestart[edi],ax    ;Restart Position

        mov ax,XMInstr[esi]
        mov MInstruments[edi],ax
        mov ITotal,ax           ;Save the number of instruments

        mov ax,XMTempo[esi]
        mov MTempo[edi],al      ;Song Tempo

        mov ax,XMBPM[esi]
        mov MBPM[edi],al        ;Song BPM

        mov MGVolume[edi],64*2

        mov eax,XMHSize[esi]
        add eax,XMHSize         ;Size from XMHeaderSize value
        mov XMOffset,eax
        MSetPos eax             ;Set Filepos to the 1st Pattern

        add esi,XMOrder
        add edi,MOrder
        mov cx,256/4
        cld
        rep movsd

        U_Free XMH

        call XM_LoadPatterns
        jc XMLoadErr

        call XM_LoadInstruments
        jc XMLoadErr

        mov esi,USMH            ;Returns a pointer to the Module...
        jmp XMLoadEnd

XMLoadErr:
        push eax
        MCLose                  ;Close the file
        pop eax

if _WATCOM
        mov _Error_Number,eax   ;Returns Error number
        xor eax,eax
        ret
else
        stc
        ret
endif

XMLoadEnd:
        MClose                  ;Close the file
        clc
        ret
;if _WATCOM
;XM_Load_ Endp
;else
XM_Load  Endp
;endif

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  XM_Loadpatterns: Load/convert XM patterns. (XM->USM)                   ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

XM_LoadPatterns Proc Near

        cmp PTotal,0
        je XMPatternEnd
        
        mov PCount,0

_LoadPatternsLoop:

        mov edx,Offset XMPHLen
        MRead edx,9

        mov eax,XMPHLen
        add XMOffset,eax

        movzx eax,XMProws

        mov eax,LE_PatternError  
        cmp XMProws,256
        ja XMPatternError
        cmp XMProws,0
        je XMPatternError        

        cmp XMPSize,0           ;XM Pattern Empty
        je XMPAtternEmpty

        movzx eax,XMProws
        mov bx,MUS_Channels
        mul bx
        mov bx,5
        mul bx                  ;rows*Channels*5 => Pattern date size

        add eax,USMPatternSize
        mov PattSize,eax        ;Total pattern size
        U_Calloc eax            ;Allocate USM Pattern Memory
        mov PPtr,eax

If PackPattern Eq No
        mov edi,USMH
        movzx edx,PCount
        mov MPattPtr[edi+4*edx],eax	;Save the Pattern Offset
EndIf

        movzx eax,XMPSize
        U_Malloc eax            ;Allocate the XM patter data buffer
        mov XMPPtr,eax

        movzx ecx,XMPSize
        MRead eax,ecx           ;Load the XM pattern data

        ; Convert the pattern XM->USM

        mov esi,XMPPtr
        mov edi,PPtr

        mov ax,PCount
        mov Pnumber[edi],ax
        mov ax,XMProws
        mov Prow[edi],ax

        If FullLoad eq yes
        mov PId[edi],'PLSU'
        mov eax,PattSize
        mov Psize[edi],eax
        endif

        mov PEnd,edi
        add PEnd,eax

        add edi,USMPatternSize

_Pconvert_loop:
        lodsb
        test al,10000000b
        jnz _Packed

        cmp al,0
        je _NoNote1
        cmp al,97
        jne _NoKeyOff1
        mov al,Key_Off
        jmp _NoNote1
_NoKeyOff1:
        add al,12       ;1 octave higher than IT modules.
_NoNote1:
        stosb           ;write note

        movsd           ;move Instr/vol/cmp/param
        jmp _PconvertEnd

_Packed:
        mov bl,al
        xor eax,eax

        shr bl,1
        jnc _noNote2

        lodsb
        cmp al,0
        je _NoNote2
        cmp al,97
        jne _NoKeyOff2
        mov al,Key_Off
        jmp _NoNote2
_NoKeyOff2:
        add al,12       ;1 octave higher than IT modules.
_NoNote2:
        stosb
;        shr bl,1
        mov ecx,4
_UnpackLoop:
        xor eax,eax
        shr bl,1
        jnc _noData
        lodsb
_noData:
        stosb
        loop _UnpackLoop

_PconvertEnd:

        cmp byte Ptr [edi-2],14     ; Convert Command Exy to Command 36+x
        jne No_ExtendedCommand
        mov al,[edi-1]
        shr al,4
        add al,36
        mov [edi-2],al
        and byte Ptr [edi-1],0Fh
No_ExtendedCommand:

        cmp byte Ptr [edi-2],_GVolume   ; Global volume*2 (0-80h, not 0-40h)
        jne No_GVolume
        shl byte Ptr [edi-1],1
No_GVolume:

        cmp edi,PEnd
        jb  _Pconvert_Loop

        U_Free XMPPtr

; Pack the pattern

If PackPattern Eq Yes
        mov esi,PPtr
        call LU_PackPattern

        mov edi,USMH                 ;Useless Module header Offset
        movzx edx,PCount             ;Get the pattern number
        mov MPattPtr[edi+4*edx],esi  ;Save the Pattern Offset
EndIf

XMPatternEmpty:

        movzx eax,XMPsize       ; Move into the file
        add XMOffset,eax

        MSetPos XMOffset

        inc PCount
        mov ax,PTotal
        cmp PCount,ax
        jne _LoadPatternsLoop   ; Pattern Loop

XMPatternEnd:
        clc
        ret

XMPatternError:
        stc
        ret

XM_LoadPatterns Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  XM_LoadInstruments: Load/convert XM instruments. (XM->USM)             ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

XMFine DW 8363,8370,8378,8385,8393,8400,8408,8416
       DW 8423,8431,8438,8446,8454,8461,8469,8476
       DW 8484,8492,8499,8507,8515,8523,8530,8538
       DW 8546,8553,8561,8569,8577,8584,8592,8600
       DW 8608,8615,8623,8631,8639,8646,8654,8662
       DW 8670,8678,8686,8693,8701,8709,8717,8725
       DW 8733,8741,8749,8756,8764,8772,8780,8788
       DW 8796,8804,8812,8820,8828,8836,8844,8852

       DW 7893,7900,7907,7915,7922,7929,7936,7943
       DW 7950,7958,7965,7972,7979,7986,7993,8001
       DW 8008,8015,8022,8030,8037,8044,8051,8059
       DW 8066,8073,8081,8088,8095,8102,8110,8117
       DW 8124,8132,8139,8146,8154,8161,8169,8176
       DW 8183,8191,8198,8205,8213,8220,8228,8235
       DW 8243,8250,8257,8265,8272,8280,8287,8295
       DW 8302,8310,8317,8325,8332,8340,8347,8355


XM_LoadInstruments Proc Near
        cmp ITotal,0
        je XMInstrumentsEnd
        
        mov ICount,0
        mov SNumber,0

        U_Malloc XMInstrumentSize	
        jc XM_LoadInstrErr
        mov XMIOffset,eax

_LoadInstrumentsLoop:

        MSetPos XMOffset
        jc XM_LoadInstrErr

        ;Load First Part

        mov edx,Offset ISize
        MRead edx,29
        jc XM_LoadInstrErr	

        ;Allocate Instrument Header

        U_Calloc USSInstrSize
        jc XM_LoadInstrErr
        mov USMIOffset,eax

        mov edi,USMH
        movzx edx,ICount
        mov MInstrPtr[edi+4*edx],eax	;Save the Instrument Offset

        ;Convert XM Instrument -> USM Instrument (First Part)
;call debug
        mov edi,USMIOffset

        mov eax,SampleTable
        mov ISTable[edi],eax            ;Pointer to sample offset table

If FullLoad eq Yes	
        mov IId[edi],'TSNI'
        add edi,IName
        mov esi,Offset XMIName
        mov ecx,22/4
        cld
        rep movsd
        mov edi,USMIOffset
        endif

        mov eax,ISize
        add XMOffset,eax                ;Move file pointer

        cmp INbSamples,0
        je  _XMNoSamples
        cmp SNumber,MAX_Samples
        je _XMNoSamples

        ; Load Second Part

        mov eax,XMIOffset
        Mread eax,XMInstrumentSize      ;Read XM Instrument Header
        jc XM_LoadInstrErr

        mov esi,XMIOffset
        mov eax,XMISSize[esi]           ;Sample Header Len
        mov bx,INbSamples
        mul bx                          ;eax <- samples * Sample Header len
        add eax,XMOffset                ;eax <- eax+File Offset
        mov SfOffset,eax                ;SfOffset <- Samples Data Start (in file)	

        ; Convert Second Part

        mov esi,XMIOffset
        mov edi,USMIOffset

        mov ax,SNumber
        inc ax                          ;Sample number is from 1 to 255.
        xor ecx,ecx
AddSNumberLoop:
        mov bl,XMISNumber[esi+ecx]
        add bl,al
        mov ISNumber[edi+ecx+12],bl
        inc ecx
        cmp ecx,120
        jne AddSNumberLoop


        mov IGVolume[edi],128
        
        mov ax,XMIVFadeOut[esi]
        mov IVFadeout[edi],ax

; Volume envelope

        mov al,XMIVType[esi]
        mov IVType[edi],al

        mov al,XMIVPoints[esi]
	mov IVPoints[edi],al

        mov al,XMIVSustain[esi]
        mov IVSustain[edi],al

        mov al,XMIVLoopStart[esi]
        mov IVLoopStart[edi],al

        mov al,XMIVLoopEnd[esi]
        mov IVLoopEnd[edi],al

; Panning Envelope

        mov al,XMIPType[esi]
        mov IPType[edi],al

        mov al,XMIPPoints[esi]
        mov IPPoints[edi],al

        mov al,XMIPSustain[esi]
        mov IPSustain[edi],al

        mov al,XMIPLoopStart[esi]
        mov IPLoopStart[edi],al

        mov al,XMIPLoopEnd[esi]
        mov IPLoopEnd[edi],al

; Do Fadeout with a key release ?

        test IVType[edi],E_On           ; If there is a volume envelope,
        jz NoFadeVolume                 ; do fadeout else notecut
        or IFlg[edi],IF_ReleaseFade
NoFadeVolume:

        call LU_Check_Instrument

        add esi,XMIVEnvelope
        add edi,IVEnvelope
        mov ecx,24*2/4
        cld
        rep movsd

        mov esi,XMIOffset
        mov edi,USMIOffset
        add esi,XMIPEnvelope
        add edi,IPEnvelope
        mov ecx,24*2/4
        cld
        rep movsd

        mov SCount,0
_LoadSamplesLoop:


        MSetPos XMOffset        ;Set file Poiner to Sample Header
        jc XM_LoadInstrErr
        add XMOffset,40

        mov edx,Offset XMSLength
        Mread edx,40            ;Read Sample header
        jc XM_LoadInstrErr

        U_Calloc USSSampleSize
        mov USMIOffset,eax
        mov edi,eax             ; Get Sample Header Offset

        mov esi,USMH
        movzx edx,SNumber
        mov MSamplPtr[esi+4*edx],edi	;Save the Sample Offset

        If FullLoad eq Yes
        mov SId[edi],'LPMS'
        add edi,SName
        mov esi,Offset XMSName
        mov ecx,22/4
        cld
        rep movsd
        mov edi,USMIOffset
        endif

        ;Convert XM Sample -> USM Sample

        mov eax,XMSLength       ; Convert Length And Loop
        mov SLength[edi],eax
        mov eax,XMSLoop
        mov SLoop[edi],eax
        add eax,XMSLoopLen
        mov SLoopEnd[edi],eax

        mov SVolume[edi],64     ; Sample Volume=64 (MAX)
        mov al,XMSVolume
        mov SDefVolume[edi],al
        mov al,XMSPanning
        mov SDefPanning[edi],al
        mov al,XMSRelNote
        mov SRelNote[edi],al

        xor bl,bl               ; Convert sample type ( 8/16bit, loop... )
        mov al,XMSType
        test al,00010000b
        jz _XMS8Bit
        or  bl,SM_16bit         ; Set 16 bit Sample
_XMS8bit:
        and al,00000011b
        cmp al,0
        je _XMSNoLoop
        or  bl,SM_Loop          ; Set sample Loop
        cmp al,1
        je _XMSNoLoop
        or  bl,SM_Bidi          ; Set Ping-Pong Loop
_XMSNoLoop:
        mov SType[edi],bl
        mov SFlag[edi],SF_Delta+SF_UsePanning

        movsx eax,XMSFine
        sar eax,1

        test USMFlags,F_Linear
        jnz FT2Fine
        and eax,07Fh
        movzx eax,XMFine[2*eax] ; FT2 -> ST3 frequency adjust value.
        jmp ST3FineDone
FT2Fine:
        or SFlag[edi],SF_Linear
ST3FineDone:
        mov SFine[edi],eax

; Sample auto vibrato

        mov esi,XMIOffset
        mov al,XMIVibType[esi]
        mov SVibType[edi],al

        mov al,XMIVibSweep[esi]
        mov SVibSweep[edi],al

        mov al,XMIVibdepth[esi]
        mov SVibdepth[edi],al

        mov al,XMIVibrate[esi]
        mov SVibrate[edi],al

        movzx eax,SVibType[edi]
        and al,3
        mov al,AVTypeConv[eax]
        mov SVibType[edi],al

        MSetPos SfOffset        ; Set file pointer to Sample Start
        jc XM_LoadInstrErr

        mov eax,XMSLength
        add SfOffset,eax

        inc SNumber             ; !!!!! Check if >255 !!!!!
        cmp SNumber,MAX_Samples
        je _XMNoSamples

        cmp SLength[edi],0
        je  NotLoadSample

        call LU_LoadSample     ; Load sample data.

NotLoadSample:

        ; ** Sample load end, load next sample **

        inc SCount
        mov ax,INbSamples
        cmp SCount,ax
        jne _LoadSamplesLoop

        mov eax,SfOffset
        mov XMOffset,eax        ; File Offset <- Sample Data Offset

_XMNoSamples:

        inc ICount
        mov ax,Itotal
        cmp ICount,ax
        jne _LoadInstrumentsLoop
        U_Free XMIOffset
        jc XM_LoadInstrErr

        mov esi,USMH
        mov ax,SNumber
        mov MSamples[esi],ax

XMInstrumentsEnd:

        clc
        ret
XM_LoadInstrErr:
        stc
        ret
XM_LoadInstruments Endp

CODE32 ENDS
;=============================================================================
end
; XMLOAD.ASM (c) 1997 FreddyV/Useless
