//
//  slAddSheet.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

struct slAddSheet: View {
    @Binding var isPresented: Bool
    @State private var inputText = ""
    
    var title: String = "您的生成目的"
    var placeHolderText: String = "请输入本次生成的目的/心愿/喜欢的事等（可跳过）…"
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
                    Text("取消")
                }
                .buttonStyle(.slSecondary)
                
                Button {
                    onConfirm?(inputText)
                    isPresented = false
                } label: {
                    Text("继续")
                }
                .buttonStyle(.slPrimary)
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
        var placeHolderText = "输入消息..."
        var minLines: Int = 1
        
        @FocusState private var isFocused: Bool
        
        var body: some View {
            HStack(alignment: .bottom, spacing: 12) {
                // 输入框
                TextField(placeHolderText, text: $text, axis: .vertical)
                    .lineLimit(minLines...5)
                    .focused($isFocused)
                    .disabled(isDisabled)
                
                // 发送按钮
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
        slAddSheet(isPresented: $isPresented)
    }
}
