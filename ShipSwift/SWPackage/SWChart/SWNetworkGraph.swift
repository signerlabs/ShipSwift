//
//  SWNetworkGraph.swift
//  ShipSwift
//
//  Interactive 3D network graph rendered with a single SwiftUI `Canvas`
//  per frame — a dependency map ("knowledge graph") of colored dots linked
//  by prerequisite edges, floating in a slowly spinning 3D funnel.
//  Inspired by the curriculum map at withmarble.com.
//
//  Mechanics ported from the original (all hand-rolled, no SceneKit):
//    - 3D funnel layout: each node gets a deterministic (x, y, z) from its
//      `level` (0 = foundation, bottom → 1 = frontier, top) via golden-angle
//      rings with hash-based jitter, then a Y-rotation + tilt matrix and
//      one-axis perspective projection (screen = world · f / (f + z)).
//    - Idle auto-spin that pauses while dragging or when a node is selected.
//    - Grow-in intro: nodes appear bottom-up, gated by `level` against an
//      elapsed-time threshold (disabled under Reduce Motion).
//    - Drag to orbit (rotY + clamped tilt), pinch to zoom (0.5–4×).
//    - Tap a dot to select: BFS walks the full prerequisite lineage; lineage
//      nodes/edges glow while everything else dims, and the camera tweens
//      so the node faces front-center. Tap empty space to clear.
//    - Depth cues: painter's-algorithm draw order, distance fog on alpha,
//      dark rim ring per dot, white focus ring on the selected node.
//
//  Built-in chrome (each can be turned off):
//    - A filter toolbar button (top trailing) that opens a sheet listing one
//      row per `group` with Select All / Clear All shortcuts. The toolbar
//      item needs an enclosing NavigationStack to be visible.
//    - A detail sheet for the selected node (medium detent, background
//      interaction stays enabled so the graph can still be orbited) with the
//      total prerequisite count and tappable "builds on" / "unlocks" rows
//      plus a back stack.
//
//  Requires iOS 17+ / macOS 14+ (SwiftUI `TimelineView`, `Canvas`,
//  `MagnifyGesture`).
//
//  Usage:
//    // Bundled sample data (mini skill tree)
//    SWNetworkGraph(
//        nodes: SWNetworkGraph.sampleNodes,
//        edges: SWNetworkGraph.sampleEdges
//    )
//    .ignoresSafeArea()
//
//    // Your own graph
//    SWNetworkGraph(
//        nodes: [
//            .init(id: "count", title: "Counting", group: "Math",
//                  color: .blue, level: 0.05),
//            .init(id: "add", title: "Addition", group: "Math",
//                  color: .blue, level: 0.25),
//        ],
//        edges: [
//            .init(from: "add", to: "count"),  // Addition builds on Counting
//        ],
//        onNodeSelected: { node in print(node?.title ?? "cleared") }
//    )
//
//  Parameters:
//    - nodes:           Graph nodes (see `SWNetworkGraphNode`).
//    - edges:           Directed edges; `from` depends on `to`
//                       (`to` is the prerequisite).
//    - background:      Background fill (default deep navy).
//    - spinSpeed:       Idle rotation in radians/second (default 0.18).
//    - growDuration:    Seconds for the bottom-up intro (default 2.8).
//    - showsLegend:     Add the filter toolbar button + sheet (default `true`;
//                       requires an enclosing NavigationStack).
//    - showsCard:       Present the selection detail sheet (default `true`).
//    - onNodeSelected:  Called with the node on select, `nil` on clear.
//

import SwiftUI

// MARK: - Data Model

/// One dot in the graph. `level` drives both the funnel height and the
/// grow-in order (0 = bottom / appears first, 1 = top / appears last).
struct SWNetworkGraphNode: Identifiable, Hashable {
    let id: String
    var title: String
    var subtitle: String? = nil
    var group: String = ""
    var color: Color = .blue
    var level: Double = 0.5
    /// Relative dot size, 0...1 (default 0.3).
    var weight: Double = 0.3
}

/// Directed dependency: `from` builds on `to` (`to` is the prerequisite).
struct SWNetworkGraphEdge: Hashable {
    var from: String
    var to: String

    init(from: String, to: String) {
        self.from = from
        self.to = to
    }
}

