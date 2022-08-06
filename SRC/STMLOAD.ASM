;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ STMLOAD.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷     º
;            º                                                   º
;            º           Useless STM Loader (STM->USM)           º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 29/09/1996       º
;            º   Last Update .................. 31/08/1997       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

PackPattern Equ Yes
FullLoad Equ Yes	; Yes => Load all (Players,trackers..)
			; No  => Load all needed for the module (Demos,games..)

INCLUDE ERR_CODE.INC
INCLUDE STMLOAD.INC

INCLUDE MEMORY.INC
INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC      ; Instruments and samples definition
INCLUDE USM.INC		; Useless Module Structures Definition


;INCLUDE UTILS.INC

;=============================================================================

DefPann DD 0

STMH DD 0
USMH DD 0
STMSamplesTable DD 0

STMOffset DD 0
USMFlags  DW 0

;=============================================================================

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  STM_LOAD: Load/convert a STM file. (STM->USM)                          ³
;³                                                                         ³
;³ Input: ESI file name/path                                               ³
;³        EAX Default panning                                              ³
;³        EBX=0 Load from a file                                           ³
;³        EBX=1 Load from memory                                           ³
;³                                                                         ³
;³ Output: CF Set=> Error                                                  ³
;³         EAX returns the error number                                    ³
;³                                                                         ³
;³         CF Clear                                                        ³
;³         ESI pointer to the USM module                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
STM_Load  Proc
        mov LoadMode,bl

        mov DefPann,eax
        mov STMH,0
        mov STMSamplesTable,0

        MOpen ESI
        jc STMLoadErr

	; *** Load the STM Header (Name+Samples def+Order) ***

	U_Calloc USMHeaderLen
        jc STMLoadErr
        mov USMH,eax

        U_Malloc STMHeaderSize
        mov STMH,eax
        jc STMLoadErr
	
        MSetPos 0                ; ! Tester MReadPos !
	Mread STMH,STMHeaderSize ; Read the STM Header
	jc STMLoadErr

        ; *** Convert STM Header -> USM Header ***

        mov esi,STMH
        mov edi,USMH

        mov MId[edi],'MLSU'
        mov MVersion[edi],USMVersion
        mov MTracker[edi],M_ST2 ; Scream Tracker 2 Module

        ; ** Period Limits **

        mov MPeriodMin[edi],56              ; Minimum amiga period value C-8
        mov MPeriodMax[edi],6848            ; Maximum amiga period value C-2

        ; ** Write Module name **

        mov ecx,20/4
        add edi,MName
        push ds
        pop es
        cld                     
        rep movsd               ;Convert the Module Name


        mov esi,STMH
        mov edi,USMH

        mov MUS_Channels,4
        mov MChannels[edi],4    ;STM is always 4 channels

                                ;Set Panning Table
        push edi
        add edi,MChPan
        mov cx,Max_Channels/4
        mov eax,DefPann
        cld
        rep stosd	
        pop edi
                                ;Set channel volume table
        push edi
        add edi,MChVol
        mov ecx,Max_Channels
        mov al,64
        rep stosb
        pop edi

        movzx eax,STMPatterns[esi]  
        or eax,eax
        jz STMLoadErr
        mov MPatterns[edi],ax	
        mov PTotal,ax           ;Save the Number of patterns	

        xor eax,eax
        mov MRestart[edi],ax    ;Restart Pos 
				
        mov MSamples[edi],31
        mov al,StmTempo[esi]
        shr al,4
        cmp al,0
        jne STMTempoOk
        mov al,6
STMTempoOk:        
        mov MTempo[edi],al
        mov MBPM[edi],125
        mov MGVolume[edi],64*2

        U_Malloc STMSampleSize*31
        mov STMSamplesTable,eax
	MRead eax,STMSampleSize*31

        add edi,MOrder          ;Read song order
        MRead edi,128

        xor ecx,ecx             ;Check if order is correct.
        xor ebx,ebx
