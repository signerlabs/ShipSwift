//
//  SWAuthView.swift
//  ShipSwift
//
//  Generic authentication view template, copy into your project and customize.
//  Supports email/password sign-in, email verification code confirmation,
//  forgot password, and social sign-in.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

struct SWAuthView: View {

    // MARK: - Environment

    @Environment(SWUserManager.self) private var userManager

    // MARK: - View Mode

    private enum ViewMode {
        case signIn                    // Sign in
        case signUp                    // Sign up
        case confirmSignUp             // Confirm email verification code
        case forgotPassword            // Forgot password (enter email)
        case resetPassword             // Reset password (enter code and new password)
    }

    // MARK: - Loading State

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

    // Email sign-in state
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var emailVerificationCode = ""
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isEmailCodeFocused: Bool

    // Reset password state
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var resetCode = ""

    // MARK: - Computed Properties

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool {
        password.count >= 8
    }

    private var isValidConfirmPassword: Bool { password == confirmPassword && isValidPassword }

    private var isValidEmailCode: Bool { emailVerificationCode.count == 6 }

    private var isValidResetCode: Bool { resetCode.count == 6 }

    private var isValidNewPassword: Bool {
        newPassword.count >= 8
    }

    private var isValidConfirmNewPassword: Bool { newPassword == confirmNewPassword && isValidNewPassword }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.accentColor)
                        .padding()

                    // Title
                    VStack(spacing: 8) {
                        Text(headerTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(headerSubtitle)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 20)

                    // Display different content based on mode
                    switch viewMode {
                    case .signIn, .signUp:
                        mainAuthSection
                    case .confirmSignUp:
                        confirmSignUpSection
                    case .forgotPassword:
                        forgotPasswordSection
                    case .resetPassword:
                        resetPasswordSection
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .task {
                // Pre-trigger network permission request to avoid permission dialog
                // appearing during sign-in which could cause sign-in failure
                await prefetchNetworkPermission()
            }
        }
    }

    // MARK: - Network Permission Prefetch

    private func prefetchNetworkPermission() async {
        guard let url = URL(string: "https://www.apple.com") else { return }
        _ = try? await URLSession.shared.data(from: url)
    }

    private var headerTitle: String {
        switch viewMode {
        case .signIn: return "Welcome"
        case .signUp: return "Create Account"
        case .confirmSignUp: return "Verify Email"
        case .forgotPassword: return "Forgot Password"
        case .resetPassword: return "Reset Password"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn: return "Sign in to continue"
        case .signUp: return "Sign up with your email"
        case .confirmSignUp: return "Enter the 6-digit code sent to \(email)"
        case .forgotPassword: return "Enter your email to receive a reset code"
        case .resetPassword: return "Enter the code and your new password"
        }
    }

    // MARK: - Main Auth Section (SignIn/SignUp)

    @ViewBuilder
    private var mainAuthSection: some View {
        VStack(spacing: 16) {
            // Email sign-in area
            emailSignInSection

            // Social sign-in area
            if viewMode == .signIn {
                socialSignInSection
            }
        }
    }

    // MARK: - Email Sign-In Section

    @ViewBuilder
    private var emailSignInSection: some View {
        VStack(spacing: 12) {
            // Email input
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

            // Password input
            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                SecureField("Password", text: $password)
                    .textContentType(viewMode == .signUp ? .newPassword : .password)
                    .focused($isPasswordFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password requirements hint (sign-up mode only)
            if viewMode == .signUp && !password.isEmpty {
                passwordRequirements
            }

            // Confirm password (sign-up mode only)
            if viewMode == .signUp {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Sign-in / Sign-up button
            Button {
                if viewMode == .signUp {
                    signUpWithEmail()
                } else {
                    signInWithEmail()
                }
            } label: {
                HStack {
                    if loadingState == .signingIn {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(emailButtonText)
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isEmailFormValid || loadingState == .signingIn)

            // Forgot password (sign-in mode only)
            if viewMode == .signIn {
                Button {
                    withAnimation {
                        viewMode = .forgotPassword
                    }
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Toggle sign-in / sign-up
            Button {
                withAnimation {
                    viewMode = viewMode == .signIn ? .signUp : .signIn
                    confirmPassword = ""
                }
            } label: {
                Text(viewMode == .signUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Password Requirements

    @ViewBuilder
    private var passwordRequirements: some View {
        HStack(spacing: 4) {
            Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(password.count >= 8 ? .green : .secondary)
            Text("At least 8 characters")
                .foregroundStyle(password.count >= 8 ? .primary : .secondary)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var emailButtonText: String {
        if loadingState == .signingIn {
            return viewMode == .signUp ? "Creating Account..." : "Signing In..."
        }
        return viewMode == .signUp ? "Create Account" : "Sign In"
    }

    private var isEmailFormValid: Bool {
        if viewMode == .signUp {
            return isValidEmail && isValidConfirmPassword
        }
        return isValidEmail && password.count >= 8
    }

    // MARK: - Confirm SignUp Section

    @ViewBuilder
    private var confirmSignUpSection: some View {
        VStack(spacing: 16) {
            // Verification code input
            TextField("000000", text: $emailVerificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isEmailCodeFocused)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .padding(.vertical, 16)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: emailVerificationCode) { _, newValue in
                    emailVerificationCode = String(newValue.filter(\.isNumber).prefix(6))
                }

            // Confirm button
            Button {
                confirmSignUp()
            } label: {
                HStack {
                    if loadingState == .verifying {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(loadingState == .verifying ? "Verifying..." : "Verify Email")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidEmailCode || loadingState == .verifying)

            // Resend verification code
            Button {
                resendEmailCode()
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(loadingState == .sendingCode)

            // Back to sign in
            Button {
                withAnimation {
                    viewMode = .signIn
                    emailVerificationCode = ""
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isEmailCodeFocused = true
            }
        }
    }

    // MARK: - Forgot Password Section

    @ViewBuilder
    private var forgotPasswordSection: some View {
        VStack(spacing: 16) {
            // Email input
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

            // Send verification code button
            Button {
                sendResetCode()
            } label: {
                HStack {
                    if loadingState == .sendingCode {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(loadingState == .sendingCode ? "Sending..." : "Send Reset Code")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidEmail || loadingState == .sendingCode)

            // Back to sign in
            Button {
                withAnimation {
                    viewMode = .signIn
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Reset Password Section

    @ViewBuilder
    private var resetPasswordSection: some View {
        VStack(spacing: 16) {
            // Verification code input
            VStack(alignment: .leading, spacing: 4) {
                Text("Verification Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("000000", text: $resetCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospacedDigit())
                    .padding(.vertical, 16)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: resetCode) { _, newValue in
                        resetCode = String(newValue.filter(\.isNumber).prefix(6))
                    }
            }

            // New password
            VStack(alignment: .leading, spacing: 4) {
                Text("New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Password requirements hint
            if !newPassword.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(newPassword.count >= 8 ? .green : .secondary)
                    Text("At least 8 characters")
                        .foregroundStyle(newPassword.count >= 8 ? .primary : .secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }

            // Confirm new password
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !confirmNewPassword.isEmpty && newPassword != confirmNewPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Reset password button
            Button {
                confirmResetPassword()
            } label: {
                HStack {
                    if loadingState == .verifying {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(loadingState == .verifying ? "Resetting..." : "Reset Password")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidResetCode || !isValidConfirmNewPassword || loadingState == .verifying)

            // Back to sign in
            Button {
                withAnimation {
                    viewMode = .signIn
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
        .padding(.vertical)
    }

    // MARK: - Social Sign-In Section

    @ViewBuilder
    private var socialSignInSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(.tertiary)
                    .frame(height: 1)
                Text("or continue with")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(.tertiary)
                    .frame(height: 1)
            }
            .padding(.top, 16)

            // Social sign-in buttons
            HStack(spacing: 12) {
                // Apple sign-in
                Button {
                    signInWithApple()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Apple")
                    }
                }
                .buttonStyle(.swSecondary)

                // Google sign-in
                Button {
                    signInWithGoogle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                        Text("Google")
                    }
                }
                .buttonStyle(.swSecondary)
            }

            // User agreement
            SWAgreementChecker(agreementChecked: $agreementChecked)
        }
    }

    // MARK: - Actions

    private func signInWithEmail() {
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
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func signUpWithEmail() {
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .signingIn
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.signUp(email: email, password: password)
                withAnimation {
                    viewMode = .confirmSignUp
                }
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func confirmSignUp() {
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.confirmSignUp(email: email, code: emailVerificationCode)
                try await userManager.signIn(email: email, password: password)
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func resendEmailCode() {
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.resendSignUpCode(email: email)
                SWAlertManager.shared.show(.success, message: "Code sent to \(email)")
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func sendResetCode() {
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await userManager.forgotPassword(email: email)
                withAnimation {
                    viewMode = .resetPassword
                }
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func confirmResetPassword() {
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
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func signInWithApple() {
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await userManager.signInWithApple()
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }

    private func signInWithGoogle() {
        guard agreementChecked else {
            SWAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await userManager.signInWithGoogle()
            } catch {
                SWAlertManager.shared.show(.error, message: error.displayMessage)
            }
        }
    }
}

#Preview {
    SWAuthView()
        .environment(SWUserManager())
}

// MARK: - Auth Error Localization

extension Error {
    /// User-friendly error message
    var displayMessage: String {
        if let authError = self as? AuthError {
            if let cognitoError = authError.underlyingError as? AWSCognitoAuthError {
                return cognitoError.localizedMessage
            }
            return authError.localizedMessage
        }
        return localizedDescription
    }
}

extension AuthError {
    var localizedMessage: String {
        switch self {
        case .notAuthorized:
            return "Incorrect email or password"
        case .signedOut:
            return "Please sign in first"
        case .validation:
            return "Invalid input"
        case .configuration:
            return "App configuration error"
        case .service, .unknown, .invalidState:
            let desc = errorDescription.lowercased()
            if desc.contains("incorrect username or password") {
                return "Incorrect email or password"
            }
            if desc.contains("user does not exist") || desc.contains("user not found") {
                return "This email is not registered"
            }
            if desc.contains("user is not confirmed") {
                return "Please verify your email first"
            }
            return "Service error, please try again"
        default:
            return "Operation failed, please try again"
        }
    }
}

extension AWSCognitoAuthError {
    var localizedMessage: String {
        switch self {
        case .userNotFound:
            return "This email is not registered"
        case .userNotConfirmed:
            return "Please verify your email first"
        case .usernameExists:
            return "This email is already registered"
        case .codeDelivery:
            return "Failed to send verification code"
        case .codeMismatch:
            return "Incorrect verification code"
        case .codeExpired:
            return "Verification code expired"
        case .invalidPassword:
            return "Password must be at least 8 characters"
        case .limitExceeded, .failedAttemptsLimitExceeded, .requestLimitExceeded, .limitExceededException:
            return "Too many attempts, please try again later"
        case .network, .lambda, .externalServiceException:
            return "Network error, please try again"
        default:
            return "An error occurred, please try again"
        }
    }
}
