//
//  WebrtcMediaDetail.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct WebrtcMediaDetail: View {
    @Bindable var webrtcMedia: WebrtcMedia
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WebrtcMedia.title) private var webrtcMedias: [WebrtcMedia]
    
    init(webrtcMedia: WebrtcMedia) {
        self.webrtcMedia = webrtcMedia
    }
    
    var body: some View {
        Form {
            HStack {
                Text("Title: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("title", text: $webrtcMedia.title)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 233)
                    .padding(5)
                    .border(.gray)
            }
            .listRowBackground(Color.white)
            
            HStack {
                Text("URL: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("URL", text: $webrtcMedia.mediaURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 233)
                    .padding(5)
                    .border(.gray)
            }
            .listRowBackground(Color.white)
        }
        .scrollContentBackground(.hidden)
        .background(.myBackground)
        .navigationTitle("New WebrtcMedia")
        .foregroundStyle(.black)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .disabled(webrtcMedia.title.isEmpty || webrtcMedia.mediaURL.isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    modelContext.delete(webrtcMedia)
                    dismiss()
                }
            }
        }
        .onAppear {
            UINavigationBar.appearance().titleTextAttributes = [ .foregroundColor: UIColor(.black)]
        }
    }
}

#Preview {
    NavigationStack {
        WebrtcMediaDetail(webrtcMedia: SampleData.shared.webrtcMedia)
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(SampleData.shared.modelContainer)
}
