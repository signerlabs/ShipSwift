//
//  slUserManager.swift
//  ShipSwift
//
//  用户管理器 - 包含认证和应用评分功能
//  参考 brushmo 项目的 UserManager 实现
//

import Foundation
import SwiftUI
import StoreKit
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

// MARK: - Session State

/// 用户会话状态
enum slSessionState: Equatable {
    case loading
    case signedOut(errorMessage: String? = nil)
    case guest                              // 游客模式，跳过登录
    case onboarding(tokens: slAuthTokens)   // 已登录，未完成问卷
    case ready(tokens: slAuthTokens)        // 已登录，已完成问卷

    var isSignedIn: Bool {
        switch self {
        case .onboarding, .ready: return true
        case .signedOut, .loading, .guest: return false
        }
    }

    var isGuest: Bool {
        if case .guest = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var tokens: slAuthTokens? {
        switch self {
        case .onboarding(let tokens), .ready(let tokens): return tokens
        case .signedOut, .loading, .guest: return nil
        }
    }

    var errorMessage: String? {
        if case .signedOut(let message) = self { return message }
        return nil
    }
}

// MARK: - Auth Tokens

/// 认证 Token
struct slAuthTokens: Equatable {
    let idToken: String
    let accessToken: String
    let refreshToken: String
}

// MARK: - Service Error

/// 服务错误类型
enum slServiceError: LocalizedError {
    case notSignedIn
    case tokenMissing
    case invalidURL
    case networkError
    case unauthorized
    case serverError(Int)
    case timeout
    case userProfileNotFound
    case userAlreadyExists
    case validationError(String)
    case decodingError
    case encodingError
    case invalidResponse
    case invalidState
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in"
        case .tokenMissing: return "Session expired, please sign in again"
        case .invalidURL: return "Invalid URL"
        case .networkError: return "Network connection failed"
        case .unauthorized: return "Session expired, please sign in again"
        case .serverError(let code): return "Server error (\(code))"
        case .timeout: return "Request timeout, please retry"
        case .userProfileNotFound: return "User profile not found"
        case .userAlreadyExists: return "User profile already exists"
        case .validationError(let message): return "Validation failed: \(message)"
        case .decodingError: return "Data parsing error"
        case .encodingError: return "Data encoding error"
        case .invalidResponse: return "Invalid response"
        case .invalidState: return "Invalid state"
        case .unknown(let message): return message
        }
    }
}

// MARK: - User Manager

@MainActor
@Observable
final class slUserManager {

    // MARK: - 存储键

    private enum StorageKey: String {
        case isFirstLaunch
        case appLaunchCount
        case actionCompletedCount
        case lastReviewRequestDate
        case hasRequestedReview
    }

    // MARK: - 评分请求配置

    private enum ReviewConfig {
        static let minActions = 2             // 至少完成 2 次操作
        static let minLaunches = 3            // 至少启动 3 次应用
        static let daysBetweenRequests = 30   // 两次评分请求间隔天数
        static let delayBeforeRequest: Duration = .seconds(1)  // 请求前延迟
    }

    // MARK: - 属性

    /// 用户会话状态
    var sessionState: slSessionState = .loading

    /// 是否正在进行认证操作
    var isAuthenticating = false

    /// 是否为首次启动（存储属性，@Observable 可追踪）
    var isFirstLaunch: Bool = false {
        didSet {
            // 注意：存储的是"是否已完成首次启动"，所以取反
            UserDefaults.standard.set(!isFirstLaunch, forKey: StorageKey.isFirstLaunch.rawValue)
        }
    }

    private let authService = slAuthService.shared

    // 评分请求相关属性
    private var actionCompletedCount: Int {
        get { UserDefaults.standard.integer(forKey: StorageKey.actionCompletedCount.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.actionCompletedCount.rawValue) }
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

        // 检查登录状态
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - 公开方法

    func completeFirstLaunch() {
        isFirstLaunch = false  // didSet 自动同步到 UserDefaults
    }

    // MARK: - 认证状态检查

    /// 检查认证状态并更新会话状态
    func checkAuthStatus() async {
        sessionState = .loading

        let isSignedIn = await authService.isSignedIn()

        if isSignedIn {
            do {
                let tokens = try await authService.fetchTokens()
                // 默认直接进入 ready 状态
                // 如果有 onboarding 流程，可以在这里查询后端状态
                sessionState = .ready(tokens: tokens)
            } catch {
                debugLog("❌ [slUserManager] Failed to check auth status:", error)
                sessionState = .signedOut(errorMessage: "Failed to fetch auth info")
            }
        } else {
            sessionState = .signedOut()
        }
    }

    // MARK: - 邮箱密码认证

    /// 注册
    func signUp(email: String, password: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }
        try await authService.signUp(email: email, password: password)
    }

