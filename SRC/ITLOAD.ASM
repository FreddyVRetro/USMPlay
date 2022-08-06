;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ ITLOAD.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷      º
;            º                                                   º
;            º            Useless IT Loader (IT->USM)            º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 01/05/1997       º
;            º   Last update .................. 06/10/1997       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

FullLoad Equ Yes        ; Yes => Load all (Players,trackers..)
                        ; No  => Load all needed for the module (Demos,games..)

INCLUDE ERR_CODE.INC
INCLUDE ITLOAD.INC

INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC      ; Instruments and samples definition
INCLUDE USM.INC         ; Useless Module Structures Definition

INCLUDE MEMORY.INC

INCLUDE UTILS.INC       ; For the writeln macro.
INCLUDE LDEBUG.INC

;----------------------------------------------------------------------------

ITH	DD 0
USMH	DD 0

ITOffset   DD 0  ;Offset of the pointer tables in the file (Patt/Smp/Instr)
ITFlg      DW 0
USMFlags   DW 0
ITVersion  DW 0

SampleTable DD 0

ChannelUsed DW 0 ; Real number of channels (found in patterns)

;----------------------------------------------------------------------------

PCount DW 0
PTotal DW 0

ITPOffset   DD 0
USMPOffset  DD 0
USMPattSize DD 0

ITPatternHeaderLen EQU 8

; IT Pattern Header
ITPSize  DW 0
ITPRows  DW 0
ITPFill1 DD 0

;----------------------------------------------------------------------------

ITotal  DW 0
ICount  DW 0

ITIOffset DD 0
USMIOffset DD 0

STotal  DW 0
SCount  DW 0

ITSOffset  DD 0
USMSOffset DD 0


ITLinAdj DW -789,-784,-779,-773,-768,-763,-757,-752,-747,-742,-737
         DW -731,-726,-721,-716,-711,-706,-701,-696,-691,-686,-681
         DW -676,-671,-667,-662,-657,-652,-647,-643,-638,-633,-629
         DW -624,-619,-615,-610,-605,-601,-596,-592,-587,-583,-578
         DW -574,-569,-565,-561,-556,-552,-547,-543,-539,-535,-530
         DW -526,-522,-517,-513,-509,-505,-501,-497,-492,-488,-484
         DW -480,-476,-472,-468,-464,-460,-456,-452,-448,-444,-440
         DW -436,-432,-428,-424,-420,-417,-413,-409,-405,-401,-397
         DW -394,-390,-386,-382,-379,-375,-371,-367,-364,-360,-356
         DW -353,-349,-345,-342,-338,-335,-331,-328,-324,-320,-317
         DW -313,-310,-306,-303,-299,-296,-292,-289,-286,-282,-279
         DW -275,-272,-269,-265,-262,-258,-255,-252,-248,-245,-242
         DW -239,-235,-232,-229,-225,-222,-219,-216,-213,-209,-206
         DW -203,-200,-197,-193,-190,-187,-184,-181,-178,-175,-172
         DW -168,-165,-162,-159,-156,-153,-150,-147,-144,-141,-138
         DW -135,-132,-129,-126,-123,-120,-117,-114,-111,-108,-106
         DW -103,-100,-97,-94,-91,-88,-85,-82,-80,-77,-74,-71,-68
         DW -65,-63,-60,-57,-54,-51,-49,-46,-43,-40,-38,-35,-32,-29
         DW -27,-24,-21,-19,-16,-13,-11,-8,-5,-3,0,2,4,7,10,12,15,18
         DW 20,23,25,28,30,33,36,38,41,43,46,48,51,53,56,58,61,63,66
         DW 68,71,73,76,78,81,83,86,88,91,93,96,98,100,103,105,108
         DW 110,112,115,117,120,122,124,127,129,131,134,136,138,141
         DW 143,145,148,150,152,155,157,159,162,164,166,168,171,173
         DW 175,177,180,182,184,186,189,191,193,195,198,200,202,204
         DW 206,209,211,213,215,217,220,222,224,226,228,230,232,235
         DW 237,239,241,243,245,247,250,252,254,256,258,260,262,264
         DW 266,268,270,273,275,277,279,281,283,285,287,289,291,293
         DW 295,297,299,301,303,305,307,309,311,313,315,317,319,321
         DW 323,325,327,329,331,333,335,337,339,341,343,345,347,349
         DW 350,352,354,356,358,360,362,364,366,368,370,372,373,375
         DW 377,379,381,383,385,387,388,390,392,394,396,398,400,401
         DW 403,405,407,409,411,412,414,416,418,420,422,423,425,427
         DW 429,431,432,434,436,438,439,441,443,445,447,448,450,452
         DW 454,455,457,459,461,462,464,466,468,469,471,473,475,476
         DW 478,480,481,483,485,487,488,490,492,493,495,497,498,500
         DW 502,504,505,507,509,510,512,514,515,517,519,520,522,524
         DW 525,527,528,530,532,533,535,537,538,540,542,543,545,546
         DW 548,550,551,553,554,556,558,559,561,562,564,566,567,569
         DW 570,572,574,575,577,578,580,581,583,585,586,588,589,591
         DW 592,594,595,597,599,600,602,603,605,606,608,609,611,612
         DW 614,615,617,618,620,621,623,624,626,627,629,630,632,633
         DW 635,636,638,639,641,642,644,645,647,648,650,651,653,654
         DW 656,657,659,660,661,663,664,666,667,669,670,672,673,675
         DW 676,677,679,680,682,683,685,686,687,689,690,692,693,695
         DW 696,697,699,700,702,703,704,706,707,709,710,711,713,714
         DW 716,717,718,720,721,722,724,725,727,728,729,731,732,733
         DW 735,736,738,739,740,742,743,744,746,747,748,750,751,752
         DW 754,755,756,758,759,760,762,763,764,766,767,768,770,771

