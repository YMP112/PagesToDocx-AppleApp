import Foundation
import SwiftUI

class AppState: ObservableObject {
    enum DestinationAction: String, CaseIterable, Identifiable {
        case save
        case share
        var id: String { self.rawValue }
    }

    @Published var selectedFiles: [URL] = []
    @Published var targetFolder: URL? = nil
    @Published var destinationAction: DestinationAction = .save
    @Published var rememberDefaults: Bool = false
}
