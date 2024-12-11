//
//  ContentView.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            TabView(selection: $selectedTab) {
                LocalMediaPage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Local", systemImage: "play.circle")
                    }
                    .tag(0)
                
                NetworkSourcePage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Network", systemImage: "livephoto.play")
                    }
                    .tag(1)
                
                rtpTestView()
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Chat", systemImage: "livephoto")
                    }
                    .tag(2)
            }
            .onAppear {
                UITabBar.appearance().backgroundColor = .white
                UITabBar.appearance().unselectedItemTintColor = .gray
                UITabBar.appearance().tintColor = .tintColor
            }
        }
        .statusBar(hidden: false)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
