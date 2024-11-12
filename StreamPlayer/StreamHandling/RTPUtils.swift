//
//  RTPTypes.swift
//  StreamPlayer
//
//  Created by 毕挺 on 2024/11/8.
//

import Foundation

public enum EncodingError: Error {
    case malformedHeader
    case unsupportedPayloadType(_ payloadType: PayloadType)
    case unknownVersion(_ version: UInt8)
    case dataTooSmall(_ expected: Int)
    case extensionDataTooSmall(_ expected: Int)
    case paddingTooLarge(_ padding: UInt8)
    case tooManyCSRCs(_ count: Int)
}

public struct PayloadType: ExpressibleByIntegerLiteral, RawRepresentable, Equatable, Sendable {
    public typealias IntegerLiteralType = UInt8

    public static let marker: Self = 0b1000_0000
    public static let opus: Self = 111

    public var rawValue: IntegerLiteralType

    public init(integerLiteral value: IntegerLiteralType) {
        rawValue = value
    }

    public init?(rawValue: IntegerLiteralType) {
        self.rawValue = rawValue
    }

    public init(_ value: IntegerLiteralType) {
        self.init(integerLiteral: value)
    }
}

public typealias SourceID = UInt32
public typealias SequenceNumber = UInt16
public typealias Timestamp = UInt32



extension Data {
    // big returns a big-endian integer of type T extracted from the bytes at the specified offset.
    func big<T: FixedWidthInteger>(at offset: Int) -> T {
        var value: T = 0
        withUnsafeMutablePointer(to: &value) {
            self.copyBytes(to: UnsafeMutableBufferPointer(start: $0, count: 1), from: offset..<offset + MemoryLayout<T>.size)
        }
        return T(bigEndian: value)
    }

    // big returns a little-endian integer of type T extracted from the bytes at the specified offset.
    func little<T: FixedWidthInteger>(at offset: Int) -> T {
        var value: T = 0
        withUnsafeMutablePointer(to: &value) {
            self.copyBytes(to: UnsafeMutableBufferPointer(start: $0, count: 1), from: offset..<offset + MemoryLayout<T>.size)
        }
        return T(littleEndian: value)
    }
}
