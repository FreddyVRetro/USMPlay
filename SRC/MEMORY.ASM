;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ MEMORY.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ               Useless Memory Manager              บ
;            บ                 for DOS32 and EOS                 บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 14/03/1996       บ
;            บ   Last Update .................. 09/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC USE32 'CODE'
ASSUME CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE ERR_CODE.INC    ;Error codes definition
INCLUDE MEMORY.INC
INCLUDE UTILS.INC	;Only for Memory debug....

INCLUDE SETUP.INC       ;NeededMem definition

UseDebug Equ No  ; If you want to use the DEBUG_MEMORY Function.
                 ; ! Warning: It uses one function of UTILS.INC, don't forget
                 ;            to link the UTILS.OBJ file.

;=============================================================================

; Memory Structures

FreeBlock Struc
FBid      DD 0          ;MemBlock Identifier 'AMEM' or 'FMEM'
FBLen     DD 0          ;Length of the block
FBPrevF   DD 0          ;Pointer to the previous Free memory Block
FBNextF   DD 0          ;Pointer to the next Free memory Block
ends

AllocBlock Struc
ABid      DD 0          ;MemBlock Identifier 'AMEM' or 'FMEM'
ABLen     DD 0          ;Length of the block
ABPrevF   DD 0          ;Pointer to the previous Free memory Block
ABNext    DD 0          ;Pointer to the next memory Block
ends

if _WATCOM

ifdef STACKCALL
Global malloc  :Near
Global free    :Near
else
Global malloc_ :Near
Global free_   :Near
endif

endif

;============================================================================

If ( (OS EQ PMODEW_ASM) or (OS EQ DOS4GW_ASM) or (OS EQ PMODEW_C) or (OS EQ DOS4GW_C))
MemInfo DD 12 DUP (0)
Endif

Memorystart     DD 0  ;Start of the heap
Firstfreeblock  DD 0  ;Pointer to the first free memory block
_blocklen       DD 0  ;Length of the revious allocated block
Memory_Return	DD 0

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _Malloc: Allocate a memory block                                        ณ
;ณ                                                                         ณ
;ณ Input: EAX, Size of the memory block to allocate                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         EAX pointer to the allocated memory block                       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_Malloc Proc

if _WATCOM                      ; ** WATCOM **
        add eax,3
        and eax,0FFFFFFFCh

	mov _Blocklen,eax
ifdef STACKCALL
        push edx eax
        call malloc             ; call the WATCOM Memory allocation function
        pop edx edx
else
        call malloc_            ; call the WATCOM Memory allocation function
endif
        cmp eax,0
	jne malloc_ok
        mov eax,2
	mov Memory_Return,eax
	stc
	ret	
malloc_ok:
	mov Memory_Return,eax
	clc
	ret
elseif (OS EQ KERNEL)           ; ** KERNEL **

        call malloc
        jz E_outofmemory

        mov Memory_Return,eax
        clc                     ; Clear Carry => Ok
        ret
else                            ; ** EOS, DOS32, PMODE/W ASM, DOS4G/W ASM **
        cmp eax,0
        jz _mallocfail          ; AskFornomem Error
        cmp eax,-32
        jae E_outofmemory       ; OutOfMemory Error
        add eax,3
        and eax,0FFFFFFFCh      ; Align length to a dword
        mov _blocklen,eax
        add eax,32
        cmp Memorystart,0
        jnz _domalloc

        pushad
        call MEMORY_Init
        popad
        jc _MallocRet

_domalloc:
        mov esi,Firstfreeblock
_mallocloop:
        cmp [esi],'FMEM'
        jne E_blockdestroyed    ; blockdestroyed Error
        cmp [esi+FBLen],eax
        jae _foundblock         ; Actual free block size > size needed ?
        mov esi,[esi+FBNextF]   ; Go to next free block
        cmp esi,0
        jne _mallocloop
        jmp E_outofmemory       ; no more free block => Out of Memory

_foundblock:
        sub eax,16
        mov edi,esi
        add edi,eax             ; edi <- FBStart+Size : Next Free Block
        cmp esi,Firstfreeblock
        jne _notfirstfreeblock
        mov Firstfreeblock,edi  ; Set New First Free Block
