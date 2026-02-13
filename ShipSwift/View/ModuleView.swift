//
//  ModuleView.swift
//  ShipSwift
//
//  Modules tab — showcases multi-file module components
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ModuleView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SWSettingView()
                    } label: {
                        ListItem(
                            title: "Settings",
                            icon: "gearshape.fill",
                            description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                        )
                    }
                } header: {
                    Text("Settings (1)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
            }
            .navigationTitle("Modules")
        }
    }
}

#Preview {
    ModuleView()
}
