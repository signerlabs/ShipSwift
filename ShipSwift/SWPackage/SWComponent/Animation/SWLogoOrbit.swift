//
//  SWLogoOrbit.swift
//  ShipSwift
//
//  SpriteKit-powered animated orbit component. Displays multiple concentric rings
//  of colored dots that rotate continuously. Icons from the images array are placed
//  on the outermost ring and periodically pop out with a scale animation. A custom
//  center view is rendered on top using SwiftUI.
//
//  Usage:
//    // Basic usage — array of image names + center view
//    SWLogoOrbit(
//        images: ["icon1", "icon2", "icon3", "icon4",
//                 "icon5", "icon6", "icon7", "icon8"]
//    ) {
//        Image("AppLogo")
//            .resizable()
//            .aspectRatio(contentMode: .fill)
//            .frame(width: 60, height: 60)
//    }
//
//    // Control size (via frame constraint, component auto-scales)
//    SWLogoOrbit(images: imageArray) {
//        Circle()
//            .fill(.blue)
//            .frame(width: 50, height: 50)
//    }
//    .frame(width: 150)
//
//  Parameters:
//    - images: [String]          — Array of asset image names (up to 8, evenly distributed on outer ring)
//    - center: @ViewBuilder      — SwiftUI view displayed at the center
//
//  Notes:
//    - Component maintains 1:1 aspect ratio, auto-scales via GeometryReader
//    - Base design size is 300pt, can be scaled down or up via frame
//    - 4 concentric dot rings, outer ring largest, inner ring smallest
//    - Icons take turns showing a pop-out animation then shrink back
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import SpriteKit

/// Logo display component with orbit animation
/// - Parameters:
///   - images: Array of images on the orbit (up to 8)
///   - center: Custom view displayed at the center
struct SWLogoOrbit<Center: View>: View {
    let images: [String]
    let center: Center

    private let baseSize: CGFloat = 300  // Base design size

    init(images: [String], @ViewBuilder center: () -> Center) {
        self.images = images
        self.center = center()
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let scale = size / baseSize

            ZStack {
                AnimatedLogoOrbit(images: images, scale: scale)

                center
                    .scaleEffect(scale)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct AnimatedLogoOrbit: View {
    let images: [String]
    let scale: CGFloat

    @State private var scene: AnimatedLogoOrbitScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
            }
        }
        .onAppear {
            let newScene = AnimatedLogoOrbitScene()
            newScene.images = images
            newScene.scaleFactor = scale
            newScene.scaleMode = .resizeFill
            scene = newScene
        }
        .onChange(of: scale) { _, newScale in
            scene?.updateScale(newScale)
        }
    }
}

class AnimatedLogoOrbitScene: SKScene {
    var images: [String] = []
    var scaleFactor: CGFloat = 1.0

    private let dotsPerCircle = 23
    private let numCircles = 4

    private var outerCircleDots: [SKShapeNode] = []
    private var nextIconIndex = 0
    private var originalPositions: [CGPoint] = []
    private var showingImageDot: SKShapeNode?

    private let container = SKNode()

    private let gradient: [(angle: CGFloat, color: SKColor)] = [
        (0, SKColor(red: 26/255, green: 127/255, blue: 93/255, alpha: 1)),
        (.pi / 2, SKColor(red: 52/255, green: 180/255, blue: 140/255, alpha: 1)),
        (.pi, SKColor(red: 80/255, green: 200/255, blue: 160/255, alpha: 1)),
        (3 * .pi / 2, SKColor(red: 40/255, green: 150/255, blue: 115/255, alpha: 1)),
        (2 * .pi, SKColor(red: 26/255, green: 127/255, blue: 93/255, alpha: 1))
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = .zero
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        addChild(container)
        container.setScale(scaleFactor)
        buildCircles()
        startRotation()
        animateNextIcon()
    }

    func updateScale(_ newScale: CGFloat) {
        scaleFactor = newScale
        container.setScale(newScale)
    }

    private func buildCircles() {
        let circles = generateCircles()
        var angleOffset: CGFloat = 0
        let step = Int(round(Double(dotsPerCircle) / Double(images.count)))

        for (circleIndex, circle) in circles.enumerated() {
            for dotIndex in 0..<dotsPerCircle {
                var angle = (2 * .pi / CGFloat(dotsPerCircle) * CGFloat(dotIndex)) + angleOffset
                if angle > 2 * .pi { angle -= 2 * .pi }

                let position = CGPoint(x: circle.radius * cos(angle), y: circle.radius * sin(angle))

                let dot = SKShapeNode(circleOfRadius: circle.size)
                dot.position = position
                dot.fillColor = getColor(for: angle)
                dot.strokeColor = .clear
                dot.name = "dot-\(circleIndex)"
                dot.physicsBody = SKPhysicsBody(circleOfRadius: circle.size + 3)
                dot.physicsBody?.isDynamic = true
                dot.physicsBody?.affectedByGravity = false

                if circleIndex == 0, dotIndex % step == 0 {
                    placeIconOnOuterCircle(for: dot)
                    outerCircleDots.append(dot)
                }

                container.addChild(dot)
                originalPositions.append(position)
            }
            angleOffset += 0.4
        }

        outerCircleDots.reverse()
    }

