                    EOS Intro example 'final version'

This show you how to do an intro with GUS and SB support.
Please read the usmp.doc file for more info about intros with usmp.

This example use some USM play files:
        usmplay.asm     * Useless USM player
        uss.asm         * Sound system
        ussvar.asm      * sound system variables
        gusdrv.asm      * GUS driver
        nosnddrv.asm    * No sound driver
        timer.asm       * Timer mannager
        hardware.asm    * DMA and environment var functions

For SB support, you must add :
        sbdrv.asm       * Sound blaster driver
        mix.asm         * Mixing routines
        memory.asm      * Memory functions

Makefile will first convert the music file to USM format with USMCONV.EXE
The USM file will then be converted to an ASM include file with BIN2INC.EXE

 USMPLAY size:
 -------------

EOS + CHIPBLUE.USM (32Kb) + USMPLAY = 88Kb... (24Kb packed with WWPACK)

The GUS and SB version is 5Kb bigger than the GUS only version (packed)
An SB Only version is 14Kb bigger than a GUS version (Not packed)

 ADVICES:
 --------

If you want to do a GUS Only version from the GUS and SB version,
you just have to set UseSB to No (in setup.inc), USE
 and to not link
the files needed for SB (sbdrv.obj, mix.obj and memory.obj)

To add Interwave support, just set UseIW to Yes in setup.inc and include
iwdrv.obj in the link file (eosintro.lnk)

! WARNING: I suggest you to use the EOS memory functions as you will not 
           able to use USMP memory functions in GUS only version.
           So don't forget to adjust the amount of free memory for EOS
           in the last SETUP.INC file line.

                                                FreddyV/Useless