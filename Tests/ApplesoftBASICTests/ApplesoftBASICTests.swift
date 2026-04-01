import Testing
@testable import ApplesoftBASICLib

@Suite("ApplesoftBASIC Library")
struct ApplesoftBASICLibTests {

    @Test("Library version is set")
    func versionExists() {
        #expect(!ApplesoftBASICLib.version.isEmpty)
    }
}
