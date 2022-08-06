// USMPlay  WATCOM C example
// By Freddy Vetele (FreddyV/Useless)
//
// This example show you how to load and play a Fast Tracker file. 
// It also use Timer functions and some synchro variables.

#include <stdio.h>
#include <stdlib.h>  // _psp definition
#include "usmplay.h"

int timer_count;

void timer(void)  // The timer function, it will be called at 70Hz
{
timer_count++;
}

main(void)
{
 USM *music;         // Pointer to an USM music
 char filename[] = "..\\..\\DATA\\EFFECT.XM";

 HardwareInit(_psp); // This must be the first function call !

 USS_Setup();
// USS_AutoSetup();

 if (Error_Number==0)
    {
     printf("USM Play v1.1 (WATCOM C example)\n");

     printf("Loading %s\n",&filename);
     
     music=XM_Load(LM_File,0x020202020,&filename);   // Load the file
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }

     printf("Music name %s\n",music->Name);
     printf("Output device: %s\n",DEV_Name);

     USS_SetAmpli(200);      // sound amplification for mixed device                             
     USMP_StartPlay(music);
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }
     
     timer_count=0;
     Timer_Start(&timer,TimerSpeed/70);             // Start a 70Hz Timer.

     printf("Press a key to stop.\n");

//     USMP_SetPosition(3,0);  // To start at Order 3, row 0
     
     while (!kbhit())
      {
      printf("Order: %2d Pattern: %2d Row: %2d\r",Order,Pattern,Row);
      }

     Timer_Stop(&timer);                            // Stop the timer.

     USMP_StopPlay();
     USMP_FreeModule(music);

   printf("\n%d Timer calls.\n",timer_count);
    }
}
