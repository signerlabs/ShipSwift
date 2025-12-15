//
//  SLRiveLoader.swift
//  full-pack
//
//  Created by Wei on 2025/5/15.
//

//import SwiftUI
//import RiveRuntime
//
//struct SLRiveLoader: View {
//    @State var riveLoader = RiveViewModel(
//        fileName: "loader",
//        autoPlay: true
//    )
//    
//    var body: some View {
//        VStack {
//            riveLoader.view()
//                .scaledToFit()
//                .frame(height: 200)
//                .onTapGesture {
//                    riveLoader.triggerInput("tap")
//                }
//            
//            Text("Processing...")
//                .foregroundStyle(.secondary)
//                .padding(.top, -20)
//                .padding(.bottom)
//            
//            Button {
//                riveLoader.triggerInput("tap")
//            } label: {
//                Image(systemName: "pawprint.circle.fill")
//                    .foregroundStyle(.ultraThickMaterial, .customGreen)
//                    .font(.system(size: 60))
//                    .shadow(color: .accent, radius: 2, x: 1, y: 1)
//            }
//        }
//    }
//}
//
//#Preview {
//    SLRiveLoader()
//}
