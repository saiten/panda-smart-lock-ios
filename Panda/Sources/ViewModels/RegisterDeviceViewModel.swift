//
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import CryptoKit
import KeychainAccess
import Common

enum RegisterDeviceViewState {
    case initialized
    case scanning
    case detected
    case register
    case confirm
    case completed
}

enum RegisterDeviceViewAction {
    case startScanning
    case registration
    case confirmPIN
    case registerCompleted
}

protocol RegisterDeviceViewModelInputs {
    var start: PublishRelay<Void> { get }
}

protocol RegisterDeviceViewModelOutputs {
    var state: Driver<RegisterDeviceViewState> { get }
    var log: Driver<String> { get }
    var running: Driver<Bool> { get }
}

protocol RegisterDeviceViewModelType {
    var inputs: RegisterDeviceViewModelInputs { get }
    var outputs: RegisterDeviceViewModelOutputs { get }
}

final class RegisterDeviceViewModel: RegisterDeviceViewModelType, RegisterDeviceViewModelInputs, RegisterDeviceViewModelOutputs {
    // MARK: - Properties
    var inputs: RegisterDeviceViewModelInputs { return self }
    var outputs: RegisterDeviceViewModelOutputs { return self }

    private let _state: BehaviorRelay<RegisterDeviceViewState>
    private let registerAction: Action<(String, [UInt8]), Void>
    private let _log: BehaviorRelay<String>
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let start = PublishRelay<Void>()
    
    // MARK: - Outputs
    let state: Driver<RegisterDeviceViewState>
    let log: Driver<String>
    let running: Driver<Bool>
    
    // MARK: - Initializer
    init(smartLockDeviceManager: SmartLockDeviceManagerProtocol = SmartLockDeviceManager.shared,
         keyStorage: KeyStorageProtocol = KeyStorage.shared) {
        self._state = BehaviorRelay(value: .initialized)
        self.state = _state.asDriver()

        let logger = PublishRelay<String>()
        self._log = BehaviorRelay(value: "Panda smart lock registration\n")
        self.log = _log.asDriver()

        logger
            .withLatestFrom(_log) { $1 + $0 + "\n" }
            .bind(to: _log)
            .disposed(by: disposeBag)
        
        self.registerAction = Action { (name, pinCode) in
            logger.accept("Start register ...")

            // create private key
            logger.accept("start scan device ...")

            // 登録モードに切り替え
            smartLockDeviceManager.stop()
            smartLockDeviceManager.start(mode: .register)

            return smartLockDeviceManager.currentDevice
                .compactMap { $0 }
                .timeout(30, scheduler: MainScheduler.asyncInstance)
                .do(onNext: { _ in logger.accept("device found !") })
                .do(onNext: { _ in
                    logger.accept("confirm name and PIN.")
                    logger.accept("name : \(name), PIN : \(pinCode.map { String($0) }.joined())")
                })
                .flatMap { device -> Single<Void> in
                    let processor = SmartLockProcessor(smartLockDevice: device, keyStorage: keyStorage)
                    return processor.register(for: name, pinCode: pinCode)
                }
                .do(onNext: {
                    // 通常モードに戻す
                    smartLockDeviceManager.stop()
                    smartLockDeviceManager.start()
                })
        }
                
        self.running = registerAction.executing
            .asDriver(onErrorDriveWith: .empty())
        start
            .map { ("MAIN", (0..<6).map { _ in UInt8(arc4random() % 10) }) }
            .bind(to: registerAction.inputs)
            .disposed(by: disposeBag)
        
        registerAction.elements
            .subscribe(onNext: {
                print("success")
                logger.accept("register completed")
            })
            .disposed(by: disposeBag)
        registerAction.errors
            .subscribe(onNext: { error in
                print("error \(error)")
                logger.accept("Error occurred. : \(error)")
            })
            .disposed(by: disposeBag)
    }
}

