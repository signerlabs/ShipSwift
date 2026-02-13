//
//  SWAgreementChecker.swift
//  ShipSwift
//
//  A checkbox row for agreeing to Terms of Service and Privacy Policy.
//  Displays a toggle circle icon and two tappable links. URLs are configurable
//  via termsURL and privacyURL parameters (defaults to example.com placeholders).
//
//  Usage:
//    @State private var agreed = false
//
//    VStack {
//        // ... sign-in form ...
//
//        SWAgreementChecker(agreementChecked: $agreed)
//
//        Button("Sign In") { signIn() }
//            .disabled(!agreed)
//    }
//
//    // Custom URLs
//    SWAgreementChecker(
//        agreementChecked: $agreed,
//        termsURL: URL(string: "https://myapp.com/terms")!,
//        privacyURL: URL(string: "https://myapp.com/privacy")!
//    )
//
//  Parameters:
//    - agreementChecked: Binding<Bool> — Whether the user has checked the agreement checkbox
//    - termsURL: URL — Link destination for Terms of Service (default: https://example.com/terms)
//    - privacyURL: URL — Link destination for Privacy Policy (default: https://example.com/privacy)
//
//  Notes:
//    - Tap the circle icon to toggle the checked state
//    - Terms of Service and Privacy Policy are external links that open in the browser
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWAgreementChecker: View {
    @Binding var agreementChecked: Bool

    var termsURL: URL = URL(string: "https://shipswift.app/terms")!
    var privacyURL: URL = URL(string: "https://shipswift.app/privacy")!

    var body: some View {
        HStack {
            Button {
                agreementChecked.toggle()
            } label: {
                Image(systemName: agreementChecked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)
            }

            HStack {
                Text("By signing in, you agree to")
                    .foregroundStyle(.secondary)

                Link(destination: termsURL) {
                    Text("Terms of Service")
                }

                Text("and")
                    .foregroundStyle(.secondary)

                Link(destination: privacyURL) {
                    Text("Privacy Policy")
                }
            }
            .font(.caption2)
        }
        .padding(.top)
    }
}

#Preview {
    @Previewable @State var agreed = false

    SWAgreementChecker(agreementChecked: $agreed)
        .padding()
}
