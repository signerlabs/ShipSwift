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
//    SWOrderSelector(items: ["S", "M", "L"], sel: $size, ns: sizeNS, label: "Size")
//
//    //    - SWQuantityControl: +/- stepper with numeric text transition
//    SWQuantityControl(qty: $qty)
//
//    //    - SWCupView: Animated cup image display with size-based scaling
//    SWCupView(idx: 0, count: 1, img: "Matcha", size: "Medium")
//
//    // 3. Customize flavors/sizes: modify the flavors and sizes arrays,
//    //    and add corresponding image mappings in SWCupView.image and colors in SWOrderView.bg.
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
    
    private let flavors = ["Matcha", "Chocolate", "Latte"]
    private let sizes = ["Medium", "Large", "XL"]
    
    private var bg: Color {
        switch flavor {
        case "Latte":
            return Color(red: 0.76, green: 0.6, blue: 0.42)
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
                SWCupView(idx: i, count: qty, img: flavor, size: size)
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
    let size: String

    private var image: ImageResource {
        switch img {
        case "Matcha":  return .matcha
        case "Chocolate": return .chocolate
        case "Latte": return .latte
        default: return .latte
        }
    }

    private var cupHeight: CGFloat {
        switch size {
        case "Large": return 320
        case "XL": return 380
        default: return 260
        }
    }

    private var isSide: Bool {
        count == 2 || (count >= 3 && idx != 1)
    }

    private var xOffset: CGFloat {
        switch count {
        case 2:  return idx == 0 ? -60 : 60
        case 3:  return idx == 0 ? -80 : idx == 2 ? 80 : 0
        default: return 0
        }
    }

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(height: cupHeight)
            .scaleEffect(isSide ? 0.75 : 1.0)
            .offset(x: xOffset)
            .zIndex(count == 3 && idx == 1 ? 10 : Double(idx))
            .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
            .animation(.easeInOut, value: img)
            .animation(.easeInOut, value: size)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.1).combined(with: .opacity),
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
