//
//  slUserManager.swift
//  full-pack
//
//  Created by Wei on 2025/5/17.
//

import Foundation
import SwiftUI
import StoreKit

@MainActor
@Observable
final class slUserManager {

    // MARK: - 存储键

    private enum StorageKey: String {
        case isFirstLaunch
        case tripCompletedCount
        case appLaunchCount
        case lastReviewRequestDate
        case hasRequestedReview
    }

    // MARK: - 评分请求配置

    private enum ReviewConfig {
        static let minTrips = 1           // 至少完成 1 次旅行
        static let minLaunches = 2        // 至少启动 2 次应用
        static let daysBetweenRequests = 30  // 两次评分请求间隔天数
        static let delayBeforeRequest: Duration = .seconds(1)  // 请求前延迟
    }

    // MARK: - 属性

    var isFirstLaunch: Bool = false

    // 使用计算属性封装 UserDefaults 访问
    private var tripCompletedCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.tripCompletedCount.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.tripCompletedCount.rawValue) }
    }

    private var appLaunchCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.appLaunchCount.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.appLaunchCount.rawValue) }
    }

    private var hasRequestedReview: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.hasRequestedReview.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.hasRequestedReview.rawValue) }
    }

    private var lastReviewRequestDate: Date? {
        get { UserDefaults.standard.object(forKey: StorageKey.lastReviewRequestDate.rawValue) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.lastReviewRequestDate.rawValue) }
    }

    // MARK: - 初始化

    init() {
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: StorageKey.isFirstLaunch.rawValue)
        appLaunchCount += 1
    }

    // MARK: - 公开方法

    func completeFirstLaunch() {
        UserDefaults.standard.set(true, forKey: StorageKey.isFirstLaunch.rawValue)
        isFirstLaunch = false
    }

    /// 记录完成的旅行次数
    func incrementTripCompletedCount() {
        tripCompletedCount += 1
        requestReviewIfAppropriate()
    }

    /// 在用户完成积极操作后调用（比如成功打包所有物品）
    func recordPositiveUserAction() {
        requestReviewIfAppropriate()
    }

    // MARK: - 评分请求逻辑

    /// 检查是否应该请求评分
    private func requestReviewIfAppropriate() {
        guard shouldRequestReview() else { return }

        Task {
            try? await Task.sleep(for: ReviewConfig.delayBeforeRequest)
            await requestReview()
        }
    }

    /// 判断是否满足评分请求条件
    private func shouldRequestReview() -> Bool {
        // 检查间隔时间
        if hasRequestedReview, let lastDate = lastReviewRequestDate {
            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day],
                from: lastDate,
                to: .now
            ).day ?? 0

            guard daysSinceLastRequest >= ReviewConfig.daysBetweenRequests else {
                return false
            }
        }

        // 检查使用量条件
        return tripCompletedCount >= ReviewConfig.minTrips
            && appLaunchCount >= ReviewConfig.minLaunches
    }

    /// 请求用户评分
    private func requestReview() async {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        // iOS 18+ 直接使用 AppStore API
        AppStore.requestReview(in: scene)

        // 记录评分请求
        hasRequestedReview = true
        lastReviewRequestDate = .now
    }
}
