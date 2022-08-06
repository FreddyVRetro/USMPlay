;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º    ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ USMPLAY.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷      º
;            º                                                   º
;            º              Useless Module Player                º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 09/08/1996       º
;            º   Last update .................. 25/01/1998       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME CS:CODE32,DS:CODE32

INCLUDE SETUP.INC
INCLUDE MUS_EFX.INC

INCLUDE ERR_CODE.INC
INCLUDE USMPLAY.INC

INCLUDE USS.INC
INCLUDE USSVAR.INC
INCLUDE USM.INC      ; USM File Format (USSVAR.INC must be included before)

INCLUDE MEMORY.INC   ; Used by USMP_FreeModule

INCLUDE UTILS.INC

;-----------------------------------------------------------------------------

; ** Synchro var **  (They are public)

_SynchroCount dd 0
_SynchroVal   db 0
_MusicEnd     db 0

;-----------------------------------------------------------------------------

; ** Current playing file infos **

USMOffset   dd 0 ; USM header offset
USMFlags    dw 0 ; USM file flags
USMTracker  dw 0 ; USM file 'source' Tracker
USMChannels dd 0 ; File channels

;-----------------------------------------------------------------------------

; ** Global player var **

UsmPlayVarStart:

BPMVal    dd 0 ; Module Tempo ( 1193180*5/(2*BPM) )
BPMCnt    dd 0 ; Timer Ticks counter
_BPM Label byte
BPM       db 0
_Speed Label byte
Speed     db 0 ; Module Speed
SpeedCnt  db 0 ; Tempo counter
TickCnt   db 0 ; Tick counter

PatternOffset dd 0 ; Current Pattern Offset
RowOffset     dd 0 ; Current Note Offset

_Order Label word
Order   dw 0    ; Current Order Pos (Can be used for synchro)
_Pattern Label word
Pattern dw 0    ; Current Pattern   (Can be used for synchro)
_Row Label Word
Row     dw 0    ; Current Row       (Can be used for synchro)
Rows    dw 0    ; Rows in current pattern

if UsePatternDelay              ; * SETUP *
PatternDelay db 0
EndIf
NextOrder    dw 0
NextRow      dw 0

CInstr  dw 0    ; Current Instrument number
CNote   dw 0    ; Current Note
if UseVolCol                    ; * SETUP *
CVolume dw 0    ; Current Volume
endif   ;UseVolCol
if UseVolEfx                    ; * SETUP *
CVComm  dw 0    ; Current Volume command
CVParam dw 0    ; Current Volume command parameter
endif   ;UseVolEfx
CComm   dw 0    ; Current Command
CParam  dw 0    ; Current command parameter

Do_SetSampleDef  db 0 ; Set Channel volume to sample Volume ?
Sample_Changed   db 0 ; Sample number changed ?

;-----------------------------------------------------------------------------

; ** Channels var **

_ChInstrument   label byte
ChInstrument    db MAX_PLCHANNELS DUP (0)  ;Channel Instrument
_ChNote         label byte
ChNote          db MAX_PLCHANNELS DUP (0)  ;Channel Note
_ChCommand      label byte
ChCommand       db MAX_PLCHANNELS DUP (0)  ;Channel Command
_ChVCommand     label byte
ChVCommand      db MAX_PLCHANNELS DUP (0)  ;Channel Volume Command
_ChVolume       label byte
ChVolume        db MAX_PLCHANNELS DUP (0)  ;Channel Volume
_ChPeriod       label word
ChPeriod        dw MAX_PLCHANNELS DUP (0)  ;Channel Period
_ChPanning      label byte
ChPanning       db MAX_PLCHANNELS DUP (0)  ;Channel Panning

ChRInstrument   db MAX_PLCHANNELS DUP (0)  ;Instrument of the current Row
ChRNote         db MAX_PLCHANNELS DUP (0)  ;Note of the current Row
if UseVolCol                    ; * SETUP *
ChRVolume       db MAX_PLCHANNELS DUP (0)  ;Volume of the current Row
endif   ;UseVolCol

ChBPMSlideData          db MAX_PLCHANNELS DUP (0) ; -- BPM Slide

if UseArpeggio                  ; * SETUP *
ChArpeggioData          db MAX_PLCHANNELS DUP (0) ; 00 Arpeggio
ChArpeggioPos           db MAX_PLCHANNELS DUP (0) ; 00 Arpeggio
endif   ;UseArpeggio

if (UsePortUp or UseITPitchUp)  ; * SETUP *
ChPortaUpData           db MAX_PLCHANNELS DUP (0) ; 01 Portamento Up
endif   ;(UsePortUp or UseITPitchUp)

if (UsePortDown or UseITPitchDn)        ; * SETUP *
ChPortaDownData         db MAX_PLCHANNELS DUP (0) ; 02 Portamento Down
endif   ;(UsePortDown or UseITPitchDn)

if (UsePortaNote or UseITPortaNote or UsePVolumeSlide or UseITPortVS or UseVPortaNote)
ChPortaToNoteData       db MAX_PLCHANNELS DUP (0) ; 03 PortaToNote
ChPortaToNotePeriode    dw MAX_PLCHANNELS DUP (0) ; 03 PortaToNote
endif ;(UsePortaNote or UseITPortaNote or UsePVolumeSlide or UseITPortVS or UseVPortaNote)

if (UseVibrato or UseFineVibrato or UseVVolumeSlide or UseITVibVS or UseVVibrato or UseVibType)
ChVibWave               db MAX_PLCHANNELS DUP (0) ; 04 Vibrato
ChVibSpeed              db MAX_PLCHANNELS DUP (0) ; 04 Vibrato
ChVibDepth              db MAX_PLCHANNELS DUP (0) ; 04 Vibrato
ChVibPos                db MAX_PLCHANNELS DUP (0) ; 04 Vibrato
endif

if (UseTremolo or UseTremType)  ; * SETUP *
ChTremWave              db MAX_PLCHANNELS DUP (0) ; 07 Tremolo
ChTremSpeed             db MAX_PLCHANNELS DUP (0) ; 07 Tremolo
ChTremdepth             db MAX_PLCHANNELS DUP (0) ; 07 Tremolo
ChTremPos               db MAX_PLCHANNELS DUP (0) ; 07 Tremolo
endif

ChSmpOffset             dw MAX_PLCHANNELS DUP (0)

ChVolumeSlideData       db MAX_PLCHANNELS DUP (0) ; 10 Volume Slide
ChChVolumeSlideData     db MAX_PLCHANNELS DUP (0) ; -- Channel Volume slide

ChGVolumeSlideData      db MAX_PLCHANNELS DUP (0) ; 17 Global VolumeSlide
ChPanningSlideData      db MAX_PLCHANNELS DUP (0) ; 25 Panning Slide
ChMRetrigSpeed          db MAX_PLCHANNELS DUP (0) ; 27 Multi Retrig
ChMRetrigParam          db MAX_PLCHANNELS DUP (0) ; 27 Multi Retrig
ChMRetrigCnt            db MAX_PLCHANNELS DUP (0) ; 27 Multi Retrig
ChTremorPos             db MAX_PLCHANNELS DUP (0) ; 29 Tremor
ChTremorLen             db MAX_PLCHANNELS DUP (0) ; 29 Tremor
ChTremorOff             db MAX_PLCHANNELS DUP (0) ; 29 Tremor
ChFVolumeSlideUpData    db MAX_PLCHANNELS DUP (0) ; 46 Fine Volume Slide Up
ChFVolumeSlideDownData  db MAX_PLCHANNELS DUP (0) ; 47 Fine Volume Slide Down
ChEFPortaUData          db MAX_PLCHANNELS DUP (0) ; 33 Extra fine Portamento
ChEFPortaDData          db MAX_PLCHANNELS DUP (0) ; 33 Extra fine Portamento

ChFPortaUpData          db MAX_PLCHANNELS DUP (0) ; 37 Fine Portamento Up
ChFPortaDownData        db MAX_PLCHANNELS DUP (0) ; 38 Fine Portamento Down
ChPatLoopRow            db MAX_PLCHANNELS DUP (0) ; 42 Pattern Loop
ChPatLoopCount          db MAX_PLCHANNELS DUP (0) ; 42 Pattern Loop

ChCommandTick           db MAX_PLCHANNELS DUP (0) ; All 'Tick based' commands

ChITPitchData           db MAX_PLCHANNELS DUP (0) ; --
ChITPitchUpData         db MAX_PLCHANNELS DUP (0) ; -- IT Portamento Up
ChITPitchDnData         db MAX_PLCHANNELS DUP (0) ; -- IT Portamento Down
ChITVolumeSlideData     db MAX_PLCHANNELS DUP (0) ; -- IT Volume Slide
ChITChVolumeSlideData   db MAX_PLCHANNELS DUP (0) ; -- IT Channel Volume Slide
ChITGVolumeSlideData    db MAX_PLCHANNELS DUP (0) ; -- IT Global VolumeSlide
ChITPanningSlideData    db MAX_PLCHANNELS DUP (0) ; -- IT Panning Slide
ChITMRetrigParam        db MAX_PLCHANNELS DUP (0) ; --
ChVVolumeSideParam      db MAX_PLCHANNELS DUP (0) ; -- IT (Fine) Volume Slide
                                                  ;       (in Volume Column)

ChVolCmdData            db MAX_PLCHANNELS DUP (0) ; Volume commands

UsmPlayVarEnd:

;----------------------------------------------------------------------------


;=============================================================================

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_LoadInternalModule: "Load" an internal USM file. (OBJ)             ³
;³                                                                         ³
;³ Input: ESI USM Module Offset                                            ³
;³                                                                         ³
;³ Output: ESI USM Module Offset                                           ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

USMP_LoadInternalModule  Proc

; ** Move the data pointers **

        mov eax,esi             ; eax=esi, do not change eax !

        xor ecx,ecx
MovePointersLoop:
        cmp MPattPtr[eax+4*ecx],0
        je NotMovePointer
        add MPattPtr[eax+4*ecx],eax
NotMovePointer:

        inc cx
        cmp ecx,MAX_Patterns+MAX_Samples+MAX_Instruments
        jne MovePointersLoop

; ** Set the pointers to sample table **

        mov edx,eax
        add edx,MSamplPtr
        xor ecx,ecx
SetISTableLoop:
        mov ebx,MInstrPtr[eax+4*ecx]
        or ebx,ebx
        je SkipSetISTable
        mov ISTable[ebx],edx
SkipSetISTable:
        inc ecx
        cmp ecx,MAX_Instruments
        jne SetISTableLoop

; ** "Load" samples data **

        xor ecx,ecx
LoadSamplesLoop:
        mov edi,MSamplPtr[eax+4*ecx]
        cmp edi,0
        je NotLoadSample

        test SFlag[edi],SF_Loaded    ; Is sample data in the file ?
        jz NotLoadSample
        and SFlag[edi],Not SF_Loaded ; Sample data is not in memory

        mov esi,SPointer[edi]
        add esi,eax

        pushad                       ; USM files samples are saved as delta
        mov ecx,SLength[edi]
        xor eax,eax
_DeltaLoop:
        add al,[esi]
        mov [esi],al
        inc esi
        loop _DeltaLoop
        and SFlag[edi],Not SF_Delta
        popad

        pushad
        call USS_LoadSample
        popad
NotLoadSample:

        inc cx
        cmp cx,MSamples[eax]
        jne LoadSamplesLoop

        mov esi,eax
        ret
USMP_LoadInternalModule  Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_FreeInternalModule:                                                ³
;³                                                                         ³
;³ Input: ESI USM Module Offset                                            ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;³ ! It only free the memory allocated for the samples.                    ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if UseFreeInternalModule        ; * SETUP *

USMP_FreeInternalModule  Proc

        mov eax,PE_NotUSM
        cmp MId[esi],'MLSU'      ;Is it a pointer do an USM Header ?
        jne USMP_FreeInternalModuleError

; ** Free the module samples **

        xor ecx,ecx
FreeIntSamplesLoop:
        mov eax,MSamplPtr[esi+4*ecx]
        or eax,eax
        jz FreeIntSampleSkip
        push ecx

        push eax
        mov edi,eax
        call USS_FreeSample ; ** Free Sample data **
        pop eax

        pop ecx
FreeIntSampleSkip:
        inc ecx
        cmp ecx,MAX_Samples
        jne FreeIntSamplesLoop

; ** Restore original 'file' pointers **

        xor ecx,ecx
RestorePointersLoop:
        cmp MPattPtr[esi+4*ecx],0
        je NotRestorePointer
        sub MPattPtr[esi+4*ecx],esi
