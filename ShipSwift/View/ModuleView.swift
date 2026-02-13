//
//  ModuleView.swift
//  ShipSwift
//
//  Modules tab — showcases multi-file module components
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ModuleView: View {
    var body: some View {
        NavigationStack {
            List {
                // Auth demo — pure UI showcase of SWAuth module (no backend)
                NavigationLink {
                    SWAuthDemoView()
                } label: {
                    ListItem(
                        title: "Auth",
                        icon: "person.badge.key.fill",
                        description: "Complete auth flow: email sign-in/up, verification code, forgot/reset password, Apple & Google social sign-in."
                    )
                }

                // Settings module
                NavigationLink {
                    SWSettingView()
                } label: {
                    ListItem(
                        title: "Setting",
                        icon: "gearshape.fill",
                        description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                    )
                }
            }
            .navigationTitle("Modules")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }

                }
            }
        }
    }
}

// MARK: - Auth Demo View (Pure UI, No Backend)

/// Standalone demo view showcasing the SWAuth module UI interactions.
/// Does not import Amplify or connect to any backend — all actions are simulated locally.
private struct SWAuthDemoView: View {

    // MARK: - View Mode

    private enum ViewMode: CaseIterable {
        case signIn
        case signUp
        case verifyEmail
        case forgotPassword
        case resetPassword
    }

    // MARK: - State

    @State private var viewMode: ViewMode = .signIn
    @State private var isLoading = false

    // Sign in / sign up fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Verify email
    @State private var verificationCode = ""
    @FocusState private var isCodeFocused: Bool

    // Reset password
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""

    // Agreement
    @State private var agreementChecked = false

    // MARK: - Computed Properties

    private var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword && isValidPassword }
    private var isValidCode: Bool { verificationCode.count == 6 }
    private var isValidResetCode: Bool { resetCode.count == 6 }
    private var isValidNewPassword: Bool { newPassword.count >= 8 }
    private var newPasswordsMatch: Bool { newPassword == confirmNewPassword && isValidNewPassword }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Icon
                Image(.shipSwiftLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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

                // Content based on mode
                switch viewMode {
                case .signIn, .signUp:
                    mainAuthSection
                case .verifyEmail:
                    verifyEmailSection
                case .forgotPassword:
                    forgotPasswordSection
                case .resetPassword:
                    resetPasswordSection
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Text

    private var headerTitle: String {
        switch viewMode {
        case .signIn:         return "Welcome"
        case .signUp:         return "Create Account"
        case .verifyEmail:    return "Verify Email"
        case .forgotPassword: return "Forgot Password"
        case .resetPassword:  return "Reset Password"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn:         return "Sign in to continue"
        case .signUp:         return "Sign up with your email"
        case .verifyEmail:    return "Enter the 6-digit code sent to \(email.isEmpty ? "your email" : email)"
        case .forgotPassword: return "Enter your email to receive a reset code"
        case .resetPassword:  return "Enter the code and your new password"
        }
    }

    // MARK: - Main Auth Section (Sign In / Sign Up)

    @ViewBuilder
    private var mainAuthSection: some View {
        VStack(spacing: 16) {
            emailFormSection

            if viewMode == .signIn {
                socialSignInSection
            }
        }
    }

    // MARK: - Email Form

    @ViewBuilder
    private var emailFormSection: some View {
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password requirements hint (sign-up only)
            if viewMode == .signUp && !password.isEmpty {
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

            // Confirm password (sign-up only)
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

            // Primary action button
            Button {
                simulateAction {
                    if viewMode == .signUp {
                        SWAlertManager.shared.show(.success, message: "Demo: Account created — verification code sent")
                        withAnimation { viewMode = .verifyEmail }
                    } else {
                        SWAlertManager.shared.show(.success, message: "Demo: Sign in successful")
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryButtonText)
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isFormValid || isLoading)

            // Forgot password (sign-in only)
            if viewMode == .signIn {
                Button {
                    withAnimation { viewMode = .forgotPassword }
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
                Text(viewMode == .signUp
                     ? "Already have an account? Sign In"
                     : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical)
    }

    private var primaryButtonText: String {
        if isLoading {
            return viewMode == .signUp ? "Creating Account..." : "Signing In..."
        }
        return viewMode == .signUp ? "Create Account" : "Sign In"
    }

    private var isFormValid: Bool {
        if viewMode == .signUp {
            return isValidEmail && passwordsMatch
        }
        return isValidEmail && isValidPassword
    }

    // MARK: - Verify Email Section

    @ViewBuilder
    private var verifyEmailSection: some View {
        VStack(spacing: 16) {
            // 6-digit code input
            TextField("000000", text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .padding(.vertical, 16)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: verificationCode) { _, newValue in
                    verificationCode = String(newValue.filter(\.isNumber).prefix(6))
                }

            // Verify button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Email verified successfully")
                    withAnimation { viewMode = .signIn }
                    verificationCode = ""
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Verifying..." : "Verify Email")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidCode || isLoading)

            // Resend code
            Button {
                SWAlertManager.shared.show(.info, message: "Demo: Verification code resent")
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }

            // Back
            Button {
                withAnimation {
                    viewMode = .signIn
                    verificationCode = ""
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isCodeFocused = true
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

            // Send reset code
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Reset code sent to \(email)")
                    withAnimation { viewMode = .resetPassword }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Sending..." : "Send Reset Code")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidEmail || isLoading)

            // Back
            Button {
                withAnimation { viewMode = .signIn }
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
            // Reset code
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

            // Password requirements
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
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Password reset successful")
                    withAnimation {
                        viewMode = .signIn
                        resetCode = ""
                        newPassword = ""
                        confirmNewPassword = ""
                        password = ""
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Resetting..." : "Reset Password")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidResetCode || !newPasswordsMatch || isLoading)

            // Back
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

            // Social buttons
            HStack(spacing: 12) {
                Button {
                    SWAlertManager.shared.show(.info, message: "Demo: Apple sign-in requires Auth Recipe")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Apple")
                    }
                }
                .buttonStyle(.swSecondary)

                Button {
                    SWAlertManager.shared.show(.info, message: "Demo: Google sign-in requires Auth Recipe")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                        Text("Google")
                    }
                }
                .buttonStyle(.swSecondary)
            }

            // Agreement checker
            SWAgreementChecker(agreementChecked: $agreementChecked)
        }
    }

    // MARK: - Helpers

    /// Simulates a loading state for 1 second, then executes the completion
    private func simulateAction(completion: @escaping () -> Void) {
        isLoading = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            isLoading = false
            completion()
        }
    }
}

#Preview {
    ModuleView()
}
