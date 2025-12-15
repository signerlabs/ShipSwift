//
//  slStepper.swift
//  full-pack
//
//  Created by Wei on 2025/5/29.
//

import SwiftUI

struct slStepper: View {
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
    slStepper(quantity: $sampleQuantity)
}