NotRestorePointer:

        inc cx
        cmp ecx,MAX_Patterns+MAX_Samples+MAX_Instruments
        jne RestorePointersLoop

        clc
        ret
USMP_FreeInternalModuleError:
if _WATCOM
        mov _Error_Number,eax
        ret
else
        stc
        ret
EndIf
USMP_FreeInternalModule  Endp

EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_FreeModule: Remove a module from memory                            ³
;³                                                                         ³
;³ Input: ESI USM Module Offset                                            ³
;³                                                                         ³
;³ Output: CF => Error code in EAX                                         ³
;³         Error code in _Error_Number for WATCOM)                         ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if UseFreeModule                ; * SETUP *

USMP_FreeModule  Proc

        mov eax,PE_NotUSM
        cmp MId[esi],'MLSU'      ;Is it a pointer do an USM Header ?
        jne USMP_FreeModuleError

        mov USMOffset,esi

; ** Free the module patterns **
        xor ecx,ecx
FreePatternsLoop:
        mov eax,MPattPtr[esi+4*ecx]
        or eax,eax
        jz FreePatternsSkip
        push ecx
        U_Free eax
        pop ecx
FreePatternsSkip:
        inc ecx
        cmp ecx,MAX_Patterns
        jne FreePatternsLoop

; ** Free the module instruments **

        xor ecx,ecx
FreeInstrumentsLoop:
        mov esi,USMOffset
        mov eax,MInstrPtr[esi+4*ecx]
        or eax,eax
        jz FreeInstrumentSkip
        push ecx
        U_Free eax
        pop ecx
FreeInstrumentSkip:
        inc ecx
        cmp ecx,MAX_Instruments
        jne FreeInstrumentsLoop

; ** Free the module samples **

        xor ecx,ecx
FreeSamplesLoop:
        mov esi,USMOffset
        mov eax,MSamplPtr[esi+4*ecx]
        or eax,eax
        jz FreeSampleSkip
        push ecx

        push eax
        mov edi,eax
        call USS_FreeSample ; ** Free Sample data **
        pop eax
        U_Free eax            ; ** Free sample definition **

        pop ecx
FreeSampleSkip:
        inc ecx
        cmp ecx,MAX_Samples
        jne FreeSamplesLoop

; ** Free the module header **
        U_Free USMOffset

        clc
        ret
USMP_FreeModuleError:
if _WATCOM
        mov _Error_Number,eax
        ret
else
        stc
        ret
EndIf
USMP_FreeModule  Endp

EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_StartPlay                                                          ³
;³                                                                         ³
;³ Input: ESI USM Module Offset                                            ³
;³                                                                         ³
;³ Output: CF => Error code in EAX                                         ³
;³         Error code in _Error_Number for WATCOM)                         ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

USMP_StartPlay  Proc


;                       ** Module init **

; ** Check the file version. **

if IntroMode Eq No               ; * SETUP *
        mov eax,PE_NotUSM
        cmp MId[esi],'MLSU'      ;Is it a pointer do an USM Header ?
        jne USMP_StartPlayError

        mov eax,PE_WrongVersion  ;Is it the correct USM file version ?
        cmp MVersion[esi],USMVersion
        jne USMP_StartPlayError
endif   ;IntroMode

        mov USMOffset,esi
        mov ax,MFlags[esi]
        mov USMFlags,ax
        mov ax,MTracker[esi]
        mov USMTracker,ax
        movzx eax,MChannels[esi]
        mov USMChannels,eax

;                      ** USM Play init **

        push esi
        mov edi,Offset UsmPlayVarStart
        mov ecx,Offset UsmPlayVarEnd
        sub ecx,edi
        push ds
        pop es
        cld
        xor eax,eax
        rep stosb
        pop esi

; ** BPM/Tempo values **

        mov al,MBPM[esi]
        call ProcSetBPM              ; Set Initial BPM
        mov al,MTempo[esi]
        mov Speed,al                 ; Set Initial Speed
        dec al
        mov SpeedCnt,al

;                       ** Sound System init **

        push esi
        call USS_Init 
        pop esi

; ** Set the active channels number **
        mov eax,PE_Channels
        cmp MChannels[esi],MAX_PLCHANNELS
        ja USMP_StartPlayError


        mov eax,USMChannels
        cmp ax,_DEV_MaxChannels
        jbe CheckNNADCT
        movzx eax,_DEV_MaxChannels      ; The music has too many channels
CheckNNADCT:
if (UseNNA or UseDCT)           ; * SETUP *
        test MFlags[esi],F_UseNNA
        jnz NNADCTUsed
        test MFlags[esi],F_UseDCT
        jz NoNNADCTUsed
NNADCTUsed:
        movzx eax,_DEV_MaxChannels      ; NNA => Use _DEV_MaxChannels
NoNNADCTUsed:
endif   ;(UseNNA or UseDCT)
        call USS_SetActiveChannels
        jc USMP_StartPlayError

; ** Set default channel panning/control **
If UsePanningTable              ; * SETUP *
        push ebp
        xor eax,eax
        xor ebp,ebp
SetStartPanningLoop:
        mov al,MChPan[esi+ebp]

; Stopped channel ?
        cmp al,128
        jb  NotStopped
        sub al,128
; Set Stopped channel
NotStopped:

; Surround channel ?
        cmp al,100
        jne NotSurround
        mov al,64               ; Surround channel -> Set to mono
; Set surround channel
NotSurround:        

; 0-40h to 0-FFh
        cmp al,40h
        jne PannR
        mov al,0FFh
        jmp PannConverted
PannR:
        shl al,2
PannConverted:
        
        mov ChPanning[ebp],al
; Set panning
        call USS_SetPanning
        inc ebp
        cmp ebp,USMChannels
        jne SetStartPanningLoop
        pop ebp
endif   ;UseDefaultPanning

; ** Set default Channel volume **
if UseChannelVolume             ; * SETUP *
        push ebp
        xor eax,eax
        xor ebp,ebp
SetStartChVolLoop:
        movzx eax,MChVol[esi+ebp]

; Set channel volume
        call USS_SetChannelVolume
        inc ebp
        cmp ebp,USMChannels
        jne SetStartChVolLoop
        pop ebp
EndIf   ;UseChannelVolume

; ** Period limits **

        mov ax,MPeriodMin[esi]
        mov SSPeriodMin,ax
        mov ax,MPeriodMax[esi]
        mov SSPeriodMax,ax

; ** Global Volume **

If UseGlobalVolume
        mov al,MGVolume[esi]         ; Set Initial Global Volume
        call USS_SetGlobalVolume
EndIf

;                 ** Start the sound output **
        push esi
        mov esi,Offset USMP_PeriodicProc
        call USS_StartOutput            ; Start the sound output.
        pop esi
        jc USMP_StartPlayError

if _WATCOM
        mov _Error_Number,0
        ret
else
        clc
        ret
EndIf
USMP_StartPlayError:
if _WATCOM
        mov _Error_Number,eax
        ret
else
        stc
        ret
EndIf
USMP_StartPlay endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_StopPlay                                                           ³
;³                                                                         ³
;³ Input: --                                                               ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
USMP_StopPlay  Proc

        call USS_StopOutput
        ret
USMP_StopPlay Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_PrevOrder: Go to next music pattern.                               ³
;³                                                                         ³
;³ Input: --                                                               ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if Use_USMP_PrevOrder           ; * SETUP *

USMP_PrevOrder  Proc
        mov ax,Order
        dec ax
        js SkipPrevOrder
        mov NextOrder,ax
        mov NextRow,0
        mov al,Speed
        dec al
        mov SpeedCnt,al
SkipPrevOrder:
        ret
USMP_PrevOrder  Endp
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_NextOrder: Go to previous music pattern.                           ³
;³                                                                         ³
;³ Input: --                                                               ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if Use_USMP_NextOrder           ; * SETUP *

USMP_NextOrder  Proc
        mov ax,Order
        inc ax

        mov esi,USMOffset
        cmp ax,MSongLen[esi]
        je SkipNextOrder
        mov NextOrder,ax
        mov NextRow,0
        mov al,Speed
        dec al
        mov SpeedCnt,al
SkipNextOrder:
        ret
USMP_NextOrder Endp
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_SetOrder Set the current order number.                             ³
;³                                                                         ³
;³ Input: AX New order.                                                    ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if Use_USMP_SetOrder            ; * SETUP *

USMP_SetOrder  Proc
        mov esi,USMOffset
        cmp ax,MSongLen[esi]
        jae SkipSetOrder
        mov NextOrder,ax
        mov NextRow,0
        mov al,Speed
        dec al
        mov SpeedCnt,al
SkipSetOrder:
        ret
USMP_SetOrder  Endp
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ USMP_SetPosition Set the current order and row number.                  ³
;³                                                                         ³
;³ Input: AX New order.                                                    ³
;³        BX New Row.                                                      ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if Use_USMP_SetPosition         ; * SETUP *

USMP_SetPosition  Proc
        mov esi,USMOffset
        cmp ax,MSongLen[esi]
        jae SkipSetPosition
        mov NextOrder,ax
        cmp bx,Rows
        jae SkipSetPosition
        mov NextRow,bx
        mov al,Speed
        dec al
        mov SpeedCnt,al
SkipSetPosition:
        ret
USMP_SetPosition  Endp
EndIf

;***************************************************************
;********************  Internal functions **********************
;***************************************************************

USMP_PeriodicProc proc
        push ebp

        add BPMCnt,eax
BPMLoop:
        mov eax,BPMVal
        cmp BPMCnt,eax
        jb  NoProcess
        sub BPMCnt,eax

        call PlayerTick      ; Process the next Row or effect.
        call USS_UpdateInstr ; Do the instruments envelopes and Auto vibrato.

        jmp BPMLoop
NoProcess:

        call USS_UpdateOutput

        pop ebp
        ret
USMP_PeriodicProc Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ PlayerTick: Process a pattern change, a Row or an effect.               ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PlayerTick Proc

; ** Process Speed **

	inc SpeedCnt
	mov al,Speed
	cmp SpeedCnt,al
	jne DoEffects
	mov SpeedCnt,0

	mov TickCnt,0

; ** Process Pattern delay and music order **

if UsePatternDelay              ; * SETUP *
        cmp PatternDelay,0   ; * Pattern delay command *
	je  NoPatternDelay
	dec PatternDelay
	jmp DoEffects        ; Do not process the Row => Delay the pattern.
NoPatternDelay:
EndIf

	cmp NextOrder,-1     ; A pattern break or jump pattern command occurs
	jne ChangeOrder      ; => Jump to the needed order

	mov ax,Row
	cmp ax,Rows          ; If actual Row is pattern length,
	jb  NotChangeOrder

	mov NextRow,0        ; jump to the next order (with Row=0)
	movzx eax,Order
	inc eax
	mov NextOrder,ax     ; Next order is actual order+1

ChangeOrder:
	call DoChangeOrder   ; Change Order number.

NotChangeOrder:
	cmp NextRow,-1
	je  NotChangeRow
	call DoChangeRow     ; Change Row number.
NotChangeRow:

; ** Process Row **

	call ProcRow
	
; ** Go to next Row **
        inc Row
	ret

DoEffects:

	inc TickCnt

	xor ebp,ebp
DoEffectsLoop:

if UseVolEfx                    ; * SETUP *
        movzx edx,ChVCommand[ebp]
	cmp edx,MaxVolCmd
	jae NoDoVCmd
	call DoVolTable[4*edx]
NoDoVCmd:
endif   ;UseVolEfx

        movzx edx,ChCommand[ebp]
	cmp edx,MaxCmd
	jae NoDoCmd
	call DoCmdTable[4*edx]
NoDoCmd:

	inc ebp
	cmp ebp,SSActiveChannels
	jne DoEffectsLoop
	
	ret
PlayerTick Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ ProcRow: Process one pattern Row.                                       ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcRow proc
		
	xor ebp,ebp
ChannelLoop:

        mov esi,RowOffset

        or esi,esi
        jz StopEffects          ;RowOffset=0 => End of Row (Empty pattern)

; ** Check if it's the Row End (Row_End code) **
	movzx eax,byte ptr [esi]
        cmp al,Row_End
        jne DoReadChannelData

        add RowOffset,1
        jmp StopEffects          ;End of Row !
        
DoReadChannelData:
; ** Read Channel datas **

	add RowOffset,5         ;Go to the next channel datas

	mov CNote,ax
	mov ChRNote[ebp],al
        movzx eax,byte ptr [esi+1]
	mov CInstr,ax
        mov ChRInstrument[ebp],al
