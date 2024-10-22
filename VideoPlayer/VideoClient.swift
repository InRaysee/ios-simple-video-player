//
//  VideoBase.swift
//  CameraTest
//
//  Created by Jade on 2022/09/16.
//

import Foundation
import AVFoundation
import Network
import SwiftUI

/// Abstract: An object to capture video data, encode it and finally send it to the server
class VideoClient {
    
    // MARK: - dependencies
    
    private var captureManager: VideoCaptureManager?
    private var videoEncoder: H264Encoder?
    private var tcpClient: TCPClient?
    
    @Binding var session: AVCaptureSession
    
    init(session: Binding<AVCaptureSession>) {
        self._session = session
    }
    
    func connect(to ipAddress: String, with port: UInt16, device: AVCaptureDevice) throws {
        captureManager = VideoCaptureManager(session: $session, device: device)
        videoEncoder = H264Encoder()
        tcpClient = TCPClient()
        
        try tcpClient?.connect(to: ipAddress, with: port)
    }
    
    func startSendingVideoToServer() throws {
        try videoEncoder?.configureCompressSession()
        
        captureManager?.setVideoOutputDelegate(with: videoEncoder!)
        
        // if connection is not established, 'send(:)' method in TCPClient doesn't
        // have any effect so it's okay to send data before establishing connection
        videoEncoder?.naluHandling = { [unowned self] data in
            tcpClient?.send(data: data)
        }
    }
}

