import SwiftUI

@main
struct CryptoBoxApp: App {
    @StateObject var keyStore = KeyStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(keyStore)
        }
    }
}