if UseVolCol
        movzx eax,byte ptr [esi+2]
	mov CVolume,ax
endif   ;UseVolCol
        
        movzx eax,byte ptr [esi+4]
	mov CParam,ax
	movzx eax,byte ptr [esi+3]

; If No Arpeggio, set CCom to 0FFh
	or eax,eax
	jnz NotArp
	cmp CParam,0
	jne NotArp
	mov al,0FFh
NotArp:
	mov CComm,ax

; ** Get Volume command value **

if UseVolCol
if UseVolEfx
        mov CVComm,0FFh
endif   ;UseVolEfx

        cmp CVolume,50h
	jbe No_VolCmd
if UseVolEfx
        mov ax,CVolume    ; Volume>=50h => Volume command
        sub ax,60h
	mov bx,ax
	shr ax,4
	mov CVComm,ax
        and bx,0Fh
	mov CVParam,bx
endif   ;UseVolEfx
        mov CVolume,0
No_VolCmd:
        mov ax,CVolume
        mov ChRVolume[ebp],al
endif   ;UseVolCol

; ** Restore the period (after an arpeggio or a vibrato)
        
        mov ax,CComm
        cmp ChCommand[ebp],al ; If actual command is previous command
	je  NoRestorePeriod   ; don't restore the period.
RestorePeriod:
        call USS_GetPeriod
	cmp ax,ChPeriod[2*ebp]
	je  NoRestorePeriod
	mov ax,ChPeriod[2*ebp]
;write 'RestPeriod !'
        call USS_SetPeriod
NoRestorePeriod:

; ** Start a new note if there is no Note Delay **

        cmp CComm,49    ; Delay Note => Do not Start sound !
	je NoStartNote

        call StartNote  ; Process Row Instrument, Note and Volume

NoStartNote:

;                  *** Process Volume command ***

if UseVolEfx
	movzx edx,CVComm
        movzx eax,CVParam
        mov ChVCommand[ebp],dl
	cmp edx,MaxVolCmd
	jae  NoProcVCmd
        call ProcVolTable[4*edx] ; Call command
NoProcVCmd:
endif   ;UseVolEfx

;                     *** Process Command ***

        movzx eax,CParam
	movzx edx,CComm

        or eax,eax               ; Check if Command=0 and paramater=0
        jnz NoCmdCheckOk
        or edx,edx
        jnz NoCmdCheckOk
        mov dl,0FFh              ; Comm and Param=0 => 
NoCmdCheckOk:        

        cmp edx,MaxCmd
	jae  NoProcCmd        
        
        push edx
        call ProcCmdTable[4*edx] ; Call Command
        pop edx
NoProcCmd:
        mov ChCommand[ebp],dl    ; Save this here so the command proc can
                                 ; check the previous command number

; ** Loop to the next channel **	
        
        inc ebp                  ; Next channel
        cmp ebp,USMChannels
	jne ChannelLoop          ; Loop

	ret

StopEffects:

StopEffectsLoop:
        mov ChCommand[ebp],0FFh
        mov ChVCommand[ebp],0FFh

        call USS_GetPeriod
        cmp ax,ChPeriod[2*ebp]
	je  NoRestorePeriod2
	mov ax,ChPeriod[2*ebp]
        call USS_SetPeriod
NoRestorePeriod2:

        inc ebp                  ; Next channel
        cmp ebp,USMChannels
        jne StopEffectsLoop
        ret
ProcRow endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ StartNote: Process Row Instrument, Note and Volume                      ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

StartNote Proc
        mov Do_SetSampleDef,0

;       **** Process Instrument ****

	cmp CInstr,0
	je NoInstrument
	
        movzx eax,CInstr

        mov Sample_Changed,0
        cmp al,ChInstrument[ebp]
        je NoSetSampleChanged
        mov Sample_Changed,1     ; Sample number changed
NoSetSampleChanged:

        mov ChInstrument[ebp],al ; Set new Instrument number.

; Now, retrig all needed  commands and values.
; (As it was not done in mxm play)

        mov Do_SetSampleDef,1	 ; Set Volume and Panning to Sample values.

        mov ChTremorPos[ebp],0   ; Retrig Tremor

        test USMFlags,F_NoMRetrReset
        jnz NoClearRetrigCnt
        mov ChMRetrigCnt[ebp],0  ; Clear multi retrig counter.
NoClearRetrigCnt:

if UseVibtype                    ; * SETUP *
        cmp ChVibWave[ebp],4     ; Retrig Vibrato ? (No if VibWave>4)
        jae NoRetrigVib
endif   ;UseVibtype
if (UseVibrato or UseFineVibrato or UseVVolumeSlide or UseITVibVS or UseVVibrato or UseVibType)
        mov ChVibPos[ebp],0      ; Retrig Vibrato
endif
NoRetrigVib:
if UseTremType                   ; * SETUP *        
        cmp ChTremWave[ebp],4    ; Retrig Tremolo ? (No if TremWave>4)
        jae NoRetrigTrem
endif   ;UseTremType
if (UseTremolo or UseTremType)   ; * SETUP *
        mov ChTremPos[ebp],0     ; Retrig Tremolo
endif
NoRetrigTrem:

NoInstrument:

;       **** Process Note **** ( Start Instrument )

        cmp CNote,Key_Off
        jne No_Key_Off
        call USS_KeyOff
        jmp NoteCmdEnd
No_Key_Off:
        cmp CNote,Note_Cut
        jne No_Note_Cut
        call USS_NoteCut
        jmp NoteCmdEnd
No_Note_Cut:
        cmp CNote,Note_Fade
        jne No_Note_Fade
        call USS_NoteFade
        jmp NoteCmdEnd
NoteCmdEnd:
        mov Do_SetSampleDef,0
        jmp NoNote
No_Note_Fade:

        cmp CNote,0
        je  NoNote
	
        cmp CComm,_ITPortaNote  ; Portamento to note
        je  NoNote
        cmp CComm,_PortaNote    ; Portamento to note
        je  NoNote
if UseVolEfx
        cmp CVComm,_VPortaNote  ; 'Volume' Portamento to note
        je  NoNote
endif   ;UseVolEfx

        mov Sample_Changed,0

        movzx ebx,CNote
        mov ChNote[ebp],bl

push ebp
        movzx eax,ChInstrument[ebp]
        call StartInstrument
pop ebp

NoNote:

; ** Start the sample with no note change **
if UseSChange                   ; * SETUP
        test USMFlags,F_SChange
        jz NoSChangeFlag
        cmp Sample_Changed,0
        je NoSChangeFlag

        movzx eax,CInstr
        call ChangeInstrument
        
NoSChangeFlag:        
endif   ;UseSChange

; ** Set Sample default values (Volume/Panning)  **
; *  It's done when an instrument number is set.  *


        cmp Do_SetSampleDef,0    ; Set Sample Default values ?
        je NoSetPanning

        call USS_InitInstrEnv    ; Retrig instrument envelopes.

        call USMP_GetSampleVolume ; Get channel default volume.
        jc NoSetPanning           ; C Flag On -> Sample don't exist

        mov ChVolume[ebp],al     ; Channel volume is sample volume.
        call USS_SetVolume
NoSetSampleVol:

        call USS_GetSamplePanning
        jc NoSetPanning

        mov ChPanning[ebp],al    ; Channel panning is sample panning.
        call USS_SetPanning
        jmp NoSetPanning

NoSetPanning:

;       **** Process Volume ****

if UseVolCol
        cmp CVolume,0
        je  NoVolume
        sub CVolume,10h

        mov ax,CVolume
        mov ChVolume[ebp],al
        call USS_SetVolume
NoVolume:
endif   ;UseVolCol
        ret
StartNote Endp


;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ GetInstrAdress:                                                         ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

GetInstrAdress Proc
        or eax,eax
        jz GetInstrAdressErr
	dec eax

        test USMFlags,F_InstrMode       ; Instrument mode ?
        jz UseSample

        cmp eax,MAX_Instruments         ; Is instrument number correct ?
        jae GetInstrAdressErr           ; Err: Incorrect instrument number

        mov esi,USMOffset
        mov eax,MInstrPtr[esi+4*eax]    ; Get instrument Offset

        jmp GetInstrAdressEnd
UseSample:

        cmp eax,MAX_Samples             ; Is sample number correct ?
        jae GetInstrAdressErr           ; Err: Incorrect instrument number

        mov esi,USMOffset
        mov eax,MSamplPtr[esi+4*eax]    ; Get instrument Offset
        
GetInstrAdressEnd:
        clc
        ret
GetInstrAdressErr:
        stc
        ret
GetInstrAdress Endp


;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ StartInstrument:                                                        ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

StartInstrument Proc

        call GetInstrAdress
        jc StartInstrumentEnd

        call USS_StartInstrument
        call USS_GetPeriod
        mov ChPeriod[2*ebp],ax

StartInstrumentEnd:
	ret
StartInstrument Endp


;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ ChangeInstrument: Changes the instrument                                ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseSChange                   ; * SETUP
ChangeInstrument Proc
        call GetInstrAdress
        jc ChangeInstrumentEnd
        
        call USS_ChangeInstrument
ChangeInstrumentEnd:
        ret
ChangeInstrument Endp
endif   ;UseSChange

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ DoChangeOrder: Changes the current Order                                ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DoChangeOrder proc
	movzx eax,NextOrder
	mov esi,USMOffset

	cmp ax,MSongLen[esi]
	jb  SongLengthOk
	mov _MusicEnd,1
	mov ax,MRestart[esi] ;Loop the song
SongLengthOk:
	mov Order,ax

	movzx eax,MOrder[esi+eax]
        mov Pattern,ax
        mov eax,MPattPtr[esi+4*eax]
	or eax,eax
	jnz PatternNotEmpty
        mov bx,64               ; Play a 64 Rows Empty pattern.
	jmp ChangeOrderEnd
PatternNotEmpty:
	mov bx,PRow[eax]
ChangeOrderEnd:
        mov PatternOffset,eax
        mov Rows,bx
	
	mov NextOrder,-1        ; Reset order value
	ret
DoChangeOrder endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ DoChangeRow: Changes the current Row                                    ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DoChangeRow proc
	movzx eax,NextRow
        mov edx,PatternOffset
        xor ebx,ebx
        cmp edx,ebx             
        je RowOffsetFound       ; PatternOffset=0 => RowOffset=0
        cmp PRow[edx],ax
        ja  RowNumberOk
        xor eax,eax             ; Wrong Row number ! (Row > Pattern length)
RowNumberOk:
        mov Row,ax
        add edx,USMPatternSize
        or eax,eax
        jz RowOffsetFound

GetRowOffsetLoop:
        mov ebx,USMChannels
ChnGetRowOffsetLoop:
        cmp byte Ptr [edx],Row_End
        jne @@NextChannel
        inc edx
        Jmp @@NextRow
@@NextChannel:
        add edx,NoteSize
        dec ebx
        jnz ChnGetRowOffsetLoop
@@NextRow:
        dec eax
        jnz GetRowOffsetLoop

;dwrite 'Row!=0'
RowOffsetFound:
        mov RowOffset,edx

        mov NextRow,-1          ; Reset Row value
	ret
DoChangeRow Endp


USMP_GetSampleVolume Proc

if UsePlayedSmpVol              ; * SETUP *
        test USMFlags,F_PlayedSmpVol
        jnz GetVolumeAsFT2

        test USMFlags,F_InstrMode
        jnz GetVolumeAsFT2

        movzx eax,ChInstrument[ebp]
        or eax,eax
        je USMP_GetSampleVolumeErr
        dec eax
        
        mov esi,USMOffset
        mov esi,MSamplPtr[esi+4*eax]
        or esi,esi
        je USMP_GetSampleVolumeErr

        movzx eax,SDefVolume[esi]        

        clc
        ret
GetVolumeAsFT2:
endif   ;UsePlayedSmpVol

        call USS_GetSampleVolume ; Get channel default volume.
        ret
USMP_GetSampleVolumeErr:
        stc
        ret
USMP_GetSampleVolume Endp

;                     ***********************
;                     * Commands processing *
;                     ***********************
;
; PT  : ProTracker
; ST2 : Scream Tracker 2
; ST3 : Scream Tracker 3
; FT2 : Fast Tracker 2
; IT  : Impulse Tracker

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Nothing                                    ³
;³                                                                         ³
;³ Compatible with: FT2                                                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ProcNothing proc
	ret
ProcNothing endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set Tempo command                          ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcSetTempo proc
;if UseSetTempo                  ; * SETUP *
        or al,al
        jz NoSetTempo
        mov Speed,al
