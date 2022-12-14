;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?      ?????????????? FILES.ASM ??????????????      ?
;            ?                                                   ?
;            ?              Useless Files Manager                ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   By Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code Starts .................. 31/03/1996       ?
;            ?   Last Update .................. 02/05/1998       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE ERR_CODE.INC
INCLUDE FILES.INC

INCLUDE UTILS.INC

;=============================================================================

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;? U_fopen: Open a file                                                    ?
;?                                                                         ?
;? Input: EDX, pointer to the file name (terminated with a 0)              ?
;?        AL,  Access mode (00h read only, 01h write only, 02 read/write ) ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;?                                                                         ?
;?         CF Clear                                                        ?
;?         AX file handle                                                  ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fopen proc
if (OS EQ KERNEL)
        call FileOpen
        jc Ferror
else
        mov ah,3Dh      ; open a file function
        int 21h
        jc ferror
endif
        ret
U_fopen endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  U_fcreate: Create a file                                               ?
;?                                                                         ?
;? Input: EDX, pointer to the file name (terminated with a 0)              ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;?                                                                         ?
;?         CF Clear                                                        ?
;?         AX file handle                                                  ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fcreate proc
if (OS EQ KERNEL)
        call FileCreate
        jc ferror
else
        mov ax,3C02h            ; creat a file function
        xor ecx,ecx
        int 21h
        jc ferror
endif
        ret
U_fcreate endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  U_fclose: Close a file                                                 ?
;?                                                                         ?
;? Input: BX, file handle                                                  ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fclose proc
if (OS EQ KERNEL)
        call FileClose
        jc ferror
else
        mov ah,03Eh         ; close a file function
        int 21h
        jc ferror
endif
        ret
U_fclose endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  U_fsetpos: Set/read the file pos                                       ?
;?                                                                         ?
;? Input: AL  origin of move                                               ?
;?         00h start of file                                               ?
;?         01h current file position                                       ?
;?         02h end of file                                                 ?
;?        BX  file handle                                                  ?
;?        EDX  offset from origin of new file position                     ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;?                                                                         ?
;?         CF Clear                                                        ?
;?         EAX new file position in bytes from start of file               ?
;?                                                                         ?
;?         Warning: Seek is alwas from begin with KERNEL 386               ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fsetpos proc
If _DPMI
        mov ecx,edx     ; Convert EDX to CX:DX (for DPMI compliant extenders)
        shr ecx,16
        mov ah,42h
        int 21h
        jc ferror
elseif (OS EQ KERNEL)
        mov eax,edx
        call FileSeek
        jc ferror
else
        mov ah,42h
        int 21h
        jc ferror
endif        
        ret
U_fsetpos endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;? U_fread: read from the file                                             ?
;?                                                                         ?
;? Input: EDX bufer offset                                                 ?
;?        ECX Length of the buffer                                         ?
;?        BX  file handle                                                  ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fread  proc
if (OS EQ KERNEL)
        call FileRead
        jc ferror
else
        mov ah,3Fh
        int 21h
        jc ferror
endif
        ret
U_fread endp

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  U_fwrite: write to the file                                            ?
;?                                                                         ?
;? Input: EDX bufer offset                                                 ?
;?        ECX Length of the buffer                                         ?
;?        BX  file handle                                                  ?
;?                                                                         ?
;? Output: CF Set=> Error                                                  ?
;?         AX returns the error number                                     ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
U_fwrite proc
if (OS EQ KERNEL)
        call FileWrite
        jc ferror
else
        mov ah,40h
        int 21h
        jc ferror
endif        
        ret
U_fwrite endp

ferror proc
        movzx eax,al
        cmp al,7
        jb ferrorEnd
        mov al,1        
ferrorEnd:
        add ax,File_Error
        stc
        ret
ferror Endp

CODE32 ENDS
;=============================================================================
end
; FILES.ASM (c) 1997 FreddyV/Useless