;=============================================================================

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  IT_LOAD: Load/convert an IT file. (IT->USM)                            ³
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
IT_Load Proc
        mov LoadMode,bl
        
        MOpen ESI
        jc ITLoadErr

        ; *** Load the IT Header ***
        U_Calloc USMHeaderLen
        jc ITLoadErr
        mov USMH,eax

        U_Malloc ITHeaderLen
        mov ITH,eax
        jc ITLoadErr

        Mread eax,ITHeaderLen   ;Read the IT Header
        jc ITLoadErr

        ; *** Convert IT Header -> USM Header ***

        mov esi,ITH
        mov edi,USMH

        mov eax,edi
        add eax,MSamplPtr
        mov SampleTable,eax

        cmp ITId[esi],'MPMI'
        mov eax,LE_WrongFormat
        jne ITLoadErr           ;Bad File Format.

        mov MTracker[edi],M_IT
        mov MId[edi],'MLSU'
        mov MVersion[edi],USMVersion

        ; * Copy music title *
        
        mov ecx,26
        add esi,ITName
        add edi,MName
        push ds
        pop es
        cld
        rep movsb               ;Copy the Module Name

        mov esi,ITH
        mov edi,USMH
        mov ax,ITCmwt[esi]
        mov ITVersion,ax       

                                ;Copy Panning Table
        mov ecx,64
        add edi,MChPan
        add esi,ITChPan
        push ds
        pop es
        cld
        rep movsb

        mov esi,ITH
        mov edi,USMH
                                ;Copy Volume Table
        mov ecx,64
        add edi,MChVol
        add esi,ITChVol
        push ds
        pop es
        cld
        rep movsb

        mov esi,ITH
        mov edi,USMH

        mov eax,LE_WrongFormat
        mov ecx,64
GetChannelNumberLoop:
        cmp ITChPan[esi+ecx-1],128
        jb ChNumberFound
        loop GetChannelNumberLoop
        jmp ITLoadErr                   ;0 Channels -> Bad file format error
ChNumberFound:
        mov MChannels[edi],cx
        mov MUS_Channels,cx


; *** Traitement des flags ***

        mov ebx,F_CutHighPitch+F_NoMRetrReset
        mov ax,ITFlags[esi]
        mov ITFlg,ax
        test ax,ITF_InstrMode
        jz NoInstrMode
        or bx,F_InstrMode
NoInstrMode:        
        test ax,ITF_Linear
        jz NoLinear
        or bx,F_Linear
NoLinear:        
        test ax,ITF_OldEfx
        jnz NoNewEfx
        or bx,F_FineVibrato
NoNewEfx:

        mov MFlags[edi],bx
        mov USMFlags,bx

        ; ** Period limits **

        Test USMFlags,F_Linear
        jnz UseLinearLimits
        mov MPeriodMin[edi],28              ; Minimum amiga period value  B-8
        mov MPeriodMax[edi],27392           ; Maximum amiga period value  C--1
        jmp AmigaLimitUsed
UseLinearLimits:        
        mov MPeriodMin[edi],768             ; Minimum linear period value B-8
        mov MPeriodMax[edi],768*11          ; Maximum linear period value C--1
AmigaLimitUsed:

        mov ax,ITOrdNum[esi]
        mov MSongLen[edi],ax
        cmp ax,256
        mov eax,LE_WrongFormat
        jae ITLoadErr

        mov ax,ITPatNum[esi]
        mov MPatterns[edi],ax
        mov PTotal,ax           ;Save the Number of patterns

;        mov ax,ITRestart[esi]
        mov MRestart[edi],0

        mov ax,ITSmpNum[esi]
        mov MSamples[edi],ax
        mov STotal,ax

        mov ax,ITInsNum[esi]
        mov MInstruments[edi],ax
        mov ITotal,ax           ;Save the number of instruments

        mov al,ITIS[esi]
        mov MTempo[edi],al

        mov al,ITIT[esi]
        mov MBPM[edi],al

        mov al,ITGV[esi]
        mov MGVolume[edi],al
        
        mov al,ITSep[esi]
        mov MSep[edi],al