    /// 确认邮箱验证码
    func confirmSignUp(email: String, code: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }
        try await authService.confirmSignUp(email: email, code: code)
    }

    /// 重新发送验证码
    func resendSignUpCode(email: String) async throws {
        try await authService.resendSignUpCode(email: email)
    }

    /// 邮箱密码登录
    func signIn(email: String, password: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }

        let tokens = try await authService.signIn(email: email, password: password)
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - 社交登录

    /// Apple 登录
    func signInWithApple() async throws {
        debugLog("🍎 [Auth] Starting Apple Sign In...")

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            debugLog("🍎 [Auth] ❌ Cannot get window")
            throw slServiceError.unknown("Cannot get window")
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            debugLog("🍎 [Auth] Calling authService.signInWithApple...")
            let tokens = try await authService.signInWithApple(presentationAnchor: window)
            debugLog("🍎 [Auth] ✅ Apple Sign In successful, got tokens")
            sessionState = .ready(tokens: tokens)
        } catch {
            debugLog("🍎 [Auth] ❌ Apple Sign In failed:", error)
            throw error
        }
    }

    /// Google 登录
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            throw slServiceError.unknown("Cannot get window")
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let tokens = try await authService.signInWithGoogle(presentationAnchor: window)
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - 游客模式

    /// 跳过登录，进入游客模式
    func skipSignIn() {
        sessionState = .guest
    }

    /// 要求登录（从游客模式切换到登录页面）
    func requireSignIn() {
        sessionState = .signedOut()
    }

    // MARK: - 登出/注销

    /// 登出
    func signOut() async {
        await authService.signOut()
        sessionState = .signedOut()
    }

    /// 注销账户
    func deleteAccount() async throws {
        try await authService.deleteUser()
        sessionState = .signedOut()
    }

    // MARK: - 密码重置

    /// 忘记密码
    func forgotPassword(email: String) async throws {
        try await authService.forgotPassword(email: email)
    }

    /// 重置密码
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
        try await authService.confirmResetPassword(email: email, newPassword: newPassword, code: code)
    }

    // MARK: - Onboarding

    /// 完成 Onboarding 问卷，切换到 ready 状态
    func completeOnboarding() {
        guard let tokens = sessionState.tokens else { return }
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - Token 管理

    /// 获取最新的 ID Token（自动刷新过期的 Token）
    func getFreshIdToken() async -> String? {
        guard sessionState.isSignedIn else {
            return nil
        }

        do {
            let tokens = try await authService.fetchTokens()

            // 同时更新缓存的 tokens
            switch sessionState {
            case .onboarding:
                sessionState = .onboarding(tokens: tokens)
            case .ready:
                sessionState = .ready(tokens: tokens)
            default:
                break
            }

            return tokens.idToken
        } catch {
            debugLog("❌ [slUserManager] Failed to get fresh token:", error)
            return nil
        }
    }

    /// 刷新 Session
    func refreshSession() async throws {
        guard sessionState.tokens != nil else {
            throw slServiceError.tokenMissing
        }

        let newTokens = try await authService.refreshSession()

        switch sessionState {
        case .onboarding:
            sessionState = .onboarding(tokens: newTokens)
        case .ready:
            sessionState = .ready(tokens: newTokens)
        default:
            break
        }
    }

    // MARK: - 评分请求

    /// 记录完成的操作次数
    func incrementActionCompletedCount() {
        actionCompletedCount += 1
        requestReviewIfAppropriate()
    }

    /// 在用户完成积极操作后调用
    func recordPositiveUserAction() {
        requestReviewIfAppropriate()
    }

    private func requestReviewIfAppropriate() {
        guard shouldRequestReview() else { return }

        Task {
            try? await Task.sleep(for: ReviewConfig.delayBeforeRequest)
            await requestReview()
        }
    }

    private func shouldRequestReview() -> Bool {
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

        return actionCompletedCount >= ReviewConfig.minActions
            && appLaunchCount >= ReviewConfig.minLaunches
    }

    private func requestReview() async {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        AppStore.requestReview(in: scene)

        hasRequestedReview = true
        lastReviewRequestDate = .now
    }
}

