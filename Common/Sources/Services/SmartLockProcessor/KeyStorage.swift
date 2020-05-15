//
//  Copyright © 2020 co.saiten. All rights reserved.
//

import KeychainAccess
import CryptoKit

public protocol KeyStorageProtocol {
    func getKey(for name: String) -> P256.Signing.PrivateKey?
    func delete(for name: String) throws
}

public final class KeyStorage: KeyStorageProtocol {
    // MARK: - Properties
    public static let shared = KeyStorage(serviceName: "co.saiten.panda")
    private let keychainAccess: Keychain
    
    // MARK: - Initializer
    public init(serviceName: String) {
        self.keychainAccess = Keychain(service: serviceName)
    }
    
    // MARK: - Operation
    public func getKey(for name: String) -> P256.Signing.PrivateKey? {
        if let data = keychainAccess[data: name],
           let key = try? P256.Signing.PrivateKey(rawRepresentation: data) {
            return key
        } else {
            let key = P256.Signing.PrivateKey()
            keychainAccess[data: name] = key.rawRepresentation
            return key
        }
    }

    public func delete(for name: String) throws {
        try keychainAccess.remove(name)
    }
}
