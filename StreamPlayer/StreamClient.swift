//
//  StreamBase.swift
//  CameraTest
//
//  Created by Jade on 2022/09/16.
//

import Foundation
import AVFoundation
import Network
import SwiftUI

/// Abstract: An object to capture video data, encode it and finally send it to the server
class StreamClient {
    
    // MARK: - dependencies
    
    private var captureManager: StreamCaptureManager?
    private var videoEncoder: H264Encoder?
    private var audioEncoder: AACEncoder?
    private var tcpClient: TCPClient?
    
    @Binding var session: AVCaptureSession
    
    init(session: Binding<AVCaptureSession>) {
        self._session = session
    }
    
    func connect(to ipAddress: String, with port: UInt16, videoDevice: AVCaptureDevice, audioDevice: AVCaptureDevice? = nil) throws {
        if let audioDevice {
            captureManager = StreamCaptureManager(session: $session, videoDevice: videoDevice, audioDevice: audioDevice)
            audioEncoder = AACEncoder()
        } else {
            captureManager = StreamCaptureManager(session: $session, videoDevice: videoDevice)
        }
        videoEncoder = H264Encoder()
        tcpClient = TCPClient()
        
        try tcpClient?.connect(to: ipAddress, with: port)
    }
    
    func startSendingStreamToServer() throws {
        try videoEncoder?.configureCompressSession()
//        try audioEncoder?.configure(inputFormat: captureManager?.audioDevice?.activeFormat)
        
        captureManager?.setVideoOutputDelegate(with: videoEncoder!)
//        captureManager?.setAudioOutputDelegate(with: audioEncoder!)
        
        // if connection is not established, 'send(:)' method in TCPClient doesn't
        // have any effect so it's okay to send data before establishing connection
        videoEncoder?.naluHandling = { [unowned self] data in
            tcpClient?.send(data: data)
        }
    }
}

