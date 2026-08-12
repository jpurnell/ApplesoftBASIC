# Learn BASIC! A Tutorial for Beginners

Welcome to Applesoft BASIC — the same programming language kids used on Apple II computers starting in 1977.

## Overview

This tutorial walks you through writing your first BASIC programs, from printing text
on screen all the way to building a number guessing game. Each lesson builds on the
one before it. All you need is a Mac with Swift installed.

## Getting Started

Open the Terminal app on your Mac. Then type:

```
cd /path/to/ApplesoftBASIC
swift run applesoft
```

You should see:

```
APPLESOFT BASIC INTERPRETER v0.1.1
SWIFT EDITION — APPLE'S 50TH BIRTHDAY
49152 BYTES FREE
READY.
]
```

That `]` is the prompt — the computer is waiting for you to type something!

## Your First Program

Type this in, pressing Enter after each line:

```
10 PRINT "HELLO!"
20 END
```

Now type `RUN` and press Enter:

```
]RUN
HELLO!
```

You just wrote a computer program!

## How BASIC Works

Every line starts with a **number**. The computer runs the lines in order: 10, then 20, then 30, and so on.

- **PRINT** tells the computer to show something on screen
- **END** tells the computer "I'm done!"

Try typing `LIST` to see your program again.

## Lesson 1: Making the Computer Talk

Type `NEW` first to clear the old program. Then type:

```
10 PRINT "MY NAME IS APPLE"
20 PRINT "I AM 50 YEARS OLD"
30 PRINT "HAPPY BIRTHDAY TO ME!"
40 END
```

Type `RUN` to see it!

**Your Turn:** Change the words to say YOUR name and YOUR age!

## Lesson 2: Counting with FOR Loops

`NEW` to clear, then:

```
10 FOR I = 1 TO 10
20 PRINT I
30 NEXT I
40 END
```

Type `RUN`. The computer counts to 10!

**How it works:**
- `FOR I = 1 TO 10` means "start I at 1, go up to 10"
- `NEXT I` means "add 1 to I and go back to the FOR line"
- It keeps going until I gets past 10

**Your Turn:** Can you make it count to 100? How about counting by 2s? Try:

```
10 FOR I = 2 TO 20 STEP 2
20 PRINT I
30 NEXT I
40 END
```

## Lesson 3: Math!

The computer is really good at math. `NEW`, then:

```
10 PRINT 2 + 2
20 PRINT 10 - 3
30 PRINT 5 * 6
40 PRINT 100 / 4
50 END
```

- `+` means add
- `-` means subtract
- `*` means multiply (use the star, not the letter x)
- `/` means divide

**Your Turn:** Can you make the computer figure out how many hours are in a week?
(Hint: 24 hours in a day, 7 days in a week)

## Lesson 4: Variables (Giving Things Names)

A **variable** is like a box with a name on it. You can put a number inside.

```
10 LET AGE = 7
20 LET DOGS = 2
30 PRINT "I AM ";AGE;" YEARS OLD"
40 PRINT "I HAVE ";DOGS;" DOGS"
50 LET TOTAL = AGE + DOGS
60 PRINT "AGE PLUS DOGS = ";TOTAL
70 END
```

- `LET AGE = 7` puts the number 7 in a box called AGE
- You can use the variable name anywhere you'd use a number

**String variables** hold words instead of numbers. They end with `$`:

```
10 LET N$ = "BUDDY"
20 PRINT "HELLO, ";N$;"!"
30 END
```

## Lesson 5: Asking Questions with INPUT

```
10 PRINT "WHAT IS YOUR NAME?"
20 INPUT "NAME: ";N$
30 PRINT
40 PRINT "HI, ";N$;"!"
50 PRINT "NICE TO MEET YOU!"
60 END
```

The computer will stop and wait for you to type something!

**Your Turn:** Can you make it ask for your age too, and then tell you how old
you'll be in 10 years?

