;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ USS.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗         บ
;            บ                                                   บ
;            บ               Useless Sound System                บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   by Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 13/03/1996       บ
;            บ   Last Update .................. 05/01/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC
INCLUDE MUS_EFX.INC

INCLUDE USS.INC
INCLUDE ERR_CODE.INC

INCLUDE USSVAR.INC

INCLUDE HARDWARE.INC ; Used in SETUP for the ZeroOffset definition.
INCLUDE MEMORY.INC   ; Used in the SETUP proc.
INCLUDE UTILS.INC    ; All display functions (can be remove if no debug
                     ;                        display is used           )

; ********** DEVICES LIST **********
If UseIW  Eq Yes
   EXTRN IW_DEVICE
EndIf
If UseGUS Eq Yes
   EXTRN GUS_DEVICE
EndIf
;If UseGUSM Eq Yes
;   EXTRN GUSM_DEVICE
;EndIf
If UseSB Eq Yes
   EXTRN SB_DEVICE
EndIf
If UseHP Eq Yes
   EXTRN HP_DEVICE
EndIf
If UseNoSnd Eq Yes
   EXTRN NOSND_DEVICE
EndIf

NoDev_Name DB 'No device',0,'$'

DEVList Label Dword
If UseIW  Eq Yes
        DD Offset IW_DEVICE
EndIf
If UseGUS Eq Yes
        DD Offset GUS_DEVICE
EndIf
;If UseGUSM Eq Yes
;        DD Offset GUSM_DEVICE
;EndIf
If UseSB Eq Yes
        DD Offset SB_DEVICE
EndIf
If UseHP Eq Yes
        DD Offset HP_DEVICE
EndIf
If UseNoSnd Eq Yes
        DD Offset NOSND_DEVICE
EndIf
        DD 0

; ********** DEVICES LIST ********** (End)

;=============================================================================

DEVICE_DRIVER Struc
              D_Detect      DD ?
              D_Init        DD ?
              D_LoadSample  DD ?
              D_FreeSample  DD ?
              D_SetAmpli    DD ?
              D_StartOutput DD ?
              D_StopOutput  DD ?
              D_UpdateSound DD ?

              D_TotalDev    DW ?
              D_PortList    DD ?
              D_DevName     DD ?
DEVICE_DRIVER Ends

;-----------------------------------------------------------------------------

BestDev  DW 0
TotalDev DW 0

VChEnvVar Struc
       VChEnvPos    DW MAX_SSCHANNELS DUP (0)
       VChEnvSegPos DW MAX_SSCHANNELS DUP (0)
VChEnvvar Ends

SS_Started DB 0 ; 1 if sound output is started.

USS_PeriodicProc DD 0

if (UsePannEnv or UseVolumeEnv) ; * SETUP *
DPos      DW 0  ; Delta position          (Envelopes)
Sustained DW 0  ; Sustain point reached ? (Envelopes)
endif

if (UseTremolo or UseAutoVibrato or UseVibrato or UseVVolumeSlide or UseVVibrato or UseITVibVS)
SinTab  DB   0,  6, 12, 18, 24, 31, 37, 43, 49, 55, 61, 68, 74, 79, 85, 91
        DB  97,103,109,114,120,125,131,136,141,146,151,156,161,166,171,175
        DB 180,184,188,193,197,201,204,208,212,215,218,221,224,227,230,233
        DB 235,237,240,242,244,245,247,248,250,251,252,253,253,254,254,254
        DB 255,254,245,254,253,253,252,251,250,248,247,245,244,242,240,237
        DB 235,233,230,227,224,221,218,215,212,208,204,201,197,193,188,184
        DB 180,175,171,166,161,156,151,146,141,136,131,125,120,114,109,103
        DB  97, 91, 85, 79 ,74, 68, 61, 55, 49, 43, 37, 31, 24, 18, 12,  6
endif

; * Var for NNA/DCT *

UseNNA_DCT Equ (UseNNA or UseDCT or UseIT)

If UseNNA_DCT           ; * SETUP *

Oldebp  DD 0

InstrAdress DD 0
SmpAdress   DD 0

EAXSave  DD 0
NoteSave DD 0

EndIf

LoadInitialSamples DD 0

;=============================================================================
;=                        USS Setup variables
;=============================================================================

If UseSetup             ; * SETUP *

SelectBuffer DD 0

MAXLines EQU 18
NbLines          DW 0
SelectLinePos    DD 0
SelectStrPos     DD 0
CurrentSize      DW 0
SDEV_Number      DW 0

CenterAttrib EQU 23*256

TopStr    DB 'Useless Sound System v',USMP_Version,' setup',0
TopStrPos EQU (25)*2
TopAttrib EQU 49*256

BStr    DB '(c) 1996-1997 FreddyV/Useless',0
BStrPos EQU (24*80)*2
BAttrib EQU 49*256

SelectAttrib    EQU 113*256
HighlightAttrib EQU 49*256

SOutputPos       EQU (24+3*80)*2
SOutputSize      EQU 32
SOutputStr       DB  'Select sound output',0
SOutputStrPos    EQU (SOutputPos+80*2)+7*2
SOutputSelectPos EQU (2)*2

SPortPos       EQU (32+3*80)*2
SPortSize      EQU 13
SPortStr       DB  'Select port',0
SPortStrPos    EQU (SPortPos+80*2)+2*2
SPortSelectPos EQU (5)*2

SIRQPos       EQU (32+3*80)*2
SIRQSize      EQU 12
SIRQStr       DB  'Select IRQ',0
SIRQStrPos    EQU (SIRQPos+80*2)+2*2
SIRQSelectPos EQU (5)*2

SDMAPos       EQU (32+3*80)*2
SDMAStr       DB  'Select DMA',0
SDMAStrPos    EQU (SDMAPos+80*2)+2*2
SDMASelectPos EQU (5)*2

SFreqPos       EQU (29+3*80)*2
SFreqStr       DB  'Select mixing rate',0
SFreqStrPos    EQU (SFreqPos+80*2)+2*2
SFreqSelectPos EQU (7)*2

SModePos       EQU (27+3*80)*2
SModeSize      EQU 24
SModeStr       DB  'Select output mode',0
SModeStrPos    EQU (SModePos+80*2)+4*2
SModeSelectPos EQU (2)*2

SAutodetectStr DB 'Autodetect best device',0
SMono    DB 'Mono',0
SStereo  DB 'Stereo',0
SMonoO   DB 'Mono oversampling',0
SStereoO DB 'Stereo oversampling',0

IRQList  DW 2,3,4,5,7,10,11,12,15,-1
DMAList  DW 0,1,3,5,6,7,-1
FreqList DW 8000,11025,16000,22050,32000,38000,44100,-1

EndIf
;=============================================================================


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_Setup: Useless Sound System Setup interface                         ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error or quit                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If UseSetup             ; * SETUP *
USS_Setup  Proc

        cls
        HideCursor

        push ds
        pop es
        cld

; ** Draw the setup screen

        mov ax,TopAttrib
        mov ecx,80
        mov edi,0
        call DrawLine

        mov esi,Offset TopStr
        mov edi,TopStrPos
        mov ax,TopAttrib
        call PrintStr

	mov ax,BAttrib
	mov ecx,80
	mov edi,(24*80)*2
	call DrawLine

        mov esi,Offset BStr
        mov edi,BStrPos
        mov ax,BAttrib
        call PrintStr

; ** Do the setup

        call USS_DetectBestDev  ; Detect the best device
        mov SDEV_Number,ax      ; Default selected device

        U_Malloc 32*20          ; Alloc Memory for 20 selections
        mov SelectBuffer,eax

; 1- Select device

SelectOutput:

        call Setup_ClearCenter

        call PrepareBuffer_Output

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,SOutputSize
        mov CurrentSize,SOutputSize
        mov edx,ecx
        mov edi,SOutputPos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SOutputStr
        mov edi,SOutputStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SOutputSelectPos
        call PrintChoices

        movzx ecx,SDEV_Number
        call DoSelection
        mov eax,SE_NoDevice
        jc USS_NoDev           ; ESC => End

        cmp ecx,0
        jz USS_SetupEnd

        mov SDEV_Number,cx
        movzx eax,cx
        call USS_DetectDEV
        
; 2- Select Base Port

SelectPort:

        cmp _DEV_BasePort,-1
        je  SelectDMA

        call Setup_ClearCenter

        mov esi,_DEV_Offset
        mov esi,D_PortList[esi]
        call PrepareBuffer_Hex

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,SPortSize
        mov CurrentSize,SPortSize
        mov edx,ecx
        mov edi,SPortPos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SPortStr
        mov edi,SPortStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SPortSelectPos
        call PrintChoices

        mov esi,_DEV_Offset
        mov esi,D_PortList[esi]
        movzx eax,_DEV_BasePort
        call GetNumberPos

        call DoSelection
        jnc SelectPortEnd

        jmp SelectOutput

SelectPortEnd:

        mov esi,_DEV_Offset
        mov esi,D_PortList[esi]
        mov ax,[esi+2*ecx]
        mov _DEV_BasePort,ax


; 3- Select IRQ number

SelectIRQ:

        cmp _DEV_IRQ,-1
        je  SelectDMA

        call Setup_ClearCenter

        mov esi,Offset IRQList
        call PrepareBuffer_DEC

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,SIRQSize
        mov CurrentSize,SIRQSize
        mov edx,ecx
        mov edi,SIRQPos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SIRQStr
        mov edi,SIRQStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SIRQSelectPos
        call PrintChoices

        movzx eax,_DEV_IRQ
        mov esi,Offset IRQList
        call GetNumberPos

        call DoSelection
        jnc SelectIRQEnd

        jmp SelectOutput

SelectIRQEnd:

        mov ax,IRQList[2*ecx]
        mov _DEV_IRQ,al

; 4- Select DMA number

SelectDMA:
        cmp _DEV_DMA,-1
        je  SelectFreq

        call Setup_ClearCenter

        mov esi,Offset DMAList
        call PrepareBuffer_DEC

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,12
        mov CurrentSize,12
        mov edx,ecx
        mov edi,SDMAPos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SDMAStr
        mov edi,SDMAStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SDMASelectPos
        call PrintChoices

        movzx eax,_DEV_DMA
        mov esi,Offset DMAList
        call GetNumberPos

        call DoSelection
        jnc SelectDMAEnd

        jmp SelectOutput

SelectDMAEnd:

        mov ax,DMAList[2*ecx]
        mov _DEV_DMA,al

; 5- Select mixing rate

