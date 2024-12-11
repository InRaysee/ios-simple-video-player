//
//  UDPUtils.swift
//  StreamPlayer
//
//  Created by 毕挺 on 2024/11/15.
//

import Foundation
import Network
import SwiftUI

// UDP 接收器类
class UDPReceiver {
    private var listener: NWListener?
    private var receiveQueue = DispatchQueue(label: "UDPReceiverQueue")
    var recievedDataHandling: ((Data) -> Void)?
    
    @Binding var endPoint: String
    
    // 初始化方法，设置接收队列和回调函数
    init(endPoint: Binding<String>) {
        self._endPoint = endPoint
    }
    
    // 启动监听 UDP 数据包
    func start(onPort port: UInt16) throws {
        let parameters = NWParameters.udp
        parameters.requiredInterfaceType = .other
        
        // 创建一个监听器用于接收 UDP 数据包
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                // 处理每个新的连接
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Listening on port \(port) for incoming UDP packets.")
                case .failed(let error):
                    print("Listener failed with error: \(error)")
                case .waiting(let error):
                    print("Listener waiting: \(error)")
                case .cancelled:
                    print("Listener cancelled.")
                default:
                    break
                }
            }
            
            // 启动监听器
            listener?.start(queue: receiveQueue)
        } catch {
            print("Failed to start listener: \(error)")
        }
    }
    
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: receiveQueue)
        
        
        receiveData(from: connection)
    }
    
    
    private func receiveData(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            if let error = error {
                print("Error receiving data: \(error)")
                return
            }

            if let data = data {
                // 调用回调函数处理接收到的数据
                self?.recievedDataHandling?(data)
            }
            
            // 继续接收数据
            if isComplete {
                connection.cancel()
            } else {
                self?.receiveData(from: connection)
            }
        }
    }
    
    
    func stopListening() {
        listener?.cancel()
        print("Listener stopped.")
    }
}

