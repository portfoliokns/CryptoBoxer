import SwiftUI
import UniformTypeIdentifiers

struct SelectedImage: Identifiable {
    let id = UUID()
    let url: URL
}

struct ViewerView: View {
    @State private var message: String = ""
    @State private var warning: String = ""
    @State private var images: [URL] = []
    @State private var selectedImage: SelectedImage?
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
                    CryptoBoxManager.shared.openFinder(folderName: "storage")
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
                        CryptoBoxManager.shared.clearFilse(folderName: "storage")
                        CryptoBoxManager.shared.clearFilse(folderName: "tmp")
                        self.images = []
                        setMessages("CryptoBox上からファイルが全て削除されました。", "")
                    }
                } message: {
                    Text("CryptoBoxに保存されているデータが全て削除されます。よろしいですか？")
                }
            }
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ]) {
                    ForEach(images, id: \.self) { url in
                        let ext = url.pathExtension.lowercased()
                        if ["png","jpg","jpeg","heic"].contains(ext) {
                            if let key = keyStore.key,
                               let encrypted = try? Data(contentsOf: url),
                               let decrypted = try? CryptoBoxManager.shared.decrypt(data: encrypted, using: key),
                               let nsImage = NSImage(data: decrypted) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedImage = SelectedImage(url: url)
                                    }
                            }
                        } else {
                            VStack {
                                Image(systemName: "key")
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
                                        let tmpFolder = try CryptoBoxManager.shared.getFolderPath(folderName: "tmp")
                                        let fileName = url.deletingPathExtension().lastPathComponent
                                        let ext = url.pathExtension
                                        let tmpURL = tmpFolder.appendingPathComponent(fileName).appendingPathExtension(ext)
                                        CryptoBoxManager.shared.openFinder(folderName: "tmp")
                                        setMessages("Finderのtmpフォルダを開きました。", "")
                                        warning = ""
                                        if FileManager.default.fileExists(atPath: tmpURL.path) { return }
                                        let encrypted = try Data(contentsOf: url)
                                        let decrypted = try CryptoBoxManager.shared.decrypt(data: encrypted, using: key)
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
                loadImages()
            }
            .sheet(item: $selectedImage) { item in
                ImageDetailView(imageURL: item.url)
            }
        }
    }
    
    func loadImages() {
        let fileManager = FileManager.default
        do {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let storage = appSupport
                .appendingPathComponent("CryptoBox")
                .appendingPathComponent("storage")
            let files = try fileManager.contentsOfDirectory(
                at: storage,
                includingPropertiesForKeys: nil
            )
            images = files
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
                let storageFolder = try CryptoBoxManager.shared.getFolderPath(folderName: "storage")
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
            let storageFolder = try CryptoBoxManager.shared.getFolderPath(folderName: "storage")
            if panel.runModal() == .OK {
                for url in panel.urls {
                    let destinationURL = storageFolder.appendingPathComponent(url.lastPathComponent)
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: url, to: destinationURL)
                }
                loadImages()
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
                let storageFolder = try CryptoBoxManager.shared.getFolderPath(folderName: "storage")
                let files = try fileManager.contentsOfDirectory(at: storageFolder, includingPropertiesForKeys: nil)
                guard let key = keyStore.key else {
                    debugPrint("エラー: 復号キーが見つかりません")
                    return
                }
                
                for fileURL in files {
                    let encryptedData = try Data(contentsOf: fileURL)
                    let decryptedData = try CryptoBoxManager.shared.decrypt(data: encryptedData, using: key)
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
}
