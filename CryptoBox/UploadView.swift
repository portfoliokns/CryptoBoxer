import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct UploadView: View {
    @EnvironmentObject var keyStore: KeyStore
    @State private var message: String = "ファイルを選択すると設定したパスワードで暗号化されます。\n暗号化されたファイルはファイル暗号化BOXにアップロードされます。"
    @State private var warning: String = ""
    @State private var useUUIDName = false

    var body: some View {
        VStack() {
            Text(warning)
                .font(.title)
                .foregroundColor(.red)
            Text(message)
                .font(.title)
                .foregroundColor(.black)
            Button(action: {
                openFile()
            }) {
                Text("画像・動画を選択")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            Toggle("ファイル名を匿名化する", isOn: $useUUIDName)
                .padding()
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    func openFile() {
        guard keyStore.key != nil else {
            warning = "先にパスワードを設定してください。\n設定されていないと暗号化ができません"
            return
        }
        warning = ""
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .movie]
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                saveFile(url)
            }
        }
    }
    
    func saveFile(_ sourceURL: URL) {
        guard let key = keyStore.key else {
            warning = "パスワードが設定されていません。暗号化に失敗しました。"
            message = ""
            return
        }
        warning = ""
        
        do {
            let storageFolder = try CryptoBoxManager.shared.getFolderPath(folderName: "storage")
            var newName = ""
            if useUUIDName {
                newName = UUID().uuidString + "." + sourceURL.pathExtension
            } else {
                newName = sourceURL.lastPathComponent
            }
            let destination = storageFolder.appendingPathComponent(newName)
            let data = try Data(contentsOf: sourceURL)
            let encrypted = try CryptoBoxManager.shared.encrypt(data: data, using: key)
            try encrypted.write(to: destination)
            message = "暗号化されました。画像・動画の一覧をご確認ください。"
        } catch {
            warning = "アップロードまたは暗号化に失敗しました。"
        }
    }
}
