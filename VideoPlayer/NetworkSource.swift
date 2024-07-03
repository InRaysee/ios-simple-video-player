//
//  Media.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import Foundation
import SwiftData

@Model
class NetworkSource {
    var title: String
    var mediaURL: String
    
    init(title: String, mediaURL: String) {
        self.title = title
        self.mediaURL = mediaURL
    }
    
    static let sampleData = [
        NetworkSource(title: "Bunny", mediaURL: "https://dash.akamaized.net/akamai/bbb_30fps/bbb_30fps_1024x576_2500k.mp4")
    ]
}
