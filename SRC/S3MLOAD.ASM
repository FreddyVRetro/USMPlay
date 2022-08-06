;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ     ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ S3MLOAD.ASM ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ           Useless S3M Loader (S3M->USM)           บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vtel (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 22/07/1997       บ
;            บ   Last update .................. 31/08/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

FullLoad Equ Yes        ; Yes => Load all (Players,trackers..)
                        ; No  => Load all needed for the module (Demos,games..)

INCLUDE ERR_CODE.INC
INCLUDE S3MLOAD.INC

INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC      ; Instruments and samples definition
INCLUDE USM.INC         ; Useless Module Structures Definition

INCLUDE MEMORY.INC

INCLUDE UTILS.INC       ; For the writeln macro.
INCLUDE LDEBUG.INC

;----------------------------------------------------------------------------

S3MH	DD 0
USMH	DD 0

S3MOffset   DD 0  ;Offset of the pointer tables in the file (Patt/Smp/Instr)
USMFlags    DW 0
S3MVersion  DW 0
S3MMono     DB 0

ChannelUsed DW 0 ; Real number of channels (found in patterns)

S3MPanningTable DB 32 DUP (0)

;----------------------------------------------------------------------------

PCount DW 0
PTotal DW 0

S3MPOffset   DD 0
USMPOffset  DD 0
USMPattSize DD 0

S3MPatternHeaderLen EQU 2

S3MPattPtr DW 200 DUP (0)

; S3M Pattern header

S3MPSize  DW 0

;----------------------------------------------------------------------------

ITotal  DW 0
ICount  DW 0

S3MIOffset DD 0

STotal  DW 0
SCount  DW 0

S3MSOffset DD 0
USMSOffset DD 0

S3MSmpPtr DW 100 DUP (0)

;=============================================================================

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  S3M_LOAD: Load/convert an S3M file. (S3M->USM)                         ณ
;ณ                                                                         ณ
;ณ Input: ESI file name/path                                               ณ
;ณ        EAX Default panning                                              ณ
;ณ        EBX=0 Load from a file                                           ณ
;ณ        EBX=1 Load from memory                                           ณ
;ณ                                                                         ณ
;ณ Output: CF Set=> Error                                                  ณ
;ณ         EAX returns the error number                                    ณ
;ณ                                                                         ณ
;ณ         CF Clear                                                        ณ
;ณ         ESI pointer to the USM module                                   ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
S3M_Load Proc
        mov LoadMode,bl
        
        MOpen ESI
        jc S3MLoadErr

        ; *** Load the S3M Header ***
        U_Calloc USMHeaderLen
        jc S3MLoadErr
        mov USMH,eax

        U_Malloc S3MHeaderLen
        mov S3MH,eax
        jc S3MLoadErr

        Mread eax,S3MHeaderLen   ;Read the S3M Header
        jc S3MLoadErr

        ; *** Convert S3M Header -> USM Header ***

        mov esi,S3MH
        mov edi,USMH

        cmp S3MId[esi],'MRCS'
        mov eax,LE_WrongFormat
        jne S3MLoadErr           ;Bad File Format.

        mov MTracker[edi],M_ST3
        mov MId[edi],'MLSU'
        mov MVersion[edi],USMVersion

        ; * Copy music title *
        
        mov ecx,28
        add esi,S3MName
        add edi,MName
        push ds
        pop es
        cld
        rep movsb               ;Copy the Module Name

        mov esi,S3MH
        mov edi,USMH

        push edi                ; !!!!!! A virer + tards !!!!!!
        add edi,MChPan
        mov ecx,Max_Channels/4
        mov eax,10303010h ;DefPann
        rep stosd
        pop edi                                
                                
                                ;Set Channel volume Table
        push edi
        add edi,MChVol
        mov ecx,Max_Channels
        mov al,64
        rep stosb
        pop edi

        movzx eax,S3MVer[esi]
        mov S3MVersion,ax       

; Detect number of channels
        
        mov eax,LE_WrongFormat
        mov ecx,32
GetChannelNumberLoop:
        cmp S3MChannels[esi+ecx-1],128
        jb ChNumberFound
        loop GetChannelNumberLoop
        jmp S3MLoadErr                   ;0 Channels -> Bad file format error
ChNumberFound:
        mov MChannels[edi],cx
        mov MUS_Channels,cx

; *** Traitement des flags ***

        mov ebx,F_BigGVolSlide+F_CutHighPitch+F_NoMRetrReset

        mov ax,S3MFlags[esi]
        test ax,S3MF_FastVS
        jz NoFastVS
        or bx,F_FastVS
NoFastVS:
        cmp S3Mcwt[esi],01300h
        jne NoOldS3M
        or bx,F_FastVS
NoOldS3M:        

        mov MFlags[edi],bx
        mov USMFlags,bx

        ; ** Period limits **

        mov MPeriodMin[edi],56              ; Minimum amiga period value  B-8
        mov MPeriodMax[edi],27392           ; Maximum amiga period value  C-0

        mov ax,S3MOrdNum[esi]
        mov MSongLen[edi],ax
        cmp ax,256
        mov eax,LE_WrongFormat
        jae S3MLoadErr

        mov ax,S3MPatNum[esi]
        mov MPatterns[edi],ax
        mov PTotal,ax           ;Save the Number of patterns

        mov MRestart[edi],0

        mov ax,S3MSmpNum[esi]
        mov MSamples[edi],ax
        mov STotal,ax

        mov al,S3MIS[esi]
        mov MTempo[edi],al

        mov al,S3MIT[esi]
        mov MBPM[edi],al

        mov al,S3MGV[esi]
        shl al,1
        mov MGVolume[edi],al
        
; Compute order section Length and Load order table
        movzx eax,S3MOrdNum[esi]

        push edi
        add edi,MOrder          ;Load the Order table in the
        MRead edi,eax           ;USM Header.
        pop edi

        cmp MSongLen[edi],0
        je NoUpdateOrderList

; ** Remove the 254 and 255 codes in order list **
        xor ecx,ecx
ChangeOrderLoop:
        movzx eax,MOrder[edi+ecx]
        cmp MOrder[edi+ecx],254
        jne No254
        mov edx,ecx
ReduceOrderLoop:        
        mov al,MOrder[edi+edx+1]
        mov MOrder[edi+edx],al
        inc edx
        cmp dx,MSongLen[edi]
        jb  ReduceOrderLoop
        dec MSongLen[edi]
        dec ecx
        jmp No255
No254:        
        cmp MOrder[edi+ecx],255
        jne No255
        mov MSongLen[edi],cx
No255:        
        inc ecx
        cmp cx,MSongLen[edi]
        jb  ChangeOrderLoop

NoUpdateOrderList:

        mov eax,MUS_Offset      ;Save current File Offset
        mov S3MOffset,eax

; Panning

        mov S3MMono,0
        mov al,S3MMV[esi]
        test al,128                     ; Test if MONO
        jnz S3MStereo
        mov S3MMono,1

        push edi                        ; Set panning to Mono
        add edi,MChPan
        mov ecx,Max_Channels/4
        mov eax,20202020h ;DefPann
        rep stosd
        pop edi          

        jmp S3MPanningEnd
S3MStereo:        


        mov ecx,0                      ; Set default panning
GetDefPanLoop:
        mov al,S3MChannels[esi+ecx]
        cmp al,7
        mov bl,30h
        ja SetToRight
        mov bl,10h
SetToRight:
        mov MChPan[edi+ecx],bl
        inc ecx
        cmp ecx,32
        jne GetDefPanLoop

        cmp S3MPantable[esi],252        ; Read the panning table ?
        jne NoReadPanningTable


        mov eax,S3MOffset
        movzx ebx,PTotal
        shl ebx,1
        add eax,ebx
        movzx ebx,STotal
        shl ebx,1
        add eax,ebx                     ; Panning table Offset

        MSetPos eax

        mov eax,Offset S3MPanningTable
        MRead eax,32

        xor ecx,ecx
ConvertPanningLoop:        
        movzx eax,S3MPanningTable[ecx]

        test al,32
        jz NoSetDefPanning

        and al,01111b
        shl al,2
        mov MChPan[edi+ecx],al
NoSetDefPanning:

        inc ecx
        cmp ecx,32
        jne ConvertPanningLoop

NoReadPanningTable:        

S3MPanningEnd:

        U_Free S3MH

        call S3M_LoadInstruments
        jc S3MLoadErr

        call S3M_LoadPatterns
        jc S3MLoadErr

        mov esi,USMH            ;Returns a pointer to the Module...

        movzx eax,ChannelUsed
        cmp ax,MUS_Channels
        jae NoMChannelsChange
        inc ax
        mov MChannels[edi],ax
NoMChannelsChange:

        jmp S3MLoadEnd	

S3MLoadErr:

        push eax
        MCLose                  ;Close the file
        pop eax

if _WATCOM
        mov _Error_Number,eax   ;Returns Error number.
        xor eax,eax
        ret
else
        stc
        ret
endif

S3MLoadEnd:
        MClose          ;Close the file
        clc
        ret
S3M_Load Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  S3M_Loadpatterns: Load/convert S3M patterns. (S3M->USM)                   ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Row     DB 0
Channel DB 0

Inst     DB 0
Note     DB 0
Vol      DB 0
Cmd      DB 0
Param    DB 0

;Warning: PTotal must be >0

S3M_LoadPatterns Proc Near

        mov ChannelUsed,0

; Read the patterns file pointers
        MSetPos S3MOffset

        movzx ecx,PTotal

        mov eax,LE_WrongFormat
        cmp ecx,200
        ja S3MPatternError
        
        shl ecx,1
        add S3MOffset,ecx

        mov eax,Offset S3MPattPtr
        MRead eax,ecx

;call debug

        mov PCount,0
_LoadPatternsLoop:

        movzx ebx,PCount
        movzx eax,S3MPattPtr[2*ebx]  ;Read the pattern header file offset

        cmp eax,0
        je S3MPatternEmpty

        shl eax,4
        MSetPos eax                      ;Set file pointer to sample

        mov eax,Offset S3MPSize
        Mread eax,S3MPatternHeaderLen    ;Load the pattern header

        cmp S3MPSize,0                   ;S3M Pattern Empty ?
        je S3MPAtternEmpty

; Allocate USM pattern memory

        mov eax,64
        mov bx,MUS_Channels
        mul bx
        mov bx,NoteSize
        mul bx                  ;rows*Channels*5 => Pattern date size        

        add eax,USMPatternSize
        mov USMPattSize,eax     ;Total pattern size
        U_Calloc eax            ;Allocate USM Pattern Memory
        mov USMPOffset,eax

        movzx eax,S3MPSize
        U_Malloc eax            ;Allocate memory to load the S3M pattern
        mov S3MPOffset,eax       
        

        movzx ecx,S3MPSize
        MRead eax,ecx           ;Load the S3M pattern data

        ; Convert the pattern XM->USM

        mov esi,S3MPOffset
        mov edi,USMPOffset

        mov PId[edi],'PLSU'
        mov eax,USMPattSize
        mov Psize[edi],eax
        mov ax,PCount
        mov Pnumber[edi],ax
        mov Prow[edi],64

        add edi,USMPatternSize

; ** Unpack Pattern **

        mov Row,0
        mov Channel,0

        mov Inst,0
        mov Note,250
        mov Vol,255
        mov Cmd,0
        mov Param,0

        push ebp
UnpackS3MPatternLoop:

; ** ChannelVariable **
        mov al,[esi]
        inc esi
        mov bl,al               ;Save channel mask
        
        cmp al,0                ;ChannelVariable=0 -> Next row
        je UnpackNextRow
        
        and al,31
        mov Channel,al          ;Channel=ChannelVariable AND 31
        movzx eax,al
        mov ebp,eax

        mov Inst,0
        mov Note,255            ;255 -> No Note
        mov Vol,255             ;255 -> No Volume
        mov Cmd,0
        mov Param,0

        mov al,bl               ;Restore channel mask
        shr al,6
        jnc NoNoteInstr
        mov bl,[esi]
        inc esi
        mov Note,bl
        mov bl,[esi]
        inc esi
        mov Inst,bl
NoNoteInstr:
        shr al,1
        jnc NoVolume
        mov bl,[esi]
        inc esi
        mov Vol,bl
NoVolume:        
        shr al,1
        jnc NoCommand
        mov bl,[esi]
        inc esi
        mov Cmd,bl
        mov bl,[esi]
        inc esi
        mov Param,bl
NoCommand:

        call ConvertNote
        call ConvertVolume
        call ConvertCmd

Write_Channel_Data:

        movzx eax,Channel
        cmp ax,MUS_Channels
        jae UnpackS3MPatternLoop

        mov ebx,NoteSize
        mul ebx
        mov ecx,eax

        movzx eax,Row
        mov ebx,NoteSize
        mul ebx
        movzx ebx,MUS_Channels
        mul ebx

        add ecx,eax
        mov al,Note        
        mov [edi+ecx],al
        mov al,Inst
        mov [edi+ecx+1],al
        mov al,Vol
        mov [edi+ecx+2],al
        mov al,Cmd
        mov [edi+ecx+3],al
        mov al,Param
        mov [edi+ecx+4],al

        jmp UnpackS3MPatternLoop

UnpackNextRow:
        inc Row
        movzx eax,Row
        cmp ax,64
        jne UnpackS3MPatternLoop
        pop ebp
        
; ** S3M Pattern Unpack End **
        
        U_Free S3MPOffset        ;Free the S3M pattern data

; ** Pack the USM pattern **

        mov esi,USMPOffset
        call LU_PackPattern

        cmp ax,ChannelUsed
        jbe NoChangeChannelUsed
        mov ChannelUsed,ax
NoChangeChannelUsed:

        mov edi,USMH                 ;Useless Module header Offset
        movzx edx,PCount             ;Get the pattern number
        mov MPattPtr[edi+4*edx],esi  ;Save the Pattern Offset
        
S3MPatternEmpty:
        inc PCount
        mov ax,PTotal
        cmp PCount,ax
        jne _LoadPatternsLoop	; Pattern Loop

        clc
        ret

S3MPatternError:
        stc
        ret
S3M_LoadPatterns Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  S3M_LoadInstruments: Load/convert S3M instruments. (S3M->USM)             ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

S3M_LoadInstruments Proc Near

; ** Samples Load

        cmp STotal,0
        je NoSamples        

; Read the samples file pointers
        MSetPos S3MOffset

        movzx ecx,STotal

        mov eax,LE_WrongFormat
        cmp ecx,100
        jae S3M_LoadInstrumentsErr

        shl ecx,1
        add S3MOffset,ecx

        mov eax,Offset S3MSmpPtr
        MRead eax,ecx
        
        mov SCount,0
_LoadSamplesLoop:        

        movzx ebx,SCount
        movzx eax,S3MSmpPtr[2*ebx]       ;Read the sample header file offset

        cmp eax,0
        je _LoadSampleLoopEnd

        shl eax,4
        MSetPos eax                      ;Set file pointer to sample

        U_Malloc S3MSampleSize
        jc S3M_LoadInstrumentsErr
        mov S3MSOffset,eax

        MRead eax,S3MSampleSize          ;Read the S3M sample header

        mov esi,S3MSOffset
        cmp S3MSId[esi],'SRCS'           ;Is S3M Sample ID correct ?
        je S3MSIdOk
        jmp NoLoadSample
S3MSIdOk:        

        U_Calloc USSSampleSize
        mov USMSOffset,eax

        mov esi,USMH
        movzx ebx,SCount
        mov MSamplPtr[esi+4*ebx],eax    ;Write the sample header offset

        mov esi,S3MSOffset
        mov edi,USMSOffset
        
        mov SId[edi],'LPMS'
        add edi,SName
        add esi,S3MSName
        mov ecx,26
        cld
        rep movsb
        mov esi,S3MSOffset
        mov edi,USMSOffset

        mov eax,S3MSLength[esi]          ; Convert Length and Loop
        mov SLength[edi],eax
        mov eax,S3MSLoop[esi]
        mov SLoop[edi],eax
        mov eax,S3MSLoopEnd[esi]
        mov SLoopEnd[edi],eax

        mov SVolume[edi],64     ; Sample Volume=64 (MAX)
        mov al,S3MSVol[esi]
        mov SDefVolume[edi],al

        mov eax,S3MSFine[esi]   ; ! Test if >65535 !
        mov SFine[edi],eax

        xor bl,bl               ; Convert sample type ( 8/16bit, loop... )
        mov al,S3MSFlg[esi]
        test al,S3MSM_16Bit
        jz _S3MS8Bit
        or  bl,SM_16bit         ; Set 16 bit sample
        shl SLoop[edi],1
        shl SLoopEnd[edi],1
        shl SLength[edi],1
_S3MS8bit:
        test al,S3MSM_Stereo
        jz _S3MSMono
        or bl,SM_Stereo         ; Set stereo sample
_S3MSMono:        
        test al,S3MSM_Loop
        je _S3MSNoLoop
        or  bl,SM_Loop          ; Set sample Loop
_S3MSNoLoop:
        mov SType[edi],bl

; !! sign/non sign ! ???????

        xor bl,bl
        cmp S3MVersion,2
        jb  _S3MSSigned         ; S3M version 1 -> Signed samples
        or bl,SF_Unsigned
_S3MSSigned:        
        mov SFlag[edi],bl

        cmp SLength[edi],0
        je  NoLoadSample

        movzx eax,S3MSPointer[esi]
        shl eax,4
        MSetPos eax

        call LU_LoadSample     ; Load sample data.

NoLoadSample:

        U_Free S3MSOffset

_LoadSampleLoopEnd:

        inc SCount
        mov ax,Stotal
        cmp SCount,ax
        jne _LoadSamplesLoop
NoSamples:

        clc
        ret

S3M_LoadInstrumentsErr:
        stc
        ret
S3M_LoadInstruments Endp

;ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
;ณ  ConvertVolume: Convert S3M volume to USM volume.                       ณ
;ณ                                                                         ณ
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

WaveFormTable DB 0,2,1,3

ConvertNote Proc

        cmp Note,254
        jae NoteCmd
        mov al,Note
        shr al,4
        inc al
        mov cl,12
        mul cl
        mov bl,Note
        and bl,0Fh
        add al,bl
        inc al
        mov note,al
        jmp ConvertNoteEnd
NoteCmd:
        cmp Note,255
        jne No_NoNote
        mov Note,0              ; No Note
        jmp ConvertNoteEnd
No_NoNote:        
        cmp Note,254
        jne No_NoteCut
        mov Note,Note_Cut       ; Note cut
        jmp ConvertNoteEnd
No_NoteCut:
ConvertNoteEnd:
        ret
ConvertNote Endp

ConvertVolume Proc

        cmp Vol,64
        ja  NoVol
        add Vol,10h
        ret
NoVol:
        mov Vol,0

        ret
ConvertVolume Endp

ConvertCmd Proc
        cmp Cmd,22
        ja NoCmd

        movzx eax,Cmd
        call CommConverter[4*eax]
        
        ret
ConvertCmd Endp

NoCmd Proc
        mov Cmd,0
        mov Param,0
        ret
NoCmd Endp

DirectConv Proc
        mov al,CommNumber[eax]
        mov Cmd,al
        ret
DirectConv Endp

ConvSetGVolume Proc
        shl Param,1
        mov Cmd,_GVolume        
        ret
ConvSetGVolume Endp

ConvSpecial Proc
        movzx eax,Param
        mov Param,0
        mov Cmd,0
        cmp al,30h
        jae NoNothing
        ret
NoNothing:
        cmp al,40h                      ; 3x                    -
        jae NoSetVibWave
        and al,3
        mov al,WaveFormTable[eax]
        mov Param,al
        mov Cmd,_VibType
        ret
NoSetVibWave:        
        cmp al,50h                      ; 4x                    -
        jae NoSetTremoloWave
        and al,3
        mov al,WaveFormTable[eax]
        mov Param,al
        mov Cmd,_TremType
        ret
NoSetTremoloWave:
        cmp al,80h                      ; Nothing
        jae NoNothing1
        mov Param,0
        mov Cmd,0
        ret
NoNothing1:
        cmp al,90h                      ; 8x Set Panning        o
        jae NoSetPanning
        and al,0Fh
        mov Param,al
        mov Cmd,_SetPanning2
        ret        
NoSetPanning:        
        cmp al,0B0h
        jae NoNothing2
        ret
NoNothing2:
        cmp al,0C0h                     ; Bx Pattern Loop       o
        jae NoPatternLoop
        and al,0Fh
        mov Param,al
        mov Cmd,_PatLoop
        ret
NoPatternLoop:        
        cmp al,0D0h                     ; Cx Note Cut           o
        jae NoNoteCut
        and al,0Fh
        mov Param,al
        mov Cmd,_CutNote
        ret
NoNoteCut:
        cmp al,0E0h                     ; Dx Note Delay         o
        jae NoNoteDelay
        and al,0Fh
        mov Param,al
        mov Cmd,_NoteDelay
        ret
NoNoteDelay:
        cmp al,0F0h                     ; Ex Pattern Delay      -
        jae NoPatternDelay
        and al,0Fh
        mov Param,0Fh
        mov Cmd,_PatternDelay
        ret
NoPatternDelay:        
        ret
ConvSpecial Endp

CommNumber Label byte
 DB 0            ; 0
 DB _SetTempo    ; 1 -Axx Set Speed                             o
 DB _Jump        ; 2 -Bxx Jump to order                         o
 DB _Break       ; 3 -Cxx Break to row                          o
 DB _ITVolSlide  ; 4 -Dxx Volume slide  (Up/Down/Fine)          o
 DB _ITPitchDn   ; 5 -Exx Pitch slide/fine slide Down (1)       -
 DB _ITPitchUp   ; 6 -Fxx Pitch slide/fine slide Up   (1)       -
 DB _ITPortaNote ; 7 -Gxx Portamento to note          (1)       -
 DB _Vibrato     ; 8 -Hxy Vibrato                               o
 DB _Tremor      ; 9 -Ixy Tremor                                -
 DB _Arpeggio    ; 10-Jxy Arpeggio                              -
 DB _ITVibVS     ; 11-Kxx Vibrato+Volume slide                  o
 DB _ITPortVS    ; 12-Lxx Portamento+Volume slide               -
 DB 0            ; 13-Mxx
 DB 0            ; 14-Nxx
 DB _SetOffset   ; 15-Oxx Set sample offset
 DB 0            ; 16-Pxx
 DB _ITMRetrig   ; 17-Qxy Multi retrig                          -
 DB _Tremolo     ; 18-Rxy Tremolo                               -
 DB 0            ; 19-Sxx "Special commands"                    -
 DB _ITSetBPM    ; 20-Txx Set Tempo/Tempo slide                 o
 DB _FineVibrato ; 21-Uxy Fine vibrato                          o
 DB 0            ; 22-Vxx Set global volume                     -
 
CommConverter Label dword
 DD NoCmd             ; 0
 DD DirectConv        ; 1 -Axx Set Speed                        o
 DD DirectConv        ; 2 -Bxx Jump to order                    o
 DD DirectConv        ; 3 -Cxx Break to row                     o
 DD DirectConv        ; 4 -Dxx Volume slide (Up/Down/Fine)      o
 DD DirectConv        ; 5 -Exx Pitch slide Down     (1)         -
 DD DirectConv        ; 6 -Fxx Pitch slide Up       (1)         -
 DD DirectConv        ; 7 -Gxx Portamento to note   (1)         -
 DD DirectConv        ; 8 -Hxy Vibrato                          -
 DD DirectConv        ; 9 -Ixy Tremor                           -
 DD DirectConv        ; 10-Jxy Arpeggio                         -
 DD DirectConv        ; 11-Kxx Vibrato+Volume slide             o
 DD DirectConv        ; 12-Lxx Portamento+Volume slide          -
 DD NoCmd             ; 13-Mxx
 DD NoCmd             ; 14-Nxx
 DD DirectConv        ; 15-Oxx Set sample offset
 DD NoCmd             ; 16-Pxx
 DD DirectConv        ; 17-Qxy Multi retrig                     -
 DD DirectConv        ; 18-Rxy Tremolo                          -
 DD ConvSpecial       ; 19-Sxx "Special commands"               -
 DD DirectConv        ; 20-Txx Set Tempo/Tempo slide            o
 DD DirectConv        ; 21-Uxy Fine vibrato                     -
 DD ConvSetGVolume    ; 22-Vxx Set global volume                -

; (1) Use shared memory
 
CODE32 ENDS
;=============================================================================
end
; S3MLOAD.ASM (c) 1997 FreddyV/Useless