;            ษอออออออออออออออออออออออออออออออออออออออออออออออออออป
;            บ       ๗๗๗๗๗๗๗๗๗๗๗๗๗๗ SETUP.INC ๗๗๗๗๗๗๗๗๗๗๗๗๗๗     บ
;            บ                                                   บ
;            บ   Useless sound system default compilation setup. บ
;            บฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤบ
;            บ   By Freddy Vetele (FreddyV/Useless)              บ
;            บ                                                   บ
;            บ   Code starts .................. 25/10/1996       บ
;            บ   Last update .................. 03/12/1997       บ
;            ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ

Yes Equ 1   ; | Don't change this !
No  Equ 0   ; |

;---------------------------- Intro/Demo mode --------------------------------
;
; IntroMode flag was added to help you to get the smallest code for your
; party version intro.
; When this flag is enabled, your intro will be GUS only with internal USM
; file loading.
;
; If you want to add Sound Blaster support, set UseSB, UseDMA and UseIRQEnable
; to Yes and use USMPLAY memory functions instead of DOS32/EOS memory functions
; (or do all your memory allocation before 'loading' the music)
;
; ! Don't forget to setup the MAX_SSChannels and MAX_PLChannels values to 
; reduce the code size again.

IntroMode Equ No

;----------------------------- Sound drivers ---------------------------------

if IntroMode Eq Yes     ; * Intro mode *

UseIW    Equ No   ; Include Interwave driver ?
UseGUS   Equ Yes  ; Include GUS driver ?
UseSB    Equ No   ; Include Sound Blaster driver ?
UseHP    Equ No   ; Include PC Speaker driver ?
UseNoSnd Equ Yes  ; Include No Sound driver ?

else                    ; * 'Demo' mode *

UseIW    Equ Yes  ; Include Interwave driver ?
UseGUS   Equ Yes  ; Include GUS driver ?
UseSB    Equ Yes  ; Include Sound Blaster driver ?
UseHP    Equ Yes  ; Include PC Speaker driver ?
UseNoSnd Equ Yes  ; Include No Sound driver ?

endIf

;-------------------------------- Setup --------------------------------------
;
; Setup function needs MEMORY.ASM to run and is bigger than Autosetup function.
; If you use the sound system for a GUS only intro, use only AutoSetup.

if IntroMode Eq Yes     ; * Intro mode *

UseSetup Equ No
UseAutoSetup Equ Yes

else                    ; * 'Demo' mode *

UseSetup Equ Yes
UseAutoSetup Equ Yes

endif

;------------------------------- Player --------------------------------------

LoopMusic Equ Yes ; Use this to loop the music when it is finish.
                  ; (Not implemented by now, the music always loop)

if IntroMode Eq Yes     ; * Intro mode *

Use_USMP_PrevOrder   Equ No  ; USMP_PrevOrder function
Use_USMP_NextOrder   Equ No  ; USMP_NextOrder function
Use_USMP_SetOrder    Equ No  ; USMP_SetOrder function
Use_USMP_SetPosition Equ No  ; USMP_SetPosition function

else                    ; * 'Demo' mode *

Use_USMP_PrevOrder   Equ Yes ; USMP_PrevOrder function
Use_USMP_NextOrder   Equ Yes ; USMP_NextOrder function
Use_USMP_SetOrder    Equ Yes ; USMP_SetOrder function
Use_USMP_SetPosition Equ Yes ; USMP_SetPosition function

endif

;---------------------------- Sound System -----------------------------------

if IntroMode Eq Yes     ; * Intro mode *

Use_SampleLoadMode Equ No  ; This add the ability to load the samples into
                           ; memory or into the sound device.

MAX_SSCHANNELS Equ 32     ; Max number of channels used by the sound system
                          ; It can be used to limit the number of IT virtual
                          ; channels or to reduce the EXE size (for intro)
MAX_PLCHANNELS Equ 32     ; Max number of channels used by the player

else                    ; * 'Demo' mode *

Use_SampleLoadMode Equ No  ; This add the ability to load the samples into
                           ; memory or into the sound device.

MAX_SSCHANNELS Equ 64     ; Max number of channels used by the sound system
MAX_PLCHANNELS Equ 64     ; Max number of channels used by the player

endif

;------------------------------- Mixing --------------------------------------
;
; Default Amplification is a very important variable for the mixing
; routines as there is no sound clipping in useless player mixing routines
;
; It define how mutch channels can be mix together (if the samples are
; at full volume)
; a value of 1000 is for One 'Full' volume channel
; With 500, it can mix 2 channels, ....
;
; You must try by yourself (In Mono AND Stereo Mode) to get the best sound
; quality.

;DefAmpli EQU 1000/2    ; It's good for 4/6 channels files
;DefAmpli EQU 1000/3    ; 8 Channels files
DefAmpli EQU 1000/5
;DefAmpli EQU 1000/8    ; If you play a 24 channels file like DOPE.MOD

FastStereoOversampling EQU Yes ; No, Slow Stereo oversampling (16 bit)
                               ; Yes, Fast Stereo oversampling (8 bit)

;------------------------------- Loaders -------------------------------------
;
; USMP_FreeModule function can only free the files loaded by the externals
; files loaders (USMLoad, MODLoad, XMLoad...)
; When you don't use external loaders, you must set UseFreeModule to No

if IntroMode Eq Yes     ; * Intro mode *

UseFreeModule         Equ No  ; Use FreeModule function ?
UseFreeInternalModule Equ No  ; Use FreeInternalModule function ?

else                    ; * 'Demo' mode *

UseFreeModule         Equ Yes ; Use FreeModule function ?
UseFreeInternalModule Equ Yes ; Use FreeInternalModule function ?

endif

;------------------------------- Timer ---------------------------------------
; Number of timer you can use.
; (If you use the GUS or PC speaker drivers, you must add 1 to max_timers)

if IntroMode Eq Yes     ; * Intro mode *

max_timers  EQU 2
timer_error EQU 0 ; 1, timer errors stop the program (No Error number return)
                  ; You must include ERROR.ASM when this is on
                  ; So It should be 0 in intros.

else                    ; * 'Demo' mode *

max_timers  EQU 4
timer_error EQU 0

endif

;------------------------------ IRQ/DMA --------------------------------------
; You can remove the DMA buffer allocation code and IRQ Enable/Disable code.
; (This must be set to no if you are doing an intro with GUS onky support)

if IntroMode Eq Yes     ; * Intro mode *

UseDMA Equ No
UseIRQEnable Equ No

else                    ; * 'Demo' mode *

UseDMA Equ Yes
UseIRQEnable Equ Yes

endif

;------------------------------- Memory --------------------------------------
;
;   When you use EOS and DOS32, the player allocates its own heap
; The player heap size is (free memory-NeededMem).
; NeededMem value will depends on which DOS extender you use.
;
;For DOS32:
;   NeededMem is the total amount of memory you allocate with the DOS32
; memory allocation functions.
;   If you use the useless memory functions, you can put NeededMem to 0
;
;For EOS:
;   As EOS internally allocates memory for the LoadInternalFile and debugger,
; NeededMem is the memory you will allocate with the EOS memory functions +
; internal EOS memory allocations.
;   As you can see, it's more difficult with EOS because the memory is
; shared between the player, EOS internal needs and EOS memory functions,
; you will have to try different values to find the optimal one.
;
; BTW: EOS load_internal_file error is file not found instead of out of memory
;
;For WATCOM C:
;   USM Play memory functions just call the WATCOM memory functions. (malloc)
;   So, the Memory functions are "useless" in WATCOM C.

NeededMem Equ 32*1024