// MARK: - Main View

struct SWNetworkGraph: View {
    var nodes: [SWNetworkGraphNode]
    var edges: [SWNetworkGraphEdge]
    var background: Color = Color(red: 0.04, green: 0.05, blue: 0.09)
    var spinSpeed: Double = 0.18
    var growDuration: Double = 2.8
    var showsLegend: Bool = true
    var showsCard: Bool = true
    var onNodeSelected: ((SWNetworkGraphNode?) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var camera = SWNetworkGraphCamera()
    @State private var selected: Int? = nil
    @State private var history: [Int] = []
    @State private var lineageNodes: Set<Int> = []
    @State private var lineageEdges: Set<Int> = []
    @State private var hiddenGroups: Set<String> = []
    @State private var pinchBaseZoom: Double? = nil
    @State private var filterPresented = false

    private var resolved: SWNetworkGraphResolved {
        SWNetworkGraphResolved(nodes: nodes, edges: edges)
    }

    /// Detail sheet presentation, driven by the selection; dismissing the
    /// sheet (swipe or Done) clears the selection.
    private var cardPresented: Binding<Bool> {
        Binding(
            get: { showsCard && selected != nil },
            set: { if !$0 { clearSelection() } }
        )
    }

    var body: some View {
        let graph = resolved
        canvasLayer(graph)
            .background(background)
            .toolbar {
                if showsLegend {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            // Only one sheet can be up at a time; drop the
                            // detail sheet before presenting the filter.
                            clearSelection()
                            filterPresented = true
                        } label: {
                            Image(systemName: hiddenGroups.isEmpty
                                  ? "line.3.horizontal.decrease.circle"
                                  : "line.3.horizontal.decrease.circle.fill")
                        }
                        .accessibilityLabel("Graph Filters")
                    }
                }
            }
            .sheet(isPresented: $filterPresented) {
                filterSheet(graph)
            }
            .sheet(isPresented: cardPresented) {
                detailSheet(graph)
            }
            .onChange(of: nodes) { _, _ in clearSelection() }
            .onChange(of: edges) { _, _ in clearSelection() }
    }

    // MARK: Canvas

    private func canvasLayer(_ graph: SWNetworkGraphResolved) -> some View {
        TimelineView(.animation) { timeline in
            Canvas { gc, size in
                camera.step(
                    now: timeline.date,
                    spinSpeed: spinSpeed,
                    growDuration: growDuration,
                    idle: selected == nil,
                    reduceMotion: reduceMotion
                )
                camera.viewSize = size
                drawGraph(graph, in: &gc, size: size)
            }
        }
        .contentShape(Rectangle())
        .gesture(orbitGesture(graph).simultaneously(with: zoomGesture))
    }

    private func drawGraph(_ graph: SWNetworkGraphResolved, in gc: inout GraphicsContext, size: CGSize) {
        let proj = camera.project(positions: graph.positions, in: size)
        let grow = reduceMotion ? 1.02 : camera.grow
        let hasSelection = !lineageNodes.isEmpty

        func nodeVisible(_ i: Int) -> Bool {
            !hiddenGroups.contains(graph.nodes[i].group) && graph.nodes[i].level <= grow
        }

        // Edges first, behind dots.
        for (k, edge) in graph.edgeIndices.enumerated() {
            let (a, b) = edge
            guard nodeVisible(a), nodeVisible(b) else { continue }
            var path = Path()
            path.move(to: CGPoint(x: proj[a].x, y: proj[a].y))
            path.addLine(to: CGPoint(x: proj[b].x, y: proj[b].y))
            if hasSelection, lineageEdges.contains(k) {
                gc.stroke(path, with: .color(graph.nodes[b].color.opacity(0.75)), lineWidth: 1.6)
            } else {
                let alpha = hasSelection ? 0.04 : 0.06
                let depth = (proj[a].scale + proj[b].scale) / 2
                gc.stroke(
                    path,
                    with: .color(Color(red: 0.59, green: 0.65, blue: 0.80).opacity(alpha * depth)),
                    lineWidth: 1
                )
            }
        }

        // Dots far-to-near (painter's algorithm).
        let order = proj.indices.sorted { proj[$0].scale < proj[$1].scale }
        for i in order {
            guard nodeVisible(i) else { continue }
            let node = graph.nodes[i]
            let inLineage = hasSelection ? lineageNodes.contains(i) : true
            let isFocus = i == selected
            let dim = (hasSelection && !inLineage) ? 0.10 : 1.0
            let p = proj[i]
            let radius = camera.dotRadius(weight: node.weight, depthScale: p.scale) * (isFocus ? 1.6 : 1)
            let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
            // Distance fog: farther dots fade toward the background.
            let alpha = dim * (0.55 + 0.45 * min(1, p.scale * p.scale))

            if isFocus || (hasSelection && inLineage) {
                gc.drawLayer { layer in
                    layer.addFilter(.shadow(color: node.color, radius: isFocus ? 9 : 4.5))
                    layer.fill(Path(ellipseIn: rect), with: .color(node.color.opacity(alpha)))
                }
            } else {
                gc.fill(Path(ellipseIn: rect), with: .color(node.color.opacity(alpha)))
            }
            // Dark rim ring separates same-color neighbors.
            gc.stroke(
                Path(ellipseIn: rect),
                with: .color(Color(red: 0.03, green: 0.04, blue: 0.07).opacity(0.5 * dim)),
                lineWidth: 1
            )
            if isFocus {
                gc.stroke(
                    Path(ellipseIn: rect.insetBy(dx: -2.5, dy: -2.5)),
                    with: .color(.white.opacity(0.95)),
                    lineWidth: 1.6
                )
            }
        }
    }

    // MARK: Gestures

    private func orbitGesture(_ graph: SWNetworkGraphResolved) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let last = camera.lastDragLocation ?? value.startLocation
                let dx = value.location.x - last.x
                let dy = value.location.y - last.y
                camera.lastDragLocation = value.location
                camera.dragging = true
                let moved = hypot(value.translation.width, value.translation.height)
                if moved > 3 { camera.dragMoved = true }
                camera.rotY += dx * 0.0055
                camera.tilt = max(-1.1, min(0.15, camera.tilt - dy * 0.003))
            }
            .onEnded { value in
                let wasTap = !camera.dragMoved
                camera.lastDragLocation = nil
                camera.dragging = false
                camera.dragMoved = false
                guard wasTap else { return }
                if let hit = pick(at: value.location, in: graph) {
                    select(hit, in: graph, pushHistory: true)
                } else {
                    clearSelection()
                }
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = pinchBaseZoom ?? camera.zoom
                pinchBaseZoom = base
                camera.zoom = max(0.5, min(4, base * value.magnification))
            }
            .onEnded { _ in pinchBaseZoom = nil }
    }

    private func pick(at point: CGPoint, in graph: SWNetworkGraphResolved) -> Int? {
        let proj = camera.project(positions: graph.positions, in: camera.viewSize)
        let grow = reduceMotion ? 1.02 : camera.grow
        var best: Int? = nil
        var bestDist = 20.0 * 20.0
        for i in graph.nodes.indices {
            let node = graph.nodes[i]
            guard !hiddenGroups.contains(node.group), node.level <= grow else { continue }
            let dx = proj[i].x - point.x
            let dy = proj[i].y - point.y
            let dist = dx * dx + dy * dy
            let reach = max(11, camera.dotRadius(weight: node.weight, depthScale: proj[i].scale) + 6)
            if dist < reach * reach, dist < bestDist {
                bestDist = dist
                best = i
            }
        }
        return best
    }

    // MARK: Selection

    private func select(_ index: Int, in graph: SWNetworkGraphResolved, pushHistory: Bool) {
        if pushHistory, let current = selected, current != index {
            history.append(current)
        }
        selected = index
        (lineageNodes, lineageEdges) = graph.lineage(of: index)
        camera.focus(on: graph.positions[index])
        onNodeSelected?(graph.nodes[index])
    }

    private func clearSelection() {
        guard selected != nil else { return }
        selected = nil
        history.removeAll()
        lineageNodes.removeAll()
        lineageEdges.removeAll()
        camera.clearFocus()
        onNodeSelected?(nil)
    }

    // MARK: Filter Sheet

    private func filterSheet(_ graph: SWNetworkGraphResolved) -> some View {
        NavigationStack {
            List {
                Section {
                    ForEach(graph.groups, id: \.name) { group in
                        let isOff = hiddenGroups.contains(group.name)
                        Button {
                            if isOff { hiddenGroups.remove(group.name) }
                            else { hiddenGroups.insert(group.name) }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: 10, height: 10)
                                Text(group.name)
                                Text("\(group.count)")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: isOff ? "circle" : "checkmark.circle.fill")
                                    .foregroundStyle(isOff ? .secondary : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Groups (\(graph.groups.count))")
                        Spacer()
                        Button("Select All") { hiddenGroups.removeAll() }
                            .disabled(hiddenGroups.isEmpty)
                        Button("Clear All") { hiddenGroups = Set(graph.groups.map(\.name)) }
                            .disabled(hiddenGroups.count == graph.groups.count)
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle("Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { filterPresented = false }
                }
            }
        }
        .presentationDetents([.fraction(0.3), .medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Detail Sheet

    private func detailSheet(_ graph: SWNetworkGraphResolved) -> some View {
        NavigationStack {
            if let index = selected, index < graph.nodes.count {
                let node = graph.nodes[index]
                let totalPrereqs = max(0, lineageNodes.count - 1)
                List {
                    Section {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(node.color)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                if let subtitle = cardSubtitle(node) {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(totalPrereqs == 1
                                     ? "1 prerequisite in total"
                                     : "\(totalPrereqs) prerequisites in total")
                                    .font(.callout.monospacedDigit())
                            }
                        }
                    }
                    cardRows(graph, title: "Builds on", indices: graph.directPrerequisites[index])
                    cardRows(graph, title: "Unlocks", indices: graph.directUnlocks[index])
                }
                .navigationTitle(node.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    if !history.isEmpty {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                if let previous = history.popLast() {
                                    select(previous, in: graph, pushHistory: false)
                                }
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .accessibilityLabel("Back")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { clearSelection() }
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.3), .medium, .large])
        .presentationDragIndicator(.visible)
        // Keep the graph interactive behind the sheet so users can still
        // orbit and tap other dots while reading the details.
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    private func cardSubtitle(_ node: SWNetworkGraphNode) -> String? {
        switch (node.group.isEmpty, node.subtitle) {
        case (false, .some(let sub)): return "\(node.group) · \(sub)"
        case (false, .none): return node.group
        case (true, .some(let sub)): return sub
        case (true, .none): return nil
        }
    }

    private func cardRows(_ graph: SWNetworkGraphResolved, title: String, indices: [Int]) -> some View {
        Section(title) {
            if indices.isEmpty {
                Text("nothing yet")
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(indices, id: \.self) { j in
                    Button {
                        select(j, in: graph, pushHistory: true)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(graph.nodes[j].color)
                                .frame(width: 8, height: 8)
                            Text(graph.nodes[j].title)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if let sub = graph.nodes[j].subtitle {
                                Text(sub)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Camera

/// Mutable camera state advanced once per frame from the Canvas closure.
/// A plain reference type on purpose: per-frame mutation must not trigger
/// SwiftUI invalidation (TimelineView already redraws every frame).
private final class SWNetworkGraphCamera {
    var rotY = 0.6
    var tilt = -0.32
    var zoom = 1.0
    var grow = 0.0
    var viewSize = CGSize.zero

    var dragging = false
    var dragMoved = false
    var lastDragLocation: CGPoint? = nil

    private var start: Date? = nil
    private var lastTick: Date? = nil
    private var rotYTarget: Double? = nil
    private var tiltTarget: Double? = nil
    private var zoomTarget: Double? = nil

    private let fov = 1400.0

    func step(now: Date, spinSpeed: Double, growDuration: Double, idle: Bool, reduceMotion: Bool) {
        let started = start ?? now
        start = started
        let dt = min(0.064, now.timeIntervalSince(lastTick ?? now))
        lastTick = now

        grow = reduceMotion
            ? 1.02
            : min(1.02, now.timeIntervalSince(started) / max(0.1, growDuration) * 1.02)

        if idle, !dragging, !reduceMotion {
            rotY += spinSpeed * dt
        }

        // Exponential approach toward the focus target, frame-rate independent.
        if let target = rotYTarget {
            let k = 1 - exp(-7 * dt)
            var delta = (target - rotY).truncatingRemainder(dividingBy: 2 * .pi)
            if delta > .pi { delta -= 2 * .pi }
            if delta < -.pi { delta += 2 * .pi }
            rotY += delta * k
            if let t = tiltTarget { tilt += (t - tilt) * k }
            if let z = zoomTarget { zoom += (z - zoom) * k }
            if abs(delta) < 0.008 {
                rotYTarget = nil
                tiltTarget = nil
                zoomTarget = nil
            }
        }
    }

    /// Rotate so the node faces front-center; the nearer of the two
    /// facing angles wins, then settle the tilt and nudge the zoom in.
    func focus(on p: SIMD3<Double>) {
        var best = 0.0
        var bestZ = Double.infinity
        for candidate in [atan2(-p.x, p.z), atan2(-p.x, p.z) + .pi] {
            let z2 = -p.x * sin(candidate) + p.z * cos(candidate)
            if z2 < bestZ {
                bestZ = z2
                best = candidate
            }
        }
        rotYTarget = best
        tiltTarget = -0.18
        zoomTarget = max(zoom, 1.15)
    }

    func clearFocus() {
        rotYTarget = nil
        tiltTarget = nil
        zoomTarget = nil
    }

    func project(positions: [SIMD3<Double>], in size: CGSize) -> [(x: Double, y: Double, scale: Double)] {
        let cy = cos(rotY), sy = sin(rotY)
        let ct = cos(tilt), st = sin(tilt)
        let centerX = size.width * 0.5
        let centerY = size.height * 0.52
        let scale = min(size.width / 1500, size.height / 1780) * zoom
        return positions.map { p in
            let x = p.x * cy + p.z * sy
            let z = -p.x * sy + p.z * cy
            let y2 = p.y * ct - z * st
            let z2 = p.y * st + z * ct
            // Clamp the perspective divisor: at max zoom + deep tilt the
            // denominator can go negative and flip points across the screen.
            let pf = fov / max(fov * 0.08, fov + z2 * scale * 1.6)
            return (centerX + x * scale * pf, centerY - y2 * scale * pf, pf)
        }
    }

    func dotRadius(weight: Double, depthScale: Double) -> Double {
        (2.3 + sqrt(max(0, weight)) * 7.5) * depthScale * min(1.6, max(0.9, zoom))
    }
}

// MARK: - Resolved Graph

/// Index-based view of the graph: funnel positions, adjacency lists, and
/// per-group counts, all derived once per `nodes`/`edges` change.
private struct SWNetworkGraphResolved {
    let nodes: [SWNetworkGraphNode]
    let positions: [SIMD3<Double>]
    let edgeIndices: [(Int, Int)]          // (dependent, prerequisite)
    let directPrerequisites: [[Int]]
    let directUnlocks: [[Int]]
    let groups: [(name: String, color: Color, count: Int)]

    init(nodes: [SWNetworkGraphNode], edges: [SWNetworkGraphEdge]) {
        self.nodes = nodes

        // Funnel layout: golden-angle spiral, radius opening with level,
        // deterministic per-id jitter so layouts are stable across runs.
        let goldenAngle = Double.pi * (3 - sqrt(5.0))
        let worldHeight = 1600.0
        let maxRadius = 620.0
        var positions: [SIMD3<Double>] = []
        positions.reserveCapacity(nodes.count)
        let placementOrder = nodes.indices.sorted { nodes[$0].level < nodes[$1].level }
        var rank = Array(repeating: 0, count: nodes.count)
        for (r, i) in placementOrder.enumerated() { rank[i] = r }
        for i in nodes.indices {
            let node = nodes[i]
            let hash = Self.stableHash(node.id)
            let jitterA = Double(hash & 0xFFFF) / 65535.0          // 0...1
            let jitterB = Double((hash >> 16) & 0xFFFF) / 65535.0  // 0...1
            let angle = goldenAngle * Double(rank[i]) + jitterA * 0.9
            let radius = maxRadius * (0.30 + 0.70 * node.level) * (0.75 + 0.45 * jitterB)
            let y = (node.level - 0.5) * worldHeight + (jitterA - 0.5) * 70
            positions.append(SIMD3(radius * cos(angle), y, radius * sin(angle)))
        }
        self.positions = positions

        var indexOf: [String: Int] = [:]
        for (i, node) in nodes.enumerated() { indexOf[node.id] = i }
        var edgeIndices: [(Int, Int)] = []
        var pre = Array(repeating: [Int](), count: nodes.count)
        var next = Array(repeating: [Int](), count: nodes.count)
        for edge in edges {
            guard let a = indexOf[edge.from], let b = indexOf[edge.to] else { continue }
            edgeIndices.append((a, b))
            pre[a].append(b)
            next[b].append(a)
        }
        self.edgeIndices = edgeIndices
        self.directPrerequisites = pre.map { list in list.sorted { nodes[$0].level < nodes[$1].level } }
        self.directUnlocks = next.map { list in list.sorted { nodes[$0].level < nodes[$1].level } }

        var seen: [String: Int] = [:]
        var groups: [(name: String, color: Color, count: Int)] = []
        for node in nodes where !node.group.isEmpty {
            if let idx = seen[node.group] {
                groups[idx].count += 1
            } else {
                seen[node.group] = groups.count
                groups.append((node.group, node.color, 1))
            }
        }
        self.groups = groups
    }

    /// Full prerequisite lineage of node `i` (BFS over incoming deps).
    func lineage(of i: Int) -> (nodes: Set<Int>, edges: Set<Int>) {
        var nodeSet: Set<Int> = [i]
        var edgeSet: Set<Int> = []
        var queue = [i]
        while let u = queue.popLast() {
            for (k, edge) in edgeIndices.enumerated() where edge.0 == u {
                edgeSet.insert(k)
                if nodeSet.insert(edge.1).inserted {
                    queue.append(edge.1)
                }
            }
        }
        return (nodeSet, edgeSet)
    }

    /// FNV-1a: stable across runs, unlike `String.hashValue`.
    private static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}

// MARK: - Sample Data

extension SWNetworkGraph {
    /// Mini skill-tree used by previews and the showcase app.
    static let sampleNodes: [SWNetworkGraphNode] = {
        let math = Color(red: 0.35, green: 0.62, blue: 1.0)
        let geometry = Color(red: 0.72, green: 0.52, blue: 1.0)
        let reading = Color(red: 1.0, green: 0.62, blue: 0.30)
        let science = Color(red: 0.30, green: 0.82, blue: 0.56)
        return [
            .init(id: "counting", title: "Counting", subtitle: "age 4", group: "Math", color: math, level: 0.02, weight: 0.9),
            .init(id: "number-sense", title: "Number Sense", subtitle: "age 5", group: "Math", color: math, level: 0.10, weight: 0.7),
            .init(id: "addition", title: "Addition", subtitle: "age 5", group: "Math", color: math, level: 0.18, weight: 0.6),
            .init(id: "subtraction", title: "Subtraction", subtitle: "age 6", group: "Math", color: math, level: 0.24, weight: 0.5),
            .init(id: "multiplication", title: "Multiplication", subtitle: "age 7", group: "Math", color: math, level: 0.38, weight: 0.6),
            .init(id: "division", title: "Division", subtitle: "age 8", group: "Math", color: math, level: 0.46, weight: 0.5),
            .init(id: "fractions", title: "Fractions", subtitle: "age 8", group: "Math", color: math, level: 0.55, weight: 0.7),
            .init(id: "decimals", title: "Decimals", subtitle: "age 9", group: "Math", color: math, level: 0.64, weight: 0.4),
            .init(id: "ratios", title: "Ratios", subtitle: "age 10", group: "Math", color: math, level: 0.74, weight: 0.4),
            .init(id: "equations", title: "Simple Equations", subtitle: "age 11", group: "Math", color: math, level: 0.86, weight: 0.6),
            .init(id: "algebra", title: "Algebra", subtitle: "age 12", group: "Math", color: math, level: 0.96, weight: 0.9),

            .init(id: "shapes", title: "Basic Shapes", subtitle: "age 4", group: "Geometry", color: geometry, level: 0.05, weight: 0.6),
            .init(id: "symmetry", title: "Symmetry", subtitle: "age 6", group: "Geometry", color: geometry, level: 0.28, weight: 0.4),
            .init(id: "angles", title: "Angles", subtitle: "age 8", group: "Geometry", color: geometry, level: 0.50, weight: 0.5),
            .init(id: "perimeter", title: "Perimeter & Area", subtitle: "age 9", group: "Geometry", color: geometry, level: 0.62, weight: 0.5),
            .init(id: "volume", title: "Volume", subtitle: "age 10", group: "Geometry", color: geometry, level: 0.76, weight: 0.4),
            .init(id: "coordinates", title: "Coordinates", subtitle: "age 11", group: "Geometry", color: geometry, level: 0.88, weight: 0.5),

            .init(id: "phonics", title: "Phonics", subtitle: "age 4", group: "Reading", color: reading, level: 0.03, weight: 0.9),
            .init(id: "sight-words", title: "Sight Words", subtitle: "age 5", group: "Reading", color: reading, level: 0.12, weight: 0.5),
            .init(id: "fluency", title: "Reading Fluency", subtitle: "age 6", group: "Reading", color: reading, level: 0.30, weight: 0.6),
            .init(id: "comprehension", title: "Comprehension", subtitle: "age 7", group: "Reading", color: reading, level: 0.44, weight: 0.7),
            .init(id: "summarizing", title: "Summarizing", subtitle: "age 9", group: "Reading", color: reading, level: 0.60, weight: 0.4),
            .init(id: "essays", title: "Essay Writing", subtitle: "age 11", group: "Reading", color: reading, level: 0.84, weight: 0.6),

            .init(id: "observation", title: "Observation", subtitle: "age 4", group: "Science", color: science, level: 0.06, weight: 0.5),
            .init(id: "measurement", title: "Measurement", subtitle: "age 6", group: "Science", color: science, level: 0.26, weight: 0.5),
            .init(id: "states-matter", title: "States of Matter", subtitle: "age 8", group: "Science", color: science, level: 0.48, weight: 0.4),
            .init(id: "food-chains", title: "Food Chains", subtitle: "age 9", group: "Science", color: science, level: 0.58, weight: 0.4),
            .init(id: "experiments", title: "Fair Experiments", subtitle: "age 10", group: "Science", color: science, level: 0.72, weight: 0.6),
            .init(id: "forces", title: "Forces & Motion", subtitle: "age 11", group: "Science", color: science, level: 0.90, weight: 0.5),
        ]
    }()

    static let sampleEdges: [SWNetworkGraphEdge] = [
        .init(from: "number-sense", to: "counting"),
        .init(from: "addition", to: "number-sense"),
        .init(from: "subtraction", to: "addition"),
        .init(from: "multiplication", to: "addition"),
        .init(from: "division", to: "multiplication"),
        .init(from: "division", to: "subtraction"),
        .init(from: "fractions", to: "division"),
        .init(from: "decimals", to: "fractions"),
        .init(from: "ratios", to: "fractions"),
        .init(from: "ratios", to: "decimals"),
        .init(from: "equations", to: "ratios"),
        .init(from: "equations", to: "multiplication"),
        .init(from: "algebra", to: "equations"),
        .init(from: "algebra", to: "coordinates"),

        .init(from: "symmetry", to: "shapes"),
        .init(from: "angles", to: "symmetry"),
        .init(from: "perimeter", to: "angles"),
        .init(from: "perimeter", to: "multiplication"),
        .init(from: "volume", to: "perimeter"),
        .init(from: "coordinates", to: "angles"),
        .init(from: "coordinates", to: "number-sense"),

        .init(from: "sight-words", to: "phonics"),
        .init(from: "fluency", to: "sight-words"),
        .init(from: "comprehension", to: "fluency"),
        .init(from: "summarizing", to: "comprehension"),
        .init(from: "essays", to: "summarizing"),

        .init(from: "measurement", to: "observation"),
        .init(from: "measurement", to: "number-sense"),
        .init(from: "states-matter", to: "measurement"),
        .init(from: "food-chains", to: "observation"),
        .init(from: "experiments", to: "measurement"),
        .init(from: "experiments", to: "states-matter"),
        .init(from: "forces", to: "experiments"),
        .init(from: "forces", to: "angles"),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWNetworkGraph(
            nodes: SWNetworkGraph.sampleNodes,
            edges: SWNetworkGraph.sampleEdges
        )
    }
}