GetSongLenLoop:
        mov al,[edi+ecx]
        cmp al,99
        ja  STMLoadErr
        je  GetSongLenEnd
        inc ebx
        inc ecx
        cmp ecx,128
        jne GetSongLenLoop
GetSongLenEnd:

        mov edi,USMH
        mov MSongLen[edi],bx    ;Ok, Song length found
	
	call STM_LoadPatterns

        mov eax,MUS_Offset
        mov STMOffset,eax
	call STM_LoadSamples

	clc
	mov esi,USMH		;Returns a pointer to the Module...
	jmp STMLoadEnd	
	
STMLoadErr:
        push eax
        MCLose                  ;Close the file
        pop eax

if _WATCOM
        mov _Error_Number,eax
        xor eax,eax
        ret
else
        stc
        ret
endif        
		
STMLoadEnd:

	MClose		;Close the file
        cmp STMH,0
        je NoSTMHFree
        U_Free STMH
NoSTMHFree:	
	cmp STMSamplesTable,0
	je NoSTMSFree
        U_Free STMSamplesTable
NoSTMSFree:
        clc 
        ret
STM_Load  Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  STM_Loadpatterns: Load/convert MOD patterns. (MOD->USM)                ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; STM notes storage:
;
; oooonnnn iiiiivvv VVVVcccc pppppppp
;
; oooo Octave, nnnn Note, iiii Instrument, VVVVvvv Volume
; cccc Commande, pppppppp Command parameter

PCount DW 0
PTotal DW 0
PPtr   DD 0
PEnd   DD 0

STMCmd DB 0FFh
       DB _SetTempo_BPM
       DB _Jump
       DB _Break
       DB _VolumeSlide
       DB _PortDown
       DB _PortUp
       DB _PortaNote
       DB _Vibrato
       DB _Tremor
       DB _Arpeggio
       DB _VVolumeSlide
       DB 0FFh,0FFh,0FFh,0FFh

USMPattSize EQU USMPatternSize+4*64*5
STMPattSize EQU 4*64*4

STMPPtr DD 0

;Warning: PTotal must be >0 

STM_LoadPatterns Proc Near

        mov PCount,0

        U_Malloc STMPAttSize            ;Allocate the STM patter data buffer
        mov STMPPtr,eax
        
_LoadPatternsLoop:
	
        U_Calloc USMPAttSize		;Allocate USM Pattern Memory
        mov PPtr,eax

If PackPattern Eq No
        mov edi,USMH
        movzx edx,PCount
        mov MPattPtr[edi+4*edx],eax	;Save the Pattern Offset
EndIf
        
        mov ecx,STMPattSize
        MRead STMPPtr,ecx               ;Load the STM pattern data

	; Convert the pattern STM->USM
	
        mov esi,STMPPtr	
        mov edi,PPtr
	
        mov ax,PCount
        mov Pnumber[edi],ax
        mov ax,64
        mov Prow[edi],ax
        mov eax,USMPattSize

        If FullLoad eq yes
        mov SId[edi],'PLSU'
        mov eax,USMPattSize
        mov Psize[edi],eax
        endif
        
        mov PEnd,edi
        add PEnd,eax
	
        add edi,USMPatternSize
_PConvertLoop:
        xor eax,eax

        mov al,[esi]    ;* Read note number
	
        mov bl,al
        and bl,0F0h
        cmp bl,70h      ;Octave>7 => Error
        ja NoNote
	
        mov bl,al
        and bl,0Fh
        cmp bl,0Bh      ;Note>11 => Error
        ja NoNote    

        shr al,4
        add al,3        ;2 octaves higher than FT2 octave 0 (3 from IT octave -1)
        imul ax,12      ;al=12*Octave
        add bl,al       
        inc bx
	
        mov [edi],bl	;* Write note number