```
10 INPUT "WHAT IS YOUR NAME? ";N$
20 INPUT "HOW OLD ARE YOU? ";A
30 PRINT
40 PRINT "HI ";N$;"!"
50 PRINT "IN 10 YEARS YOU WILL BE ";A + 10
60 END
```

## Lesson 6: Making Decisions with IF

```
10 INPUT "PICK A NUMBER: ";N
20 IF N > 50 THEN PRINT "THAT'S A BIG NUMBER!"
30 IF N <= 50 THEN PRINT "THAT'S A SMALL NUMBER!"
40 END
```

- `>` means "greater than"
- `<` means "less than"
- `=` means "equal to"
- `>=` means "greater than or equal to"
- `<=` means "less than or equal to"

## Lesson 7: GOTO (Jump Around!)

`GOTO` makes the program jump to a different line. This is what makes BASIC famous!

```
10 PRINT "THIS IS THE SONG THAT NEVER ENDS"
20 PRINT "IT JUST GOES ON AND ON MY FRIENDS"
30 GOTO 10
```

> Warning: This program never stops! Press Ctrl+C to break out of it.

Now let's use GOTO with IF to make something useful:

```
10 LET COUNT = 1
20 PRINT "COUNT IS ";COUNT
30 LET COUNT = COUNT + 1
40 IF COUNT <= 10 THEN GOTO 20
50 PRINT "DONE!"
60 END
```

## Lesson 8: Draw with Stars!

```
10 FOR ROW = 1 TO 5
20   FOR COL = 1 TO ROW
30     PRINT "*";
40   NEXT COL
50   PRINT
60 NEXT ROW
70 END
```

This makes:

```
*
**
***
****
*****
```

**Your Turn:** Can you make it go the other way?
(Hint: `FOR ROW = 5 TO 1 STEP -1`)

## Lesson 9: Subroutines with GOSUB

A subroutine is like a mini-program inside your program. You can use it over and over!

```
10 PRINT "GOING TO SAY HI..."
20 GOSUB 100
30 PRINT "GOING TO SAY HI AGAIN..."
40 GOSUB 100
50 PRINT "ALL DONE!"
60 END
100 REM -- SAY HI SUBROUTINE --
110 PRINT "*** HI THERE! ***"
120 PRINT "*** HOW ARE YOU? ***"
130 RETURN
```

- `GOSUB 100` jumps to line 100
- `RETURN` jumps back to where you came from
- Lines starting with `REM` are comments — notes for humans, the computer ignores them

## Lesson 10: Your First Real Program

Let's put it all together! Here's a number guessing game:

```
10 REM -- NUMBER GUESSING GAME --
20 LET SECRET = INT(RND(1) * 10) + 1
30 PRINT "I'M THINKING OF A NUMBER"
40 PRINT "BETWEEN 1 AND 10!"
50 PRINT
60 INPUT "YOUR GUESS? ";G
70 IF G = SECRET THEN GOTO 110
80 IF G < SECRET THEN PRINT "TOO LOW!"
90 IF G > SECRET THEN PRINT "TOO HIGH!"
100 GOTO 60
110 PRINT
120 PRINT "*** YOU GOT IT! ***"
130 END
```

- `RND(1)` picks a random number between 0 and 1
- `INT()` chops off the decimal part
- So `INT(RND(1) * 10) + 1` gives us a random number from 1 to 10

## Lesson 11: Drawing with Colors!

Now for the fun stuff — you can draw pictures! `GR` turns on color graphics.
The screen becomes a grid of 40 dots across and 48 dots down, and you can
color each dot with 16 different colors.

```
10 GR
20 COLOR= 12
30 PLOT 20,24
40 END
```

That draws a single bright green dot in the middle of the screen!

- `GR` turns on graphics mode
- `COLOR= 12` picks bright green (there are 16 colors, numbered 0 to 15)
- `PLOT 20,24` colors the dot at column 20, row 24

Here are some colors to try:

| Number | Color |
|--------|-------|
| 0 | Black |
| 1 | Red |
| 3 | Pink |
| 6 | Blue |
| 9 | Orange |
| 12 | Green |
| 13 | Yellow |
| 15 | White |

