;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ LDEBUG.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗      บ
;            บ                                                   บ
;            บ                  Loader Debugger                  บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code Starts .................. 06/04/1996       บ
;            บ   Last Update .................. 04/08/1996       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
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

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Print_Header: Display the USM Header                                   ณ
;ณ                                                                         ณ
;ณ Input: ESI, Header location                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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


;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  Print_Instruments: Display the USM Instruments                         ณ
;ณ                                                                         ณ
;ณ Input: esi, Header location                                             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
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