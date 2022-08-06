;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ ERROR.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ                  Error functions                  บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 29/03/1997       บ
;            บ   Last Update .................. 02/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE ERR_CODE.INC
INCLUDE UTILS.INC

;=============================================================================

EC_0 DB 'Error code is 0 !',DOSStrEnd
E_Unknown DB 'Unknown Error !',DOSStrEnd

;***********

ME_Nr  EQU 4
ME_Str DB 'Memory Error: ',DOSStrEnd

ME_Offset DD Offset ME_AskForNoMem_Str
          DD Offset ME_OutOfMemory_Str
          DD Offset ME_BlockDestroyed_Str
          DD Offset ME_BlockFree_Str

ME_AskForNoMem_Str     DB '0 byte Malloc.',DOSStrEnd
ME_OutOfMemory_Str     DB 'Out of memory.',DOSStrEnd
ME_BlockDestroyed_Str  DB 'Memory heap corrupted.',DOSStrEnd
ME_BlockFree_Str       DB 'Memory block already free.',DOSStrEnd

;***********

TE_Nr  EQU 2
TE_Str DB 'Timer Error: ',DOSStrEnd

TE_Offset DD Offset TE_NoFreeTimer_Str
          DD Offset TE_NotFound_Str

TE_NoFreeTimer_Str DB 'No more timer available.',DOSStrEnd
TE_NotFound_Str    DB 'Trying to release an unknown timer.',DOSStrEnd

;***********

FE_Nr  EQU 7
FE_Str DB 'File Error: ',DOSStrEnd

FE_Offset DD Offset FE_Unknown_Str
          DD Offset FE_NoFile_Str
          DD Offset FE_NoPath_Str
          DD Offset FE_NoHandle_Str
          DD Offset FE_NoHandle_Str
          DD Offset FE_NoAccess_Str
          DD Offset FE_HandleNr_Str

FE_Unknown_Str  DB 'Unknown Error.',DOSStrEnd
FE_NoFile_Str   DB 'File Not Found.',DOSStrEnd
FE_NoPath_Str   DB 'Path Not Found.',DOSStrEnd
FE_NoHandle_Str DB 'Too many open files.',DOSStrEnd
FE_NoAccess_Str DB 'Access denied',DOSStrEnd
FE_HandleNr_Str DB 'Invalid Handle',DOSStrEnd

;***********

SE_Nr  EQU 3
SE_Str DB 'Sound System Error: ',DOSStrEnd

SE_Offset DD Offset SE_NoDevice_Str
          DD Offset SE_Started_Str
          DD Offset SE_Channels_Str

SE_NoDevice_Str  DB 'No device selected.',DOSStrEnd
SE_Started_Str   DB 'Sound output already started.',DOSStrEnd
SE_Channels_Str  DB 'Not enough channels available.',DOSStrEnd

;***********

DE_Nr  EQU 1
DE_Str DB 'Output device Error: ',DOSStrEnd

DE_Offset DD Offset DE_InitFail_Str

DE_InitFail_Str  DB 'Initialisation failure.',DOSStrEnd

;***********

PE_Nr  EQU 3
PE_Str DB 'USM player Error: ',DOSStrEnd

PE_Offset DD Offset PE_NotUSM_Str
          DD Offset PE_Channels_Str
          DD Offset PE_WrongVersion_Str

PE_NotUSM_Str       DB 'It''s not an USM file.',DOSStrEnd
PE_Channels_Str     DB 'Not enough channels available.',DOSStrEnd
PE_WrongVersion_Str DB 'Wrong file version.',DOSStrEnd

;***********

LE_Nr  EQU 3
LE_Str DB 'File loader Error: ',DOSStrEnd

LE_Offset DD Offset LE_WrongFormat_Str
          DD Offset LE_WrongVersion_Str
          DD Offset LE_PatternError_Str
          
LE_WrongFormat_Str  DB 'Wrong file format.',DOSStrEnd
LE_WrongVersion_Str DB 'Unknown file version.',DOSStrEnd
LE_PatternError_Str DB 'Pattern Error.',DOSStrEnd

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ Display_Error: Display the Error message.                               ณ
;ณ                                                                         ณ
;ณ Input: EAX Error number                                                 ณ
;ณ                                                                         ณ
;ณ Output: -                                                               ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Display_Error Proc
        cmp eax,0
        jne _DE

        mov edx,Offset EC_0
        jmp Display_Error_End
_DE:
        dec eax
        push eax
        cmp ah,(Mem_Error SHR 8)
        je _Display_ME
        cmp ah,(Tim_Error SHR 8)
        je _Display_TE
        cmp ah,(File_Error SHR 8)
        je _Display_FE
        cmp ah,(USS_Error SHR 8)
        je _Display_SE
        cmp ah,(DEV_Error SHR 8)
        je _Display_DE
        cmp ah,(USMP_Error SHR 8)
        je _Display_PE
        cmp ah,(Load_Error SHR 8)
        je _Display_LE
        pop eax
        jmp _Display_Unknown
_Display_ME:
        mov edx,Offset ME_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,ME_Nr
        jae _Display_Unknown
        mov edx,ME_Offset[4*eax]
        jmp Display_Error_End

_Display_TE:
        mov edx,Offset TE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,TE_Nr
        jae _Display_Unknown
        mov edx,TE_Offset[4*eax]
        jmp Display_Error_End

_Display_FE:
        mov edx,Offset FE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,FE_Nr
        jae _Display_Unknown
        mov edx,FE_Offset[4*eax]
        jmp Display_Error_End

_Display_SE:
        mov edx,Offset SE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,SE_Nr
        jae _Display_Unknown
        mov edx,SE_Offset[4*eax]
        jmp Display_Error_End

_Display_DE:
        mov edx,Offset DE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,DE_Nr
        jae _Display_Unknown
        mov edx,DE_Offset[4*eax]
        jmp Display_Error_End

_Display_PE:
        mov edx,Offset PE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,PE_Nr
        jae _Display_Unknown
        mov edx,PE_Offset[4*eax]
        jmp Display_Error_End

_Display_LE:
        mov edx,Offset LE_Str
        writeDOS
        pop eax
        and eax,0FFh
        cmp eax,LE_Nr
        jae _Display_Unknown
        mov edx,LE_Offset[4*eax]
        jmp Display_Error_End

_Display_Unknown:
        mov edx,Offset E_Unknown

Display_Error_End:
        writeDOS

        ret
Display_Error Endp

CODE32 ENDS
END