SelectFreq:

        cmp _DEV_Freq,-1
        je  SelectMode

        call Setup_ClearCenter

        mov esi,Offset FreqList
        call PrepareBuffer_DEC

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,20
        mov CurrentSize,20
        mov edx,ecx
        mov edi,SFreqPos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SFreqStr
        mov edi,SFreqStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SFreqSelectPos
        call PrintChoices

        movzx eax,_DEV_Freq
        mov esi,Offset FreqList
        call GetNumberPos

        call DoSelection
        jnc SelectFreqEnd

        jmp SelectOutput

SelectFreqEnd:

        mov ax,FreqList[2*ecx]
        mov _DEV_Freq,ax

; Select Output Mode (Mono/Stereo)

SelectMode:

        cmp _DEV_Mode,-1
        je USS_SetupEnd

        test _DEV_Mode,DM_Mixed   ; Select the Mixing Mode only for mixed DEV.
        jz USS_SetupEnd

        call Setup_ClearCenter

        call PrepareBuffer_Mode

        mov NbLines,cx

        mov ax,SelectAttrib
        mov ebx,SModeSize
        mov CurrentSize,SModeSize
        mov edx,ecx
        mov edi,SModePos
        mov SelectLinePos,edi
        call DrawWindow

        mov esi,Offset SModeStr
        mov edi,SModeStrPos
        mov ax,SelectAttrib
        call PrintStr

        mov eax,SModeSelectPos
        call PrintChoices

        mov ecx,0
        test _DEV_Mode,DM_Stereo
        jz SelectDefMono
        inc ecx
SelectDefMono:
        call DoSelection
        jnc SelectModeEnd

        jmp SelectOutput

SelectModeEnd:
        test _DEV_Mode,DM_Stereo
        jnz NoChangeSelection
        shl ecx,1
NoChangeSelection:
        test ecx,1
        jz SetMono
        and _DEV_Mode,Not DM_Mono
        or  _DEV_Mode,DM_Stereo      ; Set Stereo Mode
        jmp SetMonoEnd
SetMono:
        and _DEV_Mode,Not DM_Stereo
        or  _DEV_Mode,DM_Mono        ; Set Mono mode
SetMonoEnd:
        cmp ecx,1
        jbe NoSetOversampling
        or _DEV_Mode,DM_Interp       ; Set Oversampling On
NoSetOverSampling:


; Setup end


USS_SetupEnd:

        U_Free SelectBuffer

        movzx eax,SDEV_Number
        call USS_InitDev
        jc USS_SetupError

        cls
if _WATCOM
        mov _Error_Number,0
Endif
        clc
        ret
USS_NoDev:
        U_Free SelectBuffer

USS_SetupError:
        cls
If _WATCOM
        mov _Error_Number,eax
Endif
        mov _DEV_Offset,0
        stc
        ret
        
GoToPrevSelection:
        
USS_Setup  Endp
EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_AutoSetup: Useless Sound System Auto Setup                          ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
If UseAutoSetup                 ; * SETUP *
USS_AutoSetup  Proc

        call USS_DetectBestDev
        call USS_InitDev
        ret
USS_AutoSetup  Endp
EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_Init                                                                ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_Init Proc
        cmp SS_Started,1
        je USS_InitEnd

; ** Clear the USS Variables **

        mov edi,Offset USSVarStart
        mov ecx,Offset USSVarEnd
        sub ecx,edi
        push ds
        pop es
        cld
        xor eax,eax
        rep stosb
USS_InitEnd:

If UseNNA_DCT                   ; * SETUP *
        xor eax,eax
InitRChNrLoop:
        inc eax
        mov RChVirtualNb[eax-1],al
        cmp eax,MAX_PLChannels
        jb  InitRChNrLoop

        xor eax,eax
InitVChNrLoop:
        mov VChRealNb[eax],al
        inc eax
        cmp eax,MAX_SSChannels
        jb  InitVChNrLoop
Endif
        ret
USS_Init Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetActiveChannels                                                   ณ
;ณ                                                                         ณ
;ณ Input: EAX Number of channels to use.                                   ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error code in EAX.                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_SetActiveChannels Proc
        cmp eax,MAX_SSCHANNELS
        ja USS_SetActiveChannelsErr

        mov SSActiveChannels,eax

        clc
        ret
USS_SetActiveChannelsErr:
        mov eax,SE_Channels
        stc
        ret
USS_SetActiveChannels Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_StartOutput                                                         ณ
;ณ                                                                         ณ
;ณ Input: ESI Periodic function to call                                    ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error code in EAX.                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_StartOutput Proc
        mov eax,SE_NoDevice
        cmp _DEV_Offset,0
        je USS_StartOutputError

        mov eax,SE_Started
        cmp SS_Started,0
        jne USS_StartOutputError

        mov SS_Started,1

; ** Start the Output **

        mov USS_PeriodicProc,esi
        mov edx,_DEV_Offset
        call D_StartOutput[edx]
        jc USS_StartOutputError

USS_StartOutputEnd:
        clc
        ret
USS_StartOutputError:
        stc
        ret
USS_StartOutput Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_StopOutput                                                          ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Error in EAX                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_StopOutput Proc
        mov edx,_DEV_Offset
        mov eax,SE_NoDevice
        or edx,edx
        jz USS_StartOutputError

        cmp SS_Started,1
        jne USS_StartOutputEnd

        mov SS_Started,0

        mov esi,USS_PeriodicProc
        call D_StopOutput[edx]
        jc USS_StopOutputError

USS_StopOutputEnd:
        clc
        ret
USS_StopOutputError:
        stc
        ret
USS_StopOutput Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_LoadSampleMode                                                      ณ
;ณ                                                                         ณ
;ณ Input: EAX=0 Load samples as 'Playable' samples (load in sound device)  ณ
;ณ        EAX=1 Load samples as 'Initial' samples  (load in memory)        ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if Use_SampleLoadMode
USS_LoadSampleMode Proc

        mov LoadInitialSamples,eax
        ret
USS_LoadSampleMode Endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_LoadSample                                                          ณ
;ณ                                                                         ณ
;ณ Input: EDI Sample structure Offset                                      ณ
;ณ        ESI Sample data Offset                                           ณ
;ณ                                                                         ณ
;ณ Output: EDI Sample structure Offset                                     ณ
;ณ         CF Set => Error in EAX                                          ณ
;ณ                                                                         ณ
;ณ Warning: it musn't change ebp.                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_LoadSample Proc

if Use_SampleLoadMode           ; * SETUP *
        cmp LoadInitialSamples,0
        je LoadPlayableSample

; ** Sample in 'initial' mode **


        and SFlag[edi],Not SF_Initial
        stc
        ret

; ** Sample in 'playable' mode **

LoadPlayableSample:
        test SFlag[edi],SF_Initial
        jz LoadSampleData

; create a new sample header...
        push esi
        mov esi,edi

        U_Calloc USSSampleSize
        mov edi,eax

        push ds
        pop es
        cld
        mov ecx,USSSampleSize
        rep movsb

        and SFlag[edi],Not SF_Initial
        
        mov edi,eax
        pop esi

LoadSampleData:
endif                           ; Use_SampleLoadMode

        mov edx,_DEV_Offset
        or edx,edx
        jz USS_LoadSampleEnd
        push edi                        ; Save edi
        call D_LoadSample[edx]
        pop edi
USS_LoadSampleEnd:
        ret
USS_LoadSample EndP

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_FreeSample                                                          ณ
;ณ                                                                         ณ
;ณ Input: EDI Sample structure offset                                      ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Warning: FreeSample doesn't free the sample header but only the data    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_FreeSample Proc

if Use_SampleLoadMode           ; * SETUP *
        test SFlag[edi],SF_Initial
        jz FreePlayableSample

        ret

FreePlayableSample:
endif                           ; Use_SampleLoadMode

        mov edx,_DEV_Offset
        or edx,edx
        jz USS_FreeSampleEnd
        call D_FreeSample[edx]
USS_FreeSampleEnd:
        ret
USS_FreeSample EndP

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetAmpli                                                            ณ
;ณ                                                                         ณ
;ณ Input: EAX Amplification value                                          ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: ?                                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetAmpli Proc

        mov edx,_DEV_Offset
        or edx,edx
        jz USS_SetAmpliEnd
        call D_SetAmpli[edx]
USS_SetAmpliEnd:
        ret
USS_SetAmpli EndP

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetGlobalVolume                                                     ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: EAX Global Volume                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If UseGlobalVolume              ; * SETUP *
USS_GetGlobalVolume Proc
        movzx eax,SSGlobalVol
        ret
USS_GetGlobalVolume Endp
EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetGlobalVolume                                                     ณ
;ณ                                                                         ณ
;ณ Input: AL Global Volume (0-64)                                          ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ณ! Warning: SSActiveChannels must be correctly set before (default=32)   !ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If UseGlobalVolume              ; * SETUP *
USS_SetGlobalVolume Proc
        cmp al,80h
        jbe GVolOk
        mov al,80h
GVolOk:
        mov SSGlobalVol,al

; ** Ask to change all Channel volume **
        push edx
        xor edx,edx
USS_SetGlobalVolumeLoop:
        or VChControl[2*edx],CC_ChVolume
        inc edx
        cmp edx,SSActiveChannels
        jne USS_SetGlobalVolumeLoop
        pop edx
        ret
USS_SetGlobalVolume Endp
EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetChannelVolume: Read global channel volume                        ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: AL Volume                                                       ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If UseChannelVolume             ; * SETUP *

USS_GetChannelVolume Proc

if UseNNA_DCT                   ; * SETUP *
        mov al,RChannelVol[ebp]
else
        mov al,VChannelVol[ebp]
endif
        ret
USS_GetChannelVolume Endp

EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetChannelVolume: Write global channel volume                       ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Channel Volume                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If UseChannelVolume             ; * SETUP *

USS_SetChannelVolume Proc

        cmp al,40h
        jbe ChVolumeOk
        mov al,40h
ChVolumeOk:

If UseNNA_DCT                   ; * SETUP *
        mov RChannelVol[ebp],al
        call GetVirtualEBP
        jc USS_SetChannelVolumeEnd
endif

        mov VChannelVol[ebp],al

        or VChControl[2*ebp],CC_ChVolume
USS_SetChannelVolumeEnd:

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret
USS_SetChannelVolume Endp

EndIf


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_StartInstrument: Starts an instrument in instrument mode or a sampleณ
;ณ                                                                         ณ
;ณ Input:  EBP Channel Number                                              ณ
;ณ         EAX Instrument/Sample Offset                                    ณ
;ณ         EBX Note (1->120)                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax ebx esi                                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_StartInstrument Proc

