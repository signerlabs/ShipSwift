//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab placeholder — will be replaced with component showcase list
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ComponentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SWBeforeAfterSlider(before: Image(.smileBefore), after: Image(.smileAfter))
                    } label: {
                        ListItem(
                            title: "Before / After",
                            icon: "slider.horizontal.below.rectangle",
                            description: "Image comparison view with auto-oscillating slider and drag gesture. Supports custom labels, speed, and aspect ratio."
                        )
                    }
                } header: {
                    Text("Animation")
                        .font(.title3.bold())
                } footer: {

                }
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentView()
}
