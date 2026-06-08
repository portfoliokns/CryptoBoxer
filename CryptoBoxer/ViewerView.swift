import SwiftUI
import UniformTypeIdentifiers

struct ViewerView: View {
    @State private var message: String = ""
    @State private var warning: String = ""
    @State private var files: [URL] = []
    @EnvironmentObject var keyStore: KeyStore
    @State private var isShowingMessage: Bool = false
    let buttonWidth: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 0) {
            Text(warning)
                .font(.title)
                .foregroundColor(.red)
            Text(message)
                .font(.title)
                .foregroundColor(.black)
            
            HStack(spacing: 0) {
                Button(action: {
                    importFiles()
                }) {
                    Text("暗号ファイル取込")
                        .frame(width: buttonWidth)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Button(action: {
                    CryptoBoxerManager.shared.openFinder(folderName: "storage")
                    setMessages("Finderのstorageフォルダを開きました。", "")
                }) {
                    Text("フォルダを開く")
                        .frame(width: buttonWidth)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            
            HStack(spacing: 0) {
                Button(action: {
                    downloadeEryptFilse()
                }) {
                    Text("一括書き出し(暗号化)")
                        .frame(width: buttonWidth)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Button(action: {
                    downloadDecryptFilse()
                }) {
                    Text("一括書き出し(復号化)")
                        .frame(width: buttonWidth)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Button(action: {
                    isShowingMessage = true
                }) {
                    Text("全削除")
                        .frame(width: buttonWidth)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .alert("データの全削除", isPresented: $isShowingMessage) {
                    Button("キャンセル", role: .cancel) {}
                    Button("削除する", role: .destructive) {
                        CryptoBoxerManager.shared.clearFilse(folderName: "storage")
                        CryptoBoxerManager.shared.clearFilse(folderName: "tmp")
                        self.files = []
                        setMessages("CryptoBoxer上からファイルが全て削除されました。", "")
                    }
                } message: {
                    Text("CryptoBoxerに保存されているデータが全て削除されます。よろしいですか？")
                }
            }
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ]) {
                    ForEach(files, id: \.self) { url in
                        VStack {
                            Image(systemName: "lock")
                                .font(.largeTitle)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(height: 120)
                        .onTapGesture {
                            guard let key = keyStore.key else { return }
                            Task{
                                do {
                                    let tmpFolder = try CryptoBoxerManager.shared.getFolderPath(folderName: "tmp")
                                    let fileName = url.deletingPathExtension().lastPathComponent
                                    let ext = url.pathExtension
                                    let tmpURL = tmpFolder.appendingPathComponent(fileName).appendingPathExtension(ext)
                                    CryptoBoxerManager.shared.openFinder(folderName: "tmp")
                                    setMessages("Finderのtmpフォルダを開きました。", "")
                                    warning = ""
                                    if FileManager.default.fileExists(atPath: tmpURL.path) { return }
                                    let encrypted = try Data(contentsOf: url)
                                    let decrypted = try CryptoBoxerManager.shared.decrypt(data: encrypted, using: key)
                                    try decrypted.write(to: tmpURL)
                                } catch {
                                    setMessages("", "動画の展開中にエラーが発生しました。")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadFiles()
        }
    }
    
    func loadFiles() {
        let fileManager = FileManager.default
        do {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let storage = appSupport
                .appendingPathComponent("CryptoBoxer")
                .appendingPathComponent("storage")
            let allFiles = try fileManager.contentsOfDirectory(
                at: storage,
                includingPropertiesForKeys: nil
            )
            files = filterHiddenFiles(allFiles: allFiles)
        } catch {
            debugPrint("読み込みエラー", error)
        }
    }
    
    func downloadeEryptFilse() {
        let fileManager = FileManager.default

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "保存先フォルダを選択してください"
        
        DispatchQueue.main.async {
            setMessages("保存中...", "")
        }

        if panel.runModal() == .OK, let selectedFolder = panel.url {
            let canAccess = selectedFolder.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    selectedFolder.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let storageFolder = try CryptoBoxerManager.shared.getFolderPath(folderName: "storage")
                let allowedExtensions: Set<String> = ["png","jpg","jpeg","heic","gif","mp4","mov","m4v", "webm", "pdf"]

                let files = try fileManager.contentsOfDirectory(
                    at: storageFolder,
                    includingPropertiesForKeys: nil
                ).filter {
                    allowedExtensions.contains($0.pathExtension.lowercased())
                }

                for fileURL in files {
                    let destination = selectedFolder.appendingPathComponent(fileURL.lastPathComponent)

                    if fileManager.fileExists(atPath: destination.path) {
                        try fileManager.removeItem(at: destination)
                    }
                    try fileManager.copyItem(at: fileURL, to: destination)
                }
                setMessages("暗号化されたファイルの保存が完了しました。", "")

            } catch {
                setMessages("", "ファイルの保存に失敗しました。")
            }
        } else {
            DispatchQueue.main.async {
                setMessages("", "")
            }
        }
    }
    
    func importFiles() {
        let fileManager = FileManager.default
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .movie]
        panel.allowsMultipleSelection = true
        
        DispatchQueue.main.async {
            setMessages("取り込み中...", "")
        }
        
        do {
            let storageFolder = try CryptoBoxerManager.shared.getFolderPath(folderName: "storage")
            if panel.runModal() == .OK {
                for url in panel.urls {
                    let baseName = url.deletingPathExtension().lastPathComponent
                    let extensionName = url.pathExtension
                    var newName = url.lastPathComponent
                    
                    var counter = 1
                    var destinationURL = storageFolder.appendingPathComponent(url.lastPathComponent)
                    while FileManager.default.fileExists(atPath: destinationURL.path) {
                        newName = "\(baseName)(\(counter)).\(extensionName)"
                        destinationURL = storageFolder.appendingPathComponent(newName)
                        counter += 1
                    }
                    try fileManager.copyItem(at: url, to: destinationURL)
                }
                loadFiles()
                setMessages("暗号化ファイルを取り込みました。", "")
            } else {
                setMessages("", "")
            }
        } catch {
            setMessages("", "ファイルの保存に失敗しました。")
        }
    }
    
    func downloadDecryptFilse() {
        let fileManager = FileManager.default

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "保存先フォルダを選択してください"
        
        DispatchQueue.main.async {
            setMessages("保存中...", "")
        }

        if panel.runModal() == .OK, let selectedFolder = panel.url {
            let canAccess = selectedFolder.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    selectedFolder.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let storageFolder = try CryptoBoxerManager.shared.getFolderPath(folderName: "storage")
                let allFiles = try fileManager.contentsOfDirectory(at: storageFolder, includingPropertiesForKeys: nil)
                guard let key = keyStore.key else {
                    setMessages("", "復号キーが見つかりません。パスワードを設定し直してください。")
                    return
                }
                
                let filterringFiles = filterHiddenFiles(allFiles: allFiles)
                
                for fileURL in filterringFiles {
                    let encryptedData = try Data(contentsOf: fileURL)
                    let decryptedData = try CryptoBoxerManager.shared.decrypt(data: encryptedData, using: key)
                    let destinationURL = selectedFolder.appendingPathComponent(fileURL.lastPathComponent)
                    try decryptedData.write(to: destinationURL)
                }
                setMessages("復号化したファイルのダウンロードが完了しました。", "")

            } catch {
                setMessages("", "ファイルのダウンロードに失敗しました。")
            }
        } else {
            DispatchQueue.main.async {
                setMessages("", "")
            }
        }
    }
    
    func setMessages(_ messageText: String, _ warningText: String) {
        message = messageText
        warning = warningText
    }
    
    func filterHiddenFiles(allFiles: [URL]) -> [URL] {
        let filterringFiles = allFiles.filter {
            !$0.lastPathComponent.hasPrefix(".")
        }
        return filterringFiles
    }
}
