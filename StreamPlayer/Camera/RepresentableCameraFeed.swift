//
//  RepresentableCameraFeed.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/5.
//

import Foundation
import SwiftUI
import AVKit

class CameraFeed: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var imageToDisplay: UIImageView!
    var shutDelegate: ShutCameraFeedDelegate?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageToDisplay = UIImageView()
        imageToDisplay.contentMode = .scaleAspectFill
        self.addSubview(imageToDisplay)
        addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.captureSession.startRunning()
    }
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
            return preview
    }()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private func addCameraInput() {
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func addPreviewLayer() {
        self.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.bounds
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "image.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
    
    func shutFeed() {
        captureSession.stopRunning()
        self.removeFromSuperview()
        shutDelegate?.didCameraFeedShut()
    }
    
}

struct RepresentableCameraFeed: UIViewRepresentable {
    
    @Binding var height: CGFloat
    @Binding var width: CGFloat
    @Binding var shutCamera: Bool
    
    init(height: Binding<CGFloat>, width: Binding<CGFloat>, shutCamera: Binding<Bool>, shutCameraHandler: @escaping () -> ()) {
        _height = height
        _width = width
        _shutCamera = shutCamera
        self.shutCameraHandler = shutCameraHandler
    }
    
    var shutCameraHandler: () -> ()?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> some UIView {
        let cameraView = CameraFeed(frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        cameraView.shutDelegate = context.coordinator
        return cameraView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let shutFlag = shutCamera
        if shutFlag,
        let view = uiView as? CameraFeed {
            view.shutFeed()
            DispatchQueue.main.async {
                shutCamera = false
            }
        }
    }
}

extension RepresentableCameraFeed {
    class Coordinator: NSObject, ShutCameraFeedDelegate {
        let parent: RepresentableCameraFeed
        
        init(_ parent: RepresentableCameraFeed) {
            self.parent = parent
        }
        
        func didCameraFeedShut() {
            // Will get called every time shutFeed is called
            parent.shutCameraHandler()
        }
    }
}

protocol ShutCameraFeedDelegate {
    func didCameraFeedShut()
}
