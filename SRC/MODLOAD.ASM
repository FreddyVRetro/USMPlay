;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º     ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ MODLOAD.ASM ÷÷÷÷÷÷÷÷÷÷÷÷÷÷     º
;            º                                                   º
;            º           Useless MOD Loader (MOD->USM)           º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code starts .................. 19/08/1996       º
;            º   Last update .................. 31/08/1997       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

Yes Equ 0
No  Equ -1

PackPattern Equ Yes
FullLoad    Equ Yes     ; Yes => Load all (Players,trackers..)
                        ; No  => Load all needed for the module (Demos,games..)

INCLUDE MODLOAD.INC
INCLUDE ERR_CODE.INC

INCLUDE MEMORY.INC
INCLUDE LOADUTIL.INC
INCLUDE USSVAR.INC      ; Instruments and samples definition
INCLUDE USM.INC         ; Useless Module Structures Definition


INCLUDE UTILS.INC

;=============================================================================

; MOD files Ident. USM Play can load 28 different MOD files...

ModIdents Label Dword
          DB '4CHN','6CHN','8CHN','10CH','12CH','16CH','18CH','20CH','22CH'
          DB '24CH','26CH','28CH','30CH','32CH','M.K.','M!K!','M&K&','FA04'
          DB 'FLT4','RASP','FLT8','OCTA','OKTA','CD81','FA08','TDZ4','TDZ6'
          DB 'TDZ8'
          DD 0     ; 0 => the table end

MODIdChannels  label byte
          DB 4     ,6     ,8     ,10    ,12    ,16    ,18    ,20    ,22
          DB 24    ,26    ,28    ,30    ,32    ,4     ,4     ,4     ,4
          DB 4     ,4     ,8     ,8     ,8     ,4     ,8     ,4     ,6     
          DB 8

PT EQU M_ProTracker
FT EQU M_FT2

Tracker   DB FT    ,FT    ,FT    ,FT    ,FT    ,FT    ,FT    ,FT    ,FT
          DB FT    ,FT    ,FT    ,FT    ,FT    ,PT    ,PT    ,PT    ,PT
          DB PT    ,PT    ,PT    ,PT    ,PT    ,PT    ,PT    ,PT    ,PT
          DB PT
          
DefPann DD 0

MODH    DD 0
USMH    DD 0

FileId  DD 0
MODTracker DB 0
MODSamples DB 0
SongLenOffset DD 0

MODOffset DD 0

;=============================================================================

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  MOD_LOAD: Load/convert a MOD file. (MOD->USM)                          ³
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
MOD_Load  Proc
	mov LoadMode,bl

        mov DefPann,eax
        mov MODH,0

        MOpen ESI
        jc MODLoadErr

        ; *** Detect MOD Type ***

        MSetPos 1080
        jc MODLoadErr

        mov eax,offset FileId
        Mread eax,4     ; Read the file Id (M.K, 8CHN...)
        jc MODLoadErr
        
        mov eax,FileId

        mov MODTracker,M_ProTracker
        mov MUS_Channels,4
        mov MODSamples,15
        mov SongLenOffset,470
        mov MODOffset,600

        mov edx,0
DetectIdLoop:
        mov eax,ModIdents[4*edx]
        inc edx
        cmp eax,0
        je  DetectIdEnd
        cmp FileId,eax
        jne DetectIdLoop
        dec edx
        movzx eax,MODIdChannels[edx]
        mov MUS_Channels,ax
        mov MODSamples,31
        mov SongLenOffset,950
        mov MODOffset,1084
        mov al,Tracker[edx]
        mov MODTracker,al
DetectIdEnd:

        ; *** Load the MOD Header (Name+Samples def+Order) ***

        movzx eax,ModSamples
        imul ax,30
        add eax,20+2+128
        mov ecx,eax
        push ecx		

        U_Calloc USMHeaderLen
        jc MODLoadErr
        mov USMH,eax

        U_Malloc ecx
        jc MODLoadErr
        mov MODH,eax

        MSetPos 0  ; ! Tester MReadPos !
        jc MODLoadErr

        pop ecx

        Mread MODH,ecx          ;Read the MOD Header
        jc MODLoadErr

        ; *** Convert MOD Header -> USM Header ***

        mov esi,MODH
        mov edi,USMH

        mov MId[edi],'MLSU'
        mov MVersion[edi],USMVersion
        movzx eax,MODTracker
        mov MTracker[edi],ax

        cmp ax,M_ProTracker
        je ProTrackerFile

        ; ** Fast Tracker Period limits **

        mov MPeriodMin[edi],28              ; Minimum amiga period value B-9
        mov MPeriodMax[edi],27392           ; Maximum amiga period value C-0
        
        mov MFlags[edi],F_PlayedSmpVol

        jmp NoProTrackerFile

