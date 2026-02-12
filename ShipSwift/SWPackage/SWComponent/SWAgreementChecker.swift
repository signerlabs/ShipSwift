//
//  SWAgreementChecker.swift
//  ShipSwift
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