if USENNA_DCT                   ; * SETUP *
        mov OldEBP,ebp
        mov EAXSave,eax
        mov InstrAdress,0
        mov SmpAdress,0
endif

        or eax,eax
        je USS_StartInstrumentErr
        or ebx,ebx                      ; ebx = 0 ?
        je USS_StartInstrumentErr       ; Err: Incorrect Note
        cmp ebx,120
        ja USS_StartInstrumentErr       ; Err: Incorrect Note

                                        ; Note in 1-120 => Ok
        mov esi,eax

if UseInstrumentMode            ; * SETUP *
        cmp dword ptr [esi],'LPMS'
        je StI_SampleMode

;** Get Instrument Address **

if USENNA_DCT                   ; * SETUP *
        mov InstrAdress,esi
else
        mov VChInsAdress[4*ebp],esi     ; Save instrument offset
endif

;** Get Sample Number **
        movzx eax,ISNumber[esi+ebx-1]   ; @@ a vrifier pour .IT !
        or eax,eax                      ; eax=0 ?
        jz USS_StartInstrumentErr       ; Err: No Sample for this note
        dec eax

        cmp eax,MAX_Samples             ; Is Sample number correct ?
        jae USS_StartInstrumentErr      ; Err: Incorrect sample number

;** Get the new note (IT) **

if UseNoteTable                 ; * SETUP *
        test IFlg[esi],IF_IT
        jz NoNoteChange
        or ebx,ebx
        jz NoNoteChange
        movzx ebx,INote[esi+ebx-1]
        inc ebx
NoNoteChange:
endif   ; UseNoteTable

;** Get Sample @ **

        mov esi,ISTable[esi]
        mov esi,[esi+4*eax]


endif

;** Get Sample Address **
StI_SampleMode:

if USENNA_DCT                   ; * SETUP *
        mov SmpAdress,esi
else
        mov VChSmpAdress[4*ebp],esi     ; Sample Address
endif

if UseNNA_DCT                   ; * SETUP *
        mov NoteSave,ebx
        
        pushad
        call DoNNA_DCA
        popad
        
        call GetVirtualEBP
        jc USS_StartInstrumentErr

        mov esi,InstrAdress
        mov VChInsAdress[4*ebp],esi
        mov esi,SmpAdress
        mov VChSmpAdress[4*ebp],esi
endif
        or VChControl[2*ebp],CC_StopVoice ; Stop Prev sound before starting one


if UseNNA_DCT                   ; * SETUP *
        mov VChNote[ebp],bl
endif
        call Get_NotePeriod             ; Get note period
        jc USS_StartInstrumentErr       ; Err: can't get the period

        call USSI_SetPeriod             ; Set channel period

        test SFlag[esi],SF_Loaded       ; Is sample loaded ?
        jz USS_StartInstrumentErr       ; Err: Sample data not loaded

; ** Get Sample data Offset **
        mov VChSmpOffset[4*ebp],0


        or VChControl[2*ebp],CC_ChSample+CC_ChVolume+CC_Playing

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret

USS_StartInstrumentErr:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        stc
        ret
USS_StartInstrument Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_ChangeInstrument: Change an instrument without note change.         ณ
;ณ                                                                         ณ
;ณ Input:  EBP Channel Number                                              ณ
;ณ         EAX Instrument/Sample Offset                                    ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax ebx esi                                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if UseSChange                   ; * SETUP
USS_ChangeInstrument Proc

if USENNA_DCT                   ; * SETUP *
        mov OldEBP,ebp
        mov NoteSave,-1
        mov EAXSave,eax
        mov InstrAdress,0
        mov SmpAdress,0
endif

        or eax,eax
        je USS_ChangeInstrumentErr

        mov esi,eax

if UseInstrumentMode            ; * SETUP *
        cmp dword ptr [esi],'LPMS'
        je ChI_SampleMode
        
;** Get Instrument Address **

if USENNA_DCT                   ; * SETUP *
        mov InstrAdress,esi
else
        mov VChInsAdress[4*ebp],esi     ; Save instrument offset
endif

;** Get Sample Number **
        movzx eax,ISNumber[esi+ebx-1] ; @@ a vrifier pour .IT !
        or eax,eax                      ; eax=0 ?
        jz USS_ChangeInstrumentErr      ; Err: No Sample for this note
        dec eax

        cmp eax,MAX_Samples             ; Is Sample number correct ?
        jae USS_ChangeInstrumentErr     ; Err: Incorrect sample number

        mov esi,ISTable[esi]
        mov esi,[esi+4*eax]

endif

;** Get Sample Address **
ChI_SampleMode:

if USENNA_DCT                   ; * SETUP *
        mov SmpAdress,esi
else
        mov VChSmpAdress[4*ebp],esi     ; Sample Address
endif

if UseNNA_DCT                   ; * SETUP *
        pushad
        call DoNNA_DCA
        popad
        
        call GetVirtualEBP
        jc USS_StartInstrumentErr

        mov esi,InstrAdress
        mov VChInsAdress[4*ebp],esi
        mov esi,SmpAdress
        mov VChSmpAdress[4*ebp],esi
endif
        or VChControl[2*ebp],CC_StopVoice ; Stop Prev sound before starting one

        test SFlag[esi],SF_Loaded       ; Is sample loaded ?
        jz USS_ChangeInstrumentErr      ; Err: Sample data not loaded

; ** Get Sample data Offset **
        mov VChSmpOffset[4*ebp],0


        or VChControl[2*ebp],CC_ChSample+CC_ChVolume+CC_Playing

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret

USS_ChangeInstrumentErr:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        stc
        ret
USS_ChangeInstrument Endp
endif   ;UseSChange

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_InitInstrEnv                                                        ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_InitInstrEnv Proc

if UseInstrumentMode            ; * SETUP *

if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_InitInstrEnvEnd
endif
        xor eax,eax
        mov VChFadeoutVol[2*ebp],08000h
        mov VChVolEnvPos[2*ebp],ax
        mov VChVolEnvSegPos[2*ebp],ax
        mov VChEnvVol[ebp],64
        mov VChPanEnvPos[2*ebp],ax
        mov VChPanEnvSegPos[2*ebp],ax
        mov VChEnvPan[ebp],32

        mov VChAVibPos[ebp],al
        mov VChAVibSwpPos[ebp],al

        and VChControl[2*ebp],Not (CC_FadeVol+CC_Release)
        or VChControl[2*ebp],CC_ChVolume+CC_ChPanning
USS_InitInstrEnvEnd:

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
endif   ;UseInstrumentMode
        ret
USS_InitInstrEnv Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetEnvPos: Set instrument envelope position                         ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel number                                               ณ
;ณ        AL Envelope position                                             ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetEnvPos Proc

if UseInstrumentMode            ; * SETUP *

if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_SetEnvPosEnd
endif

        mov edi,VChInsAdress[4*ebp]
	or edi,edi                      ; edi=0 ?
	jz USS_SetEnvPosEnd             ; No instrument -> No Set pos

        movzx eax,al

        test IVType[edi],E_On   ; ** Set Vol Pos **
	jz  Set_PanningPos

        movzx ecx,IVPoints[edi]
V_SetEnvPosLoop:
        movzx edx,word ptr IVEnvelope[edi+4*(ecx-1)]
        cmp edx,eax
        ja VPos_NotFound
        sub edx,eax
        neg edx
        dec ecx
        jmp VPos_Found
VPos_NotFound:
        dec ecx
        jnz V_SetEnvPosLoop

VPos_Found:
        mov VChVolEnvPos[2*ebp],cx
        mov VChVolEnvSegPos[2*ebp],dx

Set_PanningPos:                 ; ** Set panning Pos **
        test IPType[edi],E_On
	jnz  USS_SetEnvPosEnd

        movzx ecx,IPPoints[edi]
P_SetEnvPosLoop:
        movzx edx,word ptr IPEnvelope[edi+4*(ecx-1)]
        cmp edx,eax
        ja PPos_NotFound
        sub edx,eax
        neg edx
        dec ecx
        jmp PPos_Found
PPos_NotFound:
        dec ecx
        jnz P_SetEnvPosLoop

PPos_Found:
        mov VChPanEnvPos[2*ebp],cx
        mov VChPanEnvSegPos[2*ebp],dx

USS_SetEnvPosEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif   ;UseNNA_DCT
endif   ;UseInstrumentMode
        ret
USS_SetEnvPos Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetSampleVolume: Get the Volume of the current channel sample.      ณ
;ณ                                                                         ณ
;ณ Input:  EBP Channel Number                                              ณ
;ณ                                                                         ณ
;ณ Output: CF Set -> There is no sample on this channel.                   ณ
;ณ         EAX Sample Volume                                               ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_GetSampleVolume Proc
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_GetSampleVolumeErr
endif

        mov esi,VChSmpAdress[4*ebp]
        or esi,esi
        je USS_GetSampleVolumeErr       ; Err: No sample

        movzx eax,SDefVolume[esi]

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif        
        clc
        ret
USS_GetSampleVolumeErr:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        stc
        ret
USS_GetSampleVolume Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetSamplePanning: Get the Panning of the current channel sample.    ณ
;ณ                                                                         ณ
;ณ Input:  EBP Channel Number                                              ณ
;ณ                                                                         ณ
;ณ Output: CF Set -> There is no sample on this channel or no sample pann. ณ
;ณ         EAX Sample Volume                                               ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_GetSamplePanning Proc
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_GetSamplePanningErr
endif

        mov esi,VChSmpAdress[4*ebp]
        or esi,esi                      ; esi=0 ?
        je USS_GetSamplePanningErr      ; Err: No sample

        test SFlag[esi],SF_UseIPanning
        jnz USS_Get_InstrPanning

        test SFlag[esi],SF_UsePanning
        jz USS_GetSamplePanningErr      ; Err: sample panning turned off
                                        ; (in MOD files, for example)
        movzx eax,SDefPanning[esi]

        jmp USS_GetSamplePanningEnd

USS_Get_InstrPanning:   ;Get Instrument default panning instead of sample one.

USS_GetSamplePanningEnd:        
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret
USS_GetSamplePanningErr:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        stc
        ret
USS_GetSamplePanning Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetSampleOffset                                                     ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        EAX Sample Offset                                                ณ
;ณ        EBX<>0 Test with the sample length                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax esi                                                         ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู



USS_SetSampleOffset Proc

if (UseSetOffset or UseRetrig or UseMRetrig or UseITMRetrig)    ; * SETUP *

if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_SetSampleOffsetEnd
endif