NoSetTempo:
;EndIf   ;UseSetTempo
        ret
ProcSetTempo endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set BPM command / BPM Slide                ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITSetBPM                  ; * SETUP *
ProcITSetBPM proc
        or al,al
        je UseOldBPMSlideData
        mov ChBPMSlideData[ebp],al
UseOldBPMSlideData:        
        cmp al,20h
        jbe ProcITSetBPMEnd
        call ProcSetBPM
ProcITSetBPMEnd:        
        ret
ProcITSetBPM endp
else
ProcITSetBPM Equ ProcNothing
EndIf   ;UseITSetBPM

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set BPM command                            ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcSetBPM proc
        or al,al
        jz NoProcSetBPM
        mov BPM,al
        movzx ebx,al
        shl bx,1
        xor edx,edx
        mov eax,1193180*5
        div ebx
        mov BPMVal,eax
NoProcSetBPM:
        ret
ProcSetBPM endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process Set Tempo/BPM command                        ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcSetTempo_BPM proc
;if UseSetBPM                    ; * SETUP *
        cmp al,20h      ; If Speed>20h, Set BPM
	jb SetTempo
	jmp ProcSetBPM
SetTempo:
;EndIf   ;UseSetBPM
;if UseSetTempo                  ; * SETUP *
        mov Speed,al
;EndIf
        ret
ProcSetTempo_BPM endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Arpeggio command                           ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseArpeggio                  ; * SETUP *
ProcArpeggio proc
	mov ChArpeggioData[ebp],al
	mov ChArpeggioPos[ebp],0
	jmp DoArpeggio
	ret
ProcArpeggio endp
else
ProcArpeggio Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process IT Portamento command                      ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility :     x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if (UseITPitchUp or UseITPitchDn or UseITPortaNote)     ; * SETUP *
ProcITPitch Proc
        or al,al
	jz ProcITPitchNext
	mov ChITPitchData[ebp],al
ProcITPitchNext:
	mov al,ChITPitchData[ebp]
if UseITPitchDn                 ; * SETUP *
        cmp dl,_ITPitchDn
        je ProcITPitchDn
EndIf   ;UseITPitchDn
if UseITPitchUp                 ; * SETUP *
        cmp dl,_ITPitchUp
        je ProcITPitchUp
EndIf   ;UseITPitchUp
if UseITPortaNote               ; * SETUP *
        cmp dl,_ITPortaNote
        je ProcPortaNote
EndIf   ;UseITPortaNote
        ret
ProcITPitch Endp
else
ProcITPitch Equ ProcNothing
EndIf   ;(UseITPitchUp or UseITPitchDn or UseITPortaNote)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process IT Portamento Up command                     ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility :     x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITPitchUp                 ; * SETUP *
ProcITPitchUp proc
        or al,al
	jz ProcITPitchUpNext
	mov ChITPitchUpData[ebp],al
ProcITPitchUpNext:
	mov ChPortaUpData[ebp],0
	mov al,ChITPitchUpData[ebp]
        mov bl,al
        and bl,0F0h
        cmp bl,0F0h             ; FFx Fine portamento Up
        jne NoITFinePitchUp
        and al,0Fh
        jmp ProcFPortUp
NoITFinePitchUp:
        cmp bl,0E0h             ; FEx Extra fine portamento down
        jne NoITEFinePitchUp
        and al,0Fh
        or al,10h               ; 1, Extra fine portamento Up
        jmp ProcEFPort
NoITEFinePitchUp:        
        jmp ProcPortUp
        
ProcITPitchUp endp
else
ProcITPitchUp Equ ProcNothing
EndIf   ;UseITPitchUp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process IT Portamento Down command                   ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility :     x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITPitchDn                  ; * SETUP *
ProcITPitchDn proc
	or al,al
	jz ProcITPitchDnNext
	mov ChITPitchDnData[ebp],al
ProcITPitchDnNext:

        mov ChPortaDownData[ebp],0
	mov al,ChITPitchDnData[ebp]
        mov bl,al
        and bl,0F0h
        cmp bl,0F0h             ; FFx Fine portamento Down
        jne NoITFinePitchDown
        and al,0Fh
        jmp ProcFPortDown
NoITFinePitchDown:
        cmp bl,0E0h             ; FEx Extra fine portamento Down
        jne NoITEFinePitchDown
        and al,0Fh
        or al,20h               ; 2, Extra fine portamento Down
        jmp ProcEFPort
NoITEFinePitchDown:
        jmp ProcPortDown
        ret
ProcITPitchDn endp
else
ProcITPitchDn Equ ProcNothing
EndIf   ;UseITPitchDn

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Portamento Up command                      ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePortUp or UseITPitchUp)  ; * SETUP *
ProcPortUp proc
	or al,al
	jz ProcPortUpEnd
	mov ChPortaUpData[ebp],al
ProcPortUpEnd:
	ret
ProcPortUp endp
else
ProcPortUp Equ ProcNothing
EndIf   ;(UsePortUp or UseITPitchUp)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Portamento Down command                    ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePortDown or UseITPitchDn)        ; * SETUP *
ProcPortDown proc
	or al,al
	jz ProcPortDownEnd
	mov ChPortaDownData[ebp],al
ProcPortDownEnd:
	ret
ProcPortDown endp
else
ProcPortDown Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Porta To Note command                      ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePortaNote or UseITPortaNote)     ; * SETUP *
ProcPortaNote proc
        or al,al
        jz ProcPortaNoteNext
        mov ChPortaToNoteData[ebp],al
ProcPortaNoteNext:
        cmp CNote,0
        je ProcPortaNoteEnd
        movzx ebx,CNote
        call USS_GetNotePeriod  ; Get the period from the note number
        jc ProcPortaNoteEnd
        mov ChPortaToNotePeriode[2*ebp],ax
ProcPortaNoteEnd:
	ret
ProcPortaNote endp
else
ProcPortaNote Equ ProcNothing
EndIf   ;(UsePortaNote or UseITPortaNote)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o               Process Vibrato-Fine vibrato commands                    ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Note: Vibrato is retrig at Instrument start

if (UseVibrato or UseFineVibrato)       ; * SETUP *
ProcVibrato proc
        mov bl,al
	test al,0F0h
	jz NoVibSpeed
	shr bl,4
        shl bl,2
        mov ChVibSpeed[ebp],bl
NoVibSpeed:
	test al,0Fh
	jz NoVibDepth
	and al,0Fh
        cmp dl,_FineVibrato     ; Is it fine vibrato command ?
        je UseFineDepth
        shl al,2
UseFineDepth:
if UseFinerVibrato              ; * SETUP *
        test USMFlags,F_FineVibrato
        jnz FinerVibrato
endif   ;UseFinerVibrato
        shl al,1
FinerVibrato:
        shr ChVibDepth[ebp],1
        mov ChVibDepth[ebp],al

NoVibDepth:

if UseFinerVibrato              ; * SETUP *
        test USMFlags,F_FineVibrato
        jz NoFinerVibrato
        call DoVibrato
NoFinerVibrato:
endif   ;UseFinerVibrato
        ret
ProcVibrato endp
else
ProcVibrato Equ ProcNothing
EndIf   ;(UseVibrato or UseFineVibrato)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Tremolo command                            ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility :         x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Note: Tremolo is "Retriged" at Instrument start (in FT2).

if UseTremolo                   ; * SETUP *
ProcTremolo proc
	mov bl,al
	test al,0F0h
	jz NoTremSpeed
        shr bl,4
        shl bl,2
        mov ChTremSpeed[ebp],bl
NoTremSpeed:
	test al,0Fh
	jz NoTremDepth
	and al,0Fh
	mov ChTremdepth[ebp],al
NoTremDepth:
	ret
ProcTremolo endp
else
ProcTremolo Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set Panning command                        ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseSetPanning1               ; * SETUP *
ProcSetPanning1 proc
        mov ChPanning[ebp],al
        call USS_SetPanning
	ret
ProcSetPanning1 endp
else
ProcSetPanning1 Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set Panning command                        ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseSetPanning2               ; * SETUP *
ProcSetPanning2 proc
        shl al,4
        mov ChPanning[ebp],al
        call USS_SetPanning
	ret
ProcSetPanning2 endp
else
ProcSetPanning2 Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Sample Offset command                      ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseSetOffset         ; * SETUP *
ProcSetOffset proc
        cmp CNote,0
        je NoProcSetOffset
        or eax,eax
        jnz ProcSetOffsetNext
        mov ax,ChSmpOffset[2*ebp]
ProcSetOffsetNext:
        xor ebx,ebx     ; Don't test the sample size

        cmp USMTracker,M_IT
        jne NoUseHighOffset
        and ChSmpOffset[2*ebp],0FF00h
        add ax,ChSmpOffset[2*ebp]
        inc ebx         ; Test the sample size
NoUseHighOffset:
        
        mov ChSmpOffset[2*ebp],ax
        shl eax,8
	call USS_SetSampleOffset

NoProcSetOffset:
        ret
ProcSetOffset Endp
else
ProcSetOffset Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process Sample High Offset command                   ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcSetHighOffset proc
        shl eax,8
        mov ChSmpOffset[2*ebp],ax
        ret
ProcSetHighOffset Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Volume Slide command                       ³
;³                                                                         ³
;³ Used by       : PT  ST2 FT2                                             ³
;³ Compatibility : x   x   x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseVolumeSlide or UsePVolumeSlide or UseVVolumeSlide)  ; * SETUP *
ProcVolumeSlide proc
        or al,al
	jz  ProcVSEnd
	mov ChVolumeSlideData[ebp],al
ProcVSEnd:

if UseFastVS                    ; * SETUP *
        test USMFlags,F_FastVS  ; Fast Volume slide ?
        jz NoCallDoVS
        call DoVolumeSlide
NoCallDoVS:
endif

        ret
ProcVolumeSlide endp
else
ProcVolumeSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process IT Volume Slide command                      ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility : x   x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseITVolSlide or UseITVibVS or UseITPortVS) ;*
ProcITVolSlide proc
        or al,al
	jz  ProcITVSNext
        mov ChITVolumeSlideData[ebp],al
ProcITVSNext:
        mov ChVolumeSlideData[ebp],0
        mov al,ChITVolumeSlideData[ebp]

        cmp al,0Fh
        je No_DoFineVSDown      ; 0F -> Volume Slide down
        
        mov bl,al               ; xF -> Fine volume Slide up
        and bl,0Fh              
        cmp bl,0
        je No_DoFineVSDown      ; x0 -> Volume Slide up
        cmp bl,0Fh              
        jne No_DoFineVSUp
        shr al,4
        jmp ProcFVolumeUp
No_DoFineVSUp:

        mov bl,al
        shr bl,4
        cmp bl,0                ; 0x -> Volume Slide down
        je No_DoFineVSDown
        cmp bl,0Fh              ; Fx -> Fine volume Slide down
        jne No_DoFineVSDown
        and al,0Fh
        jmp ProcFVolumeDn
No_DoFineVSDown:

        mov ChVolumeSlideData[ebp],al

        test USMFlags,F_FastVS  ; Fast Volume slide ?
        jz NoCallDoITVS
        call DoVolumeSlide
NoCallDoITVS:

        ret
ProcITVolSlide endp
else
ProcITVolSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o               Process IT Channel Volume Slide command                  ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseITChVolSlide and UseChannelVolume)       ; * SETUP *
ProcITChVolSlide proc
        or al,al
	jz  ProcITChVSNext
	mov ChITChVolumeSlideData[ebp],al
ProcITChVSNext:
        mov ChChVolumeSlideData[ebp],0
        mov al,ChITChVolumeSlideData[ebp]

        cmp al,0Fh
        je No_DoFineChVSDown    ; 0F -> Channel Volume Slide down
        
        mov bl,al               ; xF -> Channel Fine volume Slide up
        and bl,0Fh
        cmp bl,0
        je No_DoFineChVSDown    ; x0 -> Channel Volume Slide up
        cmp bl,0Fh
        jne No_DoFineChVSUp
        shr al,4
        mov bl,al
        call USS_GetChannelVolume
        add al,bl
        cmp al,40h
        jbe ChFVSlideUpOk
        mov al,40h
ChFVSlideUpOk:
        call USS_SetChannelVolume
        ret
No_DoFineChVSUp:

        mov bl,al
        shr bl,4
        cmp bl,0                ; 0x -> Channel Volume Slide down
        je No_DoFineChVSDown
        cmp bl,0Fh              ; Fx -> Channel Fine volume Slide down
        jne No_DoFineChVSDown
        and al,0Fh
        mov bl,al
        call USS_GetChannelVolume
        sub al,bl
        jnc ChFVSlideDnOk
        xor eax,eax
