//
//  SWDonutChart.swift
//  ShipSwift
//
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI
import Charts

struct SWDonutChart: View {
    // MARK: - Built-in Data Models

    /// Category model
    struct Category: Identifiable, Hashable {
        let id: UUID
        let name: String

        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
        }
    }

    /// Data item model
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

    // chartAngleSelection binds to cumulative angle value
    @State private var selectedAngle: Int?

    // Group and count by category
    private var categoryData: [CategoryItem] {
        let grouped = Dictionary(grouping: subjects) { subject -> String in
            guard let category = subject.category else {
                return Self.noCategoryKey  // No category
            }
            return category.name  // Category name (may be empty string)
        }
        return grouped.map { CategoryItem(name: $0.key, count: $0.value.count) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }  // Descending by count, then alphabetical
    }

    private var totalCount: Int {
        subjects.count
    }

    // Category display name
    private func displayName(for categoryName: String) -> String {
        if categoryName == Self.noCategoryKey {
            return String(localized: "No Category")
        } else if categoryName.isEmpty {
            return String(localized: "Unnamed Category")
        }
        return categoryName
    }

    // Find the category corresponding to the cumulative angle value
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

    // Count for the currently selected category
    private var selectedCount: Int {
        guard let selected = selectedCategory else { return totalCount }
        return categoryData.first { $0.name == selected }?.count ?? 0
    }

    // Display name for the currently selected category
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
                    // Use displayName for legend display while keeping original name for selection matching
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

        var id: String { name }  // Use name as stable id to avoid reordering
    }
}

#Preview {
    @Previewable @State var selectedCategory: String? = nil

    // Sample data
    let workCategory = SWDonutChart.Category(name: "Work")
    let personalCategory = SWDonutChart.Category(name: "Personal")
    let healthCategory = SWDonutChart.Category(name: "Health")

    let sampleSubjects: [SWDonutChart.Subject] = [
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

    SWDonutChart(subjects: sampleSubjects, selectedCategory: $selectedCategory)
        .padding()
}
