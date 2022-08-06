;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ      ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ FILES.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ              Useless Files Manager                บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 31/03/1996       บ
;            บ   Last Update .................. 02/05/1998       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE ERR_CODE.INC
INCLUDE FILES.INC

INCLUDE UTILS.INC

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ U_fopen: Open a file                                                    ณ
;ณ                                                                         ณ
;ณ Input: EDX, pointer to the file name (terminated with a 0)              ณ
;ณ        AL,  Access mode (00h read only, 01h write only, 02 read/write ) ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         AX file handle                                                  ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  U_fcreate: Create a file                                               ณ
;ณ                                                                         ณ
;ณ Input: EDX, pointer to the file name (terminated with a 0)              ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         AX file handle                                                  ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  U_fclose: Close a file                                                 ณ
;ณ                                                                         ณ
;ณ Input: BX, file handle                                                  ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  U_fsetpos: Set/read the file pos                                       ณ
;ณ                                                                         ณ
;ณ Input: AL  origin of move                                               ณ
;ณ         00h start of file                                               ณ
;ณ         01h current file position                                       ณ
;ณ         02h end of file                                                 ณ
;ณ        BX  file handle                                                  ณ
;ณ        EDX  offset from origin of new file position                     ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         EAX new file position in bytes from start of file               ณ
;ณ                                                                         ณ
;ณ         Warning: Seek is alwas from begin with KERNEL 386               ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ U_fread: read from the file                                             ณ
;ณ                                                                         ณ
;ณ Input: EDX bufer offset                                                 ณ
;ณ        ECX Length of the buffer                                         ณ
;ณ        BX  file handle                                                  ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  U_fwrite: write to the file                                            ณ
;ณ                                                                         ณ
;ณ Input: EDX bufer offset                                                 ณ
;ณ        ECX Length of the buffer                                         ณ
;ณ        BX  file handle                                                  ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         AX returns the error number                                     ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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