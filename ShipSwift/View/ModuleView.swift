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
    @State private var showAuthDemo = false
    @State private var showCameraDemo = false

    var body: some View {
        NavigationStack {
            List {
                // Auth demo — fullScreenCover 方式展示 SWAuth 模块（无后端）
                Button {
                    showAuthDemo = true
                } label: {
                    ListItem(
                        title: "Auth",
                        icon: "person.badge.key.fill",
                        description: "Complete auth flow: email sign-in/up, phone sign-in with country code picker, verification code, forgot/reset password, Apple & Google social sign-in."
                    )
                }

                // Camera demo — showcase SWCamera UI components (no real camera)
                Button {
                    showCameraDemo = true
                } label: {
                    ListItem(
                        title: "Camera",
                        icon: "camera.fill",
                        description: "Full camera capture view with viewfinder overlay, pinch-to-zoom, zoom slider, photo library picker, and permission handling."
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
        .fullScreenCover(isPresented: $showAuthDemo) {
            NavigationStack {
                SWAuthDemoView()
            }
        }
        .fullScreenCover(isPresented: $showCameraDemo) {
            SWCameraDemoView()
                .swAlert()
        }
    }
}

// MARK: - Auth Demo View (Pure UI, No Backend)

/// Standalone demo view showcasing the SWAuth module UI interactions.
/// Does not import Amplify or connect to any backend — all actions are simulated locally.
private struct SWAuthDemoView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - View Mode

    private enum ViewMode: CaseIterable {
        case signIn
        case signUp
        case verifyEmail
        case forgotPassword
        case resetPassword
        case phoneSignIn
        case phoneVerify
    }

    // 登录方式枚举，用于顶部 Segmented Picker 切换 Email / Phone
    private enum SignInMethod: String, CaseIterable {
        case email = "Email"
        case phone = "Phone"
    }

    // MARK: - State

    @State private var viewMode: ViewMode = .signIn
    @State private var signInMethod: SignInMethod = .email
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

    // Phone sign-in
    @State private var phoneNumber = ""
    @State private var countryCode = "+1"
    @State private var showingCountryPicker = false
    @State private var countrySearchText = ""
    @State private var phoneVerificationCode = ""
    @FocusState private var isPhoneCodeFocused: Bool

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
    private var isValidPhone: Bool {
        let expectedLength = SWCountryData.phoneLength(for: countryCode)
        return expectedLength.contains(phoneNumber.count)
    }
    private var isValidPhoneCode: Bool { phoneVerificationCode.count == 6 }
    private var fullPhoneNumber: String { "\(countryCode)\(phoneNumber)" }

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

                // 登录方式切换按钮，仅在 signIn / phoneSignIn 模式下显示
                if viewMode == .signIn || viewMode == .phoneSignIn {
                    HStack(spacing: 12) {
                        signInMethodButton(.email, icon: "envelope.fill", label: "Email")
                        signInMethodButton(.phone, icon: "phone.fill", label: "Phone")
                    }
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
                case .phoneSignIn:
                    phoneSignInSection
                case .phoneVerify:
                    phoneVerifySection
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: signInMethod) { _, newMethod in
            withAnimation {
                switch newMethod {
                case .email: viewMode = .signIn
                case .phone: viewMode = .phoneSignIn
                }
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            countryCodePicker
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Header Text

    private var headerTitle: String {
        switch viewMode {
        case .signIn:         return "Welcome"
        case .signUp:         return "Create Account"
        case .verifyEmail:    return "Verify Email"
        case .forgotPassword: return "Forgot Password"
        case .resetPassword:  return "Reset Password"
        case .phoneSignIn:    return "Phone Sign In"
        case .phoneVerify:    return "Verify Phone"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn:         return "Sign in to continue"
        case .signUp:         return "Sign up with your email"
        case .verifyEmail:    return "Enter the 6-digit code sent to \(email.isEmpty ? "your email" : email)"
        case .forgotPassword: return "Enter your email to receive a reset code"
        case .resetPassword:  return "Enter the code and your new password"
        case .phoneSignIn:    return "Sign in with your phone number"
        case .phoneVerify:    return "Enter the 6-digit code sent to \(fullPhoneNumber)"
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
                    signInMethod = .email
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
                    withAnimation {
                        viewMode = .signIn
                        signInMethod = .email
                    }
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
                    signInMethod = .email
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
                withAnimation {
                    viewMode = .signIn
                    signInMethod = .email
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
                        signInMethod = .email
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
                    signInMethod = .email
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

    // MARK: - Phone Sign-In Section

    @ViewBuilder
    private var phoneSignInSection: some View {
        VStack(spacing: 16) {
            // Country code + phone number input
            HStack(spacing: 8) {
                // Country code selector button
                Button {
                    showingCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(SWCountryData.flag(for: countryCode))
                        Text(countryCode)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Phone number input
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: phoneNumber) { _, newValue in
                        let cleaned = newValue.replacingOccurrences(of: " ", with: "")
                        if cleaned != newValue {
                            phoneNumber = cleaned
                        }
                    }
            }

            // Send verification code button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Code sent to \(fullPhoneNumber)")
                    withAnimation { viewMode = .phoneVerify }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Sending..." : "Send Verification Code")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidPhone || isLoading)

            // Social sign-in area
            socialSignInSection
        }
        .padding(.vertical)
    }

    // MARK: - Phone Verify Section

    @ViewBuilder
    private var phoneVerifySection: some View {
        VStack(spacing: 16) {
            // 6-digit verification code input
            TextField("000000", text: $phoneVerificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isPhoneCodeFocused)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .padding(.vertical, 16)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: phoneVerificationCode) { _, newValue in
                    phoneVerificationCode = String(newValue.filter(\.isNumber).prefix(6))
                }

            // Verify button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Phone verified successfully")
                    withAnimation {
                        viewMode = .signIn
                        signInMethod = .email
                    }
                    phoneVerificationCode = ""
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Verifying..." : "Verify Phone")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidPhoneCode || isLoading)

            // Resend code
            Button {
                SWAlertManager.shared.show(.info, message: "Demo: Verification code resent to \(fullPhoneNumber)")
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }

            // 返回 phoneSignIn，保持 signInMethod = .phone
            Button {
                withAnimation {
                    viewMode = .phoneSignIn
                    phoneVerificationCode = ""
                }
            } label: {
                Text("Back")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isPhoneCodeFocused = true
        }
    }

    // MARK: - Country Code Picker

    private var countryCodePicker: some View {
        let filteredCountries: [SWCountry] = countrySearchText.isEmpty
            ? SWCountryData.allCountries
            : SWCountryData.allCountries.filter {
                $0.name.localizedCaseInsensitiveContains(countrySearchText) ||
                $0.code.contains(countrySearchText)
            }
        let groupedCountries = Dictionary(grouping: filteredCountries) { country in
            String(country.name.prefix(1)).uppercased()
        }.sorted { $0.key < $1.key }

        return NavigationStack {
            List {
                ForEach(groupedCountries, id: \.key) { letter, countries in
                    Section(header: Text(letter)) {
                        ForEach(countries, id: \.name) { country in
                            Button {
                                countryCode = country.code
                                countrySearchText = ""
                                showingCountryPicker = false
                            } label: {
                                HStack {
                                    Text(country.flag)
                                        .font(.title2)
                                    HStack(spacing: 8) {
                                        Text(country.name)
                                            .foregroundStyle(.primary)
                                        Text(country.code)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if countryCode == country.code {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $countrySearchText, prompt: "Search")
            .tint(.primary)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        countrySearchText = ""
                        showingCountryPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// 登录方式切换按钮：选中态为 accentColor + 胶囊背景，未选中态为 secondary
    private func signInMethodButton(_ method: SignInMethod, icon: String, label: String) -> some View {
        Button {
            withAnimation { signInMethod = method }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.subheadline)
            .fontWeight(signInMethod == method ? .medium : .regular)
            .foregroundStyle(signInMethod == method ? Color.accentColor : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                signInMethod == method ? Color.accentColor.opacity(0.1) : Color.clear,
                in: Capsule()
            )
        }
    }

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

// MARK: - Camera Demo View (Real Camera, No Processing)

/// 使用真实 SWCameraView 的 Demo，拍摄或选择的照片不做任何处理和保存。
private struct SWCameraDemoView: View {
    @State private var capturedImage: UIImage?

    var body: some View {
        SWCameraView(image: $capturedImage)
            .swAlert()
    }
}

#Preview {
    ModuleView()
}
