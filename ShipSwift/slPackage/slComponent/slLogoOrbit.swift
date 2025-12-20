//
//  slLogoOrbit.swift
//  Truvet
//
//  Created by 仲炜 on 2025/11/1.
//

import SwiftUI
import CoreGraphics
import SpriteKit

struct slLogoOrbit: View {
    let logo: String
    let images: [String]
    
    var body: some View {
        ZStack {
            AnimatedLogoOrbit(
                images: images
            )
            
            Image(logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .offset(x: 0, y: -5)
        }
        .ignoresSafeArea()
        .padding()
    }
}

struct AnimatedLogoOrbit: View {
    let images: [String]
    
    @State private var scene: AnimatedLogoOrbitScene?
    
    var body: some View {
        ZStack {
            if let scene {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        let newScene = AnimatedLogoOrbitScene()
        newScene.images = images
        newScene.scaleMode = .resizeFill
        scene = newScene
    }
}

class AnimatedLogoOrbitScene: SKScene {
    var images: [String] = []
    
    let dotsPerCircle = 23
    let numCircles = 4
    
    var outerCircleDots: [SKShapeNode] = []
    var nextIconIndex = 0
    var originalPositions: [CGPoint] = []
    var showingImageDot: SKShapeNode? = nil  // 正在显示图片的dot
    
    let container = SKNode()
    
    private let gradient: [(angle: CGFloat, color: SKColor)] = [
        (0, SKColor(red: 26/255, green: 127/255, blue: 93/255, alpha: 1)), // right = AccentColor (深绿)
        (.pi / 2, SKColor(red: 52/255, green: 180/255, blue: 140/255, alpha: 1)), // top = 亮绿色
        (.pi, SKColor(red: 80/255, green: 200/255, blue: 160/255, alpha: 1)), // left = 浅绿色
        (3 * .pi / 2, SKColor(red: 40/255, green: 150/255, blue: 115/255, alpha: 1)), // bottom = 中绿色
        (2 * .pi, SKColor(red: 26/255, green: 127/255, blue: 93/255, alpha: 1))  // right = AccentColor (深绿)
    ]
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        physicsWorld.gravity = .zero
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        addChild(container)
        buildCircles()
        startRotation()
        animateNextIcon()
    }
    
    private func buildCircles() {
        let circles = generateCircles()
        var angleOffset: CGFloat = 0
        
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
                
                if circleIndex == 0 {
                    let step = Int(round(Double(dotsPerCircle) / Double(images.count)))
                    
                    if dotIndex % step == 0 {
                        placeIconOnOuterCircle(for: dot)
                        outerCircleDots.append(dot)
                    }
                }
                
                container.addChild(dot)
                originalPositions.append(position)
            }
            
            angleOffset += 0.4
        }
        
        // icons should animate clockwise
        outerCircleDots.reverse()
    }
    
    private func placeIconOnOuterCircle(for dot: SKShapeNode) {
        // 创建圆形遮罩 - 使用更大的尺寸以适应放大动画
        let maskRadius: CGFloat = 40  // 增大到40，放大4倍后是160
        let mask = SKShapeNode(circleOfRadius: maskRadius)
        mask.fillColor = SKColor(white: 1, alpha: 1)  // 遮罩需要不透明颜色来定义形状，但不会显示
        mask.strokeColor = .clear
        
        // 创建裁剪节点
        let cropNode = SKCropNode()
        cropNode.maskNode = mask
        cropNode.alpha = 0
        cropNode.name = "sprite"
        cropNode.setScale(0.25)  // 初始缩小到1/4，保持视觉大小为10
        
        // 创建图片sprite
        let sprite = SKSpriteNode(imageNamed: images[outerCircleDots.count])
        
        // 设置texture过滤模式，避免模糊
        sprite.texture?.filteringMode = .linear
        
        // 计算图片尺寸，使用aspectFill效果
        let imageSize = sprite.size
        let scale = max((maskRadius * 2) / imageSize.width, (maskRadius * 2) / imageSize.height)
        sprite.size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        cropNode.addChild(sprite)
        dot.addChild(cropNode)
    }
    
    private func startRotation() {
        let rotate = SKAction.rotate(byAngle: .pi * -2, duration: 10)
        container.run(.repeatForever(rotate))
    }
    
