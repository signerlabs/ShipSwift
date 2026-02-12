//
//  ModuleView.swift
//  ShipSwift
//
//  Modules tab placeholder — will be replaced with module showcase list
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ModuleView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Modules",
                systemImage: "puzzlepiece.extension",
                description: Text("Coming soon")
            )
            .navigationTitle("Modules")
        }
    }
}

#Preview {
    ModuleView()
}
