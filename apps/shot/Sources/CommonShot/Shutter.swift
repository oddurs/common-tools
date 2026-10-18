import AudioToolbox
import Foundation
import OSLog

/// The sound macOS makes for its own screenshots, played as a system sound. A system sound is a user
/// interface sound unless told otherwise, so it plays only while "Play user interface sound effects" is
/// on, at the alert volume, through the device chosen for sound effects: every setting the system's own
/// screenshots follow, without reading any of them.
@MainActor
final class Shutter {
    private static let file = URL(
        filePath:
            "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"
    )
    private static let log = Logger(subsystem: "com.oddurs.commonshot", category: "sound")
    private var sound: SystemSoundID = 0

    init() {
        let status = AudioServicesCreateSystemSoundID(Self.file as CFURL, &sound)
        if status != noErr {
            // A macOS that moved or dropped the file: shots still work, silently, and the log says why.
            Self.log.error("the screen capture sound couldn't be loaded (\(status))")
            sound = 0
        }
    }

    func play() {
        guard sound != 0 else { return }
        AudioServicesPlaySystemSound(sound)
    }
}
