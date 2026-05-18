# ApplesoftBASIC

A faithful Applesoft BASIC interpreter written in modern Swift, celebrating Apple's 50th birthday.

I first used an Apple IIe in an afterschool program when I was 7. I learned the rudiments of BASIC and wrote a bunch of spaghetti GOTOs.
I woke up this morning and thought it'd be nice to write a little "happy birthday" BASIC program and throw it up on social media to celebrate Apple's 50th. Quick, easy, fun.
Then I wanted to verify that it worked, but didn't want to do it with a GUI program...I needed to see it in green on black! So, I got a little more ambitious, and decided I'd make a BASIC interpreter in modern Swift.

Here it is, along with a few sample programs, including [Steve Jobs' 1975 Atari Horoscope Program](https://blog.adafruit.com/2026/01/06/we-recreated-steve-jobss-1975-atari-horoscope-program-and-you-can-run-it/) that Adafruit recreated earlier this year.

I recommend using the [Apple II font](https://www.kreativekorp.com/software/fonts/apple2/) to keep it real.

## Features

- Interactive REPL with line editing and history
- File execution (`applesoft filename.bas`)
- Lo-res and hi-res graphics rendered as Unicode in the terminal
- Sound via AVAudioEngine (BEEP and SOUND statements)
- 50+ Applesoft BASIC statements, functions, and operators
- Swift 6 strict concurrency compliance

## Requirements

- macOS 14+ / iOS 17+
- Swift 6.2+

## Usage

```bash
# Build
swift build

# Run the REPL
swift run ApplesoftBASIC

# Run a program file
swift run ApplesoftBASIC Samples/guess.bas
```

## Sample Programs

The `Samples/` directory includes several programs to try:

| Program | Description |
|---------|-------------|
| `guess.bas` | Number guessing game |
| `fibonacci.bas` | Fibonacci sequence |
| `sinewave.bas` | Sine wave plot |
| `graphics.bas` | Lo-res color demo |
| `hires-draw.bas` | Hi-res drawing |
| `music.bas` | Sound demo |
| `astrochart.bas` | Steve Jobs' 1975 Atari horoscope |
| `adventure.bas` | Text adventure game |

## Documentation

The package includes a **Tutorial** and **Language Reference** in DocC -- open `Package.swift` in Xcode and build documentation (Product > Build Documentation) to browse them. The tutorial is written so my 7-year-old can follow along.

## Library

`ApplesoftBASICLib` is available as a Swift package library for embedding the interpreter in your own projects:

```swift
import ApplesoftBASICLib

var lexer = Lexer(source: "10 PRINT \"HELLO WORLD\"")
let tokens = try lexer.tokenize()
var parser = Parser(tokens: tokens)
let program = try parser.parse()
let interpreter = Interpreter(program: program)
try interpreter.run()
```

## License

MIT
