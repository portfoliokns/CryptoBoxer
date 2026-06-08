import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct UploadView: View {
    @EnvironmentObject var keyStore: KeyStore
    @State private var message: String = "ファイルを選択すると設定したパスワードで暗号化されます。\n暗号化されたファイルはファイル暗号化BOXにアップロードされます。"
    @State private var warning: String = ""
    @State private var useUUIDName = false
    @State private var deleteFlag = false

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
                .padding(.vertical, 4)
            Toggle("元ファイルを削除する", isOn: $deleteFlag)
                .padding(.vertical, 4)
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
        panel.allowedContentTypes = [.image, .movie, .pdf, .audio, .text]
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                saveFile(url)
            }
            message = "暗号化されました。画像・動画の一覧をご確認ください。"
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
            let storageFolder = try CryptoBoxerManager.shared.getFolderPath(folderName: "storage")
            var newName = ""
            if useUUIDName {
                newName = UUID().uuidString + "." + sourceURL.pathExtension
            } else {
                let baseName = sourceURL.deletingPathExtension().lastPathComponent
                let extensionName = sourceURL.pathExtension
                newName = sourceURL.lastPathComponent
                
                var counter = 1
                var destinationURL = storageFolder.appendingPathComponent(newName)
                while FileManager.default.fileExists(atPath: destinationURL.path) {
                    newName = "\(baseName)(\(counter)).\(extensionName)"
                    destinationURL = storageFolder.appendingPathComponent(newName)
                    counter += 1
                }
            }
            
            let destination = storageFolder.appendingPathComponent(newName)
            let data = try Data(contentsOf: sourceURL)
            let encrypted = try CryptoBoxerManager.shared.encrypt(data: data, using: key)
            try encrypted.write(to: destination)
            if deleteFlag {
                try FileManager.default.removeItem(at: sourceURL)
            }
            message = "暗号化中..."
        } catch {
            warning = "アップロードまたは暗号化に失敗しました。"
        }
    }
}
