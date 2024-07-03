//
//  Media.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import Foundation
import SwiftData

@Model
class Media {
    var title: String
    var mediaName: String
    var mediaType: String
    
    init(title: String, mediaName: String, mediaType: String) {
        self.title = title
        self.mediaName = mediaName
        self.mediaType = mediaType
    }
    
    static let sampleData = [
        Media(title: "Apple", mediaName: "apple", mediaType: "mp4"),
        Media(title: "Tokyo", mediaName: "tokyo", mediaType: "mp4")
    ]
}
