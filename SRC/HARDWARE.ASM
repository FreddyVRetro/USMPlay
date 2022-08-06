;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º    ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ HARDWARE.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷     º
;            º                                                   º
;            º           Hardware functions (DMA/IRQ)            º
;            º                                                   º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code Starts .................. 25/08/1996       º
;            º   Last Update .................. 02/05/1998       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
;
;! Warning: You must call HardwareInit first in your main procedure
;           Because of DOS32 Memory allocation problem.
;           HardwareInit allocate one 16kb DMA buffer, all DMA transfer
;           must be done with it.
;           Use HardwareEnd at the End
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC
INCLUDE HARDWARE.INC
INCLUDE UTILS.INC

;------------------------------------------------------------------------------

if UseDMA Eq Yes
DMABuffer      DD 0
DMARealAddress DD 0
endif

;------------------------------------------------------------------------------

DisplayOffset EQU 0

If ((OS EQ EOS) OR (OS EQ EOS3))

ZeroOffset EQU Zero_Addr
PSPOffset  EQU PSP_Addr
EnvOffset  EQU Environment_Addr

Else

ZeroOffset   DD 0  ; Zero base Offset
PSPOffset    DD 0  ; PSP Offset
EnvOffset    DD 0  ; Offset to the environment variables

EndIf

;------------------------------------------------------------------------------

EnvStrOffset DD 0  ; Offset to the environment string to read.


;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ HardwareInit: Init Offset variables and DMA buffer                      ³
;³                                                                         ³
;³ Input: ES, PSP selector for DPMI extenders (PMODE/W,DOS4G/W...)         ³
;³        AX, PSP selector for WATCOM C                                    ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

HardwareInit  Proc

If (OS EQ KERNEL)
        mov ebx,Code32Base
        neg ebx
        mov ZeroOffset,ebx
        mov eax,PSPBase
        add eax,ebx
        mov PSPOffset,eax
        mov eax,EnvBase
        add eax,ebx
        mov EnvOffset,eax
endif

If (OS EQ DOS32)
        mov ax,0EE02h                 ; Get DOS32 Address information
        int 31h
        neg ebx                       ; EBX = program address
	mov ZeroOffset,ebx
        mov PSPOffset,esi
        mov EnvOffset,edi

Endif

If ( (OS EQ PMODEW_C) or (OS EQ DOS4GW_C))
        push es
        mov es,ax
        mov bx,es:[2Ch] ; Env var selector (PSP:2Ch)
        pop es
        mov ax,6        ; Get selector base @ DPMI function
        xor edx,edx
        int 31h
        shl edx,16      ; CX:DX = 32bit linear base address
        shrd edx,ecx,16
        mov EnvOffset,edx

        mov bx,es       ; PSP selector
        mov ax,6        ; Get selector base @ DPMI function
        xor edx,edx
        int 31h
        shl edx,16      ; CX:DX = 32bit linear base address
        shrd edx,ecx,16
        mov PSPOffset,edx

        mov ZeroOffset,0
Endif

If ( (OS EQ PMODEW_ASM) or (OS EQ DOS4GW_ASM))
        mov bx,es:[2Ch] ; Env var selector (PSP:2Ch)
        mov ax,6        ; Get selector base @ DPMI function
        xor edx,edx
        int 31h
        shl edx,16      ; CX:DX = 32bit linear base address
        shrd edx,ecx,16
        mov EnvOffset,edx

        mov bx,es       ; PSP selector
        mov ax,6        ; Get selector base @ DPMI function
        xor edx,edx
        int 31h
        shl edx,16      ; CX:DX = 32bit linear base address
        shrd edx,ecx,16
        mov PSPOffset,edx

        mov ZeroOffset,0
Endif

If (DisplayOffset EQ 1)
        write 'ZeroOffset: '
        mov eax,ZeroOffset
        call print_hex
        writeln
        write 'PSPOffset: '
        mov eax,PSPOffset
        call print_hex
        writeln
        waitkey
Endif        

If UseDMA Eq Yes
        call DMA_AllocBuffer
        mov DMABuffer,edx
        mov DMARealAddress,ebx
EndIf
        ret
