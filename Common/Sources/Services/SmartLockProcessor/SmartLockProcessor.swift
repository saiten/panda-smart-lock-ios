//
//  Copyright © 2020 co.saiten. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import Action
import CryptoKit

public protocol SmartLockProcessorProtocol {
    func lock(for name: String) -> Single<Void>
    func unlock(for name: String) -> Single<Void>
    func register(for name: String, pinCode: [UInt8]) -> Single<Void>
}

public enum SmartLockProcessorError: Error {
    case keyNotExists
}

public final class SmartLockProcessor: SmartLockProcessorProtocol {
    // MARK: - Properties
    private let operateAction: Action<(String, SmartLockDeviceRequestMode), Void>
    private let registerAction: Action<(String, [UInt8]), Void>
    
    // MARK: - Initializer
    public init(smartLockDevice: SmartLockDeviceProtocol, keyStorage: KeyStorageProtocol) {
        // 解錠・施錠
        self.operateAction = Action { (name, mode) in
            guard let privateKey = keyStorage.getKey(for: name) else {
                return .error(SmartLockProcessorError.keyNotExists)
            }

            return Single.zip(smartLockDevice.readRSSI(),
                              smartLockDevice.getChallenge())
                .flatMap { (rssi, challenge) -> Single<Void> in
                    var head: [UInt8] = []
                    head.append(mode.rawValue)
                    head.append(UInt8(bitPattern: Int8(rssi)))
                    let payload = name.data(using: .utf8)! + Data(head) + challenge
                    
                    let hash = SHA256.hash(data: payload)
                    let signature = try! privateKey.signature(for: hash)
                    
                    let hashData = hash.withUnsafeBytes { p -> Data in Data(p) }
                    print(hashData.hexString)
                    
                    let publicKey = privateKey.publicKey
                    let valid = publicKey.isValidSignature(signature, for: hash)

                    print("signature = \(signature.rawRepresentation.hexString)")
                    print("is valid signature = \(valid)")

                    return smartLockDevice.request(payload: payload,
                                                   signature: signature.rawRepresentation)
                }
                .asObservable()
        }
        
        // 登録処理
        self.registerAction = Action { (name, pinCode) in
            try? keyStorage.delete(for: name)
            guard let privateKey = keyStorage.getKey(for: name) else {
                return .error(SmartLockProcessorError.keyNotExists)
            }
            let publicKey = privateKey.publicKey

            return smartLockDevice.registerPublicKey(publicKey.rawRepresentation)
                .flatMap { () -> Single<Void> in
                    print("name = \(name), pinCode = \(pinCode)")

                    let pinData: [UInt8] = [
                        (pinCode[0] & 0xF) << 4 | (pinCode[1] & 0xF),
                        (pinCode[2] & 0xF) << 4 | (pinCode[3] & 0xF),
                        (pinCode[4] & 0xF) << 4 | (pinCode[5] & 0xF)
                    ]
                    
                    let d1 = name.data(using: .utf8)!
                    let d2 = Data(bytes: pinData, count: pinData.count)
                    let payload = d1 + d2
                    
                    let hash = SHA256.hash(data: payload)
                    let signature = try! privateKey.signature(for: hash)
                    
                    let hashData = hash.withUnsafeBytes { p -> Data in Data(p) }
                    print(hashData.hexString)
                    
                    let valid = publicKey.isValidSignature(signature, for: hash)
                    print("signature = \(signature.rawRepresentation.hexString)")
                    print("is valid signature = \(valid)")
                    
                    return smartLockDevice.verifySignature(payload: payload,
                                                           signature: signature.rawRepresentation)
                }
                .flatMap { () -> Single<Void> in
                    print("confirm pin")
                    print("name : \(name), PIN : \(pinCode.map { String($0) }.joined())")
                    return smartLockDevice.confirmPIN()
                }
                .asObservable()
        }
    }

    // MARK: - Operation
    public func lock(for name: String) -> Single<Void> {
        return operateAction.execute((name, .lock))
            .map { self }.map { _ in }
            .asSingle()
    }
    
    public func unlock(for name: String) -> Single<Void> {
        return operateAction.execute((name, .unlock))
            .map { self }.map { _ in }
            .asSingle()
    }
    
    public func register(for name: String, pinCode: [UInt8]) -> Single<Void> {
        return registerAction.execute((name, pinCode))
            .map { self }.map { _ in }
            .asSingle()
    }
}


