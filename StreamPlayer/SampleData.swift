//
//  SampleData.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
        let schema = Schema([
            LocalMedia.self,
            NetworkSource.self,
            WebrtcMedia.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            insertSampleData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    func insertSampleData() {
        for localMedia in LocalMedia.sampleData {
            context.insert(localMedia)
        }
        
        for networkSource in NetworkSource.sampleData {
            context.insert(networkSource)
        }
        
        do {
            try context.save()
        } catch {
            print("Sample data context failed to save.")
        }
    }
    
    var localMedia: LocalMedia {
        LocalMedia.sampleData[0]
    }
    
    var networkSource: NetworkSource {
        NetworkSource.sampleData[0]
    }
    
    var webrtcMedia: WebrtcMedia {
        WebrtcMedia.sampleData[0]
    }
}
