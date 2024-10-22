//
//  NetworkSourceDetail.swift
//  StreamPlayer
//
//  Created by InRaysee on 2024/7/3.
//

import SwiftUI
import SwiftData

struct NetworkSourceDetail: View {
    @Bindable var networkSource: NetworkSource
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \NetworkSource.title) private var networkSources: [NetworkSource]
    
    init(networkSource: NetworkSource) {
        self.networkSource = networkSource
    }
    
    var body: some View {
        Form {
            HStack {
                Text("Title: ")
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("title", text: $networkSource.title)
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
                
                TextField("URL", text: $networkSource.mediaURL)
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
        .navigationTitle("New NetworkSource")
        .foregroundStyle(.black)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .disabled(networkSource.title.isEmpty || networkSource.mediaURL.isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    modelContext.delete(networkSource)
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
        NetworkSourceDetail(networkSource: SampleData.shared.networkSource)
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(SampleData.shared.modelContainer)
}
