;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º    ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ USSVAR.INC ÷÷÷÷÷÷÷÷÷÷÷÷÷÷       º
;            º                                                   º
;            º         Useless Sound System 'Variables'          º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 03/08/1996       º
;            º   Last update .................. 18/11/1997       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

MAX_Samples     EQU 128
MAX_Instruments EQU 128

; ** Devices var **

ifdef STACKCALL

Global DEV_Offset      :DWORD
Global DEV_Name        :DWORD
Global DEV_Type        :WORD
Global DEV_BasePort    :WORD
Global DEV_IRQ         :BYTE
Global DEV_DMA         :BYTE
Global DEV_Freq        :WORD
Global DEV_Mode        :WORD
Global DEV_MaxChannels :WORD

_DEV_Offset      Equ DEV_Offset
_DEV_Name        Equ DEV_Name
_DEV_Type        Equ DEV_Type
_DEV_BasePort    Equ DEV_BasePort
_DEV_IRQ         Equ DEV_IRQ
_DEV_DMA         Equ DEV_DMA
_DEV_Freq        Equ DEV_Freq
_DEV_Mode        Equ DEV_Mode
_DEV_MaxChannels Equ DEV_MaxChannels

else

Global _DEV_Offset      :DWORD
Global _DEV_Name        :DWORD
Global _DEV_Type        :WORD
Global _DEV_BasePort    :WORD
Global _DEV_IRQ         :BYTE
Global _DEV_DMA         :BYTE
Global _DEV_Freq        :WORD
Global _DEV_Mode        :WORD
Global _DEV_MaxChannels :WORD

endif

; ** Devices Type Mask **

DM_8bit   EQU 1      ; 8 bit device
DM_16bit  EQU 2      ; 16 bit device
DM_Mono   EQU 4      ; Mono Device
DM_Stereo EQU 8      ; Stereo Device
DM_Signed EQU 16     ; Need a signed or an unsigned buffer (used in mix.asm)
DM_Interp EQU 32     ; 16 bit interpolation and 32 bit mixing...

DM_Mixed  EQU 256    ; Software mixed or hardware mixed device
DM_DRAM   EQU 512
DM_MIDI   EQU 1024   ; MIDI Device (Not used yet)
DM_FM     EQU 2048   ; FM Device (Adlib, Not used yet)
DM_16bSmp EQU 4096   ; Device can play 16 bit samples

; ** Global var **

Global SSSampleOffsetT  :DWORD  ; Sample Offset Table
Global SSInstrOffsetT   :DWORD  ; Instrument Offset Table
Global SSPeriodMin      :WORD
Global SSPeriodMax      :WORD
Global SSGlobalVol      :BYTE
Global SSActiveChannels :DWORD

; ** Channels var **

Global VChControl    :WORD      ; Channel control

Global VChPeriod     :WORD
Global VChFreq       :DWORD
Global VChannelVol   :BYTE
Global VChVolume     :BYTE
Global VChFVolume    :BYTE
Global VChPanning    :BYTE
Global VChFPanning   :BYTE

Global VChInsAdress  :DWORD
Global VChSmpAdress  :DWORD
Global VChSmpOffset  :DWORD

Global VChRealNb     :BYTE
Global VChNote       :BYTE

Global RChVirtualNb  :BYTE
Global RChNNA        :BYTE
Global RChVolume     :BYTE
Global RChannelVol   :BYTE
Global RChPanning    :BYTE
Global RChPeriod     :WORD

Global VChFadeoutVol   :WORD

Global VChVolEnvPos    :WORD
Global VChVolEnvSegPos :WORD
Global VChEnvVol       :BYTE

Global VChPanEnvPos    :WORD
Global VChPanEnvSegPos :WORD
Global VChEnvPan       :BYTE

Global VChAVibPos      :BYTE
Global VChAVibSwpPos   :BYTE
Global VChAVibPitch    :WORD

Global USSVarStart
Global USSVarEnd

Global Period_Table :WORD

; ** Channel Control masques **

CC_Stopped   EQU 1      ; Active/Stopped channel                 (0)
CC_Playing   EQU 2      ; A sample is played on this channel     (1)
CC_StopVoice EQU 4      ; Stop the sample                        (2)
CC_FadeVol   EQU 8      ; Fading active                          (3)
CC_Release   EQU 16     ; Channel is released                    (4)

CC_ChSample  EQU 32     ; Change channel sample                  (5)
CC_ChPeriod  EQU 64     ; Change channel period                  (6)
CC_ChVolume  EQU 128    ; Change channel volume                  (7)
CC_ChPanning EQU 256    ; Change channel panning                 (8)
CC_DoRelease EQU 512    ; Stop sustain loop                      (9)

