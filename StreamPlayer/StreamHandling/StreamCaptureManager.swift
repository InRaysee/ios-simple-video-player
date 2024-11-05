//
//  CameraManager.swift
//  CameraTest
//
//  Created by Jade's iMac on 2022/08/27.
//

import AVFoundation
import SwiftUI

/// Absract: An facade Object configuring AVCaptureSession and managing it.
///
/// Its primary rules are to configure AVCaptureSession and
/// set delegate which should handle raw video output data
class StreamCaptureManager {
        
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private enum ConfigurationError: Error {
        case cannotAddInput
        case cannotAddOutput
        case defaultDeviceNotExist
    }
    
    // MARK: - dependencies
    
    @Binding var session: AVCaptureSession
    var videoDevice: AVCaptureDevice
    var audioDevice: AVCaptureDevice?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    
    // MARK: - DispatchQueues to make the most of multithreading
    
    private let sessionQueue = DispatchQueue(label: "session.queue")
    private let videoOutputQueue = DispatchQueue(label: "video.output.queue")
    private let audioOutputQueue = DispatchQueue(label: "audio.output.queue")
    
    // MARK: - init
    
    private var setupResult: SessionSetupResult = .success
    
    init(session: Binding<AVCaptureSession>, videoDevice: AVCaptureDevice, audioDevice: AVCaptureDevice? = nil) {
        self._session = session
        self.videoDevice = videoDevice
        if (audioDevice != nil) {
            self.audioDevice = audioDevice
        }
        
        sessionQueue.async {
            self.requestCameraAuthorizationIfNeeded()
            if (audioDevice != nil) {
                self.requestMicrophoneAuthorizationIfNeeded()
            }
        }
    
        sessionQueue.async {
            self.configureSession()
        }
        
        sessionQueue.async {
            self.startSessionIfPossible()
        }
    }
    
    // MARK: - helper methods
    
    private func requestCameraAuthorizationIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            // we suspend the queue here and request access because
            // if the authorization is not granted, we always fail to configure AVCaptureSession
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }
    }
    
    private func requestMicrophoneAuthorizationIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            // we suspend the queue here and request access because
            // if the authorization is not granted, we always fail to configure AVCaptureSession
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default :
            setupResult = .notAuthorized
        }
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            if session.canSetSessionPreset(.iFrame1280x720) {
                session.sessionPreset = .iFrame1280x720
            }
#endif
        
        do {
            // Video
            try addVideoDeviceInputToSession(device: videoDevice)
            try addVideoOutputToSession()
            
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
//            ForEach(session.connections) { connection in
//                connection.videoRotationAngle = 90
//            }
//            
//            if let connection = session.connections.first {
//                connection.videoRotationAngle = 90
//            }
            session.connections[0].videoRotationAngle = 90
            session.connections[1].videoRotationAngle = 90
            
            // Audio
            if let audioDevice = self.audioDevice {
                try addAudioDeviceInputToSession(device: audioDevice)
                try addAudioOutputToSession()
            }
#endif
        } catch {
            print("error ocurred : \(error.localizedDescription)")
            return
        }
        
        session.commitConfiguration()
    }
    
    private func addVideoDeviceInputToSession(device: AVCaptureDevice? = nil) throws {
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // use the select device if exist
            if let selectedDevice = device {
                print("The selected video device is activated.")
                defaultVideoDevice = selectedDevice
            }
            else {
                // camera devices you can use vary depending on which iPhone you are
                // using so we want to
                #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
                if let wideAngleCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    defaultVideoDevice = wideAngleCameraDevice
                } else if let ultraWideCameraDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                    defaultVideoDevice = ultraWideCameraDevice
                } else if let telephotoCameraDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
                    defaultVideoDevice = telephotoCameraDevice
                } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                    defaultVideoDevice = dualCameraDevice
                } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    defaultVideoDevice = dualWideCameraDevice
                } else if let tripleCameraDevice = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                    defaultVideoDevice = tripleCameraDevice
                } else if let continuityCameraDevice = AVCaptureDevice.default(.continuityCamera, for: .video, position: .back) {
                    defaultVideoDevice = continuityCameraDevice
                } else if let liDARDepthCameraDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
                    defaultVideoDevice = liDARDepthCameraDevice
                } else if let trueDepthCameraDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .back) {
                    defaultVideoDevice = trueDepthCameraDevice
                }
                #endif
                
                #if os(macOS)
                if let wideAngleCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    defaultVideoDevice = wideAngleCameraDevice
                } else if let continuityCameraDevice = AVCaptureDevice.default(.continuityCamera, for: .video, position: .back) {
                    defaultVideoDevice = continuityCameraDevice
                } else if let deskViewCameraDevice = AVCaptureDevice.default(.deskViewCamera, for: .video, position: .back) {
                    defaultVideoDevice = deskViewCameraDevice
                }
                #endif
                
                #if os(visionOS)
                if let wideAngleCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    defaultVideoDevice = wideAngleCameraDevice
                }
                #endif
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                
                throw ConfigurationError.defaultDeviceNotExist
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            } else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                
                throw ConfigurationError.cannotAddInput
            }
        } catch {
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            throw error
        }
    }
    
    private func addAudioDeviceInputToSession(device: AVCaptureDevice? = nil) throws {
        do {
            var defaultAudioDevice: AVCaptureDevice?
            
            // use the select device if exist
            if let selectedDevice = device {
                print("The selected audio device is activated.")
                defaultAudioDevice = selectedDevice
            }
            
            guard let audioDevice = defaultAudioDevice else {
                print("Default audio device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                
                throw ConfigurationError.defaultDeviceNotExist
            }
            
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                
                throw ConfigurationError.cannotAddInput
            }
        } catch {
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            throw error
        }
    }

    private func addVideoOutputToSession() throws {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            throw ConfigurationError.cannotAddOutput
        }
    }
    
    private func addAudioOutputToSession() throws {
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        } else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            throw ConfigurationError.cannotAddOutput
        }
    }
    
    private func startSessionIfPossible() {
        switch self.setupResult {
        case .success:
            session.startRunning()
        case .notAuthorized:
            print("camera usage not authorized")
        case .configurationFailed:
            print("configuration failed")
        }
    }
    
    // MARK: - Delegate handling video and audio output data
    
    // VideoOutputDelegate recieves sequence of raw CMSampleBuffers
    func setVideoOutputDelegate(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
    }
    
    // AudioOutputDelegate
    func setAudioOutputDelegate(with delegate: AVCaptureAudioDataOutputSampleBufferDelegate) {
        audioOutput.setSampleBufferDelegate(delegate, queue: audioOutputQueue)
    }
}

