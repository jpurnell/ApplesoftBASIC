/// Apple II color palettes for lo-res and hi-res graphics.
public enum AppleIIColors {

    /// An RGB color value.
    public struct RGB: Sendable, Equatable {
        /// Red component (0-255).
        public let r: UInt8
        /// Green component (0-255).
        public let g: UInt8
        /// Blue component (0-255).
        public let b: UInt8
    }

    /// Lo-res 16-color palette (composite NTSC approximation).
    public static let loRes: [RGB] = [
        RGB(r: 0,   g: 0,   b: 0),     // 0:  Black
        RGB(r: 227, g: 30,  b: 96),    // 1:  Red
        RGB(r: 96,  g: 78,  b: 189),   // 2:  Dark Blue
        RGB(r: 255, g: 68,  b: 253),   // 3:  Pink
        RGB(r: 0,   g: 163, b: 96),    // 4:  Dark Green
        RGB(r: 156, g: 156, b: 156),   // 5:  Gray 1
        RGB(r: 20,  g: 207, b: 253),   // 6:  Medium Blue
        RGB(r: 208, g: 195, b: 255),   // 7:  Light Blue
        RGB(r: 96,  g: 114, b: 3),     // 8:  Brown
        RGB(r: 255, g: 106, b: 60),    // 9:  Orange
        RGB(r: 156, g: 156, b: 156),   // 10: Gray 2
        RGB(r: 255, g: 160, b: 208),   // 11: Pink/Apricot
        RGB(r: 20,  g: 245, b: 60),    // 12: Light Green
        RGB(r: 208, g: 221, b: 141),   // 13: Yellow
        RGB(r: 114, g: 255, b: 208),   // 14: Aqua
        RGB(r: 255, g: 255, b: 255),   // 15: White
    ]

    /// Hi-res 8-color palette.
    public static let hiRes: [RGB] = [
        RGB(r: 0,   g: 0,   b: 0),     // 0: Black
        RGB(r: 20,  g: 245, b: 60),    // 1: Green
        RGB(r: 255, g: 68,  b: 253),   // 2: Purple
        RGB(r: 255, g: 255, b: 255),   // 3: White
        RGB(r: 0,   g: 0,   b: 0),     // 4: Black (high bit)
        RGB(r: 255, g: 106, b: 60),    // 5: Orange
        RGB(r: 20,  g: 207, b: 253),   // 6: Blue
        RGB(r: 255, g: 255, b: 255),   // 7: White (high bit)
    ]
}
