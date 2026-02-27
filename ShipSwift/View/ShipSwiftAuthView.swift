//
//  ShipSwiftAuthView.swift
//  ShipSwift
//
//  Email-only authentication view for the ShipSwift Showcase app.
//  Supports sign in, sign up, email verification, and password reset.
//  No phone, Apple, or Google sign-in (to ensure cross-platform account linking).
//
//  Created by ShipSwift on 2/27/26.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

struct ShipSwiftAuthView: View {

    // MARK: - Environment

    @Environment(SWUserManager.self) private var userManager
    @Environment(\.dismiss) private var dismiss

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
        case loading
    }

    // MARK: - State

    @State private var viewMode: ViewMode = .signIn
    @State private var loadingState: LoadingState = .idle
    @State private var agreementChecked = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var resetCode = ""
    @FocusState private var isCodeFocused: Bool

    private let termsURL = URL(string: "https://www.shipswift.app/terms")!
    private let privacyURL = URL(string: "https://www.shipswift.app/privacy")!

    // MARK: - Validation

    private var isValidEmail: Bool {
        email.range(of: #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword }
    private var isValidCode: Bool { verificationCode.count == 6 }
    private var isValidResetCode: Bool { resetCode.count == 6 }
    private var isValidNewPassword: Bool { newPassword.count >= 8 }
    private var newPasswordsMatch: Bool { newPassword == confirmNewPassword }

    private var isLoading: Bool { loadingState == .loading }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                header
                Spacer(minLength: 20)

                switch viewMode {
                case .signIn:       signInSection
                case .signUp:       signUpSection
                case .confirmSignUp: confirmSignUpSection
                case .forgotPassword: forgotPasswordSection
                case .resetPassword: resetPasswordSection
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .swAlert()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(.shipSwiftLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(headerTitle)
                .font(.title)
                .fontWeight(.bold)

            Text(headerSubtitle)
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
        case .signIn:         "Sign in to manage your API key"
        case .signUp:         "Create an account with your email"
        case .confirmSignUp:  "Enter the 6-digit code sent to \(email)"
        case .forgotPassword: "Enter your email to receive a reset code"
        case .resetPassword:  "Enter the code and your new password"
        }
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 12) {
            emailField
            passwordField(text: $password, placeholder: "Password", contentType: .password)

            SWAgreementChecker(
                agreementChecked: $agreementChecked,
                termsURL: termsURL,
                privacyURL: privacyURL
            )

            actionButton(
                title: "Sign In",
                loadingTitle: "Signing In...",
                disabled: !isValidEmail || !isValidPassword || !agreementChecked
            ) {
                await signIn()
            }

            Button {
                withAnimation { viewMode = .forgotPassword }
            } label: {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }

            Button {
                withAnimation { viewMode = .signUp; confirmPassword = "" }
            } label: {
                Text("Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Sign Up

    private var signUpSection: some View {
        VStack(spacing: 12) {
            emailField
            passwordField(text: $password, placeholder: "Password", contentType: .newPassword)

            if !password.isEmpty {
                passwordHint(valid: isValidPassword)
            }

            passwordField(text: $confirmPassword, placeholder: "Confirm Password", contentType: .newPassword)

            if !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            SWAgreementChecker(
                agreementChecked: $agreementChecked,
                termsURL: termsURL,
                privacyURL: privacyURL
            )

            actionButton(
                title: "Create Account",
                loadingTitle: "Creating Account...",
                disabled: !isValidEmail || !isValidPassword || !passwordsMatch || !agreementChecked
            ) {
                await signUp()
            }

            Button {
                withAnimation { viewMode = .signIn }
            } label: {
                Text("Already have an account? Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Confirm Sign Up

    private var confirmSignUpSection: some View {
        VStack(spacing: 16) {
            codeField(text: $verificationCode)

            actionButton(
                title: "Verify Email",
                loadingTitle: "Verifying...",
                disabled: !isValidCode
            ) {
                await confirmSignUp()
            }

            Button {
                Task { await resendCode() }
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }

            backToSignIn
        }
        .padding(.vertical)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isCodeFocused = true
        }
    }

    // MARK: - Forgot Password

    private var forgotPasswordSection: some View {
        VStack(spacing: 16) {
            emailField

            actionButton(
                title: "Send Reset Code",
                loadingTitle: "Sending...",
                disabled: !isValidEmail
            ) {
                await sendResetCode()
            }

            backToSignIn
        }
        .padding(.vertical)
    }

    // MARK: - Reset Password

    private var resetPasswordSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Verification Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                codeField(text: $resetCode)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                passwordField(text: $newPassword, placeholder: "New Password", contentType: .newPassword)
            }

            if !newPassword.isEmpty {
                passwordHint(valid: isValidNewPassword)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                passwordField(text: $confirmNewPassword, placeholder: "Confirm New Password", contentType: .newPassword)

                if !confirmNewPassword.isEmpty && !newPasswordsMatch {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            actionButton(
                title: "Reset Password",
                loadingTitle: "Resetting...",
                disabled: !isValidResetCode || !isValidNewPassword || !newPasswordsMatch
            ) {
                await confirmResetPassword()
            }

            backToSignIn
        }
        .padding(.vertical)
    }

    // MARK: - Reusable Components

    private var emailField: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundStyle(.secondary)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func passwordField(text: Binding<String>, placeholder: String, contentType: UITextContentType) -> some View {
        HStack {
            Image(systemName: "lock")
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: text)
                .textContentType(contentType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func codeField(text: Binding<String>) -> some View {
        TextField("000000", text: text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isCodeFocused)
            .multilineTextAlignment(.center)
            .font(.title2.monospacedDigit())
            .padding(.vertical, 16)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .padding(.horizontal, 4)
    }

    private func actionButton(title: String, loadingTitle: String, disabled: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(isLoading ? loadingTitle : title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(disabled || isLoading)
    }

    private var backToSignIn: some View {
        Button {
            withAnimation {
                viewMode = .signIn
                verificationCode = ""
                resetCode = ""
                newPassword = ""
                confirmNewPassword = ""
            }
        } label: {
            Text("Back to Sign In")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func signIn() async {
        loadingState = .loading
        defer { loadingState = .idle }
        do {
            try await userManager.signIn(email: email, password: password)
        } catch {
            showError(error)
        }
    }

    private func signUp() async {
        loadingState = .loading
        defer { loadingState = .idle }
        do {
            try await userManager.signUp(email: email, password: password)
            withAnimation { viewMode = .confirmSignUp }
        } catch {
            showError(error)
        }
    }

    private func confirmSignUp() async {
        loadingState = .loading
        defer { loadingState = .idle }
        do {
            try await userManager.confirmSignUp(email: email, code: verificationCode)
            try await userManager.signIn(email: email, password: password)
            SWTikTokTrackingManager.shared.track(.completeRegistration)
        } catch {
            showError(error)
        }
    }

    private func resendCode() async {
        do {
            try await userManager.resendSignUpCode(email: email)
            SWAlertManager.shared.show(.success, message: "Code sent to \(email)")
        } catch {
            showError(error)
        }
    }

    private func sendResetCode() async {
        loadingState = .loading
        defer { loadingState = .idle }
        do {
            try await userManager.forgotPassword(email: email)
            withAnimation { viewMode = .resetPassword }
        } catch {
            showError(error)
        }
    }

    private func confirmResetPassword() async {
        loadingState = .loading
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
            showError(error)
        }
    }

    // MARK: - Error Handling

    private func showError(_ error: Error) {
        swDebugLog("Auth error: \(error)")
        let message: String
        if let authError = error as? AuthError {
            swDebugLog("AuthError: \(authError.errorDescription), underlying: \(String(describing: authError.underlyingError))")
            if let cognitoError = authError.underlyingError as? AWSCognitoAuthError {
                message = cognitoMessage(cognitoError)
            } else {
                message = authMessage(authError)
            }
        } else {
            message = error.localizedDescription
        }
        SWAlertManager.shared.show(.error, message: message)
    }

    private func authMessage(_ error: AuthError) -> String {
        switch error {
        case .notAuthorized:
            return "Incorrect email or password"
        case .validation:
            return "Invalid input"
        default:
            let desc = error.errorDescription.lowercased()
            if desc.contains("incorrect username or password") { return "Incorrect email or password" }
            if desc.contains("user does not exist") { return "This email is not registered" }
            if desc.contains("user is not confirmed") { return "Please verify your email first" }
            return "Something went wrong, please try again"
        }
    }

    private func cognitoMessage(_ error: AWSCognitoAuthError) -> String {
        switch error {
        case .userNotFound:      "This email is not registered"
        case .userNotConfirmed:  "Please verify your email first"
        case .usernameExists:    "This email is already registered"
        case .codeMismatch:      "Incorrect verification code"
        case .codeExpired:       "Verification code expired"
        case .invalidPassword:   "Password must be at least 8 characters"
        case .limitExceeded, .requestLimitExceeded:
            "Too many attempts, please try again later"
        default:                 "An error occurred, please try again"
        }
    }
}

#Preview {
    NavigationStack {
        ShipSwiftAuthView()
            .environment(SWUserManager(skipAuthCheck: true))
    }
}
