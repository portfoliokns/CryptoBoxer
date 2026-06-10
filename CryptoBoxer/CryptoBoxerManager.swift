import Foundation
import CryptoKit
import AppKit

class CryptoBoxerManager {
    static let shared = CryptoBoxerManager()
    private init() {}
    
    private var count: Int = 0
    
    func makeKey(from password: String) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        var hash = SHA256.hash(data: passwordData)
        let stretchTimes = 3000000
        for _ in 1..<stretchTimes {
            hash = SHA256.hash(data: Data(hash))
            count += 1
        }
        return SymmetricKey(data: hash)
    }
    
    func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw NSError(domain: "EncryptionError", code: 0, userInfo: nil)
        }
        return combined
    }
    
    func decrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func getFolderPath(folderName: String) throws -> URL {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folderPath = appSupport
            .appendingPathComponent("CryptoBoxer")
            .appendingPathComponent(folderName)
            
        try fileManager.createDirectory(
                    at: folderPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
        return folderPath
    }
    
    func openFinder(folderName: String) {
        let fileManager = FileManager.default
        guard let appSupport = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return
        }
        
        let folderPath = appSupport
            .appendingPathComponent("CryptoBoxer")
            .appendingPathComponent(folderName)
        NSWorkspace.shared.open(folderPath)
    }
    
    func clearFiles(folderName: String) {
        let fileManager = FileManager.default
        guard let folder = try? CryptoBoxerManager.shared.getFolderPath(folderName: folderName) else {return}
        let files = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
}