    private func placeIconOnOuterCircle(for dot: SKShapeNode) {
        let maskRadius: CGFloat = 40
        let mask = SKShapeNode(circleOfRadius: maskRadius)
        mask.fillColor = .white
        mask.strokeColor = .clear

        let cropNode = SKCropNode()
        cropNode.maskNode = mask
        cropNode.alpha = 0
        cropNode.name = "sprite"
        cropNode.setScale(0.25)

        let sprite = SKSpriteNode(imageNamed: images[outerCircleDots.count])
        sprite.texture?.filteringMode = .linear

        let imageSize = sprite.size
        let scale = max((maskRadius * 2) / imageSize.width, (maskRadius * 2) / imageSize.height)
        sprite.size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        cropNode.addChild(sprite)
        dot.addChild(cropNode)
    }

    private func startRotation() {
        container.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 10)))
    }

    private func animateNextIcon() {
        let dot = outerCircleDots[nextIconIndex]

        dot.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        dot.physicsBody?.density = 110
        dot.physicsBody?.isDynamic = false

        let scaleIcon = SKAction.run { [weak self] in
            dot.run(.sequence([
                .scale(to: 4.0 * 1.1, duration: 0.1),
                .scale(to: 4.0, duration: 0.1)
            ]))

            self?.showingImageDot = dot
            dot.fillColor = dot.fillColor.withAlphaComponent(0)

            (dot.childNode(withName: "sprite") as? SKCropNode)?.alpha = 1
        }

        let wait = SKAction.wait(forDuration: 1)

        let shrinkIcon = SKAction.run { [weak self] in
            guard let self else { return }

            let scale = SKAction.scale(to: 1.0, duration: 0.6)
            scale.timingMode = .easeIn
            dot.run(scale)

            // Image fade out with delay
            if let cropNode = dot.childNode(withName: "sprite") as? SKCropNode {
                cropNode.run(.sequence([
                    .wait(forDuration: 0.35),
                    .fadeAlpha(to: 0, duration: 0.15)
                ]))
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))

                // Background fade in
                for i in 1...10 {
                    try? await Task.sleep(for: .milliseconds(25))
                    guard self.showingImageDot === dot else { return }

                    let worldPos = self.container.convert(dot.position, to: self)
                    var angle = atan2(worldPos.y, worldPos.x)
                    if angle < 0 { angle += 2 * .pi }
                    dot.fillColor = self.getColor(for: angle).withAlphaComponent(CGFloat(i) / 10)
                }

                self.showingImageDot = nil
            }
        }

        let moveDots = SKAction.run { [weak self] in
            guard let self else { return }

            for (i, surroundingDot) in container.children.enumerated()
            where !surroundingDot.position.isApproximatelyEqual(to: originalPositions[i]) {
                let moveAction = SKAction.move(to: originalPositions[i], duration: 0.6)
                moveAction.timingMode = .easeIn
                surroundingDot.run(moveAction)
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                self.nextIconIndex = (self.nextIconIndex + 1) % self.outerCircleDots.count
                self.animateNextIcon()
            }
        }

        dot.run(.sequence([scaleIcon, wait, moveDots, shrinkIcon])) {
            dot.physicsBody?.isDynamic = true
        }
    }

    private func generateCircles() -> [(radius: CGFloat, size: CGFloat)] {
        var circles: [(CGFloat, CGFloat)] = []
        var dotSize = 4

        for i in 0..<numCircles {
            circles.append((CGFloat(75 + i * 15), CGFloat(dotSize)))
            dotSize += i == 0 ? 2 : (i % 2 == 0 ? 3 : -1)
        }

        return circles.reversed()
    }

    override func update(_ currentTime: TimeInterval) {
        for case let dot as SKShapeNode in container.children where dot !== showingImageDot {
            let worldPos = container.convert(dot.position, to: self)
            var angle = atan2(worldPos.y, worldPos.x)
            if angle < 0 { angle += 2 * .pi }
            dot.fillColor = getColor(for: angle)
        }

        outerCircleDots[nextIconIndex].zRotation = -container.zRotation
    }

    private func getColor(for angle: CGFloat) -> SKColor {
        guard let startIndex = gradient.lastIndex(where: { $0.angle <= angle }) else { return .white }

        let start = gradient[startIndex]
        let end = gradient[startIndex + 1]
        let percent = (angle - start.angle) / (end.angle - start.angle)

        let r = start.color.rgba.red + (end.color.rgba.red - start.color.rgba.red) * percent
        let g = start.color.rgba.green + (end.color.rgba.green - start.color.rgba.green) * percent
        let b = start.color.rgba.blue + (end.color.rgba.blue - start.color.rgba.blue) * percent

        return SKColor(red: r, green: g, blue: b, alpha: 1)
    }
}

private extension CGPoint {
    func isApproximatelyEqual(to other: CGPoint, tolerance: CGFloat = 0.01) -> Bool {
        abs(x - other.x) < tolerance && abs(y - other.y) < tolerance
    }
}

private extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

#Preview {
    VStack {
        SWLogoOrbit(
            images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
        ) {
            Image("Fullpack Transparent")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .offset(y: -5)
        }

        SWLogoOrbit(
            images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
        ) {
            Circle()
                .fill(.blue)
                .frame(width: 50, height: 50)
        }
        .frame(width: 150)
    }
}
