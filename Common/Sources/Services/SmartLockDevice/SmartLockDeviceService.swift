// 
//  Copyright © 2019 saiten. All rights reserved.
//

import RxSwift
import RxCocoa
import RxBluetoothKit
import CoreBluetooth

public protocol SmartLockDeviceServiceProtocol {
    func scan(mode: SmartLockDeviceMode, timeout: TimeInterval) -> Single<SmartLockDeviceProtocol>
}

public enum SmartLockDeviceError: Error {
    case bluetoothError
    case invalidCharacteristic
    case failedResponse
}

public enum SmartLockDeviceMode {
    case `default`
    case register
    
    public var serviceUUIDs: [CBUUID] {
        switch self {
        case .default: return [.smartLockMainService]
        case .register: return [.smartLockRegistrationService]
        }
    }
}

public class SmartLockDeviceService: SmartLockDeviceServiceProtocol {

    private let queue: DispatchQueue
    
    public init(queue: DispatchQueue = DispatchQueue(label: "smartlock-device-service")) {
        self.queue = queue
        //RxBluetoothKitLog.setLogLevel(.verbose)
    }

    public func scan(mode: SmartLockDeviceMode, timeout: TimeInterval = 30.0) -> Single<SmartLockDeviceProtocol> {
        let manager = CentralManager(queue: queue, options: [:])

        let scannedPeripheral = manager.observeState()
            .startWith(manager.state)
            .flatMap { state -> Observable<Void> in
                switch state {
                case .poweredOn:
                    return .just(())
                case .unsupported, .unauthorized:
                    return .error(SmartLockDeviceError.bluetoothError)
                default:
                    return .empty()
                }
            }
            .flatMap { manager.scanForPeripherals(withServices: mode.serviceUUIDs) }
            .take(1)
            .share(replay: 1)
        
        let connectedPeripheral = scannedPeripheral
            .flatMap { $0.peripheral.establishConnection() }
            .share(replay: 1)
        
        let connectionDisposable = connectedPeripheral.subscribe()
        
        let mainServiceCharacteristics: Observable<[Characteristic]> = {
            guard mode == .default else { return .just([]) }
            return connectedPeripheral
                .flatMap { $0.discoverServices([.smartLockMainService]) }
                .flatMap { Observable.from($0) }
                .flatMap { $0.discoverCharacteristics(nil) }
                .flatMap { characteristics -> Observable<[Characteristic]> in
                    guard Set.smartLockMainServiceCharacteristics.isSubset(of: characteristics.map { $0.uuid }) else {
                        return .error(SmartLockDeviceError.invalidCharacteristic)
                    }
                    return .just(characteristics)
                }
        }()
        
        let registrationServiceCharacteristics: Observable<[Characteristic]> = {
            guard mode == .register else { return .just([]) }
            return connectedPeripheral
                .flatMap { $0.discoverServices([.smartLockRegistrationService]) }
                .flatMap { Observable.from($0) }
                .flatMap { $0.discoverCharacteristics(nil) }
                .flatMap { characteristics -> Observable<[Characteristic]> in
                    guard Set.smartLockRegistrationServiceCharacteristics.isSubset(of: characteristics.map { $0.uuid }) else {
                        return .error(SmartLockDeviceError.invalidCharacteristic)
                    }
                    return .just(characteristics)
                }
        }()
        
        return Observable.zip(connectedPeripheral, mainServiceCharacteristics, registrationServiceCharacteristics)
            .map { (peripheral, main, registration) in
                let register  = registration.first { $0.uuid == .smartLockRegisterKeyCharacteristic }
                let verify    = registration.first { $0.uuid == .smartLockVerifySignCharacteristic }
                let challenge = main.first { $0.uuid == .smartLockChallengeCharacteristic }
                let operation = main.first { $0.uuid == .smartLockOperationCharacteristic }
                
                let device = SmartLockDevice(peripheral: peripheral,
                                             connectionDisposable: connectionDisposable,
                                             challengeCharacteristic: challenge,
                                             lockCharacteristic: operation,
                                             registerPublicKeyCharacteristic: register,
                                             verifySignatureCharacteristic: verify)
                return device
            }
            .take(1)
            .asSingle()
    }
}