You can also draw lines! `HLIN` draws sideways and `VLIN` draws up and down:

```
10 GR
20 COLOR= 1
30 HLIN 0,39 AT 24
40 COLOR= 6
50 VLIN 0,47 AT 20
60 END
```

That draws a red line across the middle and a blue line down the middle — a big plus sign!

**Your Turn:** Can you draw a rainbow? Use a FOR loop to draw lines in different colors:

```
10 GR
20 FOR C = 0 TO 15
30   COLOR= C
40   HLIN 0,39 AT C * 3
50   HLIN 0,39 AT C * 3 + 1
60   HLIN 0,39 AT C * 3 + 2
70 NEXT C
80 END
```

You can also check what color a dot is using `SCRN`:

```
10 GR
20 COLOR= 9
30 PLOT 5,5
40 PRINT SCRN(5,5)
50 END
```

That will print `9` because you colored that dot orange (color 9).

## Lesson 12: Hi-Res Drawing!

Want even more detail? `HGR` gives you a huge canvas — 280 dots across and
192 dots down! You can draw dots and lines anywhere.

```
10 HGR2
20 HCOLOR= 1
30 HPLOT 140,96
40 END
```

That draws a single green dot right in the center.

The really cool part is `HPLOT TO` — it draws a line from one point to another:

```
10 HGR2
20 HCOLOR= 6
30 HPLOT 10,10 TO 269,10
40 HPLOT 269,10 TO 269,181
50 HPLOT 269,181 TO 10,181
60 HPLOT 10,181 TO 10,10
70 END
```

That draws a blue rectangle! Each `HPLOT TO` draws a line from the
last point to the new point.

Hi-res colors:

| Number | Color |
|--------|-------|
| 0 | Black |
| 1 | Green |
| 2 | Purple |
| 3 | White |
| 5 | Orange |
| 6 | Blue |

**Your Turn:** Can you draw a triangle? How about a house shape?

You can even draw a circle using SIN and COS (those are math functions
that go around in circles):

```
10 HGR2
20 HCOLOR= 2
30 FOR A = 0 TO 360 STEP 5
40   LET X = INT(COS(A * 3.14159 / 180) * 80 + 140)
50   LET Y = INT(SIN(A * 3.14159 / 180) * 80 + 96)
60   IF A = 0 THEN HPLOT X,Y
70   IF A > 0 THEN HPLOT TO X,Y
80 NEXT A
90 END
```

A purple circle in the middle of the screen!

## Lesson 13: Making Music!

Your computer can make sounds! `BEEP` makes a short beep, and `SOUND`
lets you play any musical note.

```
10 BEEP
20 END
```

Try it — you should hear a beep!

`SOUND` takes two numbers: the **pitch** (how high or low) and how
**long** to play it:

```
10 SOUND 440,0.5
20 END
```

That plays the note A (440 is the pitch) for half a second.

Higher numbers = higher pitch. Lower numbers = lower pitch:

```
10 SOUND 262,0.3
20 SOUND 294,0.3
30 SOUND 330,0.3
40 SOUND 349,0.3
50 SOUND 392,0.3
60 SOUND 440,0.3
70 SOUND 494,0.3
80 SOUND 523,0.3
90 END
```

That plays the musical scale — Do Re Mi Fa Sol La Ti Do!

Here are some note numbers:

| Note | Number |
|------|--------|
| C | 262 |
| D | 294 |
| E | 330 |
| F | 349 |
| G | 392 |
| A | 440 |
| B | 494 |
| High C | 523 |

**Your Turn:** Can you play "Mary Had a Little Lamb"? The notes are:
E D C D E E E (pause) D D D (pause) E E E

Here's a hint to get you started:

```
10 SOUND 330,0.3
20 FOR T = 1 TO 100: NEXT T
30 SOUND 294,0.3
40 FOR T = 1 TO 100: NEXT T
50 SOUND 262,0.3
```

The `FOR T = 1 TO 100: NEXT T` lines are little pauses between notes.