_notfirstfreeblock:
                                ; ** New Block **
        mov [esi+ABid],'AMEM'   ; New block <- alloc block          (1)
        mov ebx,[esi+FBLen]     ; Get old block length
        sub ebx,eax             ; ebx <- ebx-eax : next block len
        mov [esi+ABLen],eax     ; Set new block length              (2)
        mov ecx,[esi+FBNextF]   ; Get old next free block pointer
        mov [esi+ABNext],edi    ; Set new next block pointer        (4)

                                ; ** Next Block ** (create a free block)
        mov [edi+FBid],'FMEM'   ; next block <- free block          (1)
        mov [edi+FBLen],ebx     ; Set next block len                (2)
        mov [edi+FBNextF],ecx   ; Set next block next block pointer (4)
        mov ecx,[esi+ABPrevF]   ; Get old prev free block Ptr
        mov [edi+FBPrevF],ecx   ; Set next prev free block ptr      (3)

                        ; *Now update the next and previous pointers*

        cmp ecx,0
        jz  _maNoPrevFree       ; End if no prev free block exists
        cmp [ecx+FBid],'FMEM'   ; Is it really a free block ?
        jne E_blockdestroyed
        mov [ecx+FBNextF],edi   ;                                   (4)

_maNoPrevFree:

        cmp [edi+FBNextF],0     ; Is it the last Block ?
        je _mallocend           ; Yes, End
                                ; No, update Next blocks pointers
        mov eax,esi
        mov esi,edi
        add edi,ebx             ; Start of next block

        cmp [edi+ABid],'AMEM'
        jne E_blockdestroyed    ; Next block must be an allocated block...
_MAupdatePrevFreeLoop:
        cmp [edi+FBid],'FMEM'
        je  _MAUpdateLoopEnd
        cmp [edi+ABid],'AMEM'
        jne E_blockdestroyed
        mov [edi+ABPrevF],esi
        mov edi,[edi+ABNext]
        jmp _MAupdatePrevFreeLoop	
_MAUpdateLoopEnd:
        mov [edi+FBPrevF],esi
        mov esi,eax

_mallocend:
        mov eax,esi             ; returns a pointer to the allocated
        add eax,16              ; block
        clc                     ; Clear Carry => Ok
        mov Memory_Return,eax
        ret                     ; End
_mallocfail:
        mov Memory_Return,eax
        stc
_MallocRet:
        ret
endif
_Malloc Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _Calloc: Allocate and clear a memory block                              ณ
;ณ                                                                         ณ
;ณ Input: EAX, Size of the memory block to allocate                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         EAX pointer to the allocated memory block                       ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_Calloc Proc
        call _Malloc
        jc _callocend           ; Allocate a Memory Block
        push eax
        mov edi,eax             ; edi <- Memory block location
        xor eax,eax
        mov ecx,_BlockLen
        shr ecx,2               ; ecx <- Block size
        cld
        push ds
        pop es                  ; es <- ds
        rep stosd               ; Delete the Memory Block.
        pop eax
        clc
_callocend:
        mov Memory_Return,eax
        ret
_Calloc Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _Free: Free an allocated memory block                                   ณ
;ณ                                                                         ณ
;ณ Input: EAX, pointer to the memory block to free.                        ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear=> Ok                                                   ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_Free Proc
if _WATCOM                      ; ** WATCOM **

ifdef STACKCALL
        push edx eax
        call free
        pop edx eax
else
        call free_
endif

        xor eax,eax
        mov Memory_Return,eax
        clc                     ; Clear Carry => Ok
        ret
elseif (OS EQ KERNEL)           ; ** KERNEL **
        call Free
        xor eax,eax
        mov Memory_Return,eax
        clc                     ; Clear Carry => Ok
        ret
else
        cmp eax,0
        je  _Free_End
        sub eax,16              ; Check if the input @ is an allocated block @
        cmp [eax+ABid],'FMEM'
        je  E_BlockFree         ; BlockFree Error
        cmp [eax+ABid],'AMEM'
        jne E_blockdestroyed    ; BlockDestroyed Error

        mov ebx,Firstfreeblock
        mov esi,[eax+ABPrevF]   ; esi <- Offset of the next free block
        cmp esi,0
        je  _PrevAlloc
        mov edi,esi
        add edi,[esi+FBLen]
        mov ecx,[esi+FBPrevF]
        mov ebx,[esi+FBNextF]   ; Get NextFreeBlock Ptr in the PrevFreeBlock	
        cmp edi,eax             ; Previous block is a free block ?
        je _PrevFree
_PrevAlloc:
        mov esi,eax             ; New Free block @ is the Deleted block @
        mov ecx,[eax+ABPrevF]
_PrevFree:
                                ; esi <- Offset of the new free block
                                ; ecx <- Prev Free block	
        mov edi,[eax+ABNext]
        cmp edi,0
        je  _NextAlloc
        cmp [edi],'AMEM'
        je  _NextAlloc
        cmp [edi],'FMEM'
        jne E_blockdestroyed    ; BlockDestroyed Error
        mov edx,[edi+FBNextF]
        add edi,[edi+FBLen]
        jmp _NextFree
