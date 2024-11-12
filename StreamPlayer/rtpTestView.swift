//
//  rtpTestView.swift
//  StreamPlayer
//
//  Created by 毕挺 on 2024/11/8.
//

import SwiftUI
import SwiftData
import AVKit


struct rtpTestView: View {
    @State private var player: AVSampleBufferDisplayLayer = .init()
    @State private var isPresent: Bool = true
    
    @State private var streamServer: StreamServer?
    @State private var isPlaying: Bool = false
    @State private var endPoint: String = ""

    
    var body: some View {
        GeometryReader{geometry in
            let streamPlayerSize: CGSize = .init(width: geometry.size.width, height: geometry.size.width / 16 * 9)
            ZStack {
                
                Rectangle()
                    .fill(.black)
                
                WebrtcPlayer(layer: player, streamPlayerSize: streamPlayerSize, isPresent: $isPresent)
                    .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
            }
            .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
        }
        .onAppear {
            if self.streamServer == nil {
                self.streamServer = .init(layer: player, isPlaying: $isPlaying, endPoint: $endPoint)
            }
        }
        
    }
}

#Preview {
    rtpTestView()
}
