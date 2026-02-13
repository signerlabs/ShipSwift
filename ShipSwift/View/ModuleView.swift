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
                NavigationLink {
                    SWSettingView()
                } label: {
                    ListItem(
                        title: "Settings",
                        icon: "gearshape.fill",
                        description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                    )
                }
            }
            .navigationTitle("Modules")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    
                }
            }
        }
    }
}

#Preview {
    ModuleView()
}
