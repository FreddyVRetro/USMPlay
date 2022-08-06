;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ USS.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗         บ
;            บ                                                   บ
;            บ              Useless Sound System                 บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 04/08/1996       บ
;            บ   Last Update .................. 09/01/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Global USS_Setup           :Near
Global USS_AutoSetup       :Near
Global USS_LoadSampleMode  :Near
Global USS_LoadSample      :Near
Global USS_FreeSample      :Near
Global USS_SetAmpli        :Near

Global USS_Init              :Near
Global USS_SetActiveChannels :Near
Global USS_StartOutput       :Near
Global USS_StopOutput        :Near
Global USS_UpdateOutput      :Near

Global USS_GetGlobalVolume  :Near
Global USS_SetGlobalVolume  :Near
Global USS_GetChannelVolume :Near
Global USS_SetChannelVolume :Near

Global USS_StartInstrument  :Near
Global USS_ChangeInstrument :Near
Global USS_InitInstrEnv     :Near
Global USS_SetEnvPos        :Near
Global USS_GetSampleVolume  :Near
Global USS_GetSamplePanning :Near
Global USS_SetSampleOffset  :Near

Global USS_SetNote          :Near
Global USS_GetPeriod        :Near
Global USS_SetPeriod        :Near
Global USS_GetNotePeriod    :Near
Global USS_GetVolume        :Near
Global USS_SetVolume        :Near
Global USS_GetPanning       :Near
Global USS_SetPanning       :Near
Global USS_SetNNA           :Near
Global USS_PastNoteControl  :Near
Global USS_NoteCut          :Near
Global USS_NoteFade         :Near
Global USS_KeyOff           :Near
Global USS_UpdateInstr      :Near

; ** Some usefull functions for the player **

Global GetVibData          :Near

; USS.INC (c) 1997 FreddyV/Useless
