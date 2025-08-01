//
//  WebrtcMediaPage.swift
//  StreamPlayer
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

    @State private var showServerPlayerControls: Bool = false
    @State private var showClientPlayerControls: Bool = false
    @State private var isPresent: Bool = false
    @State private var isPlaying: Bool = false
    @State private var isPipMode: Bool = false
    @State private var endPoint: String = ""

    @State private var player: AVSampleBufferDisplayLayer = .init()
    @State private var streamClient: StreamClient?
    @State private var streamServer: StreamServer?
    @State private var session: AVCaptureSession = .init()

    #if !os(visionOS)
    @State private var preview: AVCaptureVideoPreviewLayer = .init()
    #endif
    
    @State private var serverTimeoutTask: DispatchWorkItem?
    @State private var clientTimeoutTask: DispatchWorkItem?
    
    @State private var selectedVideoDevice: AVCaptureDevice?
    @State private var selectedAudioDevice: AVCaptureDevice?
    @State private var showDeviceSelection: Bool = false
    @State private var showEmptyCameraAlert = false
    
    @State private var pipController: AVPictureInPictureController!
    @State private var pipPossibleObservation: NSKeyValueObservation?

    init(size: CGSize, safeArea: EdgeInsets) {
        self.size = size
        self.safeArea = safeArea
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            let streamPlayerSize: CGSize = .init(width: size.width, height: size.width / 16 * 9)
            
            Rectangle()
                .fill(.black)
                .frame(height: safeArea.top)
                .padding(0)

            ZStack {
                Rectangle()
                    .fill(.black)
                
                WebrtcPlayer(layer: player, streamPlayerSize: streamPlayerSize, isPresent: $isPresent)
                    .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
                    .overlay {
                        Rectangle()
                            .fill(.black.opacity(0.4))
                            .opacity(showServerPlayerControls ? 1 : 0)
                            .overlay {
                                // Customized Playback Controls
                                ServerPlayBackControls()
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
                                    .opacity(showServerPlayerControls ? 1 : 0)
                            }
                    }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showServerPlayerControls.toggle()
                }
                ServerTimeoutControls()
            }
            .overlay {
                Text("Waiting to be called...")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(isPlaying ? 0 : 1)
            }
            .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
            .fullScreenCover(isPresented: $isPresent, content: {
                ZStack {
                    Rectangle()
                        .fill(.black)
                    
                    WebrtcPlayer(layer: player, streamPlayerSize: streamPlayerSize, isPresent: $isPresent)
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showServerPlayerControls ? 1 : 0)
                                .overlay {
                                    // Customized Playback Controls
                                    ServerPlayBackControls()
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
                                        .opacity(showServerPlayerControls ? 1 : 0)
                                }
                        }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showServerPlayerControls.toggle()
                    }
                    ServerTimeoutControls()
                }
                .overlay {
                    Text("Waiting to be called...")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(isPlaying ? 0 : 1)
                }
                .background(.black)
            })
            
            Divider()
            
            ZStack {
                Rectangle()
                    .fill(.black)
                
                #if os(visionOS)
                Text("Preview not supported in visionOS.")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                #else
                CameraPreview(session: session, layer: $preview)
                    .overlay {
                        Rectangle()
                            .fill(.black.opacity(0.4))
                            .opacity(showClientPlayerControls ? 1 : 0)
                            .overlay {
                                // Customized Playback Controls
                                ClientPlayBackControls()
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
                                    .opacity(showClientPlayerControls ? 1 : 0)
                            }
                    }
                #endif
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showClientPlayerControls.toggle()
                }
                ClientTimeoutControls()
            }
            .frame(width: streamPlayerSize.width, height: streamPlayerSize.height)
            
            Form {
                Section("Select a media source to load:") {
                    ForEach(webrtcMedias) { webrtcMedia in
                        HStack {
                            Button("\(webrtcMedia.title)") {
                                if let videoDevice = selectedVideoDevice {
                                    do {
//                                        if let audioDevice = selectedAudioDevice {
//                                            try streamClient?.connect(to: webrtcMedia.mediaURL, with: 12005, videoDevice: videoDevice, audioDevice: audioDevice)
//                                        } else {
//                                            try streamClient?.connect(to: webrtcMedia.mediaURL, with: 12005, videoDevice: videoDevice)
//                                        }
                                        try streamClient?.connect(to: webrtcMedia.mediaURL, with: 12005, videoDevice: videoDevice)

                                        try streamClient?.startSendingStreamToServer()
                                    } catch {
                                        print("error occured : \(error.localizedDescription)")
                                    }
                                } else {
                                    // pop up an alert
                                    showEmptyCameraAlert = true
                                }
                            }
                            .foregroundStyle(.black)
                            .alert(isPresented: $showEmptyCameraAlert) {
                                Alert(
                                    title: Text("No video device"),
                                    message: Text("Please select at least one video device first."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                            
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
            
            Button {
                // Get device list and show popup
                self.showDeviceSelection = true
            } label: {
                VStack {
                    Text((self.selectedVideoDevice != nil) ? "Reselect devices" : "Select devices")
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Video: \(selectedVideoDevice?.localizedName ?? "")")
                            .font(.system(size: 12))
                        Text("Audio: \(selectedAudioDevice?.localizedName ?? "")")
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
            .background(.tint)
            .foregroundColor(.white)
            .cornerRadius(8)
            .sheet(isPresented: $showDeviceSelection) {
                NavigationStack {
                    // Show camera device selection list in floating window
                    DeviceSelectionDetail(videoDevices: getAvailableVideoDevices(), audioDevices: getAvailableAudioDevices(), onVideoSelect: { selectedVideoDevice in
                        self.selectedVideoDevice = selectedVideoDevice
                        if let selectedAudioDevice {
                            self.showDeviceSelection = false
                        }
                    }, onAudioSelect: { selectedAudioDevice in
                        self.selectedAudioDevice = selectedAudioDevice
                        if let selectedVideoDevice {
                            self.showDeviceSelection = false
                        }
                    })
                    .navigationBarTitleDisplayMode(.inline)
                }
                .interactiveDismissDisabled()
            }
                        
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
        .onAppear {
            if self.streamServer == nil {
                self.streamServer = .init(layer: player, isPlaying: $isPlaying, endPoint: $endPoint)
            }
            
            if self.streamClient == nil {
                self.streamClient = .init(session: $session)
            }
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
    
    // Get all available video devices
    private func getAvailableVideoDevices() -> [AVCaptureDevice] {
        #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .continuityCamera,
                .builtInLiDARDepthCamera,
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
        #endif
        
        #if os(macOS)
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .continuityCamera,
                .deskViewCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
        #endif
        
        #if os(visionOS)
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
        #endif
        
        return videoDevices
    }
    
    // Get all available audio devices
    private func getAvailableAudioDevices() -> [AVCaptureDevice] {
#if !os(visionOS)
        let audioDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .microphone
            ],
            mediaType: .audio,
            position: .unspecified
        ).devices
        return audioDevices
#else
        return [] as [AVCaptureDevice]
#endif
    }

    
    // Customized Playback Controls
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
    
    // Customized Playback Controls
    @ViewBuilder
    func ClientPlayBackControls() -> some View {
        VStack {
            Text("Camera preview")
                .fontWeight(.light)
                .foregroundStyle(.white)
                .shadow(radius: 10)
            
            Button {
                isPipMode.toggle()
            } label: {
                Image(systemName: isPipMode ? "pip.exit" : "pip.enter")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
        }
        .opacity(showClientPlayerControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: showClientPlayerControls)
    }
    
    func ServerTimeoutControls() {
        if let serverTimeoutTask {
            serverTimeoutTask.cancel()
        }
        
        serverTimeoutTask = .init(block: {
            withAnimation(.easeInOut(duration: 0.35)) {
                showServerPlayerControls = false
            }
        })
        
        if let serverTimeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: serverTimeoutTask)
        }
    }
    
    func ClientTimeoutControls() {
        if let clientTimeoutTask {
            clientTimeoutTask.cancel()
        }
        
        clientTimeoutTask = .init(block: {
            withAnimation(.easeInOut(duration: 0.35)) {
                showClientPlayerControls = false
            }
        })
        
        if let clientTimeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: clientTimeoutTask)
        }
    }
    
//    func setupPictureinPicture() {
//        // Ensure PiP is supported by current device.
//        if AVPictureInPictureController.isPictureInPictureSupported() {
//            // Create a new controller, passing the reference to the AVPlayerLayer.
//            pipController = AVPictureInPictureController(playerLayer: playerLayer)
//            pipController.delegate = self
//
//
//            pipPossibleObservation = pipController.observe(\AVPictureInPictureController.isPictureInPicturePossible,
//    options: [.initial, .new]) { [weak self] _, change in
//                // Update the PiP button's enabled state.
//                self?.pipButton.isEnabled = change.newValue ?? false
//            }
//        } else {
//            // PiP isn't supported by the current device. Disable the PiP button.
//            pipButton.isEnabled = false
//        }
//    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
