//
//  SWAddSheet.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
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

            ChatInputView(
                text: $inputText,
                onSend: {
                },
                isDisabled: false,
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

    struct ChatInputView: View {
        @Binding var text: String
        var onSend: () -> Void
        var isDisabled: Bool = false
        var placeHolderText: LocalizedStringKey = "Enter message..."
        var minLines: Int = 1

        @FocusState private var isFocused: Bool

        var body: some View {
            HStack(alignment: .bottom, spacing: 12) {
                // Input field
                TextField(placeHolderText, text: $text, axis: .vertical)
                    .lineLimit(minLines...5)
                    .focused($isFocused)
                    .disabled(isDisabled)

                // Send button
                Button {
                    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSend()
                } label: {
                    Image(systemName: "microphone")
                        .imageScale(.large)
                        .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDisabled)
            }
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
        Text("Hi")
    }
    .sheet(isPresented: $isPresented) {
        SWAddSheet(isPresented: $isPresented)
    }
}
