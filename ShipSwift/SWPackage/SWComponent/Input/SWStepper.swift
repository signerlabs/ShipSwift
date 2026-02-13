//
//  SWStepper.swift
//  ShipSwift
//
//  Compact numeric stepper with chevron-style increment/decrement buttons,
//  animated numeric text transitions, and haptic feedback on value change.
//  The decrement button is disabled when the value reaches 0.
//
//  Usage:
//    @State private var quantity = 1
//
//    SWStepper(quantity: $quantity)
//
//  Parameters:
//    quantity — Binding<Int> for the current value (minimum 0)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWStepper: View {
    @Binding var quantity: Int

    var body: some View {
        HStack {
            Button {
                quantity -= 1
            } label: {
                Image(systemName: "chevron.backward")
                    .imageScale(.large)
            }
            .disabled(quantity <= 0)
            .buttonStyle(.plain)

            Text("\(quantity)")
                .frame(minWidth: 26)
                .contentTransition(.numericText())

            Button {
                quantity += 1
            } label: {
                Image(systemName: "chevron.forward")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .animation(.default, value: quantity)
        .sensoryFeedback(.increase, trigger: [quantity])
    }
}

#Preview {
    @Previewable @State var sampleQuantity = 1
    SWStepper(quantity: $sampleQuantity)
}
