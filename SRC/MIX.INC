;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?       ?????????????? MIX.INC ??????????????       ?
;            ?                                                   ?
;            ?              MIXED DEVICES PROCEDURES             ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   By Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code starts .................. 25/08/1996       ?
;            ?   Last update .................. 01/10/1997       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?

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