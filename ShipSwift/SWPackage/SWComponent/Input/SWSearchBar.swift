//
//  SWSearchBar.swift
//  ShipSwift
//
//  Capsule-shaped search bar with a magnifying-glass icon, an inline text
//  field, and an auto-appearing clear button. Uses `.ultraThinMaterial` as
//  its background for a frosted look that sits nicely on top of gradients
//  or glassy surfaces.
//
//  The component does NOT apply any outer horizontal padding — the caller
//  is expected to wrap it with `.padding(.horizontal)` (or similar) so the
//  bar can be reused in different layouts without fighting the caller's
//  spacing rules.
//
//  Usage:
//    @State private var query = ""
//
//    SWSearchBar(text: $query)
//        .padding(.horizontal)
//
//    // With a custom placeholder:
//    SWSearchBar(text: $query, placeholder: "Search contacts")
//        .padding(.horizontal)
//
//  Parameters:
//    text        — two-way binding to the current search string
//    placeholder — prompt shown when the field is empty (default: "Search")
//

import SwiftUI

struct SWSearchBar: View {
    /// Two-way binding to the current search text.
    @Binding var text: String
    /// Placeholder shown when the field is empty.
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Text")
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }
}

#Preview {
    @Previewable @State var text = ""
    SWSearchBar(text: $text)
        .padding()
}
