//
//  slAuthView.swift
//  ShipSwift
//
//  通用认证视图，支持手机号验证码登录、邮箱密码登录、邮箱验证码确认、忘记密码
//

import SwiftUI

// MARK: - 认证协议

/// 认证服务协议，调用者需实现此协议以提供具体的认证逻辑
protocol slAuthService {
    /// 发送手机验证码
    func sendPhoneVerificationCode(phoneNumber: String) async throws
    /// 验证手机验证码
    func verifyPhoneCode(phoneNumber: String, code: String) async throws
    /// 邮箱密码登录
    func signInWithEmail(email: String, password: String) async throws
    /// 邮箱注册（发送验证码到邮箱）
    func signUpWithEmail(email: String, password: String) async throws
    /// 确认邮箱验证码（注册后）
    func confirmSignUp(email: String, code: String) async throws
    /// 重新发送邮箱验证码
    func resendSignUpCode(email: String) async throws
    /// 发送重置密码验证码
    func resetPassword(email: String) async throws
    /// 确认重置密码
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws
    /// Apple 登录
    func signInWithApple() async throws
    /// Google 登录
    func signInWithGoogle() async throws
}

// MARK: - 配置

/// slAuthView 配置
struct slAuthViewConfig {
    /// 应用标题
    var title: String = "Welcome"
    /// 应用副标题
    var subtitle: String = "Sign in to continue"
    /// 图标 SF Symbol 名称
    var iconName: String = "person.circle.fill"
    /// 图标大小
    var iconSize: CGFloat = 80
    /// 是否显示 Apple 登录
    var showAppleSignIn: Bool = true
    /// 是否显示 Google 登录
    var showGoogleSignIn: Bool = true
    /// 是否显示手机号登录
    var showPhoneSignIn: Bool = true
    /// 是否显示邮箱登录
    var showEmailSignIn: Bool = true
    /// 默认国家区号
    var defaultCountryCode: String = "+86"
    /// 是否需要同意协议
    var requireAgreement: Bool = true
    /// 密码最小长度
    var minPasswordLength: Int = 8
    /// 是否要求密码包含大小写和数字（默认关闭，简化用户体验）
    var requireStrongPassword: Bool = false

    static let `default` = slAuthViewConfig()
}

// MARK: - slAuthView

struct slAuthView<Service: slAuthService>: View {

    // MARK: - 视图模式

    private enum ViewMode {
        case signIn                    // 登录
        case signUp                    // 注册
        case confirmSignUp             // 确认邮箱验证码
        case forgotPassword            // 忘记密码（输入邮箱）
        case resetPassword             // 重置密码（输入验证码和新密码）
    }

    // MARK: - 加载状态

    private enum LoadingState {
        case idle
        case sendingCode
        case verifying
        case signingIn
    }

    // MARK: - 属性

    let authService: Service
    let config: slAuthViewConfig

    // MARK: - 状态

    @State private var viewMode: ViewMode = .signIn
    @State private var loadingState: LoadingState = .idle
    @State private var agreementChecked = false

    // 手机号登录状态
    @State private var phoneNumber = ""
    @State private var countryCode: String
    @State private var phoneVerificationCode = ""
    @State private var showingCountryPicker = false
    @State private var isPhoneCodeSent = false
    @State private var countrySearchText = ""
    @FocusState private var isPhoneCodeFocused: Bool

    // 邮箱登录状态
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var emailVerificationCode = ""
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isEmailCodeFocused: Bool

    // 重置密码状态
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var resetCode = ""

    // MARK: - 计算属性

    private var isValidPhone: Bool {
        let expectedLength = slCountryData.phoneLength(for: countryCode)
        return expectedLength.contains(phoneNumber.count)
    }

    private var isValidPhoneCode: Bool { phoneVerificationCode.count == 6 }

    private var fullPhoneNumber: String { "\(countryCode)\(phoneNumber)" }

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool {
        guard password.count >= config.minPasswordLength else { return false }
        if config.requireStrongPassword {
            let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
            let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
            return hasUppercase && hasLowercase && hasDigit
        }
        return true
    }

