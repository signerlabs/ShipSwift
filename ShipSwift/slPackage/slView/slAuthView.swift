//
//  slAuthView.swift
//  ShipSwift
//
//  通用认证视图，支持手机号验证码登录和邮箱密码登录
//

import SwiftUI
import UIKit

// MARK: - 认证协议

/// 认证服务协议，调用者需实现此协议以提供具体的认证逻辑
protocol slAuthService {
    /// 发送手机验证码
    func sendPhoneVerificationCode(phoneNumber: String) async throws
    /// 验证手机验证码
    func verifyPhoneCode(phoneNumber: String, code: String) async throws
    /// 邮箱密码登录
    func signInWithEmail(email: String, password: String) async throws
    /// 邮箱注册
    func signUpWithEmail(email: String, password: String) async throws
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

    static let `default` = slAuthViewConfig()
}

// MARK: - slAuthView

struct slAuthView<Service: slAuthService>: View {

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

    @State private var loadingState: LoadingState = .idle
    @State private var agreementChecked = false
    @State private var isKeyboardVisible = false

    // 手机号登录状态
    @State private var phoneNumber = ""
    @State private var countryCode: String
    @State private var verificationCode = ""
    @State private var showingCountryPicker = false
    @State private var isCodeSent = false
    @State private var countrySearchText = ""
    @FocusState private var isVerificationCodeFocused: Bool

    // 邮箱登录状态
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var confirmPassword = ""
    @FocusState private var isPasswordFocused: Bool

    // MARK: - 计算属性

    private var isValidPhone: Bool {
        let expectedLength = slCountryData.phoneLength(for: countryCode)
        return expectedLength.contains(phoneNumber.count)
    }

    private var isValidCode: Bool { verificationCode.count == 6 }

    private var fullPhoneNumber: String { "\(countryCode)\(phoneNumber)" }

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool { password.count >= 6 }

    private var isValidConfirmPassword: Bool { password == confirmPassword && isValidPassword }

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
                    VStack(spacing: 8) {
                        Text(config.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(config.subtitle)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 20)

                    // 手机号登录区域
                    if config.showPhoneSignIn {
                        phoneSignInSection
                    }

                    // 邮箱登录区域
                    if config.showEmailSignIn {
                        emailSignInSection
                    }

                    // 社交登录区域
                    if !isKeyboardVisible {
                        socialSignInSection
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingCountryPicker) {
                countryCodePicker
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation { isKeyboardVisible = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation { isKeyboardVisible = false }
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
                    if isCodeSent {
                        withAnimation {
                            isCodeSent = false
                            verificationCode = ""
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
                    .disabled(isCodeSent)
                    .onTapGesture {
                        if isCodeSent {
                            withAnimation {
                                isCodeSent = false
                                verificationCode = ""
                            }
                        }
                    }
            }
            
            // 验证码输入框
            if isCodeSent {
                TextField("000000", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isVerificationCodeFocused)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: verificationCode) { _, newValue in
                        verificationCode = String(newValue.prefix(6))
                    }
                    .overlay(alignment: .trailing) {
                        Button {
                            resendVerificationCode()
                        } label: {
                            Text("Resend")
                        }
                        .padding()
                    }
            }
            
            // 按钮
            if isCodeSent {
                Button {
                    verifyCode()
                } label: {
                    Text(loadingState == .verifying ? "Verifying..." : "Verify")
                }
                .disabled(!isValidCode || loadingState == .verifying)
                .buttonStyle(.slPrimary)
            } else {
                Button {
                    sendVerificationCode()
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
                    .textContentType(isSignUpMode ? .newPassword : .password)
                    .focused($isPasswordFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 确认密码（仅注册模式）
            if isSignUpMode {
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
            }
            
            // 登录/注册按钮
            Button {
                if isSignUpMode {
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
            
            // 切换登录/注册
            Button {
                withAnimation {
                    isSignUpMode.toggle()
                    confirmPassword = ""
                }
            } label: {
                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical)
    }

    private var emailButtonText: String {
        if loadingState == .signingIn {
            return isSignUpMode ? "Creating Account..." : "Signing In..."
        }
        return isSignUpMode ? "Create Account" : "Sign In"
    }

    private var isEmailFormValid: Bool {
        if isSignUpMode {
            return isValidEmail && isValidConfirmPassword
        }
        return isValidEmail && isValidPassword
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

    private func sendVerificationCode() {
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
                    isCodeSent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isVerificationCodeFocused = true
                }
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func resendVerificationCode() {
        Task {
            do {
                try await authService.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber)
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

    private func verifyCode() {
        loadingState = .verifying
        Task {
            defer { loadingState = .idle }
            do {
                try await authService.verifyPhoneCode(phoneNumber: fullPhoneNumber, code: verificationCode)
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

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
            } catch {
                slAlertManager.shared.show(.error, message: error.localizedDescription)
            }
        }
    }

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
            iconName: "star.circle.fill"
        )
    )
}
