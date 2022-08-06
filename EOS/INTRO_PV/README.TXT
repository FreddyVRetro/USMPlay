                      EOS Intro Example 'Party version'

This is an example of what I call, the 'tiny UMS play'
It show you how to get a small size player for your intros. (with EOS)

Please read the usmp.doc file for more info about intros with usmp.

This example use some USM play files:
        usmplay.asm     * Useless USM player
        uss.asm         * Sound system
        ussvar.asm      * sound system variables
        gusdrv.asm      * GUS driver
        nosnddrv.asm    * No sound driver
        timer.asm       * Timer mannager
        hardware.asm    * DMA and environment var functions

The Intromode flag is set to Yes in setup.inc

Here are the size of each parts:
  
                      Unpacked  |   Packed   | 
                                |            |
EOS v3.05              22.5Kb   |   10.5Kb   | eoslite
CHIPBLUE.USM v5        38.5Kb   |    4.0Kb   | chipblue.xm converted with usmconv
USMPLAY v1.05          10.5Kb   |    5.0Kb   | GUS only with unused effects
                                |            | in chipblue.usm off
Intro                  69.0Kb   |   19.5Kb   |


The version with all effects on is 1Kb bigger than the 'tiny' version.

See the 'Party version' example to know how to convert a GUS only intro to 
a GUS/SB one.

Note: To include the music in the file, I converted it to a .INC file
but you can convert it into a .OBJ file and link it with the other .OBJ files.

                                                FreddyV/Useless