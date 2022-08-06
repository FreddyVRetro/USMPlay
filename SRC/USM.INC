;            ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;            º       ÷÷÷÷÷÷÷÷÷÷÷÷÷÷ USM.INC ÷÷÷÷÷÷÷÷÷÷÷÷÷÷       º
;            º                                                   º
;            º              Useless Module Definition            º
;            ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº
;            º   By Freddy V‚tel‚ (FreddyV/Useless)              º
;            º                                                   º
;            º   Code Starts .................. 31/03/1996       º
;            º   Last Update .................. 22/06/1997       º
;            ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
; USM format includes all XM feathures.
; You can use this file if you want to add an USM loader in your player.
; But this format is always moving. this will not be easy.
; The USM format will be stable when IT support will be finish.
;
; See USSVAR.INC for the instruments and samples format.

; USSVAR.INC Must be include before USM.INC (MAX constants definition)

USMVersion EQU 5

ifndef MAX_Instruments
display 'USSVAR.INC must be included before USM.INC'
endif

MAX_Channels    EQU 64
MAX_Patterns    EQU 256

USMHeaderLen EQU MInstrPtr+MAX_Instruments*4

USM struc
        MId          DD 0      	        ; Useless Module Id 'USLM'
        MVersion     DW 0               ; Module Version
        MName        DB 32 DUP (0)      ; Module Name
        MFlags       DW 0               ; Module Flags
        MTracker     DW 0               ; Tracker
        MPeriodMin   DW 0               ; Minimum period value
        MPeriodMax   DW 0               ; Maximum period value

        MChannels    DW 0               ; Number of Channels
        MPatterns    DW 0               ; Number of Patterns
        MSamples     DW 0               ; Number of samples
        MInstruments DW 0               ; Number of instruments
        MSongLen     DW 0               ; Song Length
        MRestart     DW 0               ; Restart position
        MTempo	     DB 0               ; Default Speed
        MBPM	     DB 0               ; Default Tempo (BPM)
        MGVolume     DB 0               ; Global Volume
        MSep         DB 0               ; Panning separation (IT)

        MOrder       DB 256 DUP (0)     ; Pattern order table
        MChPan       DB MAX_Channels    DUP (0) ; Channels panning Table
        MChVol       DB MAX_Channels    DUP (0) ; Channels volume Table
        MPattPtr     DD MAX_Patterns    DUP (0) ; Pointers to patterns
        MSamplPtr    DD MAX_Samples     DUP (0) ; Pointers to samples
        MInstrPtr    DD MAX_Instruments DUP (0) ; Pointers to instruments
USM Ends

;MChPann : Panning for each channel (0->64)  (IT settings)
;           100 -> Surround (Not used)
;          +128 -> disabled channel

; File Flags

