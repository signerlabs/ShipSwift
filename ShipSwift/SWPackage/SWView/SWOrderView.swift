//
//  SWOrderView.swift
//  ShipSwift
//
//  Animated drink customization demo page showcasing SwiftUI animation capabilities:
//  flavor selection, cup size switching, gradient background animation,
//  matchedGeometryEffect selector, and cup scale/offset animation.
//  Can be used as a reference template for product customization pages.
//
//  Usage:
//    // 1. Present the view directly (best used full-screen; includes built-in gradient background):
//    SWOrderView()
//
//    // 2. Internal components can be reused independently:
//    //    - SWOrderSelector: Capsule-shaped selector with matchedGeometryEffect
//    SWOrderSelector(items: ["S", "M", "L"], sel: $size, ns: sizeNS, label: "Cup Size")
//
//    //    - SWOrderButton: Circular translucent icon button
//    SWOrderButton(icon: "plus") { qty += 1 }
//
//    //    - SWCupView: Animated SF Symbol cup display
//    SWCupView(idx: 0, count: 1, img: "Matcha")
//
//    // 3. Customize flavors/cup sizes: modify the flavors and sizes arrays,
//    //    and add corresponding mappings in SWCupView.sfSymbol and SWOrderView.bg.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWOrderView

struct SWOrderView: View {
    @State private var qty: Int = 1
    @State private var flavor: String = "Matcha"
    @State private var size: String = "Medium"
    @Namespace private var sizeNS
    @Namespace private var flavorNS
    
    private let flavors = ["Matcha", "Chocolate", "Mango"]
    private let sizes = ["Medium", "Large", "XL"]
    
    private var bg: Color {
        switch flavor {
        case "Mango":
            return .orange
        case "Chocolate":
            return .brown
        default:
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            contentView
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [.black, bg],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: flavor)
    }
    
    private var contentView: some View {
        VStack(spacing: 30) {
            cupsSection
            quantityControl
            selectorsSection
            Spacer()
            addToCartButton
        }
    }
    
    private var cupsSection: some View {
        ZStack {
            ForEach(Array(0..<qty), id: \.self) { i in
                SWCupView(idx: i, count: qty, img: flavor)
            }
        }
        .frame(height: 500)
        .animation(.spring(), value: qty)
    }
    
    private var quantityControl: some View {
        SWQuantityControl(qty: $qty)
    }
    
    private var selectorsSection: some View {
        VStack(spacing: 20) {
            SWOrderSelector(items: sizes, sel: $size, ns: sizeNS, label: "Size")
            SWOrderSelector(items: flavors, sel: $flavor, ns: flavorNS, label: "Flavor")
        }
    }
    
    private var addToCartButton: some View {
        Button {
            
        } label: {
            Text("Add to Cart   ¥\(33 * qty)")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.white)
                .foregroundStyle(bg)
                .clipShape(Capsule())
                .padding()
        }
    }
}

// MARK: - SWCupView

struct SWCupView: View {
    let idx: Int
    let count: Int
    let img: String
    
    private var sfSymbol: String {
        switch img {
        case "Matcha":
            return "leaf.fill"
        case "Chocolate":
            return "mug.fill"
        case "Mango":
            return "sun.max.fill"
        default:
            return "cup.and.saucer.fill"
        }
    }
    
    private var isSide: Bool {
        count >= 3 && idx != 1
    }
    
    var body: some View {
        Image(systemName: sfSymbol)
            .font(.system(size: 200))
            .foregroundStyle(.white)
            .scaleEffect(isSide ? 0.7 : 1.0)
            .offset(y: isSide ? 15 : 0)
            .opacity(isSide ? 0.6 : 1)
            .zIndex(count == 3 && idx == 1 ? 10 : Double(idx))
            .shadow(radius: 10, y: 10)
            .animation(.easeInOut, value: img)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.1).combined(with: .offset(x: -50)).combined(with: .opacity),
                removal: .opacity
            ))
    }
}

// MARK: - SWOrderSelector

struct SWOrderSelector: View {
    let items: [String]
    @Binding var sel: String
    var ns: Namespace.ID
    var label: String
    
    var body: some View {
        HStack {
            Text(label)
                .bold()
                .foregroundStyle(.white)
                .frame(width: 60)
            HStack {
                ForEach(items, id: \.self) { item in
                    itemButton(item)
                }
            }
            .padding(4)
            .background(.white.opacity(0.1), in: Capsule())
        }
        .padding(.horizontal)
    }
    
    private func itemButton(_ item: String) -> some View {
        Text(item)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(sel == item ? .white : .white.opacity(0.6))
            .background {
                if sel == item {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .matchedGeometryEffect(id: "selector", in: ns)
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    sel = item
                }
            }
    }
}

// MARK: - SWQuantityControl

struct SWQuantityControl: View {
    @Binding var qty: Int
    
    var body: some View {
        HStack(spacing: 40) {
            Button { if qty > 1 { qty -= 1 } } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white, .ultraThinMaterial)
            }
            
            Text("\(qty)")
                .font(.system(size: 40, weight: .black))
                .contentTransition(.numericText())
                .frame(width: 60)
            
            Button { if qty < 3 { qty += 1 } } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white, .ultraThinMaterial)
            }
        }
        .foregroundStyle(Color.white)
    }
}

// MARK: - SWOrderButton

struct SWOrderButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2), in: Circle())
        }
    }
}

#Preview {
    SWOrderView()
}