; Compute order section Length and Load order table
        movzx eax,ITOrdNum[esi]

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
        mov ITOffset,eax

        U_Free ITH

        call IT_LoadInstruments
        jc ITLoadErr

        call IT_LoadPatterns
        jc ITLoadErr

        mov esi,USMH            ;Returns a pointer to the Module...

        movzx eax,ChannelUsed
        cmp ax,MUS_Channels
        jae NoMChannelsChange
        inc ax
        mov MChannels[edi],ax
NoMChannelsChange:

        jmp ITLoadEnd	

ITLoadErr:

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

ITLoadEnd:
        MClose          ;Close the file
        clc
        ret
IT_Load Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  IT_Loadpatterns: Load/convert IT patterns. (IT->USM)                   ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Row     DB 0
Channel DB 0

OldMaskVariable DB 64 DUP (0)

Inst     DB 0
OldInst  DB 64 DUP (0)
Note     DB 0
OldNote  DB 64 DUP (0)
Vol      DB 0
OldVol   DB 64 DUP (0)
Cmd      DB 0
OldCmd   DB 64 DUP (0)
Param    DB 0
OldParam DB 64 DUP (0)

;Warning: PTotal must be >0

IT_LoadPatterns Proc Near

        mov ChannelUsed,0

; Read the patterns file pointers
        MSetPos ITOffset

        movzx eax,PTotal
        shl eax,2
        add ITOffset,eax

        mov esi,USMH
        add esi,MPattPtr

        MRead esi,eax

        mov PCount,0
_LoadPatternsLoop:

        mov esi,USMH
        movzx ebx,PCount
        mov eax,MPattPtr[esi+4*ebx]     ;Read the pattern header file offset
        mov MPattPtr[esi+4*ebx],0

        cmp eax,0
        je ITPatternEmpty

        MSetPos eax                     ;Set file pointer to sample

        mov eax,Offset ITPSize
        Mread eax,ITPatternHeaderLen    ;Load the pattern header

        cmp ITPSize,0                   ;IT Pattern Empty ?
        je ITPAtternEmpty

        mov eax,LE_PatternError         ;Number of rows is correct ?
        cmp ITProws,200
        ja ITPatternError
        cmp ITProws,32
        jb ITPatternError

; Allocate USM pattern memory

        movzx eax,ITProws
        mov bx,MUS_Channels
        mul bx
        mov bx,NoteSize
        mul bx                  ;rows*Channels*5 => Pattern date size        

        add eax,USMPatternSize
        mov USMPattSize,eax     ;Total pattern size
        U_Calloc eax            ;Allocate USM Pattern Memory
        mov USMPOffset,eax

        movzx eax,ITPSize
        U_Malloc eax            ;Allocate memory to load the IT pattern
        mov ITPOffset,eax       
        

        movzx ecx,ITPSize
        MRead eax,ecx           ;Load the IT pattern data

;        pushad
;        mov esi,ITPOffset
;        mov ecx,4
;        call print_Str
;        waitkey
;        popad

        ; Convert the pattern XM->USM

        mov esi,ITPOffset
        mov edi,USMPOffset

        mov PId[edi],'PLSU'
        mov eax,USMPattSize
        mov Psize[edi],eax
        mov ax,PCount
        mov Pnumber[edi],ax
        mov ax,ITProws
        mov Prow[edi],ax

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
UnpackITPatternLoop:

; ** ChannelVariable **
        mov al,[esi]
        inc esi
        mov bl,al
        
        cmp al,0                ;ChannelVariable=0 -> Next row
        je UnpackNextRow
        
        dec al
        and al,00111111b        
        mov Channel,al          ;Channel=ChannelVariable AND 63
        movzx eax,al
        mov ebp,eax

        mov Inst,0
        mov Note,250            ;250 -> No Note
        mov Vol,255
        mov Cmd,0
        mov Param,0

        cmp bl,128              ;Use Old or New Mask variable ?
        jae UseNewMask
        mov al,OldMaskVariable[ebp]
        jmp UseOldMask
        
UseNewMask:

; ** maskvariable **
        mov al,[esi]
        inc esi
        mov OldMaskVariable[ebp],al

UseOldMask:

        push eax
        shr al,5
        jnc UseOldNote
        mov bl,OldNote[ebp]
        mov Note,bl
UseOldNote:
        shr al,1
        jnc UseOldInst
        mov bl,OldInst[ebp]
        mov Inst,bl
UseOldInst:
        shr al,1
        jnc UseOldVolume
        mov bl,OldVol[ebp]
        mov Vol,bl
UseOldVolume:
        shr al,1
        jnc UseOldCmd
        mov bl,OldCmd[ebp]
        mov Cmd,bl
        mov bl,OldParam[ebp]
        mov Param,bl
UseOldCmd:
        pop eax


        shr al,1
        jnc NoNote
        mov bl,[esi]
        inc esi
        mov Note,bl
        mov OldNote[ebp],bl
