//
//  StreamPlayerApp.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

@main
struct StreamPlayerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocalMedia.self,
            NetworkSource.self,
            WebrtcMedia.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(CGSize(width: 900, height: 1950))
    }
}
