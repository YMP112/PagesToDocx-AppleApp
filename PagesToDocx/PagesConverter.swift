import Foundation
import Combine
import AppKit

final class PagesConverter: ObservableObject {
    @Published var progress: Double = 0
    @Published var currentFile: URL? = nil
    @Published var errors: [URL: String] = [:]
    @Published var successFiles: [URL] = []
    @Published var isFinished: Bool = false

    // ---- כאן הדְּלִיגֵּייט הפנימי ----
    private class SharingPickerDelegate: NSObject, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
        private let onEnd: () -> Void
        init(onEnd: @escaping () -> Void) {
            self.onEnd = onEnd
        }
        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            service?.delegate = self
        }
        func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
            onEnd()
        }
        func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
            onEnd()
        }
        func sharingService(_ sharingService: NSSharingService, didCancelSharingItems items: [Any]) {
            onEnd()
        }
    }
    private var currentDelegate: AnyObject? // לשמור על הדליגייט בזיכרון עד סוף השיתוף

    func convert(_ files: [URL],
                 saveTo folder: URL?,
                 share: Bool,
                 shareFromView: NSView?) {

        guard !files.isEmpty else { return }
        errors.removeAll(); successFiles.removeAll()
        progress = 0; isFinished = false

        let targetDir: URL
        if share {
            targetDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("AutoSaveTemp", isDirectory: true)
            try? FileManager.default.createDirectory(at: targetDir,
                                                    withIntermediateDirectories: true)
        } else {
            guard let folder = folder else { print("No target folder"); return }
            targetDir = folder
        }

        DispatchQueue.global(qos: .userInitiated).async {
            for (idx, src) in files.enumerated() {
                DispatchQueue.main.async {
                    self.currentFile = src
                    self.progress = Double(idx) / Double(files.count)
                }

                let ok = self.exportPagesToDocx(src, to: targetDir)
                DispatchQueue.main.async {
                    if ok {
                        let convertedFileName = src.deletingPathExtension().lastPathComponent + ".docx"
                        self.successFiles.append(targetDir.appendingPathComponent(convertedFileName))
                    } else {
                        self.errors[src] = "Pages export failed for \(src.lastPathComponent)"
                    }
                }
            }
            DispatchQueue.main.async {
                self.progress = 1
                self.currentFile = nil
                self.isFinished = true
                // שים לב – אין כאן קריאה ל-shareFiles!
            }
        }
    }

    private func exportPagesToDocx(_ src: URL, to dir: URL) -> Bool {
        func esc(_ p: String) -> String {
            p.replacingOccurrences(of: "\"", with: "\\\"")
        }

        let dstPathString = dir.appendingPathComponent(src.deletingPathExtension().lastPathComponent).appendingPathExtension("docx").path

        let tempScriptFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".applescript")
        let scriptContent = """
        try
            set srcFilePath to POSIX path of "\(esc(src.path))"
            set dstFilePath to POSIX path of "\(esc(dstPathString))"
            set fileExists to (do shell script "test -f " & quoted form of dstFilePath & " && echo true || echo false") as boolean
            if fileExists then
                do shell script "rm " & quoted form of dstFilePath
                delay 0.1
            end if
            tell application "Pages"
                activate
                repeat 10 times
                    delay 1
                    try
                        set appVersion to version of it
                        exit repeat
                    on error
                    end try
                end repeat
                if not (it is running) then
                    error "Pages application could not be launched or is not responding."
                end if
                set theDoc to open (POSIX file srcFilePath as alias)
                repeat 20 times
                    delay 0.25
                    try
                        if exists theDoc then exit repeat
                    on error
                    end try
                end repeat
                if not (exists theDoc) then
                    error "Failed to open Pages document within expected time."
                end if
                export theDoc to (POSIX file dstFilePath) as Microsoft Word
                close theDoc saving no
            end tell
            set fileExists to (do shell script "test -f " & quoted form of dstFilePath & " && echo true || echo false") as boolean
            if fileExists then
                return "OK"
            else
                error "ההמרה הסתיימה ללא שגיאה, אך קובץ ה-DOCX לא נמצא בנתיב: " & dstFilePath
            end if
        on error errMsg number errNum
            return errMsg
        end try
        """

        do {
            try scriptContent.write(to: tempScriptFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write temporary AppleScript file: \(error.localizedDescription)")
            return false
        }

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments  = [tempScriptFile.path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = pipe

        do {
            try task.run()
        } catch {
            print("Failed to launch osascript: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempScriptFile)
            return false
        }

        task.waitUntilExit()

        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                         encoding: .utf8) ?? ""
        print("AppleScript-out:", out.trimmingCharacters(in: .whitespacesAndNewlines),
              "| status:", task.terminationStatus)

        try? FileManager.default.removeItem(at: tempScriptFile)

        return out.contains("OK") &&
               FileManager.default.fileExists(atPath: dstPathString)
    }

    /// קריאה מתוך ה־View – לשיתוף הקבצים
    func shareFiles(_ files: [URL], from view: NSView, completion: @escaping () -> Void) {
        let sharingPicker = NSSharingServicePicker(items: files)
        let delegate = SharingPickerDelegate {
            // מחיקה אחרי השיתוף
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
            completion()
        }
        sharingPicker.delegate = delegate
        sharingPicker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        // שומרים דליגייט בזיכרון עד הסוף (חשוב!)
        currentDelegate = delegate
    }
}