_NextAlloc:
        mov edx,ebx
_NextFree:                      ; edi <- End of the new free block
        mov ebx,edi
        sub ebx,esi             ; ebx <- Len of the new free block				
                                ; edx <- Next Free Block

        mov [esi+FBid],'FMEM'   ; | Create the new Free block
        mov [esi+FBlen],ebx     ; |
        mov [esi+FBPrevF],ecx   ; |
        mov [esi+FBNextF],edx   ; |

                                ; *Now update the next and previous pointers*

        cmp ecx,0               ; do a prev free block exist ?
        je  _Notupdatenextfree
        cmp [ecx+FBid],'FMEM'   ; Is it really a free block ?
        jne E_blockdestroyed
        mov [ecx+FBNextF],esi   ; Yes => Set new pointer to next free block	
_Notupdatenextfree:
        cmp esi,Firstfreeblock  ; New Free block is first free block ?
        jae _notfirstfreeblock2
        mov Firstfreeblock,esi  ; Yes -> Set New First Free Block
_notfirstfreeblock2:

        cmp edx,0               ; Is it the last Free block ?
        je  _Free_End           ; Yes => It is the last block, do not update
                                ;        the next blocks !!!
_updatePrevFreeLoop:
        cmp [edi+FBid],'FMEM'
        je  _UpdateLoopEnd
        cmp [edi+ABid],'AMEM'
        jne E_blockdestroyed
        mov [edi+ABPrevF],esi
        mov edi,[edi+ABNext]
        jmp _updatePrevFreeLoop	
_UpdateLoopEnd:
        mov [edi+FBPrevF],esi

_Free_End:
        mov Memory_Return,eax
        clc
        ret
endif
_Free Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _Maxavail: Get the length of the biggest free block.                    ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear=> Ok                                                   ณ
;ณ         EAX returns 'Maxavail'                                          ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_Maxavail Proc
if (OS EQ KERNEL)
        call Hi_MaxAvail
else
        cmp Memorystart,0
        jnz _domaxavail

        call MEMORY_Init
        jc _MaxavailRet
_domaxavail:
        mov eax,0
        mov esi,Firstfreeblock
_maxavailloop:
        cmp [esi],'FMEM'
        jne E_blockdestroyed    ; blockdestroyed Error
        cmp [esi+FBLen],eax
        jb  _nextFreeblock
        mov eax,[esi+FBlen]
_nextfreeblock:
        mov esi,[esi+FBNextF]
        cmp esi,0
        jne _maxavailloop

        sub eax,32
endif
        mov Memory_Return,eax
        clc
_MaxavailRet:
        ret
_Maxavail Endp


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _Debug_MEMORY: Display the Memory Blocs.                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

If (UseDebug Eq 1)
_Debug_Memory Proc
        writeln
        write 'FirstFreeBlock:'
        mov eax,FirstFreeBlock
        call print_hex
        writeln

        mov esi,MemoryStart
_Debug_Loop:
        cmp [esi],'FMEM'
        je _D_Fmem
        cmp [esi],'AMEM'
        je _D_Amem
        ret
_D_FMem:
        Write '('
        mov eax,esi
        call Print_hex
        Writeln ') Id: FMEM'
        Write 'FBLen: '
        mov eax,[esi+FBlen]
        push eax
        call Print_hex
        pop eax
        write ' ('
        call print_dec
        Writeln ')'
        Write 'FBPrevF: '
        mov eax,[esi+FBPrevF]
        call Print_hex
        Writeln ' '
        write 'FBNextF: '
        mov eax,[esi+FBNextF]
        Call print_hex
        Writeln ' '
        Waitkey
        cmp [esi+FBNextF],0
        je _D_End
        add esi,[esi+FBlen]
        Jmp _Debug_Loop
_D_AMem:
        Write '('
        mov eax,esi
        call Print_hex
        Writeln ') Id: AMEM '
        Write 'ABLen: '
        mov eax,[esi+ABlen]
        call Print_hex
        Writeln ' '
        Write 'ABPrevF: '
        mov eax,[esi+ABPrevF]
        call Print_hex
        Writeln ' '
        write 'ABNext: '
        mov eax,[esi+ABNext]
        Call print_hex
        Writeln ' '
        add esi,[esi+ABlen]
        WaitKey
        Jmp _Debug_Loop
_D_End:
        ret
_Debug_Memory Endp
EndIf

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ _MEMORY_Error: Display the Memory Error.                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

