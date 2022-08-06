;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ GUSDRV.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ         Useless Gravis Ultrasound Driver          บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 13/03/1996       บ
;            บ   Last Update .................. 25/08/1996       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ


; UltraSound Ports
StatusPort      Equ 6h	   ; 2x6h	
TimerCtrlPort   Equ 8h	   ; 2x8h
TimerDataPort   Equ 9h     ; 2x9h

MidiCtrlPort    Equ 100h
MidiDataPort    Equ 101h

ActiveVoicePort Equ 102h
CommandPort     Equ 103h   ; 3x3h (Reg Select)
DataLowPort     Equ 104h   ; 3x4h
DataHighPort    Equ 105h   ; 3x5h	
DRAMIOPort      Equ 107h   ; 3x7h

JoystickTimer   Equ 201h   ; 201h

; UltraSound Commands ( or/and register )

WriteVoiceMode  Equ 00h
SetVoiceFreq    Equ 01h         ; Value=Freq/Divisor
LoopStartLo     Equ 02h
LoopStartHi     Equ 03h
SampleEndLo     Equ 04h
SampleEndHi     Equ 05h
VolRampRate     Equ 06h
VolRampStart    Equ 07h
VolRampEnd      Equ 08h
SetVolume       Equ 09h
SampleStartLo   Equ 0Ah
SampleStartHi   Equ 0Bh
VoiceBalance    Equ 0Ch
VolumeCtrl      Equ 0Dh
VoicesActive    Equ 0Eh
DMACtrl         Equ 41h
DMAStartAddress Equ 42h
DRAMAddrLo      Equ 43h
DRAMAddrHi      Equ 44h
TimerCtrl       Equ 45h
TimerCount1     Equ 46h
TimerCount2     Equ 47h
SampleFreq      Equ 48h
SampleCtrl      Equ 49h
Initialize      Equ 4Ch
Read            Equ 80h
ReadVolume      Equ Read+SetVolume      ; 89h
VoicePosLo      Equ Read+SampleStartLo  ; 8Ah
VoicePosHi      Equ Read+SampleStartHi  ; 8Bh
ReadVolCtrl     Equ Read+VolumeCtrl     ; 8Dh
IRQStatus       Equ 8Fh

; GUSDRV.INC (c) 1997 FreddyV/Useless