HardwareInit  Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ IRQ_Enable: Enable an Hardware IRQ                                      ³
;³                                                                         ³
;³ Input: DL, IRQ Number                                                   ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if UseIRQEnable Eq Yes
IRQ_Enable Proc
        mov cl,dl
        mov bx,not 1
        rol bx,cl

        cmp dl,7
        ja En_2

        in al,21h
        and al,bl
        out 21h,al

        jmp IRQ_EnableEnd
En_2:
        in al,0A1h
        and al,bh
        out 0A1h,al

        in al,21h        ; Enable IRQ 2 cascade
        and al,11111011b
        out 21h,al

IRQ_EnableEnd:
        ret
IRQ_Enable Endp
endif

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ IRQ_Disable: Disable an Hardware IRQ                                    ³
;³                                                                         ³
;³ Input: DL, IRQ Number                                                   ³
;³                                                                         ³
;³ Output: --                                                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if UseIRQEnable Eq Yes
IRQ_Disable Proc
        mov cl,dl
        mov bx,1
        shl bx,cl

        cmp dl,7
        ja Di_2

        in al,21h
        or al,bl
        out 21h,al

        jmp IRQ_DisableEnd
Di_2:
        in al,0A1h
        or al,bh
        out 0A1h,al

IRQ_DisableEnd:
        ret
IRQ_Disable Endp
endif

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ GetEnvOffset: Returns the Environement variable Offset                  ³
;³                                                                         ³
;³ Input: EAX, Offset of the variable name                                 ³
;³                                                                         ³
;³ Output: EDI, Variable offset if CF cleared                              ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
GetEnvOffset Proc
        cld
        push ds
        pop es
	mov EnvStrOffset,eax
        mov edi,EnvOffset

EnvLoop:
        mov esi,EnvStrOffset
        movzx ecx,Byte Ptr[esi]
        inc esi
        repe cmpsb
        jne WrongString	

        inc edi
        clc
        ret
WrongString:
        xor al,al
        mov ecx,400h
        repne scasb
        or ecx,ecx
        jz EnvNotFound
        cmp byte Ptr [edi],0
        jnz EnvLoop

EnvNotFound:
        stc
        ret
GetEnvOffset Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ "DMA_Setup"   PROGRAM A CHANNEL ON THE 8237 DMA CONTROLLER               ³
;³             A general routine to program the DMA controler.              ³
;³                                                                          ³
;³ By Adam Seychell                                                         ³
;³                                                                          ³
;³                                                                          ³
;³ INPUT:        AL    Mode Register  ( bits 0..1 ignored )                 ³
;³               AH    channel   ( 0..7 )                                   ³
;³               EBX   Physical Base Address ( 0..0ffffffh )                ³
;³               ECX   Bytes to transfer     ( 1..10000h )                  ³
;³                                                                          ³
;³                                                                          ³
;³Distroys:  EAX, EDX & ECX                                                 ³
;³                                                                          ³
;³        code has been optimized and fully tested.                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
If UseDMA Eq Yes
DMA_Setup Proc

        xor     edx,edx
        and     ah,7
        mov     DMA_channel,ah
        and     al,NOT 3
        mov     mode,al

        ; -----  set channel mask register ------
        movzx   edi,DMA_channel
        mov     eax,edi
        shr     edi,2
        and     al,0011b
        or      al,0100b
        mov     dl,DMA_SNGL[edi]   ; 0Ah=Canal DMA+4
        out     dx,al

        ; ----- set mode register ------
        and     al,03h
        or      al,mode
        mov     dl,DMA_MODE[edi]
        out     dx,al

        ; ------  clear MSB/LSB flip flop -----------
        mov     dl,DMA_CLRFF[edi]
        out     dx,al

        ;---- set byte count register ----
        movzx   edi,DMA_channel
        mov     eax,ecx
        mov     ecx,edi
        shr     ecx,2
        shr     eax,cl                ; divide count address by 2 for DMA # 2
        dec     eax                   ; count - 1
        mov     dl,DMA_CNT[edi]       ; bits 0..7
        out     dx,al

        shr     eax,8
        out     dx,al                 ; bits 8..15

        ;---- set channel base address ---
        shr     ebx,cl                ; divide base address by 2 for DMA # 2
        mov     al,bl                       ; set bits 0..7
        mov     dl,DMA_ADDR[edi]
        out     dx,al

        mov     al,bh                       ; set bits 8..15
        out     dx,al

        shr     ebx,15           ; divide base address by 8000h for DMA # 2
        xor     cl,1
        shr     ebx,cl           ; divide base address by 10000h for DMA # 1
        mov     al,bl            ; set bits 16..23 ( in LSB page register )
        mov     dl,DMA_PAGE[edi]
        out     dx,al

        ; -----  clear channel (mask register) ------
        mov     eax,edi
        shr     edi,2
        and     al,03h
        mov     dl,DMA_SNGL[edi]
        out     dx,al

        ret

