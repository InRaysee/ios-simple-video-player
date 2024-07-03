//
//  SampleData.swift
//  VideoPlayer
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
            Media.self,
            NetworkSource.self
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
        for media in Media.sampleData {
            context.insert(media)
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
    
    var media: Media {
        Media.sampleData[0]
    }
    
    var networkSource: NetworkSource {
        NetworkSource.sampleData[0]
    }
}
