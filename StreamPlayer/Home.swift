//
//  MediaPage.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData
import AVKit

struct MediaPage: View {
    var size: CGSize
    var safeArea: EdgeInsets
        
    @Query(sort: \Media.title) private var medias: [Media]
    @Environment(\.modelContext) private var context
    
    @State private var newMedia: Media?
    
    @State private var player: AVPlayer? = .init()
    
    @State private var showPlayerControls: Bool = false
    @State private var isPlaying: Bool = false
    
    @State private var timeoutTask: DispatchWorkItem?
    
    // Video Seeker Properties
    @GestureState private var isDragging: Bool = false
    
    @State private var isSeeking: Bool = false
    @State private var progress: CGFloat = 0
    @State private var lastDraggedProgress: CGFloat = 0
    
    @State private var isPresent = false
    
    init(size: CGSize, safeArea: EdgeInsets) {
        self.size = size
        self.safeArea = safeArea
    }
    
    var body: some View {
        
        VStack {
            let videoPlayerSize: CGSize = .init(width: size.width, height: size.width / 16 * 9)

            ZStack {
                if let player {
                    VideoPlayer(player: player)
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showPlayerControls || isDragging ? 1 : 0)
                                .animation(.easeIn(duration: 0.35), value: isDragging)
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
                                        .opacity(showPlayerControls || isDragging ? 1 : 0)
                                        .animation(.easeIn(duration: 0.35), value: isDragging)
                                }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showPlayerControls.toggle()
                            }
                            
                            if isPlaying {
                                timeoutControls()
                            }
                        }
                        .overlay(alignment: .bottom) {
                            VideoSeekerView(size)
                        }
                        .overlay {
                            Text("Video source unselected.")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .opacity((player.currentItem != nil) ? 0 : 1)
                        }
                }
            }
            .fullScreenCover(isPresented: $isPresent, content: {
                ZStack {
                    if let player {
                        VideoPlayer(player: player)
                            .overlay {
                                Rectangle()
                                    .fill(.black.opacity(0.4))
                                    .opacity(showPlayerControls || isDragging ? 1 : 0)
                                    .animation(.easeIn(duration: 0.35), value: isDragging)
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
                                            .opacity(showPlayerControls || isDragging ? 1 : 0)
                                            .animation(.easeIn(duration: 0.35), value: isDragging)
                                    }
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    showPlayerControls.toggle()
                                }
                                
                                if isPlaying {
                                    timeoutControls()
                                }
                            }
                            .overlay(alignment: .bottom) {
                                VideoSeekerView(size)
                            }
                            .overlay {
                                Text("Video source unselected.")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .opacity((player.currentItem != nil) ? 0 : 1)
                            }
//                            .ignoresSafeArea()
//                            .padding(.top, 20)
//                            .padding(.bottom, 20)
                    }
                }
                .background(.black)
            })
            .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
            .onAppear() {
                player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { time in
                    if let currentPlayerItem = player?.currentItem {
                        let totalDuration = currentPlayerItem.duration.seconds
                        guard let currentDuration = player?.currentTime().seconds else { return }
                        
                        let calculatedProgress = currentDuration / totalDuration
                        
                        if !isSeeking && !calculatedProgress.isNaN {
                            progress = calculatedProgress
                            lastDraggedProgress = progress
                        }
                    }
                })
            }
            
            Form {
                Section("Select a media source to load:") {
                    ForEach(medias) { media in
                        HStack {
                            Button("\(media.title)") {
                                if let newBundle = Bundle.main.path(forResource: "\(media.mediaName)", ofType: "\(media.mediaType)") {
                                    let newPlayerItem: AVPlayerItem = .init(url: URL(filePath: newBundle))
                                    player?.replaceCurrentItem(with: newPlayerItem)
                                    
                                    progress = 0
                                    lastDraggedProgress = 0
                                    
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        showPlayerControls = true
                                    }
                                    
                                    if isPlaying {
                                        timeoutControls()
                                    }
                                }
                            }
                            .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Text("\(media.mediaName).\(media.mediaType)")
                                .foregroundStyle(.gray)
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteMedia)
                    
                    Button(action: addMedia) {
                        Label("New...", systemImage: "plus")
                    }
                    .sheet(item: $newMedia) { media in
                        NavigationStack {
                            MediaDetail(media: media)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .interactiveDismissDisabled()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            
            Text("Presented by Research Center of 6G Mobile Communications, Huazhong University of Science and Technology, China.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .font(.system(size: 12))
                .fontWeight(.light)
                .foregroundStyle(.gray)
                .padding(.top, 5)
                .padding(.bottom, 10)
        }
        .background(.myBackground)
    }
    
    private func addMedia() {
        withAnimation {
            let newItem = Media(title: "", mediaName: "", mediaType: "")
            context.insert(newItem)
            newMedia = newItem
        }
    }
    
    private func deleteMedia(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                context.delete(medias[index])
            }
        }
    }
    
    // Video Seeker View
    @ViewBuilder
    func VideoSeekerView(_ videoSize: CGSize) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.gray)
            
            Rectangle()
                .fill(.red)
                .frame(width: max(size.width * progress, 0))
        }
        .frame(height: 3)
        .overlay(alignment: .leading) {
            Circle()
                .fill(.red)
                .frame(width: 15, height: 15)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .offset(x: size.width * progress)
                .gesture(
                    DragGesture()
                        .updating($isDragging, body: { _, out, _ in
                            out = true
                        })
                        .onChanged({ value in
                            // Cancel Existing Timeout task
                            if let timeoutTask {
                                timeoutTask.cancel()
                            }
                            
                            let translationX: CGFloat = value.translation.width
                            let calculatedProgress = (translationX / videoSize.width) + lastDraggedProgress
                            
                            progress = max(min(calculatedProgress, 1), 0)
                            isSeeking = true
                        })
                        .onEnded({ value in
                            lastDraggedProgress = progress
                            if let currentPlayerItem = player?.currentItem {
                                let totalDuration = currentPlayerItem.duration.seconds
                                
                                player?.seek(to: .init(seconds: totalDuration * progress, preferredTimescale: 1))
                                
                                if isPlaying {
                                    timeoutControls()
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isSeeking = false
                                }
                            }
                        })
                )
                .frame(width: 15, height: 15)
        }
    }
    
    // Customized Playback Controls
    @ViewBuilder
    func PlayBackControls() -> some View {
        ZStack {
            HStack(spacing: 25) {
                Button {
                    
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .fontWeight(.ultraLight)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background {
                            Circle()
                                .fill(.black.opacity(0.35))
                        }
                }
                .disabled(true)
                .opacity(0.6)
                
                Button {
                    if isPlaying {
                        player?.pause()
                        // Cancelling timeout task when the video is paused
                        if let timeoutTask {
                            timeoutTask.cancel()
                        }
                    } else {
                        player?.play()
                        timeoutControls()
                    }
                    
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPlaying.toggle()
                    }
                } label: {
                    Image(systemName: !isPlaying ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .fontWeight(.ultraLight)
                        .foregroundStyle(.black)
                        .padding(15)
                        .background {
                            Circle()
                                .fill(.white)
                        }
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .fontWeight(.ultraLight)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background {
                            Circle()
                                .fill(.black.opacity(0.35))
                        }
                }
                .disabled(true)
                .opacity(0.6)
            }
            
            Button {
                isPresent.toggle()
            } label: {
                Image(systemName: isPresent ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .position(.init(x: 30, y: 35))
        }
        .opacity(showPlayerControls && !isDragging ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: showPlayerControls && !isDragging)
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
