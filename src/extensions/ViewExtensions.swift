//
//  ViewExtensions.swift
//  
//
//  Created by lemin on 10/13/23.
//

import Foundation
import SwiftUI

// MARK: Tinted Button Style
struct TintedButton: ButtonStyle {
    var color: Color
    var fullWidth: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if fullWidth {
                configuration.label
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(AnyView(color.opacity(0.2)))
                    .cornerRadius(8)
                    .foregroundColor(color)
            } else {
                configuration.label
                    .padding(15)
                    .background(AnyView(color.opacity(0.2)))
                    .cornerRadius(8)
                    .foregroundColor(color)
            }
        }
    }
    
    init(color: Color = .blue, fullWidth: Bool = false) {
        self.color = color
        self.fullWidth = fullWidth
    }
}

// MARK: Extended Slider
struct BetterSlider: View {
    @Binding var value: Double
    var bounds: ClosedRange<Double>
    var step: Double.Stride? = nil
    
    var inputTitle: String = NSLocalizedString("Enter Value", comment:"")
    var inputBody: String = NSLocalizedString("Enter a value.", comment:"")
    
    /// Called with true when the drag starts and false when it ends. Sliders are
    /// a general-purpose control, but a screen that wants to act on "the user has
    /// let go" -- the widget preview does -- has to be told, and this is the only
    /// place that knows.
    var onEditingChanged: ((Bool) -> Void)? = nil
    
    var body: some View {
        HStack {
            if step == nil {
                Slider(value: $value, in: bounds, onEditingChanged: { editing in
                    onEditingChanged?(editing)
                })
            } else {
                Slider(value: $value, in: bounds, step: step!, onEditingChanged: { editing in
                    onEditingChanged?(editing)
                })
            }
            Spacer()
            Button(action: {
                UIApplication.shared.inputAlert(title: inputTitle, body: inputBody, onOK: { val in
                    var finalVal: Double = Double(val) ?? value
                    // make sure it is within bounds, then set it
                    if (finalVal > bounds.upperBound) {
                        finalVal = bounds.upperBound
                    } else if (finalVal < bounds.lowerBound) {
                        finalVal = bounds.lowerBound
                    }
//                    if step != nil {
//                        // make sure it is within the step
//                        finalVal = finalVal.truncatingRemainder(dividingBy: step!)
//                    }
                    value = finalVal
                    // Typing a value ends the edit just as letting go of the
                    // slider does: the caller is told, and nothing is left
                    // half-applied.
                    onEditingChanged?(false)
                }, noCancel: false)
            }) {
                Text(String(format: "%.2f", value))
            }
        }
    }
}

/// A slider with a triangle at each end that moves the value by a fixed small
/// amount. It exists for the offsets: the travel covers 200 points, so one pixel
/// of finger movement is several points of offset, and a tap is the only way to
/// land on an exact value. It is also the only control here that reports "the
/// user has finished", which is what the widget preview saves on.
struct NudgeSlider: View {
    @Binding var value: Double
    var bounds: ClosedRange<Double>
    var step: Double
    /// The offsets move the widget up and down rather than left and right when
    /// this is set. Positive is still down, so the two triangles swap over: with
    /// a value that grows to the right, the up end is the left one.
    var vertical: Bool = false
    var onCommit: () -> Void
    
    var body: some View {
        // The triangle at an end is the direction the widget goes when that end
        // is pushed: pressing it takes a step, and dragging towards it does the
        // same thing, because dragging towards an end moves the value that way.
        // For the offsets that means the widget follows the triangle, which is
        // the whole point of the control.
        //
        // The vertical pair is therefore up on the left and down on the right --
        // a bigger value is further down, so the down end of a slider that grows
        // to the right is the right one. It read the other way round before, and
        // pressing down moved the widget up.
        HStack(spacing: 8) {
            nudgeButton(vertical ? "arrowtriangle.up.fill" : "arrowtriangle.left.fill", delta: -step)
            BetterSlider(value: $value, bounds: bounds, onEditingChanged: { editing in
                if !editing {
                    onCommit()
                }
            })
            nudgeButton(vertical ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill", delta: step)
        }
    }
    
    private func nudgeButton(_ symbol: String, delta: Double) -> some View {
        Button(action: {
            let next = min(bounds.upperBound, max(bounds.lowerBound, value + delta))
            guard next != value else { return }
            value = next
            // A tap is a finished edit on its own: there is no drag to end.
            onCommit()
        }) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .frame(width: 30, height: 32)
                .contentShape(Rectangle())
        }
        // Without this the whole row is the button, and a tap on a triangle
        // would open the widget instead of moving it.
        .buttonStyle(.borderless)
    }
}