    private var isValidConfirmPassword: Bool { password == confirmPassword && isValidPassword }

    private var isValidEmailCode: Bool { emailVerificationCode.count == 6 }

    private var isValidResetCode: Bool { resetCode.count == 6 }

    private var isValidNewPassword: Bool {
        guard newPassword.count >= config.minPasswordLength else { return false }
        if config.requireStrongPassword {
            let hasUppercase = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
            let hasLowercase = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
            let hasDigit = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
            return hasUppercase && hasLowercase && hasDigit
        }
        return true
    }

    private var isValidConfirmNewPassword: Bool { newPassword == confirmNewPassword && isValidNewPassword }

    // MARK: - 初始化

    init(authService: Service, config: slAuthViewConfig = .default) {
        self.authService = authService
        self.config = config
        self._countryCode = State(initialValue: config.defaultCountryCode)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // 图标
                    Image(systemName: config.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: config.iconSize, height: config.iconSize)
                        .foregroundStyle(Color.accentColor)
                        .padding()

                    // 文案
                    headerText

                    Spacer(minLength: 20)

                    // 根据模式显示不同内容
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
            .sheet(isPresented: $showingCountryPicker) {
                countryCodePicker
            }
            .task {
                // 预先触发网络权限请求，避免登录时才弹出权限弹窗导致登录失败
                await prefetchNetworkPermission()
            }
        }
    }

    // MARK: - Network Permission Prefetch

    /// 预先触发网络权限请求
    private func prefetchNetworkPermission() async {
        // 发起一个简单的网络请求来触发 iOS 网络权限弹窗
        guard let url = URL(string: "https://www.apple.com") else { return }
        _ = try? await URLSession.shared.data(from: url)
    }

    // MARK: - Header Text

    @ViewBuilder
    private var headerText: some View {
        VStack(spacing: 8) {
            Text(headerTitle)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(headerSubtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var headerTitle: String {
        switch viewMode {
        case .signIn: return config.title
        case .signUp: return "Create Account"
        case .confirmSignUp: return "Verify Email"
        case .forgotPassword: return "Forgot Password"
        case .resetPassword: return "Reset Password"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn: return config.subtitle
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
            // 手机号登录区域
            if config.showPhoneSignIn && viewMode == .signIn {
                phoneSignInSection
            }

            // 邮箱登录区域
            if config.showEmailSignIn {
                emailSignInSection
            }

            // 社交登录区域
            if viewMode == .signIn {
                socialSignInSection
            }
        }
    }

    // MARK: - 手机号登录区域

    @ViewBuilder
    private var phoneSignInSection: some View {
        VStack(spacing: 12) {
            HStack {
                // 选择国家
                Button {
                    if isPhoneCodeSent {
                        withAnimation {
                            isPhoneCodeSent = false
                            phoneVerificationCode = ""
                        }
                    } else {
                        showingCountryPicker = true
                    }
                } label: {
                    HStack {
                        Text(slCountryData.flag(for: countryCode))
                        Text(countryCode)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .buttonStyle(.slSecondary)

                // 手机号输入
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isPhoneCodeSent)
                    .onTapGesture {
                        if isPhoneCodeSent {
                            withAnimation {
                                isPhoneCodeSent = false
                                phoneVerificationCode = ""
                            }
                        }
                    }
            }

            // 验证码输入框
            if isPhoneCodeSent {
                TextField("000000", text: $phoneVerificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isPhoneCodeFocused)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: phoneVerificationCode) { _, newValue in
                        phoneVerificationCode = String(newValue.filter(\.isNumber).prefix(6))
                    }
                    .overlay(alignment: .trailing) {
                        Button {
                            resendPhoneCode()
                        } label: {
                            Text("Resend")
                        }
                        .padding()
                    }
            }

            // 按钮
            if isPhoneCodeSent {
                Button {
                    verifyPhoneCode()
                } label: {
                    Text(loadingState == .verifying ? "Verifying..." : "Verify")
                }
                .disabled(!isValidPhoneCode || loadingState == .verifying)
                .buttonStyle(.slPrimary)
            } else {
                Button {
                    sendPhoneCode()
                } label: {
                    HStack {
                        if loadingState == .sendingCode {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(loadingState == .sendingCode ? "Sending..." : "Send Verification Code")
                    }
                }
                .buttonStyle(.slPrimary)
                .disabled(!isValidPhone || loadingState == .sendingCode)
            }
        }
        .padding(.vertical)
    }

    // MARK: - 邮箱登录区域

    @ViewBuilder
    private var emailSignInSection: some View {
        VStack(spacing: 12) {
            // 邮箱输入
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

            // 密码输入
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

            // 密码要求提示（仅注册模式）
            if viewMode == .signUp && !password.isEmpty {
                passwordRequirements
            }

            // 确认密码（仅注册模式）
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

            // 登录/注册按钮
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
            .buttonStyle(.slPrimary)
            .disabled(!isEmailFormValid || loadingState == .signingIn)

            // 忘记密码（仅登录模式）
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

            // 切换登录/注册
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
        VStack(alignment: .leading, spacing: 4) {
            requirementRow("At least \(config.minPasswordLength) characters", met: password.count >= config.minPasswordLength)
            if config.requireStrongPassword {
                requirementRow("Contains uppercase letter", met: password.range(of: "[A-Z]", options: .regularExpression) != nil)
                requirementRow("Contains lowercase letter", met: password.range(of: "[a-z]", options: .regularExpression) != nil)
                requirementRow("Contains number", met: password.range(of: "[0-9]", options: .regularExpression) != nil)
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? .green : .secondary)
            Text(text)
                .foregroundStyle(met ? .primary : .secondary)
        }
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
        return isValidEmail && password.count >= config.minPasswordLength
    }

    // MARK: - Confirm SignUp Section

    @ViewBuilder
    private var confirmSignUpSection: some View {
        VStack(spacing: 16) {
            // 验证码输入
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

            // 确认按钮
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
            .buttonStyle(.slPrimary)
            .disabled(!isValidEmailCode || loadingState == .verifying)

            // 重新发送验证码
            Button {
                resendEmailCode()
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(loadingState == .sendingCode)

            // 返回登录
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
            // 邮箱输入
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

            // 发送验证码按钮
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
            .buttonStyle(.slPrimary)
            .disabled(!isValidEmail || loadingState == .sendingCode)

            // 返回登录
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
            // 验证码输入
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

            // 新密码
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

            // 密码要求提示
            if !newPassword.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    requirementRow("At least \(config.minPasswordLength) characters", met: newPassword.count >= config.minPasswordLength)
                    if config.requireStrongPassword {
                        requirementRow("Contains uppercase letter", met: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                        requirementRow("Contains lowercase letter", met: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                        requirementRow("Contains number", met: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }

            // 确认新密码
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

            // 重置密码按钮
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
            .buttonStyle(.slPrimary)
            .disabled(!isValidResetCode || !isValidConfirmNewPassword || loadingState == .verifying)

            // 返回登录
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

    // MARK: - 社交登录区域

    @ViewBuilder
    private var socialSignInSection: some View {
        let showSocialLogin = config.showAppleSignIn || config.showGoogleSignIn

        if showSocialLogin {
            VStack(spacing: 16) {
                // 分隔线
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

                // 社交登录按钮
                HStack(spacing: 12) {
                    // Apple 登录按钮
                    if config.showAppleSignIn {
                        Button {
                            signInWithApple()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18))
                                Text("Apple")
                            }
                        }
                        .buttonStyle(.slSecondary)
                    }

                    // Google 登录按钮
                    if config.showGoogleSignIn {
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 18))
                                Text("Google")
                            }
                        }
                        .buttonStyle(.slSecondary)
                    }
                }

                if config.requireAgreement {
                    slAgreementChecker(agreementChecked: $agreementChecked)
                }
            }
        }
    }

    // MARK: - 国家区号选择器

    private var countryCodePicker: some View {
        CountryCodePickerView(
            countryCode: $countryCode,
            searchText: $countrySearchText,
            isPresented: $showingCountryPicker
        )
    }

    // MARK: - 操作方法

    // 手机号相关
    private func sendPhoneCode() {
        if config.requireAgreement && !agreementChecked {
            slAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber)
                withAnimation {
                    isPhoneCodeSent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isPhoneCodeFocused = true
                }
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func resendPhoneCode() {
        Task {
            do {
                try await authService.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber)
                slAlertManager.shared.show(.success, message: "Code sent")
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func verifyPhoneCode() {
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.verifyPhoneCode(phoneNumber: fullPhoneNumber, code: phoneVerificationCode)
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    // 邮箱相关
    private func signInWithEmail() {
        if config.requireAgreement && !agreementChecked {
            slAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .signingIn
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.signInWithEmail(email: email, password: password)
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func signUpWithEmail() {
        if config.requireAgreement && !agreementChecked {
            slAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        loadingState = .signingIn
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.signUpWithEmail(email: email, password: password)
                // 注册成功，切换到验证码确认页面
                withAnimation {
                    viewMode = .confirmSignUp
                }
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func confirmSignUp() {
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.confirmSignUp(email: email, code: emailVerificationCode)
                // 验证成功，自动登录
                try await authService.signInWithEmail(email: email, password: password)
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func resendEmailCode() {
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.resendSignUpCode(email: email)
                slAlertManager.shared.show(.success, message: "Code sent to \(email)")
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    // 重置密码相关
    private func sendResetCode() {
        loadingState = .sendingCode
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.resetPassword(email: email)
                withAnimation {
                    viewMode = .resetPassword
                }
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func confirmResetPassword() {
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.confirmResetPassword(email: email, newPassword: newPassword, code: resetCode)
                slAlertManager.shared.show(.success, message: "Password reset successfully")
                withAnimation {
                    viewMode = .signIn
                    resetCode = ""
                    newPassword = ""
                    confirmNewPassword = ""
                    password = ""
                }
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    // 社交登录
    private func signInWithApple() {
        if config.requireAgreement && !agreementChecked {
            slAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func signInWithGoogle() {
        if config.requireAgreement && !agreementChecked {
            slAlertManager.shared.show(.error, message: "Please agree to the Terms of Service and Privacy Policy")
            return
        }
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }
}

// MARK: - 国家区号选择器视图

private struct CountryCodePickerView: View {
    @Binding var countryCode: String
    @Binding var searchText: String
    @Binding var isPresented: Bool

    private var filteredCountries: [slCountry] {
        if searchText.isEmpty {
            return slCountryData.allCountries
        }
        return slCountryData.allCountries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.contains(searchText)
        }
    }

    private var groupedCountries: [(key: String, value: [slCountry])] {
        Dictionary(grouping: filteredCountries) { country in
            String(country.name.prefix(1)).uppercased()
        }.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedCountries, id: \.key) { letter, countries in
                    Section(header: Text(letter)) {
                        ForEach(countries, id: \.name) { country in
                            Button {
                                countryCode = country.code
                                searchText = ""
                                isPresented = false
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
            .searchable(text: $searchText, prompt: "Search")
            .tint(.primary)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        searchText = ""
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewAuthService: slAuthService {
        func sendPhoneVerificationCode(phoneNumber: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func verifyPhoneCode(phoneNumber: String, code: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func signInWithEmail(email: String, password: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func signUpWithEmail(email: String, password: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func confirmSignUp(email: String, code: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func resendSignUpCode(email: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func resetPassword(email: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func signInWithApple() async throws {
            try await Task.sleep(for: .seconds(1))
        }
        func signInWithGoogle() async throws {
            try await Task.sleep(for: .seconds(1))
        }
    }

    return slAuthView(
        authService: PreviewAuthService(),
        config: slAuthViewConfig(
            title: "Welcome",
            subtitle: "Sign in to continue",
            iconName: "star.circle.fill",
            showPhoneSignIn: false
        )
    )
}
