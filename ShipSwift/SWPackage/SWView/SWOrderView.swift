import SwiftUI

// MARK: - SWOrderView
// Core logic: color changes, layout, state

struct SWOrderView: View {
    @State private var qty: Int = 1
    @State private var flavor: String = "抹茶"
    @State private var size: String = "中杯"
    @Namespace private var sizeNS
    @Namespace private var flavorNS

    private let flavors = ["抹茶", "巧克力", "芒果"]
    private let sizes = ["中杯", "大杯", "超大杯"]

    private var bg: Color {
        switch flavor {
        case "芒果":
            return .orange
        case "巧克力":
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
        .frame(height: 240)
    }

    @ViewBuilder
    private var quantityControl: some View {
        HStack(spacing: 40) {
//            SWOrderButton(icon: "minus") {
//
////                guard qty > 1 else { return }
//                withAnimation(.spring()) {
//                    qty -= 1
//                }
//            }
//
//            Text("\(qty)")
//                .font(.system(size: 40, weight: .black))
//                .contentTransition(.numericText)
//
//            SWOrderButton(icon: "plus") {
////                guard qty < 3 else { return }
//                withAnimation(.spring()) {
//                    qty += 1
//                }
//            }
        }
//        .foregroundStyle(.white)
    }

    private var selectorsSection: some View {
        VStack(spacing: 20) {
            SWOrderSelector(items: sizes, sel: $size, ns: sizeNS, label: "杯型")
            SWOrderSelector(items: flavors, sel: $flavor, ns: flavorNS, label: "口味")
        }
    }

    private var addToCartButton: some View {
        Text("添加至购物车   ¥\(33 * qty)")
            .font(.title3.bold())
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(.white)
            .foregroundStyle(bg)
            .clipShape(Capsule())
            .padding()
            .padding(.top, 60)
    }
}

// MARK: - SWCupView

struct SWCupView: View {
    let idx: Int
    let count: Int
    let img: String

    private var sfSymbol: String {
        switch img {
        case "抹茶":
            return "leaf.fill"
        case "巧克力":
            return "mug.fill"
        case "芒果":
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
            .font(.system(size: 100))
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
