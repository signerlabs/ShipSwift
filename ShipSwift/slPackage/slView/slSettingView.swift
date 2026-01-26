//
//  slSettingView.swift
//  ShipSwift
//
//  通用设置页面模板，直接复制到项目中修改使用
//
//  Created by Claude on 2026/1/12.
//

import SwiftUI

struct slSettingView: View {

    // MARK: - 状态

    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isDeleting = false
    @State private var isSigningOut = false

    // MARK: - 配置（直接修改这些值）

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")!
    private let termsURL = URL(string: "https://example.com/terms")!
    private let privacyURL = URL(string: "https://example.com/privacy")!

    // App Store URLs（示例，请替换为实际 URL）
    private let appStoreFullpack = "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929"
    private let appStoreBrushmo = "https://apps.apple.com/us/app/brushmo/id6744569822"
    private let appStoreJourney = "https://apps.apple.com/us/app/journey-goal-tracker-diary/id6748666816"

    /// App 版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// App 构建号
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 通用设置
                Section {
                    // 语言切换
                    Picker("Language", selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }

                    // 分享 App
                    ShareLink(item: appStoreURL) {
                        HStack {
                            Text("Share App")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - 法律条款
                Section {
                    Link(destination: termsURL) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: privacyURL) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - 我的应用
                // 使用前需要：
                // 1. 将对应的 Logo 图片资源添加到项目的 Assets.xcassets 中
                // 2. 确保资源命名为 "Fullpack Logo", "Brushmo Logo", "Journey Logo"（会自动转换为 .fullpackLogo 等）
                // 3. 取消下面的注释
                // Section("My Apps") {
                //     Link(destination: URL(string: appStoreFullpack)!) {
                //         slLabelWithImage(image: .fullpackLogo, name: "Fullpack - Packing & Outfit")
                //     }
                //     Link(destination: URL(string: appStoreBrushmo)!) {
                //         slLabelWithImage(image: .brushmoLogo, name: "Brushmo - Oral Health Companion")
                //     }
                //     Link(destination: URL(string: appStoreJourney)!) {
                //         slLabelWithImage(image: .journeyLogo, name: "Journey - Goal Tracker & Diary")
                //     }
                // }

                // MARK: - 账户操作
                Section {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Text("Sign Out")
                            if isSigningOut {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeleting || isSigningOut)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Text("Delete Account")
                            if isDeleting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeleting || isSigningOut)
                }

                // MARK: - 版本信息
                Section {
                    LabeledContent("Version") {
                        Text("v\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }

    // MARK: - Actions（替换为实际逻辑）

    private func signOut() {
        isSigningOut = true
        Task {
            // TODO: 替换为实际的登出逻辑
            // await userManager.signOut()
            try? await Task.sleep(for: .seconds(1))
            isSigningOut = false
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            // TODO: 替换为实际的注销账户逻辑
            // try await userManager.deleteAccount()
            try? await Task.sleep(for: .seconds(1))
            isDeleting = false
        }
    }
}

#Preview {
    slSettingView()
}