; Get Sample data Offset
        mov esi,VChSmpAdress[4*ebp]
        or esi,esi                      ; esi=0 ?
        jz USS_SetSampleOffsetEnd       ; Err: No sample (Address=0)

        test SFlag[esi],SF_Loaded       ; Is sample loaded ?
        jz   USS_SetsampleOffsetEnd     ; Err: Sample data not loaded

        or ebx,ebx
        jz NoSampleLenTest

        cmp SLength[esi],eax
        jb  USS_SetSampleOffsetEnd
NoSampleLenTest:

        mov VChSmpOffset[4*ebp],eax

;@@ Pas de test sur la position du SetSampleOffset !

        or VChControl[2*ebp],CC_StopVoice+CC_ChSample+CC_ChVolume+CC_Playing

USS_SetSampleOffsetEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif   ;UseNNA_DCT

endif   ;(UseSetOffset or UseRetrig or UseMRetrig or UseITMRetrig)
        ret
USS_SetSampleOffset Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetNote : Change the note for the current channel.                  ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Note                                                         ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ณ Change: eax ebx esi                                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetNote Proc
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_SetNoteEnd
endif
        mov bl,al

; ** Get Sample Address **
        mov esi,VChSmpAdress[4*ebp]

; ** Get Periode **

if UseNNA_DCT                   ; * SETUP *
        mov VChNote[ebp],bl
endif
        call Get_NotePeriod
        jc USS_SetNoteEnd

        mov VChPeriod[2*ebp],ax
        or  VChControl[2*ebp],CC_ChPeriod

USS_SetNoteEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        ret
USS_SetNote Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetPeriod                                                           ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: AX Period                                                       ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_GetPeriod Proc
if UseNNA_DCT                   ; * SETUP *
        movzx eax,RChPeriod[2*ebp]
else
        movzx eax,VChPeriod[2*ebp]
endif
        ret
USS_GetPeriod Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetPeriod                                                           ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AX New Periode                                                   ณ
;ณ                                                                         ณ
;ณ Output: AX, New period with range limitation.                           ณ
;ณ         CF Set -> Period was out of range.                              ณ
;ณ                                                                         ณ
;ณ Change: EAX EBX                                                         ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetPeriod Proc
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_SetPeriodEnd
endif

        call USSI_SetPeriod

USS_SetPeriodEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        ret
USS_SetPeriod Endp


USSI_SetPeriod Proc

; * Test period limits **
        mov bx,SSPeriodMin
        cmp ax,bx
        jge NotTooLow
        mov ax,bx
        mov bl,1
        jmp ChangePeriod
NotTooLow:
        mov bx,SSPeriodMax
        cmp ax,bx
        jle NotTooHigh
        mov ax,bx
        mov bl,1
        jmp ChangePeriod
NotTooHigh:
        xor ebx,ebx
ChangePeriod:
        cmp VChSmpAdress[4*ebp],0
        je USSI_SetPeriodEnd

        mov VChPeriod[2*ebp],ax

if UseNNA_DCT                   ; * SETUP *
        movzx ecx,VChRealNb[ebp]
        mov RChPeriod[2*ecx],ax
endif

        or VChControl[2*ebp],CC_ChPeriod

        or ebx,ebx
        jnz USSI_SetPeriodErr
        
USSI_SetPeriodEnd:
        clc
        ret
USSI_SetPeriodErr:
        stc
        ret
USSI_SetPeriod Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetNotePeriod : Get the period from the note and channel number.    ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        BX  Note Number                                                  ณ
;ณ                                                                         ณ
;ณ Output: EAX Period                                                      ณ
;ณ                                                                         ณ
;ณ Change: eax ebx esi                                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_GetNotePeriod Proc
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_GetNotePeriodEnd
endif
        mov esi,VChSmpAdress[4*ebp]     ; Get the current sample Address
        call Get_NotePeriod

USS_GetNotePeriodEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        ret
USS_GetNotePeriod Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetVolume: Read channel volume                                      ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: AL Volume                                                       ณ
;ณ                                                                         ณ
;ณ Change: eax                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_GetVolume Proc
if UseNNA_DCT                   ; * SETUP *
        mov al,RChVolume[ebp]
else
        mov al,VChVolume[ebp]
endif
        ret
USS_GetVolume Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetVolume: Write channel volume                                     ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Channel Volume                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetVolume Proc

        cmp al,40h
        jbe VolumeOk
;       dwrite 'Wrong volume'
;       call _dprint_dec
        mov al,40h
VolumeOk:

if UseNNA_DCT                   ; * SETUP *
        mov RChVolume[ebp],al
        call GetVirtualEBP
        jc USS_SetVolumeEnd
endif

        mov VChVolume[ebp],al

        or VChControl[2*ebp],CC_ChVolume

USS_SetVolumeEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret
USS_SetVolume Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_GetPanning                                                          ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: AL Panning                                                      ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_GetPanning Proc
if UseNNA_DCT                   ; * SETUP *
        mov al,RChPanning[ebp]
else
        mov al,VChPanning[ebp]
endif
        ret
USS_GetPanning Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetPanning                                                          ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Channel Panning                                              ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_SetPanning Proc

if UseNNA_DCT                   ; * SETUP *
        mov RChPanning[ebp],al
        call GetVirtualEBP
        jc USS_SetPanningEnd
endif

        mov VChPanning[ebp],al

        or VChControl[2*ebp],CC_ChPanning

USS_SetPanningEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret
USS_SetPanning Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_SetNNA                                                              ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Channel NNA                                                  ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู


USS_SetNNA Proc
if UseNNA_DCT                   ; * SETUP *
        mov RChNNA[ebp],al
endif
        ret
USS_SetNNA Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_PastNoteAction                                                      ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ        AL  Channel NNA                                                  ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_PastNoteControl Proc
if UseNNA_DCT                   ; * SETUP *
        xor ecx,ecx
DoPNALoop:

        mov ebx,ebp
        cmp VChRealNb[ecx],bl   ; Is it a channel 'controled' by the current
        jne PNA_LoopEnd         ; channel ?

        test VChControl[2*ecx],CC_Playing
        jz PNA_LoopEnd

        test VChControl[2*ecx],CC_BackGrnd
        jz PNA_LoopEnd


        cmp al,NNA_Cut
        je PNA_Do_Cut

        cmp al,NNA_NoteFade
        je PNA_Do_NoteFade

        cmp al,NNA_NoteOff
        je PNA_Do_NoteOff

        jmp PNA_LoopEnd
PNA_Do_Cut:
        or VChControl[2*ecx],CC_StopVoice

        jmp PNA_LoopEnd
PNA_Do_NoteOff:

        mov OldEBP,ebp
        mov ebp,ecx
        call VCh_NoteOff
        
        jmp PNA_LoopEnd
PNA_Do_NoteFade:

        or VChControl[2*ecx],CC_FadeVol

PNA_LoopEnd:
        inc ecx
        cmp ecx,SSActiveChannels
        jne DoPNALoop
endif        
        ret
USS_PastNoteControl Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_NoteCut : Cut the note.                                             ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_NoteCut Proc
;        write ' NCt'
if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_NoteCutEnd
endif

        or VChControl[2*ebp],CC_StopVoice

USS_NoteCutEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
        ret
USS_NoteCut Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_NoteFade : Fade the note.                                           ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_NoteFade Proc
;        write ' NFd'

if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_NoteFadeEnd
endif

VCh_NoteFade:

        or VChControl[2*ebp],CC_FadeVol

USS_NoteFadeEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        ret
USS_NoteFade Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_KeyOff : Release the note.                                          ณ
;ณ                                                                         ณ
;ณ Input: EBP Channel Number                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

USS_KeyOff Proc
;        write ' KeyOff '

if UseNNA_DCT                   ; * SETUP *
        call GetVirtualEBP
        jc USS_KeyOffEnd
endif

VCh_NoteOff:

        or VChControl[2*ebp],CC_Release+CC_DoRelease

        mov edi,VChInsAdress[4*ebp]
	or edi,edi                      ; edi=0 ?
	jz KO_CuteNote                  ; No instrument -> Do a note cut

        test IFlg[edi],IF_ReleaseFade   ; do fadeout ?
        jnz KO_FadeVolume

KO_CuteNote:        
        mov edi,VChSmpAdress[4*ebp]
        or edi,edi
        jz USS_KeyOffEnd

        test SFlag[edi],SF_IT            ; no cut if it's an IT Sample
        jnz USS_KeyOffEnd

        or VChControl[2*ebp],CC_StopVoice

if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
	ret
KO_FadeVolume:

        or VChControl[2*ebp],CC_FadeVol

USS_KeyOffEnd:
if UseNNA_DCT                   ; * SETUP *
        mov ebp,OldEBP
endif
        clc
	ret
USS_KeyOff Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_UpdateInstr: Do KeyOff, fadeout and envelopes                       ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: --                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

P0    EQU Word Ptr
Val0  EQU Word Ptr 2
P1    EQU Word Ptr 4
Val1  EQU Word Ptr 6

USS_UpdateInstr proc

if UseInstrumentMode            ; * SETUP *

        mov ebp,0
ProCInstrLoop:
	mov edi,VChInsAdress[4*ebp]
	or edi,edi                      ;edi=0 ?
	jz ProcNextInstr

        test VChControl[2*ebp],CC_Playing
        jz ProcNextInstr

;                      ****** Do Fadeout ******

if UseFadeout                   ; * SETUP *
        test VChControl[2*ebp],CC_FadeVol
        jz  NoFadeOut
        mov ax,VChFadeoutVol[2*ebp]
        mov bx,IVFadeOut[edi]
        sub ax,bx
        jnc FadeOutEnd
        xor eax,eax                         ;eax=0
        or VChControl[2*ebp],CC_StopVoice   ;Fade End => Stop voice
FadeOutEnd:
	mov VChFadeOutVol[2*ebp],ax
        or VChControl[2*ebp],CC_ChVolume
NoFadeOut:
endif   ; UseFadeout

;                   ****** Do Volume Envelope ******
;
;
;   V1              /
;                 /  |
;               /    |
;   Vol       /      |
;           / |      |
;         /   |      |
;   Vo  /     |      |
;      |------|------|
;      |      |      |
;      |      |      |
;      |     pos     |
;      |             |
;      |<----------->|
;      Po   DPos    P1
;
;Thales => (Vol-Vo)*DPos = (V1-Vo)*pos
;       =>  Vol          =  Vo + ((V1-Vo)*pos)/DPos
;
; edi, Instrument Offset ebp, Instrument number

if UseVolumeEnv                 ; * SETUP *

        test IVType[edi],E_On           ;Is there a volume envelope ?
        jz NoVEnv

if UseIT                        ; * SETUP *
        test IFlg[edi],IF_IT
        jnz UseITVolumeEnv
endif

