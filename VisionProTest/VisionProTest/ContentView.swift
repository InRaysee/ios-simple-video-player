//
//  ContentView.swift
//  VisionProTest
//
//  Created by Feng Fangzheng on 2024/10/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    // 1.
    @State var showImmersiveSpace = false
    
    // 2.
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    // 3.
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        
        // 4.
        Toggle(showImmersiveSpace ? "Back to Reality" : "Show Immersive space", isOn: $showImmersiveSpace)
            .toggleStyle(.button)
            
            // 5.
            .onChange(of: showImmersiveSpace) { _, newValue in
                // 6.
                Task {
                    if newValue {
                        await openImmersiveSpace(id: "VideoImmersiveView")
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
            // 7.
            .controlSize(.extraLarge)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
