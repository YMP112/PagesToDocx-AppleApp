import Foundation
import SwiftUI
import Foundation

func availableLanguages() -> [String] {
    let paths = Bundle.main.paths(forResourcesOfType: "lproj", inDirectory: nil)
    // מסנן רק שפות מוכרות, לא "Base"
    return paths.compactMap {
        let lang = URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
        return lang.lowercased() == "base" ? nil : lang
    }
}


class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
            bundle = Bundle(path: Bundle.main.path(forResource: selectedLanguage, ofType: "lproj")!) ?? Bundle.main
            objectWillChange.send()
        }
    }
    @Published var bundle: Bundle

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        self.selectedLanguage = saved
        self.bundle = Bundle(path: Bundle.main.path(forResource: saved, ofType: "lproj")!) ?? Bundle.main
    }

    func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
