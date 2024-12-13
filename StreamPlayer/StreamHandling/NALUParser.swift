//
//  NALUParser.swift
//  TCPServerTest
//
//  Created by Jade on 2022/09/17.
//

import Foundation

/// Abstract: This Object receives NALU Stream and parse it to H264Format which
/// is composed of 4 bytes length data and NALU data
class NALUParser {
    
    /// Data stream received from the client.
    /// It'll be a seqeunce of NALU so we should pick out NALU from it.
    private var dataStream = Data()
    
    /// We should search data stream sequentially to pick out NALU of it.
    /// This is uesed for searching data stream.
    private var searchIndex = 0
    
    private lazy var parsingQueue = DispatchQueue.init(label: "parsing.queue",
                                                    qos: .userInteractive)
    
    /// callback when a NALU is seperated from data stream
    var h264UnitHandling: ((H264Unit) -> Void)?
    
    private var fragmentBuffer = [UInt16: Data]() // To store FU-A fragments keyed by RTP sequence number
    private var lastSequenceNumber: UInt16?
    
    /// receives NALU stream data and parse it then call 'h264UnitHandling'
    func enqueue(_ data: Data) {
        print("nalparser being executed")
        parsingQueue.async { [unowned self] in
            dataStream.append(data)
            
            while searchIndex < dataStream.endIndex-3 {
                // examine if dataStream[searchIndex...searchIndex+3] is start code(0001)
                if (dataStream[searchIndex] | dataStream[searchIndex+1] |
                    dataStream[searchIndex+2] | dataStream[searchIndex+3]) == 1 {
                    // if searchIndex is zero, that means there's nothing to extract cause
                    // we only care left side of searchIndex
                    if searchIndex != 0 {
                        let h264Unit = H264Unit(payload: dataStream[0..<searchIndex])
                        h264UnitHandling?(h264Unit)
                    }
                    
                    // We excute O(n) complexity operation here which is terribly inefficent.
                    // I hope you to refactor this part with more efficent way like a circular buffer.
                    dataStream.removeSubrange(0...searchIndex+3)
                    searchIndex = 0
                } else if dataStream[searchIndex+3] != 0 {
                    searchIndex += 4
                } else { // dataStream[searchIndex+3] == 0
                    searchIndex += 1
                }
            }
        }
    }
    
    //this function used to parse rtp formatting nal stream
    func enqueue(_ data: RtpPacket) {
        print("NALUParser being executed")
        
        parsingQueue.async { [unowned self] in
            guard data.payload.count > 0 else {
                print("Invalid RTP packet payload")
                return
            }
            let payload = data.payload
            let nalHeaderIndex = payload.startIndex
            let nalHeader = payload[nalHeaderIndex]
            let nalType = nalHeader & 0x1F // Extract NAL unit type
            
            switch nalType {
            case 1...23:
                // Single NAL unit packet
                self.handleSingleNALUnit(payload)
                
            case 24:
                // STAP-A (Single-Time Aggregation Packet)
                self.handleStapA(payload)
                
            case 28:
                // FU-A (Fragmentation Unit)
                self.handleFuA(payload, sequenceNumber: data.sequenceNumber)
                
            default:
                print("Unsupported NAL unit type: \(nalType)")
            }
        }
    }
    private func handleSingleNALUnit(_ payload: Data) {
        // Directly pass the payload as a complete NAL unit
        let h264unit = H264Unit(payload: payload)
        h264UnitHandling?(h264unit)
    }
    
    private func handleStapA(_ payload: Data) {
        
        var offset = 1 // Skip the NAL header
        while offset < payload.count {
            guard offset + 2 <= payload.count else {
                print("Malformed STAP-A packet")
                return
            }
            
            // Read NAL unit size (2 bytes, big-endian)
            let nalSize = Int(payload[offset]) << 8 | Int(payload[offset + 1])
            offset += 2
            
            guard offset + nalSize <= payload.count else {
                print("Malformed STAP-A packet")
                return
            }
            
            // Extract NAL unit
            let nalUnit = payload[offset..<(offset + nalSize)]
            let h264unit = H264Unit(payload: nalUnit)
            h264UnitHandling?(h264unit)
            offset += nalSize
        }
    }
    
    private func handleFuA(_ payload: Data, sequenceNumber: UInt16) {
        guard payload.count > 2 else {
            print("Malformed FU-A packet")
            return
        }
        
        let fuHeader = payload[1]
        let startBit = fuHeader & 0x80 > 0
        let endBit = fuHeader & 0x40 > 0
        let nalType = fuHeader & 0x1F
        
        if startBit {
            // Start of a fragmented NAL unit
            let reconstructedNALHeader = (payload[0] & 0xE0) | nalType
            fragmentBuffer = [sequenceNumber: Data([reconstructedNALHeader] + payload[2...])]
            lastSequenceNumber = sequenceNumber
        } else if let lastSeq = lastSequenceNumber, sequenceNumber == lastSeq + 1 {
            // Continuation of the fragmented NAL unit
            fragmentBuffer[sequenceNumber] = payload[2...]
            lastSequenceNumber = sequenceNumber
            
            if endBit {
                // End of the fragmented NAL unit
                let fullNALUnit = fragmentBuffer
                    .sorted { $0.key < $1.key } // Sort by sequence number
                    .compactMap { $0.value } // Extract data
                    .reduce(Data(), +) // Concatenate all parts
                
                let h264unit = H264Unit(payload: fullNALUnit)
                h264UnitHandling?(h264unit)
                fragmentBuffer.removeAll()
                lastSequenceNumber = nil
            }
        } else {
            // Packet loss or out-of-order packet, drop the fragmented NAL unit
            print("Packet loss or out-of-order detected in FU-A sequence")
            fragmentBuffer.removeAll()
            lastSequenceNumber = nil
        }
    }
    
    
}


//extension Data {
//    subscript(safeOffset offset: Int) -> UInt8? {
//        let index = self.index(self.startIndex, offsetBy: offset, limitedBy: self.endIndex)
//        return index.map { self[$0] }
//    }
//    
//    subscript(safeRange range: Range<Int>) -> Data? {
//        let lowerIndex = self.index(self.startIndex, offsetBy: range.lowerBound, limitedBy: self.endIndex)
//        let upperIndex = self.index(self.startIndex, offsetBy: range.upperBound, limitedBy: self.endIndex)
//        if let lower = lowerIndex, let upper = upperIndex, lower <= upper {
//            return self[lower..<upper]
//        }
//        return nil
//    }
//}
//
