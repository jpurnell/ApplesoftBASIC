# Changelog

All notable changes to ApplesoftBASIC are documented in this file.

## [Unreleased]

### Fixed
- Numbers that cannot be an `Int` no longer stop the process. `GOTO 1E300`,
  `LEFT$(A$,1E300)`, `CHR$(X)` with `X` infinite or NaN, array subscripts, `DIM`
  sizes and every other integer-valued argument now raise `?ILLEGAL QUANTITY
  ERROR`. All of them convert through one `BuiltInFunctions.truncatedInt(_:)`,
  which truncates toward zero as before and throws where `Int(_:)` would trap.
- `MID$` with a negative length raises `?ILLEGAL QUANTITY ERROR` instead of
  trapping on an inverted range, and a huge start plus a huge length no longer
  overflows while computing the end position.
- `AudioSoundHandler.playTone` plays nothing for a NaN frequency or duration
  rather than clamping it to 20 Hz / 1 ms — a clamp was deciding what an absent
  value meant. The `SOUND` statement already rejected NaN before reaching it.
- The `ApplesoftBASICLib.docc` catalogue is back in the library target. The
  0.1.0 exclusion rested on a wrong premise: swift-docc-plugin finds a catalogue
  through the target's source files, so excluding it meant DocC received no
  articles and their links were never checked. SwiftPM at tools 6.2 handles the
  catalogue without the "unhandled files" warning the exclusion was added for.
- `SpySoundHandler` in `SoundTests` carries the `// Justification:` comment the
  ConcurrencyAuditor requires for `@unchecked Sendable` — the test spy is
  single-task per test, so the annotation is safe; the gate had stopped at the
  concurrency checker over the missing comment.

## [0.1.1] - 2026-08-12

### Added
- `OutputHandlerTests` pins the whole contract of `CapturedOutput.lines` — CRLF,
  bare CR, interior empty lines, trailing partial line, empty buffer, and
  `clearScreen` — rather than only the repaired half. 171 tests total.

### Fixed
- `CapturedOutput.lines` splits on any newline (`whereSeparator: \.isNewline`)
  rather than the `"\n"` literal. `"\r\n"` is one `Character` in Swift, so a
  buffer containing CRLF came back as a single unsplit line; the trailing-newline
  check now uses `last?.isNewline` for the same reason.
- The `ApplesoftBASICLib` DocC article's examples pass the required `rng:`
  argument to `Interpreter.init`, and the "Testable I/O" example no longer
  redeclares `interpreter` — the two blocks are read as one program.

### Changed
- Tests draw `RND` values from `SwiftDeterminism`'s `SplitMix64` rather than a
  local `SeededGenerator`, removing this project's copy of an algorithm the
  portfolio had written four times. The two implementations are arithmetically
  identical — same increment, shifts and multipliers — so every seeded
  expectation is unchanged, and the suite passes without an edit to any test
  assertion.

### Removed
- `Tests/ApplesoftBASICTests/SeededGenerator.swift`, superseded by the package.

## [0.1.0] - 2026-07-06

### Fixed
- Excluded the `ApplesoftBASICLib.docc` catalog from the library target's
  resource handling to silence SwiftPM's "unhandled files" build warning. The
  Swift-DocC plugin reads the catalog directly from source, so documentation
  generation is unaffected.

### Added
- Applesoft BASIC interpreter with lexer, parser, and runtime
- Lo-res graphics (GR, COLOR, PLOT, HLIN, VLIN, SCRN)
- Hi-res graphics (HGR, HGR2, HCOLOR, HPLOT, HSCRN) with Unicode braille rendering
- Sound support (BEEP, SOUND) via AVAudioEngine with blocking playback
- REPL with editline history and line editing (macOS)
- File execution mode (`applesoft filename.bas`)
- iOS platform support (library only)
- DocC documentation with tutorial and language reference
- 164 tests covering lexer, parser, interpreter, graphics, and sound
- 12 sample BASIC programs including Steve Jobs' 1975 Atari horoscope
- Smart quote support in string literals
- Comprehensive error messages matching original Applesoft style

### Supported Statements
- Flow control: GOTO, GOSUB/RETURN, IF...THEN, FOR...NEXT, ON...GOTO/GOSUB, END, STOP
- I/O: PRINT, INPUT, GET, HOME, HTAB, VTAB
- Data: LET, DIM, DATA, READ, RESTORE, DEF FN
- Graphics: GR, COLOR, PLOT, HLIN, VLIN, SCRN, HGR, HGR2, HCOLOR, HPLOT, HSCRN, TEXT
- Sound: BEEP, SOUND
- Display: INVERSE, NORMAL, FLASH
- Built-in functions: ABS, ATN, COS, EXP, INT, LOG, RND, SGN, SIN, SQR, TAN, ASC, CHR$, LEFT$, RIGHT$, MID$, LEN, STR$, VAL, TAB, SPC, POS, PEEK, FRE
