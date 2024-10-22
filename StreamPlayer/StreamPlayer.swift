//
//  StreamPlayer.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import AVKit

struct StreamPlayer: UIViewControllerRepresentable {
    
    var player: AVPlayer
        
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