ChFVSlideDnOk:        
        call USS_SetChannelVolume
        ret
No_DoFineChVSDown:

        mov ChChVolumeSlideData[ebp],al
        ret
ProcITChVolSlide endp
else
ProcITChVolSlide Equ ProcNothing
EndIf   ;(UseITChVolSlide and UseChannelVolume)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o               Process IT Global Volume Slide command                   ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITGVolSlide               ; * SETUP *
ProcITGVolSlide proc
if UseGlobalVolume              ; * SETUP *
        or al,al
	je  ProcITGVSNext
	mov ChITGVolumeSlideData[ebp],al
ProcITGVSNext:
        mov ChGVolumeSlideData[ebp],0
        mov al,ChITGVolumeSlideData[ebp]

        cmp al,0Fh
        je ITGVSDown            ; 0F -> Global Volume Slide down
        
        mov bl,al               ; xF -> Global Fine volume Slide up
        and bl,0Fh
        cmp bl,0
        je ITGVSUp              ; x0 -> Global Volume Slide up
        cmp bl,0Fh
        jne No_DoFineGVSUp
        shr al,4
        mov bl,al

        call USS_GetGlobalVolume
        add al,bl
        call USS_SetGlobalVolume

        ret
No_DoFineGVSUp:

        mov bl,al
        shr bl,4
        cmp bl,0                ; 0x -> Global Volume Slide down
        je ITGVSDown
        cmp bl,0Fh              ; Fx -> Global Fine Volume Slide down
        jne No_DoFineGVSDown
        and al,0Fh
        mov bl,al

        call USS_GetGlobalVolume
        sub al,bl
        jnc GFVSlideDnOk
        xor eax,eax
GFVSlideDnOk:
        call USS_SetGlobalVolume
        ret
No_DoFineGVSDown:
ITGVSDown:
ITGVSUp:
        mov ChGVolumeSlideData[ebp],al
EndIf
        ret
ProcITGVolSlide endp
else
ProcITGVolSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process IT Panning Slide command                     ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITPannSlide                ; * SETUP *
ProcITPannSlide proc
        or al,al
	je  ProcITPSNext
	mov ChITPanningSlideData[ebp],al
ProcITPSNext:
        mov ChPanningSlideData[ebp],0
        mov al,ChITPanningSlideData[ebp]

        cmp al,0Fh
        je ITPSRight            ; 0F -> Panning Slide right
        
        mov bl,al               
        and bl,0Fh
        or bl,bl
        jz ITPSLeft             ; x0 -> Panning Slide left
        cmp bl,0Fh
        jne No_DoFinePSLeft     ; xF -> Fine panning Slide left
;Fine Panning Slide Left
        shr al,4
        shl al,2
        mov bl,al

        call USS_GetPanning
        sub al,bl
        jnc FPSlideLeftOk
        xor eax,eax
FPSlideLeftOk:        
        call USS_SetPanning
        ret
No_DoFinePSLeft:

        mov bl,al
        shr bl,4
        or bl,bl                ; 0x -> Panning Slide right
        jz ITPSRight
        cmp bl,0Fh              ; Fx -> Fine panning Slide right
        jne No_DoFinePSRight

        and al,0Fh
        mov bl,al
        shl bl,2

        call USS_GetPanning
        add al,bl
        jnc FPSlideRightOk
        mov al,255
FPSlideRightOk:
        call USS_SetPanning
        ret
No_DoFinePSRight:
ITPSRight:
ITPSLeft:
        mov ChPanningSlideData[ebp],al
        ret
ProcITPannSlide endp
else
ProcITPannSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Jump Pattern command                       ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseJump                      ; * SETUP *
ProcJump proc
        mov NextOrder,ax  ; Jump to 'Param' Order and Row 0
	mov NextRow,0
	ret
ProcJump endp
else
ProcJump Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set Volume command                         ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseSetVolume                 ; * SETUP *
ProcSetVolume proc
        mov ChVolume[ebp],al
	call USS_SetVolume
	ret
ProcSetVolume endp
else
ProcSetVolume Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Pattern Break command                      ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseBreak                     ; * SETUP *
ProcBreak proc
        mov ebx,eax
	shr eax,4
	imul eax,10
	and bl,0Fh
	add eax,ebx
endif   ;UseBreak
if (UseBreak or UseBreakHex)
if UseBreakHex                  ; * SETUP *
ProcBreakHex:
endif   ;UseBreakHex
        mov NextRow,ax
	cmp NextOrder,-1
	jne ChangeRow
	movzx ebx,Order
	inc ebx
	mov NextOrder,bx
ChangeRow:
        ret
endif   ;(UseBreak or UseBreakHex)

if UseBreak                     ; * SETUP *
ProcBreak endp
else
ProcBreak Equ ProcNothing
endif   ;UseBreak

if UseBreakHex Eq 0
ProcBreakHex Equ ProcNothing
EndIf   ;UseBreakHex

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Set Global Volume command                  ³
;³                                                                         ³
;³ Used by       : ST3 FT2 IT                                              ³
;³ Compatibility : x   x   x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseGVolume                   ; * SETUP *
ProcGVolume proc
If UseGlobalVolume              ; * SETUP *
        call USS_SetGlobalVolume
EndIf
	ret
ProcGVolume endp
else
ProcGVolume Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Global Volume Slide command                ³
;³                                                                         ³
;³ Used by       : ST3 FT2 IT                                              ³
;³ Compatibility : x   x   x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseGVolumeSlide              ; * SETUP *
ProcGVolumeSlide proc
If UseGlobalVolume              ; * SETUP *
        or al,al
	je ProcGVolumeSlideEnd
	mov ChGVolumeSlideData[ebp],al
ProcGVolumeSlideEnd:
EndIf
        ret
ProcGVolumeSlide endp
else
ProcGVolumeSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                    Process Set Channel Volume command                  ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If (UseSetChVol and UseChannelVolume)   ; * SETUP *
ProcSetChVolume Proc
        cmp al,40h
        ja ProcSetChVolumeEnd
        call USS_SetChannelVolume
ProcSetChVolumeEnd:        
        ret
ProcSetChVolume Endp
else
ProcSetChVolume Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Tick based commands                        ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ProcTick proc
        mov ChCommandTick[ebp],al
	movzx edx,CComm
	call DoCmdTable[4*edx]     ; Call for Tick 0
	ret
ProcTick endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³x                     Process Set Envelope Pos command                   ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility :                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseEnvPos                    ; * SETUP *
ProcEnvPos proc
        jmp USS_SetEnvPos
ProcEnvPos endp
else
ProcEnvPos Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Pannig Slide command                       ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Note: This Effect is reversed in MXM play...
;       (Slide from L to R instead of R to L)

if UsePanningSlide              ; * SETUP *
ProcPanningSlide proc
	or al,al
	je ProcPanningSlideEnd
	mov ChPanningSlideData[ebp],al
ProcPanningSlideEnd:
	ret
ProcPanningSlide endp
else
ProcPanningSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Multi Retrig command                       ³
;³                                                                         ³
;³ Used by       : FT2                                                     ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Note: Multi Retrig counter is "Retriged" at Instrument start (in FT2)

if UseMRetrig                   ; * SETUP *
ProcMRetrig proc
        mov bl,al
	test al,0F0h
	jz NoMRetParam
	shr bl,4
	mov ChMRetrigParam[ebp],bl
NoMRetParam:
	test al,0Fh
	jz NoMRetSpeed
	and al,0Fh
	mov ChMRetrigSpeed[ebp],al
NoMRetSpeed:
        call DoMRetrig   ; Do Multi Retrig at Tick 0
	ret
ProcMRetrig endp
else
ProcMRetrig Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                   Process IT Multi Retrig command                      ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; It's ST3 Multi retrig because I'm using IT v2.11 and it's fully bugged :(
; (I will not implement a not working multi retrig !)

if UseITMRetrig                 ; * SETUP *
ProcITMRetrig proc
	or al,al
        jz  UseOldITMRetrigParam
        mov ChITMRetrigParam[ebp],al
UseOldITMRetrigParam:
        mov al,ChITMRetrigParam[ebp]

        mov bl,al
        shr bl,4
        mov ChMRetrigParam[ebp],bl

        test al,0Fh
        jz NoITMRetSpeed
        and al,0Fh
        mov ChMRetrigSpeed[ebp],al
NoITMRetSpeed:
        cmp ChCommand[ebp],_ITMRetrig
        je NoITMRetrigCntClear
        mov ChMRetrigCnt[ebp],0  ; Clear multi retrig counter.
NoITMRetrigCntClear:        
        call DoITMRetrig   ; Do Multi Retrig at Tick 0
        ret
ProcITMRetrig endp
else
ProcITMRetrig Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Tremor command                             ³
;³                                                                         ³
;³ Used by       : ST2 ST3 FT2 IT                                          ³
;³ Compatibility :         x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; Note: Tremor is "Retriged" at Instrument start (in FT2)
;       It's played as FT2 does, ST3 plays it differently.
;       FT2 was supposed to emulate ST Tremor, It's really strange.....
;       Anyway, it's one of the most buggy FT2 effect.

If UseTremor                    ; * SETUP *
ProcTremor proc
        or al,al
        je ProcTremorEnd
        shl eax,4
        shr al,4
        inc ah
        inc al
        add al,ah
        mov ChTremorLen[ebp],al
        mov ChTremorOff[ebp],ah
ProcTremorEnd:
        ret
ProcTremor endp
else
ProcTremor Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Extra fine portamento command              ³
;³                                                                         ³
;³ Used by       :  ST3 FT2 IT                                             ³
;³ Compatibility :      x   x                                              ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If (UseEFPort or UseITPitchDn or UseITPitchUp)  ; * SETUP *
ProcEFPort proc
        shl eax,4
        shr al,4
        cmp ah,1
        je EFPortUp
        cmp ah,2
        jne ProcEFPortEnd

        or al,al
        je EFPortDPrevData
        mov ChEFPortaDData[ebp],al
EFPortDPrevData:
	movzx eax,ChEFPortaDData[ebp]
	add ax,ChPeriod[2*ebp]

	call USS_SetPeriod
        mov ChPeriod[2*ebp],ax
        ret

EFPortUp:
        or al,al
        je EFPortUPrevData
        mov ChEFPortaUData[ebp],al
EFPortUPrevData:
	movzx ebx,ChEFPortaUData[ebp]
	movzx eax,ChPeriod[2*ebp]
	sub eax,ebx
_EFTooLow:

	call USS_SetPeriod
        mov ChPeriod[2*ebp],ax
ProcEFPortEnd:
	ret
ProcEFPort endp
else
ProcEFPort Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Fine Portamento Up command                 ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseFPortUp                   ; * SETUP *
ProcFPortUp proc
        or al,al
	je ProcFPortUpEnd
	mov ChFPortaUpData[ebp],al
ProcFPortUpEnd:
	movzx ebx,ChFPortaUpData[ebp]
	shl ebx,2
	movzx eax,ChPeriod[2*ebp]
	sub eax,ebx
	call USS_SetPeriod
	mov ChPeriod[2*ebp],ax
        ret
ProcFPortUp endp
else
ProcFPortUp Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Fine Portamento Down command               ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseFPortDown                 ; * SETUP *
ProcFPortDown proc
	or al,al
	je ProcFPortDownEnd
	mov ChFPortaDownData[ebp],al
ProcFPortDownEnd:
	movzx eax,ChFPortaDownData[ebp]
	shl eax,2
	add ax,ChPeriod[2*ebp]
	call USS_SetPeriod
	mov ChPeriod[2*ebp],ax
        ret
ProcFPortDown endp
else
ProcFPortDown Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³x                     Process Glissando Control command                  ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility :                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseGliss                     ; * SETUP *
ProcGliss proc
	ret
ProcGliss endp
else
ProcGliss Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Vibrato Type command                       ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVibType                   ; * SETUP *
ProcVibType proc
	mov ChVibWave[ebp],al   ; That's easy, I love this command. ;-)
	ret
ProcVibType endp
else
ProcVibType Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Pattern Loop command                       ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UsePatLoop                   ; * SETUP *
ProcPatLoop proc
        or al,al
        jz SetLoopStart
        inc al
        cmp ChPatLoopCount[ebp],0
        jne Not_First_Loop
        mov ChPatLoopCount[ebp],al