ProTrackerFile:

        ; ** ProTracker Period limits **

        mov MPeriodMin[edi],453             ; Minimum amiga period value B-5
        mov MPeriodMax[edi],3424            ; Maximum amiga period value C-3

        mov MFlags[edi],F_SChange

NoProTrackerFile:

        ; ** Copy Module name **

        mov ecx,20/4
        add edi,MName
        push ds
        pop es
        cld
        rep movsd               ;Convert the Module Name

        mov esi,MODH
        mov edi,USMH
                                ;Set Panning Table
        push edi
        add edi,MChPan
        mov ecx,Max_Channels/4
        mov eax,DefPann
        rep stosd
        pop edi
                                ;Set Channel volume Table
        push edi
        add edi,MChVol
        mov ecx,Max_Channels
        mov al,64
        rep stosb
        pop edi

        add esi,SongLenOffset
        movzx eax,byte Ptr [esi]        ; Song Length
        inc esi
        mov MSongLen[edi],ax

        movzx ebx,byte Ptr [esi]        ; Restart Order
        inc esi
        cmp bx,ax
        jbe RestartOk
        xor ebx,ebx
RestartOk:
        mov MRestart[edi],bx

        movzx eax,MUS_Channels
        mov MChannels[edi],ax

        xor ecx,ecx
        xor ebx,ebx
GetPatternNumberLoop:
        mov al,[esi+ecx]
        cmp bl,al
        ja  PatternLower
        mov bl,al
PatternLower:
        inc ecx
        cmp ecx,128
        jne GetPAtternNumberLoop
        inc bx

        mov MPatterns[edi],bx
        mov PTotal,bx           ;Save the Number of patterns

        movzx eax,MODSamples
        mov MSamples[edi],ax

        mov MTempo[edi],6
        mov MBPM[edi],125
        mov MGVolume[edi],64*2

        add edi,MOrder
        mov cx,128/4
        cld
        rep movsd

        MSetPos MODOffset       ;Set Filepos to the 1st Pattern
        jc MODLoadErr

        call MOD_LoadPatterns
        jc MODLoadErr

        call MOD_LoadSamples
        jc MODLoadErr

        clc
        mov esi,USMH            ;Returns a pointer to the Module...
        jmp MODLoadEnd

MODLoadErr:
        pushad
        MCLose                  ;Close the file
        popad

if _WATCOM
        mov _Error_Number,eax
        ret
else
        stc
        ret
endif

MODLoadEnd:

        pushf
        MClose                  ;Close the file
        cmp MODH,0
        je NoMODHFree
        U_Free MODH
NoMODHFree:

        popf
        ret
MOD_Load  Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  MOD_Loadpatterns: Load/convert MOD patterns. (MOD->USM)                ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

PCount DW 0
PTotal DW 0
PPtr   DD 0
PEnd   DD 0

USMPattSize DD 0
MODPattSize DD 0

MODPPtr DD 0

;Warning: PTotal must be >0

MOD_LoadPatterns Proc Near

        movzx eax,MUS_Channels
        imul ax,64*4
        mov MODPattSize,eax

        movzx eax,MUS_Channels
        imul ax,64*5
        add eax,USMPatternSize
        mov USMPattSize,eax

        mov PCount,0

_LoadPatternsLoop:

        U_Calloc USMPAttSize            ;Allocate USM Pattern Memory
        jc MOD_PErr
        mov PPtr,eax

If PackPattern Eq No
        mov edi,USMH
        movzx edx,PCount
        mov MPattPtr[edi+4*edx],eax     ;Save the Pattern Offset
EndIf

        U_Malloc MODPAttSize            ;Allocate the MOD patter data buffer
        jc MOD_PErr
        mov MODPPtr,eax

        mov ecx,MODPattSize
        add MODOffset,ecx
        MRead MODPPtr,ecx               ;Load the MOD pattern data
        jc MOD_PErr

        ; Convert the pattern MOD->USM

        mov esi,MODPPtr	
        mov edi,PPtr

        mov ax,PCount
        mov Pnumber[edi],ax
        mov ax,64
        mov Prow[edi],ax

        If FullLoad eq yes
        mov SId[edi],'PLSU'
        mov eax,USMPattSize
        mov Psize[edi],eax
        endif

        mov PEnd,edi
        add PEnd,eax

        add edi,USMPatternSize