    private func animateNextIcon() {
        let dot = outerCircleDots[nextIconIndex]
        
        dot.physicsBody? = SKPhysicsBody(circleOfRadius: 10)
        dot.physicsBody?.density = 110
        dot.physicsBody?.isDynamic = false
        
        let scaleIcon = SKAction.run {
            let a1 = SKAction.scale(to: 4.0 * 1.1, duration: 0.1)
            let a2 = SKAction.scale(to: 4.0, duration: 0.1)

            dot.run(.sequence([a1, a2]))

            // 标记正在显示图片的dot，并隐藏背景颜色（带淡出效果）
            self.showingImageDot = dot
            dot.fillColor = dot.fillColor.withAlphaComponent(0)

            if let cropNode = dot.childNode(withName: "sprite") as? SKCropNode {
                cropNode.alpha = 1
            }
        }
        
        let wait = SKAction.wait(forDuration: 1)
        
        let shrinkIcon = SKAction.run {
            let scale = SKAction.scale(to: 1.0, duration: 0.6)
            scale.timingFunction = SpriteKitTimingFunctions.easeInQuad
            dot.run(scale)

            let bgFadeDuration = 0.25
            let imageFadeDelay = 0.15  // 图片延迟淡出，让背景先淡入一部分

            // dot背景提前淡入
            let steps = 10
            let stepDuration = bgFadeDuration / Double(steps)
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + stepDuration * Double(i)) {
                    if self.showingImageDot === dot {
                        let worldPos = self.container.convert(dot.position, to: self)
                        var angle = atan2(worldPos.y, worldPos.x)
                        if angle < 0 { angle += 2 * .pi }
                        let targetColor = self.getColor(for: angle)
                        let alpha = CGFloat(i) / CGFloat(steps)
                        dot.fillColor = targetColor.withAlphaComponent(alpha)
                    }
                }
            }

            // 图片延迟淡出
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + imageFadeDelay) {
                if let cropNode = dot.childNode(withName: "sprite") as? SKCropNode {
                    let fade = SKAction.fadeAlpha(to: 0, duration: 0.15)
                    cropNode.run(fade)
                }
            }

            // 完成后清除标记
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + bgFadeDuration) {
                self.showingImageDot = nil
            }
        }
        
        // move dots back to their original position
        let moveDots = SKAction.run {
            for (i, surroundingDot) in self.container.children.enumerated()
            where !surroundingDot.position.isApproximatelyEqual(to: self.originalPositions[i])
            {
            let moveAction = SKAction.move(to: self.originalPositions[i], duration: 0.6)
            moveAction.timingFunction = SpriteKitTimingFunctions.easeInQuad
            surroundingDot.run(moveAction)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.nextIconIndex = (self.nextIconIndex + 1) % self.outerCircleDots.count
                self.animateNextIcon()
            }
        }
        
        dot.run(.sequence([scaleIcon, wait, moveDots, shrinkIcon])) {
            dot.physicsBody?.isDynamic = true
        }
    }
    
    private func generateCircles() -> [(radius: CGFloat, size: CGFloat)] {
        let radiusStep = 15
        let initialRadius = 75
        var dotSize = 4
        
        var circles: [(CGFloat, CGFloat)] = []
        
        for circleIndex in 0..<numCircles {
            let radius = CGFloat(initialRadius + (circleIndex * radiusStep))
            circles.append((CGFloat(radius), CGFloat(dotSize)))
            
            if circleIndex == 0 {
                dotSize += 2
            } else if circleIndex % 2 == 0 {
                dotSize += 3
            } else {
                dotSize -= 1
            }
        }
        
        return Array(circles.reversed())
    }
    
    override func update(_ currentTime: TimeInterval) {
        for case let dot as SKShapeNode in container.children {
            // 跳过正在显示图片的dot
            if dot === showingImageDot {
                continue
            }

            let worldPos = container.convert(dot.position, to: self)
            var angle = atan2(worldPos.y, worldPos.x)

            // normalise from -pi...pi to 0...2pi
            if angle < 0 {
                angle += 2 * .pi
            }

            dot.fillColor = getColor(for: angle)
        }

        let dot = outerCircleDots[nextIconIndex]
        dot.zRotation = -container.zRotation
    }
    
    private func getColor(for angle: CGFloat) -> SKColor {
        guard let startIndex = gradient.lastIndex(where: { $0.angle <= angle }) else {
            return .white
        }
        
        let endIndex = startIndex + 1
        
        let start = gradient[startIndex]
        let end = gradient[endIndex]
        
        let percent = (angle - start.angle) / (end.angle - start.angle)
        
        let r = start.color.rgba.red + (end.color.rgba.red - start.color.rgba.red) * percent
        let g = start.color.rgba.green + (end.color.rgba.green - start.color.rgba.green) * percent
        let b = start.color.rgba.blue + (end.color.rgba.blue - start.color.rgba.blue) * percent
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
}


