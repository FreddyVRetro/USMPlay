;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ MEMORY.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ              Useless Memory Manager               บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 14/03/1996       บ
;            บ   Last Update .................. 11/11/1996       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

ifndef _OS_
display 'OS.INC must be included before MEMORY.INC'
endif

; Public memory functions

Global _Malloc       :Near ; Allocate a memory block
Global _Calloc       :Near ; Allocate and clear a memory block
Global _Free         :Near ; Free an allocated memory block
Global _Maxavail     :Near ; Get the length of the biggest free block.
Global _MEMORY_Error :Near ; Display the Memory Error.
Global _Debug_MEMORY :Near

; Public Var

Global Memory_Return :dword

DirrectError EQU 1  ; 1 => Stop program immediatly after an error
                    ; 0 => Jump to the Proc Error label

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  U_Malloc: Allocate a memory block                                        ณ
;ณ                                                                         ณ
;ณ Input: Size of the memory block to allocate                             ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         EAX pointer to the allocated memory block                       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
U_Malloc MACRO Size
Local Malloc_NoError	

        pushad
        ifdifi <Size>,<eax>
        mov eax,Size
        endif
        call _Malloc
        popad
        mov eax,Memory_Return
if DirrectError Eq 1
        jnc Malloc_NoError
        call _MEMORY_Error
endif
Malloc_NoError:	
EndM

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Calloc: Allocate and clear a memory block                              ณ
;ณ                                                                         ณ
;ณ Input: Size of the memory block to allocate                             ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         EAX pointer to the allocated memory block                       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
U_Calloc MACRO Size
Local Calloc_NoError

	pushad
        ifdifi <Size>,<eax>
        mov eax,Size
        endif				
        call _Calloc
        popad
        mov eax,Memory_Return
if DirrectError eq 1
        jnc Calloc_NoError
        call _MEMORY_Error
endif
Calloc_NoError:	
EndM

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Free: Free an allocated memory block                                   ณ
;ณ                                                                         ณ
;ณ Input: Pointer to the memory block to free.                             ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear=> Ok                                                   ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
U_Free MACRO Location
Local Free_NoError

        pushad
        ifdifi <Location>,<eax>
        mov eax,Location
        endif
        call _Free
        popad
        mov eax,Memory_Return
if DirrectError eq 1
        jnc Free_NoError
        call _MEMORY_Error
endif
Free_NoError:	
EndM

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Maxavail: Get the length of the biggest free block.                    ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear=> Ok                                                   ณ
;ณ         EAX returns 'Maxavail'                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
U_Maxavail MACRO
Local Maxavail_NoError
        pushad
        call _Maxavail
        popad
        mov eax,Memory_Return
if DirrectError eq 1
        jnc Maxavail_NoError
        call _MEMORY_Error
endif
Maxavail_NoError:	
EndM

;MEMORY.INC (c) 1997 FreddyV/Useless