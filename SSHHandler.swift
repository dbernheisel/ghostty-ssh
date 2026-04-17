import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
            NSApplication.shared.terminate(nil)
            return
        }

        // Parse ssh://[user@]host[:port]
        var raw = urlString
        if raw.hasPrefix("ssh://") {
            raw = String(raw.dropFirst(6))
        }
        if raw.hasSuffix("/") {
            raw = String(raw.dropLast())
        }

        var user: String? = nil
        var host: String
        var port: String? = nil

        if let atIndex = raw.firstIndex(of: "@") {
            user = String(raw[raw.startIndex..<atIndex])
            raw = String(raw[raw.index(after: atIndex)...])
        }

        if let colonIndex = raw.firstIndex(of: ":") {
            host = String(raw[raw.startIndex..<colonIndex])
            port = String(raw[raw.index(after: colonIndex)...])
        } else {
            host = raw
        }

        // Validate
        let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        guard !host.isEmpty, host.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
            showAlert("Invalid host in SSH URL")
            return
        }
        if let u = user, !u.unicodeScalars.allSatisfy({ validChars.contains($0) }) {
            showAlert("Invalid username in SSH URL")
            return
        }
        if let p = port, !p.allSatisfy(\.isNumber) {
            showAlert("Invalid port in SSH URL")
            return
        }

        // Build command
        var cmd = "ssh"
        if let p = port { cmd += " -p \(p)" }
        if let u = user {
            cmd += " \(u)@\(host)"
        } else {
            cmd += " \(host)"
        }

        // Feed to Ghostty via its native AppleScript API
        let script = """
        tell application "Ghostty"
            activate
            set t to new tab in front window
            set term to focused terminal of t
            input text "\(cmd)" & return to term
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NSApplication.shared.terminate(nil)
        }
    }

    func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "SSH Handler Error"
        alert.informativeText = message
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
