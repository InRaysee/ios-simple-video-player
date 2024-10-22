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
    var mediaName: String
    var mediaType: String
    
    init(title: String, mediaName: String, mediaType: String) {
        self.title = title
        self.mediaName = mediaName
        self.mediaType = mediaType
    }
    
    static let sampleData = [
        LocalMedia(title: "Apple", mediaName: "apple", mediaType: "mp4"),
        LocalMedia(title: "Tokyo", mediaName: "tokyo", mediaType: "mp4")
    ]
}
