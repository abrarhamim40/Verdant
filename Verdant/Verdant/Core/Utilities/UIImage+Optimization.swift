//
//  UIImage+Optimization.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import UIKit

extension UIImage {
    /// Downscales to a max dimension and JPEG-compresses. Plant.id accepts up to 1024px reliably.
    func optimizeForAPI(maxDimension: CGFloat = 1024, compressionQuality: CGFloat = 0.75) -> Data? {
        let resized = resizedIfNeeded(maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compressionQuality)
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
