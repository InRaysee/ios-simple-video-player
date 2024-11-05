//
//  ImmersiveView.swift
//  VisionProTest
//
//  Created by Feng Fangzheng on 2024/10/25.
//

import SwiftUI

// importing the frameworks
import RealityKit
import AVFoundation

struct ImmersiveView: View {
    var body: some View {
        // 1.
        RealityView { content in
            // 2.
            guard let skyBox = generateSkyBox() else { return }
            
            // 3.
            content.add(skyBox)
        }
    }
    
    func generateVideoMaterial() -> VideoMaterial? {
        
        // 1.
        guard let url = Bundle.main.url(forResource: "erp20231025", withExtension: "mp4") else {
            print("Error loading video")
            return nil
        }
        
        // 2.
        let avPlayer = AVPlayer(url: url)
        
        // 3.
        let videoMaterial = VideoMaterial(avPlayer: avPlayer)

        // 4.
        avPlayer.play()

        // 5.
        return videoMaterial
    }
    
    func generateSkyBox() -> Entity? {
        // 1.
        let skyBoxMesh = MeshResource.generateSphere(radius: 1000)

        // 2.
        guard let videoMaterial = generateVideoMaterial() else {
            return nil
        }

        // 3.
        let skyBoxEntity = ModelEntity(mesh: skyBoxMesh, materials: [videoMaterial])

        // 4.
        skyBoxEntity.scale *= .init(x: -1, y: 1, z: 1)

        // 5.
        return skyBoxEntity
    }
}

#Preview {
    ImmersiveView()
}
