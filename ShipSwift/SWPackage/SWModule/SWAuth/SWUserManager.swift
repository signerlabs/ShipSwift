//
//  SWUserManager.swift
//  ShipSwift
//
//  User Manager - includes authentication and app review request functionality
//  Referenced from brushmo project's UserManager implementation
//

import Foundation
import SwiftUI
import StoreKit
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

// MARK: - Session State

/// User session state
enum SWSessionState: Equatable {
    case loading
    case signedOut(errorMessage: String? = nil)
    case guest                              // Guest mode, skip sign in
    case onboarding(tokens: SWAuthTokens)   // Signed in, onboarding not completed
    case ready(tokens: SWAuthTokens)        // Signed in, onboarding completed

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

    var tokens: SWAuthTokens? {
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

/// Authentication Tokens
struct SWAuthTokens: Equatable {
    let idToken: String
    let accessToken: String
    let refreshToken: String
}

// MARK: - Service Error

/// Service error types
enum SWServiceError: LocalizedError {
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
final class SWUserManager {

    // MARK: - Storage Keys

    private enum StorageKey: String {
        case isFirstLaunch
        case appLaunchCount
        case actionCompletedCount
        case lastReviewRequestDate
        case hasRequestedReview
    }

    // MARK: - Review Request Configuration

    private enum ReviewConfig {
        static let minActions = 2             // At least 2 completed actions
        static let minLaunches = 3            // At least 3 app launches
        static let daysBetweenRequests = 30   // Days between review requests
        static let delayBeforeRequest: Duration = .seconds(1)  // Delay before request
    }

    // MARK: - Properties

    /// User session state
    var sessionState: SWSessionState = .loading

    /// Whether an authentication operation is in progress
    var isAuthenticating = false

    /// Whether this is the first launch (stored property, trackable by @Observable)
    var isFirstLaunch: Bool = false {
        didSet {
            // Note: stores whether first launch has been completed, so invert the value
            UserDefaults.standard.set(!isFirstLaunch, forKey: StorageKey.isFirstLaunch.rawValue)
        }
    }

    private let authService = SWAuthService.shared

    // Review request related properties
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

    // MARK: - Initialization

    init() {
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: StorageKey.isFirstLaunch.rawValue)
        appLaunchCount += 1

        // Check authentication status
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Public Methods

    func completeFirstLaunch() {
        isFirstLaunch = false  // didSet automatically syncs to UserDefaults
    }

    // MARK: - Auth Status Check

    /// Check authentication status and update session state
    func checkAuthStatus() async {
        sessionState = .loading

        let isSignedIn = await authService.isSignedIn()

        if isSignedIn {
            do {
                let tokens = try await authService.fetchTokens()
                // Default to ready state directly
                // If there is an onboarding flow, query backend status here
                sessionState = .ready(tokens: tokens)
            } catch {
                swDebugLog("❌ [SWUserManager] Failed to check auth status:", error)
                sessionState = .signedOut(errorMessage: "Failed to fetch auth info")
            }
        } else {
            sessionState = .signedOut()
        }
    }

    // MARK: - Email/Password Authentication

    /// Sign up
    func signUp(email: String, password: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }
        try await authService.signUp(email: email, password: password)
    }

    /// Confirm email verification code
    func confirmSignUp(email: String, code: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }
        try await authService.confirmSignUp(email: email, code: code)
    }

    /// Resend verification code
    func resendSignUpCode(email: String) async throws {
        try await authService.resendSignUpCode(email: email)
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }

        let tokens = try await authService.signIn(email: email, password: password)
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - Social Sign In

    /// Apple Sign In
    func signInWithApple() async throws {
        swDebugLog("🍎 [Auth] Starting Apple Sign In...")

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            swDebugLog("🍎 [Auth] ❌ Cannot get window")
            throw SWServiceError.unknown("Cannot get window")
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            swDebugLog("🍎 [Auth] Calling authService.signInWithApple...")
            let tokens = try await authService.signInWithApple(presentationAnchor: window)
            swDebugLog("🍎 [Auth] ✅ Apple Sign In successful, got tokens")
            sessionState = .ready(tokens: tokens)
        } catch {
            swDebugLog("🍎 [Auth] ❌ Apple Sign In failed:", error)
            throw error
        }
    }

    /// Google Sign In
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            throw SWServiceError.unknown("Cannot get window")
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let tokens = try await authService.signInWithGoogle(presentationAnchor: window)
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - Guest Mode

    /// Skip sign in and enter guest mode
    func skipSignIn() {
        sessionState = .guest
    }

    /// Require sign in (switch from guest mode to sign in page)
    func requireSignIn() {
        sessionState = .signedOut()
    }

    // MARK: - Sign Out / Delete Account

    /// Sign out
    func signOut() async {
        await authService.signOut()
        sessionState = .signedOut()
    }

    /// Delete account
    func deleteAccount() async throws {
        try await authService.deleteUser()
        sessionState = .signedOut()
    }

    // MARK: - Password Reset

    /// Forgot password
    func forgotPassword(email: String) async throws {
        try await authService.forgotPassword(email: email)
    }