if UseFT2                       ; * SETUP *
        push edi
        lea edi,IVType[edi]
        mov esi,Offset VChVolEnvPos
        call DoXMEnv
        mov VChEnvVol[ebp],al
        or VChControl[2*ebp],CC_ChVolume
        pop edi
endif   ;UseFT2

        jmp NoVEnv

if UseIT                        ; * SETUP *
UseITVolumeEnv:
        push edi
        lea edi,IVType[edi]
        mov esi,Offset VChVolEnvPos
        call DoITEnv
        jnc NoITVEnvEnd
        or VChControl[2*ebp],CC_FadeVol     ;Envelope end => Start Fade
        or eax,eax
        jnz NoITVEnvEnd
        or VChControl[2*ebp],CC_StopVoice   ;Envelope end=0 => Stop
NoITVEnvEnd:
        mov VChEnvVol[ebp],al
        or VChControl[2*ebp],CC_ChVolume
        pop edi
endif   ;UseIT

NoVEnv:
endif
        

;                 ****** Do Panning Envelope ******

if UsePannEnv                   ; * SETUP *
        test IPType[edi],E_On           ;Is there a panning envelope ?
        jz NoPEnv

if UseIT                        ; * SETUP *
        test IFlg[edi],IF_IT
        jnz UseITPanningEnv
endif   ;UseIT

if UseFT2                       ; * SETUP *
        push edi
        lea edi,IPType[edi]
        mov esi,Offset VChPanEnvPos
        call DoXMEnv
        mov VChEnvPan[ebp],al
        or VChControl[2*ebp],CC_ChPanning
        pop edi
endif   ;UseFT2

        jmp NoPEnv

if UseIT                        ; * SETUP *
UseITPanningEnv:
        push edi
        lea edi,IPType[edi]
        mov esi,Offset VChPanEnvPos
        call DoITEnv
        add al,32
        mov VChEnvPan[ebp],al
        or VChControl[2*ebp],CC_ChPanning
        pop edi
endif   ;UseIT
NoPEnv:
endif   ;UsePannEnv

ProcNextInstr:                   ; Channels Loop
        inc ebp
        cmp ebp,SSActiveChannels
        jne ProcInstrLoop
endif

; ** Process Samples auto vibrato **

if UseAutoVibrato               ; * SETUP *
        mov ebp,0
ProcSampleLoop:
        mov edi,VChSmpAdress[4*ebp]
        or edi,edi              ; edi=0 ?
        jz ProcNextSample
	
        test VChControl[2*ebp],CC_Playing
        jz ProcNextSample

;                   ****** Do Auto Vibrato ******

        movzx edx,SVibDepth[edi]
        or edx,edx
        jz NoAVib

        mov ch,SVibRate[edi]
        mov cl,SVibType[edi]

        movzx ebx,VChAVibPos[ebp]
        call GetVibData
        mov VChAVibPos[ebp],bl

        movzx cx,VChAVibSwpPos[ebp]  ; Apparently, this vib sweep is faster
        cmp cl,SVibSweep[edi]        ; than FT2 one... (?????)
        jae NoAVSweep                ; I'm too lazy to correct this ;-)
        imul cx
        movzx cx,SVibSweep[edi]
        idiv cx
        inc VChAVibSwpPos[ebp]
NoAVSweep:
        sar ax,8
        neg ax
        mov VChaVibPitch[2*ebp],ax

        or VChControl[2*ebp],CC_ChPeriod

NoAVib:

ProcNextSample:                  ; Channels Loop
        inc ebp
        cmp ebp,SSActiveChannels
        jne ProcSampleLoop
endif   ;UseAutoVibrato

        clc
        ret
USS_UpdateInstr endp


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DoXMEnv:                                                                ณ
;ณ                                                                         ณ
;ณ Input: EDI Pointer to the envelope structure                            ณ
;ณ        ESI Pointer to the envelope data structure (EnvPos, EnvSegPos)   ณ
;ณ                                                                         ณ
;ณ Output: EAX Envelope value                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if (UsePannEnv or UseVolumeEnv) ; * SETUP *
if UseFT2                       ; * SETUP *
P0    EQU Word Ptr
Val0  EQU Word Ptr 2
P1    EQU Word Ptr 4
Val1  EQU Word Ptr 6

DoXMEnv Proc
        cmp VChEnvSegPos[esi+2*ebp],0
        jne XMEnvNoLoop

        movzx edx,VChEnvPos[esi+2*ebp]

; ** Do Sustain **

        test EnvType[edi],E_Sustain ;Sustain Off => Always do loop
        jz XMEnvDoLoop

        cmp dl,EnvSustain[edi]     ;When fade is on, do not loop if sustain
        jne XMEnvDoLoop            ;point is Loop end point 
                                   ;(fade is release with FT2)

        test VChControl[2*ebp],CC_FadeVol ;Don't loop when fade is on
        jnz XMEnvNoLoop                   ;and current point is sustain

; ** Do Loop **
XMEnvDoLoop:
        test Envtype[edi],E_Loop
        jz XMEnvNoLoop
	
        cmp dl,EnvLoopEnd[edi]
        jne XMEnvNoLoop
        mov dl,EnvLoopStart[edi]
        mov VChEnvPos[esi+2*ebp],dx
XMEnvNoLoop:

; ** Get Envelope value **
        movzx eax,VChEnvPos[esi+2*ebp]
        lea ecx,EnvEnvelope[edi+4*eax]
        inc al
        cmp al,EnvPoints[edi]             ;Is it the envelope End ?
        je XMEnvLast
        movsx eax,P0[ecx]
        movsx ebx,P1[ecx]
        sub ebx,eax
        mov DPos,bx
        movsx eax,Val1[ecx]
        movsx edx,Val0[ecx]
        sub eax,edx
        imul VChEnvSegPos[esi+2*ebp]
        idiv DPos
        add ax,Val0[ecx]         ; al=Val0+((Val1-Val0)*chVolEnvSegPos)/DPos

; ** Process Sustain if no KeyOff **
	cmp VChEnvSegPos[esi+2*ebp],0
	jne XMEnvNoSustain
        test EnvType[edi],E_Sustain
        jz XMEnvNoSustain
        test VChControl[2*ebp],CC_FadeVol ; (KeyOff for FT2)
        jnz XMEnvNoSustain                ; If KeyOff, No sustain
        movzx edx,VChEnvPos[esi+2*ebp]
        cmp dl,EnvSustain[edi]
        je XMEnvEnd                       ;Do volume Sustain

XMEnvNoSustain:
        movzx edx,VChEnvSegPos[esi+2*ebp]
        inc edx
        cmp dx,DPos
        jb XMEnvNoStep
        xor edx,edx                     ;Envelope Pos is at an envelope point
        inc VChEnvPos[esi+2*ebp]
XMEnvNoStep:
        mov VChEnvSegPos[esi+2*ebp],dx
        jmp XMEnvEnd

XMEnvLast:
        mov ax,Val0[ecx]
XMEnvEnd:

        ret
DoXMEnv Endp
endif   ;UseFT2
endif   ;(UsePannEnv or UseVolumeEnv)

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DoITEnv:                                                                ณ
;ณ                                                                         ณ
;ณ Input: EDI Pointer to the envelope structure                            ณ
;ณ        ESI Pointer to the envelope data structure (EnvPos, EnvSegPos)   ณ
;ณ                                                                         ณ
;ณ Output: EAX Envelope value                                              ณ
;ณ         CF Set => Last Envelope point.                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if (UsePannEnv or UseVolumeEnv) ; * SETUP *
if UseIT                        ; * SETUP *

ITVal0  EQU Byte Ptr
ITP0    EQU Word Ptr 1
ITVal1  EQU Byte Ptr 3
ITP1    EQU Word Ptr 4

DoITEnv Proc
        mov Sustained,0
        
        cmp VChEnvSegPos[esi+2*ebp],1
        ja ITEnvNoLoop
        
        movzx edx,VChEnvPos[esi+2*ebp]

        test VChControl[2*ebp],CC_Release
        jnz ITEnvDoLoop

; ** Do Sustain **

        test EnvType[edi],EIT_SLoop ;Sustain loop Off => Do loop
        jz ITEnvDoLoop
        
        cmp dl,EnvSustEnd[edi]
        jb ITEnvNoLoop
        mov Sustained,1
        mov dl,EnvSustain[edi]
        mov VChEnvPos[esi+2*ebp],dx
        mov VChEnvSegPos[esi+2*ebp],0
        jmp ITEnvNoLoop


ITEnvDoLoop:

; ** Do Loop **
        test Envtype[edi],EIT_Loop
        jz ITEnvNoLoop

ITEnvStartLoop:
        cmp dl,EnvLoopEnd[edi]
        jb ITEnvNoLoop
        mov sustained,1
        mov dl,EnvLoopStart[edi]
        mov VChEnvPos[esi+2*ebp],dx
        mov VChEnvSegPos[esi+2*ebp],0
ITEnvNoLoop:

; ** Get Envelope value **
        movzx eax,VChEnvPos[esi+2*ebp]
        mov ebx,eax
        shl ebx,1
        add ebx,eax
        lea ecx,EnvEnvelope[edi+ebx]    ;edi+3*eax
        inc al
        cmp al,EnvPoints[edi]           ;Is it the envelope End ?
        je ITEnvLast
        movzx eax,ITP0[ecx]
        movzx ebx,ITP1[ecx]
        sub ebx,eax
        mov DPos,bx
        movsx eax,ITVal1[ecx]
        movsx edx,ITVal0[ecx]
        sub eax,edx

        imul VChEnvSegPos[esi+2*ebp]
        idiv DPos

        movsx eax,ax
        movzx edx,ITVal0[ecx]
        add eax,edx               ; al=Val0+((Val1-Val0)*chVolEnvSegPos)/DPos

        movzx edx,VChEnvSegPos[esi+2*ebp]
        inc edx
        cmp dx,DPos
        jb ITEnvNoStep
        xor edx,edx                     ;Envelope Pos is at an envelope point
        inc VChEnvPos[esi+2*ebp]
ITEnvNoStep:
        mov VChEnvSegPos[esi+2*ebp],dx
        jmp ITEnvEnd

ITEnvLast:
        movzx eax,ITVal0[ecx]
        cmp Sustained,1         ; 'sustained' => It's not the End !
        je ITEnvEnd
        stc
        ret
ITEnvEnd:
        clc
        ret
DoITEnv Endp
endif   ;UseIT
endif   ;(UsePannEnv or UseVolumeEnv)

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_UpdateOutput                                                        ณ
;ณ                                                                         ณ
;ณ Input: -                                                                ณ
;ณ                                                                         ณ
;ณ Output: -                                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_UpdateOutput Proc

	mov ebp,0