Not_First_Loop:
        dec ChPatLoopCount[ebp]
        jz ProcPatLoopEnd
        mov al,ChPatLoopRow[ebp]
        mov NextRow,ax
        mov ax,Order
        mov NextOrder,ax
        ret
SetLoopStart:
        mov ax,Row
        mov ChPatLoopRow[ebp],al
ProcPatLoopEnd:
        ret
ProcPatLoop endp
else
ProcPatLoop Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Tremolo Type command                       ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseTremType                  ; * SETUP *
ProcTremType proc
	mov ChTremWave[ebp],al
	ret
ProcTremType endp
else
ProcTremType Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     ProcessFine Volume Up command                      ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseFVolumeUp                 ; * SETUP *
ProcFVolumeUp proc
	or al,al
	je  ProcFVSlideUpEnd
	mov ChFVolumeSlideUpData[ebp],al
ProcFVSlideUpEnd:
	mov al,ChVolume[ebp]
	mov bl,ChFVolumeSlideUpData[ebp]
	add al,bl
	cmp al,40h
	jbe DoFVSUpOk
	mov al,40h
DoFVSUpOk:
	mov ChVolume[ebp],al
	call USS_SetVolume
	ret
ProcFVolumeUp endp
else
ProcFVolumeUp Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Fine Volume Down command                   ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseFVolumeDn                 ; * SETUP *
ProcFVolumeDn proc
	or al,al
	je  ProcFVSlideDownEnd
	mov ChFVolumeSlideDownData[ebp],al
ProcFVSlideDownEnd:
	mov al,ChVolume[ebp]
	mov bl,ChFVolumeSlideDownData[ebp]
	sub al,bl
	jnc DoFVSDownOk
	xor eax,eax
DoFVSDownOk:
	mov ChVolume[ebp],al
	call USS_SetVolume
	ret
ProcFVolumeDn endp
else
ProcFVolumeDn Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Pattern Delay command                      ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UsePatternDelay                      ; * SETUP *
ProcPatternDelay proc
	mov PatternDelay,al
	ret
ProcPatternDelay endp
else
ProcPatternDelay Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Synchro command                            ³
;³                                                                         ³
;³ Compatible with: FT2 (That's my command...)                             ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseSynchro                   ; * SETUP *
ProcSynchro proc
        mov _SynchroVal,al
        inc _SynchroCount
	ret
ProcSynchro endp
else
ProcSynchro Equ ProcNothing
EndIf

ProcPastNoteCtrl Proc
        call USS_PastNoteControl
        ret
ProcPastNoteCtrl Endp

ProcSetNNA Proc
        call USS_SetNNA
        ret
ProcSetNNA Endp


;                  *********************************
;                  **** Command tick procedures ****
;                  *********************************

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do BPM Slide command                               ³
;³                                                                         ³
;³ Used by       :  IT                                                     ³
;³ Compatibility :  x                                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DoBPMSlide Proc
        mov bl,ChBPMSlideData[ebp]
        cmp bl,20h
        jae DoBPMSlideEnd

        mov al,BPM
        cmp bl,10
        jb DoBPMSlideDown
                                ; 1x BPM Slide up
        and bl,0Fh
        add al,bl
        jnc BPMSlideOk
        mov al,0FFh
        jmp BPMSlideOk

DoBPMSlideDown:                 ; 0x BPM Slide down
        and bl,0Fh
        sub al,bl
        jnc BPMSlideDnTest2
        mov al,20h
BPMSlideDnTest2:
        cmp al,20h
        ja BPMSlideOk
        mov al,20h
BPMSlideOk:
        call ProcSetBPM
DoBPMSlideEnd:
        ret
DoBPMSlide Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Arpeggio command                                ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseArpeggio                  ; * SETUP *
DoArpeggio proc
        movzx eax,ChNote[ebp]
        movzx ecx,ChArpeggioPos[ebp]
        mov bl,ChArpeggioData[ebp]
        cmp cl,0
        je DoArpeggioSN
        cmp cl,1
        jne DoArpeggio2
        shr bl,4
        add al,bl
        jmp DoArpeggioSN
DoArpeggio2:
        and bl,0Fh
        add al,bl
DoArpeggioSN:
        inc cl
        cmp cl,3
        jne DoArpeggioEnd
        mov cl,0
DoArpeggioEnd:
        mov ChArpeggioPos[ebp],cl

        call USS_SetNote
        ret
DoArpeggio Endp
else
DoArpeggio Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Portamento Up command                           ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If (UsePortUp or UseITPitchUp)  ; * SETUP *
DoPortamentoUp proc
        movzx ebx,ChPortaUpData[ebp]
        shl ebx,2
        movzx eax,ChPeriod[2*ebp]
        sub eax,ebx
        call USS_SetPeriod
        mov ChPeriod[2*ebp],ax
if UseCutHighPitch              ; * SETUP *
        jc TooHighPitch
        ret
TooHighPitch:
        test USMFlags,F_CutHighPitch
        jz NoCutHighPitch
        call USS_NoteCut
NoCutHighPitch:        
endif   ;UseCutHighPitch
        ret
DoPortamentoUp Endp
else
DoPortamentoUp Equ ProcNothing
EndIf   ;(UsePortUp or UseITPitchUp)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Portamento Down command                         ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePortDown or UseITPitchDn)        ; * SETUP *
DoPortamentoDown proc
        movzx eax,ChPortaDownData[ebp]
        shl eax,2
        add ax,ChPeriod[2*ebp]
        call USS_SetPeriod
        mov ChPeriod[2*ebp],ax
        ret
DoPortamentoDown Endp
else
DoPortamentoDown Equ ProcNothing
EndIf   ;(UsePortDown or UseITPitchDn)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Porta to note command                           ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePortaNote or UseITPortaNote or UsePVolumeSlide or UseITPortVS or UseVPortaNote)
DoPortaNote proc
        movzx ebx,ChPortaToNoteData[ebp]
        shl ebx,2
        movzx eax,ChPeriod[2*ebp]
        movzx ecx,ChPortaToNotePeriode[2*ebp]

        or ecx,ecx
        jz DoPortaNoteEnd
        cmp eax,ecx
        ja  DoPortaU
        je  DoPortaNoteEnd
        add eax,ebx
        cmp eax,ecx
        jbe DoPortaNoteOk
        mov eax,ecx
DoPortaU:
        cmp eax,ebx
        ja  DoPortaUOk
        mov eax,ecx
        jmp DoPortaNoteOk
DoPortaUOk:
        sub eax,ebx
        cmp eax,ecx
        jae DoPortaNoteOk
        mov eax,ecx
DoPortaNoteOk:
        call USS_SetPeriod
        mov ChPeriod[2*ebp],ax
DoPortaNoteEnd:
        ret
DoPortaNote Endp
else
DoPortaNote Equ ProcNothing
EndIf   ;(UsePortaNote or UseITPortaNote or UseVPortaNote)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Vibrato command                                 ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility :             x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseVibrato or UseFineVibrato or UseVVolumeSlide or UseITVibVS or UseVVibrato)
DoVibrato proc
        mov ch,ChVibSpeed[ebp]
        mov cl,ChVibWave[ebp]
        and cl,3
        movzx edx,ChVibDepth[ebp]
        movzx ebx,ChVibPos[ebp]
        call GetVibData            ; Get Vibrato data
        sar cx,8                   ; Not 9, because periode is 4 times bigger
        mov ChVibPos[ebp],bl
        mov ax,ChPeriod[2*ebp]

        add ax,cx
        call USS_SetPeriod
        ret
DoVibrato endp
else
DoVibrato Equ ProcNothing
EndIf   ;(UseVibrato or UseFineVibrato or UseVVibrato)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Porta To Note+Volume Slide command              ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UsePVolumeSlide or UseITPortVS)     ; * SETUP *
DoPortVol proc
        call DoVolumeSlide  ; Do Volume Slide
        jmp  DoPortaNote    ; Do Porta to note
DoPortVol Endp
else
DoPortVol Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Vibrato+Volume Slide command                    ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseVVolumeSlide or UseITVibVS)      ; * SETUP *
DoVibVol proc
;write 'vvs'
        call DoVolumeSlide
        jmp  DoVibrato
DoVibVol endp
else
DoVibVol Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Tremolo command                                 ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility :         x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseTremolo                   ; * SETUP *
DoTremolo proc
        mov ch,ChTremSpeed[ebp]
        mov cl,ChTremWave[ebp]
        and cl,3
        movzx dx,ChTremdepth[ebp]
        movzx ebx,ChTremPos[ebp]
        call GetVibData            ; Get Tremolo data
        sar cx,6
        mov ChTremPos[ebp],bl
        mov al,ChVolume[ebp]
        or cx,cx
        js _TDNeg
        add al,cl
        cmp al,40h
        jbe DoTremEnd
        mov al,40h
        jmp DoTremEnd
_TDNeg:
        add al,cl
        cmp al,40h
        jbe DoTremEnd
        xor eax,eax
DoTremEnd:
        call USS_SetVolume
        ret
DoTremolo Endp
else
DoTremolo Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Volume Slide command                            ³
;³                                                                         ³
;³ Used by       : PT  ST2 ST3 FT2 IT                                      ³
;³ Compatibility : x   x   x   x   x                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If (UseVolumeSlide or UsePVolumeSlide or UseVVolumeSlide or UseITVolSlide or UseITVibVS or UseITPortVS)  ; * SETUP *
DoVolumeSlide proc
        mov al,ChVolume[ebp]
        mov bl,ChVolumeSlideData[ebp]
        test bl,0F0h
        jnz VSUp
        sub al,bl
        jnc VSEnd
        xor al,al
        jmp VSEnd
VSUp:
        shr bl,4
        add al,bl
        cmp al,40h
        jbe VSEnd
        mov al,40h
VSEnd:
        mov ChVolume[ebp],al
        call USS_SetVolume
        ret
DoVolumeSlide Endp
else
DoVolumeSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                 Do Channel Volume Slide command                        ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseITChVolSlide and UseChannelVolume)       ; * SETUP *
DoChVolumeSlide proc
        call USS_GetChannelVolume
        mov bl,ChChVolumeSlideData[ebp]
        test bl,0F0h
        jnz CVSUp
        sub al,bl
        jnc CVSEnd
        xor al,al
        jmp CVSEnd
CVSUp:
        shr bl,4
        add al,bl
        cmp al,40h
        jbe CVSEnd
        mov al,40h
CVSEnd:
        call USS_SetChannelVolume
        ret
DoChVolumeSlide Endp
else
DoChVolumeSlide Equ ProcNothing
EndIf   ;(UseITChVolSlide and UseChannelVolume)

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Global VolumeSlide command                      ³
;³                                                                         ³
;³ Used by       : ST3 FT2 IT                                              ³
;³ Compatibility : x   x   x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseGVolumeSlide              ; * SETUP *
DoGVolumeSlide proc
If UseGlobalVolume              ; * SETUP *
        call USS_GetGlobalVolume
        mov bl,ChGVolumeSlideData[ebp]
        test bl,0F0h
        jnz GVSUp
if UseBigGVolSlide              ; * SETUP *
        test USMFlags,F_BigGVolSlide
        jz NoBigGVolDn
        shl bl,1
NoBigGVolDn:
EndIf   ;UseBigGVolSlide
        sub al,bl
        jnc GVSEnd
        xor al,al
        jmp GVSEnd
GVSUp:
        shr bl,4
if UseBigGVolSlide              ; * SETUP *
        test USMFlags,F_BigGVolSlide
        jz NoBigGVolUp
        shl bl,1
NoBigGVolUp:
EndIf   ;UseBigGVolSlide
        add al,bl       ; Do not test if volume>40h, it's done in SetGlobalVol
GVSEnd:
	call USS_SetGlobalVolume
EndIf
        ret
DoGVolumeSlide endp
else
DoGVolumeSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                       Do Key Off command                               ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : x   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseKeyOff            ; * SETUP *
DoKeyOff proc
        mov al,ChCommandTick[ebp]
        cmp al,TickCnt
        jne DoKeyOffEnd
        call USS_KeyOff
DoKeyOffEnd:
        ret
DoKeyOff endp
else
DoKeyOff Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do Panning Slide command                           ³
;³                                                                         ³
;³ Used by       : FT2                                                     ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UsePanningSlide              ; * SETUP *
DoPanningSlide proc
        call USS_GetPanning
        mov bl,ChPanningSlideData[ebp]
        test bl,0F0h
        jnz PSRight
        sub al,bl
        jnc PSEnd
        xor al,al
        jmp PSEnd
PSRight:
        shr bl,4
        add al,bl
        jnc PSEnd
        mov al,0FFh
PSEnd:
        mov ChPanning[ebp],al
        call USS_SetPanning
        ret
