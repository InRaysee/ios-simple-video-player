//
//  LocalMediaDetail.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct LocalMediaDetail: View {
    @Bindable var localMedia: LocalMedia
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \LocalMedia.title) private var localMedias: [LocalMedia]
    
    @State private var showPicker = false
    @State private var selectedVideoURL: URL? = nil
    
    init(localMedia: LocalMedia) {
        self.localMedia = localMedia
    }
    
    var body: some View {
        Form {
            HStack {
                Text("Title: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("title", text: $localMedia.title)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 233)
                    .padding(5)
                    .border(.gray)
            }
            .listRowBackground(Color.white)

            VStack {
                HStack {
                    Text("URL: ")
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    VStack {
                        Text("\(localMedia.mediaURL)")
                        
                        Button("Select video") {
                            showPicker.toggle()
                        }
                        .fontWeight(.medium)
                        .frame(width: 233)
                        .padding(5)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showPicker) {
                        DocumentPickerView { urls in
                            if let firstURL = urls.first {
                                localMedia.mediaURL = firstURL.absoluteString
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white)
        }
        .scrollContentBackground(.hidden)
        .background(.myBackground)
        .navigationTitle("New Media")
        .foregroundStyle(.black)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .disabled(localMedia.title.isEmpty || localMedia.mediaURL.isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    modelContext.delete(localMedia)
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
        LocalMediaDetail(localMedia: SampleData.shared.localMedia)
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(SampleData.shared.modelContainer)
}