_PConvertLoop:

        mov ax,[esi]
        xchg ah,al
        mov bh,ah
        mov bl,[esi+2]
        mov cl,bl
        shr cl,4
        and bh,0F0h
        add cl,bh
        mov [edi+1],cl  ;sample number
        and bl,0Fh
        mov [edi+3],bl  ;effect number
        mov bl,[esi+3]
        mov [edi+4],bl  ;effect parameter

        and ax,0FFFh    ;Amiga periode
        shl ax,2        ;Internal period is Amiga period*4
        xor edx,edx
        cmp ax,0
        je NoteFound
getNoteNumberLoop:
        mov bx,Period_Table[2*edx]
        inc edx
        cmp bx,0
        je NoteFound
        cmp bx,ax
        ja getNoteNumberLoop	
        mov cx,Period_table[2*(edx-2)] ; bx > ax > cx
        sub cx,ax
        sub ax,bx
        cmp ax,cx
        jb NoteFound
        dec edx
NoteFound:
        mov [edi],dl    ;Note

        add esi,4
        add edi,5


        cmp byte Ptr [edi-2],14    ; Convert Command Exy to Command 36+x
        jne No_ExtendedCommand
        mov al,[edi-1]
        shr al,4
        add al,36
        mov [edi-2],al
        and byte Ptr [edi-1],0Fh
No_ExtendedCommand:

        cmp edi,PEnd
        jb  _PconvertLoop

        U_Free MODPPtr

; Pack the pattern

If PackPattern Eq Yes
        mov esi,PPtr
        call LU_PackPattern

        mov edi,USMH                 ;Useless Module header Offset
        movzx edx,PCount             ;Get the pattern number
        mov MPattPtr[edi+4*edx],esi  ;Save the Pattern Offset
EndIf

        MSetPos MODOffset
        jc MOD_PErr

        inc PCount
        mov ax,Ptotal
        cmp PCount,ax
        jne _LoadPatternsLoop   ; Pattern Loop

        clc
        ret
MOD_PErr:
        stc
        ret
MOD_LoadPatterns Endp

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³  MOD_LoadSamples: Load/convert MOD samples. (MOD->USM)                  ³
;³                                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SCount	DW 0
MODSOffset DD 0
USMSOffset DD 0

FineTable DW 8363,8413,8463,8529,8581,8651,8723,8757
          DW 7895,7941,7985,8046,8107,8169,8232,8280

MOD_LoadSamples Proc Near
        mov SCount,0
        mov eax,MODH
        add eax,20
        mov MODSOffset,eax

_LoadSamplesLoop:

        U_Calloc USSSampleSize
        jc MOD_SErr
        mov USMSOffset,eax

        mov esi,USMH
        movzx edx,SCount
        mov MSamplPtr[esi+4*edx],eax    ;Save the Sample Offset

        mov edi,USMSOffset              ; Get Sample Header Offset

        If FullLoad eq Yes
        mov SId[edi],'LPMS'
        add edi,SName
        mov esi,MODSOffset
        mov ecx,22/4
        cld
        rep movsd
        mov edi,USMSOffset
        mov esi,MODSOffset
        endif

        ;Convert MOD Sample -> USM Sample

        movzx eax,MODSLength[esi]       ; Convert Length And Loop
        xchg ah,al
        shl eax,1

        push eax
        MSetPos MODOffset
        pop eax
        jc MOD_SErr
        add MODOffset,eax

        mov SType[edi],0  ; Mettre boucl‚ ou non !!!!!!!

        mov SLength[edi],eax
        movzx eax,MODSLoop[esi]
        xchg ah,al
        shl eax,1
        mov SLoop[edi],eax

        movzx ebx,MODSLoopLen[esi]
        xchg bh,bl
        shl ebx,1
        cmp ebx,2
        jbe NoLoop
        mov SType[edi],SM_Loop
NoLoop:

        add eax,ebx
        mov SLoopEnd[edi],eax

        mov SVolume[edi],64     ;Sample Volume=64 (MAX)
        mov al,MODSVolume[esi]
        mov SDefVolume[edi],al
        mov al,80h
        mov SDefPanning[edi],al

        movzx eax,MODSFine[esi]
        mov ebx,8363
        cmp ax,16
        jae WrongFineTune
        movzx ebx,FineTable[2*eax]
WrongFineTune:
        mov SFine[edi],ebx

        cmp SLength[edi],2
        jbe  NotLoadSample

        call LU_LoadSample     ; Load sample data.

        jmp LoadNextSample
NotLoadSample:
        mov SLength[edi],0
LoadNextSample:

        ; ** Sample load end, load next sample **

        add MODSOffset,30

        inc SCount
        movzx eax,MODSamples
        cmp SCount,ax
        jne _LoadSamplesLoop

        clc
        ret

MOD_SErr:
        stc
        ret
MOD_LoadSamples Endp

CODE32 ENDS
;=============================================================================
end
; MODLOAD.ASM (c) 1997 FreddyV/Useless
