//
//  Base.swift
//  TCPServerTest
//
//  Created by Jade on 2022/09/17.
//

import Foundation
import SwiftUI
import CoreMedia
import AVKit

class StreamServer {
    
    // MARK: - dependencies
    
    private var server: TCPServer?
    private var naluParser: NALUParser?
    private var h264Converter: H264Converter?
    
    @Binding var isPlaying: Bool
    @Binding var endPoint: String
    
    // MARK: - init methods
    init(layer: AVSampleBufferDisplayLayer, isPlaying: Binding<Bool>, endPoint: Binding<String>) {
        self._isPlaying = isPlaying
        self._endPoint = endPoint
        

        
        do {
            try self.start(on: 12005)
            self.setSampleBufferCallback { [layer] sample in
                layer.enqueue(sample)
                self.isPlaying = true
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - task methods
    
    func start(on port: UInt16) throws {
        server = TCPServer(endPoint: self.$endPoint)
        naluParser = NALUParser()
        h264Converter = H264Converter()
        
        try server?.start(port: port)
        
        setServerDataHandling()
        setNALUParserHandling()
    }
    
    func setSampleBufferCallback(_ callback: @escaping (CMSampleBuffer) -> Void) {
        h264Converter?.sampleBufferCallback = callback
    }
    
    // MARK: - helper methods
    
    private func setServerDataHandling() {
        server?.recievedDataHandling = { [naluParser] data in
            naluParser?.enqueue(data)
        }
    }
    
    private func setNALUParserHandling() {
        naluParser?.h264UnitHandling = { [h264Converter] h264Unit in
            h264Converter?.convert(h264Unit)
        }
    }
}


class StreamWithUdp {
    
    // MARK: - dependencies
    
    private var server:UDPReceiver?
    private var naluParser: NALUParser?
    private var h264Converter: H264Converter?
    private var rtpPaser : RTPPaser?
    
    @Binding var isPlaying: Bool
    @Binding var endPoint: String
    
    // MARK: - init methods
    init(layer: AVSampleBufferDisplayLayer, isPlaying: Binding<Bool>, endPoint: Binding<String>) {
        self._isPlaying = isPlaying
        self._endPoint = endPoint
        

        
        do {
            try self.start(on: 12005)
            self.setSampleBufferCallback { [layer] sample in
                self.logSampleBufferInfo(sample, context: "Before enqueue")
                
                layer.enqueue(sample)
                
                self.logSampleBufferInfo(sample, context: "after enqueue")
                self.isPlaying = true
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - task methods
    
    func start(on port: UInt16) throws {
        server = UDPReceiver(endPoint: self.$endPoint)
        naluParser = NALUParser()
        h264Converter = H264Converter()
        rtpPaser = RTPPaser()
        h264Converter?.setCVFormatDescription()
        
        try server?.start(onPort: port)
        
        setRTPParserHandling()
        setServerDataHandling()
        setNALUParserHandling()
    }
    
    func setSampleBufferCallback(_ callback: @escaping (CMSampleBuffer) -> Void) {
        h264Converter?.sampleBufferCallback = callback
    }
    
    // MARK: - helper methods
    private func setServerDataHandling() {
        server?.recievedDataHandling = { [rtpPaser] data in
            rtpPaser?.enqueue(data)
        }
    }
//    private func setServerDataHandling() {
//        server?.recievedDataHandling = { [naluParser] data in
//            naluParser?.enqueue(data)
//        }
//    }
    
    private func setRTPParserHandling(){
        rtpPaser?.rtpUnitHandling = { [naluParser] data in
            naluParser?.enqueue(data.payload)
        }
    }
    
    private func setNALUParserHandling() {
        naluParser?.h264UnitHandling = { [h264Converter] h264Unit in
            h264Converter?.convert(h264Unit)
        }
    }
    
    private func logSampleBufferInfo(_ sampleBuffer: CMSampleBuffer, context: String) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            print("[\(context)] No Format Description.")
            return
        }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let timingInfo = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        print("[\(context)] SampleBuffer Info:")
        print(" - Width: \(dimensions.width)")
        print(" - Height: \(dimensions.height)")
        print(" - Presentation Time: \(timingInfo.seconds) seconds")
        
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]] {
            for (index, attachment) in attachments.enumerated() {
                print(" - Attachment \(index): \(attachment)")
            }
        } else {
            print(" - No Attachments Found")
        }
    }

}
