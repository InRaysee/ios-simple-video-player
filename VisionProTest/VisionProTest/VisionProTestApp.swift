//
//  VisionProTestApp.swift
//  VisionProTest
//
//  Created by Feng Fangzheng on 2024/10/25.
//

import SwiftUI

@main
struct VisionProTestApp: App {
    // 1.
    @State private var currentStyle: ImmersionStyle = .full
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 2.
        ImmersiveSpace(id: "VideoImmersiveView") {
            ImmersiveView()
        }
        // 3.
        .immersionStyle(selection: $currentStyle, in: .full)
    }
}
