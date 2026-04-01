# Learn BASIC! A Tutorial for Beginners

Hey! Welcome to Applesoft BASIC. This is the same programming language kids used on Apple II computers starting in 1977 — almost 50 years ago!

You're going to write your very own computer programs. Let's go!

## Getting Started

First, open the Terminal app on your Mac. Then type:

```
cd /path/to/ApplesoftBASIC
swift run applesoft
```

You should see something like:

```
APPLESOFT BASIC INTERPRETER v0.1.0
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
- `*` means multiply
- `/` means divide

**Your Turn:** Can you make the computer figure out how many hours are in a week? (Hint: 24 hours in a day, 7 days in a week)

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

**Your Turn:** Can you make it ask for your age too, and then tell you how old you'll be in 10 years?

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

**WARNING:** This program never stops! Press Ctrl+C to break out of it.

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

**Your Turn:** Can you make it go the other way? (Hint: `FOR ROW = 5 TO 1 STEP -1`)

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

## Running the Sample Programs

Instead of typing programs in, you can run the ones that come with the interpreter:

```bash
swift run applesoft birthday.bas
swift run applesoft samples/fibonacci.bas
swift run applesoft samples/sinewave.bas
swift run applesoft samples/guess.bas
swift run applesoft samples/adventure.bas
swift run applesoft samples/astrochart.bas
```

The adventure game is the most fun — you get to build the first Apple computer by exploring 1976 California!

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

## Challenge Ideas

Once you've gone through the lessons, try these:

1. **Mad Libs:** Ask for a noun, verb, and adjective, then print a funny sentence
2. **Times Tables:** Print the multiplication table for any number
3. **Countdown:** Count down from 10 to 1 and then print "BLAST OFF!"
4. **Quiz Game:** Ask 5 math questions and keep score
5. **ASCII Art:** Draw a house, a rocket, or your name out of `*` characters
6. **Story Generator:** Use `RND` to pick random words and make silly stories

## A Little History

In 1976 — exactly 50 years ago — Steve Jobs and Steve Wozniak built the first Apple computer in a garage in Los Altos, California. Wozniak wrote a BASIC interpreter for it *by hand*, in machine code, so people could write programs just like the ones you're writing now.

The language you're learning is the same one millions of kids learned on Apple II computers in schools all across America in the 1980s. Your dad was one of them!

Happy programming!