DoPanningSlide Endp
else
DoPanningSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                    Do IT Panning Slide command                         ³
;³                                                                         ³
;³ Used by       : IT                                                      ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITPannSlide               ; * SETUP *
DoITPanningSlide proc
        call USS_GetPanning
        mov bl,ChPanningSlideData[ebp]

        test bl,0F0h
        jnz DoITPSLeft
        and bl,0Fh
        shl bl,2
        add al,bl
        jnc ITPSEnd
        mov al,0FFh
        jmp ITPSEnd
DoITPSLeft:
        shr bl,4
        shl bl,2
        sub al,bl
        jnc ITPSEnd
        xor al,al
ITPSEnd:
        mov ChPanning[ebp],al
        call USS_SetPanning
        ret
DoITPanningSlide Endp
else
DoITPanningSlide Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                      Do IT Multi Retrig command                        ³
;³                                                                         ³
;³ Used by       : ST3 IT                                                  ³
;³ Compatibility :     x                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseITMRetrig                 ; * SETUP *
DoITMRetrig proc
        movzx ebx,ChMRetrigSpeed[ebp]
        movzx eax,ChMRetrigCnt[ebp]

        cmp al,bl
        jb  NotITMRetrig
        mov ChMRetrigCnt[ebp],0
        jmp DoMRetrig1
NotITMRetrig:
        inc ChMRetrigCnt[ebp]
        ret
DoITMRetrig Endp
else
DoITMRetrig Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                      Do Multi Retrig command                           ³
;³                                                                         ³
;³ Used by       : FT2                                                     ³
;³ Compatibility : x                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if (UseMRetrig or UseITMRetrig) ; * SETUP *
DoMRetrig proc
        mov bl,ChMRetrigSpeed[ebp]
        inc ChMRetrigCnt[ebp]
        cmp bl,ChMRetrigCnt[ebp]
        jne NotmRetrig
        mov ChMRetrigCnt[ebp],0
DoMRetrig1:

; Retrig the sample
        xor eax,eax
        call USS_SetSampleOffset   ; Sample Offset=0

; Now, Change the channel volume
        movzx eax,ChVolume[ebp]
        mov cl,ChMRetrigParam[ebp]

        cmp cl,8
        ja  MR_Up
        je NotmRetrig
        or cl,cl
        jz NotmRetrig

        cmp cl,6
        jae MR_Div

; Volume-(2^(cl-1))
        dec cl
        mov bl,1
        shl bl,cl
        sub al,bl
        jns mRetrigEnd
        xor eax,eax
        jmp mRetrigEnd

MR_Div:
        jne MR_Div2
; 6 => Volume*2/3
        shl al,1
        mov bl,3
        div bl
        jmp mRetrigEnd
MR_Div2:
; 7 => Volume*1/2
        shr al,1
        jmp mRetrigEnd
	
MR_Up:
        cmp cl,0Eh
        jae MR_Mul

; Volume+(2^(cl-9))
        sub cl,9
        mov bl,1
        shl bl,cl
        add al,bl
        jmp mRetrigCutHighVolume
MR_Mul:
        jne MR_Mul2
; E => Volume*3/2

        mov ah,al
        shl al,1
        add al,ah
        shr al,1
        jmp mRetrigCutHighVolume
MR_Mul2:
; F => Volume*2

        shl al,1

mRetrigCutHighVolume:
        cmp al,40h
        jbe mRetrigEnd
        mov al,40h
mRetrigEnd:

        mov ChVolume[ebp],al
        call USS_SetVolume
NotmRetrig:
        ret
DoMRetrig Endp
else
DoMRetrig Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                         Do Tremor command                              ³
;³                                                                         ³
;³ Used by       : ST2 ST3 FT2 IT                                          ³
;³ Compatibility :         x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseTremor                    ; * SETUP *
DoTremor proc
        mov bl,ChTremorPos[ebp]
        mov al,ChVolume[ebp]
        cmp bl,ChTremorOff[ebp]
        jb  TremorOn
        xor al,al
TremorOn:
        inc bl
        cmp bl,ChTremorLen[ebp]
        jb  Tremor_ChangeVolume
        xor bl,bl
Tremor_ChangeVolume:
        mov ChTremorPos[ebp],bl
        call USS_SetVolume      ; Set new volume (0 or Channel volume)
        ret                     ; It only affect the sound system volume.
DoTremor Endp
else
DoTremor Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                        Do Retrig command                               ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : ?       x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseRetrig                    ; * SETUP *
DoRetrig proc
        movzx eax,TickCnt
        cmp al,ChCommandTick[ebp]
        je _DoRetrig

        or eax,eax
        jz NotRetrig
        cmp ChCommandTick[ebp],0
        je NotRetrig

        div ChCommandTick[ebp]
        cmp ah,0
        jne NotRetrig
_DoRetrig:
        xor eax,eax
        call USS_SetSampleOffset
NotRetrig:
        ret
DoRetrig Endp
else
DoRetrig Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                      Do Note Cut command                               ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : ?       x                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseCutNote                   ; * SETUP *
DoNoteCut proc
        mov al,ChCommandTick[ebp]
        cmp al,TickCnt
        jne DoNoteCutEnd
        xor eax,eax             ; Set all the volumes to 0
        mov ChVolume[ebp],al
        call USS_SetVolume
DoNoteCutEnd:
        ret
DoNoteCut Endp
else
DoNoteCut Equ ProcNothing
EndIf

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                      Do Note Delay command                             ³
;³                                                                         ³
;³ Used by       : PT  ST3 FT2 IT                                          ³
;³ Compatibility : ?   x   x   x                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseNoteDelay                 ; * SETUP *
DoNoteDelay Proc
        mov al,ChCommandTick[ebp]
        cmp al,TickCnt             ; Is it time to start the note ?
        jne DoNoteDelayEnd

; Load the previous Row data. (Note, Instrument and Volume with no command)
        xor eax,eax
        mov al,ChRNote[ebp]
        mov CNote,ax
        mov al,ChRInstrument[ebp]
        mov CInstr,ax
if UseVolCol
        mov al,ChRVolume[ebp]
        mov CVolume,ax
        mov CComm,0FFh
EndIf   ;UseVolCol

; Start the note exactly as it is the tick 0.
        call StartNote

DoNoteDelayEnd:
        ret
DoNoteDelay Endp
else
DoNoteDelay Equ ProcNothing
EndIf   ;UseNoteDelay

;                   **********************************
;                   * Process Volume column commands *
;                   **********************************

if UseVolEfx                    ; * SETUP *

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Set volume commands parameter                      ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ProcSetVData Proc

if UseIT                        ; * SETUP *
        cmp USMTracker,M_IT     ; This effect has a memory in Impulse Tracker
        jne NoITProcSetVData
        cmp dl,_VVolSlideDown
        je ITVVolSlide
        cmp dl,_VVolSlideUp
        je ITVVolSlide
        jmp NoITVVolSlide
ITVVolSlide:
        or al,al
        jz NoSaveVVolSlideParam
        mov ChVVolumeSideParam[ebp],al
NoSaveVVolSlideParam:
        mov al,ChVVolumeSideParam[ebp]
NoITVVolSlide:        
NoITProcSetVData:
EndIf   ;UseIT

        mov ChVolCmdData[ebp],al
        ret
ProcSetVData Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Volume fine down command                   ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVFVolDown                 ; * SETUP *
ProcVFVolDown Proc
if UseIT                        ; * SETUP *
        cmp USMTracker,M_IT     ; This effect has a memory in Impulse Tracker
        jne NoITProcVFVolDown
        or al,al
        jz NoSaveVFVolDownParam
        mov ChVVolumeSideParam[ebp],al
NoSaveVFVolDownParam:
        mov al,ChVVolumeSideParam[ebp]
NoITProcVFVolDown:
EndIf   ;UseIT

        mov bl,al
        mov al,ChVolume[ebp]
        sub al,bl
        jnc ProcVFVolDownEnd
        xor al,al
ProcVFVolDownEnd:
        mov ChVolume[ebp],al
        call USS_SetVolume
        ret
ProcVFVolDown Endp
else
ProcVFVolDown Equ ProcNothing
EndIf   ;UseVFVolDown

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process Volume fine up command                     ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVFVolUp                   ; * SETUP *
ProcVFVolUp Proc

if UseIT                        ; * SETUP *
        cmp USMTracker,M_IT     ; This effect has a memory in Impulse Tracker
        jne NoITProcVFVolUp
        or al,al
        jz NoSaveVFVolUpParam
        mov ChVVolumeSideParam[ebp],al
NoSaveVFVolUpParam:
        mov al,ChVVolumeSideParam[ebp]
NoITProcVFVolUp:
EndIf   ;UseIT

        mov bl,al
        mov al,ChVolume[ebp]
        add al,bl
        cmp al,40h
        jbe ProcVFVolUpEnd
        mov al,40h
ProcVFVolUpEnd:
        mov ChVolume[ebp],al
        call USS_SetVolume
        ret
ProcVFVolUp Endp
else
ProcVFVolUp Equ ProcNothing
EndIf   ;UseVFVolUp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process "Volume" Set vibrato speed command         ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If UseVSetVibSpeed              ; * SETUP *
ProcSetVibSpeed proc
        or al,al
        jz NoVibSpeed
        mov ChVibSpeed[ebp],al
NovVibSpeed:
        ret
ProcSetVibSpeed Endp
else
ProcSetVibSpeed Equ ProcNothing
EndIf   ;UseVSetVibSpeed

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process "Volume" Vibrato command                   ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVVibrato                  ; * SETUP *
ProcVVibrato proc
        or al,al
        jz NoVibDepth
        shl al,2
        mov ChVibDepth[ebp],al
NovVibDephth:
        ret
ProcVVibrato Endp
else
ProcVVibrato Equ ProcNothing
EndIf   ;UseVVIbrato

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process "Volume" Set Panning command               ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVPanning                  ; * SETUP *
ProcVPanning proc
        shl ax,4
        mov ChPanning[ebp],al
        call USS_SetPanning
        ret
ProcVPanning Endp
else
ProcVPanning Equ ProcNothing
EndIf   ;UseVPanning

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Process "Volume" Porta to note command             ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVPortaNote                ; * SETUP *
ProcVPortaNote proc
        shl al,4
        or al,al
        jz ProcvPortanoteNext
        mov ChPortaToNoteData[ebp],al
ProcvPortanoteNext:
        cmp CNote,0
        je ProcvPortanoteEnd
        mov bx,CNote
        call USS_GetNotePeriod
        mov ChPortaToNotePeriode[2*ebp],ax
ProcvPortanoteEnd:
        ret
ProcVPortaNote Endp
else
ProcVPortaNote Equ ProcNothing
EndIf   ;UseVPortaNote

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do "Volume" Volume Slide Down                      ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVVolSlideDown             ; * SETUP *
DoVVolSlDown proc
        mov al,ChVolume[ebp]
        mov bl,ChVolCmdData[ebp]
        sub al,bl
        jnc DoVVolSlDownEnd
        xor al,al
DoVVolSlDownEnd:
        mov ChVolume[ebp],al
        call USS_SetVolume
        ret
DoVVolSlDown Endp
else
DoVVolSlDown Equ ProcNothing
EndIf   ;UseVVolSlideDown

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do "Volume" Volume Slide Up                        ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVVolSlideUp               ; * SETUP *
DoVVolSlUp Proc
        mov al,ChVolume[ebp]
        mov bl,ChVolCmdData[ebp]
        add al,bl
        cmp al,40h
        jbe DoVVolSlUpEnd
        mov al,40h
DoVVolSlUpEnd:
        mov ChVolume[ebp],al
        call USS_SetVolume
        ret
DoVVolSlUp Endp
else
DoVVolSlUp Equ ProcNothing
EndIf   ;UseVVolSlideUp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do "Volume" Panning Slide Left                     ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVPanSlideL                ; * SETUP *
DoVPanSlL Proc
        call USS_GetPanning
        mov bl,ChVolCmdData[ebp]
        sub al,bl
        jnc VPSlEnd
        xor al,al
VPSlEnd:
        mov ChPanning[ebp],al
        call USS_SetPanning
        ret
DoVPanSlL Endp
else
DoVPanSlL Equ ProcNothing
EndIf   ;UseVPanSlideL

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³o                     Do "Volume" Panning Slide Right                    ³
;³                                                                         ³
;³ Used by       : FT2 IT                                                  ³
;³ Compatibility : x   ?                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

