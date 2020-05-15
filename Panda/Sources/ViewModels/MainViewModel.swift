// 
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import CryptoKit
import Common

protocol MainViewModelInputs {
    var lockRequest: PublishRelay<Void> { get }
    var unlockRequest: PublishRelay<Void> { get }
}

protocol MainViewModelOutputs {
    var lockButtonEnabled: Driver<Bool> { get }
    var loading: Driver<Bool> { get }
    var lockSuccess: Driver<Void> { get }
    var unlockSuccess: Driver<Void> { get }
    var failed: Driver<Void> { get }
}

protocol MainViewModelType {
    var inputs: MainViewModelInputs { get }
    var outputs: MainViewModelOutputs { get }
}

final class MainViewModel: MainViewModelType, MainViewModelInputs, MainViewModelOutputs {
    // MARK: - Properties
    var inputs: MainViewModelInputs { return self }
    var outputs: MainViewModelOutputs { return self }

    private let keyAction: Action<(SmartLockDeviceRequestMode, SmartLockDeviceProtocol), SmartLockDeviceRequestMode>
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let lockRequest = PublishRelay<Void>()
    let unlockRequest = PublishRelay<Void>()

    // MARK: - Outputs
    let lockButtonEnabled: Driver<Bool>
    let loading: Driver<Bool>
    let lockSuccess: Driver<Void>
    let unlockSuccess: Driver<Void>
    let failed: Driver<Void>
    
    // MARK: - Initializer
    init(smartLockDeviceManager: SmartLockDeviceManagerProtocol = SmartLockDeviceManager.shared,
         keyStorage: KeyStorageProtocol = KeyStorage.shared) {

        self.keyAction = Action { (mode, device) in
            let processor = SmartLockProcessor(smartLockDevice: device, keyStorage: keyStorage)
            switch mode {
            case .lock:
                return processor.lock(for: "MAIN").asObservable()
                    .map { _ in .lock }
            case .unlock:
                return processor.unlock(for: "MAIN").asObservable()
                    .map { _ in .unlock }
            }
        }

        let smartLockDevice = smartLockDeviceManager.currentDevice
        
        self.lockButtonEnabled = smartLockDevice
            .map { $0 != nil }
            .asDriver(onErrorDriveWith: .empty())

        self.loading = keyAction.executing
            .asDriver(onErrorDriveWith: .empty())

        Observable<SmartLockDeviceRequestMode>
            .merge(lockRequest.map { .lock }, unlockRequest.map { .unlock })
            .withLatestFrom(smartLockDevice.compactMap { $0 }) { ($0, $1) }
            .bind(to: keyAction.inputs)
            .disposed(by: disposeBag)

        self.lockSuccess = keyAction.elements
            .filter { $0 == .lock }
            .map { _ in }
            .asDriver(onErrorDriveWith: .empty())

        self.unlockSuccess = keyAction.elements
            .filter { $0 == .unlock }
            .map { _ in }
            .asDriver(onErrorDriveWith: .empty())
        
        self.failed = keyAction.errors
            .map { _ in }
            .asDriver(onErrorDriveWith: .empty())

        keyAction.elements
            .subscribe(onNext: { _ in
                print("success")
            })
            .disposed(by: disposeBag)

        keyAction.errors
            .subscribe(onNext: { error in
                print("error \(error)")
            })
            .disposed(by: disposeBag)
    }
}