NoNote:
        shr al,1
        jnc NoInstrument
        mov bl,[esi]
        inc esi
        mov Inst,bl
        mov OldInst[ebp],bl
NoInstrument:        
        shr al,1
        jnc NoVolume
        mov bl,[esi]
        inc esi
        mov Vol,bl
        mov Oldvol[ebp],bl
NoVolume:        
        shr al,1
        jnc NoCommand
        mov bl,[esi]
        inc esi
        mov Cmd,bl
        mov Oldcmd[ebp],bl
        mov bl,[esi]
        inc esi
        mov Param,bl
        mov Oldparam[ebp],bl
NoCommand:

;pushad
;cmp Vol,255
;je NoPrintVol
;movzx eax,Vol
;call print_dec
;NoPrintvol:
;popad

        call ConvertNote
        call ConvertVolume
        call ConvertCmd

;pushad
;cmp Vol,0
;je NoPrintVol2
;write '-'
;movzx eax,Vol
;call print_dec
;write ' '
;waitkey
;NoPrintVol2:
;popad

Write_Channel_Data:

        movzx eax,Channel
        cmp ax,MUS_Channels
        jae UnpackITPatternLoop

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

        jmp UnpackITPatternLoop

UnpackNextRow:
        inc Row
        movzx eax,Row
        cmp ax,ITPRows
        jne UnpackITPatternLoop
        pop ebp
        
; ** IT Pattern Unpack End **
        
        U_Free ITPOffset        ;Free the IT pattern data

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
        
ITPatternEmpty:
        
        inc PCount
        mov ax,PTotal
        cmp PCount,ax
        jne _LoadPatternsLoop	; Pattern Loop

        clc
        ret

ITPatternError:
        stc
        ret
IT_LoadPatterns Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  IT_LoadInstruments: Load/convert IT instruments. (IT->USM)             ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

IT_LoadInstruments Proc Near

; ** Instruments Load

        cmp ITotal,0
        je NoInstruments

; Read the instruments file Pointers
        MSetPos ITOffset

        movzx eax,ITotal
        shl eax,2
        add ITOffset,eax

        mov esi,USMH
        add esi,MInstrPtr

        MRead esi,eax

        mov ICount,0
_LoadInstrLoop:

        mov esi,USMH
        movzx ebx,ICount
        mov eax,MInstrPtr[esi+4*ebx]    ;Read the sample header file offset
        mov MInstrPtr[esi+4*ebx],0

        cmp eax,0
        je _LoadInstrumentLoopEnd

        MSetPos eax                     ;Set file pointer to instrument start

        U_Malloc ITInstrumentSize
        jc IT_LoadInstrumentsErr
        mov ITIOffset,eax

        MRead eax,ITInstrumentSize      ;Read the IT sample header

        mov esi,ITIOffset

        cmp ITI1Id[esi],'IPMI'
        jne NoLoadInstrument

        U_Calloc USSInstrSize
        mov USMIOffset,eax

        mov esi,USMH
        movzx ebx,ICount
        mov MInstrPtr[esi+4*ebx],eax    ;Write the instrument header offset

        mov esi,ITIOffset
        mov edi,USMIOffset

        mov IFlg[edi],IF_IT
        mov eax,SampleTable
        mov ISTable[edi],eax            ;Pointer to sample offset table
                
        mov IId[edi],'TSNI'
        add edi,IName
        add esi,ITI1Name
        mov ecx,26
        cld
        rep movsb

        mov esi,ITIOffset
        mov edi,USMIOffset

        xor ecx,ecx
DoSNumberTableLoop:
        mov al,ITI1NoteTbl[esi+2*ecx]           ; Get Note number
        mov INote[edi+ecx],al
        mov al,ITI1NoteTbl[esi+2*ecx+1]         ; Get sample number
        mov ISNumber[edi+ecx],al
        inc ecx
        cmp ecx,120
        jne DoSNumberTableLoop

        cmp ITVersion,200h
        jae UseNewITInstrument

        mov IGVolume[edi],128

        movzx eax,ITI2FadeOut[esi]
        shl ax,6
        mov IVFadeout[edi],ax
        or IFlg[edi],IF_ReleaseFade

        mov al,ITI2NNA[esi]
        mov INNA[edi],al
        or al,al
        jz NoNNA2
        push esi
        mov esi,USMH
        or MFlags[esi],F_UseNNA
        pop esi
NoNNA2:

; ***** Volume envelope ****

        mov al,ITI2Flag[esi]
        mov IVType[edi],al

        test IVType[edi],E_On
        jz DoFadeoutOld                ; Do fadeout if there is no volume env
        test IVType[edi],EIT_Loop
        jnz DoFadeoutOld               ; No fadeout if there is no loop
        and IFlg[edi],Not IF_ReleaseFade
