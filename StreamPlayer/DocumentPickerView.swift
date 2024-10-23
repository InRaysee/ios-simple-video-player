//
//  DocumentPickerView.swift
//  StreamPlayer
//
//  Created by Feng Fangzheng on 2024/10/22.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// SwiftUI View: DocumentPickerView
struct DocumentPickerView: UIViewControllerRepresentable {

    // Callback for processing the URL selected by the user
    var onDocumentsPicked: ([URL]) -> Void

    // Create and configure UIDocumentPickerViewController
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.content, UTType.item])
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator  // Setting Up Delegation
        return documentPicker
    }

    // Update UIDocumentPickerViewController (not usually needed)
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    // Creating a Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator for handling UIDocumentPickerViewControllerDelegate
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        // The user selects the file
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Call the SwiftUI callback to pass the URL of the selected file
            parent.onDocumentsPicked(urls)
        }

        // User deselected the file
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }
}
