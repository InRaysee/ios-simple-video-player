//
//  ACCEncoder.swift
//  StreamPlayer
//
//  Created by Feng Fangzheng on 2024/10/23.
//

import AVFoundation
import AudioToolbox

class AACEncoder: NSObject {
    
    // 编码器引用
    private var audioConverter: AudioConverterRef?
    
    // 处理编码后的AAC数据的回调
    var aacDataHandling: ((Data) -> Void)?
    
    // 用于音频数据的基本描述
    private var inputFormat: AudioStreamBasicDescription?
    private var outputFormat: AudioStreamBasicDescription?
    
    // MARK: - 配置音频编码器
    func configure(inputFormat: AudioStreamBasicDescription) throws {
        var inputFormat = inputFormat
        
        // 配置输出格式（AAC）
        var outputFormat = AudioStreamBasicDescription()
        outputFormat.mSampleRate = inputFormat.mSampleRate
        outputFormat.mFormatID = kAudioFormatMPEG4AAC
        outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame
        outputFormat.mFramesPerPacket = 1024 // AAC 使用的帧数
        outputFormat.mBitsPerChannel = 0
        outputFormat.mBytesPerPacket = 0
        outputFormat.mBytesPerFrame = 0
        outputFormat.mFormatFlags = AudioFormatFlags(MPEG4ObjectID.AAC_LC.rawValue)
        
        self.outputFormat = outputFormat
        
        // 创建音频转换器
        var converter: AudioConverterRef?
        let status = AudioConverterNew(&inputFormat, &outputFormat, &converter)
        guard status == noErr else {
            throw ConfigurationError.cannotCreateConverter
        }
        
        self.audioConverter = converter
        
        // 设置AAC的比特率
        var bitrate: UInt32 = 64000
        AudioConverterSetProperty(converter!,
                                  kAudioConverterEncodeBitRate,
                                  UInt32(MemoryLayout.size(ofValue: bitrate)),
                                  &bitrate)
    }
    
    // MARK: - 编码音频数据
    func encodeAudio(buffer: AudioBuffer, completion: @escaping (Data?) -> Void) {
        guard let converter = audioConverter else {
            completion(nil)
            return
        }
        
        // 将 buffer 声明为可变变量，以便传递给 inout 参数
        var buffer = buffer
        
        // 准备输出缓冲区
        var outputBuffer = AudioBuffer()
        outputBuffer.mNumberChannels = buffer.mNumberChannels
        outputBuffer.mDataByteSize = 1024 * 4 // 足够的空间来保存编码后的数据
        outputBuffer.mData = malloc(Int(outputBuffer.mDataByteSize))
        
        var outputBufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: outputBuffer
        )
        
        var ioOutputDataPacketSize: UInt32 = 1
        var outputPacketDesc = AudioStreamPacketDescription()
        
        // 编码回调
        let status = AudioConverterFillComplexBuffer(converter,
                                                     { (converter, ioNumberDataPackets, ioData, ioPacketDesc, inUserData) -> OSStatus in
            let inputBufferList = inUserData?.assumingMemoryBound(to: AudioBufferList.self)
            ioData.pointee = inputBufferList!.pointee
            ioNumberDataPackets.pointee = 1
            return noErr
        }, &buffer, &ioOutputDataPacketSize, &outputBufferList, &outputPacketDesc)
        
        if status == noErr {
            if let data = outputBuffer.mData {
                let aacData = Data(bytes: data, count: Int(outputBuffer.mDataByteSize))
                completion(aacData)
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
        
        free(outputBuffer.mData)
    }
    
    // 清理
    func cleanup() {
        if let converter = audioConverter {
            AudioConverterDispose(converter)
        }
    }
    
    enum ConfigurationError: Error {
        case cannotCreateConverter
    }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate
extension AACEncoder: AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // 获取捕获到的音频数据
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // 获取音频数据的基本描述
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let inputFormat = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee else {
            return
        }
        
        // 第一次调用时，配置编码器
        if audioConverter == nil {
            do {
                try configure(inputFormat: inputFormat)
            } catch {
                print("Failed to configure AAC encoder: \(error)")
                return
            }
        }
        
        // 提取音频数据缓冲区
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }
        
        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
        
        if status == kCMBlockBufferNoErr, let dataPointer = dataPointer {
            var audioBuffer = AudioBuffer()
            audioBuffer.mNumberChannels = inputFormat.mChannelsPerFrame
            audioBuffer.mData = UnsafeMutableRawPointer(dataPointer)
            audioBuffer.mDataByteSize = UInt32(totalLength)
            
            // 编码音频数据
            encodeAudio(buffer: audioBuffer) { aacData in
                if let aacData = aacData {
                    // 在此处处理 AAC 数据，例如保存到文件或传递到网络
                    self.aacDataHandling?(aacData)
                }
            }
        }
    }
}
