;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ       ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ MIX.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗       บ
;            บ                                                   บ
;            บ              MIXED DEVICES PROCEDURES             บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 25/08/1996       บ
;            บ   Last update .................. 01/10/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

;=============================================================================

Global MIX_Rate     :WORD
Global MIX_BSize    :DWORD 
Global MIX_BOffset  :DWORD
Global MIX_FBOffset :DWORD
Global MIX_ActiveB  :WORD

;=============================================================================

Global MIX_GetAmpli    :Near
Global MIX_SetAmpli    :Near

Global MIX_LoadSample  :Near
Global MIX_FreeSample  :Near
Global MIX_UpdateSound :Near
Global MIX_Start       :Near
Global MIX_Stop        :Near

; MIX.INC (c) 1997 FreddyV/Useless