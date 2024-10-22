//
//  CameraPreview.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/5.
//

import SwiftUI
import AVFoundation

class PreviewView: UIView {
    
    @Binding private var previewLayer1: AVCaptureVideoPreviewLayer
    
    init(previewLayer: Binding<AVCaptureVideoPreviewLayer>) {
        self._previewLayer1 = previewLayer
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use the preview layer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    func setSession(session: AVCaptureSession) {
        Task { @MainActor in
            previewLayer.session = session
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    
    private var session: AVCaptureSession
    @Binding private var layer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession, layer: Binding<AVCaptureVideoPreviewLayer>) {
        self.session = session
        self._layer = layer
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let preview = PreviewView(previewLayer: $layer)
        // Connect the preview layer to the capture session.
        preview.setSession(session: session)
        return preview
    }
    
    func updateUIView(_ previewView: PreviewView, context: Context) {
        // No implementation needed.
    }
}
