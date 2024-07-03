//
//  ContentView.swift
//  VideoPlayer
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
                MediaPage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Local", systemImage: "record.circle")
                    }
                    .tag(0)
                
                NetworkSourcePage(size: size, safeArea: safeArea)
                    .preferredColorScheme(.none)
                    .tabItem {
                        Label("Network", systemImage: "livephoto")
                    }
                    .tag(1)
            }
            .onAppear {
                UITabBar.appearance().backgroundColor = .white
            }
            

        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
