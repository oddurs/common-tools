import Darwin
import Foundation

/// One Welcome window at a time across the family. Installing several apps at once starts them
/// together, and each would otherwise open its window in the same place, stacked.
///
/// The lock is an exclusive `flock` on a file that names the owning process by its pid. The kernel
/// drops the lock when that process exits however it exits, so an app that crashed with its window
/// open never leaves the others waiting.
public final class WelcomeLock {
    public static let defaultURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Application Support/Common Tools/welcome.lock")

    let url: URL
    private var descriptor: Int32 = -1

    public init(url: URL = WelcomeLock.defaultURL) {
        self.url = url
    }

    deinit { release() }

    public var isHeld: Bool { descriptor >= 0 }

    /// Takes the lock if no other process holds it, and writes this process's pid into the file.
    /// Returns false, without waiting, when another process has it.
    public func tryAcquire() throws -> Bool {
        if isHeld { return true }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(url.path, O_RDWR | O_CREAT | O_CLOEXEC, 0o644)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            let code = errno
            close(fd)
            if code == EWOULDBLOCK { return false }
            throw POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
        }
        let pid = Data("\(getpid())\n".utf8)
        ftruncate(fd, 0)
        _ = pid.withUnsafeBytes { pwrite(fd, $0.baseAddress, $0.count, 0) }
        descriptor = fd
        return true
    }

    /// The pid written by whoever took the lock last; it may have gone since.
    public var owner: Int32? {
        (try? String(contentsOf: url, encoding: .utf8)).flatMap {
            Int32($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    public func release() {
        guard isHeld else { return }
        flock(descriptor, LOCK_UN)
        close(descriptor)
        descriptor = -1
    }
}
