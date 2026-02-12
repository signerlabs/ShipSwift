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
            ContentUnavailableView(
                "Components",
                systemImage: "square.grid.2x2",
                description: Text("Coming soon")
            )
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentView()
}
