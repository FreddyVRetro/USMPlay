;            ���������������������������������������������������ͻ
;            �     �������������� NOSNDDRV.ASM ��������������    �
;            �                                                   �
;            �                   No Sound Driver                 �
;            ���������������������������������������������������ĺ
;            �   Auteur������������������������ Freddy V�tel�    �
;            �                                                   �
;            �   D�but d'�criture�������������� 25/08/1996       �
;            �   Derni�re modification��������� 02/05/1998       �
;            ���������������������������������������������������ͼ
.386p
INCLUDE OS.INC

CODE32 SEGMENT PUBLIC PARA 'CODE' USE32
ASSUME  CS:CODE32,DS:CODE32,ES:CODE32

INCLUDE SETUP.INC

INCLUDE USSVAR.INC
INCLUDE TIMER.INC

Public NOSND_DEVICE

NOSND_DEVICE label
             dd Offset NOS_detect
             dd Offset NOS_DoNothing
             dd Offset NOS_DoNothing
             dd Offset NOS_DoNothing
             dd Offset NOS_DoNothing
             dd Offset NOS_StartOutput
             dd Offset NOS_StopOutput
             dd Offset NOS_DoNothing

             dw 1
             dd 0
             dd Offset NOS_Name

NOS_Name db 'No sound',0,36

;�������������������������������������������������������������������������͸
;�  NOS_detect: Detect No Sound device (always here).                      �
;�                                                                         �
;� Input: _DEV_Number=Device to Init (-1=Autodetect)                       �
;�                                                                         �
;� Output: AL=1                                                            �
;�                                                                         �
;���������������������������������������������������������������������������
NOS_detect proc
        mov ax,1
        mov _DEV_Name,Offset NOS_Name
        mov _DEV_MaxChannels,Max_SSChannels
        clc
        ret
NOS_detect Endp

;�������������������������������������������������������������������������͸
;� NOS_StartOutput                                                         �
;�                                                                         �
;� Input: ESI Periodic function to call                                    �
;�                                                                         �
;� Output: CF Set => Error code in EAX.                                    �
;�                                                                         �
;���������������������������������������������������������������������������

NOS_StartOutput proc

        mov eax,esi
        mov ebx,TimerSpeed/(70*2) ; Two times faster than the screen
        call Timer_Start
        jc NOS_StartOutputError

        clc
        ret

NOS_StartOutputError:
        stc
        ret
NOS_StartOutput endp

;�������������������������������������������������������������������������͸
;� NOS_StopOutput                                                          �
;�                                                                         �
;� Input: ESI Periodic proc to stop                                        �
;�                                                                         �
;� Output: CF Set=> Error code in EAX.                                     �
;�                                                                         �
;���������������������������������������������������������������������������

NOS_StopOutput proc

        mov eax,esi
        call Timer_Stop
        jc NOS_StopOutputError

        clc
        ret

NOS_StopOutputError:
        stc
        ret
NOS_StopOutput endp

;�������������������������������������������������������������������������͸
;� NOS_DoNothing                                                           �
;�                                                                         �
;� Input: --                                                               �
;�                                                                         �
;� Output: --                                                              �
;�                                                                         �
;���������������������������������������������������������������������������
NOS_DoNothing Proc
        clc
        ret
NOS_Donothing Endp

CODE32 ENDS
;=============================================================================
END
; NOSNDDRV.ASM (c) 1997 FreddyV/Useless