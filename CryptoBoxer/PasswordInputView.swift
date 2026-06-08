import SwiftUI
import CryptoKit
import Combine

class KeyStore: ObservableObject{
    @Published var key: SymmetricKey? = nil
}

struct PasswordInputView: View {
    @State private var password: String = ""
    @State private var rePassword: String = ""
    @State private var message: String = ""
    @State private var warning: String = ""
    @State private var passRePassword = false
    @EnvironmentObject var keyStore: KeyStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View{
        VStack {
            Text(message)
                .font(.title)
                .foregroundColor(.black)
            Text(warning)
                .font(.title)
                .foregroundColor(.red)
            SecureField("パスワードを入力", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    submitPassword()
                }
            if passRePassword {
                SecureField("パスワードを入力(再)", text: $rePassword)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                    submitPassword()
                }
            }
            Toggle("パスワード(再)を入力する※誤ったパスワードで暗号化する恐れを防止します", isOn: $passRePassword)
                .padding(.vertical, 4)
            Button(action: submitPassword) {
                Text("設定")
                    .padding()
                    .background((password.isEmpty) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(password.isEmpty)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .center)
        .onAppear {setMessage()}
    }
    
    func submitPassword() {
        if password.isEmpty {
            return
        }
        if passRePassword {
            if rePassword.isEmpty {
                warning = "パスワード(再)を入力してください。"
                return
            }
            if password != rePassword {
                warning = "パスワードが一致しません。パスワードを見直してください。"
                return
            }
        }
        keyStore.key = CryptoBoxerManager.shared.makeKey(from: password)
        dismiss()
        warning = ""
    }
    
    func setMessage() {
        if keyStore.key != nil {
            message = "✅ パスワードは設定済みです。変更したい場合は設定し直してください。"
        } else {
            message = "❌ まだパスワードは設定されていません。"
        }
    }
}
