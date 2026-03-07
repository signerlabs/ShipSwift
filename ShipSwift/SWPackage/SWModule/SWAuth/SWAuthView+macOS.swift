//
//  SWAuthView+macOS.swift
//  ShipSwift
//
//  macOS-native authentication view.
//  Email sign-in/up, verification, forgot/reset password, Apple and Google sign-in.
//  Phone sign-in is not included (macOS convention).
//
//  Designed as a centered 380pt panel with native macOS control styles.
//
//  Created by Wei Zhong on 3/7/26.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

struct SWAuthView: View {

    var isDemo: Bool = false

    // MARK: - Environment

    @Environment(SWUserManager.self) private var userManager

    // MARK: - View Mode

    private enum ViewMode {
        case signIn
        case signUp
        case confirmSignUp
        case forgotPassword
        case resetPassword
    }

    private enum LoadingState {
        case idle
        case sendingCode
        case verifying
        case signingIn
    }

    // MARK: - State

    @State private var viewMode: ViewMode = .signIn
    @State private var loadingState: LoadingState = .idle
    @State private var agreementChecked = false

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @FocusState private var isCodeFocused: Bool

    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var resetCode = ""

    // MARK: - Validation

    private var isValidEmail: Bool {
        email.range(of: #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#,
                    options: .regularExpression) != nil
    }
    private var isValidPassword: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword }
    private var isValidCode: Bool { verificationCode.count == 6 }
    private var isValidResetCode: Bool { resetCode.count == 6 }
    private var isValidNewPassword: Bool { newPassword.count >= 8 }
    private var newPasswordsMatch: Bool { newPassword == confirmNewPassword }

    private var isEmailFormValid: Bool {
        viewMode == .signUp
            ? isValidEmail && isValidPassword && passwordsMatch
            : isValidEmail && isValidPassword
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    panel
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task { await prefetchNetworkPermission() }
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(spacing: 28) {
            header

            switch viewMode {
            case .signIn:         signInSection
            case .signUp:         signUpSection
            case .confirmSignUp:  confirmSignUpSection
            case .forgotPassword: forgotPasswordSection
            case .resetPassword:  resetPasswordSection
            }
        }
        .padding(36)
        .frame(maxWidth: 380)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(Color.accentColor)

            Text(headerTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var headerTitle: String {
        switch viewMode {
        case .signIn:         "Welcome Back"
        case .signUp:         "Create Account"
        case .confirmSignUp:  "Verify Email"
        case .forgotPassword: "Forgot Password"
        case .resetPassword:  "Reset Password"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn:         "Sign in to continue"
        case .signUp:         "Sign up with your email"
        case .confirmSignUp:  "Enter the 6-digit code sent to \(email)"
        case .forgotPassword: "Enter your email to receive a reset code"
        case .resetPassword:  "Enter the code and your new password"
        }
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 16) {
            emailField
            passwordField(text: $password, placeholder: "Password", newPassword: false)

            SWAgreementChecker(agreementChecked: $agreementChecked)

            primaryButton(
                title: "Sign In",
                loadingTitle: "Signing In…",
                isLoading: loadingState == .signingIn,
                disabled: !isEmailFormValid || !agreementChecked
            ) { signInWithEmail() }

            HStack(spacing: 20) {
                linkButton("Forgot Password?") {
                    withAnimation { viewMode = .forgotPassword }
                }
                linkButton("Create Account") {
                    withAnimation { viewMode = .signUp; confirmPassword = "" }
                }
            }

            socialDivider

            socialButtons
        }
    }

    // MARK: - Sign Up

    private var signUpSection: some View {
        VStack(spacing: 12) {
            emailField
            passwordField(text: $password, placeholder: "Password", newPassword: true)

            if !password.isEmpty {
                passwordHint(valid: isValidPassword)
            }

            passwordField(text: $confirmPassword, placeholder: "Confirm Password", newPassword: true)

            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            SWAgreementChecker(agreementChecked: $agreementChecked)

            primaryButton(
                title: "Create Account",
                loadingTitle: "Creating…",
                isLoading: loadingState == .signingIn,
                disabled: !isEmailFormValid || !agreementChecked
            ) { signUpWithEmail() }

            linkButton("Already have an account? Sign In") {
                withAnimation { viewMode = .signIn }
            }
        }
    }

    // MARK: - Confirm Sign Up

    private var confirmSignUpSection: some View {
        VStack(spacing: 16) {
            codeField(text: $verificationCode)

            primaryButton(
                title: "Verify Email",
                loadingTitle: "Verifying…",
                isLoading: loadingState == .verifying,
                disabled: !isValidCode
            ) { confirmSignUp() }

            HStack(spacing: 20) {
                linkButton("Resend Code") { resendEmailCode() }
                linkButton("Back to Sign In") {
                    withAnimation { viewMode = .signIn; verificationCode = "" }
                }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isCodeFocused = true
        }
    }

    // MARK: - Forgot Password

    private var forgotPasswordSection: some View {
        VStack(spacing: 16) {
            emailField

            primaryButton(
                title: "Send Reset Code",
                loadingTitle: "Sending…",
                isLoading: loadingState == .sendingCode,
                disabled: !isValidEmail
            ) { sendResetCode() }

            backToSignIn
        }
    }

    // MARK: - Reset Password

    private var resetPasswordSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Verification Code").font(.caption).foregroundStyle(.secondary)
                codeField(text: $resetCode)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("New Password").font(.caption).foregroundStyle(.secondary)
                passwordField(text: $newPassword, placeholder: "New Password", newPassword: true)
            }

            if !newPassword.isEmpty {
                passwordHint(valid: isValidNewPassword)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm New Password").font(.caption).foregroundStyle(.secondary)
                passwordField(text: $confirmNewPassword, placeholder: "Confirm New Password", newPassword: true)
                if !confirmNewPassword.isEmpty && !newPasswordsMatch {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            primaryButton(
                title: "Reset Password",
                loadingTitle: "Resetting…",
                isLoading: loadingState == .verifying,
                disabled: !isValidResetCode || !isValidNewPassword || !newPasswordsMatch
            ) { confirmResetPassword() }

            backToSignIn
        }
    }

    // MARK: - Reusable Controls

    private var emailField: some View {
        TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
    }

    private func passwordField(text: Binding<String>, placeholder: String, newPassword: Bool) -> some View {
        SecureField(placeholder, text: text)
            .textContentType(newPassword ? .newPassword : .password)
            .textFieldStyle(.roundedBorder)
    }

    private func codeField(text: Binding<String>) -> some View {
        TextField("000000", text: text)
            .textContentType(.oneTimeCode)
            .focused($isCodeFocused)
            .multilineTextAlignment(.center)
            .font(.title2.monospacedDigit())
            .textFieldStyle(.roundedBorder)
            .onChange(of: text.wrappedValue) { _, newValue in
                text.wrappedValue = String(newValue.filter(\.isNumber).prefix(6))
            }
    }

    private func passwordHint(valid: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: valid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(valid ? .green : .secondary)
            Text("At least 8 characters")
                .foregroundStyle(valid ? .primary : .secondary)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primaryButton(
        title: String,
        loadingTitle: String,
        isLoading: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading { ProgressView().controlSize(.small) }
                Text(isLoading ? loadingTitle : title)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(disabled || isLoading)
    }

    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(Color.accentColor)
    }

    private var backToSignIn: some View {
        linkButton("Back to Sign In") {
            withAnimation {
                viewMode = .signIn
                verificationCode = ""
                resetCode = ""
                newPassword = ""
                confirmNewPassword = ""
            }
        }
    }

    private var socialDivider: some View {
        HStack {
            Rectangle().fill(.tertiary).frame(height: 1)
            Text("or continue with")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle().fill(.tertiary).frame(height: 1)
        }
    }

    private var socialButtons: some View {
        HStack(spacing: 12) {
            Button {
                signInWithApple()
            } label: {
                Label("Apple", systemImage: "apple.logo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                signInWithGoogle()
            } label: {
                Label("Google", systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - Actions

    private func demoGuard() -> Bool {
        guard isDemo else { return false }
        SWAlertManager.shared.show(.info, message: "UI Demo — auth actions are not functional")
        return true
    }

    private func prefetchNetworkPermission() async {
        guard let url = URL(string: "https://www.apple.com") else { return }
        _ = try? await URLSession.shared.data(from: url)
    }

    private func signInWithEmail() {
        guard !demoGuard() else { return }
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .signingIn
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.signIn(email: email, password: password)
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func signUpWithEmail() {
        guard !demoGuard() else { return }
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .signingIn
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.signUp(email: email, password: password)
                withAnimation { viewMode = .confirmSignUp }
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func confirmSignUp() {
        guard !demoGuard() else { return }
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.confirmSignUp(email: email, code: verificationCode)
                try await userManager.signIn(email: email, password: password)
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func resendEmailCode() {
        guard !demoGuard() else { return }
        Task {
            do {
                try await userManager.resendSignUpCode(email: email)
                SWAlertManager.shared.show(.success, message: "Code sent to \(email)")
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func sendResetCode() {
        guard !demoGuard() else { return }
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.forgotPassword(email: email)
                withAnimation { viewMode = .resetPassword }
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func confirmResetPassword() {
        guard !demoGuard() else { return }
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.confirmResetPassword(email: email, newPassword: newPassword, code: resetCode)
                SWAlertManager.shared.show(.success, message: "Password reset successfully")
                withAnimation {
                    viewMode = .signIn
                    resetCode = ""
                    newPassword = ""
                    confirmNewPassword = ""
                    password = ""
                }
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func signInWithApple() {
        guard !demoGuard() else { return }
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await userManager.signInWithApple()
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }

    private func signInWithGoogle() {
        guard !demoGuard() else { return }
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await userManager.signInWithGoogle()
            } catch {
                SWAlertManager.shared.show(.error, message: SWMacAuthErrorHelper.displayMessage(for: error))
            }
        }
    }
}

#Preview {
    SWAuthView()
        .environment(SWUserManager(skipAuthCheck: true))
        .frame(width: 600, height: 700)
}

// MARK: - Auth Error Localization

private enum SWMacAuthErrorHelper {

    static func displayMessage(for error: Error) -> String {
        if let authError = error as? AuthError {
            if let cognitoError = authError.underlyingError as? AWSCognitoAuthError {
                return cognitoMessage(for: cognitoError)
            }
            return authMessage(for: authError)
        }
        return error.localizedDescription
    }

    private static func authMessage(for error: AuthError) -> String {
        switch error {
        case .notAuthorized:   return "Incorrect email or password"
        case .signedOut:       return "Please sign in first"
        case .validation:      return "Invalid input"
        case .configuration:   return "App configuration error"
        default:
            let desc = error.errorDescription.lowercased()
            if desc.contains("incorrect username or password") { return "Incorrect email or password" }
            if desc.contains("user does not exist")            { return "This email is not registered" }
            if desc.contains("user is not confirmed")          { return "Please verify your email first" }
            return "Service error, please try again"
        }
    }

    private static func cognitoMessage(for error: AWSCognitoAuthError) -> String {
        switch error {
        case .userNotFound:        return "This email is not registered"
        case .userNotConfirmed:    return "Please verify your email first"
        case .usernameExists:      return "This email is already registered"
        case .codeDelivery:        return "Failed to send verification code"
        case .codeMismatch:        return "Incorrect verification code"
        case .codeExpired:         return "Verification code expired"
        case .invalidPassword:     return "Password must be at least 8 characters"
        case .limitExceeded, .failedAttemptsLimitExceeded, .requestLimitExceeded, .limitExceededException:
            return "Too many attempts, please try again later"
        case .network, .lambda, .externalServiceException:
            return "Network error, please try again"
        default:                   return "An error occurred, please try again"
        }
    }
}
