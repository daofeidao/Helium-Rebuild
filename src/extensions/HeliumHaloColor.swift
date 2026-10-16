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

    /// One tap each. The picker beside them is for everything else.
    static let presets: [Preset] = [
        Preset(name: "White", hex: "#FFFFFF"),
        Preset(name: "Black", hex: "#000000"),
        Preset(name: "Yellow", hex: "#FFCC00"),
        Preset(name: "Orange", hex: "#FF9500"),
        Preset(name: "Cyan", hex: "#00C7BE"),
        Preset(name: "Green", hex: "#34C759"),
        Preset(name: "Blue", hex: "#007AFF"),
        Preset(name: "Pink", hex: "#FF2D55")
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

    /// Anything unreadable falls back to black, which is the halo default.
    static func color(fromHex hex: String) -> Color {
        Color(hex: hex.uppercased()) ?? .black
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
        HStack(spacing: 12) {
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
