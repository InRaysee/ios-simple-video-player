//
//  MediaDetail.swift
//  VideoPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct MediaDetail: View {
    @Bindable var media: Media
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Media.title) private var medias: [Media]
    
    init(media: Media) {
        self.media = media
    }
    
    var body: some View {
        Form {
            HStack {
                Text("Title: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("title", text: $media.title)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 233)
                    .padding(5)
                    .border(.gray)
            }
            
            HStack(spacing: 4.0) {
                Text("File: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("name", text: $media.mediaName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 150)
                    .padding(5)
                    .border(.gray)
                
                Text(".")
                    .frame(width: 5)
                
                TextField("type", text: $media.mediaType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 60)
                    .padding(5)
                    .border(.gray)
            }
        }
        .navigationTitle("New Media")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .disabled(media.title.isEmpty || media.mediaName.isEmpty || media.mediaType.isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    modelContext.delete(media)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MediaDetail(media: SampleData.shared.media)
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(SampleData.shared.modelContainer)
}
