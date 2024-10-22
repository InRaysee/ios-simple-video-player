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
    
    let devices: [AVCaptureDevice]
    var onSelect: (AVCaptureDevice) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.myBackground)
                .ignoresSafeArea()
            
            VStack {
                if devices.isEmpty {
                    // Gray alert message when the device list is empty
                    Text("No camera available")
                        .foregroundColor(.gray)  // Set the text color to gray
                        .padding()
                } else {
                    // If the device list is not empty, show camera devices
                    List(devices, id: \.self) { device in
                        Button(action: {
                            // After the user selects the device, call onSelect
                            onSelect(device)
                        }) {
                            Text(device.localizedName)  // Display device name
                        }
                        .listRowBackground(Color.white)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Select a camera")
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
            .builtInTelephotoCamera,
            .builtInUltraWideCamera,
            .builtInDualCamera,
            .builtInTripleCamera,
            .builtInTrueDepthCamera
        ],
        mediaType: .video,
        position: .unspecified
    ).devices
    
    NavigationStack {
        DeviceSelectionDetail(devices: videoDevices, onSelect: { _ in })
            .navigationBarTitleDisplayMode(.inline)
    }
}
