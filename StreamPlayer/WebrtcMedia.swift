//
//  WebrtcMedia.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import Foundation
import SwiftData

@Model
class WebrtcMedia {
    var title: String
    var mediaURL: String
    
    init(title: String, mediaURL: String) {
        self.title = title
        self.mediaURL = mediaURL
    }
    
    static let sampleData = [
        WebrtcMedia(title: "A", mediaURL: "http://10.12.190.215")
    ]
}
