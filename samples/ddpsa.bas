5 REM WRITTEN BY D. GOLDSTEIN 3/17/84  IDEA BY C. BUTLER
6 REM PORTED FROM GW-BASIC TO APPLESOFT BY J. PURNELL 4/1/26
10 HOME
20 PRINT "+-----------------------+"
30 PRINT "|                       |"
40 PRINT "|                       |"
50 PRINT "|   B A R               |"
60 PRINT "|            +----------+"
70 PRINT "|            |"
80 PRINT "+-----------+"
90 REM DOOR MARKERS
100 PRINT "PARKING  > \                             /"
110 PRINT "           |                             |"
120 HTAB 1: VTAB 6
130 PRINT "PRESS ANY KEY TO SEE WHAT DRUNK DRIVING WILL CAUSE";
140 GET A$
150 REM -- DRUNK WALK FROM BAR --
160 DIM WK(23)
170 FOR C = 7 TO 22
180   R = INT(RND(1) * 4 + 15)
190   WK(C) = R
200   REM LOCATE C,R USING ANSI
210   PRINT CHR$(27);"[";C;";";R;"H";
220   PRINT "*"
230   FOR YY = 1 TO 400: NEXT YY
240 NEXT C
250 REM -- ROAD SCENE --
260 HOME
270 REM BUILD ROAD
280 PRINT CHR$(27);"[13;1H";
290 FOR I = 1 TO 79: PRINT "=";: NEXT I
300 PRINT CHR$(27);"[11;1H";
310 PRINT "     - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -     "
320 PRINT CHR$(27);"[9;1H";
330 FOR I = 1 TO 79: PRINT "=";: NEXT I
340 REM -- ANIMATION LOOP --
350 LET CR = 0
360 FOR X = 35 TO 5 STEP -2
370   REM DRAW CAR GOING LEFT ON ROW 12
380   PRINT CHR$(27);"[12;";X;"H";
390   PRINT "o==o"
400   REM CHECK FOR CRASH (RANDOM DRUNK SWERVE)
410   IF X < 10 AND RND(1) > 0.6 THEN CR = 1
420   IF CR = 1 THEN GOTO 560
430   FOR ZZ = 1 TO 30: NEXT ZZ
440   REM ERASE CAR
450   PRINT CHR$(27);"[12;";X;"H";
460   PRINT "    "
470   FOR T = 1 TO X: NEXT T
480 NEXT X
490 FOR X = 5 TO 35 STEP 2
500   REM DRAW CAR GOING RIGHT ON ROW 10
510   PRINT CHR$(27);"[10;";X;"H";
520   PRINT "o==o"
530   FOR ZZ = 1 TO 20: NEXT ZZ
540   REM ERASE CAR
550   PRINT CHR$(27);"[10;";X;"H";
551   PRINT "    "
552   FOR T = 1 TO X: NEXT T
553 NEXT X
554 GOTO 360
560 REM -- CRASH! --
570 HOME
580 FOR RR = 1 TO 7
590   PRINT CHR$(27);"[7m";
600   HOME
610   FOR Y = 1 TO 50: NEXT Y
620   PRINT CHR$(27);"[0m";
630   HOME
640   FOR Y = 1 TO 50: NEXT Y
650 NEXT RR
660 HOME
670 PRINT "  *            *         o"
680 PRINT "                                   (     -       ** |    "
690 PRINT
700 PRINT
710 PRINT "         =      =    |        o  "
720 PRINT
730 PRINT "                                    =                         o"
740 PRINT CHR$(7)
750 PRINT
760 PRINT
770 PRINT
780 PRINT
790 PRINT "             ==  -        (             ~"
800 PRINT
810 PRINT " ~~-"
820 PRINT "                     ||"
830 PRINT "                     B..O..O..M !"
840 FOR T = 1 TO 1000: NEXT T
850 HOME
860 REM -- MESSAGE --
870 PRINT CHR$(27);"[8;5H";
880 PRINT "WHEN YOU'RE "
890 FOR G = 1 TO 30
900   PRINT CHR$(27);"[12;";G;"H";
910   PRINT "DRUNK"
920 NEXT G
930 FOR G = 1 TO 29
940   PRINT CHR$(27);"[12;";G;"H";
950   PRINT " "
960 NEXT G
970 PRINT CHR$(27);"[19;1H";
980 PRINT "                                   DONT DRIVE!"
990 PRINT
1000 REM -- POLICE CAR --
1010 PRINT CHR$(27);"[11;1H";
1020 PRINT "              *"
1030 PRINT "        *-----+-----*  "
1040 PRINT "       /     |||     \"
1050 PRINT "      / /--\     /--\ \"
1060 PRINT "*-------------+-------------*"
1070 PRINT "|      \______*______ /     |"
1080 PRINT "| _-_   \ P O L I C E/  _-_ |"
1090 PRINT "|( * )   |||||||||||||   ( * )|"
1100 PRINT " \_______|||||||||||_______/"
1110 PRINT "    ||     | MD21 |     ||"
1120 PRINT "    ||     +------+     ||"
1130 END
