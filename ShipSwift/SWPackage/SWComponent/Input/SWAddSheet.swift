//
//  SWAddSheet.swift
//  ShipSwift
//
//  Bottom sheet with a text input field, Cancel and Continue buttons.
//  Presented as a .medium detent sheet for collecting user input (e.g. purpose, wish, notes).
//
//  Usage:
//    @State private var showSheet = false
//
//    Button("Add Item") { showSheet = true }
//    .sheet(isPresented: $showSheet) {
//        SWAddSheet(isPresented: $showSheet) { text in
//            // text is the user input content
//            print("User entered: \(text)")
//        }
//    }
//
//    // Custom title and placeholder text
//    SWAddSheet(
//        isPresented: $showSheet,
//        title: "Your Wish",
//        placeHolderText: "Enter your wish...",
//        minLines: 3
//    ) { text in
//        handleInput(text)
//    }
//
//  Parameters:
//    - isPresented: Binding<Bool>          — Controls sheet show/hide
//    - title: LocalizedStringKey           — Top title (default "Your Generation Purpose")
//    - placeHolderText: LocalizedStringKey — Input field placeholder text
//    - minLines: Int                       — Input field minimum lines (default 5)
//    - onConfirm: ((String) -> Void)?      — Callback when user taps Continue
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWAddSheet: View {
    @Binding var isPresented: Bool
    @State private var inputText = ""

    var title: LocalizedStringKey = "Your Generation Purpose"
    var placeHolderText: LocalizedStringKey = "Enter your purpose/wish/favorite things for this generation (optional)..."
    var minLines: Int = 5
    var onConfirm: ((String) -> Void)?

    var body: some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.horizontal)

            InputField(
                text: $inputText,
                placeHolderText: placeHolderText,
                minLines: minLines
            )

            Spacer()
            Spacer()

            HStack {
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.swSecondary)

                Button {
                    onConfirm?(inputText)
                    isPresented = false
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.swPrimary)
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - InputField (private)

    private struct InputField: View {
        @Binding var text: String
        var placeHolderText: LocalizedStringKey = "Enter message..."
        var minLines: Int = 1

        @FocusState private var isFocused: Bool

        var body: some View {
            TextField(placeHolderText, text: $text, axis: .vertical)
                .lineLimit(minLines...5)
                .focused($isFocused)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.primary, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    VStack {
        Text("Background")
    }
    .sheet(isPresented: $isPresented) {
        SWAddSheet(isPresented: $isPresented)
    }
}