    /// Reset password
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
        try await authService.confirmResetPassword(email: email, newPassword: newPassword, code: code)
    }

    // MARK: - Onboarding

    /// Complete onboarding questionnaire, transition to ready state
    func completeOnboarding() {
        guard let tokens = sessionState.tokens else { return }
        sessionState = .ready(tokens: tokens)
    }

    // MARK: - Token Management

    /// Get the latest ID Token (automatically refreshes expired tokens)
    ///
    /// Important: Use this method to get token before each API call,
    /// instead of directly using the cached `sessionState.tokens?.idToken`
    ///
    /// How it works:
    /// 1. Calls `authService.fetchTokens()` -> `Amplify.Auth.fetchAuthSession()`
    /// 2. SDK automatically checks if ID Token is expired (default 1 hour)
    /// 3. If expired, SDK uses Refresh Token to obtain a new ID Token
    /// 4. Also updates the cached tokens
    ///
    /// Returns nil when:
    /// - User is not signed in
    /// - Refresh Token expired (30 days of inactivity), requires re-sign-in
    ///
    /// Usage example:
    /// ```swift
    /// guard let idToken = await userManager.getFreshIdToken() else { return }
    /// await apiService.fetchData(idToken: idToken)
    /// ```
    func getFreshIdToken() async -> String? {
        guard sessionState.isSignedIn else {
            return nil
        }

        do {
            let tokens = try await authService.fetchTokens()

            // Also update the cached tokens
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
            swDebugLog("❌ [SWUserManager] Failed to get fresh token:", error)
            return nil
        }
    }

    /// Refresh session
    func refreshSession() async throws {
        guard sessionState.tokens != nil else {
            throw SWServiceError.tokenMissing
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

    // MARK: - Review Request

    /// Record completed action count
    func incrementActionCompletedCount() {
        actionCompletedCount += 1
        requestReviewIfAppropriate()
    }

    /// Call after user completes a positive action
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

/// Authentication Service - uses Amplify SDK directly
actor SWAuthService {
    static let shared = SWAuthService()

    private init() {}

    // MARK: - Email/Password Authentication

    /// Sign up a new user
    func signUp(email: String, password: String) async throws {
        _ = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: AuthSignUpRequest.Options(
                userAttributes: [AuthUserAttribute(.email, value: email)]
            )
        )
    }

    /// Confirm email verification code
    func confirmSignUp(email: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(
            for: email,
            confirmationCode: code
        )

        guard result.isSignUpComplete else {
            throw SWServiceError.invalidState
        }
    }

    /// Resend verification code
    func resendSignUpCode(email: String) async throws {
        _ = try await Amplify.Auth.resendSignUpCode(for: email)
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> SWAuthTokens {
        let result = try await Amplify.Auth.signIn(
            username: email,
            password: password
        )

        guard result.isSignedIn else {
            throw SWServiceError.notSignedIn
        }

        return try await fetchTokens()
    }

    // MARK: - Social Sign In

    /// Apple Sign In
    func signInWithApple(presentationAnchor: AuthUIPresentationAnchor) async throws -> SWAuthTokens {
        #if DEBUG
        print("🍎 [SWAuthService] signInWithApple started")
        #endif

        // If already signed in, sign out first
        if await isSignedIn() {
            #if DEBUG
            print("🍎 [SWAuthService] Already signed in, signing out first...")
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
                throw SWServiceError.notSignedIn
            }

            return try await fetchTokens()
        } catch let error as AuthError {
            #if DEBUG
            print("🍎 [SWAuthService] ❌ AuthError:", error.errorDescription)
            #endif
            throw error
        } catch {
            #if DEBUG
            print("🍎 [SWAuthService] ❌ Unknown Error:", String(describing: error))
            #endif
            throw error
        }
    }

    /// Google Sign In
    func signInWithGoogle(presentationAnchor: AuthUIPresentationAnchor) async throws -> SWAuthTokens {
        // If already signed in, sign out first
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
            throw SWServiceError.notSignedIn
        }

        return try await fetchTokens()
    }

    // MARK: - Token Management

    /// Fetch current tokens
    func fetchTokens() async throws -> SWAuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession()

        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw SWServiceError.tokenMissing
        }

        let tokensResult = cognitoSession.getCognitoTokens()

        switch tokensResult {
        case .success(let tokens):
            return SWAuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw SWServiceError.tokenMissing
        }
    }

    /// Refresh tokens
    func refreshSession() async throws -> SWAuthTokens {
        let session = try await Amplify.Auth.fetchAuthSession(options: .forceRefresh())

        guard let cognitoSession = session as? AWSAuthCognitoSession else {
            throw SWServiceError.tokenMissing
        }

        let tokensResult = cognitoSession.getCognitoTokens()

        switch tokensResult {
        case .success(let tokens):
            return SWAuthTokens(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        case .failure:
            throw SWServiceError.tokenMissing
        }
    }

    // MARK: - Sign Out / Delete Account

    /// Sign out
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    /// Delete user account
    func deleteUser() async throws {
        try await Amplify.Auth.deleteUser()
    }

    /// Check sign in status
    func isSignedIn() async -> Bool {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            return session.isSignedIn
        } catch {
            return false
        }
    }

    // MARK: - Password Reset

    /// Forgot password - send verification code
    func forgotPassword(email: String) async throws {
        _ = try await Amplify.Auth.resetPassword(for: email)
    }

    /// Reset password - set new password using verification code
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
        try await Amplify.Auth.confirmResetPassword(
            for: email,
            with: newPassword,
            confirmationCode: code
        )
    }
}