DoFadeoutOld:

        mov al,ITI1VlEnvNum[esi]
        mov IVPoints[edi],al

        mov al,ITI2VLS[esi]
        mov IVLoopStart[edi],al
        
        mov al,ITI2VLE[esi]
        mov IVLoopEnd[edi],al
        
        mov al,ITI2SLS[esi]
        mov IVSustain[edi],al
        
        mov al,ITI2SLE[esi]
        mov IVSustEnd[edi],al

        xor ecx,ecx
ConvertOldITEnvLoop:
        cmp ITI2VlEnvPts[esi+2*ecx],0FFh
        je ConvertOldITEnvEnd
        mov ebx,ecx
        shl ebx,1
        add ebx,ecx                              ; ebx=ecx*3
        movzx ax,byte ptr ITI2VlEnvPts[esi+2*ecx]
        mov word Ptr IVEnvelope[edi+ebx+1],ax    ; write envelope point
        mov al,ITI2VlEnvPts[esi+2*ecx+1]
        mov IVEnvelope[edi+ebx],al               ; write envelope data
        inc ecx
        cmp ecx,25
        jbe ConvertOldITEnvLoop
        dec cl
ConvertOldITEnvEnd:
        mov IVPoints[edi],cl

        jmp NoLoadInstrument
UseNewITInstrument:

;writeln 'New IT instrument'

        mov al,ITI1GbV[esi]
        mov IGVolume[edi],al

        movzx eax,ITI1FadeOut[esi]
        shl ax,5
        mov IVFadeout[edi],ax
        or IFlg[edi],IF_ReleaseFade

        mov al,ITI1DCT[esi]
        mov IDCT[edi],al

        or al,al
        jz NoDCT
        push esi
        mov esi,USMH
        or MFlags[esi],F_UseDCT
        pop esi
NoDCT:
        
        mov al,ITI1DCA[esi]
        mov IDCA[edi],al
        
        mov al,ITI1NNA[esi]
        mov INNA[edi],al

        or al,al
        jz NoNNA
        push esi
        mov esi,USMH
        or MFlags[esi],F_UseNNA
        pop esi
NoNNA:        

; ***** Volume envelope *****

        mov al,ITI1VlEnvFlg[esi]
        mov IVType[edi],al

        test IVType[edi],E_On
        jz DoFadeout                   ; Do fadeout if there is no volume env
        test IVType[edi],EIT_Loop
        jnz DoFadeout                  ; No fadeout if there is no loop
        and IFlg[edi],Not IF_ReleaseFade
DoFadeout:

        mov al,ITI1VlEnvNum[esi]
        mov IVPoints[edi],al

        mov al,ITI1VlEnvLpB[esi]
        mov IVLoopStart[edi],al
        
        mov al,ITI1VlEnvLpE[esi]
        mov IVLoopEnd[edi],al
        
        mov al,ITI1VlEnvSLB[esi]
        mov IVSustain[edi],al
        
        mov al,ITI1VlEnvSLE[esi]
        mov IVSustEnd[edi],al

        add esi,ITI1VlEnvPts
        add edi,IVEnvelope
        mov ecx,75
        cld
        rep movsb

; ***** Panning envelope *****

        mov esi,ITIOffset
        mov edi,USMIOffset

        mov al,ITI1PnEnvFlg[esi]
        mov IPType[edi],al

        mov al,ITI1PnEnvNum[esi]
        mov IPPoints[edi],al

        mov al,ITI1PnEnvLpB[esi]
        mov IPLoopStart[edi],al
        
        mov al,ITI1PnEnvLpE[esi]
        mov IPLoopEnd[edi],al
        
        mov al,ITI1PnEnvSLB[esi]
        mov IPSustain[edi],al
        
        mov al,ITI1PnEnvSLE[esi]
        mov IPSustEnd[edi],al

        add esi,ITI1PnEnvPts
        add edi,IPEnvelope
        mov ecx,75
        cld
        rep movsb     
        
NoLoadInstrument:

        U_Free ITIOffset
        
_LoadInstrumentLoopEnd:

        inc ICount
        mov ax,Itotal
        cmp ICount,ax
        jne _LoadInstrLoop

NoInstruments:

; ** Samples Load

        cmp STotal,0
        je NoSamples        

; Read the samples file pointers
        MSetPos ITOffset

        movzx eax,STotal
        shl eax,2
        add ITOffset,eax

        mov esi,USMH
        add esi,MSamplPtr

        MRead esi,eax
        
        mov SCount,0
_LoadSamplesLoop:        
        mov esi,USMH
        movzx ebx,SCount
        mov eax,MSamplPtr[esi+4*ebx]    ;Read the sample header file offset
        mov MSamplPtr[esi+4*ebx],0

        cmp eax,0
        je _LoadSampleLoopEnd

        MSetPos eax                     ;Set file pointer to sample

        U_Malloc ITSampleSize
        jc IT_LoadInstrumentsErr
        mov ITSOffset,eax

        MRead eax,ITSampleSize          ;Read the IT sample header

        mov esi,ITSOffset
        cmp ITSId[esi],'SPMI'           ;Is IT Sample ID correct ?
        je ITSIdOk
        jmp NoLoadSample