ChannelLoop:
	mov edi,VChInsAdress[4*ebp]
	
	test VChControl[2*ebp],CC_ChPeriod
	jz   NoChPeriod

        movzx eax,VChPeriod[2*ebp]

; ** Add auto vibrato pitch **

if UseAutoVibrato               ; * SETUP *
        add ax,VChAVibPitch[2*ebp]
endif

; ** Set Frequency (Hz) **

	call SetFrequency

NoChPeriod:

	test VChControl[2*ebp],CC_ChVolume
	jz   NoChVolume

; ** Process the final volume calculation.
;
; I try to keep the maximum precision for volume processing.

	xor ecx,ecx
	xor edx,edx
        movzx eax,VChVolume[ebp]      ; vol = Sample volume (0-40h)

If UseGlobalVolume              ; * SETUP *
        movzx ecx,SSGlobalVol
        mul ecx                       ; vol * GlobalVol (0-80h)
        mov bl,7
else
        xor ebx,ebx
endif

If UseChannelVolume             ; * SETUP *
        movzx ecx,VChannelVol[ebp]
        mul ecx                       ; vol * ChannelVol (0-40h)
        add bl,6
endif

if UseFadeOut                   ; * SETUP *
        test VChControl[2*ebp],CC_FadeVol
        jz  NoFadeVol

        movzx ecx,VChFadeOutVol[2*ebp]
        mul ecx                       ; vol * fadeVol (0-8000h)
         
        shrd eax,edx,9
        add bl,6
NoFadeVol:
endif   ;UseFadeOut

if UseVolumeEnv                 ; * SETUP *
        or edi,edi                    ; Is it an instrument ?
        jz NoEnvVol                   ; No => No envelope volume
        movzx ecx,VChEnvVol[ebp]
        mul ecx                       ; vol * EnvelopeVol (0-40h)
        add bl,6
NoEnvVol:
endif   ;UseVolumeEnv

        ; edx-eax=Vol*CV*GV*EnvV*FadeV

If (UseGlobalVolume or UseChannelVolume or UseFadeOut or UseVolumeEnv)
If (UseSampleGVol or UseInstrumentGVol) ; * SETUP *
        sub bl,6
EndIf   ;(UseSampleGVol or UseInstrumentGVol)

        mov cl,bl
        shrd eax,edx,cl
If (UseSampleGVol or UseInstrumentGVol) ; * SETUP *
        mov bl,6
else
        xor ebx,ebx
EndIf   ;(UseSampleGVol or UseInstrumentGVol)
EndIf   ;(UseGlobalVolume or UseChannelVolume or UseFadeOut or UseVolumeEnv)

if UseSampleGVol                ; * SETUP *
        mov esi,VChSmpAdress[4*ebp]
        or esi,esi
        jz NoSampleVolume
        movzx ecx,SVolume[esi]
        mul ecx                       ; vol * SampleVol (0-40h)
        add bl,6
NoSampleVolume:        
endif   ;UseSampleGVol

if UseInstrumentGVol            ; * SETUP *
        or edi,edi
        jz NoInstrVolume
        movzx ecx,IGVolume[edi]
        mul ecx                       ; vol * InstrumentVol (0-80h)
        add bl,7        
NoInstrVolume:        
endif   ;UseInstrumentGVol
        
        ; edx-eax=Vol*CV*GV*EnvV*FadeV*(SV*IV)
If (UseSampleGVol or UseInstrumentGVol) ; * SETUP *
        mov cl,bl
        shrd eax,edx,cl        
endIf

        mov VChFVolume[ebp],al  ;Set Final Volume

NoChVolume:

        test VChControl[2*ebp],CC_ChPanning
        jz   NoChPanning

        movsx edx,VChPanning[ebp]
		
        or edi,edi
        jz NoEnvPann
        test IPType[edi],E_On
        jz NoEnvPann

        mov al,VChEnvPan[ebp]   ;FPan=Pan+(EnvPan-32)*(128-abs(Pan-128))/32
        sub al,32
        xor dl,dh
        imul dl
        shr eax,5
        add al,VChPanning[ebp]
        mov dl,al

NoEnvPann:

        mov VChFPanning[ebp],dl
	
NoChPanning:

        inc ebp
        cmp ebp,SSActiveChannels
        jne ChannelLoop

	
        mov edx,_DEV_Offset
        call D_UpdateSound[edx]

        clc
        ret
USS_UpdateOutput endp

;***************************************************************************
;**************************  Internal functions ****************************
;***************************************************************************

If UseNNA_DCT       

GetVirtualEBP Proc
        mov OldEBP,ebp
        cmp RChVirtualNb[ebp],0
        je NoChannelAllocated
        movzx ebp,RChVirtualNb[ebp]
        dec ebp
        clc
        ret
NoChannelAllocated:
        stc
        ret
GetVirtualEBP Endp

NNA DB 0
DCT DB 0
DCA DB 0

DoNNA_DCA Proc
        mov esi,EAXSave         ; Read the Instrument/Sample offset

        cmp RChVirtualNb[ebp],0
        jnz ChannelExist
        call AllocateChannel
        jc DoNNAErr
ChannelExist:

        mov NNA,NNA_Cut
        cmp dword ptr [esi],'TSNI'
        jne UseNNA_Stop

        movzx eax,INNA[esi]
        mov NNA,al

if UseDCT                       ; * SETUP *
        cmp IDCT[esi],DCT_Off   ; DCT/DCA ?
        je UseNNA_Stop


        xor ecx,ecx
DoDCTLoop:

        mov ebx,ebp
        cmp VChRealNb[ecx],bl   ; Is it a channel 'controled' by the current
        jne DCT_DCA_End         ; channel ?

        mov ebx,InstrAdress     ; AND Is it the same instrument ?
        cmp ebx,VChInsAdress[4*ecx]
        jne DCT_DCA_End

        test VChControl[2*ecx],CC_Playing
        jz DCT_DCA_End

; Ok, I can do the DCT check...

        cmp IDCT[esi],DCT_Note
        jne NoDCT_Note

        mov ebx,NoteSave
        cmp bl,VChNote[ecx]
        jne DCT_DCA_End

        jmp DoDCA
NoDCT_Note:        

        cmp IDCT[esi],DCT_Sample
        jne NoDCT_Sample

        mov ebx,SmpAdress
        cmp ebx,VChSmpAdress[4*ecx]
        jne DCT_DCA_End

        jmp DoDCA
NoDCT_Sample:

        cmp IDCT[esi],DCT_Instrument
        jne NoDCT_Instrument

        mov ebx,InstrAdress
        cmp ebx,VChInsAdress[4*ecx]
        jne DCT_DCA_End

        jmp DoDCA
NoDCT_Instrument:

DoDCA:

        cmp IDCA[esi],DCA_Cut
        je DoDCA_Cut

        cmp IDCA[esi],DCA_NoteFade
        je DoDCA_NoteFade

        cmp IDCA[esi],DCA_NoteOff
        je DoDCA_NoteOff

        jmp DCT_DCA_End
DoDCA_Cut:
        or VChControl[2*ecx],CC_StopVoice

        jmp DCT_DCA_End
DoDCA_NoteOff:

        mov OldEBP,ebp
        mov ebp,ecx
        call VCh_NoteOff
        
        jmp DCT_DCA_End
DoDCA_NoteFade:

        or VChControl[2*ecx],CC_FadeVol

DCT_DCA_End:
        inc ecx
        cmp ecx,SSActiveChannels
        jne DoDCTLoop
endif   ;UseDCT

UseNNA_Stop:
        movzx ebx,RChVirtualNb[ebp]
        dec ebx
        or VChControl[2*ebx],CC_BackGrnd ; Set the virtual channel to background

        cmp RChNNA[ebp],NNA_Cut
        je DoNNA_Cut

        cmp RChNNA[ebp],NNA_Continue
        je DoNNA_Alloc

        cmp RChNNA[ebp],NNA_NoteFade
        je DoNNA_Fade

        cmp RChNNA[ebp],NNA_NoteOff
        je DoNNA_Off
        
        jmp DoNNA_Cut        

DoNNA_Fade:

        call USS_NoteFade
        
        jmp DoNNA_Alloc
DoNNA_Off:

        call USS_KeyOff

        jmp DoNNA_Alloc
DoNNA_Cut:
                                        ; Use the same channel (CUT)
        or VChControl[2*ebx],CC_StopVoice

        cmp ebp,SSActiveChannels
        jb DoNNA_End
;write '!'

DoNNA_Alloc:
        call AllocateChannel
        jc DoNNAErr
DoNNA_End:
        mov al,NNA
        mov RChNNA[ebp],al
        and VChControl[2*ebx],Not CC_BackGrnd
        ret
DoNNAErr:
        mov RChVirtualNb[ebp],0
        stc
        ret
DoNNA_DCA Endp


AllocateChannel Proc
        mov ebx,ebp
        cmp ebp,SSActiveChannels
        jae DoAllocateChannel

        test VChControl[2*ebp],CC_Playing
        jz ChannelFound

DoAllocateChannel:

; Watch for the First not active channel

        xor ebx,ebx
CheckNotActiveChannelsLoop:
        test VChControl[2*ebx],CC_Playing
        jz ChannelFound
        inc ebx
        cmp ebx,SSActiveChannels
        jne CheckNotActiveChannelsLoop

; Watch for the background channel with the lowest volume

        mov al,-1
        xor edx,edx
CheckLowVolumeChannelLoop:
        test VChControl[2*edx],CC_BackGrnd
        jz CLV_NoBackGround
        cmp VChFVolume[edx],al
        jae CLV_NoBackGround
        mov ebx,edx
        mov al,VChFVolume[edx]
CLV_NoBackGround:
        inc edx
        cmp edx,SSActiveChannels
        jne CheckLowVolumeChannelLoop
        cmp al,-1
        jne ChannelFound

; Watch for the foreground channel with the lowest volume

;        mov al,-1
;        xor edx,edx
;CheckLowVolumeFGChannelLoop:
;        test VChControl[2*edx],CC_BackGrnd
;        jnz CLV_NoForeGround
;        cmp VChFVolume[edx],al
;        jae CLV_NoForeGround
;        mov ebx,edx
;        mov al,VChFVolume[edx]
;CLV_NoForeGround:
;        inc edx
;        cmp edx,SSActiveChannels
;        jne CheckLowVolumeFGChannelLoop
;        cmp al,-1
;        jne ChannelFound
        stc
        ret