mode            DB  ?
DMA_channel     DB  ?

;* 1st & 2nd DMA Controler's ports *;

  DMA_STAT   db 008h,0D0h        ;* read status register *;
  DMA_CMD    db 008h,0D0h        ;* write command register *;
  DMA_REQ    db 009h,0D2h        ;* write request register *;
  DMA_SNGL   db 00Ah,0D4h        ;* write single bit register *;
  DMA_MODE   db 00Bh,0D6h        ;* write mode register *;
  DMA_CLRFF  db 00Ch,0D8h        ;* clear byte ptr flip;flop *;
  DMA_MCLR   db 00Dh,0DAh        ;* master clear register *;
  DMA_CLRM   db 00Eh,0DCh        ;* clear mask register *;
  DMA_WRTALL db 00Fh,0DEh        ;* write all mask register *;

; * ports for 8 channels *;

DMA_PAGE        db 087h,083h,081h,082h,08Fh,08Bh,089h,08Ah ; page register
DMA_ADDR        db 000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh ; base adddress
DMA_CNT         db 001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh ; base count

DMA_Setup   Endp
endif

;***************************************************************
;********************  Internal functions **********************
;***************************************************************

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ DMA_AllocateBuffer: Allocate One 16kb DMA buffer                        ³
;³                                                                         ³
;³ Input: --                                                               ³
;³                                                                         ³
;³ Output: EDX, Buffer Address                                             ³
;³         EBX, Buffer Physical Address                                    ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If UseDMA Eq Yes
DMA_AllocBuffer Proc

If (OS EQ KERNEL)
        mov eax,32*1024       ; I need 32Kb low memory
        call Lo_Alloc
        jz DMA_AllocBErr

        mov ebx,eax
        sub ebx,ZeroOffset

        push eax
        
        pop edx
Endif

If (OS EQ DOS32)
;display 'Allocation du tampon DMA DOS32'
        mov ax,0EE41h         ; call a DOS32 service (DMA buffer allocation)
        int 31h
        jc  DMA_AllocBErr
Endif

If ((OS EQ EOS) OR (OS EQ EOS3))
;display 'Allocation du tampon DMA EOS'

        mov bx,(32*1024)/16   ; ask DOS for 32Kb
        mov ah,48h
        DosInt 21h
        jc DMA_AllocBErr

        movzx ebx,ax
        mov dx,ax
        shr ax,12
        add dx,(16*1024)/16
        shr dx,12
        cmp dx,ax
        je  DMAAddressOk
        add bx,(16*1024)/16   ; DMA buffer cross a 64k page => Use second
DMAAddressOk:

        shl ebx,4
        mov edx,ebx
        add edx,Zero_Addr

Endif

If ((OS EQ PMODEW_ASM) OR (OS EQ DOS4GW_ASM) OR (OS EQ PMODEW_C) OR (OS EQ DOS4GW_C))
;display 'Allocation du tampon DPMI'

        mov ebx,(32*1024)/16   ; ask DPMI for 32kb DOS memory.
        mov eax,100h
        Int 31h
        jc DMA_AllocBErr

        movzx ebx,ax
        mov dx,ax
        shr ax,12
        add dx,(16*1024)/16
        shr dx,12
        cmp dx,ax
        je  DMAAddressOk
        add bx,(16*1024)/16   ; DMA buffer cross a 64k page => Use second
DMAAddressOk:

        shl ebx,4
        mov edx,ebx
        add edx,ZeroOffset

Endif

;call debug

DMA_AllocBOk:
        clc
        ret
DMA_AllocBErr:
        write 'Can''t allocate DMA buffer.'

        stop

        stc
        ret
DMA_AllocBuffer Endp
EndIf

CODE32 ENDS
;=============================================================================
END
; HARDWARE.ASM (c) 1997 FreddyV/Useless