F_Linear       EQU 1   ; Linear/Amiga Periode (Don't change it)
F_InstrMode    EQU 2   ; Samples/Instrument Mode
F_PlayedSmpVol EQU 4   ; Use currently played sample default volume (FT2)
F_FineVibrato  EQU 8   ; Finer vibrato command (IT OldEfx Off)
F_CutHighPitch EQU 16  ; Cut channel sound with too high pitch (IT/ST3 porta up)
F_FastVS       EQU 32  ; ST3 Fast Volume slide.
F_BigGVolSlide EQU 64  ; Global volume slide parametres*2 (for S3M/XM)
F_NoMRetrReset EQU 128 ; Don't reset retrig counters when an instrument number
                       ; is set (FOR ST3/IT)
F_SChange      EQU 256 ; Start the sample if instrument number is changed

F_UseNNA       EQU 16384 ; NNA is used by this music
F_UseDCT       EQU 32768 ; DCT is used by this music

; 'Source' Tracker constants
M_ProTracker Equ 1
M_FT2 Equ 2
M_ST2 Equ 3
M_ST3 Equ 4
M_IT  EQU 5

; Channels panning are from 0 (Full left) to 64 (Full right)
; Channels volume are from 0 to 64 (+128, channel is disable)

USMPatternSize EQU PRow+2

USMPattern Struc
        PId     DD 0    ; Useless pattern Id 'USLP'
        PSize   DD 0    ; Pattern Size
        PNumber DW 0    ; Pattern number
        PRow    DW 0
USMPattern Ends

NoteSize EQU 5

; Pattern rows format:
;
; Note (byte)        1 (C-0) to 96 (B-7) 255 is Key Off 
; Instrument (byte)  1 to 255
; Volume (byte)      FT2 like volume (See the end of the file)
; Command (byte)
; Parameter (byte)

Key_Off   EQU 255       ; (Note Off for IT)
Note_Cut  EQU 254
Note_Fade EQU 253
Row_End   EQU 252       ; End of the current row (very simple packing)

; Command Constants.

;   Name      Value  Full Number/Name          First used by  x, not in player

_Arpeggio      EQU 0  ;00-0xy Arpeggio                (MOD)
_PortUp        EQU 1  ;01-1xx Portamento Up           (MOD)
_PortDown      EQU 2  ;02-2xx Portamento Down         (MOD)
_PortaNote     EQU 3  ;03-3xx Portamento to Note      (MOD)
_Vibrato       EQU 4  ;04-4xy Vibrato                 (MOD)
_PVolumeSlide  EQU 5  ;05-5xy Portamento+Volume Slide (MOD)
_VVolumeSlide  EQU 6  ;06-6xy Vibrato+Volume Slide    (MOD)
_Tremolo       EQU 7  ;07-7xy Tremolo                 (MOD)
_SetPanning1   EQU 8  ;08-8xx Set Panning (0-FFh)     (MOD/DMP)
_SetOffset     EQU 9  ;09-9xx Set Sample Offset       (MOD)
_VolumeSlide   EQU 10 ;10-Axy Volume Slide            (MOD)
_Jump          EQU 11 ;11-Bxx Jump to pattern         (MOD)
_SetVolume     EQU 12 ;12-Cxx Set Volume              (MOD)
_Break         EQU 13 ;13-Dxx Pattern Break           (MOD)
                      ;14-Exy Extended Effects (24+x)
_SetTempo_BPM  EQU 15 ;15-Fxx Set Speed/Set BPM       (MOD)

_GVolume       EQU 16 ;16-Gxx Set Global Volume       (S3M/XM)
_GVolumeSlide  EQU 17 ;17-Hxx Global Volume Slide     (XM)
                      ;18-I
                      ;19-J
_KeyOff        EQU 20 ;20-Kxx Key Off (after xx tick) (XM)
_EnvPos        EQU 21 ;21-Lxx Set Envelope Pos        (XM)
                      ;22-M
                      ;23-N
                      ;24-O
_PanningSlide  EQU 25 ;25-Pxx Panning Slide           (XM)
                      ;26-Q
_MRetrig       EQU 27 ;27-Rxy Multi Retrig Note       (S3M)
                      ;28-S
_Tremor        EQU 29 ;29-Txy Tremor                  (STM)
                      ;30-U
                      ;31-V
_Synchro       EQU 32 ;32-Wxx Synchro function        (USM)
_EFPort        EQU 33 ;33-Xxy Extra Fine Portamento   (S3M)
                      ;34-Y
                      ;35-Z

_SetFilter     EQU 36 ;36-E0x Set Filter              (MOD) x
_FPortUp       EQU 37 ;37-E1x Fine Portamento Up      (MOD)
_FPortDown     EQU 38 ;38-E2x Fine Portamento Down    (MOD)
_Gliss         EQU 39 ;39-E3x Glissando Control       (MOD) x
_Vibtype       EQU 40 ;40-E4x Set Vibrato Waveform    (MOD)
_FineTune      EQU 41 ;41-E5x Set Finetune            (MOD) x
_Patloop       EQU 42 ;42-E6x Pattern Loop            (MOD)
_TremType      EQU 43 ;43-E7x Set Tremolo WaveForm    (MOD)
_SetPanning2   EQU 44 ;44-E8x Set Panning (0-Fh)      (MOD/IT/S3M)
_Retrig        EQU 45 ;45-E9x Retrig Note             (MOD)
_FVolumeUp     EQU 46 ;46-EAx Fine Volume Slide Up    (MOD)
_FVolumeDn     EQU 47 ;47-EBx Fine Volume Slide Down  (MOD)
_CutNote       EQU 48 ;48-ECx Cut Note                (MOD)
_NoteDelay     EQU 49 ;49-EDx Delay Note              (MOD)
_PatternDelay  EQU 50 ;50-EEx Pattern Delay           (MOD)
_InvertLoop    EQU 51 ;51-EFx Invert Loop             (MOD) x

_SetTempo      EQU 52 ;52-    Set Tempo
_SetBPM        EQU 53 ;53-    Set BPM
_BreakHex      EQU 54 ;54-    Pattern Break (Hex)     (IT )
_ITSetBPM      EQU 55 ;55-    IT Set/Slide BPM        (IT )
_ITVolSlide    EQU 56 ;56-Dxx IT Volume slide/Fine VS (IT/S3M)
_ITPitchDn     EQU 57 ;57-Exx
_ITPitchUp     EQU 58 ;58-Fxx
_ITPortaNote   EQU 59 ;59-Gxx IT Portamento to note   (IT/S3M)
_ITVibVS       EQU 60 ;60-Kxy IT Vibrato+Volume slide (IT/S3M)
_ITPortVS      EQU 61 ;61-Lxy IT Portamento+Vol Slide (IT/S3M)
_SetChVol      EQU 62 ;62-Mxx Set Channel Volume      (IT )
_ITChVolSlide  EQU 63 ;63-Nxy Channel volume slide
_ITPanSlide    EQU 64 ;64-Pxy IT Panning Slide
_ITMRetrig     EQU 65 ;65-Qxy IT Multi retrig         (IT/S3M)
_FineVibrato   EQU 66 ;66-Uxy Fine Vibrato
_ITGVolSlide   EQU 67 ;67-Wxy Global volume slide
_Panbrello     EQU 68 ;68-Xxy Panbrello               (IT )
_PasteNoteCtrl EQU 69 ;69-S70-S73 Paste Notes control
_SetNNA        EQU 70 ;70-S74-S77 Set NNA
_SetHighOffset EQU 71 ;71-SAy Set sample offset high part yxx00h

; Volume commands are processed as in FT2:
;
; 00h-09h -> Do nothing
; 10h-5Fh -> Set Volume (value-10h)
; 60h-FF  -> Process "volume" command.

_VVolSlideDown EQU 0
_VVolSlideUp   EQU 1
_VFVolDown     EQU 2
_VFVolUp       EQU 3
_VSetVibSpeed  EQU 4
_VVibrato      EQU 5
_VPanning      EQU 6
_VPanSlideL    EQU 7
_VPanSlideR    EQU 8
_VPortaNote    EQU 9

; USM.INC (c) 1997 FreddyV/Useless