NoNote:

        mov al,[esi+1]  
        shr al,3
        mov [edi+1],al	;* Write sample number

        mov al,[esi+2]
        and al,0F0h
        shr al,1
        mov bl,[esi+1]
        and bl,07h
        add al,bl
        cmp al,64
        jbe VolumeOk
        mov al,-10h
VolumeOk:
        add al,10h      ;It's XM like volume => volume 0 is 10h
	mov [edi+2],al  ;* Write Volume
NoVolume:
        movzx eax,byte ptr [esi+2]	
	mov cl,[esi+3]
	and al,0Fh
	mov al,STMCmd[eax]
        
        cmp al,15
        jne NotAdjustTempo
        shr cl,4        ; STM Tempo is 16 times finer than MOD/XM ones
                        ; (Convertion lost precision, but it's quite correct)
NotAdjustTempo:        
        cmp al,0FFh
        jne NoEmptyCmd
        mov cl,0
        mov al,0
NoEmptyCmd:        
        mov [edi+3],al  ;* Write effect number
        mov [edi+4],cl  ;* Write effect parameter
	add esi,4
	add edi,5
	cmp edi,PEnd
	jb  _PconvertLoop

; Pack the pattern

If PackPattern Eq Yes
        mov esi,PPtr
        call LU_PackPattern

        mov edi,USMH                 ;Useless Module header Offset
        movzx edx,PCount             ;Get the pattern number
        mov MPattPtr[edi+4*edx],esi  ;Save the Pattern Offset
EndIf

        inc PCount
        mov ax,Ptotal
        cmp PCount,ax
        jne _LoadPatternsLoop      ; Pattern Loop

        U_Free STMPPtr

        clc
        ret

STM_LoadPatterns Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  STM_LoadSamples: Load/convert STM samples. (STM->USM)                  ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SCount	DW 0
USMSOffset DD 0

STM_LoadSamples Proc Near

        mov SCount,0
	
_LoadSamplesLoop:

        U_Calloc USSSampleSize
        mov USMSOffset,eax

        mov esi,USMH
        movzx edx,SCount
        mov MSamplPtr[esi+4*edx],eax    ;Save the Sample Offset

	mov edi,USMSOffset	; Get Sample Header Offset

	If FullLoad eq Yes		
	mov SId[edi],'LPMS'
	add edi,SName
	mov esi,STMSamplesTable
	mov ecx,14/4
	cld
	rep movsd
	mov edi,USMSOffset
	mov esi,STMSamplesTable
	endif	

        ;Convert STM Sample -> USM Sample
	
        movzx eax,STMSLength[esi]    ; Convert Length And Loop

        push eax
        MSetPos STMOffset 
        pop eax
        add STMOffset,eax
	
        mov SType[edi],0

        mov SLength[edi],eax
        movzx eax,STMSLoop[esi]
        mov SLoop[edi],eax
	
        movzx eax,STMSLoopEnd[esi]
        cmp eax,65535
        je NoLoop
        mov SType[edi],SM_Loop  
NoLoop:	

        mov SLoopEnd[edi],eax

        mov SVolume[edi],64     ;Sample Volume=64 (MAX)
        mov al,STMSVolume[esi]
        mov SDefVolume[edi],al
        mov al,80h
        mov SDefPanning[edi],al

        movzx eax,STMSFine[esi]
        mov SFine[edi],eax

        cmp SLength[edi],2
        jbe  NotLoadSample

        call LU_LoadSample      ; Load sample data.

        jmp LoadNextSample
NotLoadSample:
        mov SLength[edi],0
LoadNextSample:        

        ; ** Sample load end, load next sample **

        add STMSamplesTable,STMSampleSize
	
        inc SCount 	
        cmp SCount,31
        jne _LoadSamplesLoop

        sub STMSamplesTable,STMSampleSize*31

        ret
STM_LoadSamples Endp

CODE32 ENDS
;=============================================================================
end
; STMLOAD.ASM (c) 1997 FreddyV/Useless