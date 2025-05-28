//
//  PagesToDocxApp.swift
//  PagesToDocx
//
//  Created by yaakov m. pines on 27/5/25.
//

import SwiftUI

@main
struct PagesToDocxApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            FileSelectionView(appState: appState)
        }
    }
}
