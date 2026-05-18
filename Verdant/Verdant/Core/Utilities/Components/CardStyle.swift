//
//  CardStyle.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Reusable card-depth view modifiers + a pressable button style. Replaces
//  the flat tinted backgrounds across the app with dimensional surfaces
//  (subtle shadow, optional accent tint, light border) so cards read as
//  layered objects instead of colored shapes.

import SwiftUI

extension View {
    /// Default app card: white-on-cream surface with a soft drop shadow and a
    /// hairline border. Use for neutral cards (plant grid, scan history rows,
    /// completed reminders).
    func appCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, tint: nil))
    }

    /// Tinted accent card. Use when the card itself communicates urgency or
    /// category (overdue = terracotta, treatment = forestGreen, etc.). Same
    /// shadow/border as appCard, just with a colored fill instead of white.
    func accentCard(tint: Color, intensity: Double = 0.10, cornerRadius: CGFloat = 16) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, tint: tint.opacity(intensity)))
    }
}

private struct AppCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(surfaceFill)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(colorScheme == .dark ? 0.06 : 0.5), lineWidth: 0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
    }

    private var surfaceFill: Color {
        if let tint { return tint }
        return colorScheme == .dark ? Color.white.opacity(0.05) : Color.white
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.06)
    }
}

/// Tap feedback for any pressable surface — slight scale + opacity dip while
/// the finger is down. Use with `.buttonStyle(.pressable)` on Buttons that
/// wrap card content (PlantCard, ReminderCard, etc.).
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static func pressable(scale: CGFloat) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale)
    }
}
