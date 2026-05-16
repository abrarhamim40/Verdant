//
//  CameraPicker.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  SwiftUI bridge to UIImagePickerController for live camera capture.
//  Camera is the only iOS capture surface without a pure-SwiftUI equivalent in iOS 17,
//  so a UIViewControllerRepresentable bridge is the standard SwiftUI pattern here.
//
//  Requires Info.plist key NSCameraUsageDescription. On Simulator (no camera), falls
//  back to photoLibrary so the picker remains testable.

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { [weak self] in
                if let image {
                    self?.onCapture(image)
                } else {
                    self?.onCancel()
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [weak self] in
                self?.onCancel()
            }
        }
    }
}
