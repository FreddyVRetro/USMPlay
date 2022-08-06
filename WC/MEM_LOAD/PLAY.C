// USMPlay  WATCOM C example
// By Freddy Vetele (FreddyV/Useless)
//
// This example show you how to load and play a Fast Tracker file. 
// It also use Timer functions and some synchro variables.

#include <stdio.h>
#include <stdlib.h>  // _psp definition
#include "usmplay.h"

main(void)
{
 USM *music;         // Pointer to an USM music
 long filesize;
 FILE *musfile;
 USM *muspointer;

 char filename[] = "..\\..\\DATA\\EFFECT.XM";

 HardwareInit(_psp); // This must be the first function call !

 USS_Setup();
// USS_AutoSetup();

 if (Error_Number==0)
    {
     printf("USM Play v1.1 (WATCOM C example)\n");

     printf("Loading %s\n",&filename);
     
     if ((musfile=fopen(filename,"rb"))==NULL) 
        { printf("Error opening file.\n"); exit(0); }

// Get file size.
     fseek(musfile,0,SEEK_END);
     filesize=ftell(musfile);
     fseek(musfile,0,SEEK_SET);

// Read file in memory.
     if ((muspointer=malloc(filesize))==NULL)
        { printf("Memory error.\n"); exit(0); }

     if (!fread(muspointer,filesize,1,musfile))
        { printf("Error reading file.\n"); exit(0); }

     fclose(musfile);

//   Load the music from memory
     music=XM_Load(LM_Memory,0x020202020,(char *) muspointer);
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }
     free(muspointer);

     printf("Music name %s\n",music->Name);
     printf("Output device: %s\n",DEV_Name);

     USS_SetAmpli(200);      // sound amplification for mixed device                             
     USMP_StartPlay(music);
     if (Error_Number!=0) { Display_Error(Error_Number); exit(0); }
     
     printf("Press a key to stop.\n");

     while (!kbhit()) {  }

     USMP_StopPlay();
     USMP_FreeModule(music);
   }
}