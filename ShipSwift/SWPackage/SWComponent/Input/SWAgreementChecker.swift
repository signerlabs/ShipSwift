//
//  SWAgreementChecker.swift
//  ShipSwift
//
//  A checkbox row for agreeing to Terms of Service and Privacy Policy.
//  Displays a toggle circle icon and two tappable links. The URLs are currently
//  hardcoded to signerlabs.com/fullpack/terms and signerlabs.com/fullpack/privacy.
//  To customize URLs, modify the Link destination strings in the source.
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
//  Parameters:
//    - agreementChecked: Binding<Bool> — Whether the user has checked the agreement checkbox
//
//  Notes:
//    - Tap the circle icon to toggle the checked state
//    - Terms of Service and Privacy Policy are external links that open in the browser
//    - To customize URLs, modify the Link destination strings in the file
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWAgreementChecker: View {
    @Binding var agreementChecked: Bool

    var body: some View {
        HStack {
            Button {
                agreementChecked.toggle()
            } label: {
                Image(systemName: agreementChecked ? "checkmark.circle.fill" : "circle")
            }

            HStack {
                Text("By signing in, you agree to our")
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://signerlabs.com/fullpack/terms")!) {
                    Text("Terms of Service")
                }

                Text("and")
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://signerlabs.com/fullpack/privacy")!) {
                    Text("Privacy Policy")
                }
            }
            .font(.footnote)
        }
        .padding(.top)
    }
}

#Preview {
    SWAgreementChecker(agreementChecked: .constant(false))
}