CC_Surround  EQU 1024   ; Surround                               (10)

CC_Backgrnd  EQU 2048   ; Background channel

; ** Instrument and sample definition **

USSInstrSize EQU IPEnvelope+75

USSInstr Struc
        IId         DD 0		;'INST'
        IName       DB 32  DUP (0)

        IFlg        DB 0
        INNA        DB 0
        IDCT        DB 0
        IDCA        DB 0

        IGVolume    DB 0                ;Global instrument volume
        IDefPanning DB 0                ;Default panning
        IPPC        DB 0                ;Pitch-pan center
        IPPS        DB 0                ;Pitch-pan separation
        IVFadeout   DW 0                ;Fadeout

        ISNumber    DB 132 DUP (0)      ;Sample number for all notes  (1-255)
        INote       DB 120 DUP (0)      ;'Real' Note number for each note (IT)

        ISTable     DD 0                ;Sample offset table

        IVType      DB 0
        IVPoints    DB 0
        IVSustain   DB 0
        IVSustEnd   DB 0
        IVLoopStart DB 0
        IVLoopEnd   DB 0
        IVEnvelope  DB 75  DUP (0)

        IPType      DB 0
        IPPoints    DB 0
        IPSustain   DB 0
        IPSustEnd   DB 0
        IPLoopStart DB 0
        IPLoopEnd   DB 0
        IPEnvelope  DB 75  DUP (0)

USSInstr Ends

USSEnv   Struc
        EnvType      DB 0
        EnvPoints    DB 0
        EnvSustain   DB 0
        EnvSustEnd   DB 0
        EnvLoopStart DB 0
        EnvLoopEnd   DB 0
        EnvEnvelope  DB 75  DUP (0)
USSEnv   Ends

; Instruments flag

IF_IT          EQU 1            ; XM/Impulse tracker instrument
IF_ReleaseFade EQU 2            ; Fade volume with a Key off command
IF_UsePanning  EQU 2            ; Use default panning ?

; Envelope Type Mask (XM)

E_On      EQU 1
E_Sustain EQU 2
E_Loop    EQU 4

; Envelope type Mask (IT)

EIT_On    EQU 1
EIT_Loop  EQU 2
EIT_SLoop EQU 4

NNA_Cut      EQU 0
NNA_Continue EQU 1
NNA_NoteOff  EQU 2
NNA_NoteFade EQU 3

DCT_Off        EQU 0
DCT_Note       EQU 1
DCT_Sample     EQU 2
DCT_Instrument EQU 3

DCA_Cut        EQU 0
DCA_NoteOff    EQU 1
DCA_NoteFade   EQU 2

; Warning: E_On and EIT_On must stay the same !

USSSampleSize EQU SVibrate+1		; ! Can't be >255 !

USSSample Struc
        SId	    DD 0		; 'SMPL'
        SName       DB 32 DUP (0)

        SLength     DD 0
        SLoop	    DD 0
        SLoopEnd    DD 0
        SSustain    DD 0
        SSustEnd    DD 0

        SType       DB 0
        SFlag       DB 0
        SDefVolume  DB 0
        SVolume     DB 0
        
        SDefPanning DB 0                ;Sample default panning
        SRelNote    DB 0
        SFine	    DD 0
        SPointer    DD 0                ;Pointer to the sample data
        SSPointer   DD 0                ;Pointer to the sample data (sustain loop)

        SVibType    DB 0                ;Sample auto vibrato
        SVibSweep   DB 0
        SVibdepth   DB 0
        SVibrate    DB 0
USSSample Ends

; Sample Type Mask 
; Warning: Don't change 16bit, Loop and Bidi. I've used GUS values.

SM_Stereo  EQU 1
SM_Packed  EQU 2

SM_16bit   EQU 4
SM_Loop    EQU 8
SM_Bidi    EQU 16
SM_Sustain EQU 32
SM_SBidi   EQU 64

; Sample Flag Mask

SF_Loaded      EQU 1
SF_UsePanning  EQU 2    ;Use the panning default value
SF_UseIPanning EQU 4    ;Use Instrument panning for default sample panning
SF_Linear      EQU 8    ;Use Linear/Amiga period

SF_Unsigned    EQU 16
SF_Delta       EQU 32
SF_IT          EQU 64   ;IT sample (Key release don't cut IT samples)
SF_Initial     EQU 128  ;Initial or Playable sample

; USSVAR.INC (c) 1997 FreddyV/Useless
