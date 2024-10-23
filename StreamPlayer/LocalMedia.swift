//
//  LocalMedia.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import Foundation
import SwiftData

@Model
class LocalMedia {
    var title: String
    var mediaURL: String
    
    init(title: String, mediaURL: String) {
        self.title = title
        self.mediaURL = mediaURL
    }
    
    static let sampleData = [
        LocalMedia(title: "Apple", mediaURL: "/Users/fengfangzheng/sites/ios-simple-video-player/apple.mp4"),
        LocalMedia(title: "Tokyo", mediaURL: "/Users/fengfangzheng/sites/ios-simple-video-player/tokyo.mp4")
    ]
}
