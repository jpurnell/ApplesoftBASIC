/// A single lexical token from Applesoft BASIC source code.
public enum Token: Sendable, Equatable {
    /// A line number at the start of a program line.
    case lineNumber(Int)

    /// A reserved keyword (PRINT, GOTO, etc.).
    case keyword(Keyword)

    /// A variable name (A, X1, NAME, N$).
    case identifier(String)

    /// A quoted string literal ("HELLO WORLD").
    case stringLiteral(String)

    /// A numeric literal (42, 3.14, 1E10).
    case numberLiteral(Double)

    /// An arithmetic or comparison operator.
    case op(Operator)

    /// A comma separator.
    case comma

    /// A semicolon separator.
    case semicolon

    /// A colon (statement separator on same line).
    case colon

    /// A left parenthesis.
    case leftParen

    /// A right parenthesis.
    case rightParen

    /// End of a logical line.
    case endOfLine
}

/// Reserved keywords in Applesoft BASIC.
public enum Keyword: String, Sendable, CaseIterable {
    // Flow control
    case GOTO, GOSUB, RETURN, IF, THEN, FOR, TO, STEP, NEXT
    case ON, END, STOP

    // I/O
    case PRINT, INPUT, GET

    // Data
    case LET, DIM, DATA, READ, RESTORE, DEF, FN

    // Screen
    case HOME, HTAB, VTAB, INVERSE, NORMAL, FLASH
    case TEXT

    // Graphics
    case GR, COLOR, PLOT, HLIN, VLIN, AT, SCRN
    case HGR, HGR2, HCOLOR, HPLOT, HSCRN

    // Sound
    case BEEP, SOUND

    // Commands
    // LIVE: RUN, LIST, NEW, DEL are matched via Keyword(rawValue:) in the lexer for BASIC source containing these commands.
    case RUN, LIST, NEW, DEL, CLR
    case REM

    // Logical
    case AND, OR, NOT

    // Built-in functions
    case ABS, ATN, COS, EXP, INT, LOG, RND, SGN, SIN, SQR, TAN
    case ASC, CHR, LEFT, RIGHT, MID, LEN, STR, VAL
    case TAB, SPC, POS, PEEK, FRE
}

/// Operators in Applesoft BASIC.
public enum Operator: String, Sendable {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
    case equal = "="
    case notEqual = "<>"
    case lessThan = "<"
    case greaterThan = ">"
    case lessThanOrEqual = "<="
    case greaterThanOrEqual = ">="
}