// MARK: - Auth Service

/// 认证服务 - 直接使用 Amplify SDK
actor slAuthService {
    static let shared = slAuthService()

    private init() {}

    // MARK: - 邮箱密码认证

    /// 注册新用户
    func signUp(email: String, password: String) async throws {
        _ = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: AuthSignUpRequest.Options(
                userAttributes: [AuthUserAttribute(.email, value: email)]
            )
        )
    }

    /// 确认邮箱验证码
    func confirmSignUp(email: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(
            for: email,
            confirmationCode: code
        )

        guard result.isSignUpComplete else {
            throw slServiceError.invalidState
        }
    }

    /// 重新发送验证码
    func resendSignUpCode(email: String) async throws {
        _ = try await Amplify.Auth.resendSignUpCode(for: email)
    }

    /// 邮箱密码登录
    func signIn(email: String, password: String) async throws -> slAuthTokens {
        let result = try await Amplify.Auth.signIn(
            username: email,
            password: password
        )

        guard result.isSignedIn else {
            throw slServiceError.notSignedIn
        }

        return try await fetchTokens()
    }

    // MARK: - 社交登录

    /// Apple 登录
    func signInWithApple(presentationAnchor: AuthUIPresentationAnchor) async throws -> slAuthTokens {
        #if DEBUG
        print("🍎 [slAuthService] signInWithApple started")
        #endif

        // 如果已有登录状态，先登出
        if await isSignedIn() {
            #if DEBUG
            print("🍎 [slAuthService] Already signed in, signing out first...")
            #endif
            await signOut()
        }

        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)

        do {
            let result = try await Amplify.Auth.signInWithWebUI(
                for: .apple,
                presentationAnchor: presentationAnchor,
                options: options
            )

            guard result.isSignedIn else {
                throw slServiceError.notSignedIn
            }

            return try await fetchTokens()
        } catch let error as AuthError {
            #if DEBUG
            print("🍎 [slAuthService] ❌ AuthError:", error.errorDescription)
            #endif
            throw error
        } catch {
            #if DEBUG
            print("🍎 [slAuthService] ❌ Unknown Error:", String(describing: error))
            #endif
            throw error
        }
    }

    /// Google 登录
    func signInWithGoogle(presentationAnchor: AuthUIPresentationAnchor) async throws -> slAuthTokens {
        // 如果已有登录状态，先登出
        if await isSignedIn() {
            await signOut()
        }

        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)

        let result = try await Amplify.Auth.signInWithWebUI(
            for: .google,
            presentationAnchor: presentationAnchor,
            options: options
        )

        guard result.isSignedIn else {
            throw slServiceError.notSignedIn
        }

        return try await fetchTokens()
    }

    // MARK: - Token 管理

    /// 获取当前 Token
    func fetchTokens() async throws -> slAuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession()

        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw slServiceError.tokenMissing
        }

        let tokensResult = cognitoSession.getCognitoTokens()

        switch tokensResult {
        case .success(let tokens):
            return slAuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw slServiceError.tokenMissing
        }
    }

    /// 刷新 Token
    func refreshSession() async throws -> slAuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession(options: .forceRefresh())

        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw slServiceError.tokenMissing
        }

        let tokensResult = cognitoSession.getCognitoTokens()

        switch tokensResult {
        case .success(let tokens):
            return slAuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw slServiceError.tokenMissing
        }
    }

    // MARK: - 登出/注销

    /// 登出
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    /// 删除用户账户
    func deleteUser() async throws {
        try await Amplify.Auth.deleteUser()
    }

    /// 检查登录状态
    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return session.isSignedIn
        } catch {
            return false
        }
    }

    // MARK: - 密码重置

    /// 忘记密码 - 发送验证码
    func forgotPassword(email: String) async throws {
        _ = try await Amplify.Auth.resetPassword(for: email)
    }

    /// 重置密码 - 使用验证码设置新密码
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
        try await Amplify.Auth.confirmResetPassword(
            for: email,
            with: newPassword,
            confirmationCode: code
        )
    }
}
