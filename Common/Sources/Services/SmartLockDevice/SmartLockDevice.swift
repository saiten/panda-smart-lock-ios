// 
//  Copyright © 2019 tomoaki.shibata. All rights reserved.
//

import RxSwift
import RxCocoa
import RxBluetoothKit
import CoreBluetooth

public enum SmartLockDeviceRequestMode: UInt8 {
    case lock = 1
    case unlock = 2
}

public protocol SmartLockDeviceProtocol: AnyObject {
    var canRegistration: Bool { get }

    func readRSSI() -> Single<Int>
    
    func registerPublicKey(_ key: Data) -> Single<Void>
    func verifySignature(payload: Data, signature: Data) -> Single<Void>
    func confirmPIN() -> Single<Void>
    
    func getChallenge() -> Single<Data>
    func request(payload: Data, signature: Data) -> Single<Void>
    
    func observeConnection() -> Observable<Bool>
}

public class SmartLockDevice: SmartLockDeviceProtocol {
    
    // MARK: - Properties
    public var canRegistration: Bool {
        return registerPublicKeyCharacteristic != nil && verifySignatureCharacteristic != nil
    }
    
    public var canOperation: Bool {
        return challengeCharacteristic != nil && lockCharacteristic != nil
    }
    
    private let peripheral: Peripheral
    private let connectionDisposable: Disposable
    private let challengeCharacteristic: Characteristic?
    private let lockCharacteristic: Characteristic?
    private let registerPublicKeyCharacteristic: Characteristic?
    private let verifySignatureCharacteristic: Characteristic?
    
    // MARK: - Initializer
    public init(peripheral: Peripheral,
         connectionDisposable: Disposable,
         challengeCharacteristic: Characteristic?,
         lockCharacteristic: Characteristic?,
         registerPublicKeyCharacteristic: Characteristic?,
         verifySignatureCharacteristic: Characteristic?) {
        self.peripheral = peripheral
        self.connectionDisposable = connectionDisposable
        self.challengeCharacteristic = challengeCharacteristic
        self.lockCharacteristic = lockCharacteristic
        self.registerPublicKeyCharacteristic = registerPublicKeyCharacteristic
        self.verifySignatureCharacteristic = verifySignatureCharacteristic
    }

    deinit {
        print("deinit")
        connectionDisposable.dispose()
    }
    
    // MARK: - Operation methods
    
    public func observeConnection() -> Observable<Bool> {
        return peripheral.observeConnection()
    }
    
    
    public func readRSSI() -> Single<Int> {
        return peripheral.readRSSI().map { $1 }
    }
    
    public func registerPublicKey(_ key: Data) -> Single<Void> {
        guard let characteristic = registerPublicKeyCharacteristic else { return .error(SmartLockDeviceError.invalidCharacteristic) }

        return Observable.zip(characteristic.observeValueUpdateAndSetNotification(),
                              characteristic.writeValue(key, type: .withResponse).asObservable())
            .map { $0.0 }
            .flatMap { (c: Characteristic) -> Observable<Void> in
                guard let data = c.value, data.count > 0 else { return .error(SmartLockDeviceError.bluetoothError) }
                if data[0] == 0 {
                    return .just(())
                } else {
                    return .error(SmartLockDeviceError.failedResponse)
                }
            }
            .take(1)
            .asSingle()
    }
    
    public func verifySignature(payload: Data, signature: Data) -> Single<Void> {
        guard let characteristic = verifySignatureCharacteristic else { return .error(SmartLockDeviceError.invalidCharacteristic) }

        return Observable.zip(characteristic.observeValueUpdateAndSetNotification(),
                              characteristic.writeValue(payload + signature, type: .withResponse).asObservable())
            .map { $0.0 }
            .flatMap { (c: Characteristic) -> Observable<Void> in
                guard let data = c.value, data.count > 0 else { return .error(SmartLockDeviceError.bluetoothError) }
                if data[0] == 0 {
                    return .just(())
                } else {
                    return .error(SmartLockDeviceError.failedResponse)
                }
            }
            .take(1)
            .asSingle()
    }

    public func confirmPIN() -> Single<Void> {
        guard let characteristic = verifySignatureCharacteristic else { return .error(SmartLockDeviceError.invalidCharacteristic) }
        return characteristic.observeValueUpdateAndSetNotification()
            .flatMap { (c: Characteristic) -> Observable<Void> in
                guard let data = c.value, data.count > 0 else { return .error(SmartLockDeviceError.bluetoothError) }
                if data[0] == 0 {
                    return .just(())
                } else {
                    return .error(SmartLockDeviceError.failedResponse)
                }
            }
            .take(1)
            .asSingle()
    }

    public func getChallenge() -> Single<Data> {
        guard let characteristic = challengeCharacteristic else { return .error(SmartLockDeviceError.invalidCharacteristic) }
        return characteristic.readValue()
            .map { $0.value }
            .flatMap {
                if let challenge = $0 {
                    return .just(challenge)
                } else {
                    return .error(SmartLockDeviceError.failedResponse)
                }
            }
    }
    
    public func request(payload: Data, signature: Data) -> Single<Void> {
        guard let characteristic = lockCharacteristic else { return .error(SmartLockDeviceError.invalidCharacteristic) }

        return Observable.zip(characteristic.observeValueUpdateAndSetNotification(),
                              characteristic.writeValue(payload + signature, type: .withResponse).asObservable())
            .map { $0.0 }
            .flatMap { (c: Characteristic) -> Observable<Void> in
                guard let data = c.value, data.count > 0 else { return .error(SmartLockDeviceError.bluetoothError) }
                if data[0] == 0 {
                    return .just(())
                } else {
                    return .error(SmartLockDeviceError.failedResponse)
                }
            }
            .take(1)
            .asSingle()
    }
}
