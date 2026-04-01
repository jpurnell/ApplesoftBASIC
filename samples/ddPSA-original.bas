5 'written by D. Goldstein 3/17/84  idea by C. Butler
10 CLS
20 PRINT "�����������������������Ŀ"
30 PRINT "�                       �"
40 PRINT "�                       �"
50 PRINT "�   B A R               �
60 PRINT "�            ������������
70 PRINT "�            �"
80 PRINT "��������������
90 LOCATE 6 ,15:PRINT "�":LOCATE 7,15:PRINT "�"
100 LOCATE 22,1:PRINT "PARKING "CHR$(16)" \                             /"
110 LOCATE 23,1:PRINT "          |                             |
120 LOCATE 6,20:PRINT "PRESS ANY KEY TO SEE WHAT DRUNK DRIVING WILL CAUSE":
130 IF INKEY$="" THEN 130
140 FOR C=7 TO 23:
150 R=INT(RND*(21-18+1)+15)
160 LOCATE C,R:PRINT "�"
170 SOUND R+500,.5
180 FOR YY=1 TO 400 :NEXT YY
190 NEXT C
200 CLS
210 V$=STRING$(79,254)
220 LOCATE 13:PRINT V$
230 LOCATE 11:PRINT "     - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -     ":LOCATE 12,1:PRINT " ":LOCATE 12,39:PRINT " "
240 LOCATE 9,1:PRINT " ":LOCATE 9,39:PRINT " "
250 LOCATE 9:PRINT V$
260 LOCATE 10,1:PRINT " ":LOCATE 10,39:PRINT " "
270 FOR X=35 TO 5 STEP -2
280 MOTOR
290 LOCATE 12,X:PRINT"o�=o"
300 V= SCREEN(12,X-1):IF V=219 THEN GOTO 420
310 FOR ZZ=1 TO 30:NEXT ZZ:LOCATE 12,X:PRINT"    "
320 FOR T=1 TO X :NEXT T
330 NEXT X
340 FOR X=5 TO 35 STEP 2
350 IF X=35 THEN LOCATE 12,7:PRINT "���"
360 LOCATE 10,X:PRINT "o=�o"
370 FOR ZZ=1 TO 20:NEXT ZZ:LOCATE 10,X:PRINT "    "
380 MOTOR
390 FOR T= 1 TO X:NEXT T
400 NEXT X
410 GOTO 270
420 FOR RR=1 TO 7:COLOR 0,7:CLS:FOR Y=1 TO 50 :NEXT Y:COLOR 7,0:CLS:FOR Y=1 TO 50:NEXT Y:NEXT RR:COLOR 15
430 CLS:PRINT "  �            �         o"
440 PRINT"                                   (     -       ** |    ":PRINT:
450 PRINT:PRINT "         =      =    |        o  ":PRINT
460 PRINT "                                    =                         o"
470 BEEP
480 LOCATE 17,1:PRINT "             ==  -        (             ~"
490 LOCATE 19,1:PRINT " ~~-"
500 PRINT "                     ||               �    �"
510 LOCATE 19,5:PRINT"                 B..O..O..M !
520 FOR T=1 TO 1000 :NEXT T:CLS
530 COLOR 15
540 LOCATE 8,5:PRINT "WHEN YOU'RE "
550 FOR G=1 TO 30 :LOCATE 12,G:PRINT "DRUNK":NEXT G
560 FOR G=1 TO 29:LOCATE 12,G:PRINT" ":NEXT G
570 LOCATE 19,1:PRINT "                                   DONT DRIVE!"
580 FOR T=500 TO 2000 STEP 20
590 SOUND T,1
600 NEXT T
610 FOR T=2000 TO 500 STEP -20
620 SOUND T,1
630 NEXT T
640 LOCATE 11,1:COLOR 28:PRINT "              �"
650 LOCATE 12,1:COLOR 15:PRINT "        �-----+-----�  "
660 LOCATE 13,1:COLOR 15:PRINT "       /     ���     \
670 LOCATE 14,1:        :PRINT "      / /--\     /--\ \
680 LOCATE 15,1:        :PRINT "�-------------+-------------�"
690 LOCATE 16,1:        :PRINT "|      \______�______ /     |
700 LOCATE 17,1:        :PRINT "| _-_   \ P O L I C E/  _-_ |
710 LOCATE 18,1:        :PRINT "|( ";:COLOR 30:PRINT "* ";:COLOR 15:PRINT ")   ���������˻   ( ";:COLOR 30:PRINT "* ";:COLOR 15:PRINT ")|"
720 LOCATE 19,1:        :PRINT " \_______���������ʹ_______/
730 LOCATE 20,1:        :PRINT "    ��     �MD 21�     ��
740 LOCATE 21,1:        :PRINT "    ��     �������     ��
 