_MEMORY_Error Proc
        jnc _MEMORY_Error_End
        Write 'Memory_Error: '
        cmp eax,ME_AskForNoMem
        jne D_AskForNoMem
        Writeln '0 bytes malloc.'
D_AskForNoMem:
        cmp eax,ME_OutOfMemory
        jne D_OutOfMemory
        Writeln 'Out of memory.'
D_OutOfMemory:
        cmp eax,ME_BlockDestroyed
        jne D_BlockDestroyed
        Writeln 'Memory heap corrupted.'
D_BlockDestroyed:
        cmp eax,ME_BlockFree
        jne D_BlockFree
        Writeln 'Memory Block already free.'
        D_BlockFree:
;	Writeln 'Pas d''erreur !! ?????'
_MEMORY_Error_End:

        mov ax,4C00h
        int 21h

        ret
_MEMORY_Error Endp

;***************************************************************
;********************  Internal functions **********************
;***************************************************************

if not (OS EQ KERNEL)
E_AskFornomem Proc
       mov eax,ME_AskForNoMem
       mov Memory_Return,eax
       stc
       ret
E_AskFornomem Endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  E_blockdestroyed: Returns a blockdestroyed error                       ณ
;ณ                                                                         ณ
;ณ Output: CF Set and eax=ME_BlockDestroyed                                ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
if not (OS EQ KERNEL)
E_blockdestroyed Proc
        mov eax,ME_BlockDestroyed
        mov Memory_Return,eax
        stc
        ret
E_blockdestroyed Endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  E_outofmemory: Returns an outofmemory error                            ณ
;ณ                                                                         ณ
;ณ Output: CF Set and eax=ME_OutOfMemory                                   ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
E_outofmemory Proc
        mov eax,ME_OutOfMemory
	mov Memory_Return,eax
        stc
        ret
E_outofmemory endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  E_BlockFree: Returns a BlockFree error                                 ณ
;ณ                                                                         ณ
;ณ Output: CF Set and eax=ME_BlockFree                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
if not (OS EQ KERNEL)
E_BlockFree Proc
        mov eax,ME_BlockFree
        mov Memory_Return,eax
        stc
        ret
E_BlockFree Endp
endif

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ Memory_Init: Initialise the Memory Mannager                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
if not (OS EQ KERNEL)
MEMORY_Init Proc

if (OS EQ DOS32)

        mov edx,-1                      ; Ask DOS32 for 4Gb memory
        mov ax,0EE42h
        int 31h                         ; Returns EAX with actual size
        push eax
        mov eax,0EE40h                  ; Free the previous allocated block
        int 31h
        pop edx

        sub edx,16+NeededMem            ; Allocate (Free Memory-NeededMem)
        js E_OutOfMemory

        mov ax,0EE42h                   ; Allocate memory
        int 31h                         ; Returns EAX with actual size

        jbe E_outofmemory
endif

if ((OS eq EOS) OR (OS eq EOS3))

        mov edx,128*1024*1024           ;Try to allocate 128Mb
        mov ah,Allocate_Memory
        Int_EOS
        sub eax,16+4*1024+NeededMem     ;Allocate (Free Memory-NeededMem)
        js  E_OutOfMemory               ;if eax<0 => Out of memory
        add eax,16
        mov edx,eax
        push eax
        mov ah,Allocate_Memory
        Int_EOS
        pop eax
        jc E_outofmemory

endif

if ( (OS EQ PMODEW_ASM) or (OS EQ DOS4GW_ASM) or (OS EQ PMODEW_C) or (OS EQ DOS4GW_C))

        mov ax,0500h           ;Get Free Memory Information
        push ds
        pop es
        mov edi,Offset MemInfo ;ES:EDI pointer to a 48 byte Offset
        int 31h
        jc E_Outofmemory

        mov ax,0501h           ;Allocate memory block
        mov ebx,MemInfo

        sub ebx,1024*16+NeededMem
        push ebx
        mov cx,bx
        shr ebx,16             ;BX:CX Size of block
        int 31h
        pop eax                ;Block size is now in eax
        jc E_Outofmemory

        mov dx,bx
        shl edx,16
        mov dx,cx              ;Block Offset (BX:CX)

endif

        mov Memorystart,edx                 ; edx, memory block offset
        mov Firstfreeblock,edx
        mov FBId[edx],'FMEM'                ; First block=>Free Block
        mov FBLen[edx],eax                  ; eax, memory block size
        mov FBPrevF[edx],0
        mov FBNextF[edx],0

        clc
        ret
MEMORY_Init Endp
endif

CODE32 ENDS
End
; MEMORY.ASM (c) 1997 FreddyV/Useless