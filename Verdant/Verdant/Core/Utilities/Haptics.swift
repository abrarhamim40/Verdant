//
//  Haptics.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//
//  Centralized haptic feedback so the whole app uses consistent vibration tastes.
//  Wrap UIKit feedback generators behind one tiny surface — easy to swap to
//  CoreHaptics patterns later (Week 7 polish) without touching call sites.

import UIKit

enum Haptics {
    /// Subtle tick for picking/deselecting items.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Tactile thump when committing to a primary action (Identify, Save).
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Double-buzz for completed long-running work.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Triple-buzz for errors / rejections.
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Two-tone buzz for soft warnings (e.g. cache miss, retry, low confidence).
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
