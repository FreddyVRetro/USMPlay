# Makefile for the USM player WATCOM library.
# Use Watcom WMAKE.EXE (WMAKE /f MAKEFILE.D4G)
# 
# By FreddyV/Useless and SiRiO/KSD

# Library name (for pmode/w or dos/4gw)

TARGET = usmpwr.lib

# USM play source directory
SRC   = ..\SRC

# USM play include files directory
INC   = ..\SRC

# Assembler parameters
# --------------------
# /mx           Case sensitive (Gloval var)
# /m2           2 passes
# /t            Supress messages if successfull assembly
# /dUsePMODEW_C Use PMODE/W and WATCOM C
# /dUseDOS4GW_C Use DOS4G/W and WATCOM C

#ASMPARAM = /mx /m2 /t /I$(INC) /dUsePMODEW_C
ASMPARAM = /mx /m2 /t /I$(INC) /dUseDOS4GW_C /dSTACKCALL

#------------------------------------------------------------------------------

ASM      = TASM $(ASMPARAM)
LIB     = WLIB

OBJS = 	error.obj usmplay.obj uss.obj ussvar.obj &
        iwdrv.obj gusdrv.obj sbdrv.obj nosnddrv.obj hpdrv.obj mix.obj &
        usmload.obj xmload.obj modload.obj stmload.obj s3mload.obj itload.obj &
        loadutil.obj &
        files.obj memory.obj timer.obj hardware.obj utils.obj


#
#                         ** lib link **
#

$(TARGET) : $(OBJS) makefile
            @if exist $(TARGET) del $(TARGET) >NUL
            *$(LIB) $(TARGET) @files.lst
#            @del *.obj >NUL

#
#                       ** USM Player **
#
                         
usmplay.obj : $(SRC)\usmplay.asm $(SRC)\utils.inc $(SRC)\usm.inc &
              $(SRC)\usmplay.inc
		$(ASM) $(SRC)\usmplay.asm

#
#                    ** Useless sound system **
#
                            
uss.obj     : $(SRC)\uss.asm $(SRC)\uss.inc $(SRC)\utils.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\uss.asm
	      
ussvar.obj  : $(SRC)\ussvar.asm $(SRC)\utils.inc
		$(ASM) $(SRC)\ussvar.asm

#
#                       ** Error handler ** (Display_Error_ function)
#

error.obj   : $(SRC)\ERROR.ASM
                $(ASM) $(SRC)\error.asm
              
#
#                       ** Sound drivers **
#

iwdrv.obj  : $(SRC)\iwdrv.asm  $(SRC)\gusdrv.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\iwdrv.asm

gusdrv.obj  : $(SRC)\gusdrv.asm  $(SRC)\gusdrv.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\gusdrv.asm

sbdrv.obj  : $(SRC)\sbdrv.asm $(SRC)\utils.inc
		$(ASM) $(SRC)\sbdrv.asm

nosnddrv.obj : $(SRC)\nosnddrv.asm $(SRC)\utils.inc
		$(ASM) $(SRC)\nosnddrv.asm

hpdrv.obj    : $(SRC)\hpdrv.asm $(SRC)\utils.inc $(SRC)\mix.asm
		$(ASM) $(SRC)\hpdrv.asm

mix.obj      : $(SRC)\mix.asm $(SRC)\utils.inc $(SRC)\mix.inc
		$(ASM) $(SRC)\mix.asm

#
#                       ** Files loaders **
#

usmload.obj  : $(SRC)\usmload.asm   $(SRC)\usmload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\usmload.asm

xmload.obj   : $(SRC)\xmload.asm   $(SRC)\xmload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\xmload.asm
	      
modload.obj  : $(SRC)\modload.asm  $(SRC)\modload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\modload.asm
	      
stmload.obj  : $(SRC)\stmload.asm  $(SRC)\stmload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\stmload.asm

s3mload.obj  : $(SRC)\s3mload.asm  $(SRC)\s3mload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\s3mload.asm

itload.obj   : $(SRC)\itload.asm  $(SRC)\itload.inc $(SRC)\utils.inc &
	       $(SRC)\loadutil.inc $(SRC)\ussvar.inc
		$(ASM) $(SRC)\itload.asm

loadutil.obj: $(SRC)\loadutil.asm $(SRC)\loadutil.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\loadutil.asm

#
#                       ** Misc files **
#

files.obj   : $(SRC)\files.asm $(SRC)\files.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\files.asm

memory.obj  : $(SRC)\memory.asm $(SRC)\memory.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\memory.asm

timer.obj   : $(SRC)\timer.asm $(SRC)\timer.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\timer.asm

hardware.obj   : $(SRC)\hardware.asm $(SRC)\hardware.inc $(SRC)\utils.inc
		$(ASM) $(SRC)\hardware.asm

utils.obj   : $(SRC)\utils.asm $(SRC)\utils.inc
		$(ASM) $(SRC)\utils.asm
