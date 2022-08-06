;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ    ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ USSVAR.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗       บ
;            บ                                                   บ
;            บ         Useless Sound System 'Variables'          บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 04/04/1996       บ
;            บ   Last update .................. 09/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC
INCLUDE MUS_EFX.INC

;=============================================================================

if _WATCOM

ifdef STACKCALL
Public Error_Number
Error_Number DD 0       ; Error number for WATCOM C
else
Public _Error_Number
_Error_Number DD 0      ; Error number for WATCOM C
endif

endif

;-----------------------------------------------------------------------------

ifdef STACKCALL
Public DEV_Offset
Public DEV_Name
Public DEV_Type
Public DEV_BasePort
Public DEV_IRQ
Public DEV_DMA
Public DEV_Freq
Public DEV_Mode
Public DEV_MaxChannels

DEV_Offset      DD 0           ; Pointer to the driver structure
DEV_Name        DD 0           ; Pointer to the device name
DEV_Type        DW 0           ; 
DEV_BasePort    DW 0
DEV_IRQ         DB 0
DEV_DMA         DB 0
DEV_Freq        DW 0
DEV_Mode        DW 0
DEV_MaxChannels DW 0
else
Public _DEV_Offset
Public _DEV_Name
Public _DEV_Type
Public _DEV_BasePort
Public _DEV_IRQ
Public _DEV_DMA
Public _DEV_Freq
Public _DEV_Mode
Public _DEV_MaxChannels

_DEV_Offset      DD 0           ; Pointer to the driver structure
_DEV_Name        DD 0           ; Pointer to the device name
_DEV_Type        DW 0           ; 
_DEV_BasePort    DW 0
_DEV_IRQ         DB 0
_DEV_DMA         DB 0
_DEV_Freq        DW 0
_DEV_Mode        DW 0
_DEV_MaxChannels DW 0
endif

;-----------------------------------------------------------------------------

Public SSPeriodMin
Public SSPeriodMax
If UseGlobalVolume              ; * SETUP *
Public SSGlobalVol
EndIf
Public SSActiveChannels

SSPeriodMin      DW 0
SSPeriodMax      DW 0
If UseGlobalVolume              ; * SETUP *
SSGlobalVol      DB 0   ;Global Volume (Sound system Volume)
EndIf
SSActiveChannels DD MAX_SSCHANNELS  ;Actual Actives channels

;-----------------------------------------------------------------------------

;*** "Virtual" channels definitions ***

Public VChControl 
Public VChInsAdress
Public VChPeriod
Public VChFreq
Public VChannelVol
Public VChVolume
Public VChFVolume
Public VChPanning
Public VChFPanning
Public VChSmpAdress
Public VChSmpOffset

Public VChRealNb
Public VChNote

Public RChVirtualNb
Public RChNNA
Public RChVolume
Public RChannelVol
Public RChPanning
Public RChPeriod

; ** Instruments var **

Public VChFadeoutVol   
Public VChVolEnvPos    
Public VChVolEnvSegPos 
Public VChEnvVol       
Public VChPanEnvPos    
Public VChPanEnvSegPos 
Public VChEnvPan 

Public VChAVibPos   
Public VChAVibSwpPos
Public VChAVibPitch

Public USSVarStart
Public USSVarEnd

;This label is used to clear the following var at Sound System start.
USSVarStart:

VChControl   DW MAX_SSCHANNELS DUP (0)

VChPeriod    DW MAX_SSCHANNELS DUP (0) ; Channel Period
VChFreq      DD MAX_SSCHANNELS DUP (0) ; Channel Final Frequency
VChannelVol  DB MAX_SSCHANNELS DUP (0) ; Channel Volume
VChVolume    DB MAX_SSCHANNELS DUP (0) ; Channel Instrument Volume
VChFVolume   DB MAX_SSCHANNELS DUP (0) ; Channel Final Volume
VChPanning   DB MAX_SSCHANNELS DUP (0) ; Channel Panning
VChFPanning  DB MAX_SSCHANNELS DUP (0) ; Channel Final Panning

VChInsAdress DD MAX_SSCHANNELS DUP (0) ; Instrument definition Adress
VChSmpAdress DD MAX_SSCHANNELS DUP (0) ; Sample definition Adress
VChSmpOffset DD MAX_SSCHANNELS DUP (0) ; Current Sample Offset (GUS/MIX device)

; ** NNA Var **


VChRealNb    DB MAX_SSCHANNELS DUP (0) ; To get the virtual channel number
VChNote      DB MAX_SSCHANNELS DUP (0) ; Used for the DCT Note

RChVirtualNb DB MAX_PLCHANNELS DUP (0) ; To get the virtual channel number
RChNNA       DB MAX_PLCHANNELS DUP (0)
RChVolume    DB MAX_PLCHANNELS DUP (0)
RChannelVol  DB MAX_PLCHANNELS DUP (0)
RChPanning   DB MAX_PLCHANNELS DUP (0)
RChPeriod    DW MAX_PLCHANNELS DUP (0)

; ** Instruments var **

VChFadeoutVol   DW MAX_SSCHANNELS DUP (0)

VChVolEnvPos    DW MAX_SSCHANNELS DUP (0)
VChVolEnvSegPos DW MAX_SSCHANNELS DUP (0)
VChEnvVol       DB MAX_SSCHANNELS DUP (0)

VChPanEnvPos    DW MAX_SSCHANNELS DUP (0)
VChPanEnvSegPos DW MAX_SSCHANNELS DUP (0)
VChEnvPan       DB MAX_SSCHANNELS DUP (0)

VChAVibPos    DB MAX_SSCHANNELS DUP (0)
VChAVibSwpPos DB MAX_SSCHANNELS DUP (0)
VChAVibPitch  DW MAX_SSCHANNELS DUP (0)

USSVarEnd:

;-----------------------------------------------------------------------------

Public Period_Table

Period_Table:
if UseAmigaPeriod Eq Yes ; The first octave (-1) is for IT compatibility.
;    C                                                                 B      
dw 27392*2,25856*2,24384*2,23040*2,21696*2,20480*2,19328*2,18240*2,17216*2,16256*2,15360*2,14496*2 ;-1
dw 27392,25856,24384,23040,21696,20480,19328,18240,17216,16256,15360,14496 ;0
dw 13696,12928,12192,11520,10848,10240, 9664, 9120, 8608, 8128, 7680, 7248 ;1
dw  6848, 6464, 6096, 5760, 5424, 5120, 4832, 4560, 4304, 4064, 3840, 3624 ;2
dw  3424, 3232, 3048, 2880, 2712, 2560, 2416, 2280, 2152, 2032, 1920, 1812 ;3
dw  1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016,  960,  906 ;4
dw   856,  808,  762,  720,  678,  640,  604,  570,  538,  508,  480,  453 ;5
dw   428,  404,  381,  360,  339,  320,  302,  285,  269,  254,  240,  226 ;6
dw   214,  202,  190,  180,  170,  160,  151,  143,  135,  127,  120,  113 ;7
dw   107,  101,   95,   90,   85,   80,   75,   71,   67,   63,   60,   56 ;8
dw    53,   50,   47,   45,   42,   40,   37,   35,   33,   31,   30,   28 ;9
dw     0
endif

CODE32 ENDS
;=============================================================================
end
; USSVAR.ASM (c) 1997 FreddyV/Useless
