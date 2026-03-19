import SwiftUI

struct ImageDetailView: View {
    let imageURL: URL
    @EnvironmentObject var keyStore: KeyStore
    
    var body: some View {
        VStack {
            if let key = keyStore.key,
               let encrypted = try? Data(contentsOf: imageURL),
               let decrypted = try? CryptoBoxManager.shared.decrypt(data: encrypted, using: key),
               let nsImage = NSImage(data: decrypted) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                Text("画像を読み込めません")
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
