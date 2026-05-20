//
//  UIImage+Optimization.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import UIKit

extension UIImage {
    /// Downscales to a max dimension and JPEG-compresses. Use the named helpers below for
    /// per-API tuning; this generic form remains for tests and edge cases.
    func optimizeForAPI(maxDimension: CGFloat = 1024, compressionQuality: CGFloat = 0.75) -> Data? {
        let resized = resizedIfNeeded(maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    /// Plant.id-tuned: 1024 px max dimension, JPEG quality 0.75. Plant.id favours higher
    /// resolution — variety/cultivar classification needs the detail.
    func optimizedForPlantId() -> Data? {
        optimizeForAPI(maxDimension: 1024, compressionQuality: 0.75)
    }

    /// Gemini-tuned: 512 px max dimension, JPEG quality 0.60. Smaller input cuts vision
    /// input-token cost ~50% while still well above the model's effective resolution floor.
    /// Per blueprint §3.3.
    func optimizedForGemini() -> Data? {
        optimizeForAPI(maxDimension: 512, compressionQuality: 0.60)
    }

    private func resizedIfNeeded(maxDimension: CGFloat) -> UIImage {
        guard size.width > maxDimension || size.height > maxDimension else { return self }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