ChannelFound:
        mov eax,ebp
        mov VChRealNb[ebx],al

        mov al,RChVolume[ebp]   ; Copy the values from the real channel
        mov VChVolume[ebx],al
        mov al,RChannelVol[ebp]
        mov VChannelVol[ebx],al
        mov al,RChPanning[ebp]
        mov VChPanning[ebx],al
        mov ax,RChPeriod[2*ebp]
        mov VChPeriod[2*ebx],ax

        or VChControl[2*ebx],CC_ChVolume+CC_ChPanning

        inc ebx
        xor eax,eax
ClearRefToNewChannelLoop:
        cmp RChVirtualNb[eax],bl
        jne NoPreviousRefFound
        mov RChVirtualNb[eax],0
NoPreviousRefFound:
        inc eax
        cmp eax,SSActiveChannels
        jne ClearRefToNewChannelLoop

        mov RChVirtualNb[ebp],bl

        dec ebx
        clc
        ret
AllocateChannel Endp

EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GetVibData :                                                            ณ
;ณ                                                                         ณ
;ณ Input: EBX Vibrato Pos                                                  ณ
;ณ        CH Vibrato Speed                                                 ณ
;ณ        CL Vibrato Wave                                                  ณ
;ณ        DX Vibrato Depth                                                 ณ
;ณ                                                                         ณ
;ณ Output: AX and CX Vibrato Data                                          ณ
;ณ         BL New Vibrato Pos                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

; 0,sine 1,ramp down 2,square 3,square 4,ramp up
; 3 should be random, but FT2 plays it as square...

if (UseTremolo or UseAutoVibrato or UseVibrato or UseVVolumeSlide or UseVVibrato or UseITVibVS)
GetVibData Proc
        xor eax,eax

        cmp cl,0
        jne NoSinWave
        movzx eax,bl          ;1, Sine
        and eax,7Fh
        mov al,SinTab[eax]
        jmp GetVibDataEnd
NoSinWave:
        cmp cl,1
        jne NoRampDown
        mov ax,bx             ;1, Ramp down
        cmp bl,127
        ja RD2
        sal ax,1
        jmp GetVibDataEnd
RD2:
        sub ax,256
        sal ax,1
        neg eax
        jmp GetVibDataEnd
NoRampDown:
        cmp cl,4
        je NoSquare
        mov al,255            ;2 and 3, Square => +255/-255
        jmp GetVibDataEnd
NoSquare:
        mov al,bl             ;4, Ramp Up
        cmp bl,127
        ja RU2
        sal ax,1
        neg ax
        jmp GetVibDataEnd
RU2:
        sub ax,256
        sal ax,1
GetVibDataEnd:
        cmp bl,127
        jbe VibDataOk
        neg ax
VibDataOk:
        add bl,ch

        imul dx

        mov cx,ax
        ret
GetVibData Endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ Get_NotePeriod: Get the period from the note and the sample definition  ณ
;ณ                                                                         ณ
;ณ Input: BL Note                                                          ณ
;ณ        ESI Sample Address                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set -> Incorrect Note/Sample                                 ณ
;ณ         EAX Period                                                      ณ
;ณ                                                                         ณ
;ณ Change: eax ebx                                                         ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Get_NotePeriod Proc
        xor eax,eax

        cmp esi,0
	je _NoPeriod
	cmp bl,0
	je _NoPeriod
	dec bl

        cmp bl,11*12
        ja _NoPeriod

        mov al,SRelNote[esi]            ; Sample Relative Note
	add al,bl
	cmp al,11*12
	jae _NoPeriod

        test SFlag[esi],SF_Linear
        jz GetAmigaPeriod

if UseLinearPeriod              ; * SETUP *

; ** Linear period **

	;Per=11*12*16*4-Note*16*4-Fine/2 (FineTune is done at the End)
	
	mov ebx,11*12*16*4
	shl eax,6
	sub ebx,eax

; ** Do FineTune **

       mov eax,SFine[esi]            ; Sample FineTune/2
       sub ebx,eax
	
       mov eax,ebx

       jmp GetNotePeriodEnd
endif

GetAmigaPeriod:

if UseAmigaPeriod               ; * SETUP *

; ** Amiga period **

        movzx eax,Period_Table[2*eax]

; ** Do FineTune **

        push edx
        push ecx
        mov ebx,SFine[esi]
        cmp bx,100              ; Marge de 100 (qui digitalise … 100 Hz ?)
        jb NoFine
        cmp bx,8363
        je NoFine
                                ; - Ajuster la priode - ( Frq pour C-4 )
        mov ecx,8363
        mul ecx
        div ebx
NoFine:
        pop ecx
        pop edx
endif

GetNotePeriodEnd:

        clc
        ret
_NoPeriod:
        xor eax,eax
        stc
        ret
Get_NotePeriod Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ exp768                                                                  ณ
;ณ                                                                         ณ
;ณ Input: EAX                                                              ณ
;ณ                                                                         ณ
;ณ Output: EAX=32768*2^(EAX/768)                                           ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

if UseLinearPeriod              ; * SETUP *
exp0    dw 32768,32798,32827,32857,32887,32916,32946,32976
        dw 33005,33035,33065,33094,33125,33155,33185,33215
exp1    dw 32768,33245,33728,34219,34716,35221,35733,36254
        dw 36781,37315,37859,38409,38968,39535,40110,40693
exp2    dd 32768,41285,52016,65536,82570,104032,131072,165140
        dd 208063,262144,330281,416128,524288,660561,832255,1048576
exp3    dd 32768,1321123,53264341,2147483648

exp768 proc
        
        mov edx,eax
        mov ebx,eax
        mov ecx,eax

        shr eax,12
        shr edx,8
        shr ebx,4

        and eax,3
        and ebx,15
        and ecx,15
        and edx,15

        mov eax,exp3[4*eax]
        mov edx,exp2[4*edx]
        movzx ebx,exp1[2*ebx]
        movzx ecx,exp0[2*ecx]
        mul edx
        shrd eax,edx,15
        mul ebx
        shrd eax,edx,15
        mul ecx
        shrd eax,edx,15
        ret
exp768 endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ SetFrequency: Set the channel frequency from the channel period.        ณ
;ณ                                                                         ณ
;ณ Input: EAX Channel Period.                                              ณ
;ณ        EBP Channel number (Get Period from ChPeriod[2*ebp])             ณ
;ณ                                                                         ณ
;ณ Output: AX Channel sample Frequency                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

SetFrequency Proc
        mov ecx,eax

        mov esi,VChSmpAdress[4*ebp]
        or esi,esi
        jz SetFreqError
        
        test SFlag[esi],SF_Linear
        jz GetAmigaFrequence

if UseLinearPeriod              ; * SETUP *

        mov eax,11*12*16*4
        sub eax,ecx

        call exp768

        mov ecx,8363
        mul ecx
        shrd eax,edx,20  ; Old, 19
endif
        jmp GetFreqEnd
GetAmigaFrequence:

if UseAmigaPeriod               ; * SETUP *
        xor edx,edx
        mov eax,14317456 ; =C-4 Period*C-4 Frequency (1712*8636)
        cmp ecx,10
        jbe SetFreqError ; It's just to avoid DIV 0 errors.
        div ecx
endif
GetFreqEnd:

        mov VChFreq[4*ebp],eax	

        clc
        ret
SetFreqError:

        stc
        ret
SetFrequency Endp

;               *****************************************
;               ***** Procedures used for the SETUP *****
;               *****************************************

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_DetectBestDev: Returns the first device detected.                   ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: EAX, First detected device number                               ณ
;ณ         EBX, Total devices number                                       ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_DetectBestDev proc

        mov BestDev,-1
        mov TotalDev,0
        xor edx,edx
DevLoop:
        mov esi,DEVList[4*edx]
        cmp esi,0
        je DevLoopEnd

        push edx
        movzx ecx,D_TotalDev[esi]
	
        cmp BestDev,-1
        jne DevNotDetected

        push ecx
        call Clear_DEV         ; Clear actual device definition
        xor eax,eax
        call D_Detect[esi]     ; Detect device
        pop ecx
        jc DevNotDetected
        add ax,TotalDev
        mov BestDev,ax
	
DevNotDetected:
        pop edx
	
        add TotalDev,cx
        inc edx
        jmp DevLoop
DevLoopEnd:
        movzx eax,BestDev
        movzx ebx,TotalDev
        ret
USS_DetectBestDev Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_DetectDev: Returns the first device detected.                       ณ
;ณ                                                                         ณ
;ณ Input: --                                                               ณ
;ณ                                                                         ณ
;ณ Output: CF Set => Device may not be here.                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_DetectDev proc

        xor edx,edx
        xor ecx,ecx
DetectDevLoop:
        mov esi,DEVList[4*edx]
        or esi,esi
        jz DetectDevError

        movzx ebx,D_TotalDev[esi]
        add ecx,ebx
        cmp ecx,eax
        jae DD_DevFound

        inc edx
        jmp DetectDevLoop

DD_DevFound:
        sub ecx,ebx
        sub eax,ecx
        mov _DEV_Offset,esi

        call Clear_DEV
        mov _DEV_Type,ax

        call D_Detect[esi]

        clc
        ret
DetectDevError:
        stc
        ret
USS_DetectDev Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ USS_InitDev: Initialise a device.                                       ณ
;ณ                                                                         ณ
;ณ Input: All _DEV_xxxx var must be correctly set                          ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
USS_InitDev Proc
        xor edx,edx
        xor ecx,ecx
InitDevLoop:
        mov esi,DEVList[4*edx]
        cmp esi,0
        je InitDevError

        movzx ebx,D_TotalDev[esi]
        add cx,bx
        cmp cx,ax
        jae ID_DevFound

        inc edx
        jmp InitDevLoop
ID_DevFound:

	mov _DEV_Offset,esi
        call D_Init[esi]        ; Init device
        ret

InitDevError:
        mov _DEV_Offset,0
        stc
        ret
USS_InitDev Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ Clear_Dev: Delete all device definitions                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Clear_DEV Proc
        mov _DEV_Name,Offset NoDev_Name
        mov _DEV_BasePort,-1
        mov _DEV_IRQ,-1
        mov _DEV_DMA,-1
        mov _DEV_Freq,-1
        mov _DEV_Mode,-1
        ret
Clear_DEV Endp

UseWriteDev Equ No

if UseWriteDev          ; * SETUP *
Write_DEV Proc

        Cls
        
        write 'Type: '
        movzx eax,_DEV_Type
        call print_dec
        writeln
        
        write 'BasePort: '
        movzx eax,_DEV_BasePort
        call print_hex
        writeln
        
        write 'IRQ: '
        movzx eax,_DEV_IRQ
        call print_dec
        writeln

        write 'DMA: '
        movzx eax,_DEV_DMA
        call print_dec
        writeln
        
        write 'Mode: '
        movzx eax,_DEV_Mode
        call print_dec
        writeln

        waitkey

        ret
