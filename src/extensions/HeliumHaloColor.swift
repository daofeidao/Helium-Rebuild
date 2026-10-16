//
//  HeliumHaloColor.swift
//
//  The text halo's colours.
//

import SwiftUI

/// Halo colours travel through the plist as "#RRGGBB" / "#RRGGBBAA" strings
/// rather than as an archived UIColor, so the stored value next to the text
/// colour stays something a person can read and a test can check.
enum HeliumHaloColor {
    struct Preset: Identifiable {
        let name: String
        let hex: String
        var id: String { hex }
    }

    /// Eight colours that are actually eight colours. The first list paired off
    /// yellow/orange, cyan/blue and red/pink, which reads as the same colour
    /// twice in a row of small circles; these are spread further apart, and the
    /// grey is there because a black outline is often harsher than wanted.
    static let presets: [Preset] = [
        Preset(name: "White", hex: "#FFFFFF"),
        Preset(name: "Black", hex: "#000000"),
        Preset(name: "Grey", hex: "#8E8E93"),
        Preset(name: "Red", hex: "#FF3B30"),
        Preset(name: "Orange", hex: "#FF9500"),
        Preset(name: "Green", hex: "#34C759"),
        Preset(name: "Blue", hex: "#0A84FF"),
        Preset(name: "Purple", hex: "#BF5AF2")
    ]

    /// The same shape the HUD parses: six digits, plus alpha only when the
    /// colour is not fully opaque.
    static func hex(from color: Color) -> String {
        let ui = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#000000"
        }
        func channel(_ value: CGFloat) -> Int {
            max(0, min(255, Int((value * 255).rounded())))
        }
        if alpha >= 0.999 {
            return String(format: "#%02X%02X%02X", channel(red), channel(green), channel(blue))
        }
        return String(format: "#%02X%02X%02X%02X", channel(red), channel(green), channel(blue), channel(alpha))
    }

    /// Parsed here rather than with the shared `Color(hex:)`. That initialiser
    /// masks the six-digit form eight bits too low, so every six-digit colour
    /// comes out as (0, 1, 1): the whole palette used to draw as one cyan, which
    /// looks exactly like a palette full of duplicates. Reading the value in
    /// this order is the whole point of the function, so do not "simplify" it
    /// back to the shared one.
    static func color(fromHex hex: String) -> Color {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if text.hasPrefix("#") {
            text.removeFirst()
        }
        guard text.count == 6 || text.count == 8, let value = UInt32(text, radix: 16) else {
            // Anything unreadable falls back to black, which is the halo default.
            return .black
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
        if text.count == 8 {
            // RRGGBBAA
            red = Double((value >> 24) & 0xFF) / 255.0
            green = Double((value >> 16) & 0xFF) / 255.0
            blue = Double((value >> 8) & 0xFF) / 255.0
            alpha = Double(value & 0xFF) / 255.0
        } else {
            // RRGGBB
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
            alpha = 1.0
        }
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static func isSelected(_ color: Color, _ preset: Preset) -> Bool {
        hex(from: color).uppercased() == preset.hex.uppercased()
    }
}

/// The row of colour swatches, shared by the outline and the glow so the two
/// cannot drift apart.
struct HeliumHaloPresetRow: View {
    @Binding var selection: Color
    @Binding var changesMade: Bool

    var body: some View {
        HStack(spacing: 10) {
            ForEach(HeliumHaloColor.presets) { preset in
                Circle()
                    .fill(HeliumHaloColor.color(fromHex: preset.hex))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                            .opacity(HeliumHaloColor.isSelected(selection, preset) ? 1 : 0)
                    )
                    .onTapGesture {
                        selection = HeliumHaloColor.color(fromHex: preset.hex)
                        changesMade = true
                    }
                    .accessibilityLabel(Text(verbatim: preset.name))
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
