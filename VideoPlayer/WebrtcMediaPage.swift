//
//  WebrtcMediaPage.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData
import AVKit

struct WebrtcMediaPage: View {
    var size: CGSize
    var safeArea: EdgeInsets
    
    @Query(sort: \WebrtcMedia.title) private var webrtcMedias: [WebrtcMedia]
    @Environment(\.modelContext) private var context
    
    @State private var newWebrtcMedia: WebrtcMedia?
    
    @State private var player: AVSampleBufferDisplayLayer? = .init()
    @State private var videoClient: VideoClient = .init()

    @State private var showPlayerControls: Bool = false
    @State private var isPresent: Bool = false
    @State private var isPlaying: Bool = false
    @State private var timeoutTask: DispatchWorkItem?
    
    init(size: CGSize, safeArea: EdgeInsets) {
        self.size = size
        self.safeArea = safeArea
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            let videoPlayerSize: CGSize = .init(width: size.width, height: size.width / 16 * 9)
            
            Rectangle()
                .fill(.black)
                .frame(height: safeArea.top)
                .padding(0)

            ZStack {
                Rectangle()
                    .fill(.black)
                
                if let player {
                    WebrtcPlayer(layer: player, videoPlayerSize: videoPlayerSize, isPresent: $isPresent, isPlaying: $isPlaying)
                        .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showPlayerControls ? 1 : 0)
                                .overlay {
                                    // Customized Playback Controls
                                    PlayBackControls()
                                }
                                .overlay(alignment: .bottom) {
                                    Text("Presented by Research Center of 6G Mobile Communications, Huazhong University of Science and Technology, China.")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.system(size: 12))
                                        .fontWeight(.light)
                                        .foregroundStyle(.white)
                                        .padding(.top, 5)
                                        .padding(.bottom, 10)
                                        .background(Color.black.opacity(0.5))
                                        .opacity(showPlayerControls ? 1 : 0)
                                }
                        }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showPlayerControls.toggle()
                }
                timeoutControls()
            }
            .overlay {
                Text("Video source unselected.")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(isPlaying ? 0 : 1)
            }
            .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
            .fullScreenCover(isPresented: $isPresent, content: {
                ZStack {
                    Rectangle()
                        .fill(.black)
                    
                    if let player {
                        WebrtcPlayer(layer: player, videoPlayerSize: videoPlayerSize, isPresent: $isPresent, isPlaying: $isPlaying)
                            .overlay {
                                Rectangle()
                                    .fill(.black.opacity(0.4))
                                    .opacity(showPlayerControls ? 1 : 0)
                                    .overlay {
                                        // Customized Playback Controls
                                        PlayBackControls()
                                    }
                                    .overlay(alignment: .bottom) {
                                        Text("Presented by Research Center of 6G Mobile Communications, Huazhong University of Science and Technology, China.")
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .font(.system(size: 12))
                                            .fontWeight(.light)
                                            .foregroundStyle(.white)
                                            .padding(.top, 5)
                                            .padding(.bottom, 10)
                                            .background(Color.black.opacity(0.5))
                                            .opacity(showPlayerControls ? 1 : 0)
                                    }
                            }
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showPlayerControls.toggle()
                    }
                    timeoutControls()
                }
                .overlay {
                    Text("Video source unselected.")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(isPlaying ? 0 : 1)
                }
                .background(.black)
            })
            
            Form {
                Section("Select a media source to load:") {
                    ForEach(webrtcMedias) { webrtcMedia in
                        HStack {
                            Button("\(webrtcMedia.title)") {
                                do {
                                    try videoClient.connect(to: webrtcMedia.mediaURL, with: 12005)
                                    try videoClient.startSendingVideoToServer()
                                } catch {
                                    print("error occured : \(error.localizedDescription)")
                                }
                            }
                            .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Text("\(webrtcMedia.mediaURL)")
                                .foregroundStyle(.gray)
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteMedia)
                    
                    Button(action: addMedia) {
                        Label("New...", systemImage: "plus")
                    }
                    .sheet(item: $newWebrtcMedia) { webrtcMedia in
                        NavigationStack {
                            WebrtcMediaDetail(webrtcMedia: webrtcMedia)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .interactiveDismissDisabled()
                    }
                    .foregroundStyle(.tint)
                }
                .foregroundStyle(.gray)
                .listRowBackground(Color.white)
            }
            .scrollContentBackground(.hidden)
            
            Text("Presented by Research Center of 6G Mobile Communications, Huazhong University of Science and Technology, China.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .font(.system(size: 12))
                .fontWeight(.light)
                .foregroundStyle(.gray)
                .padding(.top, 5)
            
            Button {
                guard let url = URL(string: "http://sinc-lab.cse.hust.edu.cn/") else { return }
                UIApplication.shared.open(url)
            } label: {
                Text("Learn more...")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
            }
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(edges: .top)
        .background(.myBackground)
    }
    
    private func addMedia() {
        withAnimation {
            let newItem = WebrtcMedia(title: "", mediaURL: "")
            context.insert(newItem)
            newWebrtcMedia = newItem
        }
    }
    
    private func deleteMedia(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                context.delete(webrtcMedias[index])
            }
        }
    }
    
    // Customized Playback Controls
    @ViewBuilder
    func PlayBackControls() -> some View {
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
        }
        .opacity(showPlayerControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: showPlayerControls)
    }
    
    func timeoutControls() {
        if let timeoutTask {
            timeoutTask.cancel()
        }
        
        timeoutTask = .init(block: {
            withAnimation(.easeInOut(duration: 0.35)) {
                showPlayerControls = false
            }
        })
        
        if let timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: timeoutTask)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
