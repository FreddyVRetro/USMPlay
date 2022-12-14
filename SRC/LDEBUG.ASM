;            浜様様様様様様様様様様様様様様様様様様様様様様様様様?
;            ?     ?????????????? LDEBUG.ASM ??????????????      ?
;            ?                                                   ?
;            ?                  Loader Debugger                  ?
;            債陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
;            ?   By Freddy V?tel? (FreddyV/Useless)              ?
;            ?                                                   ?
;            ?   Code Starts .................. 06/04/1996       ?
;            ?   Last Update .................. 04/08/1996       ?
;            藩様様様様様様様様様様様様様様様様様様様様様様様様様?
; ! It's only used by me when I'm writing a new loader.
;   I included it if you want to add a driver. (SEND IT TO ME !)
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE USSVAR.INC
INCLUDE USM.INC

INCLUDE LDEBUG.INC
INCLUDE UTILS.INC

;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  Print_Header: Display the USM Header                                   ?
;?                                                                         ?
;? Input: ESI, Header location                                             ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
Print_Header Proc
	writeln 'Header USM'
	
	write 'MName: '
	mov ecx,32
        push esi
        add esi,MName
        call print_str
        pop esi
        writeln
        
        write 'MFlags: ' 
        xor eax,eax
        mov ax,MFlags[esi] 
        call Print_Hex
        Writeln
	
        write 'MVersion: ' 
        mov ax,MVersion[esi] 
        call print_Dec
        Writeln
	
        write 'MTracker: '
        mov ax,MTracker[esi] 
        call print_Dec
        Writeln
	
        write 'MChannel: '
        mov ax,MChannels[esi] 
        call print_Dec
        Writeln
	
        write 'MSongLen: '
        mov ax,MSongLen[esi]
        call Print_Dec
        Writeln
	
        write 'MPattern: '
        mov ax,MPatterns[esi]
        call Print_Dec
        Writeln
	
        write 'MRestart: '
        mov ax,MRestart[esi]
        call Print_dec
        Writeln
	
        write 'MInstruments: '
        mov ax,MInstruments[esi]
        call Print_dec
        Writeln

        write 'MSamples: '
        mov ax,MSamples[esi]
        call Print_dec
        Writeln     
        
        write 'MTempo: '	
        mov al,MTempo[esi]	
        call print_dec
        Writeln
	
        write 'MBPM: '	
        mov al,MBPM[esi]	
        call print_dec
        Writeln

	write 'MOrder: '  
	mov eax,0
	mov cx,0
PrintOrderLoop:
	mov al,MOrder[esi+ECX]
	call print_dec
	Write ','
	inc cx
	cmp MSongLen[esi],cx
	jne PrintOrderLoop

	ret
Print_Header Endp

Print_Sample Proc
        pushad

        cmp SId[esi],'LPMS'
        je SmpIdOk
        writeln 'Sample ID Incorrect !'

        popad
        ret
SmpIdOk:        

        write 'SName: '
	mov ecx,32
        push esi
        add esi,SName
        call print_str
        pop esi
        writeln        

        write 'SType: '
        movzx eax,SType[esi]
        call Print_dec
        Writeln

        write 'SFlag: '
        movzx eax,SFlag[esi]
        call Print_dec
        Writeln

        write 'SLength: '
        mov eax,SLength[esi]
        call Print_dec
        Writeln

        write 'SLoop: '
        mov eax,SLoop[esi]
        call Print_dec
        Writeln

        write 'SLoopEnd: '
        mov eax,SLoopEnd[esi]
        call Print_dec
        Writeln

        write 'SSustain: '
        mov eax,SSustain[esi]
        call Print_dec
        Writeln

        write 'SSustEnd: '
        mov eax,SSustEnd[esi]
        call Print_dec
        Writeln

        write 'SDefVolume: '
        movzx eax,SDefVolume[esi]
        call Print_dec
        Writeln

        write 'SVolume: '
        movzx eax,SVolume[esi]
        call Print_dec
        Writeln

        write 'SFine: '
        mov eax,SFine[esi]
        call Print_dec
        Writeln        
        
        popad
        ret
Print_Sample Endp


;嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様?
;?  Print_Instruments: Display the USM Instruments                         ?
;?                                                                         ?
;? Input: esi, Header location                                             ?
;?                                                                         ?
;青陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳?
NbPrinted DD 0

Print_Instruments Proc
	mov NbPrinted,0
	add esi,MInstrPtr

_Print_Instruments_Loop:
	push esi
	mov esi,[esi]
	cmp esi,0
	je _NoInstr

	write 'InstrPtr: '
	mov eax,esi	
	call print_hex	
	
	push esi
	Write ' Iname: '
	add esi,IName
	mov ecx,32
	call Print_Str	
	pop esi
	
;	Write ' NbSamples: '
;	movzx eax,INbSmp[esi] 
;	call print_dec

	Writeln ' '
	
	WaitKey
	
_NoInstr:	
	pop esi
	add esi,4
	inc NbPrinted
	cmp NbPrinted,256
	jne _Print_Instruments_Loop
	ret
Print_Instruments Endp

CODE32 ENDS
;=============================================================================
end
; LDEBUG.ASM (c) 1997 FreddyV/Useless