ITSIdOk:        

        U_Calloc USSSampleSize
        mov USMSOffset,eax

        mov esi,USMH
        movzx ebx,SCount
        mov MSamplPtr[esi+4*ebx],eax    ;Write the sample header offset

        mov esi,ITSOffset
        mov edi,USMSOffset
        
        mov SId[edi],'LPMS'
        add edi,SName
        add esi,ITSName
        mov ecx,26
        cld
        rep movsb
        mov esi,ITSOffset
        mov edi,USMSOffset

        mov eax,ITSLength[esi]          ; Convert Length and Loop
        mov SLength[edi],eax
        mov eax,ITSLoop[esi]
        mov SLoop[edi],eax
        mov eax,ITSLoopEnd[esi]
        mov SLoopEnd[edi],eax
        mov eax,ITSSustain[esi]
        mov SSustain[edi],eax
        mov eax,ITSSustEnd[esi]
        mov SSustEnd[edi],eax

        mov al,ITSGvl[esi]
        mov SVolume[edi],al
        mov al,ITSVol[esi]
        mov SDefVolume[edi],al

; Sample Auto vibrato

        mov al,ITSVibType[esi]
        mov SVibType[edi],al

        mov al,ITSVibSpeed[esi]
        mov SVibRate[edi],al

        mov al,ITSVibDepth[esi]         ;Ok
        mov SVibDepth[edi],al

        mov al,255
        sub al,ITSVibrate[esi]          ;Ok ?
        mov SVibSweep[edi],al

        mov eax,ITSFine[esi]
        test USMFlags,F_Linear
        jz ST3Fine

        xor ecx,ecx
        cmp eax,8363
        jae higher
Lower:
        cmp eax,4181
        jae FreqAdjOk
Lower1:        
        inc ecx
        shl eax,1
        cmp eax,4181
        jb Lower1

        push eax
        mov eax,ecx
        mov ebx,768
        mul ebx
        mov ecx,eax
        neg ecx                 ;ecx=-768*ecx
        pop eax
        jmp FreqAdjOk
        
Higher:
        cmp eax,8363*2          ;(16726)
        jbe FreqAdjOk
Higher1:
        inc ecx
        shr eax,1
        cmp eax,8363*2
        ja Higher1        

        push eax
        mov eax,ecx
        mov ebx,768
        mul ebx
        mov ecx,eax             ;ecx=-768*ecx
        pop eax        
        
FreqAdjOk:

        cmp eax,8363
        jne NoFine0
        xor eax,eax
        jmp ST3Fine
NoFine0:        

        xor edx,edx
        mov bx,20
        sub eax,4100
        div bx
        movzx eax,ax
        movsx eax,ITLinAdj[2*eax]
        add eax,ecx

ST3Fine:
        mov SFine[edi],eax

; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! A voir (Panning par def)
        
;        mov al,XMSPanning
;        mov SDefPanning[edi],al

        xor bl,bl               ; Convert sample type ( 8/16bit, loop... )
        mov al,ITSFlg[esi]
        test al,ITSM_16Bit
        jz _ITS8Bit
        or  bl,SM_16bit         ; Set 16 bit sample
        shl SLoop[edi],1
        shl SLoopEnd[edi],1
        shl SLength[edi],1
        shl SSustain[edi],1
        shl SSustEnd[edi],1
_ITS8bit:
        test al,ITSM_Stereo
        jz _ITSMono
        or bl,SM_Stereo         ; Set stereo sample
_ITSMono:        
        test al,ITSM_Loop
        je _ITSNoLoop
        or  bl,SM_Loop          ; Set sample Loop
        test al,ITSM_BLoop
        je _ITSNoLoop
        or  bl,SM_Bidi          ; Set Ping-Pong Loop
_ITSNoLoop:
        test al,ITSM_Sustain
        je _ITSNoSustain
        or  bl,SM_Sustain       ; Set sample sustain loop
        test al,ITSM_BSustain
        je _ITSNoSustain
        or  bl,SM_SBidi         ; Set Ping-Pong sustain loop
_ITSNoSustain:
        test al,ITSM_Packed
        je _ITSNotPacked
;        or  bl,SM_Packed        ; Packed sample (IT v1.24+)
_ITSNotPacked:
        mov SType[edi],bl

        mov bl,SF_IT
        test USMFlags,F_Linear
        jz _NoLinearPer
        or bl,SF_Linear        
_NoLinearPer:
        movzx eax,ITSConv[esi]
        test al,ITSF_Signed
        jnz _ITSSigned
        or bl,SF_Unsigned
_ITSSigned:        
        mov SFlag[edi],bl

        test ITSFlg[esi],ITSM_Loaded
        jz NoLoadSample

        cmp SLength[edi],0
        je  NoLoadSample


        mov eax,ITSPointer[esi]

        MSetPos eax

        call LU_LoadSample     ; Load sample data.

NoLoadSample:

        U_Free ITSOffset

