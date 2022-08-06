// USMPlay  WATCOM C++ example
// By Freddy Vetele (FreddyV/Useless)
//
// This example show you how to load and play a Fast Tracker file. 
// It also use Timer functions and some synchro variables.

#include <conio.h>
#include <stdlib.h>  // _psp definition
#include "usmplay.h"

int timer_count;

void timer(void)
{
 timer_count++;
}

main(void)
{
 USM *music;
 char filename[] = "..\\DATA\\EFFECT.XM";

 HardwareInit(_psp); // This must be the first function call !

 USS_Setup();
// USS_AutoSetup();

 if (Error_Number==0)
    {
     cputs("USM Play v1.1 (WATCOM C++ example)\r\n");

     cprintf("Loading %s\r\n",&filename);

     music=XM_Load(LM_File,0x020202020,(char *)&filename); // Load the file
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }

     cprintf("Output device: %s\r\n",DEV_Name);

     USMP_StartPlay(music);
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }

     timer_count=0;
     Timer_Start(&timer,TimerSpeed/70);             // Start a 70Hz Timer.

     cputs("Press a key to stop.\r\n");

     while (!kbhit())
      {
      cprintf("Instruments: %2d  %2d  %2d  %2d\r",
              ChInstrument[0],ChInstrument[1],ChInstrument[2],ChInstrument[3]);
      }
     
     Timer_Stop(&timer);                            // Stop the timer.

     USMP_StopPlay();
     USMP_FreeModule(music);

     cprintf("\r\n%d Timer calls.\r\n",timer_count);
    }
}