extension CGPoint {
    func isApproximatelyEqual(to other: CGPoint, tolerance delta: CGFloat = 0.01) -> Bool {
        return abs(self.x - other.x) < delta &&
        abs(self.y - other.y) < delta
    }
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}

class SpriteKitTimingFunctions {
    
    // no easing, no acceleration
    static var easeLinear: SKActionTimingFunction = {
        var t: Float = $0
        return t
    }
    
    // accelerating from zero velocity
    static var easeInQuad: SKActionTimingFunction = {
        var t: Float = $0
        return t*t
    }
    
    // decelerating to zero velocity
    static var easeOutQuad: SKActionTimingFunction = {
        var t: Float = $0
        return t*(2-t)
    }
    
    // acceleration until halfway, then deceleration
    static var easeInOutQuad: SKActionTimingFunction = {
        var t: Float = $0
        return t<0.5 ? 2*t*t : -1+(4-2*t)*t
    }
    
    // accelerating from zero velocity
    static var easeInCubic: SKActionTimingFunction = {
        var t: Float = $0
        return t*t*t
    }
    
    // decelerating to zero velocity
    static var easeOutCubic: SKActionTimingFunction = {
        var t: Float = $0
        return (t - 1)*t*t+1
    }
    
    // acceleration until halfway, then deceleration
    static var easeInOutCubic: SKActionTimingFunction = {
        var t: Float = $0
        return t<0.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1
    }
    
    // accelerating from zero velocity
    static var easeInQuart: SKActionTimingFunction = {
        var t: Float = $0
        return t*t*t*t
    }
    
    // decelerating to zero velocity
    static var easeOutQuart: SKActionTimingFunction = {
        var t: Float = $0
        return 1-(t-1)*t*t*t
    }
    
    // acceleration until halfway, then deceleration
    static var easeInOutQuart: SKActionTimingFunction = {
        var t: Float = $0
        return t<0.5 ? 8*t*t*t*t : 1-8*(t-1)*t*t*t
    }
    
    // accelerating from zero velocity
    static var easeInQuint: SKActionTimingFunction = {
        var t: Float = $0
        return t*t*t*t*t
    }
    
    // decelerating to zero velocity
    static var easeOutQuint: SKActionTimingFunction = {
        var t: Float = $0
        return 1+(t-1)*t*t*t*t
    }
    
    // acceleration until halfway, then deceleration
    static var easeInOutQuint: SKActionTimingFunction = {
        var t: Float = $0
        return t<0.5 ? 16*t*t*t*t*t : 1+16*(t-1)*t*t*t*t
    }
    
    static var easeInSin: SKActionTimingFunction = {
        var t: Float = $0
        return 1 + sin(Float.pi / 2 * t - Float.pi / 2)
    }
    
    static var easeOutSin : SKActionTimingFunction = {
        var t: Float = $0
        return sin(Float.pi / 2 * t)
    }
    
    static var easeInOutSin: SKActionTimingFunction = {
        var t: Float = $0
        return (1 + sin(Float.pi * t - Float.pi / 2)) / 2
    }
    
    // elastic bounce effect at the beginning
    static var easeInElastic: SKActionTimingFunction = {
        var t: Float = $0
        return (0.04 - 0.04 / t) * sin(25 * t) + 1
    }
    
    // elastic bounce effect at the end
    static var easeOutElastic: SKActionTimingFunction = {
        var t: Float = $0
        return 0.04 * t / (t - 1) * sin(25 * t)
    }
    
    // elastic bounce effect at the beginning and end
    static var easeInOutElastic: SKActionTimingFunction = {
        var t: Float = $0
        return (t < 0.5) ? (0.01 + 0.01 / t) * sin(50 * t) : (0.02 - 0.01 / t) * sin(50 * t) + 1
    }
    
}



#Preview {
    slLogoOrbit(
        logo: "Fullpack Transparent",
        images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat"]
    )
}
