import SwiftUI
import AppKit

struct ConversionSummaryView: View {
    let successFiles: [URL]
    let failedFiles: [URL: String]
    let targetFolder: URL
    let shouldShare: Bool   // ← חובה להוסיף בפרופס

    @Environment(\.dismiss) private var dismiss
    @State private var isSharing = false
    @State private var shareStatus: String?
    @State private var shareDisabled = false
    // נדרש לקבל את ה־PagesConverter הראשי
    @StateObject private var converter = PagesConverter()
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(NSLocalizedString("summary_title", comment: ""))
                .font(.title2).bold()
                .padding(.top)

            HStack {
                Text(String(format: NSLocalizedString("success_files", comment: ""), successFiles.count))
                    .foregroundColor(.green)
                Text(" | " + String(format: NSLocalizedString("failed_files", comment: ""), failedFiles.count))
                    .foregroundColor(failedFiles.isEmpty ? .gray : .red)
                Text(String(format: NSLocalizedString("total_files", comment: ""), successFiles.count + failedFiles.count))
                    .font(.subheadline)
            }
            .padding(.horizontal, 6)

            List {
                if !successFiles.isEmpty {
                    Section(header: Label(NSLocalizedString("success_section", comment: ""), systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.headline)
                    ) {
                        ForEach(successFiles, id: \.self) { url in
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text(url.lastPathComponent)
                                    .fontWeight(.semibold)
                                    .help(url.path)
                                Spacer()
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                } label: {
                                    Label(NSLocalizedString("open_target_folder", comment: ""), systemImage: "folder")

                                }
                                .buttonStyle(.borderless)
                                .disabled(shouldShare)
                            }
                        }
                    }
                }
                if !failedFiles.isEmpty {
                    Section(header: Label(NSLocalizedString("failed_section", comment: ""), systemImage: "xmark.octagon")
                        .foregroundColor(.red)
                        .font(.headline)
                    ) {
                        ForEach(failedFiles.sorted(by: { $0.key.path < $1.key.path }), id: \.key) { file, error in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundColor(.red)
                                    Text(file.lastPathComponent)
                                        .fontWeight(.bold)
                                        .help(file.path)
                                    Spacer()
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(error, forType: .string)
                                    } label: {
                                        Image(systemName: "doc.on.clipboard")
                                    }
                                    .buttonStyle(.borderless)
                                    .help(NSLocalizedString("copy_error", comment: ""))
                                }
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: min(360, CGFloat((successFiles.count + failedFiles.count) * 48 + 64)))

            HStack(spacing: 16) {
                if shouldShare && !successFiles.isEmpty {
                    
                    Button(NSLocalizedString("send_files", comment: "")) {
                        shareDisabled = true
                        isSharing = true
                        shareFiles()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(shareDisabled)
                } else {
                    Button(NSLocalizedString("open_target_folder", comment: "")) {
                        NSWorkspace.shared.open(targetFolder)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
                Button(NSLocalizedString("finish", comment: "")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if let shareStatus = shareStatus {
                Text(shareStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
            }
        }
        .padding()
        .frame(width: 490)
    }

    private func shareFiles() {
        guard let keyWindow = NSApplication.shared.keyWindow else {
            shareStatus = NSLocalizedString("no_window_for_share", comment: "")
            isSharing = false
            return
        }
        converter.shareFiles(successFiles, from: keyWindow.contentView ?? NSView()) {
            shareStatus = NSLocalizedString("files_shared_deleted", comment: "")
            isSharing = false
        }
    }
}
