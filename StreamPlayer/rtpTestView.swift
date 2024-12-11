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
    
    @State private var streamServer: StreamWithUdp?
    @State private var isPlaying: Bool = false
    @State private var endPoint: String = ""

    
    @State private var showServerPlayerControls: Bool = false
    
    var body: some View {
        GeometryReader{geometry in
            let streamPlayerSize: CGSize = .init(width: geometry.size.width, height: geometry.size.width / 16 * 9)
            ZStack {
                
                Rectangle()
                    .fill(.black)
                
                WebrtcPlayer(layer: player, streamPlayerSize: streamPlayerSize, isPresent: $isPresent)
                    .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
                    .opacity(showServerPlayerControls ? 1 : 0)
                    .overlay {
                        // Customized Playback Controls
                        ServerPlayBackControls()
                    }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showServerPlayerControls.toggle()
                }
            }
            .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
        }
        .onAppear {
            if self.streamServer == nil {
                self.streamServer = .init(layer: player, isPlaying: $isPlaying, endPoint: $endPoint)
            }
        }
        
    }
    
    
    @ViewBuilder
    func ServerPlayBackControls() -> some View {
        ZStack {
            Button {
                isPresent.toggle()
            } label: {
                Image(systemName: isPresent ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .position(CGPoint(x: 30.0, y: 35.0))
            
            Text("Session from: \(endPoint)")
                .fontWeight(.light)
                .foregroundStyle(.white)
                .shadow(radius: 10)
                .opacity(isPlaying ? 1 : 0)
        }
        .opacity(showServerPlayerControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: showServerPlayerControls)
    }
    
}

#Preview {
    rtpTestView()
}