_LoadSampleLoopEnd:

        inc SCount
        mov ax,Stotal
        cmp SCount,ax
        jne _LoadSamplesLoop
NoSamples:

        clc
        ret

IT_LoadInstrumentsErr:
        stc
        ret
IT_LoadInstruments Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  ConvertVolume: Convert IT volume to USM volume.                        ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

WaveFormTable DB 0,2,1,3

ConvertNote Proc
                        ; Note is 0-119
        cmp Note,120
        jae NoteCmd
        inc Note        ; Note is 1-120
        jmp ConvertNoteEnd
NoteCmd:
        cmp Note,250
        jne No_NoNote
        mov Note,0      ; No Note
        jmp ConvertNoteEnd
No_NoNote:        
        cmp Note,255
        jne No_NoteOff
        mov Note,Key_Off        ; Key off
        jmp ConvertNoteEnd        
No_NoteOff:
        cmp Note,254
        jne No_NoteCut
        mov Note,Note_Cut       ; Note cut
        jmp ConvertNoteEnd        
No_NoteCut:
        cmp Note,252
        jne No_NoteFade
        mov Note,Note_Fade      ; Note fade
        jmp ConvertNoteEnd        
No_NoteFade:
ConvertNoteEnd:
        ret
ConvertNote Endp

ConvertVolume Proc

        cmp Vol,64              ; 0 -> 40h Volume   (Converted to 10h -> 50h)
        ja  NoVol
        add Vol,10h
        ret
NoVol:
        cmp Vol,74              ; 65 -> 74 FVol Up  (Converted to 90h -> 9Fh)
        ja NoFineVolUp          ; Modifie la m‚moire de DxF ?
;pushad
;movzx eax,Vol
;call print_dec
;waitkey
;popad
        add Vol,90h-65
        ret
NoFineVolUp:
        cmp Vol,84              ; 75 -> 84 FVol Dn  (Converted to 80h -> 8Fh)
        ja NoFineVolDn          ; Modifie la m‚moire de DFx ?
;pushad
;movzx eax,Vol
;call print_dec
;waitkey
;popad
        add Vol,80h-75
        ret
NoFineVolDn:
        cmp Vol,94              ; 85 -> 94  Vol Up  (Converted to 70h -> 7Fh)
        ja NoVolUp
        add Vol,70h-85
        ret
NoVolUp:
        cmp Vol,104             ; 95 -> 104 Vol Dn  (Converted to 60h -> 6Fh)
        ja NoVolDn
        add Vol,60h-95
        ret
NoVolDn:
        mov Vol,0
        ret
ConvertVolume Endp

ConvertCmd Proc
        cmp Cmd,25
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
        cmp al,60h                      ; 5x
        jae NoSetPanbrelloType
        and al,3
        mov al,WaveFormTable[eax]
        mov Param,0
        mov Cmd,0
        ret
NoSetPanbrelloType:        
        cmp al,70h                      ; 6x
        jae NoTickPatternDelay
        and al,0Fh
        mov Param,0
        mov Cmd,0
        ret
NoTickPatternDelay:        
        cmp al,80h                      ; 7x
        jae NoInstrumentControl
;write 'IControl !'
        and al,0Fh
        mov bl,InstrControlParam[eax]
        mov Param,bl
        mov bl,InstrControlCmd[eax]
        mov Cmd,bl
;pushad
;write 'IControl: '
;call print_dec
;write 'Cmd:'
;movzx eax,Cmd
;call print_dec
;write 'Param:'
;movzx eax,Param
;call print_dec
;;waitkey
;popad
        ret
NoInstrumentControl:
        cmp al,90h                      ; 8x Set Panning        o
        jae NoSetPanning
        and al,0Fh
        mov Param,al
        mov Cmd,_SetPanning2
        ret        
NoSetPanning:        
        cmp al,0A0h
        jae NoSetSurround        
        ret
NoSetSurround:        
        cmp al,0B0h                     ; SAy Set high sample offset o
        jae NoSetHighOffset
        and al,0Fh
        mov param,al
        mov Cmd,_SetHighOffset
        ret
NoSetHighOffset:        
        cmp al,0C0h                     ; Bx Pattern loop       o
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

ConvPorta Proc
        test ITFlg,ITF_GxComp
        jz  LinkGxxMemory
        mov Cmd,_PortaNote
        ret
LinkGxxMemory:
        mov Cmd,_ITPortaNote
        ret
ConvPorta Endp

InstrControlCmd Label byte
  DB _PasteNoteCtrl  ; S70 - Past note cut
  DB _PasteNoteCtrl  ; S71 - Past note off
  DB _PasteNoteCtrl  ; S72 - Past note fade
  DB _SetNNA         ; S73 - Set NNA to note cut
  DB _SetNNA         ; S74 - Set NNA to continue
  DB _SetNNA         ; S75 - Set NNA to note off
  DB _SetNNA         ; S76 - Set NNA to note fade
  DB 0               ; S77 - Turn Volume envelope off
  DB 0               ; S78 - Turn Volume envelope on 
  DB 0               ; 
  DB 0               ;
  DB 0               ;
  DB 0               ;
  DB 0               ;
  DB 0               ;
  DB 0               ;
  
