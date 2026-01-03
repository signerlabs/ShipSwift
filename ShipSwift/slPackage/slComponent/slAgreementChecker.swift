//
//  slAgreementChecker.swift
//  ShipSwift
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct slAgreementChecker: View {
    @Binding var agreementChecked: Bool
    
    var body: some View {
        HStack {
            Button {
                agreementChecked.toggle()
            } label: {
                Image(systemName: agreementChecked ? "checkmark.circle.fill" : "circle")
            }
            
            HStack {
                Text("登录代表您已阅读并同意")
                    .foregroundStyle(.secondary)
                
                Link(destination: URL(string: slConstants.URL.termsOfService)!) {
                    Text("用户协议")
                }
                
                Text("和")
                    .foregroundStyle(.secondary)
                
                Link(destination: URL(string: slConstants.URL.privacyPolicy)!) {
                    Text("隐私条款")
                }
            }
            .font(.footnote)
        }
        .padding(.top)
    }
}

#Preview {
    slAgreementChecker(agreementChecked: .constant(false))
}