if UseVPanSlideR                ; * SETUP *
DoVPanSlR Proc
        call USS_GetPanning
        mov bl,ChVolCmdData[ebp]
        add al,bl
        jnc VPSrEnd
        mov al,0FFh
VPSrEnd:
        mov ChPanning[ebp],al
        call USS_SetPanning
        ret
DoVPanSlR Endp
else
DoVPanSlR Equ ProcNothing
EndIf   ;UseVPanSlideR

EndIf   ;UseVolEfx

;=============================================================================

MaxCmd EQU 72

; Command order is the FT2 Order, Commands not in FT2 will be add at the end

ProcCmdTable  label dword

;    Jump label         Number Name                    Source format
  dd ProcArpeggio      ;00-0xy Arpeggio                (MOD)
  dd ProcPortUp        ;01-1xx Portamento Up           (MOD)
  dd ProcPortDown      ;02-2xx Portamento Down         (MOD)
  dd ProcPortaNote     ;03-3xx Portamento to Note      (MOD)
  dd ProcVibrato       ;04-4xy Vibrato                 (MOD)
  dd ProcVolumeSlide   ;05-5xy Portamento+Volume Slide (MOD)
  dd ProcVolumeSlide   ;06-6xy Vibrato+Volume Slide    (MOD)
  dd ProcTremolo       ;07-7xy Tremolo                 (MOD)
  dd ProcSetPanning1   ;08-8xx Set Panning             (MOD/DMP)
  dd ProcSetOffset     ;09-9xx Set Sample Offset       (MOD)
  dd ProcVolumeSlide   ;10-Axy Volume Slide            (MOD)
  dd ProcJump          ;11-Bxx Jump to pattern         (MOD)
  dd ProcSetVolume     ;12-Cxx Set Volume              (MOD)
  dd ProcBreak         ;13-Dxx Pattern Break           (MOD)
  dd ProcNothing       ;14-Exy Extended Effects (24+x)
  dd ProcSetTempo_BPM  ;15-Fxx Set Speed/Set BPM       (MOD)

  dd ProcGVolume       ;16-Gxx Set Global Volume       (S3M/XM)
  dd ProcGVolumeSlide  ;17-Hxx Global Volume Slide     (XM)
  dd ProcNothing       ;18-I
  dd ProcNothing       ;19-J
  dd ProcTick          ;20-Kxx Key Off (after xx tick) (XM)
  dd ProcEnvPos        ;21-Lxx Set Envelope Pos        (XM)
  dd ProcNothing       ;22-M
  dd ProcNothing       ;23-N
  dd ProcNothing       ;24-O
  dd ProcPanningSlide  ;25-Pxx Panning Slide           (XM)
  dd ProcNothing       ;26-Q
  dd ProcMRetrig       ;27-Rxy Multi Retrig Note       (S3M)
  dd ProcNothing       ;28-S
  dd ProcTremor        ;29-Txy Tremor                  (STM)
  dd ProcNothing       ;30-U
  dd ProcNothing       ;31-V
  dd ProcSynchro       ;32-Wxx Synchro funtion
  dd ProcEFPort        ;33-Xxy Extra Fine Portamento   (S3M)
  dd ProcNothing       ;34-Y
  dd ProcNothing       ;35-Z

  dd ProcNothing       ;36-E0x Set Filter              (MOD) x
  dd ProcFPortUp       ;37-E1x Fine Portamento Up      (MOD)
  dd ProcFPortDown     ;38-E2x Fine Portamento Down    (MOD)
  dd ProcGliss         ;39-E3x Glissando Control       (MOD) x
  dd ProcVibType       ;40-E4x Set Vibrato Waveform    (MOD)
  dd ProcNothing       ;41-E5x Set Finetune            (MOD) x
  dd ProcPatLoop       ;42-E6x Pattern Loop            (MOD)
  dd ProcTremType      ;43-E7x Set Tremolo WaveForm    (MOD)
  dd ProcSetPanning2   ;44-E8x Unused/Set Panning      (MOD/S3M)
  dd ProcTick          ;45-E9x Retrig Note             (MOD)
  dd ProcFVolumeUp     ;46-EAx Fine Volume Slide Up    (MOD)
  dd ProcFVolumeDn     ;47-EBx Fine Volume Slide Down  (MOD)
  dd ProcTick          ;48-ECx Cut Note                (MOD)
  dd ProcTick          ;49-EDx Delay Note              (MOD)
  dd ProcPatternDelay  ;50-EEx Pattern Delay           (MOD)
  dd ProcSynchro       ;51-EFx Invert Loop, Synchro    (MOD) x
  dd ProcSetTempo      ;52-    Set Tempo
  dd ProcSetBPM        ;53-    Set BPM 
  dd ProcBreakHex      ;54-    Pattern Break (Hex)     (IT )
  dd ProcITSetBPM      ;55-    IT Set/Slide BPM        (IT )
  dd ProcITVolSlide    ;56-    IT Volume Slide/Fine VS (IT/S3M)
  dd ProcITPitch       ;57-Exx                         (IT/S3M)
  dd ProcITPitch       ;58-Fxx                         (IT/S3M)
  dd ProcITPitch       ;59-Gxx
  dd ProcITVolSlide    ;60-Kxy IT Vibrato+Volume Slide (IT/S3M)
  dd ProcITVolSlide    ;61-Lxy IT Portamento+Vol Slide (IT/S3M)
  dd ProcSetChVolume   ;62-Mxy Set Channel volume      (IT)
  dd ProcITChVolSlide  ;63-Nxy Channel volume slide    (IT)
  dd ProcITPannSlide   ;64-Pxy Panning Slide           (IT)  x
  dd ProcITMRetrig     ;65-Qxy Multi retrig
  dd ProcVibrato       ;66-Uxy Fine Vibrato            (IT/S3M)
  dd ProcITGVolSlide   ;67-Wxy Global volume slide
  dd ProcNothing       ;68-Xxy Panbrello     
  dd ProcPastNoteCtrl  ;69-S70-S73 Paste Notes control
  dd ProcSetNNA        ;70-S74-S77 Set NNA
  dd ProcSetHighOffset ;71-SAy Set sample offset high part yxx00h


;(71d au total)

DoCmdTable label dword
  dd DoArpeggio        ;00-0xy Arpeggio                (MOD)
  dd DoPortamentoUp    ;01-1xx Portamento Up           (MOD)
  dd DoPortamentoDown  ;02-2xx Portamento Down         (MOD)
  dd DoPortaNote       ;03-3xx Portamento to Note      (MOD)
  dd DoVibrato         ;04-4xy Vibrato                 (MOD)
  dd DoPortVol         ;05-5xy Portamento+Volume Slide (MOD)
  dd DoVibVol          ;06-6xy Vibrato+Volume Slide    (MOD)
  dd DoTremolo         ;07-7xy Tremolo                 (MOD)
  dd ProcNothing       ;08-8xx Set Panning             (MOD/DMP)
  dd ProcNothing       ;09-9xx Set Sample Offset       (MOD)
  dd DoVolumeSlide     ;10-Axy Volume Slide            (MOD)
  dd ProcNothing       ;11-Bxx Jump to pattern         (MOD)
  dd ProcNothing       ;12-Cxx Set Volume              (MOD)
  dd ProcNothing       ;13-Dxx Pattern Break           (MOD)
  dd ProcNothing       ;14-Exy Extended Effects (24+x)
  dd ProcNothing       ;15-Fxx Set Speed/Set BPM       (MOD)

  dd ProcNothing       ;16-Gxx Set Global Volume       (S3M/XM)
  dd DoGVolumeSlide    ;17-Hxx Global Volume Slide     (XM)
  dd ProcNothing       ;18-I
  dd ProcNothing       ;19-J
  dd DoKeyOff          ;20-Kxx Key Off (after xx tick) (XM)
  dd ProcNothing       ;21-Lxx Set Envelope Pos        (XM)
  dd ProcNothing       ;22-M
  dd ProcNothing       ;23-N
  dd ProcNothing       ;24-O
  dd DoPanningSlide    ;25-Pxx Panning Slide           (XM)
  dd ProcNothing       ;26-Q
  dd DoMRetrig         ;27-Rxy Multi Retrig Note       (S3M)
  dd ProcNothing       ;28-S
  dd DoTremor          ;29-Txy Tremor                  (STM)
  dd ProcNothing       ;30-U
  dd ProcNothing       ;31-V
  dd ProcNothing       ;32-Wxx Synchro function
  dd ProcNothing       ;33-Xxy Extra Fine Portamento   (S3M)
  dd ProcNothing       ;34-Y
  dd ProcNothing       ;35-Zxx Synchro function        (USM)

  dd ProcNothing       ;36-E0x
  dd ProcNothing       ;37-E1x Fine Portamento Up      (MOD)
  dd ProcNothing       ;38-E2x Fine Portamento Down    (MOD)
  dd ProcNothing       ;39-E3x Glissando Control       (MOD)
  dd ProcNothing       ;40-E4x Set Vibrato Waveform    (MOD)
  dd ProcNothing       ;41-E5x Set Finetune            (MOD)
  dd ProcNothing       ;42-E6x Pattern Loop            (MOD)
  dd ProcNothing       ;43-E7x Set Tremolo WaveForm    (MOD)
  dd ProcNothing       ;44-E8x Unused/Set Panning      (MOD/S3M)
  dd DoRetrig          ;45-E9x Retrig Note             (MOD)
  dd ProcNothing       ;46-EAx Fine Volume Slide Up    (MOD)
  dd ProcNothing       ;47-EBx Fine Volume Slide Down  (MOD)
  dd DoNoteCut         ;48-ECx Cut Note                (MOD)
  dd DoNoteDelay       ;49-EDx Delay Note              (MOD)
  dd ProcNothing       ;50-EEx Pattern Delay           (MOD)
  dd ProcNothing       ;51-EFx Synchro function
  dd ProcNothing       ;52-    Set Tempo 
  dd ProcNothing       ;53-    Set BPM
  dd ProcNothing       ;54-    Pattern Break (Hex)     (IT )
  dd DoBPMSlide        ;55-    IT Set/Slide BPM        (IT/S3M)
  dd DoVolumeSlide     ;56-Dxx IT Volume Slide/Fine VS (IT/S3M)
  dd DoPortamentoDown  ;57-Exx IT Portamento Down
  dd DoPortamentoUp    ;58-Fxx IT Portamento Up
  dd DoPortaNote       ;59-Gxx IT Portamento to note   (IT/S3M)
  dd DoVibVol          ;60-Kxy IT Vibrato+Volume Slide (IT)
  dd DoPortVol         ;61-Lxy IT Portamento+Vol Slide (IT) ! A modifier
  dd ProcNothing       ;62-Mxx Set Channel Volume      (IT)
  dd DoChVolumeSlide   ;63-Nxy Channel volume slide
  dd DoITPanningSlide  ;64-Pxy IT Panning slide
  dd DoITMRetrig       ;65-Qxy IT Multi retrig
  dd DoVibrato         ;66-Uxy Fine Vibrato
  dd DoGVolumeSlide    ;67-Wxy Global volume slide
  dd ProcNothing       ;68-Xxy Panbrello     
  dd ProcNothing       ;69-S70-S73 Paste Notes control
  dd ProcNothing       ;70-S74-S77 Set NNA
  dd ProcNothing       ;71-SAy Set sample offset high part yxx00h


MaxVolCmd EQU 10

; Volume commands are processed as in FT2:
;
; 00h-09h -> Do nothing
; 10h-5Fh -> Set Volume (value-10h)
; 60h-FF  -> Process one of the following commands:

if UseVolEfx                    ; * SETUP *
ProcVolTable label dword
  dd ProcSetVData     ; 6x Volume Slide down
  dd ProcSetVData     ; 7x Volume Slide up
  dd ProcVFVolDown    ; 8x Fine volume Slide down
  dd ProcVFVolUp      ; 9x Fine volume Slide up
  dd ProcSetVibSpeed  ; Ax SetVibSpeed
  dd ProcVVibrato     ; Bx Vibrato
  dd ProcVPanning     ; Cx Set Panning
  dd ProcSetVData     ; Dx Panning Slide left
  dd ProcSetVData     ; Ex Panning Slide right
  dd ProcVPortaNote   ; Fx Porta to note

DoVolTable label dword
  dd DoVVolSlDown
  dd DoVVolSlUp
  dd ProcNothing
  dd ProcNothing
  dd ProcNothing
  dd DoVibrato
  dd ProcNothing
  dd DoVPanSlL
  dd DoVPanSlR
  dd DoPortaNote
endif   ;UseVolEfx

CODE32 ENDS
end