Write_DEV Endp
endif

If UseSetup             ; * SETUP *

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrintStr                                                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrintStr Proc
	add edi,ZeroOffset
	add edi,0B8000h
PrintStrLoop:
	lodsb
	or al,al
	jz PrintStrEnd
	stosw
	jmp PrintStrLoop
PrintStrEnd:
	ret
PrintStr Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DrawLine                                                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
DrawLine Proc
	add edi,ZeroOffset
	add edi,0B8000h
	cld
	rep stosw
	ret
DrawLine Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ NextWindowLine                                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
NextWindowLine Proc
	mov ecx,80-2
	sub ecx,ebx
	shl ecx,1
	add edi,ecx
	ret
NextWindowLine Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DrawWindowLine                                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
DrawWindowLine Proc
	mov ecx,ebx
	mov al,'บ'
	stosw
	mov al,' '
	rep stosw
	mov al,'บ'
	stosw
	
	call NextWindowLine

	ret
DrawWindowLine Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DrawWindow                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
DrawWindow Proc
	add edi,ZeroOffset
	add edi,0B8000h
	
	mov ecx,ebx
	mov al,'ษ'
	stosw
	mov al,'อ'
	rep stosw
	mov al,'ป'
	stosw

	call NextWindowLine
	
	call DrawWindowLine

	mov ecx,ebx
	mov al,'ฬ'
	stosw
	mov al,'อ'
	rep stosw
	mov al,'น'
	stosw
	
	call NextWindowLine
	
DrawWLinesLoop:
	call DrawWindowLine
	dec edx
	jne DrawWLinesLoop

	mov ecx,ebx
	mov al,'ศ'
	stosw
	mov al,'อ'
	rep stosw
	mov al,'ผ'
	stosw

	ret
DrawWindow Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ Setup_ClearCenter                                                       ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Setup_ClearCenter Proc
	mov edi,ZeroOffset
	add edi,0B8000h+80*2
	mov ax,'ฑ'+CenterAttrib
	mov ecx,80*23
	cld
	rep stosw
	ret
Setup_ClearCenter Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrepareBuffer_Output                                                    ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrepareBuffer_Output Proc

	mov edi,SelectBuffer

	push edi
	mov esi,Offset SAutodetectStr ; 1st choice, Autodetect
	mov ecx,23
	rep movsb
	pop edi
	add edi,32
	
	xor edx,edx                   ; Other choices, devices names
	mov ecx,1
PBOutLoop:
	mov ebx,DEVList[4*edx]
	inc edx
	cmp ebx,0
	je PBOutEnd
	
	movzx eax,D_TotalDev[ebx]
	add ecx,eax
	cmp cx,MAXLines
	ja PBOutEnd

	add ebx,D_DevName
CopyNextName:
	mov esi,[ebx]
	push edi
	push eax

CopyNameLoop:
	mov al,[esi]
	inc esi
	mov [edi],al
	inc edi
	or al,al
	jnz CopyNameLoop

	pop eax
	pop edi
	add edi,32
	mov Byte Ptr [edi-1],0
	add ebx,4
	dec eax
	jnz CopyNextName
	jmp PBOutLoop
	
PBOutEnd:
	ret
PrepareBuffer_Output Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrepareBuffer_Mode                                                      ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrepareBuffer_Mode Proc

        mov edi,SelectBuffer

        push edi
        mov esi,Offset SMono    ; 1st choice, Mono
        mov ecx,23
        rep movsb
        pop edi
        add edi,32

        test _DEV_Mode,DM_Stereo
        jz NoAffStereo

        push edi
        mov esi,Offset SStereo  ; 2nd choice, Stereo
        mov ecx,23
        rep movsb
        pop edi
        add edi,32

NoAffStereo:

        push edi
        mov esi,Offset SMonoO   ; 3rd choice, Mono Oversampling
        mov ecx,23
        rep movsb
        pop edi
        add edi,32

        mov ecx,2

        test _DEV_Mode,DM_Stereo
        jz NoAffStereoO

        push edi
        mov esi,Offset SStereoO ; 4th choice, Stereo Oversampling
        mov ecx,23
        rep movsb
        pop edi
        add edi,32

        mov ecx,4
NoAffStereoO:

        ret
PrepareBuffer_Mode Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DecToAscii                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
DecToAscii Proc
        xor ebx,ebx
        mov cx,10

        push ax
GetNbDigitDECLoop:
        inc ebx
        xor edx,edx
        div cx
        or ax,ax
        jnz GetNbDigitDECLoop
        pop ax

        add edi,ebx
        mov Byte Ptr [edi],0
WriteDecLoop:
        dec edi
        xor edx,edx
        div cx
        add dl,'0'
        mov [edi],dl
        dec ebx
        jne WriteDecLoop

        ret
DecToAscii Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ HexToAscii                                                              ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
HexToAscii Proc
        xor ebx,ebx
        mov cx,10

        push ax
GetNbDigitHEXLoop:
        inc ebx
        shr ax,4
        or ax,ax
        jnz GetNbDigitHEXLoop
        pop ax

        add edi,ebx
        mov Byte Ptr [edi],0
WriteHexLoop:
        dec edi
        mov dx,ax
        and dx,0Fh
        add dl,'0'
        cmp dl,'9'
        jbe WriteHexStr
        add dl,'A'-'0'
WriteHexStr:
        mov [edi],dl
        shr eax,4
        dec ebx
        jne WriteHexLoop

        ret
HexToAscii Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrepareBuffer_Dec                                                       ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrepareBuffer_Dec Proc
        xor ecx,ecx
        mov edi,SelectBuffer
PrepareBuffer_DecLoop:
        movzx eax,Word Ptr [esi]
        add esi,2
        cmp ax,-1
        je PrepareBufferEnd
        inc ecx

        push ecx
        call DecToAscii
        pop ecx
        add edi,32
        jmp PrepareBuffer_DecLoop
PrepareBufferEnd:
        ret
PrepareBuffer_Dec Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrepareBuffer_Hex                                                       ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrepareBuffer_Hex Proc
        xor ecx,ecx
        mov edi,SelectBuffer
PrepareBuffer_HexLoop:
        movzx eax,Word Ptr [esi]
        add esi,2
        cmp ax,-1
        je PrepareBufferHexEnd
        inc ecx

        push ecx
        call HexToAscii
        pop ecx
        add edi,32
        jmp PrepareBuffer_HexLoop
PrepareBufferHexEnd:
        ret
PrepareBuffer_Hex Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ GetNumberPos                                                            ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
GetNumberPos Proc
        xor ecx,ecx
GetNumberPosLoop:
        cmp ax,[esi]
        je GetNumberPosEnd
        add esi,2
        inc ecx
        cmp Word Ptr[esi],-1
        jne GetNumberPosLoop
        xor ecx,ecx
GetNumberPosEnd:
        ret
GetNumberPos Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrintChoice                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrintChoice Proc
PrintChoiceLoop:
        lodsb
        cmp al,0
        je PrintChoiceEnd
        stosw
        jmp PrintChoiceLoop
PrintChoiceEnd:
        ret
PrintChoice Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrintChoices                                                            ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrintChoices Proc
        mov edi,ZeroOffset
        add edi,0B8000h+(1+3*80)*2
        add edi,SelectLinePos
        mov SelectLinePos,edi   ;Position of the first selection line
        add edi,eax
        mov SelectStrPos,edi    ;Position of the first selection string
        mov esi,SelectBuffer
        mov ax,SelectAttrib
        movzx ecx,NbLines

PrintChoicesLoop:
        push esi
        push edi
        call PrintChoice
        pop edi
        pop esi
        add edi,80*2        ; Next line
        add esi,32          ; Next device name
        dec ecx
        jnz PrintChoicesLoop

        ret
PrintChoices Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ PrintHighLight                                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
PrintHighLight Proc
        mov edx,ecx

        mov edi,SelectLinePos
        mov eax,ecx
        imul eax,80*2
        add edi,eax
        mov ebx,eax
        mov ax,HighlightAttrib

        mov al,16
        stosw
        mov al,' '
        movzx ecx,CurrentSize
        sub ecx,2
        rep stosw
        mov al,17
        stosw

; ** Print the selection string

        mov edi,SelectStrPos
        add edi,ebx
        mov esi,SelectBuffer
        mov eax,edx
        shl eax,5
        add esi,eax
        mov ax,HighlightAttrib
        call PrintStrLoop

        mov ecx,edx
        ret
PrintHighLight Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ CleanHighLight                                                          ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
CleanHighLight Proc
        mov edx,ecx

        mov edi,SelectLinePos
        mov eax,ecx
        imul eax,80*2
        add edi,eax
        mov ebx,eax
        mov ax,SelectAttrib

        mov al,' '
        movzx ecx,CurrentSize
        rep stosw

; ** Print the selection string

        mov edi,SelectStrPos
        add edi,ebx
        mov esi,SelectBuffer
        mov eax,edx
        shl eax,5
        add esi,eax
        mov ax,SelectAttrib
        call PrintStrLoop

        mov ecx,edx
        ret
CleanHighLight Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ DoSelection                                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
KUp    EQU 72
KDown  EQU 80
KPUp   EQU 73
KPDown EQU 81

DoSelection Proc
        dec NbLines

        call PrintHighLight

DoSelectionLoop:

        WaitKey
        
        cmp al,27
        je EscPressed

        cmp al,13
        je ReturnPressed

        cmp al,0
        jne DoSelectionLoop

        cmp ah,KUp
        jne NoKUp
        call CleanHighLight
        cmp cx,0
        je DoPrintHighLight
        dec ecx
        jmp DoPrintHighLight
NoKUp:
        cmp ah,KDown
        jne NoKDown
        call CleanHighLight
        cmp cx,NbLines
        je DoPrintHighLight
        inc ecx
        jmp DoPrintHighLight
NoKDown:
        cmp ah,KPUp
        jne NoKPUp
        call CleanHighLight
        mov cx,0
        jmp DoPrintHighLight
NoKPUp:
        cmp ah,KPDown
        jne NoKPDown
        call CleanHighLight
        mov cx,NbLines
        jmp DoPrintHighLight
NoKPDown:

DoPrintHighLight:

        call PrintHighLight

        jmp DoSelectionLoop

ReturnPressed:

        clc
        ret
EscPressed:
        stc
        ret
DoSelection Endp

EndIf   ;UseSetup

CODE32 ENDS
;==============================================================================
End
; USS.ASM (c) 1996-1998 FreddyV/Useless