InstrControlParam Label byte
  DB NNA_Cut       ; S70 - Past note cut
  DB NNA_NoteOff   ; S71 - Past note off
  DB NNA_NoteFade  ; S72 - Past note fade
  DB NNA_Cut       ; S73 - Set NNA to note cut
  DB NNA_Continue  ; S74 - Set NNA to continue
  DB NNA_NoteOff   ; S75 - Set NNA to note off
  DB NNA_NoteFade  ; S76 - Set NNA to note fade
  DB 0             ; S77 - Turn Volume envelope off
  DB 0             ; S78 - Turn Volume envelope on 
  DB 0             ;
  DB 0             ;
  DB 0             ;
  DB 0             ;
  DB 0             ;
  DB 0             ;
  DB 0             ;
  
CommNumber Label byte
 DB 0            ; 0
 DB _SetTempo    ; 1 -Axx Set Speed                             o
 DB _Jump        ; 2 -Bxx Jump to order                         o
 DB _BreakHex    ; 3 -Cxx Break to row                          o
 DB _ITVolSlide  ; 4 -Dxx Volume slide  (Up/Down/Fine)          o
 DB _ITPitchDn   ; 5 -Exx Pitch slide/fine slide Down (1)       o
 DB _ITPitchUp   ; 6 -Fxx Pitch slide/fine slide Up   (1)       o
 DB 0            ; 7 -Gxx Portamento to note          (1)       -
 DB _Vibrato     ; 8 -Hxy Vibrato                               o
 DB _Tremor      ; 9 -Ixy Tremor                                o
 DB _Arpeggio    ; 10-Jxy Arpeggio                              o
 DB _ITVibVS     ; 11-Kxx Vibrato+Volume slide                  o
 DB _ITPortVS    ; 12-Lxx Portamento+Volume slide               o
 DB _SetChVol    ; 13-Mxx Set channel volume                    o
 DB _ITChVolSlide; 14-Nxx Slide channel volume                  o
 DB _SetOffset   ; 15-Oxx Set sample offset                     o
 DB _ITPanSlide  ; 16-Pxx Slide panning command
 DB _ITMRetrig   ; 17-Qxy Multi retrig                          o
 DB _Tremolo     ; 18-Rxy Tremolo                               o
 DB 0            ; 19-Sxx "Special commands"                    o
 DB _ITSetBPM    ; 20-Txx Set Tempo/Tempo slide                 o
 DB _FineVibrato ; 21-Uxy Fine vibrato                          o
 DB 0            ; 22-Vxx Set global volume                     o
 DB _ITGVolSlide ; 23-Wxx Slide global volume                   ?
 DB _SetPanning1 ; 24-Xxx Set panning position                  o
 DB 0            ; 25-Yxx Panbrello
 
CommConverter Label dword
 DD NoCmd             ; 0
 DD DirectConv        ; 1 -Axx Set Speed                        o
 DD DirectConv        ; 2 -Bxx Jump to order                    o
 DD DirectConv        ; 3 -Cxx Break to row                     o
 DD DirectConv        ; 4 -Dxx Volume slide (Up/Down/Fine)      o
 DD DirectConv        ; 5 -Exx Pitch slide Down     (1)         o
 DD DirectConv        ; 6 -Fxx Pitch slide Up       (1)         o
 DD ConvPorta         ; 7 -Gxx Portamento to note   (1)         -
 DD DirectConv        ; 8 -Hxy Vibrato                          -
 DD DirectConv        ; 9 -Ixy Tremor                           -
 DD DirectConv        ; 10-Jxy Arpeggio                         -
 DD DirectConv        ; 11-Kxx Vibrato+Volume slide             o
 DD DirectConv        ; 12-Lxx Portamento+Volume slide          -
 DD DirectConv        ; 13-Mxx Set channel volume               o
 DD DirectConv        ; 14-Nxx Slide channel volume             o
 DD DirectConv        ; 15-Oxx Set sample offset                -
 DD DirectConv        ; 16-Pxx Slide panning command
 DD DirectConv        ; 17-Qxy Multi retrig                     -
 DD DirectConv        ; 18-Rxy Tremolo                          -
 DD ConvSpecial       ; 19-Sxx "Special commands"               -
 DD DirectConv        ; 20-Txx Set Tempo/Tempo slide            o
 DD DirectConv        ; 21-Uxy Fine vibrato                     -
 DD ConvSetGVolume    ; 22-Vxx Set global volume                -
 DD DirectConv        ; 23-Wxx Slide global volume              ?
 DD DirectConv        ; 24-Xxx Set panning position             o
 DD NoCmd             ; 24-Yxx Panbrello

; (1) Use shared memory
 
CODE32 ENDS
;=============================================================================
end
; ITLOAD.ASM (c) 1997 FreddyV/Useless