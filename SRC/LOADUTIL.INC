;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ   ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ LOADUTIL.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ             Useless Loaders Utilities             บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 06/04/1996       บ
;            บ   Last Update .................. 02/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

INCLUDE FILES.INC

Global File_Open     :BYTE
Global LoadMode      :BYTE

Global MUS_MemOffset :DWORD
Global MUS_File      :DWORD
Global MUS_Offset    :DWORD
Global MUS_Channels  :WORD

Global LU_LoadSample       :Near
Global LU_Check_Instrument :Near
Global LU_PackPattern      :Near

Global Memoryfread         :Near


MOpen   MACRO Filename
Local MOpenfile,NotOpened
        cmp LoadMode,1
        jne MOpenFile
                                ; Memory
        mov edx,Filename
        mov MUS_MemOffset,edx
        mov MUS_Offset,0
        mov File_Open,1
        clc
        jmp NotOpened
                                ; File        
MOpenFile:
        ifdifi <Filename>,<edx>
        mov edx,Filename
        endif
        mov File_Open,0
        mov MUS_offset,0
        xor eax,eax             ; read only (for CD ROM)
        call U_fopen
        jc NotOpened
        mov File_Open,1         ; File is opened
        mov MUS_File,eax
NotOpened:
Endm

MCreate MACRO Filename
        ifdifi <Filename>,<edx>
        mov edx,Filename
        endif
        mov MUS_Offset,0
        call U_fcreate
        mov MUS_File,eax	
Endm

; Length musn't be edx
Mread   MACRO Buffer,Length
local Mreadfile,MreadEnd
	pushad
        cmp LoadMode,1
        jne Mreadfile
                                ; Memory
        mov ecx,Length
        mov edi,Buffer
        call Memoryfread
        jmp MreadEnd
                                ; File
Mreadfile:
        ifdifi <Buffer>,<edx>
        mov edx,Buffer
        endif
        ifdifi <Length>,<ecx>
        mov ecx,Length
        endif
        add MUS_Offset,ecx
        mov ebx,MUS_File
        call U_fread
MreadEnd:
	popad
Endm

; Length musn't be edx
Mwrite  MACRO Buffer,Length
        ifdifi <Buffer>,<edx>
        mov edx,Buffer
        endif
        ifdifi <Length>,<ecx>
        mov ecx,Length
        endif
        add MUS_Offset,ecx
        mov ebx,MUS_File
        call U_fwrite
Endm

Mreadpos MACRO pos,Buffer,Length
local Mreadposfile,MreadposEnd

        cmp LoadMode,1
        jne Mreadposfile
                                ; Memory
        mov edx,pos
        mov MUS_Offset,edx

        pushad
        mov ecx,Length
        mov edi,Buffer
        call Memoryfread
        popad
        jmp MreadposEnd
                                ; File
Mreadposfile:
        ifdifi <pos>,edx
        mov edx,pos
        endif
        mov al,0
        mov MUS_Offset,edx
        mov ebx,MUS_File
        call fsetpos
        jc MreadPosend

        ifdifi <Buffer>,<edx>
        mov edx,Buffer
        endif
        ifdifi <Length>,<ecx>
        mov ecx,Length
        endif
        add MUS_Offset,ecx
        mov ebx,MUS_File
        call U_fread
MreadposEnd:
Endm

Msetpos MACRO pos
Local Msetposfile,MsetposEnd
        cmp LoadMode,1
        jne Msetposfile
                                ; Memory
        mov edx,pos
        mov MUS_Offset,edx
        jmp MsetposEnd
                                ; File
Msetposfile:        
        ifdifi <pos>,<edx>
        mov edx,pos
        endif
        mov al,0
        mov MUS_Offset,edx
        mov ebx,MUS_File
        call U_fsetpos
MsetposEnd:
Endm

Mclose  MACRO
Local NoClose,McloseEnd
        cmp LoadMode,1
        je NoClose

        cmp File_Open,1         ; Is file Opened ?
        jne NoClose             ; No -> do not close it
        mov ebx,MUS_FILE
        call U_fclose
NoClose:        
        mov File_Open,0
Endm

; LOADUTILS.INC (c) 1997 FreddyV/Useless