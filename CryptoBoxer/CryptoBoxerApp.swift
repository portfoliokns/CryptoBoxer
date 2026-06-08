import SwiftUI

@main
struct CryptoBoxerApp: App {
    @StateObject var keyStore = KeyStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(keyStore)
        }
    }
}

