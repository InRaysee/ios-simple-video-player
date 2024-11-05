//
//  DeviceSelectionDetail.swift
//  StreamPlayer
//
//  Created by Feng Fangzheng on 2024/10/22.
//

import SwiftUI
import AVFoundation

struct DeviceSelectionDetail: View {
    @Environment(\.dismiss) private var dismiss
    
    let videoDevices: [AVCaptureDevice]
    let audioDevices: [AVCaptureDevice]
    var onVideoSelect: (AVCaptureDevice) -> Void
    var onAudioSelect: (AVCaptureDevice) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.myBackground)
                .ignoresSafeArea()
            
            VStack {
                Form {
                    Section("Select a video device:") {
                        if videoDevices.isEmpty {
                            // Gray alert message when the device list is empty
                            Text("No video device available")
                                .foregroundColor(.gray)  // Set the text color to gray
                                .padding()
                        } else {
                            // If the device list is not empty, show video devices
                            ForEach(videoDevices, id: \.self) { device in
                                Button(action: {
                                    // After the user selects the device, call onSelect
                                    onVideoSelect(device)
                                }) {
                                    Text(device.localizedName)  // Display device name
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                    }
                    .foregroundStyle(.gray)
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
                
                Form {
                    Section("Select a audio device:") {
                        if audioDevices.isEmpty {
                            // Gray alert message when the device list is empty
                            Text("No audio device available")
                                .foregroundColor(.gray)  // Set the text color to gray
                                .padding()
                        } else {
                            // If the device list is not empty, show audio devices
                            ForEach(audioDevices, id: \.self) { device in
                                Button(action: {
                                    // After the user selects the device, call onSelect
                                    onAudioSelect(device)
                                }) {
                                    Text(device.localizedName)  // Display device name
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                    }
                    .foregroundStyle(.gray)
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Select devices")
        .foregroundStyle(.black)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            UINavigationBar.appearance().titleTextAttributes = [ .foregroundColor: UIColor(.black)]
        }
    }
}

#Preview {
    let videoDevices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .builtInWideAngleCamera,
//            .builtInTelephotoCamera,
//            .builtInUltraWideCamera,
//            .builtInDualCamera,
//            .builtInTripleCamera,
//            .builtInTrueDepthCamera
        ],
        mediaType: .video,
        position: .unspecified
    ).devices
    let audioDevices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
            .microphone
        ],
        mediaType: .audio,
        position: .unspecified
    ).devices
    
    NavigationStack {
        DeviceSelectionDetail(videoDevices: videoDevices, audioDevices: audioDevices, onVideoSelect: { _ in }, onAudioSelect: { _ in })
            .navigationBarTitleDisplayMode(.inline)
    }
}
