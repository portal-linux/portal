import Darwin
import Testing
@testable import PortalCore

struct RawTerminalModeTests {
    @Test func clearsEchoAndCanonicalFlags() {
        var original = termios()
        original.c_lflag = tcflag_t(ECHO | ICANON | ISIG | IEXTEN)

        let raw = RawTerminalMode.makeRaw(from: original)

        #expect(raw.c_lflag & tcflag_t(ECHO) == 0)
        #expect(raw.c_lflag & tcflag_t(ICANON) == 0)
        #expect(raw.c_lflag & tcflag_t(ISIG) == 0)
        #expect(raw.c_lflag & tcflag_t(IEXTEN) == 0)
    }

    @Test func clearsInputTranslationFlags() {
        var original = termios()
        original.c_iflag = tcflag_t(ICRNL | IXON | BRKINT | INPCK | ISTRIP)

        let raw = RawTerminalMode.makeRaw(from: original)

        #expect(raw.c_iflag & tcflag_t(ICRNL) == 0)
        #expect(raw.c_iflag & tcflag_t(IXON) == 0)
    }

    @Test func leavesUnrelatedFieldsUntouched() {
        var original = termios()
        original.c_cflag = tcflag_t(CREAD)

        let raw = RawTerminalMode.makeRaw(from: original)

        #expect(raw.c_cflag & tcflag_t(CREAD) != 0)
    }
}