You can even make a siren!

```
10 FOR F = 400 TO 800 STEP 50
20   SOUND F,0.05
30   FOR T = 1 TO 20: NEXT T
40 NEXT F
50 FOR F = 800 TO 400 STEP -50
60   SOUND F,0.05
70   FOR T = 1 TO 20: NEXT T
80 NEXT F
90 GOTO 10
```

> Warning: This siren never stops! Press Ctrl+C to break out.

## Running the Sample Programs

Instead of typing programs in, you can run the ones that come with the interpreter:

```bash
swift run applesoft birthday.bas
swift run applesoft samples/fibonacci.bas
swift run applesoft samples/sinewave.bas
swift run applesoft samples/guess.bas
swift run applesoft samples/adventure.bas
swift run applesoft samples/astrochart.bas
swift run applesoft samples/graphics.bas
swift run applesoft samples/lores-art.bas
swift run applesoft samples/hires-draw.bas
swift run applesoft samples/music.bas
```

The adventure game is the most fun — you get to build the first Apple computer
by exploring 1976 California! The music demo plays Happy Birthday!

## Quick Reference Card

| Command | What It Does |
|---------|-------------|
| `PRINT "HI"` | Show text on screen |
| `PRINT X` | Show a number |
| `PRINT A;B` | Show A and B right next to each other |
| `LET X = 5` | Put 5 in variable X |
| `INPUT "? ";X` | Ask the user for a number |
| `IF X = 5 THEN ...` | Do something if X is 5 |
| `GOTO 100` | Jump to line 100 |
| `FOR I = 1 TO 10` | Start a counting loop |
| `NEXT I` | Go back to the FOR |
| `GOSUB 100` | Jump to a subroutine at line 100 |
| `RETURN` | Come back from a subroutine |
| `REM comment` | A note (computer ignores it) |
| `END` | Stop the program |
| `RUN` | Run your program |
| `LIST` | Show your program |
| `NEW` | Erase your program |
| `HOME` | Clear the screen |
| `GR` | Turn on color graphics |
| `COLOR= n` | Pick a drawing color (0-15) |
| `PLOT x,y` | Color a dot |
| `HLIN x1,x2 AT y` | Draw a line sideways |
| `VLIN y1,y2 AT x` | Draw a line up and down |
| `SCRN(x,y)` | Check what color a dot is |
| `TEXT` | Go back to text mode |
| `HGR2` | Turn on hi-res graphics |
| `HCOLOR= n` | Pick a hi-res color (0-7) |
| `HPLOT x,y` | Draw a hi-res dot |
| `HPLOT TO x,y` | Draw a line to a point |
| `BEEP` | Make a beep sound |
| `SOUND f,d` | Play a note (f=pitch, d=how long) |

## Challenge Ideas

Once you've gone through the lessons, try these:

1. **Mad Libs:** Ask for a noun, verb, and adjective, then print a funny sentence
2. **Times Tables:** Print the multiplication table for any number
3. **Countdown:** Count down from 10 to 1 and then print "BLAST OFF!" (with sound!)
4. **Quiz Game:** Ask 5 math questions and keep score
5. **Pixel Art:** Draw a smiley face or your initials using PLOT
6. **Story Generator:** Use `RND` to pick random words and make silly stories
7. **Etch A Sketch:** Use INPUT to get X and Y, then HPLOT to that spot
8. **Music Box:** Write a program that plays your favorite song
9. **Animated Art:** Use a FOR loop to draw and redraw graphics that move
10. **Color Mixer:** PLOT random colors and see what patterns appear

## A Little History

In 1976 — exactly 50 years ago — Steve Jobs and Steve Wozniak built the first Apple
computer in a garage in Los Altos, California. Wozniak wrote a BASIC interpreter for
it *by hand*, in machine code, so people could write programs just like the ones
you're writing now.

The language you're learning is the same one millions of kids learned on Apple II
computers in schools all across America in the 1980s. Your dad was one of them!

Happy programming!
