//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab placeholder — will be replaced with component showcase list
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ComponentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SWBeforeAfterSlider(
                            before: Image(.smileBefore),
                            after: Image(.smileAfter)
                        )
                        .padding()
                    } label: {
                        ListItem(
                            title: "Before / After Slider",
                            icon: "slider.horizontal.below.rectangle",
                            description: "Draggable image comparison slider with auto-oscillating animation. Supports custom labels, speed, and aspect ratio."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 26) {
                            SWTypewriterText(
                                texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                                animationStyle: .spring
                            )
                            .font(.title3.weight(.semibold))

                            SWTypewriterText(
                                texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                                animationStyle: .blur
                            )
                            .font(.title3.weight(.semibold))

                            SWTypewriterText(
                                texts: ["Hello World", "Welcome Back", "Let's Go"],
                                animationStyle: .spring,
                                gradient: LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                            .font(.title.weight(.bold))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } label: {
                        ListItem(
                            title: "Typewriter Text",
                            icon: "character.cursor.ibeam",
                            description: "Typing and deleting text animation that cycles through strings. Six animation styles: spring, blur, fade, scale, wave, none."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 40) {
                            SWShakingIcon(image: Image(systemName: "apple.logo"), height: 20)
                            SWShakingIcon(image: Image(.smileAfter), height: 100, cornerRadius: 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "Shaking Icon",
                            icon: "iphone.radiowaves.left.and.right",
                            description: "Periodically zooms in and shakes side-to-side, mimicking the iOS home-screen jiggle effect. Supports SF Symbols and asset images."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 30) {
                            SWShimmer {
                                Button {} label: {
                                    Text("Upgrade Now")
                                        .font(.largeTitle)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            SWShimmer {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.gray.opacity(0.3))
                                    .frame(width: 280, height: 120)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "Shimmer",
                            icon: "light.max",
                            description: "Translucent light band sweep across any view. Commonly used on buttons, skeleton loaders, or cards to draw attention."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 26) {
                            SWGlowSweep {
                                Text("Start Scan Today")
                                    .font(.largeTitle.bold())
                            }

                            SWGlowSweep(baseColor: .accentColor, glowColor: .white, duration: 1.5) {
                                Text("Analyzing...")
                                    .font(.title2.bold())
                            }

                            SWGlowSweep(baseColor: .green.opacity(0.7), glowColor: .black) {
                                Text("Processing")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "Glow Sweep",
                            icon: "wand.and.rays",
                            description: "Sweeps a glowing highlight band using the original content shape as mask. Ideal for text, icons, and SF Symbols."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 26) {
                            SWLightSweep {
                                Image(.smileAfter)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180)
                            }

                            SWLightSweep(lineWidth: 120, duration: 0.5, cornerRadius: 20) {
                                Image(.smileAfter)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "Light Sweep",
                            icon: "light.beacon.max",
                            description: "Gradient light band that sweeps across content in a rounded rectangle. Great for image cards and thumbnails."
                        )
                    }

                    NavigationLink {
                        VStack(spacing: 20) {
                            SWScanningOverlay {
                                Image(.facePicture)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            SWScanningOverlay(gridOpacity: 0.1, bandOpacity: 0.1, speed: 3.0) {
                                Image(.facePicture)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "Scanning Overlay",
                            icon: "barcode.viewfinder",
                            description: "Grid lines, sweeping scan band, and noise layer overlay. Conveys an analyzing / processing visual effect."
                        )
                    }

                    NavigationLink {
                        SWAnimatedMeshGradient()
                            .ignoresSafeArea()
                    } label: {
                        ListItem(
                            title: "Animated Mesh Gradient",
                            icon: "circle.hexagongrid.fill",
                            description: "3x3 mesh gradient background that transitions between two color palettes. Designed as a full-screen or section background."
                        )
                    }

                    NavigationLink {
                        VStack {
                            SWOrbitingLogos(
                                images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                            ) {
                                Image(.fullpackLogo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .offset(y: -5)
                            }

                            SWOrbitingLogos(
                                images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                            ) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 50, height: 50)
                            }
                            .frame(width: 150)
                        }
                    } label: {
                        ListItem(
                            title: "Orbiting Logos",
                            icon: "atom",
                            description: "SpriteKit-powered concentric rings of colored dots with icons on the outermost ring. Custom center view via SwiftUI."
                        )
                    }
                } header: {
                    Text("Animation (9)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentView()
}
