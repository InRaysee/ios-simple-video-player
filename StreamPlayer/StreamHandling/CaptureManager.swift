//
//  CameraManager.swift
//  CameraTest
//
//  Created by Jade's iMac on 2022/08/27.
//

import AVFoundation
import SwiftUI
import VideoToolbox
import AudioToolbox

/// Absract: An facade Object configuring AVCaptureSession and managing it.
///
/// Its primary rules are to configure AVCaptureSession and
/// set delegate which should handle raw video output data
class CaptureManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
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
    
    var onVideoData: ((Data) -> Void)?
    var onAudioData: ((Data) -> Void)?
    
    @Binding var session: AVCaptureSession
    @Binding var tcpClient: TCPClient
    private var videoCompressionSession: VTCompressionSession?
    private var audioConverter: AudioConverterRef?
    
    private var videoDevice: AVCaptureDevice
    private var audioDevice: AVCaptureDevice
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    
    // MARK: - DispatchQueues to make the most of multithreading
    
    private let sessionQueue = DispatchQueue(label: "session.queue")
    private let videoOutputQueue = DispatchQueue(label: "video.output.queue")
    private let audioOutputQueue = DispatchQueue(label: "audio.output.queue")
    
    // MARK: - init
        
    private var setupResult: SessionSetupResult = .success
    
    init(session: Binding<AVCaptureSession>, tcpClient: Binding<TCPClient>, videoDevice: AVCaptureDevice, audioDevice: AVCaptureDevice? = nil) {
        
        super.init()
        
        self._session = session
        self._tcpClient = tcpClient
        self.videoDevice = videoDevice
        self.audioDevice = audioDevice!
        
        setupCaptureSession()
        setupH264Encoder()
        setupAACEncoder()
        
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
    
    func setupCaptureSession() {
        
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        do {
            // Video
            try addVideoDeviceInputToSession(device: videoDevice)
            try addVideoOutputToSession()
            
//            ForEach(session.connections) { connection in
//                connection.videoRotationAngle = 90
//            }
            
//            if let connection = session.connections.first {
//                connection.videoRotationAngle = 90
//            }
            session.connections[0].videoRotationAngle = 90
            session.connections[1].videoRotationAngle = 90
            
            // Audio
            try addAudioDeviceInputToSession(device: audioDevice)
            try addAudioOutputToSession()
        } catch {
            print("error ocurred : \(error.localizedDescription)")
            return
        }
        
        session.commitConfiguration()
        startSessionIfPossible()
        
    }
    
    private func addVideoDeviceInputToSession(device: AVCaptureDevice? = nil) throws {
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // use the select device if exist
            if let selectedDevice = device {
                print("The selected video device is activated.")
                defaultVideoDevice = selectedDevice
            }
            // camera devices you can use vary depending on which iPhone you are
            // using so we want to
            else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
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
        
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            
            throw ConfigurationError.cannotAddOutput
        }
        
    }
    
    private func addAudioOutputToSession() throws {
        
        audioOutput.setSampleBufferDelegate(self, queue: audioOutputQueue)
        
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
    
    func setupH264Encoder() {
        // 初始化 H.264 编码器
        let err = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                             width: Int32(options.destWidth),
                                             height: Int32(options.destHeight),
                                             codecType: options.codec,
                                             encoderSpecification: videoEncoderSpecification,
                                             imageBufferAttributes: sourceImageBufferAttributes,
                                             compressedDataAllocator: nil,
                                             outputCallback: nil,
                                             refcon: nil,
                                             compressionSessionOut: &compressionSessionOut)
        guard err == noErr, let compressionSession = compressionSessionOut else {
            throw RuntimeError("VTCompressionSession creation failed (\(err))!")
        }
        
        
        VTCompressionSessionCreate(allocator: nil, width: 640, height: 480, codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: { _, _, status, flags, sampleBuffer in
            guard status == noErr else { return }
            
            if let sampleBuffer = sampleBuffer, let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                var length = 0
                var dataPointer: UnsafeMutablePointer<Int8>?
                CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: &length, dataPointerOut: &dataPointer)
                
                if let dataPointer = dataPointer {
                    let data = Data(bytes: dataPointer, count: length)
                    // 通过 TCP 发送 H.264 视频数据
                    self.tcpClient.send(data: data)
                }
            }
        }, refcon: nil, compressionSessionOut: &videoCompressionSession)
        
        VTSessionSetProperty(videoCompressionSession!, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(videoCompressionSession!, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
    }
    
    func setupAACEncoder() {
        var inputFormat = AudioStreamBasicDescription()
        inputFormat.mSampleRate = 44100
        inputFormat.mFormatID = kAudioFormatLinearPCM
        inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        inputFormat.mBytesPerPacket = 2
        inputFormat.mFramesPerPacket = 1
        inputFormat.mBytesPerFrame = 2
        inputFormat.mChannelsPerFrame = 1
        inputFormat.mBitsPerChannel = 16
        inputFormat.mReserved = 0
        
        var outputFormat = AudioStreamBasicDescription()
        outputFormat.mSampleRate = 44100
        outputFormat.mFormatID = kAudioFormatMPEG4AAC
        outputFormat.mChannelsPerFrame = 1
        
        var bitrate: UInt32 = 64000
        AudioConverterNew(&inputFormat, &outputFormat, &audioConverter)
        AudioConverterSetProperty(audioConverter!, kAudioConverterEncodeBitRate, UInt32(MemoryLayout.size(ofValue: bitrate)), &bitrate)
    }
    
    func encodeAudio(sampleBuffer: CMSampleBuffer) {
        guard let audioConverter = audioConverter else { return }
        
        var blockBuffer: CMBlockBuffer?
        var audioBufferList = AudioBufferList()
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
            
        )
        
        var encodedData = Data()
        let outputData = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        var outputSize: UInt32 = 1024
        var outputBufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: 1024, mData: outputData)
        )
        
        let status = AudioConverterFillComplexBuffer(
            audioConverter,
            { inAudioConverter, ioNumberDataPackets, ioData, outPacketDescription, inUserData in
                ioData.pointee.mBuffers.mData = audioBufferList.mBuffers.mData
                ioData.pointee.mBuffers.mDataByteSize = audioBufferList.mBuffers.mDataByteSize
                ioNumberDataPackets.pointee = 1
                return noErr
            },
            &audioBufferList,
            &outputSize,
            &outputBufferList,
            nil
        )
        
        if status == noErr {
            encodedData.append(outputData, count: Int(outputSize))
            // 通过 TCP 发送 AAC 音频数据
            self.tcpClient.send(data: encodedData)
        }
        
        outputData.deallocate()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.audioChannels.isEmpty {
            // 处理视频帧 (H.264 编码)
            if let compressionSession = videoCompressionSession, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                VTCompressionSessionEncodeFrame(compressionSession, imageBuffer: imageBuffer, presentationTimeStamp: timeStamp, duration: .invalid, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: nil)
            }
        } else {
            // 处理音频帧 (AAC 编码)
            encodeAudio(sampleBuffer: sampleBuffer)
        }
    }
    
}

