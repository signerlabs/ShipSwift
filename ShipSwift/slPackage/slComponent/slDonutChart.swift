//
//  slDonutChart.swift
//  full-pack
//
//  Created by 仲炜 on 2025/12/14.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI
import Charts

struct slDonutChart: View {
    // MARK: - 内置数据模型

    /// 分类模型
    struct Category: Identifiable, Hashable {
        let id: UUID
        let name: String

        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
        }
    }

    /// 数据项模型
    struct Subject: Identifiable {
        let id: UUID
        let name: String
        let category: Category?

        init(id: UUID = UUID(), name: String, category: Category? = nil) {
            self.id = id
            self.name = name
            self.category = category
        }
    }

    // MARK: - Properties

    let subjects: [Subject]
    @Binding var selectedCategory: String?

    private static let noCategoryKey = "__no_category__"

    // chartAngleSelection 绑定的是累计角度值
    @State private var selectedAngle: Int?

    // 按 category 分组统计
    private var categoryData: [CategoryItem] {
        let grouped = Dictionary(grouping: subjects) { subject -> String in
            guard let category = subject.category else {
                return Self.noCategoryKey  // 没有分类
            }
            return category.name  // 分类名称（可能为空字符串）
        }
        return grouped.map { CategoryItem(name: $0.key, count: $0.value.count) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }  // 数量降序，相同则按名称排序
    }

    private var totalCount: Int {
        subjects.count
    }

    // 分类显示名称
    private func displayName(for categoryName: String) -> String {
        if categoryName == Self.noCategoryKey {
            return String(localized: "No Category")  // 没有分类
        } else if categoryName.isEmpty {
            return String(localized: "Unnamed Category")  // 有分类但名称为空
        }
        return categoryName
    }

    // 根据累计角度值找到对应的分类
    private func findCategory(for angle: Int) -> String? {
        var cumulative = 0
        for item in categoryData {
            cumulative += item.count
            if angle <= cumulative {
                return item.name
            }
        }
        return nil
    }

    // 当前选中分类的数量
    private var selectedCount: Int {
        guard let selected = selectedCategory else { return totalCount }
        return categoryData.first { $0.name == selected }?.count ?? 0
    }

    // 当前选中分类的显示名称
    private var selectedDisplayName: String {
        guard let selected = selectedCategory else {
            return String(localized: "All Items")
        }
        return displayName(for: selected)
    }

    var body: some View {
        Group {
            if categoryData.isEmpty {
                EmptyView()
            } else {
                Chart(categoryData) { item in
                    let isSelected = selectedCategory == item.name
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(isSelected ? 1.0 : 0.9),
                        angularInset: isSelected ? 2 : 1
                    )
                    .cornerRadius(6)
                    // 使用 displayName 作为图例显示，同时保留原始 name 用于选择匹配
                    .foregroundStyle(by: .value("Category", displayName(for: item.name)))
                    .opacity(selectedCategory == nil || isSelected ? 1.0 : 0.3)
                }
                .chartLegend(position: .trailing, alignment: .center, spacing: 16)
                .chartAngleSelection(value: $selectedAngle)
                .onChange(of: selectedAngle) { _, newValue in
                    if let angle = newValue, let category = findCategory(for: angle) {
                        selectedCategory = category
                    } else {
                        selectedCategory = nil
                    }
                }
                .animation(.bouncy, value: selectedCategory)
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        if let plotFrame = proxy.plotFrame {
                            let frame = geometry[plotFrame]
                            VStack(spacing: 2) {
                                Text("\(selectedCount)")
                                    .font(.title.bold())
                                Text(selectedDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(.horizontal)
    }

    struct CategoryItem: Identifiable {
        let name: String
        let count: Int

        var id: String { name }  // 用 name 作为稳定 id，避免重排
    }
}

#Preview {
    @Previewable @State var selectedCategory: String? = nil

    // 示例数据
    let workCategory = slDonutChart.Category(name: "Work")
    let personalCategory = slDonutChart.Category(name: "Personal")
    let healthCategory = slDonutChart.Category(name: "Health")

    let sampleSubjects: [slDonutChart.Subject] = [
        .init(name: "Meeting", category: workCategory),
        .init(name: "Report", category: workCategory),
        .init(name: "Email", category: workCategory),
        .init(name: "Shopping", category: personalCategory),
        .init(name: "Reading", category: personalCategory),
        .init(name: "Exercise", category: healthCategory),
        .init(name: "Meditation", category: healthCategory),
        .init(name: "Running", category: healthCategory),
        .init(name: "Uncategorized Task", category: nil),
    ]

    slDonutChart(subjects: sampleSubjects, selectedCategory: $selectedCategory)
        .padding()
}
