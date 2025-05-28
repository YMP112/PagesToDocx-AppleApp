import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileSelectionView: View {
    @ObservedObject var appState: AppState
    @StateObject private var converter = PagesConverter()
    @State private var showImporter = false
    @State private var isDropTarget = false
    @State private var showFolderPicker = false
    @State private var showProgress = false
    @State private var showSummary = false
    @State private var didDismiss = false
    @StateObject private var languageManager = LanguageManager.shared

    private let pagesType = UTType(filenameExtension: "pages")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // --- רקע גרדיאנט ---
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.99, green: 0.80, blue: 0.58),
                    Color(red: 0.78, green: 0.88, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

           
            // --- כפתור גלובוס ---
                        VStack {
                            HStack {
                                Spacer()
                                Menu {
                                    ForEach(availableLanguages(), id: \.self) { lang in
                                        Button {
                                            languageManager.selectedLanguage = lang
                                        } label: {
                                            HStack {
                                                Text(Locale(identifier: lang)
                                                    .localizedString(forLanguageCode: lang)?
                                                    .capitalized(with: Locale(identifier: lang)) ?? lang)
                                                if languageManager.selectedLanguage == lang {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.88))
                                            .frame(width: 44, height: 44)
                                            .shadow(radius: 3)
                                        Image(systemName: "globe")
                                            .font(.system(size: 23, weight: .medium))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 16)
                                .padding(.trailing, 16)
                            }
                            Spacer()
                        }
            
            // --- תוכן עיקרי של האפליקציה ---
            VStack(spacing: 5) {
                Image("HomeLogo")
                    .resizable()
                    .frame(width: 108, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 3)
                    .padding(.top, 38)

                Text(languageManager.localizedString("app_title"))
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                    .shadow(radius: 0.8)

                // --- כפתור בחירת קבצים ---
                Button {
                    showImporter = true
                } label: {
                    Label(languageManager.localizedString("choose_files"), systemImage: "plus.circle.fill")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.24))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: [pagesType],
                    allowsMultipleSelection: true
                ) { result in
                    if case let .success(urls) = result {
                        for url in urls where !appState.selectedFiles.contains(url) {
                            appState.selectedFiles.append(url)
                        }
                    }
                }
                .padding(.horizontal)

                // --- אזור גרירה ---
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDropTarget ? Color.accentColor : Color.gray.opacity(0.45),
                                style: StrokeStyle(lineWidth: 3, dash: [10]))
                        .background(
                            (isDropTarget ? Color.accentColor.opacity(0.09) : Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                    VStack {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 36))
                            .foregroundColor(isDropTarget ? .accentColor : .gray)
                        Text(languageManager.localizedString("drag_files"))
                            .font(.headline)
                            .foregroundColor(isDropTarget ? .accentColor : .gray)
                    }
                }
                .frame(height: 86)
                .padding(.horizontal, 12)
                .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
                    for provider in providers {
                        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                            if let data = item as? Data,
                               let url = URL(dataRepresentation: data, relativeTo: nil),
                               url.pathExtension.lowercased() == "pages" {
                                DispatchQueue.main.async {
                                    if !appState.selectedFiles.contains(url) {
                                        appState.selectedFiles.append(url)
                                    }
                                }
                            }
                        }
                    }
                    return true
                }

                // --- רשימת קבצים נבחרים ---
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        if appState.selectedFiles.isEmpty {
                            Text(languageManager.localizedString("no_files"))
                                .foregroundColor(.secondary)
                                .padding(.top, 16)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text(
                                String(
                                    format: languageManager.localizedString("files_selected"),
                                    appState.selectedFiles.count
                                )
                            )
                            .font(.subheadline).bold()
                            .foregroundColor(.accentColor)
                            .padding(.top, 3)
                            ScrollView {
                                ForEach(appState.selectedFiles, id: \.self) { url in
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.secondary)
                                        Text(url.lastPathComponent)
                                            .lineLimit(1)
                                            .help(url.path)
                                        Spacer()
                                        Button {
                                            if let idx = appState.selectedFiles.firstIndex(of: url) {
                                                appState.selectedFiles.remove(at: idx)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.borderless)
                                        .help(languageManager.localizedString("remove_file"))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .frame(maxHeight: 110)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.10), radius: 5, y: 1)
                    )
                    .frame(width: 330)
                    Spacer()
                }
                .padding(.vertical, 6)

                // --- הגדרות יעד (בין רשימת קבצים לכפתור) ---
                if !appState.selectedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker(languageManager.localizedString("after_conversion"), selection: $appState.destinationAction) {
                            Text(languageManager.localizedString("convert_and_save")).tag(AppState.DestinationAction.save)
                            Text(languageManager.localizedString("convert_and_share")).tag(AppState.DestinationAction.share)
                        }
                        .pickerStyle(.radioGroup)
                        .padding(.bottom, 4)

                        if appState.destinationAction == .save {
                            HStack {
                                Button(languageManager.localizedString("pick_folder")) { showFolderPicker = true }
                                if let f = appState.targetFolder {
                                    Text(f.path).lineLimit(1).truncationMode(.middle)
                                }
                            }
                        }

                        Toggle(languageManager.localizedString("use_defaults"), isOn: $appState.rememberDefaults)
                    }
                    .padding(.horizontal, 14)
                    .fileImporter(isPresented: $showFolderPicker,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false) { result in
                        if case let .success(urls) = result, let folder = urls.first {
                            appState.targetFolder = folder
                        }
                    }
                }

                // --- כפתור המרה דינאמי במרכז ---
                if !appState.selectedFiles.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            let viewForShare = NSApplication.shared.keyWindow?.contentView
                            converter.convert(appState.selectedFiles,
                                              saveTo: appState.targetFolder,
                                              share: appState.destinationAction == .share,
                                              shareFromView: viewForShare)
                            showProgress = true
                        } label: {
                            HStack {
                                Image(systemName: appState.destinationAction == .save ? "arrow.down.circle.fill" : "paperplane.fill")
                                Text(
                                    appState.destinationAction == .save ?
                                    languageManager.localizedString("convert_and_save") :
                                    languageManager.localizedString("convert_and_share")
                                )
                                .font(.title2).bold()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 34)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.88),
                                        Color.orange.opacity(0.88)
                                    ]),
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(17)
                            .shadow(radius: 6)
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.destinationAction == .save && appState.targetFolder == nil)
                        Spacer()
                    }
                    .padding(.top, 12)
                } else {
                    Spacer(minLength: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)

            // --- Sheet התקדמות ---
            .sheet(isPresented: $showProgress) {
                VStack(spacing: 22) {
                    Text(languageManager.localizedString("processing")).font(.title2).bold()
                    if let cur = converter.currentFile {
                        Text(cur.lastPathComponent).font(.subheadline)
                    }
                    ProgressView(value: converter.progress)
                        .frame(width: 300)
                        .padding(.vertical, 10)
                    Text(
                        String(
                            format: languageManager.localizedString("completed_percent"),
                            Int(converter.progress * 100)
                        )
                    )
                    .font(.caption).foregroundColor(.secondary)

                    if converter.progress == 1 {
                        ProgressView(languageManager.localizedString("show_summary"))
                            .padding(.top, 16)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showProgress = false
                                    showSummary  = true
                                }
                            }
                    } else {
                        Button(languageManager.localizedString("cancel")) {
                            showProgress = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .frame(width: 400)
            }

            // --- Sheet סיכום ---
            .sheet(isPresented: $showSummary, onDismiss: {
                let failedSet = Set(converter.errors.keys)
                appState.selectedFiles.removeAll { !failedSet.contains($0) }
                if !didDismiss {
                    didDismiss = true
                }
            }) {
                ConversionSummaryView(
                    successFiles: converter.successFiles,
                    failedFiles: converter.errors,
                    targetFolder: appState.targetFolder ?? .homeDirectory,
                    shouldShare: appState.destinationAction == .share
                )
            }
        }
    }
}
