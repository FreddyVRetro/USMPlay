;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ    ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ USMPLAY.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ              Useless Module Player                บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 09/08/1996       บ
;            บ   Last update .................. 09/01/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

; Module loading mode (from file or memory)

LM_File  EQU 0
LM_Memory EQU 1

Global USMP_LoadInternalModule :Near
Global USMP_FreeInternalModule :Near

Global USMP_FreeModule         :Near

Global USMP_StartPlay          :Near
Global USMP_StopPlay           :Near

Global USMP_PrevOrder          :Near
Global USMP_NextOrder          :Near
Global USMP_SetOrder           :Near
Global USMP_SetPosition        :Near

ifdef STACKCALL

Global SynchroCount :DWORD
Global SynchroVal   :BYTE
Global MusicEnd     :BYTE
Global Order        :WORD
Global Pattern      :WORD
Global Row          :WORD
Global BPM          :BYTE
Global Speed        :BYTE

Global ChInstrument :BYTE
Global ChNote       :BYTE
Global ChCommand    :BYTE
Global ChVCommand   :BYTE
Global ChVolume     :BYTE
Global ChPeriod     :WORD
Global ChPanning    :BYTE

else

Global _SynchroCount :DWORD
Global _SynchroVal   :BYTE
Global _MusicEnd     :BYTE
Global _Order        :WORD
Global _Pattern      :WORD
Global _Row          :WORD
Global _BPM          :BYTE
Global _Speed        :BYTE

Global _ChInstrument :BYTE
Global _ChNote       :BYTE
Global _ChCommand    :BYTE
Global _ChVCommand   :BYTE
Global _ChVolume     :BYTE
Global _ChPeriod     :WORD
Global _ChPanning    :BYTE

endif