//
//  WebrtcPlayer.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import AVKit

class myViewController: UIViewController {
    
    var timer : Timer = .init()
    
    var layer: AVSampleBufferDisplayLayer
    var streamPlayerSize: CGSize
    var shouldBePresent: Bool
    var isFinishPresent: Bool
    @Binding var isPresent: Bool
    
    init(layer: AVSampleBufferDisplayLayer, streamPlayerSize: CGSize, isPresent: Binding<Bool>) {
        self.layer = layer
        self.streamPlayerSize = streamPlayerSize
        self.shouldBePresent = isPresent.wrappedValue
        self.isFinishPresent = true
        self._isPresent = isPresent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layer.frame = isPresent ? view.frame : CGRect(x: 0, y: 0, width: streamPlayerSize.width, height: streamPlayerSize.height)
        view.layer.addSublayer(layer)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            if self.isPresent != self.shouldBePresent {
                self.isFinishPresent = false
            } else {
                if !self.isFinishPresent {
                    self.layer.frame = self.isPresent ? self.view.frame : CGRect(x: 0, y: 0, width: self.streamPlayerSize.width, height: self.streamPlayerSize.height)
                    self.view.layer.addSublayer(self.layer)
                    self.isFinishPresent = true
                }
            }
//            print("shouldBePresent: \(self.shouldBePresent ? 1 : 0), isPresent: \(self.isPresent ? 1 : 0), isFinishPresent: \(self.isFinishPresent ? 1 : 0)")
        })
    }
}

var controllerFS: myViewController? = nil

struct WebrtcPlayer: UIViewControllerRepresentable {
    
    var layer: AVSampleBufferDisplayLayer
    var streamPlayerSize: CGSize
    @Binding var isPresent: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        if controllerFS == nil {
            let controller = myViewController(layer: layer, streamPlayerSize: streamPlayerSize, isPresent: $isPresent)
            if isPresent {
                controllerFS = controller
            }
            return controller
        } else {
            return controllerFS!
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
