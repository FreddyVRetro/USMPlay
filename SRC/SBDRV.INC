
SB10  EQU 1
SB15  EQU 2
SB20  EQU 3
SBPro EQU 4
SB16  EQU 5

MixAddrPort  EQU 04h  ; Mixer register port.             Write Only. 
MixDataPort  EQU 05h  ; Mixer data port.                 Read/Write. 

DSPResetPort EQU 06h  ; DSP Reset port.                  Write Only. 
DSPReadPort  EQU 0Ah  ; DSP Read data port.              Read  Only. 
DSPLifePort  EQU 0Ah  ; DSP Read data port.              Read  Only. 
DSPWStatPort EQU 0Ch  ; DSP Write buffer status port.    Write Only. 
DSPWritePort EQU 0Ch  ; DSP Write data port.             Write Only. 
DSPRStatPort EQU 0Eh  ; DSP Read buffer status port.     Read  Only. 
DSP8AckPort  EQU 0Eh  ;  8 bit DMA IRQ Acknowledge port. Write Only. 
DSP16AckPort EQU 0Fh  ; 16 bit DMA IRQ Acknowledge port. Write Only. 

; SBPro Mixer Registers 

mxrDataReset    EQU 00h
mxrMsterVolume  EQU 02h   ; 7-5 Volume Gauche  3-1 Volume Droite          
mxrDACVolume    EQU 04h   ; 7-5 Vol DAC Gauche 3-1 Vol DAC Droite       * 
mxrFMControl    EQU 06h   ; 6-Gauche On/Off 7- Droite On/On 3-1 Volume    
mxrMicroVolume  EQU 0Ah   ; 2-0 Volume Micro                              
mxrInSetting    EQU 0Ch   ; Reglages Entr‚e et Filtre                     
mxrOutSetting   EQU 0Eh   ; 1- Stereo On  5- Filtre Off                   
mxrMasterVolume EQU 22h   ; 7-5 Left Volume    3-1 Right Volume       * 
mxrFMVolume     EQU 26h   ; 7-5 Left FM Volume 3-1 Right FM Volume    * 
mxrCDVolume     EQU 28h   ; 7-5 Left CD Volume 3-1 Right CD Volume    * 
mxrLineVolume   EQU 2Eh   ; 7-5 Left In Volume 3-1 Right In Volume    * 

; * On SB 16, 7-4 Bits for Left and 3-0 for Right  

; SG NX Pro Mixer Registers 

mxrBass        EQU 46h   ; 2-0 Niveau des basses
mxrTremble     EQU 44h   ; 2-0 Niveau des aigus

; SB16 Mixer Registers 

mxrMasterVolumeL EQU 30h ; 7-3 Left Volume
mxrMasterVolumeR EQU 31h ; 7-3 Right Volume
mxrDACVolumeR    EQU 32h ; 7-3 Left DAC Volume
mxrDACVolumeL    EQU 33h ; 7-3 Right Volume
mxrFMVolumeL     EQU 34h
mxrFMVolumeR     EQU 35h
mxrCDVolumeL     EQU 36h
mxrCDVolumeR     EQU 37h
mxrINVolumeL     EQU 38h
mxrINVolumeR     EQU 39h
mxrMicroVolume16 EQU 3Ah ; 7-3 Volume Micro                              
mxrPCSpeakerVol  EQU 3Bh ; 7-6 Volume PC Speaker                         
mxrOutControl    EQU 3Ch ;                                               

;  SBPro Mixer Const

mxiFilterVal EQU 38h
mxoFilterNeg EQU 20h      ; Reg 0Eh bit 5=1 => Filtre Off                 
mxoStereoOn  EQU 02h      ; Reg 0Eh bit 1=1 => St‚r‚o On                  

;  OPL2 Registers

OPL2Test   EQU 001h
OPL2Timer1 EQU 002h
OPL2Timer2 EQU 003h
OPL2TimCtr EQU 004h     ; Contr“le des Timer.                           
OPL2CtrlG  EQU 008h     ; Contr“le g‚n‚ral.                             
OPL2AM_VIB EQU 020h     ;                                               
OPL2KSL_TL EQU 040h     ; KSL et Niveau total.                          
OPL2AR_DR  EQU 060h     ; Vitesse d'attaque et Vitesse de d‚croissance. 
OPL2SL_RR  EQU 080h     ; Niveau soutenu et vitesse de relachement.     
OPL2Fnum   EQU 0A0h
OPL2Key    EQU 0B0h
OPL2FB_FM  EQU 0C0h
OPL2WS     EQU 0E0h     ; Wave Select.                                  

bKey EQU 20h            ; Masque pour Key                               

; Commandes DSP   
SendOneSample  EQU 010h ; Sortie DAC Directe. (Mono, 20KHz Maxi)          
StartLSpeedDMA EQU 014h ; D‚part du transfer DMA Basse vitesse. (Mono, SB)
ReadOneSample  EQU 020h ; Entr‚e ADC Directe. (Mono, 20KHz Maxi)          
SetTimeConst   EQU 040h ; Envoyer la fr‚quence. (Commandes 14 et 91)    
SetSampleRate  EQU 041h ; Envoyer la fr‚quence. (SB16)                    
SetHSpeedSize  EQU 048h ; Envoyer la taille du transfer DMA Rapide.       
StartHSpeedDMA EQU 091h ; Transfer DMA Haute Vitesse.                     
TurnOnSpeaker  EQU 0D1h ; Turn on the SB speaker.                         
TurnOffSpeaker EQU 0D3h ; Turn off the SB speaker.                        
GetDSPVersion  EQU 0E1h ; Lire la Version du DSP.                         
GetCopyright   EQU 0E3h ; Lire la chaine copyright de la carte.           

; SBDRV.INC (c) 1997 FreddyV/Useless